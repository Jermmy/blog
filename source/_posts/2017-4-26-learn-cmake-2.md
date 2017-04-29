---
title: cmake学习笔记(2)——引用文件夹
date: 2017-04-26 10:27:00
tags: [工具, cmake]
categories: 工具
---

### 学习目标

之前的文章中，我们介绍了 cmake 的 HelloWorld 程序，并了解了执行 cmake 的一般套路。今天，我们稍微深入一下，学习如何引用多个文件夹下的代码。

### 引用文件夹

随着功能的增加，我们的项目也变得越来越大了。这个时候，为了更好地管理代码，我们将工程拆分成各个模块，每个模块的代码文件单独放在一个文件夹下以便管理。在这种情况下，cmake  将带来更多的便利。

<!--more-->

现在，我们将 HelloWorld 单独封装成一个类，并把头文件放到 include 文件夹，源代码放在 src 文件夹，同时将 main 函数单独放在 app.cpp 文件中作为应用程序的入口。工程目录如下：

```shell
xyzdeMacBook-Pro:my_cmake_code xyz$ tree
.
├── CMakeLists.txt
├── build
├── include
│   └── helloworld.h
└── src
    ├── app.cpp
    └── helloworld.cpp

3 directories, 4 files
```

注意，我在项目根目录下新建了一个 build 文件夹。这个文件夹用来存放 cmake 产生的临时文件以及最终的可执行程序。

下面，我们看看 CMakeList.txt 怎么写：

```shell
cmake_minimum_required(VERSION 2.8.9)
project (hello)

# Bring the headers, such as helloworld.h into the project
include_directories(include)

# Can manually add the sources using the set command as follows:
# set(SOURCES src/app.cpp src/helloworld.cpp)

# Add all the file in directory
# aux_source_directory(src SOURCES)

# However, the file(GLOB...) allows for wildcard additions:
file(GLOB SOURCES "src/*.cpp")

add_executable(hello ${SOURCES})
```

我们分析一下几条重要的命令：

+ `include_directories(include)` 这条命令将 include 文件夹下的头文件添加到编译环境中；
+ `set(SOURCES src/app.cpp src/helloworld.cpp)` 这条命令的作用跟接下来两条命令相同，在文件中被我注释掉了，但在 cmake 中是很常用的命令。`set` 函数用于设置变量，在本例中，我们定义一个 `SOURCES` 变量（变量名可以随便起），并将 `src/app.cpp`、 `src/helloworld.cpp` 两个文件路径添加到 `SOURCES` 变量中；
+ `aux_source_directory(src SOURCE)` 这条命令会将 `src` 文件夹下的所有文件都放到 `SOURCES` 变量中，在本例中，它的作用和下一条 `file` 一致；
+ `file(GLOB SOURCES "src/*.cpp")` 这条命令会将后面匹配到的所有文件 `src/*.cpp` 交给 `GLOB` 子命令，由后者生成一个文件列表，并将列表赋给 `SOURCES` 变量。由于这条命令可以帮助我们自动引用所有的源文件，而 `set` 命令需要我们一个一个地添加文件，所以这里使用 `file` 更加省事；
+ `add_executable(hello ${SOURCES})` 这条命令在之前的教程中已经介绍过了，不过这一次我们传入一个 `SOURCES` 变量，这个变量包含所有源文件的路径。

写完 `CMakeList.txt` 后，我们同样要用 cmake 来执行。如果你执行过上一篇文章的 cmake 程序，你会发现 cmake 输出了很多临时文件。所以，为了方便管理，我们这次要将所有 cmake 临时文件输出到 `build` 文件夹。具体做法如下：

```shell
cd build
cmake ..
make
```

首先我们先进入 build 文件夹，然后执行 cmake 程序，不过，由于 `CMakeList.txt` 文件在 `build` 目录上一层，所以需要执行 `cmake ..`，之后，cmake 会在当前文件夹下生成临时文件以及 `Makefile`，然后我们 `make` 一下就可以了，你会看到 `build` 目录下生成的可执行文件。

如果我们想重新执行 cmake，只需要删掉 `build` 下的所有文件，然后再重复之前的操作即可。

### 总结

这一篇教程主要介绍了三个新命令：

```shell
# Bring the headers, such as helloworld.h into the project
include_directories(include)

# Can manually add the sources using the set command as follows:
set(SOURCES src/app.cpp src/helloworld.cpp)

# Add all the file in directory
aux_source_directory(src SOURCES)

# However, the file(GLOB...) allows for wildcard additions:
file(GLOB SOURCES "src/*.cpp")
```

第一条 `include_directories()` 命令用于引用头文件的目录，我们可以添加多个参数，中间用空格隔开；

第二条 `set()` 在 cmake 中很常见，通常用于定义和设置变量。；

第三条 `aux_source_directory()`  可以添加指定文件夹下所有的文件；

第四条 `file()` 可以批量引用代码文件，并通过子命令 `GLOB` 转成文件列表存到变量中。

### 参考

+ [Introduction to CMake by Example](http://derekmolloy.ie/hello-world-introductions-to-cmake/)