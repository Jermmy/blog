---
title: Android NDK编译
tags: Android
categories: Android
---

（在使用 NDK 之前，应该先确定一定以及肯定 C/C++ 能更好地提升程序性能，如果 Java 也能做得很好的事，讲道理的话是不应该用。当然，隐藏代码细节的除外。）

<!--more-->

关于 NDK 编译的文章已经烂大街了。这里只是简单总结一下在 AS 中怎么做，方便博主日后查看。有必要提供这篇文章作为参考[Android NDK and OpenCV development with Android Studio](https://hujiaweibujidao.github.io/blog/2014/10/22/android-ndk-and-opencv-development-with-android-studio/)，作者不仅认真负责，与时俱进，还富有情调，为广大程序员所不及也。这篇文章主要讲了怎么用 AS 来更快捷地使用 `javah `, `ndk-build `等命令，如何在 gradle 里面配置 task，当然也说了一下怎么来编译 opencv。

我觉得这里面比较复杂的是编译 ndk 这个过程，所以就只是简单描述一下这个流程^_^

首先，要先确定 java 和 C/C++ 的交互接口，说白了就是 java 要调用哪些 C/C++ 函数，假设是以下这个：

```java
public class NdkJniUtils {
    public native String getCLangString();

    static {
        System.loadLibrary("jni_name");
    }
}
```

这里面加载外部依赖库的代码要放在 static 里面，这样会先于 onCreate 等方法执行，并且只加载一次依赖库。依赖库的名称也比较重要，下面会提到。

之后就要开始实现 C/C++ 代码了。由于 NDK 对 C/C++ 的函数名要求比较严格，新手容易出错，这个时候便可以借助 `javah` 这个工具了，`javah `可以根据你的 native 函数，自动生成本地头文件。我这里使用 AS 的 External Tools（如何在 External Tools 中使用 `javah`，请看前面那篇文章），右键 NdkJniUtils.java 使用 `javah`，这时会在 jni 目录下生成 your_package_NdkJniUtils.h 这个头文件。打开这个头文件，可以在里面看到函数声明：

```c
/*
 * Class:     your_package_NdkJniUtils
 * Method:    getCLangString
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_your_package_NdkJniUtils_getCLangString
  (JNIEnv *, jobject);
```

有了这个函数声明，我们可以新建一个对应的 your_package_NdkJniUtils.cpp 或 c 文件，然后实现这个函数

```c
#include "your_package_NdkJniUtils.h"

/*
 * Class:     your_package_NdkJniUtils
 * Method:    getCLangString
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_your_package_NdkJniUtils_getCLangString
        (JNIEnv *env, jobject obj) {
    return env->NewStringUTF("This is just a test");
}
```

写完代码，接下来就要准备编译了，编译的方法有两种。

##### 方法一：使用gradle

这种方法不需要编码 Android.mk ，gradle 会自动帮我们生成。我们要做的是修改 gradle 的配置文件，在 defaultConfig 下面添加 ndk 配置：

```groovy
    defaultConfig {
       ......

        ndk {
            moduleName "jni_name" 	//生成的so名字
            abiFilters "armeabi", "armeabi-v7a", "x86" //输出指定三种abi体系结构下的so库。
        }

    }
```

`ndk` 里面有一个 `moduleName`，它就是我们前面在 Java 代码中添加的依赖库的名称。

为了让 gradle 知道 ndk 放在哪，需要在 `local.properties` 文件中添加 ndk 目录：

```groovy
ndk.dir=/your-dir-path/android-ndk-r10e
```

这时再 build 一下工程，gradle 会自动调用 `ndk-build` 命令，并且自动生成 `Android.mk` ，进入到你的工程目录，可以在 app/build/intermediates/ndk/debug 下面看到 `Android.mk` 以及 `lib/<abi>/*.so` ，run 之后这些 so 依赖库都会打包到 apk 文件中。

##### 方法二：自己使用ndk-build

对于一些习惯 eclipse 的朋友，可能这种方式会更亲切一点。如果是自己在命令行编译代码的话，需要在 jni 目录下编写 `Android.mk` 文件（ `Application.mk` 貌似可有可无），然后进入jni这个目录用 `ndk-build` 进行编译。博主也喜欢这样的方式，但博主直接用 AS 的 External Tools 调用 `ndk-build` （如何在 External Tools 中使用 `ndk-build`，请看前面那篇文章）。

首先需要自己配置 Android.mk（关于这个文件如何配置的，之后再学习）：

``` shell
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := your_package_NdkJniUtils.cpp
LOCAL_LDLIBS += -llog
LOCAL_MODULE := jni_name

LOCAL_C_INCLUDES += /your_project_dir/app/src/main/jni
LOCAL_C_INCLUDES += your_project_dir/app/src/debug/jni

include $(BUILD_SHARED_LIBRARY)
```

看到里面有一个 `LOCAL_MODULE`，它就是我们在 java 代码中需要的依赖库名称。

如果想生成各个平台的依赖库，可以在 `Application.mk` 中这样写：

```shell
APP_ABI := armeabi armeabi-v7a x86
```

之后，右键刚才创建的 your_package_NdkJniUtils.cpp/c 文件，执行 ndk-build，这样会在 jniLibs 目录下生成那些 .so 文件。接下来用 gradle 编译整个项目，注意要现在 gradle 配置文件中添加一句：

```groovy
android {
    compileSdkVersion 23
    buildToolsVersion "23.0.1"

    defaultConfig {
      ......
    }

    // 添加
    sourceSets.main.jni.srcDirs = []

}
```

这样 Android 的 build 系统才会根据我们自己的 Android.mk 寻找依赖库，然后链接各个模块，最终生成 apk 文件。

### 依赖其他第三库

当然啦，如果你没有依赖其他第三方的 .so 库，那么这两种方法都可以帮你完成编译，但如果用到第三方依赖库怎么办？对于第一种方法，需要你在 gradle 的配置文件中添加 task，声明 `ndk-build` 的参数，同时要自己声明 Android.mk。（这也是为什么我喜欢第二种方法的原因，既然都会用到 Android.mk，何必在 gradle 中写那么多配置）。由于配置的过程比较麻烦，这里不细说，具体可以参考最开始给出的那篇文章。

重点说说第二种方法。以编译 opencv 库为例吧。

由于需要引入 opencv 库，所以要修改我们的 Android.mk 文件

```shell
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

#opencv
OPENCVROOT := /your_opencv_dir/OpenCV-android-sdk
OPENCV_CAMERA_MODULES := on
OPENCV_INSTALL_MODULES := on
OPENCV_LIB_TYPE := SHARED
include ${OPENCVROOT}/sdk/native/jni/OpenCV.mk

LOCAL_SRC_FILES := your_package_NdkJniUtils.cpp
LOCAL_LDLIBS += -llog
LOCAL_MODULE := jni_name

LOCAL_C_INCLUDES += /your_package_dir/app/src/main/jni
LOCAL_C_INCLUDES += /your_package_dir/app/src/debug/jni

include $(BUILD_SHARED_LIBRARY)
```

然后我们在原来 cpp 文件中引入 opencv 头文件：

``` c++
#include "your_package_NdkJniUtils.h"
#include <opencv2/opencv.hpp>

using namespace cv;

/*
 * Class:     your_package_NdkJniUtils
 * Method:    getCLangString
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_your_package_NdkJniUtils_getCLangString
        (JNIEnv *env, jobject obj) {
    return env->NewStringUTF("This is just a test");
}
```

右键跑一下`ndk-build`，正常的话是可以编译成功的。但如果要run这个项目，需要在gradle配置文件中添加一句：

```groovy
android {
    compileSdkVersion 23
    buildToolsVersion "23.0.1"

    defaultConfig {
      ......
    }

    // 添加
    sourceSets.main.jni.srcDirs = []

}
```

 这条语句的目的是让 gradle 使用我们自己定义的 Android.mk 文件，而不是像之前的方法一一样，自己去寻找依赖然后编译。

好了，整个操作流程就讲这么多，之后有时间再看看 Android.mk 以及 jni 具体该怎么使用。