---
title: 让计算机审美，这可能吗?
date: 2019-08-06 22:37:29
tags: [计算机视觉, 深度学习, 论文]
categories: 计算机视觉
mathjax: true
---

入职一个月，一直在研究计算机美学 (photo aesthetic) 的课题，因为有一个需求是帮助用户筛选出一些拍的比较好的图片。这段时间陆陆续续看了很多相关的文章，也一直在思考这个问题：让计算机来对图片进行审美，到底有没有可能？毕竟审美是一件很主观的事情，美的定义本身也不清晰，让需要明确指令的计算机来做一件人类都不明确的事情，这看起来就不太现实。

本文会记录一下我最近看过的一些文章，总结一下这个领域的研究思路，以及我个人的一些想法。

<!--more-->

## 什么是计算机美学

狭义上讲，计算机美学 (photo aesthetic) 的研究内容是教计算机对图片审美，可以是输出一个分数，也可以是对图片分好坏，抑或是其他评价手段均可以。

当然，更广义的讲，凡是涉及到审美相关的领域都可以归结到计算机美学的范畴。从这个角度出发，可以衍生出大量的课题和应用，比如，让计算机扣图、生成一些非常专业的摄影那个图片等等。

题外话，与计算机审美相关的，还有另一个课题叫图像质量评估 (image quality assessment)。我的理解是，计算机美学偏向于主观感受，而图像质量评估则偏向于客观感受 (比如噪声、饱和度等客观因素)。前者由于太过主观，所以评价指标一般是跟数据集中已有的评分进行比较，而后者则有一些客观的评价标准 (如 [PSNR]([https://zh.wikipedia.org/zh-hans/%E5%B3%B0%E5%80%BC%E4%BF%A1%E5%99%AA%E6%AF%94](https://zh.wikipedia.org/zh-hans/峰值信噪比))，[SSIM]([https://zh.wikipedia.org/wiki/%E7%B5%90%E6%A7%8B%E7%9B%B8%E4%BC%BC%E6%80%A7](https://zh.wikipedia.org/wiki/結構相似性)))。

下面，我们就根据不同的应用类型，看看各个相关领域的课题都是怎么玩的。

## 美学评分

最容易想到的应用自然是让计算机给一张图片进行打分。这里的打分可以是输出一个分数，也可以是对图片进行分类，抑或是输出一个美的等级等各种评价手段。前几年很火各种的测颜值 APP，就是美学评分最直接的应用。

这个任务现在来看似乎很简单，无非是将图片丢入一个网络后，再输出一个分数即可。但在没有深度学习的时代，人们通常只能计算一些手工特征（类似颜色直方图、饱和度等），再用一个分类器或回归模型来训练，效果并不好，因而只能是一些实验室 demo，或者在论文中灌灌水。而等到卷积网络大行其道后，美学评分也像其他任务一样，被研究人员从角落里捡起来，加入到各种刷分比赛中，甚至已经被工业界落地成产品。

要想让计算机对图像进行打分，就得先搞清楚美的定义是什么。遗憾的是，对于美的定义，连人类自己都模糊不清，一千个摄影师，就有一千张不同的摄影技巧。因此，为了推动这个领域的研究，人们构造了很多数据集，并且让很多人来对每张图片进行打分，从统计的意义上讲，只要打分的人数足够多，那么平均所有人的评分后，得到的均值就是符合大部分人审美的分数。目前常用的几个数据集包括 [CUHK-PQ](http://personal.ie.cuhk.edu.hk/~dy015/ImageAesthetics/Image_Aesthetic_Assessment.html)、[AVA](http://academictorrents.com/details/71631f83b11d3d79d8f84efe0a7e12f0ac001460)、[AADB](https://github.com/aimerykong/deepImageAestheticsAnalysis) 等，其中被用得比较广的当属 AVA 了，因为这个数据集的图片数量异常庞大，且标签也比较丰富，因此可以挖的点更多。

接下来，美学打分的任务就是在这些数据集上刷分。

下面就简单讲几篇典型的文章，虽然灌水严重，但也不乏启发性很强的好文。

### 1. RAPID: Rating Pictorial Aesthetics using Deep Learning (ACM MM2014)

这应该算是最早使用深度学习做美学评分的论文了。在图像美学中，图片的整体布局 (global) 和细节内容 (local) 都是需要考虑的因素。为了让网络能同时捕获这些信息，这篇论文除了将整张图片 (global) 输入网络外，还从图片中随机抠出很多 patch (local) 输入网络，然后将二者的信息结合起来进行分类。

<center>
  <img src="/images/2019-8-6/rapid-rdcnn.png" width="500px">
</center>

除此以外，由于这篇论文是在 AVA 上做的实验，作者发现 AVA 数据集除了评分外，还有一些 style 相关的属性分数，所以他们也探索了这部分信息的作用。由于不是每张图片都有 style 标签，所以这里面还用了迁移学习的方法来训练一个 pretrain 模型。具体细节不表。

当然，随着网络结构的发展，这篇论文的实验结果早已被超过，但它用 patch 作为输入的做法由于效果不错，因此一直被之后的论文采用。

### 2. Deep multi-patch aggregation network for image style, aesthetics, and quality estimation (ICCV 2015)

还是上一篇论文的作者，他们在之前的尝试中，估计发现 patch 对这种美学评分的任务效果很好，因此又专门针对 patch 做了一次研究。这一次，他们只尝试了用 patch 作为输入，并设计了几种方法来融合这些 patch 的信息：

<center>
  <img src="/images/2019-8-6/DMA-net.png" width="400px">
</center>



### 3. A-Lamp: Adaptive Layout-Aware Multi-Patch Deep Convolutional Neural (CVPR 2017)

### 4. Attention-based Multi-Patch Aggregation for Image Aesthetic Assessment (ACM MM 2018)

### 5. Deep Aesthetic Quality Assessment with Semantic Information (TIP 2017)

不同的场景往往会有不同的拍照方式和审美标准，因此，把场景的语义信息也融合到网络中，对结果会不会有提升呢？这篇论文在 AVA 中挑了一些常见的场景标签，并用 MTCNN 网络做了一番尝试：

<center>
  <img src="/images/2019-8-6/semantic-net.png" width="500px">
</center>

从实验结果也可以看出，这种场景的语义信息可以提高美学分类的准确性 (注：$\delta$ 表示对好图和坏图的容忍度，具体请参考原论文。STCNN 表示没有加入场景语义信息)：

<center>
  <img src="/images/2019-8-6/semantic-exp-1.png" width="500px">
</center>

另外，这篇文章真对多任务学习提出了一种 Multi-Task Relationship Learning(MTRL) 的优化框架，分类准确率提高了 0.5 个点左右。

<center>
  <img src="/images/2019-8-6/semantic-exp-2.png" width="500px">
</center>



## 图片美化



## 自动裁剪

## 自动构图





总的来说，一流的研究提出一个新的研究方向 (也就是常说的**坑**)，伴随而来的是一个 (或者一类) 新的数据集。二流的研究则在别人提出的研究方向上改进模型。三流的研究在模型上打补丁。

## 应用

### 图片筛选

### 图像增强

### 自动扣图

## 参考
