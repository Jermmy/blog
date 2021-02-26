---
title: 神经网络量化入门--Add和Concat
date: 2020-12-07 22:42:03
tags: [深度学习]
categories: 深度学习
mathjax: true
---

好久没更新了，一方面是因为工作繁忙，另一方面主要是懒。

之前写过几篇关于神经网络量化的[文章](http://jermmy.github.io/2020/06/13/2020-6-13-network-quantization-1/)，主要是对 Google 量化[论文](https://arxiv.org/abs/1712.05877)以及[白皮书](https://arxiv.org/abs/1806.08342)的解读，但有一些细节的问题当时没有提及。这篇文章想补充其中一个问题：关于 ElementwiseAdd (简称 EltwiseAdd) 和 Concat 的量化。

<!--more-->

## EltwiseAdd量化

EltwiseAdd 的量化主要是在论文的附录里面提及的。过程不是太复杂，如果了解量化的基本原理的话，完全可以自己推导出来。

<center>
  <img src="/images/2020-12-12/Add.png" width="500px">
</center>

回忆一下量化的基本公式：
$$
r=S(q-Z) \tag{1}
$$
(看不懂的可以再参考一下我之前的文章)

这里面 $r$ 是实数域中的数值 (一般是 float)，$q$ 则是量化后的整型数值 (常用的是 int8)。

EltwiseAdd 就是对两个 tensor 的数值逐个相加。假设两个 tensor 中的数值分别是 $r_1$、$r_2$，相加得到的和用 $r_3$ 表示，那全精度下的 EltwiseAdd 可以表示为：
$$
r_3 = r_1 + r_2  \tag{2}
$$
用量化的公式代入进去后可以得到：
$$
S_3(q_3-Z_3)=S_1(q_1-Z_1)+S_2(q_2-Z_2) \tag{3}
$$
稍作整理可以得到：
$$
q_3=\frac{S_1}{S_3}(q_1-Z_1+\frac{S_2}{S_1}(q_2-Z_2))+Z_3 \tag{4}
$$


注意，这里有两个 scale 运算需要转换为定点小数加一个 bitshift 的运算 (具体做法见之前的[文章](http://jermmy.github.io/2020/06/13/2020-6-13-network-quantization-1/))。除了需要对输出按照 $\frac{S_1}{S_3}$ 放缩外，其中一个输入也需要按照 $\frac{S_2}{S_1}$ 进行放缩，这一步就是论文中提到的 rescale。

这一部分的代码我就不准备在 pytorch 中实现了，毕竟这个模块的量化最主要的就是统计输入跟输出的 minmax，因此训练代码几乎没什么内容，主要的工作都是在推理引擎实现的。因此这篇文章我会摘取 tflite 中部分实现简单说明一下。

下面是 tf1.5 中我摘取的部分关于 EltwiseAdd 的量化实现，对应的链接是https://github.com/tensorflow/tensorflow/blob/r1.15/tensorflow/lite/kernels/internal/reference/add.h#L53：

```c++
inline void AddElementwise(int size, const ArithmeticParams& params,
                           const uint8* input1_data, const uint8* input2_data,
                           uint8* output_data) {
  // ......此处省略若干无关代码
  for (int i = 0; i < size; ++i) {
    const int32 input1_val = params.input1_offset + input1_data[i];
    const int32 input2_val = params.input2_offset + input2_data[i];
    const int32 shifted_input1_val = input1_val * (1 << params.left_shift);
    const int32 shifted_input2_val = input2_val * (1 << params.left_shift);
    const int32 scaled_input1_val =
        MultiplyByQuantizedMultiplierSmallerThanOneExp(
            shifted_input1_val, params.input1_multiplier, params.input1_shift);
    const int32 scaled_input2_val =
        MultiplyByQuantizedMultiplierSmallerThanOneExp(
            shifted_input2_val, params.input2_multiplier, params.input2_shift);
    const int32 raw_sum = scaled_input1_val + scaled_input2_val;
    const int32 raw_output =
        MultiplyByQuantizedMultiplierSmallerThanOneExp(
            raw_sum, params.output_multiplier, params.output_shift) +
        params.output_offset;
    const int32 clamped_output =
        std::min(params.quantized_activation_max,
                 std::max(params.quantized_activation_min, raw_output));
    output_data[i] = static_cast<uint8>(clamped_output);
  }
}
```

这里面有个函数 `MultiplyByQuantizedMultiplierSmallerThanOneExp`，它的主要作用是调用 gemmlowp 中的函数将乘以 scale 的浮点运算转换为乘以一个定点小数加 bitshift 的操作，由于涉及比较多底层操作，不在本文讨论之内。

整段代码的逻辑和上文分析的基本类似，首先是对输入加 offset 操作，对应公式中的 $q_i-Z_i$，然后分别对两个输入乘以 scale，那按照上文的描述，一般来说只有一个输入需要进行 rescale 操作，另一个输入的 scale 其实是 1。在对两个输入相加后得到输出 (代码中的 `raw_sum`)，会按照同样的方式对输出进行 scale 放缩并加上 offset，最后再 clamp 到 uint8 的数值范围内。

## Concat量化

Concat 可以采用和 EltwiseAdd 类似的操作，对其中一个输入进行 rescale 后再 concat，最后再对输出进行 rescale，参考如下推导：
$$
r_3=concat[r_1, r_2]  \tag{5}
$$
代入量化公式：
$$
S_3(q_3-Z_3)=concat[S_1(q_1-Z_1),S_2(q_2-Z_2)]  \tag{6}
$$
整理后得到：
$$
\frac{S_3}{S_1}(q_3-Z_3)=concat[(q_1-Z_1),\frac{S_2}{S_1}(q_2-Z_2)] \tag{7}
$$
不过 rescale 本身是存在精度损失的，而 Concat 严格来说是一个无损的操作 (concat 其实就是内存拷贝而已)，因此论文建议统一输入输出的 scale 来避免 rescale：

<center>
  <img src="/images/2020-12-12/Concat.png" width="500px">
</center>

不过我始终想不通要如何在没有 rescale 的情况下统一输入输出的 scale。论文中也没有提及相关的实现，很多细节只能到 tflite 的源码中查找。

可以明确的一点是，output 的 minmax 可以通过取两个输入的最小 min 和最大 max 来确定。那无非存在两种情况：1. 其中一个输入的 minmax 覆盖了整个范围，即输出的 minmax 完全由某一个输入确定；2. minmax 分别来自两个输入，即一个输入的 min 和 另一个输入的 max 确定输出的 minmax。

为了了解 Google 到底怎么处理 concat 量化，我稍微翻了下 tf1.5 中对于量化 concat 的实现。

下面是在源码中找到的部分代码注释：

```c++
// There are two inputs for concat, "input0" and "input1". "input0" has [0, 5]
// as min/max and "input1" has [0, 10] as min/max. The output "output" for
// concat has [0, 10] as min/max.
// After applyging QuantizeModel(), "input0" will have a requant op added, along
// with a tensor "input0_reqaunt" that has [0, 10] as min/max. So the topology
// becomes:
// input0 -> requant -> input0_requant \
//                                       concat - output
//                              input1 /
```

具体位置在：https://github.com/tensorflow/tensorflow/blob/r1.15/tensorflow/lite/tools/optimize/quantize_model_test.cc#L303

这段注释说的是上面的情况 1，即其中一个输入的 minmax 覆盖了整个范围。这种情况下，tflite 的做法是将 range 较小的输入进行 requant，即根据大 range 的 minmax，来重新量化这个输入。

那具体怎么 requant 呢？这里需要在另一段代码中找细节：

```c++
inline void ConcatenationWithScaling(const ConcatenationParams& params,
                                     const RuntimeShape* const* input_shapes,
                                     const uint8* const* input_data,
                                     const RuntimeShape& output_shape,
                                     uint8* output_data) {
  ....
  const float inverse_output_scale = 1.f / output_scale;
  uint8* output_ptr = output_data;
  for (int k = 0; k < outer_size; k++) {
    for (int i = 0; i < inputs_count; ++i) {
      const int copy_size = input_shapes[i]->Dims(axis) * base_inner_size;
      const uint8* input_ptr = input_data[i] + k * copy_size;
      if (input_zeropoint[i] == output_zeropoint &&
          input_scale[i] == output_scale) {
        memcpy(output_ptr, input_ptr, copy_size);
      } else {
        const float scale = input_scale[i] * inverse_output_scale;
        const float bias = -input_zeropoint[i] * scale;
        for (int j = 0; j < copy_size; ++j) {
          const int32_t value =
              static_cast<int32_t>(std::round(input_ptr[j] * scale + bias)) +
              output_zeropoint;
          output_ptr[j] =
              static_cast<uint8_t>(std::max(std::min(255, value), 0));
        }
      }
      output_ptr += copy_size;
    }
  }
}
```

这里只贴了其中比较关键的实现，链接：https://github.com/tensorflow/tensorflow/blob/r1.15/tensorflow/lite/kernels/internal/reference/reference_ops.h#L1164。

具体做法是这样的：如果输入的 scale、zeropoint 和输出不一样，那么就对该输入按照输出的 scale 和 zeropoint 重新 requant，表示成公式的话是这样子的：
$$
\begin{align}
q_3&=(q_1\frac{S_1}{S_3}-Z_1\frac{S_1}{S_3})+Z_3 \notag \\
&=\frac{S_1}{S_3}(q_1-Z_1)+Z_3 \tag{8}
\end{align}
$$
对比上面公式 (7)，我发现这他喵不就是对输入 $q_1$ 进行 rescale 吗？而且，上面这段代码不会区分 $q_1$、$q_2$，只要发现输入的 scale 和 zeropoint 和输出对不上，就会对任何一个输入进行 requant。

换言之，量化 concat 可以用公式表示为：
$$
q_3=concat[\frac{S_1}{S_3}(q_1-Z_1)+Z_3,\frac{S_2}{S_3}(q_2-Z_2)+Z_3]  \tag{9}
$$

## 总结

这篇文章是对网络量化中 EltwiseAdd 和 Concat 两个操作的补充，由于有 rescale 以及 requant 的存在，这两个运算相比 float 而言，计算量反而更大，而且可能导致精度上的损失。因此在量化网络的时候，需要关注这两个函数的输入 range 不要相差太大，以避免精度损失过大。

## 参考

+ [tensorflow量化部分整理ing](https://blog.csdn.net/azheng_wen/article/details/99440697)
+ [Quantizing Networks](https://zhuanlan.zhihu.com/p/127977794)

PS: 之后的文章更多的会发布在公众号上，欢迎有兴趣的读者关注我的个人公众号：AI小男孩，扫描下方的二维码即可关注
<center>
  <img src="/images/wechat.jpg" width="500px">
</center>