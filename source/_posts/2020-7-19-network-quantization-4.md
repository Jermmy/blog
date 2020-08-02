---
title: 神经网络量化入门--BatchNorm Folding
date: 2020-07-19 14:38:47
tags: [深度学习]
categories: 深度学习
mathjax: true
---

上一篇[文章](http://jermmy.github.io/2020/07/11/2020-7-11-network-quantization-3/)介绍了量化训练的基本流程，本文介绍量化中如何在把 BatchNorm 和 ReLU 合并到 Conv 中。

<center>
  <img src="/images/2020-7-19/FoldBN.jpg" width="500px">
</center>

<!--more-->

## Folding BatchNorm

[BatchNorm](https://arxiv.org/abs/1502.03167) 是 Google 提出的一种加速神经网络训练的技术，在很多网络中基本是标配。

回忆一下，BatchNorm 其实就是在每一层输出的时候做了一遍归一化操作：

<center>
  <img src="/images/2020-7-19/bn_formulation.png" width="500px">
</center>

其中 $x_i$ 是网络中间某一层的激活值，$\mu_{\beta}$、$\sigma_{\beta}$ 分别是其均值和方差，$y_i$ 则是过了 BN 后的输出。

### 一般卷积层与BN合并

Folding BatchNorm 不是量化才有的操作，在一般的网络中，为了加速网络推理，我们也可以把 BN 合并到 Conv 中。

Folding 的过程是这样的，假设有一个已经训练好的 Conv 和 BN：

<center>
  <img src="/images/2020-7-19/conv_bn.png" width="500px">
</center>

假设 Conv 的 weight 和 bias 分别是 $w$ 和 $b$。那么卷积层的输出为：
$$
y=\sum_{i}^N w_i x_i + b \tag{1}
$$
图中 BN 层的均值和标准差可以表示为 $\mu_{y}$、$\sigma_{y}$，那么根据论文的表述，BN 层的输出为：
$$
\begin{align}
y_{bn}&=\gamma \hat{y}+\beta \\
&=\gamma \frac{y-\mu_y}{\sqrt{\sigma_y^2+\epsilon}}+\beta \tag{2}
\end{align}
$$
然后我们把 (1) 代入 (2) 中可以得到：
$$
y_{bn}=\frac{\gamma}{\sqrt{\sigma_y^2+\epsilon}}(\sum_{i}^N w_i x_i + b-\mu_y)+\beta \tag{3}
$$
我们用 $\gamma'$ 来表示 $\frac{\gamma}{\sqrt{\sigma_y^2+\epsilon}}$，那么 (3) 可以简化为：
$$
\begin{align}
y_{bn}&=\gamma'(\sum_{i}^Nw_ix_i+b-\mu_y)+\beta \\
&=\sum_{i}^N \gamma'w_ix_i+\gamma'(b-\mu_y)+\beta \tag{4}
\end{align}
$$
发现没有，(4) 式形式上跟 (1) 式一模一样，因此它本质上也是一个 Conv 运算，我们只需要用 $w_i'=\gamma'w_i$ 和 $b'=\gamma'(b-\mu_y)+\beta$ 来作为原来卷积的 weight 和 bias，就相当于把 BN 的操作合并到了 Conv 里面。实际 inference 的时候，由于 BN 层的参数已经固定了，因此可以把 BN 层 folding 到 Conv 里面，省去 BN 层的计算开销。

### 量化 BatchNorm Folding

量化网络时可以用同样的方法把 BN 合并到 Conv 中。

如果量化时不想更新 BN 的参数 (比如后训练量化)，那我们就先把 BN 合并到 Conv 中，直接量化新的 Conv 即可。

如果量化时需要更新 BN 的参数 (比如量化感知训练)，那也很好处理。Google 把这个流程的心法写在一张图上了：

<center>
  <img src="/images/2020-7-19/BN-quantize.png" width="300px">
</center>

由于实际 inference 的时候，BN 是 folding 到 Conv 中的，因此在量化训练的时候也需要模拟这个操作，得到新的 weight 和 bias，并用新的 Conv 估计量化误差来回传梯度。

## Conv与ReLU合并

在量化中，Conv + ReLU 这样的结构一般也是合并成一个 Conv 进行运算的，而这一点在全精度模型中则办不到。

在之前的[文章](https://jermmy.github.io/2020/06/13/2020-6-13-network-quantization-1/)中说过，ReLU 前后应该使用同一个 scale 和 zeropoint(zp)。这是因为 ReLU 本身没有做任何的数学运算，只是一个截断函数，如果使用不同的 scale 和 zp，会导致无法量化回 float 域。

举个例子。假设 ReLU 前的数值范围是 (-1, 1)，那么经过 ReLU 后的数值范围是 (0, 1)。假设量化到 uint8 类型，即 [0, 255]，那么 ReLU 前后的 scale 分别为 $\frac{2}{255}$、$\frac{1}{255}$，zp 分别为 128 和 0。 再假设 ReLU 前的浮点数是 0.5，那么经过 ReLU 后的值依然是 0.5。换算成整型的话，ReLU 前的整数是 192，由于 zp 为 128，因此过完 ReLU 后的数值依然是 192。但是，由于 ReLU 后的 scale 和 zeropoint 已经发生了变化，因此换算回 float 域后的数值不再是 0.5，而这不是我们想要的。所以，如果想要保证量化的 ReLU 和浮点型的 ReLU 之间的一致性，就必须保证前后的 scale 和 zp 是一样的。

但是保证 scale 和 zp 一样，没规定一定得用 ReLU 前的 scale 和 zp，我们一样可以用 ReLU 之后的 scale 和 zp。不过，使用哪一个 scale 和 zp，意义完全不一样。如果使用 ReLU 之后的 scale 和 zp，那我们就可以用量化本身的截断功能来实现 ReLU 的作用。

再举个例子，