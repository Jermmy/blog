---
title: SVM小白教程（2）：拉格朗日对偶
data: 2018-01-03
tags: [机器学习, 优化理论]
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
<!--more-->

## 拉格朗日乘子法
对于（1）式中的问题，如果限制条件是等号的话，我们是可以直接用[拉格朗日乘子法](https://jermmy.github.io/2017/07/27/2017-7-27-understand-lagrange-multiplier/)求解的。而为了应对不等号的情况，研究人员提出了 KKT 条件下的拉格朗日乘子法。所谓 KKT 条件，我们可以简单地把它当作拉格朗日乘子法的进阶版，只要原优化问题满足几个特定的条件，就可以仿照拉格朗日乘子法来求解问题。（关于 KKT 条件的具体内容，博主没有仔细研究过）。

而 SVM 原问题，刚好满足这些条件。因此可以直接套用拉格朗日乘子法的流程，首先列出拉格朗日函数：
$$
L(\mathbf w, b, \mathbf \alpha)=\frac{1}{2}||\mathbf w||^2-\sum_{i=1}^n\alpha_i(y_i(\mathbf w^T \mathbf x_i + b)-1) \\
s.t. \alpha_i \ge 0   \tag{2}
$$
（注意，在 KKT 条件下，需要满足 $\alpha_i \ge 0$）

然后，令 $\frac{\partial L}{\partial \mathbf w}=0$，$\frac{\partial L}{\partial b}=0$，可以得到方程组：
$$
\frac{\partial L}{\partial \mathbf w}=\mathbf w-\sum_{i=1}^n\alpha_i y_i \mathbf x_i=0   \tag{3}
$$

$$
\frac{\partial L}{\partial b}=\sum_{i=1}^n \alpha_i y_i=0   \tag{4}
$$

在约束条件是等式的情况中，我们还会根据 $\frac{\partial L}{\partial \mathbf \alpha}=0$ 得到另外几组方程，然后可以解出 $\mathbf w$ 和 $b$。

不过，由于现在约束条件是不等式，所以 $\frac{\partial L}{\partial \mathbf \alpha}$ 得到的是一堆不等式：
$$
y_i (\mathbf w \mathbf x_i+b)-1 \ge 0 \ \ i=1,2,\dots,N
$$
这样是没法直接解出 $\mathbf w$ 和 $b$ 的。

为了让方程组的形式更加简单，我们可以联立 (2)(3)(4) 把 $\mathbf w$ 和 $b$ 消掉（后文有详细的推导过程）：
$$
L(\mathbf w,b, \mathbf \alpha)=\sum_{i=1}^n \alpha_i - \frac{1}{2}\sum_{i=1}^n \sum_{j=1}^n \alpha_i \alpha_j y_i y_j \mathbf x_j^T \mathbf x_i   \tag{5}
$$
到这一步，熟悉优化的同学应该发现，我们已经把原问题转化为拉格朗日对偶问题。换句话说，我们接下来要优化的问题就变为：
$$
\underset{\alpha}{\operatorname{max}} \sum_{i=1}^n \alpha_i - \frac{1}{2}\sum_{i=1}^n \sum_{j=1}^n \alpha_i \alpha_j y_i y_j \mathbf x_j^T \mathbf x_i  \tag{6}  \\
s.t. \ a_i \ge 0, i=1,\dots,m \\
\sum_{i=1}^m\alpha_i y_i=0
$$

## 拉格朗日对偶问题

博主刚开始接触拉格朗日对偶的时候，一直搞不懂为什么一个**最小化**的问题可以转换为一个**最大化**问题。直到看了这篇[博文](http://www.hanlongfei.com/convex/2015/11/05/duality/)后，才对它有了形象的理解。所以，下面我就根据这篇博文，谈谈我对拉格朗日对偶的理解。

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
\underset{x,y}{\operatorname{min}} px+qy \tag{7} \\
s.t. \ x+y \ge 2  \\
x,y \ge 0
$$
同样地，通过这种拼凑的方法，我们可以将问题变换为：
$$
\begin{align}
a(x+y) &\ge 2a  \notag \\
bx &\ge 0 \notag\\
cy &\ge 0 \notag\\
a(x+y)+bx+cy&=(a+b)x+(a+c)y \ge 2a \tag{8}
\end{align}
$$
其中，$a,b,c > 0$。

（8）式对 $\forall a,b,c > 0$ 均成立。不管 $a+b$、$a+c$ 的值是多少，$(a+b)x+(a+c)y$ 的最小值都是 $2a$。因此，我们可以加上约束：$a+b=p$、$a+c=q$，这样就得到 $px+qy$ 的最小值为 $2a$。需要注意的是，$2a$ 是 $px+qy$ 的下界，即这个最小值对 $\forall a$ 都要成立，所以，需要在约束条件内求出 $a$ 的最大值，才能得出 $px+qy$ 的最小值。

这样一来，问题就转换为：
$$
\begin{eqnarray}
\underset{a,b,c} {\operatorname {max}}\ {2a}   \tag{9} \\
s.t. \ p=a+b \notag\\
q = a+c \notag\\ 
a,b,c \ge 0 \notag
\end{eqnarray}
$$
（9）式就是（7）式的对偶形式。

**对偶**和**对称**有异曲同工之妙。所谓对偶，就是把原来的最小化问题（7）转变为最大化问题（9）。这种转化对最终结果没有影响，但却使问题更加简单（问题（9）中的限制条件都是等号，而不等号只是针对单个变量 $a,b,c$，因此可以直接套用拉格朗日乘子法）。

另外，对偶分**强对偶**和**弱对偶**两种。借用上面的例子，强对偶指的是 $px+qy$ 的最小值就等于 $2a$ 的最大值，而弱对偶则说明，$px+qy$ 的最小值大于 $2a$ 的最大值。SVM 属于强对偶问题。

### 线性规划问题的对偶问题

现在，我们把问题再上升到一般的线性规划问题：
$$
\begin{eqnarray}
\underset{x \in \mathbb{R}^n} {\operatorname{min}} c^Tx \tag{10} \\
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
\underset{u \in \mathbb{R}^m,v \in \mathbb{R}^r} {\operatorname{max}}   -b^Tu-h^Tu  \tag{11} \\
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
$\underset{x}{\operatorname{min}}{L(x,u,v)}$ 在 $x$ 没有任何限制的前提下，是不存在最小值。因此，我们要加上约束条件：$c^T+u^TA+v^TG=0$，这样，$\underset{x}{\operatorname{min}}{L(x,u,v)}=-u^Tb-v^Th$。如此一来，我们又把原问题转换到（11）中的对偶问题上了。

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

现在看回 SVM。我们将约束条件表述成 $y_i  (\mathbf{w}^T\mathbf{x_i}+b) -1 \ge 0, \ i=1, \dots ,m$，然后，按照上面的「套路」，表示出拉格朗日原始问题：
$$
\begin{align}
L(\mathbf{w},b,\alpha)= & \frac{1}{2}\mathbf{w}^2-\sum_{i=1}^m{\alpha_i}[y_i(\mathbf{w}^T\mathbf{x_i}+b)-1] \tag{12} \\
s.t. \ \alpha_i \ge &\ 0, \ i=1, \dots, m \notag
\end{align}
$$
下面要求出 $L(\mathbf{w},b,\alpha)$ 关于 $\mathbf{w}$ 和 $b$ 的最小值，这里可以直接通过偏导求得：
$$
\nabla_\mathbf{w} L=\mathbf{w}-\sum_{i=1}^m \alpha_iy_i \mathbf{x}_i=0 \tag{13}
$$

$$
\frac{\partial L}{\partial b}=-\sum_{i=1}^m\alpha_i y_i=0  \tag{14}
$$

由（13）式解得：
$$
\begin{align}
\mathbf{w}=\sum_{i=1}^m \alpha_i y_i \mathbf{x}_i \tag{15}
\end{align}
$$
（15）式代入（12）式得到：
$$
W(\alpha,b)=\sum_{i=1}^m\alpha_i-\frac{1}{2}\sum_{i=1}^m\sum_{j=1}^m\alpha_i \alpha_j y_i y_j \mathbf{x}_i \mathbf{x}_j-b\sum_{i=1}^m \alpha_i y_i \tag{16}
$$
而（14）式已经表明：$\sum_{i=1}^m\alpha_i y_i=0$，所以（16）式化简为：
$$
W(\alpha)=\sum_{i=1}^m\alpha_i-\frac{1}{2}\sum_{i=1}^m\sum_{j=1}^m\alpha_i \alpha_j y_i y_j \mathbf{x}_i \mathbf{x}_j \tag{17}
$$
（17）式就是最终版本的对偶形式了（上文的 (6) 式其实也是这样推出来的）。自此，我们得出 SVM 的拉格朗日对偶问题：
$$
\underset{\alpha}{\operatorname{max}} W(\alpha)   \\
s.t. \ a_i \ge 0, i=1,\dots,m \\
\sum_{i=1}^m\alpha_i y_i=0
$$
解出 $\mathbf \alpha$ 后，就可以根据 (15) 式解出 $\mathbf w$，然后根据超平面的间隔求出 $b$。

当然，这个对偶形式的优化问题依然不是那么容易解的，研究人员提出了一种 [SMO 算法](https://en.wikipedia.org/wiki/Sequential_minimal_optimization)，可以快速地求解 $\mathbf \alpha$。不过算法的具体内容，本文就不继续展开了。

## 参考

+ [凸优化-对偶问题](http://www.hanlongfei.com/convex/2015/11/05/duality/)
+ [拉格朗日乘子法](https://jermmy.github.io/2017/07/27/2017-7-27-understand-lagrange-multiplier/)
+ [简易解说拉格朗日对偶（Lagrange duality）](http://www.cnblogs.com/90zeng/p/Lagrange_duality.html)
+ [支持向量机SVM（二）](http://www.cnblogs.com/jerrylead/archive/2011/03/13/1982684.html)
+ [第7课 支持向量机，为什么能理解SVM的人凤毛麟角？](https://www.youtube.com/watch?v=Cz144VkaRUQ)

