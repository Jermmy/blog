---
title: 线性代数中的重要矩阵
date: 2017-04-03
tags: [线性代数]
categories: 线性代数
mathjax: true
---

老实说，我觉得线性代数可能是大学里最重要的数学，没有之一。无论是机器学习、计算机视觉，抑或是计算机图形学等等，都需要靠线性代数这门工具作支撑。这篇文章主要总结一下线性代数中那些很重要的矩阵们。

<!--more-->

### 单位正交矩阵(orthonormal matrix)
单位正交矩阵，顾名思义，就是矩阵的列由两两相互正交的单位向量组成。用数学语言表达为（以 3 * 3 得矩阵为例）：
$$
U=\begin{bmatrix} \mathbf u1 & \mathbf u2 & \mathbf u_3 \end{bmatrix}
$$
其中，$\mathbf u_1^T\mathbf u_2=\mathbf u_2^T\mathbf u_1=0$，$\mathbf u_1^T\mathbf u_3=\mathbf u_3^T\mathbf u_1=0$，$\mathbf u_2^T\mathbf u_3=\mathbf u_3^T\mathbf u_2=0$，
并且，$\mathbf u_1^T\mathbf u_1=1, \mathbf u_2^T\mathbf u_2=1, \mathbf u_3^T\mathbf u_3=1$。

（如果观察细致，你就会发现，这个矩阵的列向量其实是可以张成一个 $R^3$ 空间的基。）
这个矩阵有什么用处呢？它隐藏着一个很重要的性质：$U^TU=I$。这个性质的证明也很简单，如下所示：

$U^TU=\begin{bmatrix} \mathbf u_1^T \\\\ \mathbf u_2^T \\\\ \mathbf u_3^T \end{bmatrix} \begin{bmatrix} \mathbf u_1 &  \mathbf u_2 &  \mathbf u_3  \end{bmatrix}$

$=\begin{bmatrix} \mathbf u_1^T\mathbf u_1 & \mathbf u_1^T\mathbf u_2 & \mathbf u_1^T\mathbf u_3 \\\\ \mathbf u_2^T\mathbf u_1 & \mathbf u_2^T\mathbf u_2 & \mathbf u_2^T\mathbf u_3 \\\\ \mathbf u_3^T\mathbf u_1 & \mathbf u_3^T\mathbf u_2 & \mathbf u_3^T\mathbf u_3  \end{bmatrix}$

结合前面的数学定义，很容易得到：$U^TU=I$
这个性质和我们熟悉的可逆矩阵的性质很类似。事实上，如果 **$U$ 同时是个方阵**，那么，由可逆矩阵的性质，我们可以断定：**$U$ 是可逆的，并且 $U^{-1}=U^T$**（由 $U^TU=I=U^{-1}U$ 也可以间接推出来）。而且另一个很重要的性质是：**在这种情况下，$U$ 的行向量也是单位正交向量**。
这个性质对我们来说很有帮助，因为求逆矩阵是一个计算量较大的工作，而求矩阵的转置就容易得多。因此，如果我们知道矩阵是一个单位正交矩阵，就可以利用它的转置轻松求出矩阵的逆。