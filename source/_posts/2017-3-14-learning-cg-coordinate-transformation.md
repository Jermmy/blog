---
title: 坐标系统之间的转换
date: 2017-03-14
tags: [Computer Graphics, Linear Algebra, OpenGL]
categories: [Computer Graphics]
mathjax: true
---

**（阅读本文需要有线性代数基础。）**
### 概要
这篇文章中，我们来聊聊OpenGL中的坐标系统以及它们之间的转换。
### 坐标变换原理
首先，我们需要运用一点线性代数的知识，了解不同坐标系统变换的原理。
由于本文针对的是三维坐标，所以讨论的空间是$R^3$空间。
<!--more-->
在标准三维坐标系中，我们通常用一个向量**v**=[x, y, z]来表示一个点的位置。这里的x、y、z分别对应x轴、y轴以及z轴三个方向的偏移，而标准三维坐标空间的基采用的是三个互相垂直的向量$\mathbf e_1=[1,0,0], \mathbf e_2=[0,1,0], \mathbf e_3=[0,0,1]$。但根据线性无关等知识，我们完全可以找出另外三个向量作为三维空间的基，只要这三个向量线性无关，同样能够张成$R^3$空间。

现在，假设坐标系A采用的基向量是{$\mathbf v_1, \mathbf v_2, \mathbf v_3$}，坐标系B采用的是{$\mathbf u_1, \mathbf u_2, \mathbf u_3$}。
那么，根据线性无关性，我们可以得到线性方程组：
${\mathbf u\_1 = \gamma\_{11}\mathbf v\_1+\gamma\_{12}\mathbf v\_2+\gamma\_{13}\mathbf v\_3}$ 
$\mathbf u\_2 = \gamma\_{21}\mathbf v\_1+\gamma\_{22}\mathbf v\_2+\gamma\_{23}\mathbf v\_3$
$\mathbf u\_3 = \gamma\_{31}\mathbf v\_1+\gamma\_{32}\mathbf v\_2+\gamma\_{33}\mathbf v\_3$
用矩阵方程的形式表示为：$\mathbf u = \mathbf M \mathbf v$。
由于$\mathbf u, \mathbf v$都是三维空间的基，因此，对于三维空间内任意一个向量$\mathbf w$，$\mathbf u、\mathbf v$都可以通过线性组合的方式表示出$\mathbf w$：
$\mathbf w = \mathbf a^T \mathbf v = \mathbf b^T \mathbf u$（这里的$\mathbf a^T, \mathbf b^T$分别表示不同坐标空间的标量）。
结合前面$\mathbf u = \mathbf M \mathbf v$，进一步得到：$\mathbf w = \mathbf b^T \mathbf u = \mathbf b^T \mathbf M \mathbf v=\mathbf a^T \mathbf v$，
继而 ：$\mathbf a = \mathbf M^T \mathbf b$，$\mathbf b = (\mathbf M^T)^{-1} \mathbf a$。

好了，到这里，关键的东西就讲完了。所以坐标系统的变换很简单有木有！如果你在B坐标系（基向量为{$\mathbf u_1, \mathbf u_2, \mathbf u_3$}）中有个向量$\mathbf w$，沿用上面的假设，$\mathbf w$的坐标为$\mathbf b$（即$\mathbf w = \mathbf b^T \mathbf u$），这个时候，我们想求出它在A坐标系（基向量为{$\mathbf v_1, \mathbf v_2, \mathbf v_3$}）的坐标表示（假设为$\mathbf a$），我们只需要求出矩阵$\mathbf M$，则：$\mathbf a = \mathbf M^T \mathbf b$。
反之同理。

这个时候，有同学可能会问矩阵$\mathbf M$怎么求？
假设一个坐标系统的基向量为{$\mathbf u_1, \mathbf u_2, \mathbf u_3$}，而另一个系统采用标准向量{$\mathbf e_1, \mathbf e_2, \mathbf e_3$}，假设存在关系：$\mathbf u = \mathbf M^T \mathbf e$（这个式子的理解是：如果$\mathbf M$是两个坐标系统的变换矩阵，那么两个系统内的任意向量可以通过这个矩阵相互转换，基向量只不过是特殊的向量，一样可以通过$\mathbf M$进行转换），那矩阵$\mathbf M$其实可以表示为[$\mathbf u_1, \mathbf u_2, \mathbf u_3$]。这个结果其实很好理解，只要换种写法：
$\mathbf u =   \begin{bmatrix}
    \mathbf u_1   \\\\
    \mathbf u_2    \\\\
    \mathbf u_3    \\\\
   \end{bmatrix}$，$\mathbf e = \begin{bmatrix}
    \mathbf e_1   \\\\
    \mathbf e_2    \\\\
    \mathbf e_3    \\\\
   \end{bmatrix}$，可以发现，$\mathbf e$其实是一个单位矩阵。
而如果是非标准坐标系统之间的变换，则需要解一个线性方程组：$\mathbf u = \mathbf M^T \mathbf v$，而且可以肯定，这个解存在且唯一。

尽管从上面的推论中我们可以得出，不同坐标系统可以通过一个唯一的3*3矩阵$\mathbf M$来变换，但都是基于坐标原点相同的前提。如果原点也发生变化，这时就必须引入第四个维度来表示平移的偏移量，也就是常说的齐次坐标。
引入第四维后，$\mathbf u=[\mathbf u_1,\mathbf u_2,\mathbf u_3,\mathbf p]$，$\mathbf v=[\mathbf v_1,\mathbf v_2,\mathbf v_3,\mathbf q]$，我们再次用一个矩阵$\mathbf M$来转换这两个坐标系统，不同的是，这里的$\mathbf M$是一个4*4的矩阵：
$\mathbf M= \begin{bmatrix}
\gamma\_{11} & \gamma\_{12} & \gamma\_{13} & 0 \\\\
\gamma\_{21} & \gamma\_{22} & \gamma\_{23} & 0 \\\\
\gamma\_{31} & \gamma\_{32} & \gamma\_{33} & 0 \\\\
\gamma\_{41} & \gamma\_{42} & \gamma\_{43} & 1 \\\\
\end{bmatrix}$，$\mathbf u = \mathbf M^T * \mathbf v$。
除了多出一维外，齐次坐标与上面使用的三维坐标本质上没有区别，计算方法也基本一致，在对应到三维坐标系时，只需要舍弃第四个维度即可。


### OpenGL中的坐标系统
OpenGL的坐标系统有六种：
1. Object (or model) coordinates
2. World coordinates
3. Eye (or camera) coordinates
4. Clip coordinates
5. Normalized device coordinates
6. Window (or screen) coordinates

模型坐标系(Object coordinates)是每个模型在制作时特有的，如果要把模型放入世界，就需要将所有模型的坐标系转换成世界坐标系(World coordinates)。世界中的场景需要通过相机被人眼观察，需要将世界坐标系转换成相机坐标系(Eye coordinates)。从模型坐标系，到世界坐标系，再到相机坐标系的变换，通常称为model-view transformation，通过model-view matrix来实现。
前三种坐标系统通常是由用户指定的，而后三种坐标系统一般都是在OpenGL管道中，由程序自己实现的。
而OpenGL中坐标系统转换的原理，其实就是上面所讲的那些，只不过在使用时，我们可以使用一些API来简化不少工作。

### 参考
Interactive Computer Graphics - A Top-Down Approach 6e By Edward Angel and Dave Shreiner (Pearson, 2012)











