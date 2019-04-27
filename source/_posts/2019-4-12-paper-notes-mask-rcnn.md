---
title: 论文笔记：Mask R-CNN
date: 2019-04-12 23:41:11
tags: [论文, 计算机视觉, 深度学习]
mathjax: true
---

之前在一次组会上，师弟诉苦说他用 UNet 处理一个病灶分割的任务，但效果极差，我看了他的数据后发现，那些病灶区域比起整张图而言非常的小，而 UNet 采用的损失函数通常是 MSE Loss，如此一来，网络只要能够分割出大部分背景，那么 loss 的值就可以下降很多，自然无法精细地分割出那些细小的病灶。反过来想，这其实类似于正负样本极不均衡的情况，网络拟合了大部分负样本后，即使正样本拟合得较差，整体的 loss 也已经很低了。

发现这个问题后，我就在想可以不可以先用 Faster RCNN 之类的先检测出这些病灶区域的候选框，再在框内做分割，甚至，能不能直接把 Faster RCNN 和分割部分做成一个统一的模型来处理。后来发现，这不就是 Mask RCNN 做的事情咩～囧～

这篇文章，我们就从无到有来看看 Mask RCNN 是怎么设计出来的。

<center>
  <img src="/images/" width="">
</center>

<!--more-->

## 回顾 Faster RCNN

首先，我们简单回忆一下 Faster RCNN 的结构，看看如何针对它进行拓展。上面这个框架图中，虚线框内就是 Faster RCNN 的大致结构了。算法过程可以粗略分为以下几步：

1. 将图片输入 CNN 中，得到 feature map；
2. 用一个 RPN 网络在 feature map 提取出候选框（region proposals）。**这一步对应 RPN 网络分支**；
3. 用另一个 CNN 进一步对该 feature map 进行特征提取，结合候选框得到很多 ROI，然后在每个 ROI 内用 ROI Pooling 提取特征，之后接上 FC 层分别预测框内物体的类别以及做 bounding box 微调。**这一步对应 Fast RCNN 网络分支**。

整个流程其实非常简洁。既然我们是想在候选框内进一步做分割，那么很自然的想法，就是在原 Faster RCNN 选出来的 ROI 中，根据 **classification score** 和 **bounding box regression** 选出得分最高的 ROI，并对这些 ROI 的框进行微调。这样，这些 ROI 就是最可能包含物体，同时定位也更为准确的 ROI 了，之后继续在这些 ROI 内做分割即可。另外，这个想法还能继续沿用之前得到的 feature map，避免卷积重复计算，可以说是一举两得。

事实上，Mask RCNN 采用的也是这一套思路。这种先检测物体再做分割的两步走策略，江湖人称 **two stage**，而 UNet 这种一步到位的分割方法，则被称为 **one stage**。显然，一步到位的 UNet 实现起来简单，大部分情况下效果也还行，但论精度，还是 Mask RCNN 更胜一筹，毕竟有候选框作为先验支撑。

下面，我们就来看看 Mask RCNN 是怎么把这个过程细化实现的。

## Mask RCNN

Mask RCNN 的整体流程图可以参考文章开头那个框架图。它在 Faster RCNN 的基础上，延伸出了一个 **Mask** 分支。根据 Faster RCNN 计算出来的每个候选框的分数，筛选出一大堆更加准确的 ROI（对应图中 **selected ROI**），然后用一个 **ROI Align** 层提取这些 ROI 的特征，计算出一个 mask，根据 ROI 和原图的比例，将这个 mask 扩大回原图，就可以得到一个分割的 mask 了。

ROI Align 的具体细节稍后会讲，暂且就将它当作一个黑盒。但在此之前，我们先从零出发，假设让我们来设计 Mask RCNN，这中间每一步要如何操作，以及会面临哪些问题。

### ROI 如何到 Mask

首先第一个问题是如何处理这些 ROI 的特征，输出分割的 mask。在 UNet 和 FCN 中，是先将图片通过卷积操作得到 feature map，再通过 deconvolution（或者 upsample + convolution）的方法将 feature map 的尺寸还原成原图大小。因此，我们也可以借用同样的思路，先根据 ROI 的尺寸换算回原图，看看这个 ROI 对应到原图上的尺寸有多大，再将 ROI 内的 feature map 上采样成对应尺寸的 mask。



