---
title: Build Android Studio Source Code
categories: "android"
date: "2016-11-09"
---
本文简单记录下如何编译Android Studio这个开发工具的源码。 <!--more-->

### 1.简单说明
android studio的源码其实是aosp中的一部分，同样是采用repo对git项目进行管理。
android studio的源码涉及到aosp中的sdk.git，ndk.git，external/qemu.git等几个项目。

`sdk.git` is the project for all java based tools such as the SDK Manager, DDMS, and the Eclipse plug-ins.
`ndk.git` is the project hosting the Android NDK source files.
`external/qemu.git` is the project for our qemu-based emulator.

sdk.git项目是一个核心项目，大部分基于Java开发的工具都在这个项目里面，包含了ddms，traceview， hierarchyviewer，lint等工具，其中的eclipse目录是android device monitor的工具的源码，包含了各种插件，例如ddms，traceview，hierarchyviewer等。

sdk.git项目根目录下的[README文档](http://androidxref.com/7.0.0_r1/xref/sdk/)的主要内容是关于sdk.git这个项目的变化以及使用需知
其中解答了几个重要的问题，例如如何只构建某个单独的工具？如何修改工具源码来构建一个新的sdk？
(1)I don't build full SDKs but I want to change tool X
(2)How do I change some tools sources and build a new SDK using these?

文档[http://tools.android.com/build](http://tools.android.com/build)中给出了编译sdk的方法
```
./tools/buildSrc/servers/build_tools.sh `pwd`/out `pwd`/out/dist 1234
```

如果遇到`Required ANDROID_HOME environment variable not set.`这个错误只需设置ANDROID_HOME这个环境变量即可

### 2.下载地址
android studio代码也可以通过repo来下载，分支可以使用master-dev或者某个具体版本对应的分支，下载之后大约占用4GB左右磁盘空间
```
repo init -u https://android.googlesource.com/platform/manifest -b studio-2.2
```

### 3.编译源码
3.1 使用ant
最简单的编译运行方式是在tools/idea目录下执行`ant`，最终会在tools/idea/out/中生成可运行的Android Studio应用程序

3.2 使用Intellij (推荐)
tools/idea目录下的README.md文档说明了如何编译Android Studio源码
(1)下载Intellij Community版本并安装
(2)使用IDEA打开项目的tools/idea目录
(3)在Project Structure的SDKs中新建名为`IDEA jdk`的jdk，路径设置为jdk 6的根目录
如果是在Linux/Mac上运行的话，还需要将<JDK_HOME>/lib/tools.jar添加到`IDEA jdk`中
(4)在Project Structure的SDKs中新建名为`1.8`的jdk，路径设置为jdk 8的根目录
(5)点击Build下的`Make Project`来编译项目源码
(6)选择`IDEA`这个运行配置来运行或者调试代码

运行起来就可以看到AS第一次安装时选择settings的界面，然后就进入到启动界面了

![img](/images/as_run.png)

如果遇到`java: package com.sun.source.tree does not exist`这个错误的话记得检查是否已经将`<JDK_HOME>/lib/tools.jar`添加到IDEA jdk中

下面是README.md文档的原文，其中第一步执行tools/idea目录下的`getPlugins.sh`脚本，这个脚本会去下载两个repository，但是**这个步骤在我这里一直没能成功，两个git项目能访问但是网络连接很慢源码下载不下来**，不过幸运的是这个步骤对后面的操作并没有影响。
`git clone git://git.jetbrains.org/idea/android.git android`
`git clone git://git.jetbrains.org/idea/adt-tools-base.git android/tools-base`

**Building and Running from the IDE**
To develop IntelliJ IDEA, you can use either IntelliJ IDEA Community Edition or IntelliJ IDEA Ultimate not older than 15.0. To build and run the code:

- Run getPlugins.sh / getPlugins.bat from the project root directory to check out additional modules.
- If this git repository is not on 'master' branch you need to checkout the same branches/tags in android and android/tools-base git repositories.
- Open the project.
- If an error notification about a missing required plugin (e.g. Kotlin) is shown enable or install that plugin.
- Configure a JDK named "IDEA jdk" (case sensitive), pointing to an installation of JDK 1.6.
- Unless you're running on a Mac with an Apple JDK, add <JDK_HOME>/lib/tools.jar to the set of "IDEA jdk" jars.
- Configure a JDK named "1.8", pointing to an installation of JDK 1.8.
- Add <JDK_18_HOME>/lib/tools.jar to the set of "1.8" jars.
- Use Build | Make Project to build the code.
- To run the code, use the provided shared run configuration "IDEA".

### 4.其他参考资料
(1) [Build Android Studio](http://tools.android.com/build/studio)
(2) hierarchyviewer工具的学习，从使用到源码实现
[http://www.cnblogs.com/vowei/archive/2012/07/30/2614353.html](http://www.cnblogs.com/vowei/archive/2012/07/30/2614353.html)
[http://www.cnblogs.com/vowei/archive/2012/08/03/2618753.html](http://www.cnblogs.com/vowei/archive/2012/08/03/2618753.html)
[http://www.cnblogs.com/vowei/archive/2012/08/08/2627614.html](http://www.cnblogs.com/vowei/archive/2012/08/08/2627614.html)
[http://www.cnblogs.com/vowei/archive/2012/08/22/2650722.html](http://www.cnblogs.com/vowei/archive/2012/08/22/2650722.html)


