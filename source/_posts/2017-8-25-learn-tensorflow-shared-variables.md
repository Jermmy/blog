---
title: TensorFlow学习笔记：共享变量
date: 2017-08-25 22:45:57
tags: [TensorFlow, 深度学习]
categories: TensorFlow
---

本文是根据 TensorFlow 官方[教程](https://www.tensorflow.org/versions/r0.12/how_tos/variable_scope/index.html)翻译总结的学习笔记，主要介绍了在 TensorFlow 中如何共享参数变量。

教程中首先引入共享变量的应用场景，紧接着用一个例子介绍如何实现共享变量（主要涉及到 `tf.variable_scope()`和`tf.get_variable()`两个接口），最后会介绍变量域 (Variable Scope) 的工作方式。

<!--more-->

### 遇到的问题

假设我们创建了一个简单的 CNN 网络：

```python
def my_image_filter(input_images):
    conv1_weights = tf.Variable(tf.random_normal([5, 5, 32, 32]),
        name="conv1_weights")
    conv1_biases = tf.Variable(tf.zeros([32]), name="conv1_biases")
    conv1 = tf.nn.conv2d(input_images, conv1_weights,
        strides=[1, 1, 1, 1], padding='SAME')
    relu1 = tf.nn.relu(conv1 + conv1_biases)

    conv2_weights = tf.Variable(tf.random_normal([5, 5, 32, 32]),
        name="conv2_weights")
    conv2_biases = tf.Variable(tf.zeros([32]), name="conv2_biases")
    conv2 = tf.nn.conv2d(relu1, conv2_weights,
        strides=[1, 1, 1, 1], padding='SAME')
    return tf.nn.relu(conv2 + conv2_biases)
```

这个网络中用 `tf.Variable()` 初始化了四个参数。

不过，别看我们用一个函数封装好了网络，当我们要调用网络进行训练时，问题就会变得麻烦。比如说，我们有 `image1` 和 `image2` 两张图片，如果将它们同时丢到网络里面，由于参数是在函数里面定义的，这样一来，每调用一次函数，就相当于又初始化一次变量：

```python
# First call creates one set of 4 variables.
result1 = my_image_filter(image1)
# Another set of 4 variables is created in the second call.
result2 = my_image_filter(image2)
```

当然了，我们很快也能找到解决办法，那就是把参数的初始化放在函数外面，把它们当作全局变量，这样一来，就相当于全局「共享」了嘛。比如说，我们可以用一个 `dict` 在函数外定义参数：

```python
variables_dict = {
    "conv1_weights": tf.Variable(tf.random_normal([5, 5, 32, 32]),
        name="conv1_weights")
    "conv1_biases": tf.Variable(tf.zeros([32]), name="conv1_biases")
    ... etc. ...
}

def my_image_filter(input_images, variables_dict):
    conv1 = tf.nn.conv2d(input_images, variables_dict["conv1_weights"],
        strides=[1, 1, 1, 1], padding='SAME')
    relu1 = tf.nn.relu(conv1 + variables_dict["conv1_biases"])

    conv2 = tf.nn.conv2d(relu1, variables_dict["conv2_weights"],
        strides=[1, 1, 1, 1], padding='SAME')
    return tf.nn.relu(conv2 + variables_dict["conv2_biases"])

# The 2 calls to my_image_filter() now use the same variables
result1 = my_image_filter(image1, variables_dict)
result2 = my_image_filter(image2, variables_dict)
```

不过，这种方法对于熟悉面向对象的你来说，会不会有点别扭呢？因为它完全破坏了原有的封装。也许你会说，不碍事的，只要将参数和`filter`函数都放到一个类里即可。不错，面向对象的方法保持了原有的封装，但这里出现了另一个问题：当网络变得很复杂很庞大时，你的参数列表/字典也会变得很冗长，而且如果你将网络分割成几个不同的函数来实现，那么，在传参时将变得很麻烦，而且一旦出现一点点错误，就可能导致巨大的 bug。

为此，TensorFlow 内置了**变量域**这个功能，让我们可以通过**域名**来区分或共享变量。通过它，我们完全可以将参数放在函数内部实例化，再也不用手动保存一份很长的参数列表了。

### 用变量域实现共享参数

这里主要包括两个函数接口：

1. `tf.get_variable(<name>, <shape>, <initializer>)` ：根据指定的变量名实例化或返回一个 `tensor` 对象；
2. `tf.variable_scope(<scope_name>)`：管理 `tf.get_variable()` 变量的域名。

`tf.get_variable()` 的机制跟 `tf.Variable()` 有很大不同，如果指定的变量名已经存在（即先前已经用同一个变量名通过 `get_variable()` 函数实例化了变量），那么 `get_variable()`只会返回之前的变量，否则才创造新的变量。

现在，我们用 `tf.get_variable()` 来解决上面提到的问题。我们将卷积网络的两个参数变量分别命名为 `weights` 和 `biases`。不过，由于总共有 4 个参数，如果还要再手动加个 `weights1` 、`weights2` ，那代码又要开始恶心了。于是，TensorFlow 加入变量域的机制来帮助我们区分变量，比如：

```python
def conv_relu(input, kernel_shape, bias_shape):
    # Create variable named "weights".
    weights = tf.get_variable("weights", kernel_shape,
        initializer=tf.random_normal_initializer())
    # Create variable named "biases".
    biases = tf.get_variable("biases", bias_shape,
        initializer=tf.constant_initializer(0.0))
    conv = tf.nn.conv2d(input, weights,
        strides=[1, 1, 1, 1], padding='SAME')
    return tf.nn.relu(conv + biases)


def my_image_filter(input_images):
    with tf.variable_scope("conv1"):
        # Variables created here will be named "conv1/weights", "conv1/biases".
        relu1 = conv_relu(input_images, [5, 5, 32, 32], [32])
    with tf.variable_scope("conv2"):
        # Variables created here will be named "conv2/weights", "conv2/biases".
        return conv_relu(relu1, [5, 5, 32, 32], [32])
```

我们先定义一个 `conv_relu()` 函数，因为 conv 和 relu 都是很常用的操作，也许很多层都会用到，因此单独将这两个操作提取出来。然后在 `my_image_filter()` 函数中真正定义我们的网络模型。注意到，我们用 `tf.variable_scope()` 来分别处理两个卷积层的参数。正如注释中提到的那样，这个函数会在内部的变量名前面再加上一个「scope」前缀，比如：`conv1/weights`表示第一个卷积层的权值参数。这样一来，我们就可以通过域名来区分各个层之间的参数了。

不过，如果直接这样调用 `my_image_filter`，是会抛异常的：

```python
result1 = my_image_filter(image1)
result2 = my_image_filter(image2)
# Raises ValueError(... conv1/weights already exists ...)
```

因为 `tf.get_variable()`虽然可以共享变量，但默认上它只是检查变量名，防止重复。要开启变量共享，你还必须指定在哪个域名内可以共用变量：

```python
with tf.variable_scope("image_filters") as scope:
    result1 = my_image_filter(image1)
    scope.reuse_variables()
    result2 = my_image_filter(image2)
```

到这一步，共享变量的工作就完成了。你甚至都不用在函数外定义变量，直接调用同一个函数并传入不同的域名，就可以让 TensorFlow 来帮你管理变量了。

**==================== UPDATE 2018.3.8 ======================**

官方的教程都是一些简单的例子，但在实际开发中，情况可能会复杂得多。比如，有一个网络，它的前半部分是要共享的，而后半部分则是不需要共享的，在这种情况下，如果还要自己去调用 `scope.reuse_variables()` 来决定共享的时机，无论如何都是办不到的，比如下面这个例子：

```python
def test(mode):
    w = tf.get_variable(name=mode+"w", shape=[1,2])
    u = tf.get_variable(name="u", shape=[1,2])
    return w, u

with tf.variable_scope("test") as scope:
    w1, u1 = test("mode1")
	# scope.reuse_variables()
    w2, u2 = test("mode2")
```

这个例子中，我们要使用两个变量： `w` 和 `u`，其中 `w` 是不共享的，而 `u` 是共享的。在这种情况下，不管你加不加 `scope.reuse_variables()`，代码都会出错。因此，Tensorflow 提供另一种开启共享的方法：

```python
def test(mode):
    w = tf.get_variable(name=mode+"w", shape=[1,2])
    u = tf.get_variable(name="u", shape=[1,2])
    return w, u

with tf.variable_scope("test", reuse=tf.AUTO_REUSE) as scope:
    w1, u1 = test("mode1")
    w2, u2 = test("mode2")
```

这里只是加了一个参数 `reuse=tf.AUTO_REUSE`，但正如名字所示，这是一种自动共享的机制，当系统检测到我们用了一个之前已经定义的变量时，就开启共享，否则就重新创建变量。这几乎是「万金油」式的写法😈。

### 背后的工作方式

#### 变量域的工作机理

接下来我们再仔细梳理一下这背后发生的事情。

我们要先搞清楚，当我们调用 `tf.get_variable(name, shape, dtype, initializer)` 时，这背后到底做了什么。

首先，TensorFlow 会判断是否要共享变量，也就是判断 `tf.get_variable_scope().reuse` 的值，如果结果为 `False`（即你没有在变量域内调用`scope.reuse_variables()`），那么 TensorFlow 认为你是要初始化一个新的变量，紧接着它会判断这个命名的变量是否存在。如果存在，会抛出 `ValueError` 异常，否则，就根据 `initializer` 初始化变量：

```python
with tf.variable_scope("foo"):
    v = tf.get_variable("v", [1])
assert v.name == "foo/v:0"
```

 而如果 `tf.get_variable_scope().reuse == True`，那么 TensorFlow 会执行相反的动作，就是到程序里面寻找变量名为 `scope name + name` 的变量，如果变量不存在，会抛出 `ValueError` 异常，否则，就返回找到的变量：

```python
with tf.variable_scope("foo"):
    v = tf.get_variable("v", [1])
with tf.variable_scope("foo", reuse=True):
    v1 = tf.get_variable("v", [1])
assert v1 is v
```

了解变量域背后的工作方式后，我们就可以进一步熟悉其他一些技巧了。

####  变量域的基本使用

变量域可以嵌套使用：

```python
with tf.variable_scope("foo"):
    with tf.variable_scope("bar"):
        v = tf.get_variable("v", [1])
assert v.name == "foo/bar/v:0"
```

我们也可以通过 `tf.get_variable_scope()` 来获得当前的变量域对象，并通过 `reuse_variables()` 方法来设置是否共享变量。不过，TensorFlow 并不支持将 `reuse` 值设为 `False`，如果你要停止共享变量，可以选择离开当前所在的变量域，或者再进入一个新的变量域（比如，再进入一个 `with` 语句，然后指定新的域名）。

还需注意的一点是，一旦在一个变量域内将 `reuse` 设为 `True`，那么这个变量域的子变量域也会继承这个 `reuse` 值，自动开启共享变量：

```python
with tf.variable_scope("root"):
    # At start, the scope is not reusing.
    assert tf.get_variable_scope().reuse == False
    with tf.variable_scope("foo"):
        # Opened a sub-scope, still not reusing.
        assert tf.get_variable_scope().reuse == False
    with tf.variable_scope("foo", reuse=True):
        # Explicitly opened a reusing scope.
        assert tf.get_variable_scope().reuse == True
        with tf.variable_scope("bar"):
            # Now sub-scope inherits the reuse flag.
            assert tf.get_variable_scope().reuse == True
    # Exited the reusing scope, back to a non-reusing one.
    assert tf.get_variable_scope().reuse == False
```

#### 捕获变量域对象

如果一直用字符串来区分变量域，写起来容易出错。为此，TensorFlow 提供了一个变量域对象来帮助我们管理代码：

```python
with tf.variable_scope("foo") as foo_scope:
    v = tf.get_variable("v", [1])
with tf.variable_scope(foo_scope)
    w = tf.get_variable("w", [1])
with tf.variable_scope(foo_scope, reuse=True)
    v1 = tf.get_variable("v", [1])
    w1 = tf.get_variable("w", [1])
assert v1 is v
assert w1 is w
```

记住，用这个变量域对象还可以让我们跳出当前所在的变量域区域：

```python
with tf.variable_scope("foo") as foo_scope:
    assert foo_scope.name == "foo"
with tf.variable_scope("bar")
    with tf.variable_scope("baz") as other_scope:
        assert other_scope.name == "bar/baz"
        with tf.variable_scope(foo_scope) as foo_scope2:
            assert foo_scope2.name == "foo"  # Not changed.
```

#### 在变量域内初始化变量

每次初始化变量时都要传入一个 `initializer`，这实在是麻烦，而如果使用变量域的话，就可以批量初始化参数了：

```python
with tf.variable_scope("foo", initializer=tf.constant_initializer(0.4)):
    v = tf.get_variable("v", [1])
    assert v.eval() == 0.4  # Default initializer as set above.
    w = tf.get_variable("w", [1], initializer=tf.constant_initializer(0.3)):
    assert w.eval() == 0.3  # Specific initializer overrides the default.
    with tf.variable_scope("bar"):
        v = tf.get_variable("v", [1])
        assert v.eval() == 0.4  # Inherited default initializer.
    with tf.variable_scope("baz", initializer=tf.constant_initializer(0.2)):
        v = tf.get_variable("v", [1])
        assert v.eval() == 0.2  # Changed default initializer.
```



### 参考

+ [TensorFlow官方教程](https://www.tensorflow.org/versions/r0.12/how_tos/variable_scope/index.html)

