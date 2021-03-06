---
title: Android NDK-异常总结
date: 2016-09-06 19:37:41
tags: [NDK, Android]
categories: Android
---

开发 NDK 时，由于大量用到指针等，在失去 Java 虚拟机保护（异常抛出）的情况下，常常面临崩溃闪退却不知道哪里出错的问题。更有甚者，这种情况还具有随机性，非常麻烦！本文记录一下我开发 NDK 时遇到的各种蛋疼问题，方便以后查找使用。

<!--more-->

### 1.  A/libc(3347): Fatal signal 11 (SIGSEGV) at 0xdeadbaad (code=1)

这个异常会导致 app 闪退。我开发的时候是随机遇到的，当时调了一个早上。网上 google 后发现遇到问题的原因各种各样，但大多数是访问了不该访问的内存（如：数组越界）。在仔细查看了代码后，我对所有可能越界的地方做了改善，并打了断点，结果还是遇到这种问题，但同样的数据在电脑上跑完全正常。后来我猜想是否是栈空间不足导致的，于是将所有数组的内存分配到堆上，之后便一切顺利了。不管原因是否是栈空间不足导致的，总算是找到了一种解决方案。

#### 参考

[Fatal signal 11 (SIGSEGV) at 0xdeadbaad (code=1) 错误 解决方案(android-ndk)](http://blog.csdn.net/lancees/article/details/8896711)