---
title: 神经网络量化入门--激活函数
date: 2021-02-25 19:47:47
tags: [深度学习]
categories: 深度学习
mathjax: true
---

**本文首发于公众号「AI小男孩」，欢迎大伙过来砸场！**

在之前的[文章](http://jermmy.github.io/2020/07/19/2020-7-19-network-quantization-4/)中提到过可以把 ReLU 合并到 Conv 中加速量化推理，当时只是用一个例子简单介绍一下过程，逻辑上存在一些漏洞。本文打算从数学上深入剖析一下其中的原理，并进一步扩展到其他激活函数，看看在网络量化中激活函数一般是怎么处理的。

<!--more-->

## 温故知新

为了简单起见，假设我们是量化到 uint8 的数值范围「即0~255」。回忆一下量化的基本公式「我在之前的文章中多次强调这几个公式，它们非常重要」

$$
\begin{align}
r&=S(q-Z) \tag{1} \\
q& = clip(round(\frac{r}{S}+Z),0,255) \tag{2}
\end{align}
$$


再简单重复一下符号的含义，$r$ 表示实数，$q$ 表示量化后的定点数，$S$ 和 $Z$ 分别是是 scale 和 zero point。

注意，这次我对 $q$ 单独加了一个 clip 操作，在之前的文章中，这一步在公式中被我省略了，不过在实际量化的时候，这一步是必须的，否则会有数值溢出的危险。

现在，假设激活函数为 $f(x)$，应用到实数域上是这个样子：
$$
r_2=f(r_1) \tag{3}
$$
那么把 (1) 式代入后可以得到量化的公式：
$$
S_2(q_2-Z_2)=f(S_1(q_1-Z_1)) \tag{4}
$$
这就是量化时处理所有激活函数的总口诀，别看它平平无奇，但话越少，信息量越多。下面，我们就看看针对具体的激活函数，怎么运用这个公式。

## ReLU

ReLU 是一个非常简单的函数，它除了把小于 0 的数值截断外，甚至不做任何操作：
$$
\begin{align}
ReLU(x)=\begin{cases} x & x >= 0 \\ 0 & x < 0 \end{cases} \tag{5}
\end{align}
$$
如果把上面的函数 $f$ 替换成 ReLU 的公式，就可以得到：
$$
\begin{align}
r_2=\begin{cases} r_1 & r_1 >= 0 \\ 
0 & r_1<0 \end{cases} \tag{6}
\end{align}
$$
把 (1) 式代入就变成：
$$
S_2(q_2-Z_2)=\begin{cases} S_1(q_1-Z_1) & q_1 >= Z_1 \\ 0 & q_1 < Z_1 \end{cases} \tag{7}
$$
换算一下可以得到：
$$
q_2=\begin{cases} \frac{S_1}{S_2}(q_1-Z_1)+Z_2 & q_1 >= Z_1 \\ Z_2 & q_1 < Z_1 \end{cases} \tag{8}
$$
这是量化 ReLU 最通用的运算，其中 $\frac{S_1}{S_2}$ 可以通过之前文章讲的**定点数 + bitshift** 来实现。

需要重点指出的是，ReLU 之后，$Z_2$ 永远等于 0。因为 ReLU 会把实数域上小于 0 的数全部截断为 0，此时去统计实数域的范围，可以发现是 0~a，而我们量化的数值范围是 0～255，为了保证零点对齐，因此 $Z_2$ 只能取 0。

当然啦，具体实现上没有必要完全按照 (8) 式来操作。一来公式内的 scale 操作过于麻烦还掉精度，二来 ReLU 本身是有明确的物理意义的，那就是把小于零点的数值截断，其余不变。这个意义在量化里面依然成立。

因此，我们其实可以用一种更简洁明了的方式来实现量化的 ReLU：
$$
q_2=\begin{cases} q_1 & q_1 >= Z_1 \\ Z_1 & q_1 < Z_1 \end{cases}   \tag{9}
$$
如果是使用这个公式，那 ReLU 前后的 scale 和 zeropoint 是要保持一致的，这一点可以从 ReLU 本身的物理含义出发得出。

tflite 里面就是用了这个简化的公式来实现 ReLU 的功能「下面这段代码参考自https://github.com/tensorflow/tensorflow/blob/r1.15/tensorflow/lite/kernels/internal/reference/reference_ops.h#L214」：

```c++
template <typename T>
inline void ReluX(const tflite::ActivationParams& params,
                  const RuntimeShape& input_shape, const T* input_data,
                  const RuntimeShape& output_shape, T* output_data) {
  gemmlowp::ScopedProfilingLabel label("Quantized ReluX (not fused)");
  const int flat_size = MatchingFlatSize(input_shape, output_shape);
  const T max_value = params.quantized_activation_max;
  const T min_value = params.quantized_activation_min;
  for (int i = 0; i < flat_size; ++i) {
    const T val = input_data[i];
    const T clamped =
        val > max_value ? max_value : val < min_value ? min_value : val;
    output_data[i] = clamped;
  }
}
```

可以看出，这个量化的 ReLU 和浮点数版本的 ReLU 逻辑上几乎没有区别。

### ReLU如何勾搭上Conv

其实不止是 Conv，全连接层 FC 等也可以和 ReLU 合并。我们来看看为什么。

同样地，假设一个卷积操作为 $r_3=\sum_{i}^N r_1^i r_2^i$，按照之前文章的描述，量化后的公式为：
$$
S_3(q_3-Z_3)=S_1S_2 \sum_{i}^N (q_1-Z_1)(q_2-Z_2)  \tag{10}
$$
现在，$q_3$ 进入 ReLU 进行运算得到 $q_4$，按照上面的推算可以得出：
$$
\begin{align}
S_4(q_4-Z_4)&=\begin{cases} S_3(q_3-Z_3) & q_3 >= Z_3 \\ 0 & q_3 < Z_3 \end{cases}  \\ \notag
&=\begin{cases} S_1S_2 \sum_{i}^N (q_1-Z_1)(q_2-Z_2)  & q_3 >= Z_3 \\ 0 & q_3 < Z_3 \end{cases}
\end{align}  \tag{11}
$$
换算一下得到：
$$
q_4=\begin{cases} \frac{S_1S_2}{S_4}\sum_{i}^N (q_1-Z_1)(q_2-Z_2)+Z_4  & q_3 >= Z_3 \\ Z_4  & q_3 < Z_3 \end{cases}  \tag{12}
$$
到这里，这个式子仍然是 ReLU 的形式。换句话说，我们仍然要走两个分支来计算函数的结果。

但是，如果要把 ReLU 合并到 Conv 中，就必须得用 Conv 的运算来代替这个分支运算。换句话说，$q_4$ 无论跑哪个分支，都必须可以用 $\frac{S_1S_2}{S_4}\sum_{i}^N (q_1-Z_1)(q_2-Z_2)+Z_4$ 直接计算出来，我们才能实现 Conv 和 ReLU 的合并。

这时，就要用到量化中的 clip 操作了。上面式子 (12)，其实更严格的写法应该是：
$$
q_4=\begin{cases} clip(\frac{S_1S_2}{S_4}\sum_{i}^N (q_1-Z_1)(q_2-Z_2)+Z_4, 0, 255)  & q_3 >= Z_3 \\ Z_4  & q_3 < Z_3 \end{cases}   \tag{13}
$$
前面说了，$Z_4=0$。如果 $q_3 < Z_3$，那么等价地 $\sum_{i}^N (q_1-Z_1)(q_2-Z_2)<0$，此时会跑第二个分支得到 $q_4=Z_4$。但是，由于有 clip 操作，在这种情况下，$q_4=clip(\frac{S_1S_2}{S_4}\sum_{i}^N (q_1-Z_1)(q_2-Z_2)+Z_4, 0, 255)=0=Z_4$，因此，我们发现，无论跑哪个分支，最后都可以统一用下面这个式子来表示：
$$
q_4=clip(\frac{S_1S_2}{S_4}\sum_{i}^N (q_1-Z_1)(q_2-Z_2)+Z_4, 0, 255)   \tag{14}
$$
而这个公式的意义相当于：我们计算出 ReLU 之后的 $S$ 和 $Z$，然后把这个 $S$ 和 $Z$ 对应到 Conv 的输出，这样一来，ReLU 的运算就合并到 Conv 里面了。

正如我前面提到的，ReLU 除了做数值上的截断外，其实没有其他操作了，而量化本身自带截断操作，因此才能把 ReLU 合并到 Conv 或者 FC 等操作里面。

## LeakyReLU

有读者可能觉得，ReLU 本身的操作很简单，为什么还得用 (8) 式这种绕弯路的方式说一大堆。那是因为 ReLU 本身的性质可以让我们抄近道，如果换成其他函数，这个流程就绕不过去了。

不信来看看 LeakyReLU 是怎么量化的。

LeakyReLU 的公式可以表示成：
$$
LeakyReLU(x)=\begin{cases}x & x >= 0 \\ \alpha x & x < 0 \end{cases}  \tag{15}
$$
这里面的 $\alpha$ 是我们事先指定的数值，一般是 0~1 之间的小数。

同样地，我们按照文章最开始的总口诀，即公式 (3)(4)，来逐步分析这个函数。把原来的函数 $f$ 替换成 LeakyReLU，可以得到：

$$
r_2=\begin{cases} r_1 & r_1 >= 0 \\ \alpha r_1 & r_1 < 0 \end{cases} \tag{16}
$$

把 (1) 式代入：
$$
S_2(q_2-Z_2)=\begin{cases}S_1(q_1-Z_1) & q_1 >= Z_1 \\ \alpha S_1(q_1-Z1) & q_1 < Z_1 \end{cases}  \tag{17}
$$
换算一下得到：
$$
q_2=\begin{cases}\frac{S_1}{S_2}(q_1-Z_1)+Z_2 & q_1 >= Z_1 \\ \frac{\alpha S_1}{S_2}(q_1-Z_1)+Z_2 & q_1 < Z_1 \end{cases} \tag{18}
$$
此时，由于有 $\alpha$ 的存在，这两个分支就无法像 ReLU 一样进行合并，自然也就无法整合到 Conv 等操作内部了。

在 tflite 中是将 $\alpha$ 转换为一个定点数再计算的。具体地，假设 $\alpha_q=clip(round(\frac{\alpha}{S_1}+Z_1), 0, 255)$，可以得到：
$$
q_2=\begin{cases}\frac{S_1}{S_2}(q_1-Z_1)+Z_2 & q_1 >= Z_1 \\ \frac{S_1S_1}{S_2}(\alpha_q-Z_1)(q_1-Z_1) & q_1 < Z_1 \end{cases} \tag{19}
$$
具体代码如下「参考自https://github.com/tensorflow/tensorflow/blob/r1.15/tensorflow/lite/kernels/activations.cc#L248」：

```c++
TfLiteStatus LeakyReluPrepare(TfLiteContext* context, TfLiteNode* node) {
  TF_LITE_ENSURE_EQ(context, NumInputs(node), 1);
  TF_LITE_ENSURE_EQ(context, NumOutputs(node), 1);
  const TfLiteTensor* input = GetInput(context, node, 0);
  TfLiteTensor* output = GetOutput(context, node, 0);
  TF_LITE_ENSURE_EQ(context, input->type, output->type);

  LeakyReluOpData* data = reinterpret_cast<LeakyReluOpData*>(node->user_data);

  if (output->type == kTfLiteUInt8) {
    const auto* params =
        reinterpret_cast<TfLiteLeakyReluParams*>(node->builtin_data);
    // Quantize the alpha with same zero-point and scale as of input
    data->q_alpha = static_cast<uint8_t>(std::max<float>(
        std::numeric_limits<uint8_t>::min(),
        std::min<float>(std::numeric_limits<uint8_t>::max(),
                        std::round(input->params.zero_point +
                                   (params->alpha / input->params.scale)))));

    double real_multiplier =
        input->params.scale * input->params.scale / output->params.scale;
    QuantizeMultiplierSmallerThanOneExp(
        real_multiplier, &data->output_multiplier, &data->output_shift);
  }
  return context->ResizeTensor(context, output,
                               TfLiteIntArrayCopy(input->dims));
}
```

这段代码主要是做一些准备工作，把 $\alpha_q$ 和 $\frac{S_1S_1}{S_2}$ 等变量事先计算好。

函数本身的具体操作如下「参考自https://github.com/tensorflow/tensorflow/blob/r1.15/tensorflow/lite/kernels/internal/reference/reference_ops.h#L242」：

```c++
template <typename T>
inline void QuantizeLeakyRelu(const LeakyReluParams& params, T q_alpha,
                              const RuntimeShape& input_shape,
                              const T* input_data,
                              const RuntimeShape& output_shape,
                              T* output_data) {
  gemmlowp::ScopedProfilingLabel label("LeakyRelu (not fused)");
  const int flat_size = MatchingFlatSize(input_shape, output_shape);
  static const int32 quantized_min = std::numeric_limits<T>::min();
  static const int32 quantized_max = std::numeric_limits<T>::max();
  static const int32 alpha_value = q_alpha - params.alpha_offset;
  for (int i = 0; i < flat_size; ++i) {
    const int32 input_value = input_data[i] - params.input_offset;
    if (input_value >= 0) {
      output_data[i] = input_data[i];
    } else {
      const int32 unclamped_output =
          params.output_offset + MultiplyByQuantizedMultiplierSmallerThanOneExp(
                                     input_value * alpha_value,
                                     params.output_multiplier,
                                     params.output_shift);
      const T clamped_output =
          std::min(quantized_max, std::max(quantized_min, unclamped_output));
      output_data[i] = static_cast<uint8>(clamped_output);
    }
  }
}
```

代码里面的 `input_value` 就是公式 (19) 里面的 $q_1-Z_1$，tflite 会根据 `input_val` 的数值情况分两个分支运行，这个过程和 (19) 基本一致。

眼尖的读者可能发现，为啥 $q_1>Z_1$ 这个分支，代码里面好像直接令 $q_2=q_1$ 了，这跟公式 (19) 描述的好像不一样啊。哈哈，这个地方我也暂时不明白，了解详情的读者请教教我，或者我之后弄懂再补充一下。

## 非线性函数

对于类 ReLU 函数来说，其实还都是分段线性的，那遇到非线性的函数「比如 sigmoid、tanh」又该怎么量化呢？从 gemmlowp 的文档来看，这些函数其实是用定点运算来近似浮点的效果。这部分内容触及到我的知识盲区，所以就不给大家做深入介绍了，感兴趣的读者可以看一下 gemmlowp 的源码进一步了解：https://github.com/google/gemmlowp/blob/master/fixedpoint/fixedpoint.h。

虽然我对里面的原理了解不多，但还是有一点点落地的经验。我曾经用高通骁龙的 SNPE 工具量化了 tanh 函数，但在 DSP 上跑定点运算的时候，发现耗时比在 GPU 上跑浮点运算满了 100 倍左右。

因此对于有落地需求的同学来说，我的建议是网络中尽量不要包含这类非线性函数。如果实在要有的话，要么尝试把网络拆成几块，一些跑定点，一些跑浮点，要么就是用一些线性函数来近似这些非线性函数的效果。

## 总结

这篇文章主要讲了网络量化中如何处理激活函数，并从数学上进一步剖析为何 ReLU 可以和 Conv 等操作合并。

你可能已经发现，网络量化这个课题跟底层的实现联系非常紧密，比如涉及到 gemmlowp、neon 等底层函数库等。有读者会说：我只想老老实实研究算法，对这些底层的运算不了解也没兴趣了解啊！
对于这部分读者，其实也不用焦虑，诚然，网络量化对底层的联系相比其他深度学习算法而言更加紧密，但对于顶层的算法开发人员，只需要大概知道底层是怎么运行的就可以，而把更多的精力放在对量化算法的改进上。当然啦，如果想成为一流的网络量化专家，熟悉底层还是很有必要的，否则你怎么知道未来算法的发展趋势呢？

PS. 最近陆续填了一些坑，之后应该会介绍一些更前沿且对落地比较友好的论文和技术了。感谢大家在我断更这么久后依然不离不弃。
