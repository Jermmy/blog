---
title: python numpy 三行代码打乱训练数据
date: 2017-04-18 10:39:00
tags: [Python, numpy]
categories: Python
---

今天发现一个用 `numpy` 随机化数组的技巧。

### 需求

我有两个数组（ ndarray ）：train_datasets 和 train_labels。其中，train_datasets 的每一行和 train_labels 是一一对应的。现在我要将数组打乱并用于训练，打乱后要求两者的行与行之间必须保持原来的对应关系。

<!--more-->

### 实现

一般的实现思路，应该是先将 train_datasets（或 train_labels ）打乱，并记录被打乱的行号，再通过行号调整 train_labels （或 train_datasets ）的行次序，这样两者的对应关系能保持一致。但代码实现起来会很繁琐，而如果用上 `numpy` 的话，可以三行代码搞定。

首先，假设我们用如下训练数据（训练数据和标签都是三个）：

```python
>>> train_data = np.ndarray(shape=(3,1,2), dtype=np.int32, buffer=np.asarray((1,2,3,4,5,6), dtype=np.int32))
>>> train_label  = np.ndarray(shape=(3,), dtype=np.int32, buffer=np.asarray((1,2,3), dtype=np.int32))
>>> train_data
array([[[1, 2]],

       [[3, 4]],

       [[5, 6]]], dtype=int32)
>>> train_label
array([1, 2, 3], dtype=int32)
```

下面，我们用**三行代码**打乱样本数据：

```python
>>> permutation = np.random.permutation(train_label.shape[0])
>>> shuffled_dataset = train_data[permutation, :, :]
>>> shuffled_labels = train_label[permutation]
```

稍微解释一下代码：

利用 `np.random.permutation` 函数，我们可以获得打乱后的行号，输出`permutation` 为：`array([2, 1, 0])`。

然后，利用 `numpy array` 内置的操作 `train_data[permutation, :, :]` ，我们可以获得打乱行号后的新的训练数据。

我们看看训练数据和标签是不是对应的：

```python
>>> shuffled_dataset
array([[[5, 6]],

       [[3, 4]],

       [[1, 2]]], dtype=int32)
>>> shuffled_labels
array([3, 2, 1], dtype=int32)
```

没错，完全按照 `permutation` [2, 1, 0] 的顺序重新调整了。

**学会这种技巧，妈妈再也不担心我加班了🤓**