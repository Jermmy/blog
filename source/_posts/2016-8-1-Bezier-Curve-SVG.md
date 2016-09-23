---
layout: post
title: 从贝塞尔曲线反推控制点
date: 2016-08-01 23:17:19
tags: SVG
categories: SVG
mathjax: true
---

由之前的文章我们可以得到贝塞尔曲线的方程，今天要通过贝塞尔曲线(三次)重新推出控制点。

### 需求

在得到并对贝塞尔曲线做完处理后，为了让浏览器重新渲染贝塞尔曲线，必须通过贝塞尔曲线重新取得控制点坐标。

<!--more-->

### 准备条件

了解SVG的path中C/c相关指令的用法，还有相对位置等一些概念。最好能提前获得贝塞尔曲线的表达式。

### 解决方案

假设我们已经得到了贝塞尔曲线的表达式：
$$
\overline{P^3} = (1-t)^3\overline{P\_{0}} + 3t(1-t)^2\overline{P\_{1}}+3t^2(1-t)\overline{P\_{2}}+t^3\overline{P\_{3}}  \ \ \ \ \ \ (1)
$$
其中，$ \overline{P^3} $是三次贝塞尔曲线上的点，$\overline{P\_{0}} 、\overline{P\_{1}}、\overline{P\_{2}}、\overline{P\_{3}}$ 分别是贝塞尔曲线的控制点，因为$\overline{P\_{0}} 、\overline{P\_{3}}$本身就是贝塞尔曲线的两个端点，所以它们的坐标是事先知道的，我们的目标是要求出$\overline{P\_{1}}、\overline{P\_{2}}$。注意到，贝塞尔曲线的点是t由0逐渐增加到1的过程中采样得到的（数学上需要对t取极限，但计算机是离散的，所以称为采样），因为项目中，我是通过原控制点得到贝塞尔曲线后，对曲线做形变处理，然后再反推控制点，所以我只需要在原来的贝塞尔曲线表达式中分别取t=$\frac{1}{3}$和$\frac{2}{3}$(t的取值可以是0到1之间任意实数，当然不能是0和1，不然就和端点重合了)，就可以得到两个$\overline{P^3}$点的坐标，形变处理完后，我同样**近似**地认为这两个点是新曲线中t取$\frac{1}{3}$和$\frac{2}{3}$的坐标点。这样，我们相当于知道了四个点的坐标，对于一个二元一次方程，我们由这四个点可以得到两组方程，最终一定可以把$\overline{P\_{1}} 、\overline{P\_{2}}$解出来。对于原表达式不知道的情况，可以根据端点坐标来近似取点，具体可以看参考链接。

#### step1

对于(1)式，令t＝$\frac{1}{3}$，我们得到：
$$
\overline{P^3}=(\frac{2}{3})^3\overline{P\_{0}}+(\frac{2}{3})^2\overline{P\_{1}}+3(\frac{1}{3})^2\frac{2}{3}\overline{P\_{2}}+(\frac{1}{3})^3\overline{P\_{3}}    \\\\
\overline{P^3}-\frac{8}{27}\overline{P\_{0}}-\frac{1}{27}\overline{P\_{3}}=\frac{4}{9}\overline{P\_{1}}+\frac{2}{9}\overline{P\_{2}}    \ \ \ \ \ \ \ \ (2)
$$
因为$\overline{P^3}$、$\overline{P\_{0}}$、$\overline{P\_{3}}$的坐标是事先已知的，所以可以设$\overline{P^3}-\frac{8}{27}\overline{P\_{0}}-\frac{1}{27}\overline{P\_{3}}$为$\overline{B}$。我们设$\overline{P\_{1}}$、$\overline{P\_{2}}$的坐标分别为(x1, y1)、(x2, y2)，$\overline{B}$的坐标为($x\_{b}$, $y\_{b}$)，由(2)式可以得到如下方程：
$$
\frac{4}{9}x\_{1}+\frac{2}{9}x\_{2}=x\_{b}     \\\\
\frac{4}{9}y\_{1}+\frac{2}{9}y\_{2}=y\_{b}
$$

#### step2

按照step1的思路，令t=$\frac{2}{3}$，可以得到：
$$
\overline{P^3}-\frac{1}{27}\overline{P\_{0}}-\frac{8}{27}\overline{P\_{3}}=\frac{2}{9}\overline{P\_{1}}+\frac{4}{9}\overline{P\_{2}}    \ \ \ \ \ \ \ \ (3)
$$
令$\overline{P^3}-\frac{1}{27}\overline{P\_{0}}-\frac{8}{27}\overline{P\_{3}}$为$\overline{C}$，设$\overline{C}$的坐标为($x\_{c}$, $y\_{c}$)，同样的可以得到另一组方程：
$$
\frac{2}{9}x\_{1}+\frac{4}{9}x\_{2}=x\_{c}     \\\\
\frac{2}{9}y\_{1}+\frac{4}{9}y\_{2}=y\_{c}
$$

#### step3

联立step1和step2的方程组，最终可以吧$\overline{P\_{1}}$、$\overline{P\_{2}}$的坐标求出来。
$$
x\_{1}=3x\_{b}-\frac{3}{2}x\_{c}     \\\\
y\_{1}=3y\_{b}-\frac{3}{2}y\_{c}      \\\\
x\_{2}=3x\_{c}-\frac{3}{2}x\_{b}      \\\\
y\_{2}=3y\_{c}-\frac{3}{2}y\_{b}
$$

### 代码实现

```c++
/**
* 计算第二，第三个控制点的坐标
**/
void get_control_points(Point &p1, Point &thirdOne, Point &thirdTwo, 
	Point &p4, Point &p2, Point &p3) {
	double xb1, yb1, xb2, yb2;   // 计算的中间变量
	double f1 = 0.037037037037037037037; // (1/3)^3
    double f2 = 0.296296296296296296296; // (2/3)^3
    double x2, y2, x3, y3;    // 返回的p2、p3的坐标
	xb1 = thirdOne.x - f2 * p1.x - f1 * p4.x;
	yb1 = thirdOne.y - f2 * p1.y - f1 * p4.y;
	xb2 = thirdTwo.x - f1 * p1.x - f2 * p4.x;
	yb2 = thirdTwo.y - f1 * p1.y - f2 * p4.y;
	x2 = 3 * xb1 - 3 / (double)2 * xb2;
	y2 = 3 * yb1 - 3 / (double)2 * yb2;
	x3 = 3 * xb2 - 3 / (double)2 * xb1;
	y3 = 3 * yb2 - 3 / (double)2 * yb1;
	p2.x = (int)x2;
	p2.y = (int)y2;
	p3.x = (int)x3;
	p3.y = (int)y3;
}

/**
* points里面，除了贝塞尔曲线前后的端点外，还包括曲线上1/3和2/3位置的点。
* 返回贝塞尔曲线的控制点
*/
vector<Point> regain_new_points(vector<Point>& points) {
	vector<Point> newPoints;

	for (int i = 0; i < points.size()-1; i+=3) {
		Point p2, p3;
		get_control_points(points[i], points[i+1], points[i+2], 
			points[i+3], p2, p3);
		if (i == 0) {
			newPoints.push_back(points[i]);
		}
		newPoints.push_back(p2);
		newPoints.push_back(p3);
		newPoints.push_back(points[i+3]);	
	}
	return newPoints;
}
```

#### 测试结果

![test](/images/2016-8-1/屏幕快照 2016-08-02 下午2.22.14.png)

右图的脸为原svg在浏览器中的展示效果，左图的脸部轮廓白点为根据svg的控制点绘制出贝塞尔曲线后，再根据贝塞尔曲线反推的控制点坐标，而左图的脸部曲线则是根据这些控制点绘制出的贝塞尔曲线。从效果上看，两张人脸的轮廓基本很相似。

接下来，我对贝塞尔曲线做了平移、缩放和旋转，看看重新推出的控制点以及贝塞尔曲线的情况：

平移操作

![translate](/images/2016-8-1/translate.jpg)

缩放操作

![scale](/images/2016-8-1/scale.jpg)

旋转操作

![rotate](/images/2016-8-1/rotate.jpg)

看得出，这些基本的线性变换都不会导致贝塞尔曲线“失真”:-)，这是个好消息。

### 参考

[Algorithm for deriving control points of a bezier curve from points along that curve?](http://stackoverflow.com/questions/19217546/algorithm-for-deriving-control-points-of-a-bezier-curve-from-points-along-that-c)



















