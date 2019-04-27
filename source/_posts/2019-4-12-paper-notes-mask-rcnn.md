---
title: 论文笔记：Mask R-CNN
date: 2019-04-12 23:41:11
tags: [论文, 计算机视觉, 深度学习]
mathjax: true
---

之前在一次组会上，师弟诉苦说他用 UNet 处理一个病灶分割的任务，但效果极差，我看了他的数据后发现，那些病灶区域比起整张图而言非常的小，而 UNet 采用的损失函数通常是逐像素的分类损失，如此一来，网络只要能够分割出大部分背景，那么 loss 的值就可以下降很多，自然无法精细地分割出那些细小的病灶。反过来想，这其实类似于正负样本极不均衡的情况，网络拟合了大部分负样本后，即使正样本拟合得较差，整体的 loss 也已经很低了。

发现这个问题后，我就在想可以不可以先用 Faster RCNN 之类的先检测出这些病灶区域的候选框，再在框内做分割，甚至，能不能直接把 Faster RCNN 和分割部分做成一个统一的模型来处理。后来发现，这不就是 Mask RCNN 做的事情咩～囧～

这篇文章，我们就从无到有来看看 Mask RCNN 是怎么设计出来的。

<center>
  <img src="/images/2019-4-12/mask-rcnn.png" width="700px">
</center>

<!--more-->

## 回顾 Faster RCNN

首先，我们简单回忆一下 Faster RCNN 的结构，看看如何针对它进行拓展。上面这个框架图中，虚线框内就是 Faster RCNN 的大致结构了。算法过程可以粗略分为以下几步：

1. 将图片输入 CNN 中，得到 feature map；
2. 用一个 RPN 网络在 feature map 提取出候选框（region proposals）。**这一步对应 RPN 网络分支**；
3. 用另一个 CNN 进一步对该 feature map 进行特征提取，结合候选框得到很多 RoI，然后在每个 RoI 内用 RoI Pooling 提取特征，之后接上 FC 层分别预测框内物体的类别以及做 bounding box 微调。**这一步对应 Fast RCNN 网络分支**。

整个流程其实非常简洁。既然我们是想在候选框内进一步做分割，那么很自然的想法，就是在原 Faster RCNN 选出来的 RoI 中，根据 **classification score** 和 **bounding box regression** 选出得分最高的 RoI，并对这些 RoI 的框进行微调。这样，这些 RoI 就是最可能包含物体，同时定位也更为准确的 RoI 了，之后继续在这些 RoI 内做分割即可。另外，这个想法还能继续沿用之前得到的 feature map，避免卷积重复计算，可以说是一举两得。

事实上，Mask RCNN 采用的也是这一套思路。这种先检测物体再做分割的两步走策略，江湖人称 **two stage**，而 UNet 这种一步到位的分割方法，则被称为 **one stage**。显然，一步到位的 UNet 实现起来简单，大部分情况下效果也还行，但论精度，还是 Mask RCNN 更胜一筹，毕竟有候选框作为先验支撑。

这里要注意另一个问题，虽然 UNet 和 Mask RCNN 都是处理分割，但前者又称为 semantic segmentation，后者称为 instance segmentation。两者的区别可以用下面这张图体现，semantic segmentation 在分割的时候对同一类物体一视同仁，而 instance segmentation 则需要把每个个体都单独分割出来。因此，把 UNet 和 Mask RCNN 进行对比其实不太公平。instance segmentation 由于需要单独分割每个个体，因此基本上所有针对 instance segmentation 的方法都需要先用一个候选框把物体找出来，之后再分割。

<center>
  <img src="/images/2019-4-12/segmentation-type.png" width="600px">
</center>



下面，我们就来看看 Mask RCNN 是怎么在 Faster RCNN 的基础上实现分割的。

## Mask RCNN

Mask RCNN 的整体流程图可以参考文章开头那个框架图。它在 Faster RCNN 的基础上，延伸出了一个 **Mask** 分支。根据 Faster RCNN 计算出来的每个候选框的分数，筛选出一大堆更加准确的 RoI（对应图中 **selected RoI**），然后用一个 **RoI Align** 层提取这些 RoI 的特征，计算出一个 mask，根据 RoI 和原图的比例，将这个 mask 扩大回原图，就可以得到一个分割的 mask 了。

RoI Align 之后打算新开一篇文章针对代码细讲，本文只稍微提及 RoI Align 背后的机理，暂且就将它当作一个黑盒。

现在，我们从零出发，假设让我们来设计 Mask RCNN，这中间每一步要如何操作，以及会面临哪些问题。

### RoI 如何到 Mask

首先第一个问题是如何处理这些 RoI 的特征，输出分割的 mask。在 UNet 和 FCN 中，是先将图片通过卷积操作得到 feature map，再通过 deconvolution（或者 upsample + convolution）的方法将 feature map 的尺寸还原成原图大小。因此，我们也可以借用同样的思路，先根据 RoI 的尺寸换算回原图，看看这个 RoI 对应到原图上的尺寸有多大，再将 RoI 内的 feature map 上采样成对应尺寸的 mask，然后接一个 FCN 网络将 mask 的通道数处理成 $K$ 即可（假设总共有 $K$ 种类别）。由于上采样是可以求导的，因此反向传播依然有效。

> 写到这里，我突然觉得，之前 Fast RCNN 中提出的 RoI Pooling 其实是不是也可以换成这种**上/下采样 + 卷积**的方式来得到一个固定大小的 feature map，之后的 FC 层的维度也是可以匹配上的。而且 RoI Pooling 本质上也类似一种下采样的操作，只不过采样的方式是取邻域中最大的数值。但转念一想，这其实就是在问 Pooling 操作能不能用下采样来代替，从大佬们设计的网络结构中普遍采用 Pooling 操作来看，应该是 Pooling 的效果会更好。这个问题就此打住，暂且认为 Pooling 的效果好于下采样。

可以看出，我们设计的这个 mask 分支跟 UNet 或 FCN 的思路其实一样。不过，直接下采样可能会导致 feature map 中一些重要的信息丢失，因此，我们可以沿用 RoI Pooling 的思路，将 RoI 内的那块 feature map 处理成指定大小的 feature map，然后采用 conv/deconv 的方法进一步转换成 $K \times H \times W$ 的 mask，其中 $K​$ 表示物体的类别。最后把这个 mask 按照 RoI 对应的 bounding box 换算回原图中即可。这一步在训练上也可以类比 FCN，直接在 ground truth 中，根据 bounding box 找到那块对应的 mask，再按比例缩成跟网络输出的 mask 一样大小，然后根据分类损失或者 MSE 构造 Loss 函数即可。

大部分人都能走到这一步，但也就仅仅走到这一步而已。这个流程简单直接，而且也能 work，但实操后会发现效果不佳。这里就涉及到论文中提及的 **misalignment** 问题。

事实上，分割对模型精度的要求比分类以及检测要高得多，因为前者需要逐像素的标注类别信息。这意味着，如果 RoI 中的 feature map 跟原图中对应的区域存在偏差，就可能导致计算出来的 mask 跟 ground truth 是对不齐的。我们用一张图来说明：

<center>
  <img src="/images/2019-4-12/misalignment-1.jpg" width="600px">
</center>

原图中的小男孩有两个 bounding box 框住他，我们用卷积操作对图像进行 downsample，然后根据 feature map 和原图的比例，推算出这两个 bounding box 对应在 feature map 上的位置和大小。结果，很不幸这两个框的位置四舍五入后刚好对应同一块 feature map。接着，RoI Pooling 和 FCN 会对这块 feature map 进行处理得到 mask，再根据 ground truth 计算 Loss。两个框对应的 ground truth 当然是不一样的。这个时候，网络就左右为难，同样一个 feature map，居然要拟合两个不同的结果，它左右为难一脸懵逼，直接导致模型无法收敛。

这就是所谓的 **misalignment**。问题的根源在于 bounding box 缩放时的取整。当然，RoI Pooling 本身在 pooling 的时候也是存在取整误差的。

既然问题出在取整上，那么，很自然想到的解决思路就是放弃取整，直接根据推算得到的浮点数来处理 bounding box。如此一来，bounding box 对应到的 feature map 上就会有一些点的坐标不是整数，于是，我们需要重新确定这些点的特征值。而这一步也是 **RoI Align** 的主要工作。其具体的做法是采样双线性插值，根据相邻 feature map 上的点来插值一个新的特征向量。如下图所示：

<center>
<img src="/images/2019-4-12/roi-align.jpg" width="600px">
</center>

图中，我们现在 bounding box 中采样出几个点，然后用双线性插值计算出这几个点的向量，之后，再按照一般的 Pooling 操作得到一个固定大小的 feature map。具体的细节，之后开一篇新的文章介绍。

论文中通过 RoI Align 和 FCN 将 RoI 内对应的 feature map 处理成固定大小的 mask（$K \times m \times m$，$K$ 表示分割物体的种类数），然后将该 mask 还原回原图后，就可以得到对应的分割掩码了。

### Loss 的设计

在损失函数的设计方面，除了原本 Faster RCNN 中的分类损失和 bounding box 回归损失外，我们还需要针对 mask 分支设计一个分割任务的损失函数。最容易想到的函数自然是 FCN 和 UNet 中用到的 Softmax + Log 的多分类损失。不过，直接采用这个损失函数会出现所谓的 **class competition** 的问题。

### 几个小问题

#### 

## 实验

## 参考

+ [令人拍案称奇的Mask RCNN](https://zhuanlan.zhihu.com/p/37998710)
+ [A Brief History of CNNs in Image Segmentation: From R-CNN to Mask R-CNN](<https://blog.athelas.com/a-brief-history-of-cnns-in-image-segmentation-from-r-cnn-to-mask-r-cnn-34ea83205de4>)



