---
title: "Android Ndk and Opencv Development 1"
date: "2013-11-18"
categories: "android"
---
从本节开始之后的几节将介绍关于Android NDK和OpenCV整合开发的内容，本节介绍Android NDK 和 OpenCV 整合开发的环境搭建以及人脸检测项目的运行测试。<!--more-->

在Samsung呆了段时间，还是学了不少东西的，主要做的任务是做[Android NDK](http://developer.android.com/tools/sdk/ndk/index.html)开发，也涉及到了[OpenCV](http://opencv.org/)的内容，正好自己最近在开发XFace，这些知识都用得上，所以，想写几篇文章总结下这些知识。该系列内容均为原创，摘录的部分我都会引用提示，尊重版权嘛，嘿嘿，我保证这里有不少内容是搜索不到的独家秘笈哟！很多都是我的开发经验，嘿嘿。   

该系列主要包括三大部分，分为下面三节来介绍，本节主要介绍第一部分

1.Android NDK 和 OpenCV 整合开发的环境搭建以及人脸检测项目的运行测试
2.[Android NDK 的核心内容和开发总结](/blog/2013/11/18/android-ndk-and-opencv-development-2/)
3.[OpenCV 在 Android NDK 开发中的应用](/blog/2013/11/18/android-ndk-and-opencv-development-3/)

[本文假设你是安装配置好了Java和Android SDK开发环境的，如果没有的话，可以看[我以前在点点博客写的这篇文章](http://hujiaweiyinger.diandian.com/post/2013-10-30/setup_android_ndk_environment_and_solve_some_problems)，开发工具建议使用[ADT](http://developer.android.com/sdk/installing/bundle.html)，它更加方便，包含了Android SDK 和 安装了 ADT Plugin 的 Eclipse，何乐而不为呢?]

#### 1. 下载Android NDK，解压即可

下载地址： [Android NDK](https://developer.android.com/tools/sdk/ndk/index.html)   
[如果不能下载(公司内部可能就不让访问或者访问很慢)，可以查看这位作者的备用下载地址](http://download.csdn.net/download/xiao87651234/3991166)

#### 2. 下载安装OpenCV[2.6版本] (可选步骤)

下载地址：[OpenCV首页](http://opencv.org/)
[Linux平台的安装教程](http://docs.opencv.org/trunk/doc/tutorials/introduction/linux_install/linux_install.html#linux-installation)  [Mac平台的安装教程](http://tilomitra.com/opencv-on-mac-osx/ )

(1) 首先安装需要安装的工具和依赖包[详见前面的Linux安装教程]，Mac平台基本上只要安装CMake即可   
(2) 使用CMake编译opencv源码，然后通过make安装opencv[完成之后在`/usr/local/include`目录下便有了`opencv`和`opencv2`两个目录，在`/usr/local/lib`目录下有很多的`opencv`相关的动态库，例如`libopencv_core.dylib`等等]

```
cd <path-to-opencv-source>
mkdir release
cd release
cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local ..
make
sudo make install
```

#### 3. 下载opencv_android_sdk 2.4.4版本，导入目录sdk/java作为Library Project (这个是OpenCV for Android)

下载地址：[opencv-android on sourceforge](http://sourceforge.net/projects/opencvlibrary/files/opencv-android/)

[2.4.2相对比较旧了，有些新特性不支持，比如人脸识别(但是有人脸检测)，不推荐下载这个；2.4.6相对比较新，但是可能导入的Library Project一直报错，所以如果不能解决就考虑使用2.4.4，只要Library Project导入进来没问题就行]

[关于opencv for android的目录结构的详细解释](http://docs.opencv.org/doc/tutorials/introduction/android_binary_package/O4A_SDK.html#general-info)

#### 4. 环境配置NDK和OpenCV环境

安装Android SDK(略过)和NDK，配置到系统PATH中

[推荐配置，方便以后在终端执行adb和ndk-build等命令]

```
export ANDROID_SDK_ROOT=/Users/hujiawei/Android/android_sdk
export PATH=${PATH}:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools
export ANDROID_NDK_ROOT=/Users/hujiawei/Android/android_ndk
export PATH=${PATH}:${ANDROID_NDK_ROOT}
```

使用`ndk-build -v`测试配置

```
GNU Make 3.81
Copyright (C) 2006  Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
This program built for i386-apple-darwin10.8.0
```

如果是在Windows下，并且安装了Cygwin的话，输出就略有不同，它使用的不是系统内置的GNU Make

```
$ ndk-build -v
GNU Make 3.82.90
Built for i686-pc-cygwin
Copyright (C) 2010  Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

在Eclipse(Android Development Tool)的设置中，在 C/C++ -> Build -> Environment 中添加下面两个配置 [添加这两项配置是为了后面进行各项关于路径配置的方便]

```
NDKROOT = /Users/hujiawei/Android/android_ndk
OPENCVROOT = /Users/hujiawei/Android/opencv_sdk
```

#### 5. 运行OpenCV for Android中的Sample项目FaceDetection

导入OpenCV for Android中的`Library Project` - `OpenCV Library - 2.4.4`

修改`Library Project`，改为前面导入到workspace中的`Library Project`

[原有的配置默认该项目和`Library Project`是在同一个目录下，所以如果你以前接触过的话，会发现很多文章都是告诉你要把`Library Project`拷贝到和当前项目同一个目录下，其实是完全没有必要的！]

修改`C/C++ Build`，将`Build Command`改成： `${NDKROOT}/ndk-build`  
[Windows平台则不要删除末尾的`.cmd`，Linux和Mac平台则需要删掉`.cmd`]

修改`C/C++ General`，将`Paths and Symbols`中的`GNU C`和`GNU C++`配置的最后一个路径修改成 `${OPENCVROOT}/sdk/native/jni/include` (这个路径保存的是opencv的native code头文件)
[建议将这个配置导出到文件中，方便以后做类似项目时可以快速进行配置]

修改jni目录下的`Android.mk`，将`include OpenCV.mk`这行改成：`include${OPENCVROOT}/sdk/native/jni/OpenCV.mk`
[原有的配置是默认OpenCV的sdk文件夹和包含项目根目录的文件夹是同一个目录下]

经过上面的配置之后，FaceDetection项目便没有问题了，打开jni目录下的cpp和h文件也不会报错了，当然，手机必须安装OpenCV Manager才能成功运行FaceDetection

运行人眼检测的示例程序

项目来源：<http://romanhosek.cz/android-eye-detection-and-tracking-with-opencv/>  
该作者根据原有的人脸检测做了一个人眼检测，博文最后附有[下载地址](http://romanhosek.cz/?wpdmact=process&did=MS5ob3RsaW5r)，我的[Github](https://github.com/yinger090807/XFace)上已经有了一份备份，配置方式和Face Detection一样  
[如果配置完了之后提示一个`app_platform`的警告的话，可以在`Application.mk`文件中添加 `APP_PLATFORM := android-8`]  
仔细理解上面的配置和操作，如果还有啥问题或者不清楚的可以查看[OpenCV官方这篇入门文档:Manual OpenCV4Android SDK setup](http://docs.opencv.org/doc/tutorials/introduction/android_binary_package/O4A_SDK.html)

两个项目运行结果：[帮主，对不住啦，谁叫您长得这么帅呢！我的脸识别不了，只能用您老的啦！]

![image](/images/face_detection.png)

![image](/images/eye_detection.png)


OK！本节结束！如果觉得好，请看下节[Android NDK 的核心内容和开发总结](/blog/2013/11/18/android-ndk-and-opencv-development-2/)！
