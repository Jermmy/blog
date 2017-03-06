---
title: 论文笔记：Flow-Based Image Abstraction
date: 2017-03-06 22:21:20
tags: [NPR, paper]
categories: NPR
mathjax: true
---

### 概要

本文是对Henry Kang等人提出的**Flow-Based Image Abstraction**方法的总结。该方法采用NPR中经常用到的DoG算子，由于他们引入了在流方向进行卷积的思路，使得物体的形状线条可以很好地表现出来。

先上一张论文中的效果图：

![paper_result](/Users/xyz/GitCode/jermmy.github.io/source/images/2017-3-6/paper_result.png)

图(e)是FDoG的效果，比起(d)普通DoG的做法，FDoG很好地表现出爱因斯坦的头发和抬头纹，而这种“线条美”正是FDoG的独特之处。

<!--more-->

<br\>

### FDoG流程分析

在进一步分析之前，需要先大致了解FDoG的总体流程：

![overview](/Users/xyz/GitCode/jermmy.github.io/source/images/2017-3-6/overview.png)这几个骷髅头很好地揭示了FDoG执行过程中的几个关键部分。

作者把渲染过程分为边的提取和颜色提取两部分。其中，输入图片会和一个叫**Edge Tangent Flow**的东西一同作为下一步滤波的依据。滤波过程分为**Line drawing**和**Region smoothing**两部分（其实就是边缘滤波和颜色平滑），最后综合一下便得到一个线条感十足的骷髅头。

很明显，这里面最关键的三个步骤分别是：**Edge Tangent Flow**、**FDoG filtering**和**FBL filtering**。

#### Edge Tangent Flow

在我看来，**Edge Tangent Flow（ETF）**应该是整篇论文的点睛之笔。FDoG的这种流效果（线条美）全拜ETF所赐。

这篇文章中对ETF的描述部分，有些细节比较含糊，因此我更多的是参考原作者的另一篇文章去理解ETF的，这两篇文章本质上讲的是一个东西。

ETF，中文译为**边的正切流**，可以理解为曲线上每个点的切线方向。这些切线方向跟该点的梯度方向互相垂直，因此，这些切线方向其实就是边缘的方向。看图说话：

![etf](/Users/xyz/GitCode/jermmy.github.io/source/images/2017-3-6/etf.png)

图中x这个点的梯度方向是穿过边缘的细线，而切线方向则是穿过x点的红线。

以上是我对ETF的感性理解，作者在论文中给出了更加复杂的方式来计算出所有点的这种流方向（为与论文一致，以下简称**流向量**）。

论文中给出了这种**流向量**应该满足的**三个特性**：

1. **流向量要能描述相邻区域的显著边缘的正切方向**；（抓住重要的边缘方向）
2. **出了尖锐的边角，相邻的流向量必须被平滑对齐**；（不重要的流方向要平滑掉）
3. **重要的边必须保持它们原本的方向**。（重要的流方向要保留）













​		
​	