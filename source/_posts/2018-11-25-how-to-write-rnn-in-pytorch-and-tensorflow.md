---
title: RNN，写起来真的烦
date: 2018-11-25 17:49:42
tags: [深度学习, pytorch, tensorflow, nlp]
categories: NLP
mathjax: true
---

曾经，为了处理一些序列相关的数据，我稍微了解了一点递归网络 (RNN) 的东西。由于那个时候只会 tensorflow，当时就从官网上找了一些 tensorflow 相关的 demo，中间陆陆续续折腾了两个多星期，才对 squence to sequence，sequence classification 这些常见的模型和代码有了一些肤浅的认识。虽然只是多了**时间**这个维度，但 RNN 相关的东西，不仅是模型搭建上，在数据处理方面的繁琐程度也比 CNN 要高一个 level。另外，我也是从那个时候开始对 tensorflow 产生抵触心理，在 tf 中，你知道 RNN 有几种写法吗？你知道 dynamic_rnn 和 static_rnn 有什么区别吗？各种纷繁复杂的概念无疑加大了初学者的门槛。后来我花了一两天的时间转向 pytorch 后，感觉整个世界瞬间清净了 (当然了，学 tf 的好处就是转其他框架的时候非常快，但从其他框架转 TF 却可能生不如死)。pytorch 在模型搭建和数据处理方面都非常好上手，比起 tf 而言，代码写起来更加的整洁干净，而且开发人员更容易理解代码的运作流程。不过，在 RNN 这个问题上，新手还是容易犯嘀咕。趁着这一周刚刚摸清了 pytorch 搭建 RNN 的套路，我准备记录一下用 pytorch 搭建 RNN 的基本流程，以及数据处理方面要注意的问题，希望后来的同学们少流点血泪...

至于 tf 怎么写 RNN，之后有闲再补上 (我现在是真的不想回去碰那颗烫手的山芋😩)

<center>
    <img src="images/2018-11-25/rnn.png">
</center>



<!--more-->

## 什么是 RNN

虽然说我们用的是 API，但对于 RNN 是什么东西还是得了解一下吧。对于从没接触过 RNN 的小白来说，**karpathy** 这篇家喻户晓的[文章](https://karpathy.github.io/2015/05/21/rnn-effectiveness/)是一定要读一下的，如果想更加形象地了解它的工作机制，可以搜一些**李宏毅**的深度学习教程。

RNN 其实也是一个普通的神经网络，只不过多了一个 hidden state 来保存历史信息。跟一般网络不同的是，RNN 网络的输入数据的维度通常是 $[batch\_size \times seq\_len \times input\_size ]$，它多了一个序列长度 $seq\_len$。每次，我们都是把样本的 $t$ 个时间序列的信息不断输入同一个网络 (见题图)，因为是重复地使用同一个网络，所以称为递归网络。

关于 RNN，你只需要记住一个公式：$h_t = \tanh(w_{ih} x_t + b_{ih}  +  w_{hh} h_{(t-1)} + b_{hh})$。这也是 pytorch 官方文档中给出的最原始的 RNN 公式，其中 $w_{*}$ 表示 weight，$b_{*}$ 表示 bias。回忆一下，普通的神经网络只有 $w_{ih} x_t + b_{ih}$ 这一部分，而 RNN 无非就是多加了一个隐藏状态的信息 $w_{hh} h_{(t-1)} + b_{hh}$ 而已。

普通网络都是一次前向传播就得到结果，而 RNN 因为多了 sequence 这个维度，所以需要跑 n 次前向。我们用 numpy 的写法把 RNN 的工作流程总结一下，就得到了如下代码 (部分抄自 **karpathy** 的文章)：

```python
# 这里要啰嗦一句，karpathy在RNN的前向中还计算了一个输出向量output vector，但根据RNN的原始公式，它的输出只有一个hidden state，至于整个网络最后的output vector，是在 hidden state之后再接一个全连接层得到的，所以并不属于RNN的内容。包括pytorch和tf框架中，RNN的输出也只有hidden state。理解这一点很重要。
class RNN:
  # ...
  def step(self, x, hidden):
    # update the hidden state
    hidden = np.tanh(np.dot(self.W_hh, hidden) + np.dot(self.W_xh, x))
    return hidden

rnn = RNN()
# x: [batch_size * seq_len * input_size]
x = get_data()
seq_len = x.shape[1]
# 初始化一个hidden state，RNN中的参数没有包括hidden state，只包括hidden state对应的权重W和b，所以一般需要我们手动初始化一个全零的hidden state
hidden_state = np.zeros()
# 下面这个循环就是RNN的工作流程了，看到没有，每次输入的都是一个时间步长的数据，然后同一个hidden_state会在循环中反复输入到网络中。
for i in range(seq_len):
    hidden_state = rnn(x[:, i, :], hidden_state)
```

一定要看懂上面的代码再往下读呀。

## pytorch 中的 RNN



## 参考

+ [tensor flow dynamic_rnn 与rnn有啥区别？](https://www.zhihu.com/question/52200883)
+ [pytorch官方文档](https://pytorch.org/docs/stable/nn.html#torch.nn.RNN)
+ [读PyTorch源码学习RNN（1）](https://zhuanlan.zhihu.com/p/32103001)
+ [why do we “pack” the sequences in pytorch?](https://stackoverflow.com/questions/51030782/why-do-we-pack-the-sequences-in-pytorch)
+ [pytorch对可变长度序列的处理](https://www.cnblogs.com/lindaxin/p/8052043.html)
+ [The Unreasonable Effectiveness of Recurrent Neural Networks](https://karpathy.github.io/2015/05/21/rnn-effectiveness/)
+ [Understanding LSTM Networks](https://colah.github.io/posts/2015-08-Understanding-LSTMs/)