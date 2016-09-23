---
title: Android-WebView加载非Assets目录下的文件
date: 2016-09-13 20:38:21
tags: Android
categories: Android
---

### 背景

最近遇到这样一个需求：WebView里的文件需要定期更新，而且是在java层获取后台的json数据后，更新到原来的js文件中。由于之前app的html、js等文件都是放在Assets目录下的，所以最开始的想法当然是看能不能对Assets目录进行读写。google一番后，SO上有人给出了答复：**You cannot write data's to asset/Raw folder, since it is packed(.apk) and not expandable in size.**  然后我出于好奇想知道apk安装后，这两个文件夹的资源会被存储在哪。于是便进入到**data/data/packageName**目录下，结果发现这两个目录相关的资源并不存在，不仅如此，res目录下的资源也不在这里。于是又google了一番，发现apk安装后，除了**data/data/packageName**目录下会有东西，在**data/app**目录下会有一个与该apk相关的文件，暂时不知道是什么，但十有八九就是跟res等资源有关的东西。

<!--more-->

### 解决方法

现在解决方案就很明显了：既然我不能向Assets目录下写数据，又不能在html中通过相对路径找到其他文件（因为**data/app**下那个文件不是很了解），那么可行的办法就是将html、js等文件都从Assets目录中拿下来，重新放在别的地方，这样不管做什么就方便多了。

再次google一番，发现`WebView`的`loadUrl()`方法本身就可以加载不同路径下的文件。比如，加载raw目录下的文件，可以写成 `webView.loadUrl("file:///android_res/raw/your_file_name.html");`，形式和加载Assets下的文件差不多。

考虑到html等文件不能被误删，我决定将这些文件转移到内部存储空间（也就是`data/data/packageName`）下面，这样需要更新的js文件也需要存储到内部存储空间。好在这些文件本身并不大，因此对存储器空间几乎没有影响。于是，在用户第一次进入app的时候，需要先通过 `Activity` 的 `openFileOutput()`方法将html等文件转移到**data/data/packageName/files**目录下，之后一旦有新的更新，也需要将更新应用到这个目录下的js等文件。在WebView中访问的方式：`webView.loadUrl("file:///data/data/packageName/files/your_file_name.html");`。如果是要访问外部存储器的文件，只需要将文件路径改为外部文件路径即可。

### 参考

[Load html files from raw folder in web view](http://stackoverflow.com/questions/14171316/load-html-files-from-raw-folder-in-web-view)

[How to write files to assets folder or raw folder in android?](http://stackoverflow.com/questions/3760626/how-to-write-files-to-assets-folder-or-raw-folder-in-android)

[How exactly the android assets are stored in device's storage (closed)](http://stackoverflow.com/questions/22687136/how-exactly-the-android-assets-are-stored-in-devices-storage)

[Loading local html file in webView android](http://stackoverflow.com/questions/20873749/loading-local-html-file-in-webview-android)

