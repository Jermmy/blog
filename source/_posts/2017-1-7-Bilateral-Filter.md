---
title: Bilateral Filter
date: 2017-01-07
tags: Computer Vision
categories: Computer Vision
mathjax: true
---

最近在看图像风格化的论文的时候，频繁遇到Bilateral Filter。google一波后，发现并不是什么不得了的东西，但它的思想却很有借鉴意义。

### 简介

Bilateral Filter，中文又称“双边滤波器”。相比以往那些仅仅使用位置信息进行滤波的filter，Bilateral Filter还考虑了颜色信息，可以保证边缘部分不会被过滤。

简单来说，一般的filter都是基于这样的公式进行滤波的：
$$
h(x)=k\_{d}^{-1}{(x)}\iint_\infty^\infty{f(\zeta)c(\zeta, x)} d\zeta
$$
<!--more-->

其中，$k\_{d}^{-1}{(x)}$是权重之和，$f(\zeta)$可以理解为单个像素，$c(\zeta, x)$可以理解为位置权重。

翻译成程序员可以理解的语言，大概是这样：

```c++
for (int i = -r; i <= r; i++) {
  for (int j = -r; j <= +r; j++) {
    newpixel += pixel[row+i][col+j] * c[i][j];
    k += c[i][j];
  }
}
pixel[row][col] = newPixel / k;
```

高斯函数也属于这类filter。

但这种filter有一个缺点：各向同性（不知道这个理解对不对）。用这种滤波器，每个点受邻居的影响是一样的，即使它跟邻居像素可能差得比较多，也会被邻居“同化”（举个例子：边缘被“和谐”掉了）。因此，有人提出了Bilateral Filter。

Bilateral Filter采用这样的公式：
$$
h(x)=k\_{d}^{-1}{(x)}\iint_\infty^\infty{f(\zeta)c(\zeta, x)s(f(\zeta), f(x))} d\zeta
$$
对比之前的式子，最大的变化无非是权值中增加了一个$s(f(\zeta), f(x))$，这个东西也是权值，不过它不是采用位置信息，而是颜色信息$f(\zeta)$。不管是哪种信息，形势上来看都是一样的，但由于增加了颜色权值，却使滤波的结果有了明显不同，后面会给出效果图。

再次翻译成程序语言：

```c++
for (int i = -r; i <= r; i++) {
  for (int j = -r; j <= +r; j++) {
    newpixel += pixel[row+i][col+j] * c[i][j] * s(pixel[row][col], pixel[row+i][col+j]);
    k += c[i][j]*s(pixel[row][col], pixel[row+i][col+j]);
  }
}
pixel[row][col] = newPixel / k;
```

s函数可以借鉴位置权值的思路。例如，可以采用这种方式定义（当然这个是我自己构造的）：

```c++
function s(p1, p2) {
  return (255-abs(p1-p2)) / 255
}
```

这样，差的越多的颜色，所占权值越小。

如果要追求科学严谨一点，也不妨仿照高斯核函数的定义：
$$
c(\zeta-x) = e^{-{1\over2}({ {\zeta-x} \over {\sigma} } )^2}  \\\\\\
s(\zeta-x) = e^{-{1\over2}({ {f(\zeta)-f(x)} \over \sigma })^2}
$$
<br\>

### 代码实现

理解原理后，实现其实也很简单，上面给出的伪代码基本是核心算法了。另外需要注意的是，如果是彩色图的话，需要对每个通道的颜色值进行滤波。

具体实现可以参考这篇博客：[图像处理之双边滤波效果(Bilateral Filtering for Gray and Color Image)](http://blog.csdn.net/jia20003/article/details/7740683)，或者参考我自己的 [demo](https://github.com/Jermmy/BilateralFilter)，当然，我也只是将上面博客的java版改成c++而已^0^。

给出几幅结果图：

**原图**：

![lena](/images/2017-1-7/lena.jpg)

**高斯模糊**：

![gau_blur](/images/2017-1-7/gau_blur.jpg)

**仅仅用颜色信息滤波**：

![simi_blur](/images/2017-1-7/simi_blur.jpg)

**双边滤波：**

![blur](/images/2017-1-7/blur.jpg)

仔细对比一下，双边滤波对边缘的保留效果比高斯滤波好太多了，这一点从第三幅图就可以知晓缘由了。

另外！！如果使用高斯核函数来实现双边滤波，颜色卷积和的$\sigma$要取大一点的值，比如：50。否则，由于不同颜色的差值往往比位置差值大出许多（举个例子：50和60两种像素值肉眼上看很接近，但却差出10，平方一下就是100），可能导致很相近的像素点权值很小，最后跟没滤波的效果一样。

<br\>

### 启发

Bilateral Filter的思想是：在位置信息的基础上加上颜色信息，相当于考虑两个权值。如果还要考虑其他重要因素，是不是可以再加进一个权值，构成一个三边滤波器呢？答案当然是可以的，由此，我们可以把很多简单的滤波器综合起来形成一个更强大的滤波器。（嗯，我好像知道了什么）

<br\>

### 参考

[图像处理之双边滤波效果(Bilateral Filtering for Gray and Color Image)](http://blog.csdn.net/jia20003/article/details/7740683)

[双边滤波器](https://zh.wikipedia.org/wiki/%E9%9B%99%E9%82%8A%E6%BF%BE%E6%B3%A2%E5%99%A8)





















​                          

