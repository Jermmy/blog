---
title: 论文笔记：Cross-Domain Visual Matching via Generalized Similarity Measure and Feature Learning
date: 2017-12-12 23:34:00
tags: [深度学习, 计算机视觉, 论文]
categories: 计算机视觉
mathjax: true
---

Cross-Domain Visual Matching，即跨域视觉匹配。所谓跨域，指的是数据的分布不一样，简单点说，就是两种数据「看起来」不像。如下图中，（a）一般的正面照片和各种背景角度下拍摄的照片；（b）摄像头不同角度下拍到的照片；（c）年轻和年老时的人脸照；（d）证件照和草图风格的人脸照，这些图像都存在对应关系，但由于它们属于不同的域，因此必须针对不同的域采用不同的特征提取方法，之后再做特征匹配。这篇论文提出用一种通用的相似模型来匹配两个域之间的特征，并将其和特征提取流程融合在一起，统一成一个 end-to-end 的框架。

<center>

<img src="/images/2017-12-12/cross-domain.png" width="400px">

</center>

<!--more-->

### 论文动机

针对这种跨域图片检索，常用的方法是：先用深度学习方法提取出不同域之间的特征，然后选择一种相似度模型来度量特征之间的相似性，并以此作为网络的代价函数来训练网络参数。如下图就是一种很常用的 Siamese 网络结构：

<center>

<img src="/images/2017-12-12/siamese.png" width="400px">

</center>

这里说的相似模型可以是欧氏距离、余弦相似度等等。但很多时候，我们并不知道哪种相似度模型最合适。这篇论文提出了一种通用的相似度模型——一种 Affine 变换。它表明，很多相似模型都可以用这个统一的模型来表示，而这个通用的模型也可以认为是多种相似模型的综合。因此，我们与其纠结选择哪种相似度模型，不如让网络自己学习出这个通用模型的参数，让网络自己选择最适合的模型。本文的另一个贡献在于将特征的提取与相似模型的学习融合进一个统一的框架内。

### 论文方法

#### 通用的相似模型

论文认为，大多数相似模型都可以归纳为如下形式：
$$
\begin{align}
S(\mathbf{x}, \mathbf{y})=\begin{bmatrix}\mathbf{x}^T & \mathbf{y}^T & 1  \end{bmatrix} \begin{bmatrix} \mathbf{A} & \mathbf{C} & \mathbf{d} \\ \mathbf{C}^T & \mathbf{B} & \mathbf{e} \\ \mathbf{d}^T & \mathbf{e}^T & f \end{bmatrix} \begin{bmatrix} \mathbf{x} \\ \mathbf{y} \\ 1 \end{bmatrix}  \tag{1}
\end{align}
$$
其中，我们限制 $\mathbf{A}$、$\mathbf{B}$ 为半正定矩阵，表示同域内的自相关性，$\mathbf{C}$ 为两个域之间的协方差矩阵。根据半正定矩阵的性质以及 $\mathbf(C)$ 的对称性，我们可以将 $\mathbf{A}$、$\mathbf{B}$、$\mathbf{C}$ 表示为：
$$
\begin{align}
\mathbf{A}=\mathbf{L_A}^T \mathbf{L_A} \notag \\
\mathbf{B}=\mathbf{L_B}^T \mathbf{L_B}  \tag{2} \\
\mathbf{C}=-\mathbf{L_C^x}^T\mathbf{L_C^y}  \notag
\end{align}
$$
这样，(1) 式可以展开为：
$$
\begin{align}
\tilde{S}(\mathbf{x},\mathbf{y})&=S(\mathbf{f_1}(\mathbf{x}), \mathbf{f_2}(\mathbf{y})) \notag \\
=&
\begin{bmatrix} \mathbf{f_1}(\mathbf{x})^T & \mathbf{f_2}(\mathbf{y})^T & 1 \end{bmatrix} 
\begin{bmatrix} \mathbf{A} & \mathbf{C} & \mathbf{d} \\ \mathbf{C}^T & \mathbf{B} & \mathbf{e} \\ \mathbf{d}^T & \mathbf{e}^T & f \end{bmatrix} 
\begin{bmatrix} \mathbf{f_1}(\mathbf{x}) \\ \mathbf{f_2}(\mathbf{y}) \\ 1 \end{bmatrix} \tag{3} \\
=& \mathbf{f_1}(\mathbf{x})^T\mathbf{A}\mathbf{f_1}(\mathbf{x}) + \mathbf{f_1}(\mathbf{x})^T\mathbf{C}\mathbf{f_2}(\mathbf{y}) + \mathbf{f_1}(\mathbf{x})^T\mathbf{d} + \mathbf{f_2}(\mathbf{y})^T\mathbf{C}\mathbf{f_1}(\mathbf{x})  \notag \\
&+\mathbf{f_2}(\mathbf{y})^T\mathbf{B}\mathbf{f_2}(\mathbf{y}) + \mathbf{f_2}(\mathbf{y})^T\mathbf{e} + \mathbf{d}^T\mathbf{f_1}(\mathbf{x}) + \mathbf{e}^T\mathbf{f_2}(\mathbf{y}) + f  \notag \\
=&||\mathbf{L_A}\mathbf{f_1}(\mathbf{x})||^2+||\mathbf{L_B}\mathbf{f_2}(\mathbf{y})||^2+2\mathbf{d}^T\mathbf{f_1}(\mathbf{x}) \notag \\ 
& -2(\mathbf{L_C^x}\mathbf{f_1}(\mathbf{x}))^T(\mathbf{L_C^y}\mathbf{f_2}(\mathbf{y}))+2\mathbf{e}^T\mathbf{f_2}(\mathbf{y})+f \notag
\end{align}
$$
(3) 式中的 $\mathbf{f_1}(\mathbf{x})$ 和 $\mathbf{f_2}(\mathbf{y})$ 分别代表 $\mathbf{x}$、$\mathbf{y}$ 两个样本经过提取得到的向量。这样一来，我们就将半正定矩阵等限制引入到这个度量关系中。

接下来，我们考虑如何优化这个相似模型。

假设 $D=\{(\{\mathbf{x_i}, \mathbf{y_i}\}, \ell_i) \}_{i=1}^N$ 表示训练的数据集，$\{\mathbf{x_i}, \mathbf{y_i}\}$ 表示来自两个不同域的样本，$\ell_i$ 标记两个样本是否属于同一类，如果是同一类则记为 -1，否则为 1：
$$
\begin{align}
\ell_i=\ell(\mathbf{x_i}, \mathbf{y_i})=
\begin{cases} -1 & c(\mathbf{x})=c(\mathbf{y}) \\ 1 &  otherwise \end{cases} \tag{4}
\end{align}
$$
我们的目标是，当两个样本属于同一类时，相似度要小于 -1，否则大于 1：
$$
\begin{align}
\tilde{S}(\mathbf{x_i}, \mathbf{y_i})=\begin{cases} < -1 & if\ \ell_i=-1 \\ \ge 1 & otherwise \end{cases}  \tag{5}
\end{align}
$$
基于此，论文提出如下目标函数：
$$
\begin{align}
G(\mathbf{W}, \mathbf{\phi})=\sum_{i=1}^N{(1-\ell_i \tilde{S}(\mathbf{x_i}, \mathbf{y_i}))_+}+\Psi (\mathbf{W}, \mathbf{\phi}) \tag{6}
\end{align}
$$
其中，$\mathbf{W}, \mathbf{\phi}$ 分别表示网络参数和相似模型参数，$\mathbf{\phi}=(\mathbf{L_A},\mathbf{L_B},\mathbf{L_C^x},\mathbf{L_C^y},\mathbf{d},\mathbf{e},f)$，$\Psi(\mathbf{W}, \mathbf{\phi})$ 表示正则化项。

#### 特征学习与相似度融合

接下来要解决的是如何用一个框架将特征学习与相似模型融合在一起。论文采用如下网络结构：

<center>

<img src="/images/2017-12-12/network.png" width="600px">

</center>

首先，我们用两个子网络分支分别提取两个不同域的图片特征，然后用一个共享的网络将两种特征融合起来，最后再用两个子网络分支计算相似模型的参数。
接下来分析一下网络训练的流程。首先，我们将网络的输出结果记为：
$$
\begin{align} 
\tilde{x} \triangleq \begin{bmatrix} \mathbf{L_A f_1(x)} & \mathbf{L_C^x f_1(x)} & \mathbf{d}^T \mathbf{f_1(x)} \end{bmatrix}^T   \notag \\
\tilde{y} \triangleq \begin{bmatrix} \mathbf{L_B f_2(x)} & \mathbf{L_C^y f_2(y)} & \mathbf{e}^T \mathbf{f_2(y)} \end{bmatrix}^T \notag 
\end{align}
$$
为了将 $\tilde{x}$ 和 $\tilde{y}$ 代入 (3) 式，我们再引入三个辅助矩阵：
$$
\begin{align}
& \mathbf{P_1}=\begin{bmatrix} \mathbf{I}^{r \times r} & \mathbf{0}^{r \times (r+1)} \end{bmatrix}  \notag \\
& \mathbf{P_2}=\begin{bmatrix} \mathbf{0}^{r \times r} & \mathbf{I}^{r \times r} & \mathbf{0}^{r \times 1} \end{bmatrix} \notag \\
& \mathbf{P_3}=\begin{bmatrix} \mathbf{0}^{1 \times 2r} & 1^{1 \times 1} \end{bmatrix}^T \notag
\end{align}
$$
$r$ 表示网络输出的特征维度，即 $\mathbf{f_1}(\mathbf{x})$ 和 $\mathbf{f_2}(\mathbf{y})$ 的维度。

借助这三个矩阵，可以得到：$\mathbf{L_A}\mathbf{f_1}(\mathbf{x})=\mathbf{P_1}\tilde{x}$，$\mathbf{L_B}\mathbf{f_2}(\mathbf{y})=\mathbf{P_1}\tilde{y}$ 等。

然后我们可以把 (3) 式表示为：
$$
\begin{align}
\tilde{S}(x,y)=&(\mathbf{P_1} \tilde{x})^T\mathbf{P_1}\tilde{x}+(\mathbf{P_1} \tilde{y})^T\mathbf{P_1}\tilde{y} \notag \\
&-2(\mathbf{P_2}\tilde{x}^T)\mathbf{P_2}\tilde{y}+2\mathbf{P_3}^T\tilde{x}+2\mathbf{P_3}^T\tilde{y}+f \notag
\end{align}
$$
目标函数调整为：
$$
\begin{align}
G(\mathbf{W}, \mathbf{\phi}; D)
=&\sum_{i=1}^N{(1-\ell_i \tilde{S}(x_i,y_i))_+ + \Psi{(\mathbf{W}, \phi)}} \notag \\
=&\sum_{i=1}^N{\{1-\ell_i [(\mathbf{P_1}\tilde{x_i})^T\mathbf{P_1}\tilde{x_i} + (\mathbf{P_1}\tilde{y_i})^T\mathbf{P_1}\tilde{y_i}} - \notag \\
& {2(\mathbf{P_2 \tilde{x_i}})^T\mathbf{P_2}\tilde{y_i} + 2\mathbf{P_3}^T\tilde{x_i}+2\mathbf{P_3}^T\tilde{y_i}+f] \}}_+ + \Psi{(\mathbf{W}, \phi)}  \tag{13}
\end{align}
$$


#### 训练细节优化

值得注意的是，(13) 式是一种 sample-pair-based 的表示，每次计算目标函数的时候，我们需要生成很多的样本对，时间和空间的开销都比较大。所以，下一步是将它表示成 sample-based 的形式，这样我们可以用普通的 SGD 算法来优化目标函数。

对于$D$中的每一个样本对$\{\mathbf{x_i}, \mathbf{y_i}\}$，我们假设 $\mathbf{z}^{j_{i,1}}=\mathbf{x_i}$，$\mathbf{z}^{j_{i,2}}=\mathbf{y_i}$，其中，$1 \le j_{i,1} \le M_x$，$M_x+1 \le j_{i,2} \le M_z(=M_x+M_y)$，$M_x$ 是样本 $\mathbf{x}$ 的数量，$M_y$ 是样本 $\mathbf{y}$ 的数量。同理，$\tilde{\mathbf{z}}^{j_{i,1}}=\tilde{\mathbf{x_i}}$，$\tilde{\mathbf{z}}^{j_{i,2}}=\tilde{\mathbf{y_i}}$。
然后，我们可以将 (13) 式改写成 sample-based 的形式：
$$
\begin{align}
G(\Omega;Z)=&L(\Omega;Z)+\Psi(\Omega) \notag \\
=& \sum_{i=1}^N{\{1-\ell_i [(\mathbf{P_1} \tilde{\mathbf{z}}^{j_{i,1}})^T \mathbf{P_1}\tilde{\mathbf{z}}^{j_{i,1}} + (\mathbf{P_1} \tilde{\mathbf{z}}^{j_{i,2}})^T \mathbf{P_1}\tilde{\mathbf{z}}^{j_{i,2}}} \notag \\
& {-2(\mathbf{P_2}\tilde{\mathbf{z}}^{j_{i,1}})^T\mathbf{P_2}\tilde{\mathbf{z}}^{j_{i,2}} + 2\mathbf{P_3}^T\tilde{\mathbf{z}}^{j_{i,1}} + 2\mathbf{P_3}^T\tilde{\mathbf{z}}^{j_{i,2}} + f] \}}_+ \notag \\
& + \Psi(\Omega)  \tag{14}
\end{align}
$$
其中，$\Omega=(\mathbf{W}, \phi)$。
梯度下降的导数为：
$$
\Omega=\Omega - \alpha \frac{\partial G(\Omega)}{\partial \Omega}=\Omega - \alpha ( \frac{\partial L(\Omega)}{\Omega} + \frac{\partial \Psi}{\partial \Omega})
$$
其中，$\alpha$ 是学习率。
这里的重点是要计算 $\frac{\partial L(\Omega)}{\partial \Omega}$：
$$
\frac{\partial L(\Omega)}{\partial \Omega}=\sum_j{\frac{\partial L}{\partial \tilde{\mathbf{z}}^j}\frac{\partial \tilde{\mathbf{z}}^j}{\partial \Omega}}
$$
由于存在两个子网络分支，上式中，$\tilde{\mathbf{z}}^j=\tilde{\mathbf{z}}^{j_{i,x}}$ 或 $\tilde{\mathbf{z}}^j=\tilde{\mathbf{z}}^{j_{i,y}}$，$\frac{\partial \tilde{\mathbf{z}}^j}{\partial \Omega}$
分别对应两个网络分支的导数（论文中 $\tilde{\mathbf{z}}^{j_{i,x}}$、$\tilde{\mathbf{z}}^{j_{i,y}}$ 和 (14) 式中的 $\tilde{\mathbf{z}}^{j_{i,1}}$、$\tilde{\mathbf{z}}^{j_{i,2}}$ 等符号混用了）。在梯度下降中，我们需要针对两个网络分支计算两次导数。
对处理 $\mathbf{x}$ 的分支，计算得到：
$$
\begin{align}
\frac{\partial L}{\partial \tilde{\mathbf{z}}^{j_{i,x}}}=-\sum_{j_{i,y}}{2\ell_{j_{i,x},j_{i,y}} (\mathbf{P_1}^T\mathbf{P_1}\tilde{\mathbf{z}}^{j_{i,x}}-\mathbf{P_2}^T\mathbf{P_2}\tilde{\mathbf{z}}^{j_{i,y}}+\mathbf{P_3})} \notag 
\end{align}
$$
这里的 $\ell_{j_{i,x},j_{i,y}}$ 就是 (4) 式中定义的 $\ell(\mathbf{x_i}, \mathbf{y_i})$。
另外，有些样本可能已经具备一定的区分度了，因此训练时要剔除这些样本。论文中引入一个标识函数 $\mathbf{1}_{\mathbf{z}^{j_{i,x}}}(\mathbf{z}^{j_{i,y}})$，当 $\ell_{j_{i,x},j_{i,y}}\tilde{S}(\mathbf{z}^{j_{i,x}},\mathbf{z}^{j_{i,y}})<1$ 时「由 (5) 式可知，此时 $(\mathbf{z}^{j_{i,x}},\mathbf{z}^{j_{i,y}})$ 还达不到要求的区分度」，$\mathbf{1}_{\mathbf{z}^{j_{i,x}}}(\mathbf{z}^{j_{i,y}})=1$，否则为 0。于是，得到最终的导数公式：
$$
\frac{\partial L}{\partial \tilde{\mathbf{z}}^{j_{i,x}}}=-\sum_{j_{i,y}}{2\mathbf{1}_{\mathbf{z}^{j_{i,x}}}(\mathbf{z}^{j_{i,y}})\ell_{j_{i,x},j_{i,y}} (\mathbf{P_1}^T\mathbf{P_1}\tilde{\mathbf{z}}^{j_{i,x}}-\mathbf{P_2}^T\mathbf{P_2}\tilde{\mathbf{z}}^{j_{i,y}}+\mathbf{P_3})} \tag{18}
$$
对于另一个分支，我们可以用同样的方法计算 $\frac{\partial L}{\partial \tilde{\mathbf{z}}^{j_{i,y}}}$。



### 参考

+ [Cross-Domain Visual Matching via Generalized Similarity Measure and Feature Learning](https://arxiv.org/abs/1605.04039)