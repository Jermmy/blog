---
layout: post
title: Shell脚本跑adb，快速替换.so
tags: Shell adb
---

### NDK开发遇到的麻烦

最近使用Android Studio开发jni程序时，遇到一个极其蛋疼的问题：AS编译运行的速度实在是太慢了！！！而且jni开发的时候一定要先clean一遍，再重新build工程，整个过程总耗时＝上个厕所＋喝一杯咖啡，这在调试时尤为不便。于是我上网兜了一遍，终于找到一种更快捷的方法。

参考链接：[使用QtCreator加速Android NDK开发调试](http://wrox.cn/article/100066906/)

### 前期准备工作

一部Android手机(最好是root过的，我用华为P7测试的时候发现没root会失败，用没有root的Samsung GT9105则成功了)。虚拟机没有尝试，毕竟jni开发还是真机靠谱一点。另外，adb、ndk等程序肯定也是需要的。

### 具体步骤

大致流程是：先用 `ndk-build` 编译c/c++代码，再用adb将生成的so库上传到手机里面，然后直接运行app即可(如果改了java代码当然还是得用AS编译一下再运行的，但是这个时间比之前的clean＋build所花时间少一个数量级)。下面以我的实践为例看看怎么玩：

1. ##### ndk-build 编译代码

   这里我直接使用了AS的External Tools工具，具体可以看这篇博客 [Android NDK and OpenCV development with Android Studio](http://hujiaweibujidao.github.io/blog/2014/10/22/android-ndk-and-opencv-development-with-android-studio/) 。配置好External Tools后，只需要对着你的jni文件夹，右键选择 External Tools中的ndk-build命令即可，之后正常的话会在jniLibs目录(这里取决于你的ndk-build参数怎么设置)下生成.so链接库。

2. ##### adb push到手机

   现在.so链接库已经有了，接下来就是将库推到手机上，需要用到adb提供的push命令。这里先讲一下Android文件系统的权限问题。一般来说，Android的文件系统分为两种：一种是app私有文件空间，在/data/data/com.yourcompany.yourapp目录下，这个空间是该app特有的，一般会存放sharepreference以及数据库等文件，用户无权访问；另一种是内置存储器的文件空间(在java代码中通过`Environment.getExternalStorageDirectory()`得到的就是这一部分的文件路径，所以也可以称之为外部空间吧)，用手机上的文件管理工具可以直接访问，用户有读写权限。言归正传，我的做法是先将.so文件推到sdcard目录里，之后再复制到app所在的文件夹(之后会给出详细的命令操作)。这样做的原因是，在进入手机shell之前，我无法得到app内部文件的读写权限，所以先暂时将文件推到手机上再说。

3. ##### 拷贝.so文件到app文件夹

   这里的app文件夹就是前面提到的app私有文件空间。先用`adb shell`进入手机后，再`cd /data/data/com.yourcompany.yourapp`就进入该app内部了，但此时我们是没有读写权限的。文章开头参考链接的文章提供了另一种方法：用Android提供的run-as命令来获取权限，这个命令具体我不清楚，貌似是为debug用的，所以应该是对那种apk签名是debug的起作用。具体用法是：`run-as com.yourcompany.yourapp`。此时，ls、touch等命令应该是有效的。但我在华为P7上用cp命令的时候则提示permission denied，而Samsung那部机子则没有问题，所以还是root的可靠一点。如果提示没有权限而手机已经root过，可以使用su命令获得权限，再用cp命令将文件copy到当前目录。说到这又有必要扯一下.so链接库的存放位置，如果你成功进入app内部空间用`ls`命令可以看到这些文件夹：

   ```java
   app_data
   app_webview
   cache
   files
   lib
   shared_prefs
   ```

   别的不说，.so链接库一般是放在lib文件夹下的，我们用来加载链接库的代码：

   ```java
   static {
     System.loadLibrary("name");
   }
   ```

   默认会去lib文件夹下寻找指定的链接库。遗憾的是，这个文件即使root过也没有写权限。因此，我们只能退一步将.so文件拷贝到app总目录下，然后修改加载的代码来“曲线救国”：

   ```java
   static {
     System.load("/data/data/com.yourcompany.yourapp/libname.so");
   }
   ```

   load函数也是加载文件，但需要用户指定文件位置以及文件名，注意前面的loadLibrary函数只需要指定文件名，而且不需要前缀lib，而后面这个函数需要指定so文件的全名。之后还需要给动态链接库运行权限

   ```shell
   chmod 0755 libname.so
   ```

4. ##### build、 run

   基本步骤到这里就结束了，接下来就是重新生成apk并跑起来。讲道理的话，如果你中间没有修改过java代码，那你完全可以将.so文件推到app文件夹内，直接跑就可以了(毕竟是动态链接的)。但如果改了也没关系，先用AS build一下(比clean再build快n倍)，但将ndk-build生成的.so文件按照之前的步骤推到手机上，然后运行app就可以了，讲道理的话，运行结果跟直接用AS编译运行的结果是一样的。之后如果你只是调试修改了C/C++的代码，你只需要重新生成.so库，然后推到手机上就可以跑了，java层完全不影响。

5. ##### 写个脚本吧

   虽然这种方法让调试速度大幅提高，但敲那么多命令终究还是很耗时的，所以有必要用脚本批处理一下。因为ndk-build我不太熟悉，而且已经在AS里配置好了，一键运行即可，所以脚本只处理adb相关的命令。这里又涉及另一个问题：一开始用adb的时候，我们是在电脑的shell上运行的，而之后的命令又是在手机的shell上跑的，只用一个脚本会在shell切换的时候卡住。因此我在adb shell的时候用了重定向符 ‘<’ 引用了另一个脚本文件。这两个脚本的命令如下：

   ```shell
   # file name: run.sh，在电脑上跑的命令

   # 停止运行app
   adb shell am force-stop com.yourcompany.yourapp
   # 这里要根据实际情况修改路径和文件名
   adb push app/src/main/jniLibs/armeabi-v7a/libname.so  /sdcard/  
   echo "push .so finish"
   # 这一步重定向脚本文件
   adb shell < cmd.sh
   ```

   ```shell
   # file name: cmd.sh  在手机上跑的命令

   # 进入调试模式的app内部
   run-as com.weimanteam.weiman
   # 获取权限，视情况而定，可能有些手机不用获取也可以
   su
   # 拷贝文件到当前目录下
   cp /sdcard/libname.so .
   # 添加执行权限
   chmod 0755 libname.so
   # 离开su超级权限
   exit
   # 离开run-as调试权限
   exit
   # 离开手机shell，注意之后有空行，否则shell没读到回车键就会一直停在这里
   exit

   ```

### 缺陷

可能需要一部root的手机。另外，对于静态链接库应该不适用。

### 参考

[使用QtCreator加速Android NDK开发调试](http://wrox.cn/article/100066906/)

[Android NDK and OpenCV development with Android Studio](http://hujiaweibujidao.github.io/blog/2014/10/22/android-ndk-and-opencv-development-with-android-studio/)

[Why do I get access denied to data folder when using adb?](http://stackoverflow.com/questions/1043322/why-do-i-get-access-denied-to-data-folder-when-using-adb)

[BAT脚本如何自动执行 adb shell 以后的命令 ](http://mzywqwq.blog.163.com/blog/static/958701220134842449172/)