---
title: SVM小白教程（2）：拉格朗日对偶
data: 2018-01-03
tags: [机器学习]
categories: 机器学习
mathjax: true
---

在上一篇文章中，我们推导出了 SVM 的目标函数：
$$
\underset{(\mathbf{w},b)}{\operatorname{min}} ||\mathbf{w}|| \\  \operatorname{s.t.} \ y_i(\mathbf{w}^T\mathbf{x_i}+b) \ge \delta, \ \ i=1,...,m
$$
由于求解过程中，限制条件中的 $\delta$ 对结果不产生影响，所以简单起见我们把 $\delta$ 替换成 1。另外，为了之后求解的方便，我们会把原函数中的 $||\mathbf{w}||$ 换成 $\frac{1}{2}||\mathbf{w}||^2$，优化前者跟优化后者，最终的结果是一致的。这样，我们就得到 SVM 最常见的目标函数：
$$
\begin{align}
&\underset{(\mathbf{w},b)}{\operatorname{min}} \frac{1}{2}\mathbf{w}^2 \tag{1} \\  \operatorname{s.t.} \ y_i  (\mathbf{w}^T & \mathbf{x_i}+b) \ge 1,  \ i=1,...,m  \notag
\end{align}
$$
现在，我们要开始着手来解这个函数。
这篇文章想谈一谈拉格朗日对偶的问题，这也是求解 SVM 最经典的方法（考虑到我不是数学专业出身，所以很多问题只能「肤浅」着讲了）。
<!--more-->

## 拉格朗日对偶
对于（1）式中的问题，如果限制条件是等号的话，我们是可以用[拉格朗日乘子法](https://jermmy.github.io/2017/07/27/2017-7-27-understand-lagrange-multiplier/)求解的，然而这里的不等号却让问题变得复杂了一点。而拉格朗日对偶就是为了将复杂的问题简单化。

### 对偶问题
先看一个简单的线性规划问题：
$$
\underset{x,y}{\operatorname{min}} x+3y \\
s.t. \ x+y \ge 2 \\
x,y \ge 0
$$
要求 $x+3y$ 的最小值，可以通过变换目标函数来获得：
$$
x+y+2y \ge 2 + 2 \times 0 = 2
$$

所以 $x+3y$ 的最小值是 2。

如果将问题泛化：
$$
\underset{x,y}{\operatorname{min}} px+qy \tag{2} \\
s.t. \ x+y \ge 2  \\
x,y \ge 0 
$$
同样地，通过这种拼凑的方法，我们可以将问题变换为：
$$
\begin{align}
a(x+y) &\ge 2a  \notag \\
bx &\ge 0 \notag\\
cy &\ge 0 \notag\\
a(x+y)+bx+cy&=(a+b)x+(a+c)y \ge 2a \tag{3}
\end{align}
$$
其中，$a,b,c > 0$。

（3）式对 $\forall a,b,c > 0$ 均成立。不管 $a+b$、$a+c$ 的值是多少，$(a+b)x+(a+c)y$ 的最小值都是 $2a$。因此，我们可以加上约束：$a+b=p$、$a+c=q$，这样就得到 $px+qy$ 的最小值为 $2a$。需要注意的是，$2a$ 是 $px+qy$ 的下界，即这个最小值对 $\forall a$ 都要成立，所以，需要在约束条件内求出 $a$ 的最大值，才能得出 $px+qy$ 的最小值。

这样一来，问题就转换为：
$$
\begin{eqnarray}
\underset{a,b,c} {\operatorname {max}}\ {2a}   \tag{4} \\
s.t. \ p=a+b \notag\\
q = a+c \notag\\ 
a,b,c \ge 0 \notag
\end{eqnarray}
$$
（4）式就是（2）式的对偶形式。

**对偶**和**对称**有异曲同工之妙。所谓对偶，就是把原来的最小化问题（2）转变为最大化问题（4）。这种转化对最终结果没有影响，但却使问题更加简单（问题（4）中的限制条件都是等号，而不等号只是针对单个变量 $a,b,c$，因此可以直接套用拉格朗日乘子法）。

另外，对偶分**强对偶**和**弱对偶**两种。借用上面的例子，强对偶指的是 $px+qy$ 的最小值就等于 $2a$ 的最大值，而弱对偶则说明，$px+qy$ 的最小值大于 $2a$ 的最大值。SVM 属于强对偶问题。

### 线性规划问题的对偶问题

现在，我们把问题再上升到一般的线性规划问题：
$$
\begin{eqnarray}
\underset{x \in \mathbb{R}^n} {\operatorname{min}} c^Tx \tag{5} \\
s.t. \ Ax=b \notag \\
Gx \le h \notag
\end{eqnarray}
$$
用同样的方法进行转换：
$$
\begin{align}
-u^TAx & =-b^Tu \notag \\
-v^TGx & \ge -h^Tv \notag \\
(-u^TA-v^TG)x & \ge -b^Tu-h^Tu \notag
\end{align}
$$
这样，可以得到该线性问题的对偶形式：
$$
\underset{u \in \mathbb{R}^m,v \in \mathbb{R}^r} {\operatorname{max}}   -b^Tu-h^Tu  \tag{6} \\
s.t.  \  c=  -A^Tu-G^Tv  \\
v  >  \ 0
$$
这种「拼凑」的转换方法可以用拉格朗日函数作为通用的方法解决。定义原函数如下：
$$
f(x)=c^Tx
$$
引入拉格朗日函数：
$$
L(x,u,v)=f(x)+u^T(Ax-b)+v^T(Gx-h)
$$
其中，$v>0$。

由于 $Ax-b = 0$，$Gx-h \le 0$，所以必有 $f(x) \ge L(x,u,v)$，换句话说，$\underset{x}{\operatorname{min}}{f(x)} \ge \underset{x}{\operatorname{min}}{L(x,u,v)}$。因此，求 $f(x)$ 的最小值就转换为求 $L(x,u,v)$ 的最小值。
$$
\begin{align}
L(x,u,v)&=(c^T+u^TA+v^TG)x-u^Tb-v^Th   \notag 
\end{align}
$$
$\underset{x}{\operatorname{min}}{L(x,u,v)}$ 在 $x$ 没有任何限制的前提下，是不存在最小值。因此，我们要加上约束条件：$c^T+u^TA+v^TG=0$，这样，$\underset{x}{\operatorname{min}}{L(x,u,v)}=-u^Tb-v^Th$。如此一来，我们又把原问题转换到（6）中的对偶问题上了。

### 二次规划问题的对偶问题

由于 SVM 的目标函数是一个二次规划问题（带有平方项），因此我们最后再来看一个二次规划的优化问题。

假设有如下二次规划问题：
$$
\begin{equation}
\underset{x}{\operatorname{min}}\ {\frac{1}{2}x^TQx+c^Tx} \notag \\
s.t. \ Ax=b \notag \\
x \ge 0
\end{equation}
$$
其中，$Q>0$（保证有最小值）。

按照线性规划问题的思路，构造拉格朗日函数（注意，构造出来的 $L(x,u,v)$ 必须小于等于原函数 $\frac{1}{2}x^TQx+c^Tx$）：
$$
\begin{equation}
L(x,u,v)=\frac{1}{2}x^TQx+c^Tx-u^Tx+v^T(Ax-b) \notag \\
=\frac{1}{2}x^TQx+(c+v^TA-u)^Tx+v^Tb \notag 
\end{equation}
$$
由于二次函数 $ax^2+bx+c$ 的最小值在 $x=-\frac{b}{2a}$ 处取得，因此可以求得函数 $L$ 的最小值：
$$
\begin{equation}
\underset{x}{\operatorname{min}} L(x,u,v)=-\frac{1}{2}(c-u+A^Tv)^TQ^{-1}(c-u+A^Tv)-b^Tv
\end{equation}
$$
这样一来，我们就求得原问题的拉格朗日对偶问题：
$$
\begin{equation}
\underset{u,v}{\operatorname{max}}-\frac{1}{2}(c-u+A^Tv)^TQ^{-1}(c-u+A^Tv)-b^Tv \notag \\
s.t. \ u>0
\end{equation}
$$

### 拉格朗日对偶问题

现在总结一下拉格朗日对偶问题的基本「套路」。

假设原问题为：
$$
\begin{equation}
\underset{x}{\operatorname{min}}f(x)  \notag \\
s.t. \ h_i(x) \le 0, i=1,\dots,m \notag \\
l_i(x)=0, j=1,\dots,r \notag
\end{equation}
$$
则拉格朗日原始问题为：
$$
L(x,u,v)=f(x)+\sum_{i=1}^m {u_i h_i(x)}+\sum_{j=1}^r v_j l_j(x)
$$
其中，$u_i>0$。

之后，我们求出 $\underset{x}{\operatorname{min}}L(x,u,v)=g(u,v)$，将问题转换为对偶问题：
$$
\begin{equation}
\underset{u,v}{\operatorname{max}} \ g(u,v)  \notag \\
s.t. \ u \ge 0 \notag 
\end{equation}
$$
教材上通常把拉格朗日原始问题表示为 $\underset{x}{\operatorname{min}}\underset{u,v}{\operatorname{max}}L(x,u,v)$，而对偶问题表示成 $\underset{u,v}{\operatorname{max}}\underset{x}{\operatorname{min}}L(x,u,v)$。它们之间存在如下关系：
$$
\underset{x}{\operatorname{min}}\underset{u,v}{\operatorname{max}}L(x,u,v) \ge \underset{u,v}{\operatorname{max}}\underset{x}{\operatorname{min}}L(x,u,v) 
$$

## SVM的对偶问题

现在终于可以扯回 SVM 了。我们将约束条件表述成 $y_i  (\mathbf{w}^T\mathbf{x_i}+b) -1 \ge 0, \ i=1, \dots ,m$，然后，按照上面的「套路」，表示出拉格朗日原始问题：
$$
\begin{align}
L(\mathbf{w},b,\alpha)= & \frac{1}{2}\mathbf{w}^2-\sum_{i=1}^m{\alpha_i}[y_i(\mathbf{w}^T\mathbf{x_i}+b)-1] \tag{7} \\
s.t. \ \alpha_i \ge &\ 0, \ i=1, \dots, m \notag
\end{align}
$$
（乍一看，约束条件中的不等式也比较简单，直接用拉格朗日乘子法也可以解了，不过，这本[教程](http://localhost:4000/images/2017-12-23/support_vector_machines_succinctly.pdf)提到，只有样本量很少的时候才解得出来，所以我们还是转换成对偶问题求解）

下面要求出 $L(\mathbf{w},b,\alpha)$ 关于 $\mathbf{w}$ 和 $b$ 的最小值，这里可以直接通过偏导求得：
$$
\nabla_\mathbf{w} L=\mathbf{w}-\sum_{i=1}^m \alpha_iy_i \mathbf{x}_i=0 \tag{8} 
$$

$$
\frac{\partial L}{\partial b}=-\sum_{i=1}^m\alpha_i y_i=0  \tag{9}
$$

由（8）式解得：
$$
\begin{align}
\mathbf{w}=\sum_{i=1}^m \alpha_i y_i \mathbf{x}_i \tag{10}
\end{align}
$$
（10）式代入（7）式得到：
$$
W(\alpha,b)=\sum_{i=1}^m\alpha_i-\frac{1}{2}\sum_{i=1}^m\sum_{j=1}^m\alpha_i \alpha_j y_i y_j \mathbf{x}_i \mathbf{x}_j-b\sum_{i=1}^m \alpha_i y_i \tag{11}
$$
而（9）式已经表明：$\sum_{i=1}^m\alpha_i y_i=0$，所以（11）式化简为：
$$
W(\alpha)=\sum_{i=1}^m\alpha_i-\frac{1}{2}\sum_{i=1}^m\sum_{j=1}^m\alpha_i \alpha_j y_i y_j \mathbf{x}_i \mathbf{x}_j \tag{12}
$$
（12）式就是最终版本的对偶形式了。自此，我们得出 SVM 的拉格朗日对偶问题：
$$
\underset{\alpha}{\operatorname{max}} W(\alpha)   \\
s.t. \ a_i \ge 0, i=1,\dots,m \\
\sum_{i=1}^m\alpha_i y_i=0
$$
求出 $W(\alpha)$ 的最大值，就相当于求出了我们需要的参数 $\mathbf{w}$。

## 参考

+ [凸优化-对偶问题](http://www.hanlongfei.com/convex/2015/11/05/duality/)
+ [拉格朗日乘子法](https://jermmy.github.io/2017/07/27/2017-7-27-understand-lagrange-multiplier/)
+ [简易解说拉格朗日对偶（Lagrange duality）](http://www.cnblogs.com/90zeng/p/Lagrange_duality.html)
+ [支持向量机SVM（二）](http://www.cnblogs.com/jerrylead/archive/2011/03/13/1982684.html)