---
title: Bagging, Boosting, Bootstrap
date: 2017-04-12 10:19:08
tags: [Machine Learning]
categories: [Machine Learning]
---

Bagging 和 Boosting 都属于机器学习中的元算法（meta-algorithms）。所谓元算法，简单来讲，就是将几个较弱的机器学习算法综合起来，构成一个更强的机器学习模型。这种「三个臭皮匠，赛过诸葛亮」的做法，可以帮助减小方差（over-fitting）和偏差（under-fitting），提高准确率。

狭义的理解：Bagging，Boosting 为这种元算法的训练提供了一种采样的思路。

<!--more-->

### Boosting

Boosting 最著名的实现版本应该是 AdaBoost 了。

Boosting 的流程一般为：

1. 从数据集 D 中，无放回地、随机地挑选出一个子集 d1，训练一个弱的分类器 C1； 
2. 从数据集 D 中，无放回地、随机地挑选出一个子集 d2，再加上一部分上一步被错分类的样本，训练一个弱分类器 C2；
3. 重复步骤 2，直到所有分类器都训练完毕；
4. 综合所有的弱分类器，并为每个分类器赋予一个权值。

### Bagging

采用 Bagging 原理的机器学习算法，代表的有 Random Forest（有些许改进）。

理解 Bagging 之前，需要先简单了解一下 Bootstrap 的概念。Bootstrap 是一种有放回的随机采样过程（注意，Boosting 是无放回的）。

Bagging 指的其实是 **B**ootstrap **AGG**regat**ING**，「aggregating」是聚合的意思，也就是说，Bagging 是 Bootstrap 的增强版。

Bagging 的流程一般为：

1. 根据 bootstrap 方法，生成 n 个不同的子集；
2. 在每个子集上，单独地训练弱分类器（或者说，子机器学习模型）；
3. 预测时，将每个子模型的预测结果平均一下，作为最终的预测结果。

### Bagging 和 Boosting 对比

Bagging 这种有放回的采样策略，可以减少 over-fitting，而 Boosting 会修正那些错分类的样本，因此能提高准确率（但也可能导致 overfitting ）。

Bagging 由于样本之间没有关联，因此它的训练是可以并行的，比如 Random Forest 中，每一棵决策树都是可以同时训练的。Boosting 由于需要考虑上一步错分类的样本，因此需要顺序进行。

### 参考

+ [What's the difference between boosting and bagging?](https://www.quora.com/Whats-the-difference-between-boosting-and-bagging)
+ [Bagging, boosting and stacking in machine learning](http://stats.stackexchange.com/questions/18891/bagging-boosting-and-stacking-in-machine-learning)
+ [bootstrap, boosting, bagging 几种方法的联系](http://blog.csdn.net/jlei_apple/article/details/8168856)

