---
title: 读书笔记：neuralnetworksanddeeplearning chapter1
date: 2017-05-13 14:41:53
tags: [深度学习]
categories: 深度学习
mathjax: true
---

(本文是根据 [neuralnetworksanddeeplearning](http://neuralnetworksanddeeplearning.com/index.html) 这本书的第一章 [Using neural nets to recognize handwritten digits](http://neuralnetworksanddeeplearning.com/chap1.html) 整理而成的读书笔记，根据个人口味做了删减)

对于人类来说，识别下面的数字易如反掌，但对计算机而言，却不是一个简单的任务。

![digits](/images/2017-5-13/digits.png)

在我们的大脑中，有一块跟视觉相关的皮层 V1，这里面包含着数以百万计的神经元，而这些神经元之间的连接，更是达到了数以亿计。在漫长的进化过程中，大自然将人类的大脑训练成了一个「超级计算机」，使它可以轻易地读懂、看懂、听懂很多目前的计算机仍然难以处理的问题。在本章中，作者介绍了一种可以帮助计算机识别手写体的程序：神经网络「neural network」。

<!--more-->

首先，我们从神经网络的几个基本概念讲起。

### Perceptrons

Perceptrons，中文译为**感知器**，最早由科学家[Frank Rosenblatt](http://en.wikipedia.org/wiki/Frank_Rosenblatt)于上个世纪 50 至 60 年代提出。在现代神经网络中，Perceptrons 已经用得很少了（更多地使用 sigmoid neuron 等神经元模型）。但要了解 sigmoid neuron 怎么来的，就有必要先弄清楚 Perceptrons。

举例来说，最简单的 Perceptrons 类似如下结构：

![tikz0](/images/2017-5-13/tikz0.png)

它接受三个输入 $x\_1$、$x\_2$、$x\_3$，输出 0 或者 1。为了衡量每个输入的重要程度，Rosenblatt 引入了权重的概念，假设 $w\_1$、$w\_2$、$w\_3$ 分别对应 $x\_1$、$x\_2$、$x\_3$，那么，我们可以得到 Perceptrons 的输出为：
$$
output=\begin{cases} 0 &if \ \ \sum_{j}{w_j x_j} <= threshold \\
1 &if \ \ \sum_{j}{w_jx_j} > threshold
 \end{cases} 
$$
当然，Perceptrons 在处理较复杂的任务的时候，其结构也会更加复杂，比如：

![tikz1](/images/2017-5-13/tikz1.png)

在这个网络中，Perceptrons 的第一列称为第一层 (first layer)，这一层的感知器接受三个输入 (evidence) 来决定输出。Perceptrons 的第二层，则以第一层的输出结果作为输入来产生最后的输出，因此第二层可以认为是在处理比第一层更加复杂抽象的工作。

为了简化数学表达，我们将 $\sum\_{j}{w\_jx\_j}$ 表示成 $WX$，$W$、$X$ 分别代表权重和输入的向量。同时，我们将阈值的负值 (-threshold) 表示成 bias，即 $b = -threshold$。这样，Perceptrons 的输出可以重写为：
$$
output=\begin{cases} 0 &if \ \ WX+b <= 0 \\ 1 &if \ \ WX+b > 0 \end{cases}.
$$

### Sigmoid neurons

现在，我们考虑一下如何训练 Perceptrons 的参数（W 和 b）。假设网络的参数发生了一点点**微小**的变化，为了训练过程的可控，网络的输出也应该发生**微小**的变化。

![tikz8](/images/2017-5-13/tikz8.png)

如果网络错误地将手写数字 **8** 分类为 **9**，那么我们希望在参数做一点点修改，网络的输出会更靠近 **9** 这个结果，只要数据量够多，这个修改的过程重复下去，最后网络的输出就会越来越正确，这样神经网络才能不断学习。

然而，对于 Perceptrons 来说，参数的微调却可能导致结果由 **0** 变为 **1**，然后导致后面的网络层发生连锁反应。换句话说，Perceptrons 的性质导致它的训练过程是相当难控制的。

为了克服这个问题，我们引入一种新的感知器 **sigmoid neuron**。它跟 Perceptrons 的结构一模一样，只是在输出结果时加上了一层 **sigmoid 函数**：$\sigma(z)=\frac{1}{1+e^(-z)}$。这样，网络的输出就变成了：
$$
output=\frac{1}{1+exp(WX+b)}
$$
sigmoid 函数的图像如下：

![sigmoid](/images/2017-5-13/sigmoid.png)

当 $WX+b$ 趋于 ∞ 的时候，函数值趋于 1，当 $WX+b$ 趋于 0 的时候，函数值趋于 0。在这种情况下，sigmoid neuron 就退化成 Perceptrons。

sigmoid 函数也可以看作是对 step 函数的平滑，step 函数如下：

![step function](/images/2017-5-13/step function.png)

可以看出，Perceptrons neuron 的本质就是 step 函数。

那么，为什么 sigmoid neuron 就比 Perceptrons 更容易训练呢？原因在于，sigmoid 函数是平滑、连续的，它不会发生 step 函数那种从 0 到 1 的突变。用数学的语言表达就是，参数微小的改变（$\Delta w\_j$、$\Delta b$）只会引起 output 的微小改变：$\Delta output \approx \sum\_j{\frac{\partial output}{\partial w\_j}\Delta w\_j}+\frac{\partial output}{\partial b}\Delta b$。可以发现，$\Delta output$ 和 $\Delta w\_j$、$\Delta b$ 是一个线性关系，这使得网络的训练更加可控。

事实上，正是 sigmoid 函数这种平滑的特性起了关键作用，而函数的具体形式则无关紧要。在本书后面的章节中，还会介绍其他函数来代替 sigmoid，这类函数有个学名叫**激活函数 (activation function)**。从数学上讲，函数平滑意味着函数在定义域内是可导的，而且导数有很好的数学特性（比如上面提到的线性关系），step 函数虽然分段可导，但它的导数值要么一直是 0，要么在突变点不可导，所以它不具备平滑性。

### Learning with gradient descent











































