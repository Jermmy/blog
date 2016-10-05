---
title: Android NDK编译
tags: Android
categories: Android
---

（在使用NDK之前，应该先确定一定以及肯定C/C++能更好地提升程序性能，如果Java也能做得很好的事，讲道理的话是不应该用。当然，隐藏代码细节的除外。）

<!--more-->

关于NDK编译的文章已经烂大街了。这里只是简单总结一下在AS中怎么做，方便博主日后查看。有必要提供这篇文章作为参考[Android NDK and OpenCV development with Android Studio](https://hujiaweibujidao.github.io/blog/2014/10/22/android-ndk-and-opencv-development-with-android-studio/)，作者不仅认真负责，与时俱进，还富有情调，为广大程序员所不及也。这篇文章主要讲了怎么用AS来更快捷地使用`javah`, `ndk-build`等命令，如何在gradle里面配置task，当然也说了一下怎么来编译opencv。

我觉得这里面比较复杂的是编译ndk这个过程，所以就只是简单描述一下这个流程^_^

首先，要先确定java和C/C++的交互接口，说白了就是java要调用哪些C/C++函数，假设是以下这个：

```java
public class NdkJniUtils {
    public native String getCLangString();

    static {
        System.loadLibrary("jni_name");
    }
}
```

这里面加载外部依赖库的代码要放在static里面，这样会先于onCreate等方法执行，并且只加载一次依赖库。依赖库的名称也比较重要，下面会提到。

之后就要开始实现C/C++代码了。由于NDK对C/C++的函数名要求比较严格，新手容易出错，这个时候便可以借助`javah`这个工具了，`javah`可以根据你的native函数，自动生成本地头文件。我这里使用AS的External Tools（如何在External Tools中使用`javah`，请看前面那篇文章），右键NdkJniUtils.java使用`javah`，这时会在jni目录下生成your_package_NdkJniUtils.h这个头文件。打开这个头文件，可以在里面看到函数声明：

```c
/*
 * Class:     your_package_NdkJniUtils
 * Method:    getCLangString
 * Signature: ()Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_your_package_NdkJniUtils_getCLangString
  (JNIEnv *, jobject);
```

有了这个函数声明，我们可以新建一个对应的your_package_NdkJniUtils.cpp或c文件，然后实现这个函数

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

这种方法不需要编码Android.mk，gradle会自动帮我们生成。我们要做的是修改gradle的配置文件，在defaultConfig下面添加ndk配置：

```groovy
    defaultConfig {
       ......

        ndk {
            moduleName "jni_name" 	//生成的so名字
            abiFilters "armeabi", "armeabi-v7a", "x86" //输出指定三种abi体系结构下的so库。
        }

    }
```

`ndk`里面有一个`moduleName`，它就是我们前面在Java代码中添加的依赖库的名称。

为了让gradle知道ndk放在哪，需要在`local.properties`文件中添加ndk目录：

```groovy
ndk.dir=/your-dir-path/android-ndk-r10e
```

这时在build一下工程，gradle会自动调用`ndk-build`命令，并且自动生成`Android.mk`，进入到你的工程目录，可以在app/build/intermediates/ndk/debug下面看到`Android.mk`以及`lib/<abi>/*.so`，run之后这些so依赖库都会打包到apk文件中。

##### 方法二：自己使用ndk-build

对于一些习惯eclipse的朋友，可能这种方式会更亲切一点。如果是自己在命令行编译代码的话，需要在jni目录下编写`Android.mk`文件（`Application.mk`貌似可有可无），然后进入jni这个目录用`ndk-build`进行编译。博主也喜欢这样的方式，但博主直接用AS的External Tools调用`ndk-build` （如何在External Tools中使用`ndk-build`，请看前面那篇文章）。

首先需要自己配置Android.mk（关于这个文件如何配置的，之后再学习）：

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

看到里面有一个`LOCAL_MODULE`，它就是我们在java代码中需要的依赖库名称。

如果想生成各个平台的依赖库，可以在`Application.mk`中这样写：

```shell
APP_ABI := armeabi armeabi-v7a x86
```

之后，右键刚才创建的your_package_NdkJniUtils.cpp/c文件，执行ndk-build，这样会在jniLibs目录下生成那些.so文件。接下来用gradle编译整个项目，注意要现在gradle配置文件中添加一句：

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

这样Android的build系统才会根据我们自己的Android.mk寻找依赖库，然后链接各个模块，最终生成apk文件。

### 依赖其他第三库

当然啦，如果你没有依赖其他第三方的.so库，那么这两种方法都可以帮你完成编译，但如果用到第三方依赖库怎么办？对于第一种方法，需要你在gradle的配置文件中添加task，声明`ndk-build`的参数，同时要自己声明Android.mk。（这也是为什么我喜欢第二种方法的原因，既然都会用到Android.mk，何必在gradle中写那么多配置）。由于配置的过程比较麻烦，这里不细说，具体可以参考最开始给出的那篇文章。

重点说说第二种方法。以编译opencv库为例吧。

由于需要引入opencv库，所以要修改我们的Android.mk文件

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

然后我们在原来cpp文件中引入opencv头文件：

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

 这条语句的目的是让gradle使用我们自己定义的Android.mk文件，而不是像之前的方法一一样，自己去寻找依赖然后编译。

好了，整个操作流程就讲这么多，之后有时间再看看Android.mk以及jni具体该怎么使用。