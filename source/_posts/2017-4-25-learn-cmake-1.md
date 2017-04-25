---
title: cmake学习笔记（1）
date: 2017-04-25 22:26:01
tags: [工具, cmake]
categories: 工具
---

### 什么是 cmake

cmake 是一个跨平台的自动化构建系统，它可以产生不同系统平台的构建文件（例如：类 Unix 系统的 Makefile，Windows 系统的 .vcproj ）。开发者只要根据 cmake 的命令规则编写好 CMakeLists.txt 文件，就可以用对应平台的 cmake 程序生成相应的构建文件，再根据构建文件编译代码。它的好处是，开发者只要学会 cmake 自身的语法规则即可，至于平台本身的项目构建文件，则交由 cmake 开发人员处理。总而言之，cmake 是高级版的 Makefile，是优秀的 C/C++ 程序员必不可少的技能（当然后面这句是我自己说的）。

下面，我们就一步一步地来学习 cmake 吧🤓。本系列教程基于 cmake 3.8 版本。

（注：本教程大部分内容取自 [Introduction to CMake by Example](http://derekmolloy.ie/hello-world-introductions-to-cmake/) ）

<!--more-->

### HelloWorld

按照程序员的规矩，我们要先讲讲 cmake 的 HelloWorld 程序。

首先，我们先创建一个 helloworld.cpp 文件，并编写你最熟悉的 helloworld 代码：

```c++
#include <iostream>
 
int main(int argc, char *argv[]) {
	std::cout << "Hello World!" << std::endl;
	return 0;
}
```

之后，在同一个目录下创建一个 CMakeLists.txt 文件。CMakeLists.txt 是默认存放 cmake 命令的文件，如同 make 的 Makefile。我们在这个文件上输入以下命令：

```cmake
cmake_minimum_required(VERSION 2.8.9)
project (hello)
add_executable(hello helloworld.cpp)
```

作为第一个 cmake 程序，我们要分析一下上面三条简单的命令：

+ 第一条命令指明 cmake 的最低版本，这个命令的功能不言而喻，一般来说照抄就可以了；
+ 第二条命令设置了项目的名字；
+ 第三条命令比较重要。`add_executable()` 命令的第一个参数表示我们最终编译出来的程序的名称，第二个参数是编译所需要的代码文件。

下面，我们用 cmake 来编译这个 HelloWorld 程序。

在 CMakeLists.txt 同一个目录下，执行以下命令（不要忘了点）：

```shell
cmake .
```

cmake 会执行当前目录的 CMakeLists.txt ，生成需要的构建文件。

你会看到类似输出：

```shell
-- The C compiler identification is AppleClang 8.0.0.8000042
-- The CXX compiler identification is AppleClang 8.0.0.8000042
-- Check for working C compiler: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc
-- Check for working C compiler: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc -- works
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Detecting C compile features
-- Detecting C compile features - done
......
```

不同的系统输出会有不同。cmake 在执行过程中会自动寻找系统的 C/C++ 编译器，将它们和其他配置信息一起写入 Makefile 文件。

之后，你会在同一个目录下看到一个 Makefile 文件，这个文件是 cmake 自动生成的，不要去修改它。然后，我们就可以用 make 来生成可执行程序了。

```shell
make
```

然后就是一般的 make 执行过程，最终我们会在同一个目录下看到 `hello` 程序。

### 总结

第一个教程虽然简单，但它已经包含了 cmake 的基本使用流程。首先，我们创建一个 CMakeList.txt 文件，在上面输入 cmake 命令，再让 cmake 来执行这个文件，得到特定平台的 Makefile 文件，最后再 make 一下便可以生成可执行程序了。

之后的教程会继续介绍其他高级的 cmake 指令。



### 参考

+ [cmake wikipedia](https://zh.wikipedia.org/wiki/CMake)
+ [Introduction to CMake by Example](http://derekmolloy.ie/hello-world-introductions-to-cmake/)
+ [cmake tutorial](https://cmake.org/cmake-tutorial/)

