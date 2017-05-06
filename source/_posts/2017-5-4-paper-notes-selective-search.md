---
title: 论文笔记：Selective Search for Object Recognition
date: 2017-05-04 22:18:01
tags: [计算机视觉]
categories: [计算机视觉]
mathjax: true
---

与 Selective Search 初次见面是在著名的物体检测论文 `Region-Based Convolutional Networks for Accurate Object Detection and Segmentation` 中，因此，这篇论文算是阅读 RCNN 的准备。

这篇论文的标题虽然也提到了 Object Recognition ，但就创新点而言，其实在 Selective Search 。所以，这里只简单介绍 Selective Search 的思想和算法过程，对于 Object Recognition 则不再赘述。

### 什么是 Selective Search

Selective Search，说的简单点，就是从图片中找出物体可能存在的区域。

在进一步探讨它的原理之前，我们分析一下，如何判别哪些 region 属于一个物体？

![image seg](/images/2017-5-4/image seg.png)

<!--more-->

作者在论文中用以上四幅图，分别描述了四种可能的情况：

1. 图 a ，物体之间可能存在层级关系，比如：碗里有个勺；
2. 图 b，我们可以用颜色来分开两只猫，却没法用纹理来区分；
3. 图 c，我们可以用纹理来区分变色龙，却没法用颜色来区分；
4. 图 d，轮胎是车的一部分，不是因为它们颜色相近、纹理相近，而是因为轮胎包含在车上。

所以，我们没法用单一的特征来定位物体，需要综合考虑多种策略，这一点是 Selective Search 精要所在。

### 需要考虑的问题

在学习 Selective Search 算法之前，我曾在计算机视觉课上学到过关于物体（主要是人脸）检测的方法。通常来说，最常规也是最简单粗暴的方法，就是用不同尺寸的矩形框，一行一行地扫描整张图像，通过提取矩形框内的特征判断是否是待检测物体。这种方法的复杂度极高，所以又被称为 **exhaustive search**。在人脸识别中，由于使用了 Haar 特征，因此可以借助 **Paul Viola** 和 **Michael Jones** 两位大牛提出的积分图，使检测在常规时间内完成。但并不是每种特征都适用于积分图，尤其在神经网络中，积分图这种动态规划的思路就没什么作用了。

针对传统方法的不足，Selective Search 从三个角度提出了改进：

1. 我们没法事先得知物体的大小，在传统方法中需要用不同尺寸的矩形框检测物体，防止遗漏。而 Selective Search 采用了一种具备层次结构的算法来解决这个问题；
2. 检测的时间复杂度可能会很高。Selective Search 遵循简单即是美的原则，只负责快速地生成可能是物体的区域，而不做具体的检测；
3. 另外，结合上一节提出的，采用多种先验知识来对各个区域进行简单的判别，避免一些无用的搜索，提高速度和精度。

### 算法框架

![algorithm](/images/2017-5-4/algorithm.png)

论文中给出的这个算法框架还是很详细的，这里再简单翻译一下。

+ 输入：彩色图片。
+ 输出：物体可能的位置，实际上是很多的矩形坐标。
+ 首先，我们使用这篇[论文](http://cs.brown.edu/~pff/segment/)的方法将图片初始化为很多小区域 $R={r\_i, …, r\_n}$。由于我们的重点是 Selective Search，因此我直接将该论文的算法当成一个黑盒子。
+ 初始化一个相似集合为空集： $S=\varnothing$。
+ 计算所有相邻区域之间的相似度（相似度函数之后会重点分析），放入集合 S 中，集合 S 保存的其实是一个区域对以及它们之间的相似度。
+ 找出 S 中相似度最高的区域，将它们合并，并从 S 中删除与它们相关的所有相似度。重新计算这个新区域与周围区域的相似度，放入集合 S 中，并将这个新合并的区域放入集合 R 中。重复这个步骤直到 S 为空。
+ 从 R 中找出所有区域的 bounding box（即包围该区域的最小矩形框），这些 box 就是物体可能的区域。

另外，为了提高速度，新合并区域的 feature 可以通过之前的两个区域获得，而不必重新遍历新区域的像素点进行计算。这个 feature 会被用于计算相似度。

### 相似度计算方法

相似度计算方法将直接影响合并区域的顺序，进而影响到检测结果的好坏。

正如一开始提出的那样，我们需要综合多种信息来判断。论文中，作者将相似度度量公式分为四个部分：

#### 互补色空间(Complementary Color Spaces)



### 参考

+ [Selective Search for Object Recognition(阅读)](http://blog.csdn.net/langb2014/article/details/52575507)
+ [Efficient Graph-Based Image Segmentation](http://cs.brown.edu/~pff/segment/)