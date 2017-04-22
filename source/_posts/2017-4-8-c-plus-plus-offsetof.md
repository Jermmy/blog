---
title: C++ offsetof
date: 2017-04-08 11:49:40
tags: [C++]
categories: C++
---

今天写 OpenGL 时，发现一个 C/C++ 中可能很实用但出现频率较低的函数： `offsetof(type, member)`。

严格来说，这只是一个宏定义。其中的 `type` 表示一个数据结构（ struct 或者 class ），`member` 表示这个结构的成员。这个函数会返回一个 `size_t` 类型的数值，表示这个 `member` 在这个数据结构中的位置（以字节为单位）。

<!--more-->

看个例子（改自 [C++官网](http://www.cplusplus.com/reference/cstddef/offsetof/) ）：

```c++
#include <iostream>

using namespace std;

struct foo {
    char a;
    char b[10];
    int c;
    char d;
};

int main(int argc, const char * argv[]) {
    cout << offsetof(foo, a) << endl;
    cout << offsetof(foo, b) << endl;
    cout << offsetof(foo, c) << endl;
    cout << offsetof(foo, d) << endl;
    
    return 0;
}
```

输出：

```shell
0
1
12
16
```

这个例子简单明了。

在结构体 `foo` 中，成员 `a` 处于第一位的位置，所以它的偏移是 0 。

成员 `b` 处于第二位的位置，它的偏移就是 `a` 所占的空间大小，所以是 1 ，注意 `offsetof` 以字节为单位返回偏移量，而 `a` 是 `char` 类型，刚好占一个字节的空间。

成员 `c` 的偏移是成员 `a` 和 成员 `b` 所占空间之和。由于 `b` 是一个 10 字节的数组，所以 `c` 最终的偏移是 11。可等等！上面的结果却是 12 ！这并不是你的编译器在调皮，而是它悄悄帮你做了「对齐」的工作（关于「对齐」的知识，欢迎参考文末链接[C语言字节对齐问题详解](http://www.cnblogs.com/clover-toeic/p/3853132.html)）。这里简单提一下为什么结果会是 12。从前面的分析我们知道，`a` 和 `b` 总共占了 11 个字节的内容，`c` 作为一个 int 变量，讲道理应该占据 11，12，13，14 这几个位置。可是，为了满足**对齐**的规则，int 变量必须从一个能满足被 4 整除的地址空间开始存放。所以，gcc/g++ 会跳过 11 这个位置，从 12 开始为 `c` 分配空间。而原来 11 这个位置，则会自行填充其他值（一般是 0 ）。

成员 `d` 在 `c` 之后，因此它的偏移位置就是 12 + 4 = 16。由于 `d` 是 `char` 类型，因此只要起始位置能被 1 整除就可以，不用对齐。

### 参考

+ [C++官网](http://www.cplusplus.com/reference/cstddef/offsetof/)
+ [C语言字节对齐问题详解](http://www.cnblogs.com/clover-toeic/p/3853132.html)