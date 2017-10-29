---
title: 多维高斯分布
date: 2017-10-28 11:20:47
tags: [机器学习, 线性代数]
categories: 机器学习
mathjax: true
---

高中的时候我们便学过一维正态（高斯）分布的公式：
$$
N(x|u,\sigma^2)=\frac{1}{\sqrt{2\pi \sigma^2}}exp[-\frac{1}{2\sigma^2}(x-u)^2]
$$
拓展到高维时，就变成：
$$
N(\overline x | \overline u, \Sigma)=\frac{1}{(2\pi)^{D/2}}\frac{1}{|\Sigma|^{1/2}}exp[-\frac{1}{2}(\overline x-\overline u)^T\Sigma^{-1}(\overline x-\overline u)]
$$
其中，$\overline x$ 表示维度为 D 的向量，$\overline u$ 则是这些向量的平均值，$\Sigma$ 表示所有向量 $\overline x$ 的协方差矩阵。

本文只是想简单探讨一下，上面这个高维的公式是怎么来的。

<!--more-->

### 二维的情况

为了简单起见，本文假设所有变量都是相互独立的。即对于概率分布函数 $f(x_0,x_1,…,x_n)$ 而言，有 $f(x_0,x_1,…,x_n)=f(x_0)f(x_1)f(x_n)$ 成立。

现在，我们用一个二维的例子推出上面的公式。

假设有很多变量 $\overline x=\begin{bmatrix} x_1 \\ x_2 \end{bmatrix}$，它们的均值为 $\overline u=\begin{bmatrix} u_1 \\ u_2 \end{bmatrix}$，方差为 $\overline \sigma=\begin{bmatrix} \sigma_1 \\ \sigma_2 \end{bmatrix}$。

由于 $x_1$，$x_2$ 是相互独立的，所以，$\overline x$ 的高斯分布函数可以表示为：
$$
\begin{eqnarray}
f(\overline x) &=& f(x_1,x_2) \\
&=& f(x_1)f(x_2) \\
&=& \frac{1}{\sqrt{2\pi \sigma_1^2}}exp(-\frac{1}{2}(\frac{x_1-u_1}{\sigma_1})^2) \times \frac{1}{\sqrt{2\pi \sigma_2^2}}exp(-\frac{1}{2}(\frac{x_2-u_2}{\sigma_2})^2) \\
&=&\frac{1}{(2\pi)^{2/2}(\sigma_1^2 \sigma_2^2)^{1/2}}exp(-\frac{1}{2}[(\frac{x_1-u_1}{\sigma_1})^2+(\frac{x_2-u_2}{\sigma_2})^2])
\end{eqnarray}
$$
接下来，为了推出文章开篇的高维公式，我们要想办法得到协方差矩阵 $\Sigma$。

对于二维的向量 $\overline x$ 而言，其协方差矩阵为：
$$
\begin{eqnarray}
\Sigma&=&\begin{bmatrix}
\sigma_{11} & \sigma_{12} \\
\sigma_{12} & \sigma_{22}
\end{bmatrix} \\
&=&\begin{bmatrix}
\sigma_1^2 & \sigma_{12} \\
\sigma_{21} & \sigma_{2}^2
\end{bmatrix} \\
\end{eqnarray}
$$
(不熟悉协方差矩阵的请查找其他资料或翻看我之前的[文章](https://jermmy.github.io/2017/03/19/2017-3-19-covariance-matrix/))

由于 $x_1$，$x_2$ 是相互独立的，所以 $\sigma_{12}=\sigma_{21}=0$。这样，$\Sigma$ 退化成 $\begin{bmatrix} \sigma_1^2 & 0 \\ 0 & \sigma_{2}^2 \end{bmatrix}$。

则 $\Sigma$ 的行列式 $|\Sigma|=\sigma_1^2  \sigma_2^2$，代入公式 (4) 就可以得到：
$$
f(\overline x)=\frac{1}{(2\pi)^{2/2}|\Sigma|^{1/2}}exp(-\frac{1}{2}[(\frac{x_1-u_1}{\sigma_1})^2+(\frac{x_2-u_2}{\sigma_2})^2])
$$
这样一来，我们已经推出了公式的左半部分，下面，开始处理右面的 $exp$ 函数。

原始的高维高斯函数的 $exp$ 函数为：$exp[-\frac{1}{2}(\overline x-\overline u)^T\Sigma^{-1}(\overline x-\overline u)]$，根据前面算出来的 $\Sigma$，我们可以求出它的逆：$\Sigma^{-1}=\frac{1}{\sigma_1^2 \sigma_2^2} \begin{bmatrix} \sigma_2^2 & 0 \\ 0 & \sigma_1^2 \end{bmatrix}$。

接下来根据这个二维的例子，将原始的 $exp()$ 展开：
$$
\begin{eqnarray}
exp[-\frac{1}{2}(\overline x-\overline u)^T\Sigma^{-1}(\overline x-\overline u)] &=& exp[-\frac{1}{2} \begin{bmatrix} x_1-u_1  \ \ \  x_2-u_2 \end{bmatrix} \frac{1}{\sigma_1^2 \sigma_2^2} \begin{bmatrix} \sigma_2^2 & 0 \\ 0 & \sigma_1^2 \end{bmatrix}  \begin{bmatrix} x_1-u_1 \\  x_2-u_2 \end{bmatrix}] \\
&=&exp[-\frac{1}{2} \begin{bmatrix} x_1-u_1  \ \ \  x_2-u_2 \end{bmatrix} \frac{1}{\sigma_1^2 \sigma_2^2} \begin{bmatrix} \sigma_2^2(x_1-u_1) \\ \sigma_1^2(x_2-u_2) \end{bmatrix}] \\
&=&exp[-\frac{1}{2\sigma_1^2 \sigma_2^2}[\sigma_2^2(x_1-u_1)^2+\sigma_1^2(x_2-u_2)^2]] \\
&=&exp[-\frac{1}{2}[\frac{(x_1-u_1)^2}{\sigma_1^2}+\frac{(x_2-u_2)^2}{\sigma_2^2}]]
\end{eqnarray}
$$
展开到最后，发现推出了公式 (4)。说明原公式 $N(\overline x | \overline u, \Sigma)=\frac{1}{(2\pi)^{D/2}}\frac{1}{|\Sigma|^{1/2}}exp[-\frac{1}{2}(\overline x-\overline u)^T\Sigma^{-1}(\overline x-\overline u)]$ 是成立的。你也可以将上面展开的过程逆着推回去，一样可以从例子中的公式 (4) 推出多维高斯公式。

### 总结

本文只是从一个简单的二维例子出发，来说明多维高斯公式的来源。在 PRML 的书中，推导的过程更加全面，也复杂了许多，想深入学习多维高斯模型的还是参考教材为准。

重新对比一维和多维的公式：
$$
N(x|u,\sigma^2)=\frac{1}{\sqrt{2\pi \sigma^2}}exp[-\frac{1}{2\sigma^2}(x-u)^2]
$$

$$
N(\overline x | \overline u, \Sigma)=\frac{1}{(2\pi)^{D/2}}\frac{1}{|\Sigma|^{1/2}}exp[-\frac{1}{2}(\overline x-\overline u)^T\Sigma^{-1}(\overline x-\overline u)]
$$

其实二者是等价的。一维中，我们针对的是一个数，多维时，则是针对一个个向量求分布。如果向量退化成一维，则多维公式中的 $D=1$，$\Sigma=\sigma^2$，$\Sigma^{-1}=\frac{1}{\sigma^2}$，这时多维公式就退化成一维的公式。所以，在多维的公式中，我们可以把 $\Sigma$ 当作是样本向量的标准差。

### 参考

+ [协方差矩阵](https://jermmy.github.io/2017/03/19/2017-3-19-covariance-matrix/)