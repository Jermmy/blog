---
title: 图像中的傅立叶变换（三）
date: 2017-10-15 16:26:16
tags: [图像处理]
categories: 图像处理
mathjax: true
---

在之前的文章中，我们介绍了傅立叶变换的本质和很多基本性质，现在，该聊聊代码实现的问题了。

为了方便起见，本文采用的编程语言是 Python3，矩阵处理用 numpy，图像处理则使用 OpenCV3。

<!--more-->

### 离散傅立叶变换

首先，回忆一下离散傅立叶变换的公式：
$$
\begin{eqnarray}
F(u, v)&=&\frac{1}{MN}\sum_{x=0}^{M-1}\sum_{y=0}^{N-1}f(x, y)e^{-j2\pi ux/M}e^{-j2\pi vy/N} \\
&=&\frac{1}{MN}\sum_{y=0}^{N-1}\lbrace \sum_{x=0}^{M-1}f(x, y)e^{-j2\pi ux/M}\rbrace e^{-j2\pi vy/N}
\end{eqnarray}
$$
从上式可以得到一个很有用的性质：可分性。即我们可以先计算 $\sum_{x=0}^{M-1}f(x, y)e^{-j2\pi ux/M}$，得到 $F(u,y)$，再计算 $\frac{1}{MN}\sum_{y=0}^{N-1} F(u,y) e^{-j2\pi vy/N}$ 得到 $F(u,v)$。

根据这种可分性，我们可以将二维的计算分为两个一维进行。

现在，考虑如何计算 $F(u,y)=\sum_{x=0}^{M-1}f(x, y)e^{-j2\pi ux/M}$，这个式子中的 $y$ 可以当作是常数，所以这其实是关于 $x$ 的一维运算。

根据这个式子，可以得到：
$$
F(0,y)=\sum_{x=0}^{M-1}f(x,y)e^{-j2\pi 0 x} \\
F(1,y)=\sum_{x=0}^{M-1}f(x,y)e^{-j2\pi x/M} \\
\dots  \\
F(M-1,y)=\sum_{x=0}^{M-1}f(x,y)e^{-j2\pi (M-1)x/M}
$$
我们完全可以用矩阵相乘的形式来表示这些式子：
$$
\begin{bmatrix}
F(0,y) \\
F(1,y) \\
\dots \\
F(M-1,y)
\end{bmatrix}
=
\begin{bmatrix}
1 & 1 & \dots & 1 \\
1 & W_M^{1} & \dots & W_M^{M-1} \\
\vdots & \vdots & \vdots & \vdots \\
1& W_{M}^{M-1} & \dots & W_M^{(M-1)(M-1)}
\end{bmatrix}
\times 
\begin{bmatrix}
f(0,y) \\
f(1,y) \\
\dots \\
f(M-1, y)
\end{bmatrix}
$$
（式子中的 $W_M$ 表示 $e^{-j2\pi /M}$）

当然，由于图片是二维的，所以 $f(x,y)$ 对应的向量实际上应该是：
$$
\begin{bmatrix}
f(0,y_1) & f(0,y_2) & \dots & f(0,y_N) \\
f(1,y_1) & f(1,y_2) & \dots & f(1,y_N) \\
\dots \\
f(M-1, y_1) & f(M-1,y_2) & \dots & f(M-1,y_N)
\end{bmatrix}
$$
同理，得到的 $F(u,y)$ 也是一个二维矩阵。

现在，我们还是先考虑怎么实现这个一维的计算。

首先，需要先把 $W_M$ 这个矩阵表示出来。注意到，这个矩阵实际上可以由 $\begin{bmatrix} W_M^0 \\ W_M^1 \\ \vdots \\ W_M^{M-1} \end{bmatrix}$ $\times$ $\begin{bmatrix} W_M^0 & W_M^1 & \dots & W_M^{M-1} \end{bmatrix}$ 得到。借助 numpy 强大的矩阵处理能力，可以很方便的计算出这个矩阵。示例如下：

```python
def dftmtx(M):
    n = np.asmatrix(np.arange(M))
    return np.exp((-2j * np.pi / M) * n.transpose() * n)
```

`np.asmatrix` 是把 M 维的向量变成 1 $\times$ M 的矩阵的格式，因为只有矩阵才有 `transpose()` 操作。`np.exp` 会把 $exp$ 函数作用到矩阵的每个元素中。

得到这个矩阵后，最关键的一步其实就做完了，我们可以用这个矩阵计算出 $F(u,y)$：

```python
# input表示输入图像，M是图像的高
M = input.shape[0]
F = dftmtx(M) * input
```

得到 $F(u,y)$ 后，剩下的是要对 y 这一维进行同样的操作：$F(u,v)=\frac{1}{MN}\sum_{y=0}^{N-1}F(u,y) e^{-j2\pi vy/N}$。同样地，我们需要计算一个 $W_N$ 的矩阵。幸运的是，这个矩阵的计算方法和之前的 $W_M$ 一模一样，这样一来，我们已经可以得到完整的计算方法了：

```python
# 傅立叶变换函数
def dft2d(input):
    M, N = input.shape[0], input.shape[1]
    return dftmtx(M) * input * dftmtx(N) / (M * N)
```

接下来我们把频谱图打印出来。傅立叶频谱图是实部和虚部的平方和，需要注意的是，由于数值显示的问题，我们需要将频谱图用 `log` 函数增强后，再标定到 [0, 255] 之间才能看清。代码如下：

```python
# 将像素值标定到[0，255]之间
def scale_intensity(image):
    min = image.min()
    max = image.max()
    image = (image - min) / (max - min) * 255.0
    return image

# 计算频谱图
def spectrogram(image):
    dft = dft2d(image)
    spec = np.sqrt(np.power(np.real(dft), 2) + np.power(np.imag(dft), 2))
    spec = np.log(0.5 + spec) * 10
    spec = scale_intensity(spec)
    return spec
 
image = cv2.imread("your_file.png", cv2.IMREAD_GRAYSCALE)
spec = spectrogram(image)
cv2.imwrite("spec.png", spec)
```

结果展示：

<figure>

<img src="/images/2017-10-15/03.png" width="250px">

<img src="/images/2017-10-15/spec.png" width="250px">

</figure>

上一幅图是原图，下面的图是频谱图。如果仔细看的话，可以发现频谱图四个角有一些白色的点。这是因为图片中低频成分居多，而频谱图四个角代表的就是低频分量（至于为什么四个角是低频，我也没搞懂）。

实践中，人们习惯于把低频都聚集到图片中心，这样方便后续的操作。根据平移性质：
$$
F(u-\frac{M}{2},v-\frac{N}{2}) =f(x,y)(-1)^{x+y}
$$
要把频谱图的低频部分平移到中心，需要将整个频谱图平移 $(M/2, N/2)$ 个单位，也就是需要对原图乘以 $(-1)^{x+y}$。代码如下：

```python
def shift_image(image):
    M, N = image.shape[0], image.shape[1]
    for x in range(M):
        for y in range(N):
            image[x, y] *= np.power(-1, x + y)
    return image

  
image = cv2.imread("your_file.png", cv2.IMREAD_GRAYSCALE)
shift_image(image)
spec = spectrogram(image)
cv2.imwrite("shift_spec.png", spec)
```

结果展示：

<figure>

<img src="/images/2017-10-15/shift_spec.png" width="250px">

</figure>

### 离散傅立叶反变换

讲完傅立叶变换后，反变换基本也得到了，唯一的区别是，这一次我们需要计算一个傅立叶反变换的矩阵。这个矩阵和之前计算的矩阵 $W_M$ 的区别只在于符号，这里就直接给出代码了：

```python
def idftmtx(M):
    n = np.asmatrix(np.arange(M))
    # 下面的符号是正的
    return np.exp((2j * np.pi / M) * n.transpose() * n)
```

反变换的代码如下：

```python
def idft2d(input):
    M, N = input.shape[0], input.shape[1]
    return idftmtx(M) * input * idftmtx(N)
```

把之前得到的傅立叶变换的结果，输入 `idft2d` 函数后，再取实部既可以得到原图：

```python
image = cv2.imread("your_file.png", cv2.IMREAD_GRAYSCALE)
dft = dft2d(image)
idft = idft2d(dft)
cv2.imwrite("idft.png", np.real(idft))
```

结果如下：

<figure>

<img src="/images/2017-10-15/idft.png" width="250px">

</figure>

这个反变换的结果和原图是略有差别的，因为傅立叶变换时舍弃了很多高频成分。不过，由于图片中高频成分本身就比较少，所以这点差别可以忽略不计。