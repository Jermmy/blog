---
title: 如何用PyTorch实现ROI Pooling和ROI Align
date: 2019-05-12 23:47:07
tags: [PyTorch, 深度学习]
categories: PyTorch
mathjax: true
---

承接[上文]([http://jermmy.xyz/2019/04/12/2019-4-12-paper-notes-mask-rcnn/](http://jermmy.xyz/2019/04/12/2019-4-12-paper-notes-mask-rcnn/))，今天要聊聊如何用 PyTorch 实现 `ROI Pooling` 和 `ROI Align`。

在正式开始前，我们需要了解 PyTorch 如何自定义 `module`。这其中，最常见的就是在 `python` 中继承 `torch.nn.Module`，用 PyTorch 中已有的 operator 来组装成自己的模块。这种方式实现简单，但是，计算效率却未必最佳，另外，如果我们想实现的功能过于复杂，可能 PyTorch 中那些已有的函数也没法实现我们的要求。这时，用 C、C++、CUDA 来扩展 PyTorch 的模块就是最佳的选择了。

由于目前市面上大部分深度学习系统（TensorFlow、PyTorch等）都是基于 C、C++ 构建的后端，因此这些系统基本都存在 C、C++ 的扩展接口。PyTorch 是基于 Torch 构建的，而 Torch 底层采用的是 C 语言，因此 PyTorch 天生就和 C 兼容，因此用 C 来扩展 PyTorch 并非难事。而随着 PyTorch1.0 的发布，官方已经开始考虑将 PyTorch 的底层代码用 caffe2 替换，因此他们也在逐步重构 ATen，后者是目前 PyTorch 使用的 C++ 扩展库。总的来说，C++ 是未来的趋势。至于 CUDA，这是几乎所有深度学习系统在构建之初就采用的工具，因此 CUDA 的扩展接口是标配。

<!--more-->

## PyTorch的C、C++、CUDA扩展

关于 PyTorch 的 C 扩展，可以参考[官方教程](https://pytorch.org/tutorials/advanced/c_extension.html)或者这篇[博文](https://oldpan.me/archives/pytorch-combine-c-and-cuda)，其操作并不难，无非是借助原先 Torch 提供的 `<TH/TH.h>` 和 `<THC/THC.h>` 等接口，再利用 PyTorch 中提供的 `torch.util.ffi` 模块进行扩展。需要注意的是，随着 PyTorch 版本升级，这种做法在新版本的 PyTorch 中可能会失效。

本文主要介绍 C++（以及 CUDA）的扩展方法。



## ROI Pooling实现

## ROI Align实现

## 参考

+ [CUSTOM C EXTENSIONS FOR PYTORCH](https://pytorch.org/tutorials/advanced/c_extension.html)
+ [CUSTOM C++ AND CUDA EXTENSIONS](https://pytorch.org/tutorials/advanced/cpp_extension.html)
+ [Pytorch拓展进阶(一)：Pytorch结合C以及Cuda语言](https://oldpan.me/archives/pytorch-combine-c-and-cuda)
+ [Pytorch拓展进阶(二)：Pytorch结合C++以及Cuda拓展](https://oldpan.me/archives/pytorch-cuda-c-plus-plus)