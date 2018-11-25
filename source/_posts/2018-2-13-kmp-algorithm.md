---
title: KMP算法
date: 2018-02-13 11:11:40
tags: 算法
categories: 算法
---

这篇文章想简单讲讲 KMP 算法的内容。

## KMP 算法

[KMP](https://en.wikipedia.org/wiki/Knuth–Morris–Pratt_algorithm) 算法由 Knuth–Morris–Pratt 三个人共同提出，它的目的是判断字符串 A 中是否包含另一个字符串 B（如：判断 **abababaababacb** 中是否包含 **ababacb**）。

<!--more-->

## KMP 算法流程 

### KMP

下面演示一下 KMP 的流程。假设我们要判断字符串 A（abababaababacb）中是否包含字符串 B（ababacb）。

我们分别用两个指针 **i** 和 **j** 指示 A、B 匹配的位置。

首先比较第一个位置：

```c
i: 0
A: a
B: a
j: 0
```

匹配了 a 跟 a，向前移动指针 **i** 和 **j**：

```c
i: 01 
A: ab
B: ab
j: 01
```

匹配了 b，继续向前移动指针 **i**、**j**，直到：

```c
i: 01234 5
A: ababa b
B: ababa c
j: 01234 5
```

按照常规的方法，我们要把 **i** 从上次起始点 0 移动到 1，而 **j** 则回到 0 继续匹配。但你是否注意到一个现象：我们已经用 B 的 ababa 匹配了 A 的 ababa，也就是说，我们已经掌握 A、B 前面这部分的信息，那么，对于前面这部分信息能否相互匹配，我们其实已经知道了。

比如说，我们没有必要把 **i** 和 **j** 重新调回 1 和 0，因为 A[1] 和 B[0] 肯定是不匹配的。最明智的做法是调成下面这种状态：

```c
i: 01234 5
A: ababa b
B:   aba b
j:   012 3
```

**i** 还是在 5 的位置，而 **j** 则调整到 3，然后继续后面的匹配工作。

这一步，就是 KMP 的精髓所在（这个 j 的位置如何调整，后面会说）。

继续这个例子，当 **i** 走到 7 的时候，又没法匹配了：

```c
i: 0123456 7
A: abababa a
B:   ababa c
j:   01234 5
```

同样的道理，我们可以把 B 串往后挪动，而保持 A 串不动（其实就是 **i** 不变，移动 **j**）。这一次，**j** 还是调整到 3 的位置：

```c
i: 0123456 7
A: abababa a
B:     aba b
j:     012 3
```

我们发现，经过这次调整，依然没法匹配下去，那只能继续挪动 B，直到：

```c
i: 01234567
A: abababaa
B:        a
j:        0
```

**j** 这次被打回原形了。

之后，我们可以一路匹配直到结束：

```c
i: 0123456789 10 11 12 13
A: abababaaba  b  a  c  b
B:        aba  b  a  c  b
j:        012  3  4  5  6
```

到这里，我们先总结一下，假设在每次出现不匹配时，我们已经知道了如何调整 **j**，那上面的流程可以写成下面的代码：

```c++
int kmp(string A, string B) {
    int n = A.length();
    for (int i = 0, j = 0; i < n; i++) {
        if (A[i] == B[j]) j++;
        if (j == B.length()) return i - j + 1; // 返回 A、B 匹配的起点
        // 如果 A 的下一位和 B 不匹配，则不断调整 j，直到匹配或者j回到0为止
        while (j > 0 && A[i + 1] != B[j]) {
            j = next[j - 1];    // next[j]表示当j+1位出现不匹配时，j应该回到next[j]的位置
        }
    }
}
```

上面这段代码的时间复杂度为 O(n)，具体可以看这篇[文章](http://www.matrix67.com/blog/archives/115)的分析。

### next 数组

**现在问题来了：我们该如何调整 j 的位置呢？**

看回刚才那个例子，当出现下面这种不匹配的情况时，

```c
i: 01234 5
A: ababa b
B: ababa c
j: 01234 5
```

我们是这样调整 **j** 的：

```c
i: 01234 5
A: ababa b
B:   aba b
j:   012 3
```

由于 B 中的 ababa 和 A 是匹配的，所以 A 前面那一串肯定是 ababa。然后我们才能把 B 前三个字符（B[0 : 2] = aba）移到后面，跟 A 中 ababa 的后三个字符匹配。

**前三个字符跟后三个字符匹配！**

**前三个字符跟后三个字符匹配！**

**前三个字符跟后三个字符匹配！**

这是关键。

ababa 是 A 的字符串，同时也是 B 的字符串，所以这些新位置的计算完全可以仅仅根据 B 来预处理。

现在，我们重新审视这个过程。

假设 B（ababacb） 跟某个字符串进行匹配，在 j = 5 时才发生失配：

```c
i:
A: ***** *
B: ababa c
j: 01234 5（01234都是匹配的，5开始不匹配）
```

这时，我们可以在不管 A 的情况下，将 j 调整为：

```c
i:
A: ***** *
B:   aba b
j:   012 3
```

为什么可以这么做？因为 ababa 的后三个字符和前三个字符是相等。

现在，你应该明白 j 的位置要怎么调整了。它本质上是在计算 B 子串中**最长且相等的前缀和后缀**，是 B 自己对自己的匹配。

通常，我们会用一个**部分匹配表**来记录这部分信息（即之前代码中的**next**数组）。

我们继续用一个例子来解释 next 数组的计算流程。为了让例子更具代表性，我们选用 **B = abababca**。在下面的例子中，我们同样会用 **i**、**j** 两个指针来标示，这一次是用 B 来匹配 B（请铭记：next[i] 表示的是 B 的子串 B[0 : i] 中，最长且相等的前缀和后缀的长度，它和前面代码中的注释本质是一样的。⚠️B[0 : i] 包含 B[0] 到 B[i] 总共 i+1 个字符）。

例子中的 **n** 代表 **next** 数组。

我们默认 next[0] = 0，因为 B[0] 就只包含一个字符，不存在前缀后缀。

所以匹配从第二个字符开始：

```c
i: 01
B: ab******
B:  a
j:  0
n: 00
```

B[0 : 1] 中，前缀是 B[0]，后缀是 B[1]，二者不等，所以 next[1] = 0（最长且相等的前后缀的长度为 0）。

因为没有匹配上，我们只能移动 **i**，固定 **j**：

```c
i: 012
B: aba*****
B:   a
j:   0
n: 001
```

终于匹配到了一个，next[2] = 1。

之后，**i**、**j** 同时移动：

```c
i: 0123
B: abab****
B:   ab
j:   01
n: 0012
```

在 B[0 : 3] 这个串 (abab) 中，我们继续匹配到 b，现在匹配的前缀和后缀变为 ab，next[3] = 2。

以此类推:

```c
i: 012345
B: ababab**
B:   abab
j:   0123
n: 001234
```

不过，再往前走一步，情况就复杂了：

```c
i: 012345 6
B: ababab c*
B:   abab a
j:   0123 4
n: 001234
```

第 6 位，c 这颗老鼠屎，搅坏一锅粥。怎么办呢？只能重新调整 **j** 了。但是，我们不能一口气将 **j** 调回 0，因为这一步中，j != 0 告诉我们：c 之前的串是能够匹配的呀。而我们的目的也是要找最长的前缀和后缀，因而，虽然前面千辛万苦找到的 abab 现在是匹配不下去了，我们能不能继续找一个长度小于 4 的匹配串呢？比如，abab 中的前缀 ab 和后缀 ab 也是能匹配的呀。所以，我们将 **j** 调成这个样子，看能不能挽救一下：

```c
i: 012345 6
B: ababab c*
B:     ab a
j:     01 2
n: 001234
```

结果还是挽救不了，因为 B[6] 和 B[2] 不相等。但此时，j 还是大于 0，也就是说前面还是有子串是匹配的。不过，眼睛瞄一下也知道，剩下的 ab 本身是不存在匹配情况的，所以这下只能将 **j** 调回 0 了：

```c
i: 0123456
B: abababc*
B:       a
j:       0
n: 0012340
```

上面这个「挽救」的过程，其实是求 next 数组中最难理解的地方（而 next 是 KMP 最难理解的地方）。

再回顾一下，我们遇到 c 之后，不是直接将 **j** 置 0，而是从之前匹配到的子串中，寻找可能的前缀和后缀。在这个例子中，我们已经匹配到的是 abab，因此之后就是找找 abab 身上的前缀跟后缀。不知道你注意到没有，从 abab 身上找前缀后缀的工作，我们在计算 next[3] 的时候就遇过了👇：

```c
i: 0123
B: abab****
B:   ab
j:   01
n: 0012
```

因为这个 abab 本身也是 B 的前缀，而我们之前已经计算出这个前缀的最长且相等的前后缀长度是 2（next[3] = 2）。

但是，尽管我们挽救了 ab 出来，但还是没法进一步匹配下去，所以又要从 ab 身上挽救点东西。但坑爹的是，我们在计算 next[1] 时就已经发现，ab 本身就没有相等的前后缀👇：

```c
i: 01
B: ab******
B:  a
j:  0
n: 00
```

next[1] = 0，所以，这一次我们是真没办法了，才将 **j** 调回 0。一旦 **j** 回到 0，c 之前也就没有匹配的子串了，一切又从头开始。

希望以上这段解释，能让你明白下面这段代码：

```c++
vector<int> getNext(string B) {
  int n = B.length();
  vector<int> next(n, 0);
  for (int i = 1, j = 0; i < n; i++) {
    // 注意，这里的j表示长度
    while (j > 0 && B[i] != B[j]) {
      j = next[j - 1];
    }
    if (B[i] == B[j]) {
      j++;
    }
    next[i] = j;
  }
  return next;
}
```

现在，KMP 的基本流程就讲完了。

KMP 算法我主要是看了这篇[文章](http://www.matrix67.com/blog/archives/115)入门的，但其中，对 next 数组的求解过程一直不明白，于是，我又找了其他文章，但坑爹的是，不同作者的讲解思路和风格都不一样，虽然道理是一样的，但在顿悟道理之前，这些不同的文章还是会让初学者很困惑。最后，实在没辙了，我就找了个例子，按照最开始那篇文章的思路，在那使劲捣鼓，总算折腾出一个在我看来还过得去的解释。不过，我的思考方式不可能适合所有人，如果你看到这堆解释后，依然一头雾水，最好的方法是静下心来，拿出纸笔，对着例子捣鼓一段时间，这样的效率会比不断找文章阅读来的高。

## 参考

+ [KMP算法详解](http://www.matrix67.com/blog/archives/115)
+ [The Knuth-Morris-Pratt Algorithm in my own words](http://jakeboxer.com/blog/2009/12/13/the-knuth-morris-pratt-algorithm-in-my-own-words/)