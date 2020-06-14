---
title: 神经网络量化入门--基本原理
date: 2020-06-13 19:47:47
tags: [计算机视觉, 深度学习]
categories: 深度学习
mathjax: true
---

最近打算写一个关于神经网络量化的入门教程，包括网络量化的基本原理、离线量化、量化训练，以及全量化模型的推理过程，最后我会用 pytorch 从零构建一个量化模型，帮助读者形成更深刻的理解。

之所以要写这系列教程，主要是想帮助初次接触量化的同学快速入门。笔者在刚开始接触模型量化时走了很多弯路，并且发现网上的资料和论文对初学者来说太不友好。目前学术界的量化方法都过于花俏，能落地的极少，工业界广泛使用的还是 Google TFLite 那一套量化方法，而 TFLite 对应的大部分资料都只告诉你如何使用，能讲清楚原理的也非常少。这系列教程不会涉及学术上那些花俏的量化方法，主要是想介绍工业界用得最多的量化方案 (即 TFLite 的量化原理，对应 Google 的论文 [Quantization and Training of Neural Networks for Efficient Integer-Arithmetic-Only Inference](https://arxiv.org/abs/1712.05877) )

话不多说，我们开始。这一章中，主要介绍网络量化的基本原理，以及推理的时候如何跑量化模型。

<!--more-->

## 背景知识

量化并不是什么新知识，我们在对图像做预处理时就用到了量化。回想一下，我们通常会将一张 uint8 类型、数值范围在 0~255 的图片归一成 float32 类型、数值范围在 0.0~1.0 的张量，这个过程就是**反量化**。类似地，我们经常将网络输出的范围在 0.0~1.0 之间的张量调整成数值为 0~255、uint8 类型的图片数据，这个过程就是**量化**。所以量化本质上只是对数值范围的重新调整，可以「粗略」理解为是一种线性映射。(之所以加「粗略」二字，是因为有些论文会用非线性量化，但目前在工业界落地的还都是线性量化，所以本文只讨论线性量化的方案)。

不过，可以明显看出，反量化一般没有信息损失，而量化一般都会有精度损失。这也非常好理解，float32 能保存的数值范围本身就比 uint8 多，因此必定有大量数值无法用 uint8 表示，只能四舍五入成 uint8 型的数值。量化模型和全精度模型的误差也来自四舍五入的 clip 操作。

这篇文章中会用到一些公式，这里我们用 $r$ 表示浮点实数，$q$ 表示量化后的定点整数。浮点和整型之间的换算公式为：
$$
r = S(q-Z) \tag{1}
$$

$$
q = round(\frac{r}{S}+Z) \tag{2}
$$



其中，$S$ 是 scale，表示实数和整数之间的比例关系，$Z$ 是 zero point，表示实数中的 0 经过量化后对应的整数，它们的计算方法为：
$$
S = \frac{r_{max}-r_{min}}{q_{max}-q_{min}} \tag{3}
$$

$$
Z = round(q_{max} - \frac{r_{max}}{S}) \tag{4}
$$

$r_{max}$、$r_{min}$分别是 $r$ 的最大值和最小值，$q_{min}$、$q_{max}$同理。这个公式的推导比较简单，很多资料也有详细的介绍，这里不过多介绍。需要强调的一点是，定点整数的 zero point 就代表浮点实数的 0，二者之间的换算不存在精度损失，这一点可以从公式 (2) 中看出来，把 $r=0$ 代入后就可以得到 $q=Z$。这么做的目的是为了在 padding 时保证浮点数值的 0 和定点整数的 zero point 完全等价，保证定点和浮点之间的表征能够一致。

## 矩阵运算的量化

由于卷积网络中的卷积层和全连接层本质上都是一堆矩阵乘法，因此我们先看如何将浮点运算上的矩阵转换为定点运算。

假设 $r_1$、$r_2$ 是浮点实数上的两个 $N \times N$ 的矩阵，$r_3$ 是 $r_1$、$r_2$ 相乘后的矩阵：
$$
r_3^{i,k}=\sum_{j=1}^N r_1^{i,j}r_2^{j,k} \tag{5}
$$
假设 $S_1$、$Z_1$ 是 $r_1$ 矩阵对应的 scale 和 zero point，$S_2$、$Z_2$、$S_3$、$Z_3$同理，那么由 (5) 式可以推出：
$$
S_3(q_3^{i,k}-Z_3)=\sum_{j=1}^{N}S_1(q_{1}^{i,j}-Z_1)S_2(q_2^{j,k}-Z_2)
$$


##  参考

+ [神经网络量化简介](https://zhuanlan.zhihu.com/p/64744154)
+ [Building a quantization paradigm from first principles](https://github.com/google/gemmlowp/blob/master/doc/quantization.md#implementation-of-quantized-matrix-multiplication)
+ [Post Training Quantization General Questions](https://github.com/NervanaSystems/distiller/issues/327)
+ 

