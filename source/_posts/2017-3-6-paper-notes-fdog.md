---
title: 论文笔记：Flow-Based Image Abstraction
date: 2017-03-06 22:21:20
tags: [paper, Computer Vision]
categories: [Computer Vision]
mathjax: true
---

### 概要

本文是对Henry Kang等人提出的**Flow-Based Image Abstraction**方法的总结。该方法采用NPR中经常用到的DoG算子，由于他们引入了在流方向进行卷积的思路，使得物体的形状线条可以很好地表现出来。

先上一张论文中的效果图：

![paper_result](/images/2017-3-6/paper_result.png)

图(e)是FDoG的效果，比起(d)普通DoG的做法，FDoG很好地表现出爱因斯坦的头发和抬头纹，而这种“线条美”正是FDoG的独特之处。

<!--more-->

<br\>

### FDoG流程分析

在进一步分析之前，需要先大致了解FDoG的总体流程：

![overview](/images/2017-3-6/overview.png)这几个骷髅头很好地揭示了FDoG执行过程中的几个关键部分。

作者把渲染过程分为边的提取和颜色提取两部分。其中，输入图片会和一个叫**Edge Tangent Flow**的东西一同作为下一步滤波的依据。滤波过程分为**Line drawing**和**Region smoothing**两部分（其实就是边缘滤波和颜色平滑），最后综合一下便得到一个线条感十足的骷髅头。

很明显，这里面最关键的三个步骤分别是：**Edge Tangent Flow**、**FDoG filtering**和**FBL filtering**。

#### Edge Tangent Flow

在我看来，**Edge Tangent Flow（ETF）**应该是整篇论文的点睛之笔。FDoG的这种流效果（线条美）全拜ETF所赐。

这篇文章中对ETF的描述部分，有些细节比较含糊，因此我更多的是参考原作者的另一篇文章**Coherent Line Drawing**去理解ETF的，这两篇文章本质上讲的是一个东西。

ETF，中文译为**边的正切流**，可以理解为曲线上每个点的切线方向。这些切线方向跟该点的梯度方向互相垂直，因此，这些切线方向其实就是边缘的方向。看图说话：

![etf](/images/2017-3-6/etf.png)

图中x这个点的梯度方向是穿过边缘的细线，而切线方向则是穿过x点的红线。

以上是我对ETF的感性理解，作者在论文中给出了更加复杂的方式来计算出所有点的这种流方向（为与论文一致，以下简称**流向量**）。

论文中给出了这种**流向量**应该满足的**三个特性**：

1. **流向量要能描述相邻区域的显著边缘的正切方向**；（抓住重要的边缘方向）
2. **出了尖锐的边角，相邻的流向量必须被平滑对齐**；（不重要的流方向要平滑掉）
3. **重要的边必须保持它们原本的方向**。（重要的流方向要保留）


为了达到这三个特性，作者提出一种类似双边滤波的方法，使用基于核函数的非线性滤波来计算每个点的流向量(kernel-based nonlinear smoothing)。在对每个像素点进行卷积运算的时候，重要的边缘方向会被保留，而弱的边缘则会被相邻的强边缘引导同化。

为了表述方便，下面引入一些数学符号：

**I(x)**：原图像；

**t(x)**：与图像梯度垂直的向量，即流向量；

**g(x)**：图像梯度向量，∇**I(x)**，分为x、y两个方向；

g(x)：归一化的图像梯度大小，梯度计算公式为：$\sqrt{({∂f(x) \over ∂x})^2 + ({∂f(x) \over ∂y})^2}$，至于怎么归一化，作者没说；

好了，接下来要引入本文的“重磅炸弹”，ETF的计算公式：
$$
\mathbf t^{new}( \mathbf x)={1 \over k} \sum_{y \in {\Omega(\mathbf x)}} { {\phi(\mathbf x, \mathbf y)} {\mathbf t^{cur}(\mathbf y)} {w_s(\mathbf x, \mathbf y)} {w_m(\mathbf x, \mathbf y)} {w_d(\mathbf x, \mathbf y)} }
$$
需要注意的是，ETF其实是一个迭代的过程，因此$\mathbf t^{new}$表示新的向量，$\mathbf t^{cur}$表示旧的向量。关于迭代后面会细讲。

下面分解一下这个令人望而生畏的公式：

1. $\Omega(x)$表示核函数的大小，也就是卷积的大小；

2. $\phi(\mathbf x, \mathbf y)$表示方向因子：
   $$
   \phi(\mathbf x, \mathbf y) = \begin{cases} 1 &if \ \  \mathbf t^{cur}(\mathbf x) \mathbf t^{cur}(\mathbf y) > 0  \\\\ -1 &otherwise \end{cases}
   $$
   论文解释说，如果当前点的流向量与邻居点的流向量方向相反（大于90度），可以通过这个式子将邻居点的流方向旋转为与当前点一致；

3. $w_s(\mathbf x, \mathbf y)$是一个半径为r的盒子过滤器，r是核的大小，简而言之就是确定卷积大小
   $$
   w_s(\mathbf x, \mathbf y)=\begin{cases} 1 &if \ \ ||\mathbf x-\mathbf y|| < r \\\\ 0 & otherwise. \end{cases}
   $$

4. $w_m(\mathbf x, \mathbf y)$对特征的保留起到关键作用，论文中称为**magnitude weight function**：
   $$
   w_m(\mathbf x, \mathbf y)= {1 \over 2}(1+tanh[\eta (g(\mathbf y)-g(\mathbf x))])
   $$
   其中，g(z)如上所述，表示z点的归一化的梯度大小。$\eta$的值论文中取1；

5. $w_d(\mathbf x, \mathbf y)$被称为**directional weight function**，同样是关键函数：
   $$
   w_d(\mathbf x, \mathbf y)=|\mathbf t^{cur}(\mathbf x) \mathbf t^{cur}(\mathbf y)|
   $$
   其中，$\mathbf t^{cur}(z)$表示z这个点的归一化流向量；

6. 最前面那个k是归一化参数，也就是上面这些权重之和。

扯完一堆公式之后，接下来要品味一下ETF的迭代流程。

对于初始向量$\mathbf t^{0}(\mathbf x)$，论文中采用与梯度向量**g(x)**垂直的向量作为初始值。**g(x)**直接通过Sobel算子计算得到。在正式使用前，需要将$\mathbf t^{0}(\mathbf x)$归一化。之后，便按照上面的公式进行迭代：$\mathbf t^{i}(\mathbf x)$➝$\mathbf t^{i+1}(\mathbf x)$。需要注意的是，在迭代过程中，**g(x)**也会不断更新，但g(x)保持不变。












​		
​	