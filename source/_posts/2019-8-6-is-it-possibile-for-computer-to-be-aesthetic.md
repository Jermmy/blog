
---
title: 让计算机审美，这可能吗?
date: 2019-08-06 22:37:29
tags: [计算机视觉, 深度学习, 论文]
categories: 计算机视觉
mathjax: true
---

入职一个月，一直在研究计算机美学 (photo aesthetic) 的课题，因为有一个需求是帮助用户筛选出一些拍的比较好的图片。这段时间陆陆续续看了很多相关的文章，也一直在思考这个问题：让计算机来对图片进行审美，到底有没有可能？毕竟审美是一件很主观的事情，美的定义本身也不清晰，让需要明确指令的计算机来做一件人类都不明确的事情，这看起来就不太现实。

本文会记录一下我最近看过的一些文章，总结一下这个领域的研究思路，以及我个人的一些想法。

<!--more-->

## 什么是计算机美学

狭义上讲，计算机美学 (photo aesthetic) 的研究内容是教计算机对图片审美，可以是输出一个分数，也可以是对图片分好坏，抑或是其他评价手段均可以。

与之类似的另一个课题叫图像质量评估 (image quality assessment)。我的理解是，前者偏向于主观感受，后者偏向于客观感受 (比如噪声、饱和度等客观因素)。前者的评价指标一般是跟数据集中已有的评分进行比较，而后者会有一些客观的评价标准 (如 [PSNR]([https://zh.wikipedia.org/zh-hans/%E5%B3%B0%E5%80%BC%E4%BF%A1%E5%99%AA%E6%AF%94](https://zh.wikipedia.org/zh-hans/峰值信噪比))，[SSIM]([https://zh.wikipedia.org/wiki/%E7%B5%90%E6%A7%8B%E7%9B%B8%E4%BC%BC%E6%80%A7](https://zh.wikipedia.org/wiki/結構相似性)))。

这篇文章只关注计算机美学。

## 研究思路

由于美的定义模糊不清，且因人而异，因此要想做出令人信服的研究 (或水文)，就需要在一些大家都认可的数据集上刷分。目前常用的几个数据集包括 [CUHK-PQ](http://personal.ie.cuhk.edu.hk/~dy015/ImageAesthetics/Image_Aesthetic_Assessment.html)、[AVA](http://academictorrents.com/details/71631f83b11d3d79d8f84efe0a7e12f0ac001460)、[AADB](https://github.com/aimerykong/deepImageAestheticsAnalysis) 等，其中被用得比较广的当属 AVA 了，因为这个数据集的图片数量异常庞大，且标签也比较丰富，因此可以挖的点更多。

在看了最近几年的论文后，我发现这个领域的研究方法主要集中在两个方向：1. 在模型 (包括 loss) 上面改进；2. 在数据方面创新。

## 计算机美学可以做什么

## 参考
