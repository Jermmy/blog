---
title: TensorFlow学习笔记：保存和读取模型
date: 2017-04-23
tags: [TensorFlow]
categories: TensorFlow
---

TensorFlow 更新频率实在太快，从 1.0 版本正式发布后，很多 API 接口就发生了改变。今天用 TF 训练了一个 CNN 模型，结果在保存模型的时候居然遇到各种问题。Google 搜出来的答案也是莫衷一是，有些回答对 1.0 版本的已经不适用了。后来实在没办法，就翻了墙去官网看了下，结果分分钟就搞定了。果然，掌握一套正确的学习方法太重要了，信息不对等才是导致人三六九等的原因。

这篇文章内容不多，主要讲讲 TF v1.0 版本中保存和读取模型的最简单用法，其实就是对官网教程的简要翻译摘抄。

<!--more-->

### 保存和恢复

在 TensorFlow 中，保存和恢复模型最简单的方法就是使用 `tf.train.Saver` 类。这个类会将变量的保存和恢复操作添加到 TF 的图（graph）中。

### Checkpoint 文件

TF 将变量保存在二进制文件中，这个文件包含一个从变量名到 tensor 值的映射。当我们创建一个 `Saver` 对象的时候，我们可以指定 checkpoint 文件中的变量名。默认会使用变量的 `Variable.name` 属性。

这一段读起来比较生涩难懂，具体看下面的例子。

### 保存变量

可以通过创建 `Saver` 来管理模型内的所有变量。

```python
# Create some variables.
v1 = tf.Variable(..., name="v1")
v2 = tf.Variable(..., name="v2")
...
# Add an op to initialize the variables.
init_op = tf.global_variables_initializer()

# Add ops to save and restore all the variables.
saver = tf.train.Saver()

# Later, launch the model, initialize the variables, do some work, save the
# variables to disk.
with tf.Session() as sess:
  sess.run(init_op)
  # Do some work with the model.
  ..
  # Save the variables to disk.
  save_path = saver.save(sess, "/tmp/model.ckpt")
  print("Model saved in file: %s" % save_path)
```

### 恢复变量

可以通过同一个 `Saver` 对象（指定相同的保存路径）来恢复变量。这种情况下，我们不需要事先初始化变量（即无需调用 `tf.global_variables_initializer()`）

```python
# Create some variables.
v1 = tf.Variable(..., name="v1")
v2 = tf.Variable(..., name="v2")
...
# Add ops to save and restore all the variables.
saver = tf.train.Saver()

# Later, launch the model, use the saver to restore variables from disk, and
# do some work with the model.
with tf.Session() as sess:
  # Restore variables from disk.
  saver.restore(sess, "/tmp/model.ckpt")
  print("Model restored.")
  # Do some work with the model
  ...
```

### 例子

下面用我自己的例子解释一下。

首先，我们先定义一个图模型（只截选出变量部分）：

```python
    graph = tf.Graph()

    with graph.as_default():
        # Input data
        # ....省略代码若干

        # Variables
        layer1_weights = tf.Variable(tf.truncated_normal(
            [patch_size, patch_size, image_channels, depth], stddev=0.1), name="layer1_weights")
        layer1_biases = tf.Variable(tf.zeros([depth]), name="layer1_biases")

        layer2_weights = tf.Variable(tf.truncated_normal(
            [image_size // 4 * image_size // 4 * depth, num_hidden], stddev=0.1, name="layer2_weights")
        )
        layer2_biases = tf.Variable(tf.constant(1.0, shape=[num_hidden]), name="layer2_biases")

        layer3_weights = tf.Variable(tf.truncated_normal(
            [num_hidden, num_labels], stddev=0.1, name="layer3_weights"),
        )
        layer3_biases = tf.Variable(tf.constant(1.0, shape=[num_labels]), name="layer3_biases")

        def model(data):
            #....省略代码若干
            return tf.matmul(fc1, layer3_weights) + layer3_biases

        # Training computation
        #....省略代码若干

        # Optimizer
        optimizer = tf.train.GradientDescentOptimizer(0.05).minimize(loss) 
```

这个模型里的变量其实只有三个网络层的参数：`layer1_weights`，`layer1_biases`，`layer2_weights`，`layer2_biases`，`layer3_weights`，`layer3_biases`。

然后就是启动会话进行训练：

```python
    with tf.Session(graph=graph) as session:
        saver = tf.train.Saver()

        if loading_model:
            saver.restore(session, model_folder + "/" + model_file)
            print("Model restored")
        else:
            tf.global_variables_initializer().run()
            print("Initialized")

        for step in range(num_steps):
            # ....省略训练模型的代码

        print('Test accuracy: %.1f%%' % accuracy(test_prediction.eval(), test_labels))
        save_path = saver.save(session, model_folder + "/" + model_file)
        print("Model saved in file: ", save_path)
```

这段代码是本文的关键，我们先通过 `tf.train.Saver()` 构造一个 `Saver` 对象，注意，这一步要在 `Session` 启动之后执行，否则会抛异常 `ValueError("No variables to save")`，至少 v1.0 是这样。

通过 `Saver`，我们可以在模型训练完之后，将参数保存下来。`Saver` 保存数据的方法十分简单，只要将 `session` 和 文件路径传入 `save` 函数即可：`saver.save(session, model_folder + "/" + model_file)`。

如果我们一开始想载入本地的模型文件，而不是让 TF 自动初始化训练，则可以通过 `Saver` 的 `restore` 函数读取模型文件，文件路径需要和之前保存的文件路径一致。注意，如果是通过这种方式初始化变量，则不能再调用 `tf.global_variables_initializer()` 函数。之后，训练或预测的代码不需要改变，TensorFlow 会自动根据模型文件，将你的模型参数初始化。

当然啦，以上都是最基础的用法，只是简单地将所有参数保存下来。更高级的用法，之后如果使用到再继续总结。

### 参考

+ [TensorFlow官方教程](https://www.tensorflow.org/versions/master/how_tos/variables/index.html)



