---
title: cmake学习笔记(3): 编译和引用链接库
date: 2017-04-26 15:44:39
tags: [工具, cmake]
categories: 工具
---

### 学习目标

上一篇文章我们介绍了如何用 cmake 去 build 一个小型的工程项目。在实际开发中，我们有时候只是想编译生成一些链接库，而不是编译一个完整的项目。今天，我们来学习如何用 cmake 构建链接库。

<!--more-->

### 编译动态链接库(.so/dylib/dll)

接下来我们沿用上一篇文章的例子，编写一个 HelloWorld 类，并将这个类编译成动态链接库。

项目目录如下：

```shell
xyzdeMacBook-Pro:my_cmake_code xyz$ tree
.
├── CMakeLists.txt
├── build
├── include
│   └── helloworld.h
└── src
    └── helloworld.cpp

3 directories, 3 files
```

`helloworld.*` 文件的代码和之前的教程一样。

下面，我们还是先编写 CMakeList.txt 文件：

```shell
cmake_minimum_required(VERSION 2.8.9)
project (hello)
set(CMAKE_BUILD_TYPE Release)

# Bring the headers, such as helloworld.h into the project
include_directories(include)

# However, the file(GLOB...) allows for wildcard additions:
file(GLOB SOURCES "src/*.cpp")

# Generate the shared library from the sources
add_library(hello SHARED ${SOURCES})

# Set the location for library installation -- i.e., /usr/local/lib
# not really necessary in this example. Use "sudo make install" to apply
install(TARGETS hello DESTINATION /usr/local/lib)
```

下面介绍几条新命令的含义：

+ `set(CMAKE_BUILD_TYPE Release)` 表示此次编译为正式版本的编译，一般来说照抄即可；
+ `add_library(hello SHARED ${SOURCES})` 这条命令是本文的重点。它表示 `${SOURCES}` 变量中包含的源代码会被编译成动态链接库（另外两个选项是 `STATIC` 和 `MODULE` ）。这个链接库的名称是 `hello`；
+ `install(TARGETS hello DESTINATION /usr/local/lib)` 这条命令表示会将动态链接库 `hello` 安装到 `/usr/local/lib` 这个目录下。我们需要使用 `sudo make install` 来激发这个 TARGET。

之后，我们按照之前的方式执行 cmake 和 make：

```shell
cd build
cmake ..
make
```

make 完成后，你会在 `build` 文件夹下看到一个 `libhello.dylib` 文件（不同系统命名可能不同，Linux 下的后缀名是`.so`，Windows 下是`.dll` ）。

而如果要把链接库安装到系统中，还需要执行一步 `sudo make install`。你会在 `shell` 里面看到安装位置：

```shell
xyzdeMacBook-Pro:build xyz$ make install
[100%] Built target hello
Install the project...
-- Install configuration: ""
-- Installing: /usr/local/lib/libhello.dylib
```

如果还不放心，可以亲自到 `/usr/local/lib` 目录下查看是否有 `libhello` 这个链接库。

在类 Unix 系统中，只要链接库在 `/usr/local/lib` 或 `/usr/lib` 目录下，我们就可以在链接时用 `-l` 来链接这些库了。

### 编译静态链接库(.a) 

讲完如何构建动态链接库，下面依葫芦画瓢，看看如何构建静态链接库。

不同于动态链接库的是，静态链接库是在编译的时候被「链接」进编译器的。换句话说，静态链接库中包含所有需要用到的源代码（当然是被编译器处理过的源代码），所以它的体积比动态链接库要大许多。但也由于它包含的是高级的代码形式，所以跨平台性比动态链接库好，而且也没有运行时加载库文件的时间开销。不过，由于动态链接库中的代码冗余更少，而且可以在不编译整个工程的情况下动态更新代码，因此动态链接库的使用场景更广。

编译静态链接库的方式和动态链接库几乎一模一样，唯一的区别是把 `add_library(hello SHARED ${SOURCES})` 中的 `SHARED` 改成 `STATIC` 。然后按照之前的步骤执行 cmake 和 make，就可以在 `build` 文件夹下看到 `libhello.a` 文件。

### 引用链接库

好了，前面虽然扯了这么多，但我们还没验证生成的库文件是否正确。所以，接下来，我们再用 cmake 来引用我们生成的链接库。

为了调用 HelloWorld 函数库，我们先创建一个 main 函数的代码文件（app.cpp）：

```c++
#include "helloworld.h"

int main(int argc, char const *argv[]) {
	HelloWorld h;
	h.print();
	return 0;
}
```

然后我们把 helloworld.cpp 文件删掉。这样，我们的项目就变成下面这个样子：

```shell
xyzdeMacBook-Pro:my_cmake_code xyz$ tree
.
├── CMakeLists.txt
├── build
│   └── libhello.dylib
├── include
│   └── helloworld.h
└── src
    └── app.cpp

3 directories, 4 files
```

现在，helloworld.h 文件的实现就以 libhello.dylib 的形式存在了。之后我们要重新编写 CMakeList.txt 文件，让 app.cpp 可以引用到 libhello.dylib 链接库。

```shell
cmake_minimum_required(VERSION 2.8.9)
project (hello)

# For the shared library:
set(PROJECT_LINK_LIBS libhello.dylib)
link_directories(build)

# For the static library:
#set(PROJECT_LINK_LIBS libhello.a)
#link_directories(build)

include_directories(include)
file(GLOB SOURCES src/*cpp)
add_executable(hello ${SOURCES})
target_link_libraries(hello ${PROJECT_LINK_LIBS})
```

同样的，我们要分析一下上面的命令是如何链接到 `libhello.dylib` 的（注释中提供了静态链接库的链接代码，和动态链接库的几乎一样，不再赘述）：

+ `set(PROJECT_LINK_LIBS libhello.dylib)` 这条命令定义了一个 `PROJECT_LINK_LIBS` 变量，该变量表示我们要链接的库为 `libhello.dylib`；
+ `link_directories(build)` 这条命令表示我们的链接库在 `build` 文件夹下；
+ `target_link_libraries(hello ${PROJECT_LINK_LIBS})` 这条命令会将我们的程序和库函数链接起来。

然后，我们执行 cmake 和 make 程序：

```shell
cd build
cmake ..
make
```

前面的步骤指令都正确的话，我们会在 `build` 文件夹下看到一个 `hello` 程序。执行这个程序，如果输出如下结果，证明链接成功了：

```shell
xyzdeMacBook-Pro:build xyz$ ./hello
Hello World!
```

### 总结

这一篇教程我们主要介绍了四条新命令：

```shell
add_library(hello SHARED(STATIC) ${SOURCES})
install(TARGETS hello DESTINATION /usr/local/lib)

link_directories(build)
target_link_libraries(hello ${PROJECT_LINK_LIBS})
```

前两条用于生成和安装动/静态链接库，后两条用于链接这些库文件。

### 参考

+ [Introduction to CMake by Example](http://derekmolloy.ie/hello-world-introductions-to-cmake/)