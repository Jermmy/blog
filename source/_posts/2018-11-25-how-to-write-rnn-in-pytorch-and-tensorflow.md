---
title: RNN，写起来真的烦
date: 2018-11-25 17:49:42
tags: [深度学习, pytorch, tensorflow, nlp]
categories: NLP
mathjax: true
---

曾经，为了处理一些序列相关的数据，我稍微了解了一点递归网络 (RNN) 的东西。由于那个时候只会 tensorflow，当时就从官网上找了一些 tensorflow 相关的 demo，中间陆陆续续折腾了两个多星期，才对 squence to sequence，sequence classification 这些常见的模型和代码有了一些肤浅的认识。虽然只是多了**时间**这个维度，但 RNN 相关的东西，不仅是模型搭建上，在数据处理方面的繁琐程度也比 CNN 要高一个 level。另外，我也是从那个时候开始对 tensorflow 产生抵触心理，在 tf 中，你知道 RNN 有几种写法吗？你知道 dynamic_rnn 和 static_rnn 有什么区别吗？各种纷繁复杂的概念无疑加大了初学者的门槛。后来我花了一两天的时间转向 pytorch 后，感觉整个世界瞬间清净了 (当然了，学 tf 的好处就是转其他框架的时候非常快，但从其他框架转 TF 却可能生不如死)。pytorch 在模型搭建和数据处理方面都非常好上手，比起 tf 而言，代码写起来更加的整洁干净，而且开发人员更容易理解代码的运作流程。不过，在 RNN 这个问题上，新手还是容易犯嘀咕。趁着这一周刚刚摸清了 pytorch 搭建 RNN 的套路，我准备记录一下用 pytorch 搭建 RNN 的基本流程，以及数据处理方面要注意的问题，希望后来的同学们少流点血泪...

至于 tf 怎么写 RNN，之后有闲再补上 (我现在是真的不想回去碰那颗烫手的山芋)

<center>
    <img src="images/2018-11-25/rnn.png">
</center>



<!--more-->

