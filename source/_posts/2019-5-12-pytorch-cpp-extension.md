---
title: PyTorch中的C++扩展
date: 2019-05-12 23:47:07
tags: [PyTorch, 深度学习]
categories: PyTorch
mathjax: true
---

今天要聊聊用 PyTorch 进行 C++ 扩展。

在正式开始前，我们需要了解 PyTorch 如何自定义 `module`。这其中，最常见的就是在 python 中继承 `torch.nn.Module`，用 PyTorch 中已有的 operator 来组装成自己的模块。这种方式实现简单，但是，计算效率却未必最佳，另外，如果我们想实现的功能过于复杂，可能 PyTorch 中那些已有的函数也没法满足我们的要求。这时，用 C、C++、CUDA 来扩展 PyTorch 的模块就是最佳的选择了。

由于目前市面上大部分深度学习系统（TensorFlow、PyTorch 等）都是基于 C、C++ 构建的后端，因此这些系统基本都存在 C、C++ 的扩展接口。PyTorch 是基于 Torch 构建的，而 Torch 底层采用的是 C 语言，因此 PyTorch 天生就和 C 兼容，因此用 C 来扩展 PyTorch 并非难事。而随着 PyTorch1.0 的发布，官方已经开始考虑将 PyTorch 的底层代码用 caffe2 替换，因此他们也在逐步重构 ATen，后者是目前 PyTorch 使用的 C++ 扩展库。总的来说，C++ 是未来的趋势。至于 CUDA，这是几乎所有深度学习系统在构建之初就采用的工具，因此 CUDA 的扩展接口是标配。

本文用一个简单的例子，梳理一下进行 C++ 扩展的步骤，至于一些具体的实现，不做深入探讨。

<!--more-->

## PyTorch的C、C++、CUDA扩展

关于 PyTorch 的 C 扩展，可以参考[官方教程](https://pytorch.org/tutorials/advanced/c_extension.html)或者这篇[博文](https://oldpan.me/archives/pytorch-combine-c-and-cuda)，其操作并不难，无非是借助原先 Torch 提供的 `<TH/TH.h>` 和 `<THC/THC.h>` 等接口，再利用 PyTorch 中提供的 `torch.util.ffi` 模块进行扩展。需要注意的是，随着 PyTorch 版本升级，这种做法在新版本的 PyTorch 中可能会失效。

本文主要介绍 C++（未来可能加上 CUDA）的扩展方法。

### C++扩展

首先，介绍一下基本流程。在 PyTorch 中扩展 C++/CUDA 主要分为几步：

1. 安装好 pybind11 模块（通过 pip 或者 conda 等安装），这个模块会负责 python 和 C++ 之间的绑定；
2. 用 C++ 写好自定义层的功能，包括前向传播 `forward` 和反向传播 `backward`；
3. 写好 **setup.py**，并用 python 提供的 `setuptools` 来编译并加载 C++ 代码。
4. 编译安装，在 python 中调用 C++ 扩展接口。

接下来，我们就用一个简单的例子（**z=2x+y**）来演示这几个步骤。

#### 第一步

安装 **pybind11** 比较简单，直接略过。我们先写好 C++ 相关的文件：

头文件 **test.h**

```C++
#include <torch/extension.h>
#include <vector>

// 前向传播
torch::Tensor Test_forward_cpu(const torch::Tensor& inputA,
                            const torch::Tensor& inputB);
// 反向传播
std::vector<torch::Tensor> Test_backward_cpu(const torch::Tensor& gradOutput);
```

注意，这里引用的 `<torch/extension.h>` 头文件至关重要，它主要包括三个重要模块：

+ pybind11，用于 C++ 和 python 交互；
+ ATen，包含 Tensor 等重要的函数和类；
+ 一些辅助的头文件，用于实现 ATen 和 pybind11 之间的交互。

源文件 **test.cpp** 如下：

```c++
#include "test.h"

// 前向传播，两个 Tensor 相加。这里只关注 C++ 扩展的流程，具体实现不深入探讨。
torch::Tensor Test_forward_cpu(const torch::Tensor& x,
                            const torch::Tensor& y) {
    AT_ASSERTM(x.sizes() == y.sizes(), "x must be the same size as y");
    torch::Tensor z = torch::zeros(x.sizes());
    z = 2 * x + y;
    return z;
}

// 反向传播
// 在这个例子中，z对x的导数是2，z对y的导数是1。
// 至于这个backward函数的接口（参数，返回值）为何要这样设计，后面会讲。
std::vector<torch::Tensor> Test_backward_cpu(const torch::Tensor& gradOutput) {
    torch::Tensor gradOutputX = 2 * gradOutput * torch::ones(gradOutput.sizes());
    torch::Tensor gradOutputY = gradOutput * torch::ones(gradOutput.sizes());
    return {gradOutputX, gradOutputY};
}

// pybind11 绑定
PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
  m.def("forward", &Test_forward_cpu, "TEST forward");
  m.def("backward", &Test_backward_cpu, "TEST backward");
}

```

#### 第二步

新建一个编译安装的配置文件 **setup.py**，文件目录安排如下：

```shell
└── csrc
    ├── cpu
    │   ├── test.cpp
    │   └── test.h
    └── setup.py
```

以下是 **setup.py** 中的内容：

```python
from setuptools import setup
import os
import glob
from torch.utils.cpp_extension import BuildExtension, CppExtension

# 头文件目录
include_dirs = os.path.dirname(os.path.abspath(__file__))
# 源代码目录
source_cpu = glob.glob(os.path.join(include_dirs, 'cpu', '*.cpp'))

setup(
    name='test_cpp',  # 模块名称，需要在python中调用
    version="0.1",
    ext_modules=[
        CppExtension('test_cpp', sources=source_cpu, include_dirs=[include_dirs]),
    ],
    cmdclass={
        'build_ext': BuildExtension
    }
)
```

注意，这个 C++ 扩展被命名为 `test_cpp`，意思是说，在 python 中可以通过 `test_cpp` 模块来调用 C++ 函数。

#### 第三步

在 **cpu** 这个目录下，执行下面的命令编译安装 C++ 代码：

```shell
python setup.py install
```

之后，可以看到一堆输出，该 C++ 模块会被安装在 python 的 site-packages 中。

完成上面几步后，就可以在 python 中调用 C++ 代码了。在 PyTorch 中，按照惯例需要先把 C++ 中的前向传播和反向传播封装成一个函数 `op`（以下代码放在 **test.py** 文件中）：

```python
from torch.autograd import Function

import test_cpp

class TestFunction(Function):

    @staticmethod
    def forward(ctx, x, y):
        return test_cpp.forward(x, y)

    @staticmethod
    def backward(ctx, gradOutput):
        gradX, gradY = test_cpp.backward(gradOutput)
        return gradX, gradY
```

这样一来，我们相当于把 C++ 扩展的函数嵌入到 PyTorch 自己的框架内。

我查看了这个 `Function` 类的代码，发现是个挺有意思的东西：

```python
class Function(with_metaclass(FunctionMeta, _C._FunctionBase, _ContextMethodMixin, _HookMixin)):
  
    ...

    @staticmethod
    def forward(ctx, *args, **kwargs):
        r"""Performs the operation.

        This function is to be overridden by all subclasses.

        It must accept a context ctx as the first argument, followed by any
        number of arguments (tensors or other types).

        The context can be used to store tensors that can be then retrieved
        during the backward pass.
        """
        raise NotImplementedError

    @staticmethod
    def backward(ctx, *grad_outputs):
        r"""Defines a formula for differentiating the operation.

        This function is to be overridden by all subclasses.

        It must accept a context :attr:`ctx` as the first argument, followed by
        as many outputs did :func:`forward` return, and it should return as many
        tensors, as there were inputs to :func:`forward`. Each argument is the
        gradient w.r.t the given output, and each returned value should be the
        gradient w.r.t. the corresponding input.

        The context can be used to retrieve tensors saved during the forward
        pass. It also has an attribute :attr:`ctx.needs_input_grad` as a tuple
        of booleans representing whether each input needs gradient. E.g.,
        :func:`backward` will have ``ctx.needs_input_grad[0] = True`` if the
        first input to :func:`forward` needs gradient computated w.r.t. the
        output.
        """
        raise NotImplementedError
```

这里需要注意一下 `backward` 的实现规则。该接口包含两个参数：`ctx` 是一个辅助的环境变量，`grad_outputs` 则是来自前一层网络的梯度列表，而且这个梯度列表的数量与 `forward` 函数返回的参数数量相同，这也符合链式法则的原理，因为链式法则就需要把前一层中所有相关的梯度与当前层进行相乘或相加。同时，`backward` 需要返回 `forward` 中每个输入参数的梯度，如果 `forward` 中包括 n 个参数，就需要一一返回 n 个梯度。所以，在上面这个例子中，我们的 `backward` 函数接收一个参数作为输入（`forward` 只输出一个变量），并返回两个梯度（`forward` 接收上一层两个输入变量）。

定义完 `Function` 后，就可以在 `Module` 中使用这个自定义 `op` 了：

```python
import torch

class Test(torch.nn.Module):

    def __init__(self):
        super(Test, self).__init__()

    def forward(self, inputA, inputB):
        return TestFunction.apply(inputA, inputB)
```

现在，我们的文件目录变成：

```shell
├── csrc
│   ├── cpu
│   │   ├── test.cpp
│   │   └── test.h
│   └── setup.py
└── test.py
```

之后，我们就可以将 **test.py** 当作一般的 PyTorch 模块进行调用了。

#### 测试

下面，我们测试一下前向传播和反向传播：

```python
import torch
from torch.autograd import Variable

from test import Test

x = Variable(torch.Tensor([1,2,3]), requires_grad=True)
y = Variable(torch.Tensor([4,5,6]), requires_grad=True)
test = Test()
z = test(x, y)
z.sum().backward()
print('x: ', x)
print('y: ', y)
print('z: ', z)
print('x.grad: ', x.grad)
print('y.grad: ', y.grad)
```

输出如下：

```shell
x:  tensor([1., 2., 3.], requires_grad=True)
y:  tensor([4., 5., 6.], requires_grad=True)
z:  tensor([ 6.,  9., 12.], grad_fn=<TestFunctionBackward>)
x.grad:  tensor([2., 2., 2.])
y.grad:  tensor([1., 1., 1.])
```

可以看出，前向传播满足 **z=2x+y**，而反向传播的结果也在意料之中。

### CUDA扩展

虽然 C++ 写的代码可以直接跑在 GPU 上，但它的性能还是比不上直接用 CUDA 编写的代码，毕竟 ATen 没法并不知道如何去优化算法的性能。不过，由于我对 CUDA 仍一窍不通，因此这一步只能暂时略过，留待之后补充～囧～。



## 参考

+ [CUSTOM C EXTENSIONS FOR PYTORCH](https://pytorch.org/tutorials/advanced/c_extension.html)
+ [CUSTOM C++ AND CUDA EXTENSIONS](https://pytorch.org/tutorials/advanced/cpp_extension.html)
+ [Pytorch拓展进阶(一)：Pytorch结合C以及Cuda语言](https://oldpan.me/archives/pytorch-combine-c-and-cuda)
+ [Pytorch拓展进阶(二)：Pytorch结合C++以及Cuda拓展](https://oldpan.me/archives/pytorch-cuda-c-plus-plus)