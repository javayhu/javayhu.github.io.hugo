---
title: "Android Ndk and Opencv Development 2"
date: "2013-11-18"
tags: ["android"]
---
本节主要介绍的内容是[Android NDK](http://developer.android.com/tools/sdk/ndk/index.html)开发的核心内容和开发总结(包括很多常见问题的解决方案)。<!--more-->

本节主要分为三部分：  
1.JNI技术和javah命令   
2.Android NDK Dev Guide   
3.NDK开发中常见的问题  

#### 1.不得不说的JNI和javah命令

NDK开发的核心之一便是JNI，在[Oracle官方的JNI相关文档](http://docs.oracle.com/javase/7/docs/technotes/guides/jni/spec/jniTOC.html)中重要的是里面的第3-4部分(数据类型和函数)，本文不会介绍这些，如果想快速入手可以查看[这位作者的几篇关于JNI的文章](http://my.oschina.net/zhiweiofli/blog?catalog=225458)，讲得深入浅出，另外推荐一篇[IBM DeveloperWorks上的文章:JNI 对象在函数调用中的生命周期](http://www.ibm.com/developerworks/cn/java/j-lo-jni/index.html)，讲得有点深奥哟。

[javah命令：查看命令详细参数](http://docs.oracle.com/javase/6/docs/technotes/tools/windows/javah.html)  
`javah produces C header files and C source files from a Java class. These files provide the connective glue that allow your Java and C code to interact.`

在Eclipse中配置**万能的javah工具**的方法

(1)在`External Tools Configurations`中新建`Program`
(2)`Location`设置为`/usr/bin/javah` [你可能不是这个位置，试试`${system_path:javah}`]
(3)`Working Directory`设置为`${project_loc}/bin/classes` [适用于Android项目开发]
(4)`Arguments`设置为`-jni -verbose -d "${project_loc}${system_property:file.separator}jni" ${java_type_name}`
(5)OK，以后只要选中要进行"反编译"的Java Class，然后运行这个External Tool就可以了！    

**注意**因为我的`Arguments`设置为导出的头文件是放在项目的jni目录中，如果不是Android NDK开发的话，请自行修改输出路径，还有`Working Directory`设置为`${project_loc}/bin`，不要包含后面的`/classes`。如果还有问题的话，推荐看下[这位作者的JNI相关配置](http://blog.csdn.net/mirkerson/article/details/8901270)

#### 2.那些年的Android NDK Dev Guide

在ndk的根目录下有一个html文件`document.html`，这个就是Android NDK Dev Guide，用浏览器打开可以看到里面介绍了NDK开发中的很多配置问题，不同版本的NDK差别还是蛮大的，而且NDK开发中问题会很多，不像SDK开发那么简单，所以，一旦出现了问题，运气好能够Google解决，RP弱的时候只能啃这些Guide来找答案了。这几篇文章的简单介绍可以查看[Android Developer上的解释](http://developer.android.com/tools/sdk/ndk/index.html#Docs)。对于这部分的内容，可以阅读下[这位作者的几篇NDK Dev Guide的翻译版本](http://blog.csdn.net/smfwuxiao/article/category/1328624)，虽然略有过时，但是看后肯定会很受用的，下面我简单介绍下这里的几个内容：

**[1]Android NDK Overview**
这篇文章介绍了NDK的目标和NDK开发的简易实践过程，后面的那些文章基本上都是围绕这个核心内容展开的，非常建议阅读。需要注意的是，NDK只支持Android 1.5版本以上的设备。

**[2]Android.mk文件**
Android.mk文件是用来描述源代码是如何进行编译的，**ndk-build命令实际上对GNU Make命令的一个封装**，所以，Android.mk文件的写法就类似Makefile的写法[关于Make的详细内容可以看这本书，[GNU Make的中文手册]，虽然是今年读的，但是我记得的也不多了，老了老了…]   
Android.mk文件可以生成一个动态链接库或者一个静态链接库，但是只有动态链接库是会复制到应用的安装包中的，静态库一般是用来生成其他的动态链接库的。你可以在一个Android.mk文件定义一个或者多个module，不同的module可以使用相同的source file进行编译得到。你不需要列出头文件，也不需要显示指明要生成的目标文件之间的依赖关系(这些内容在GNU Make中是很重要的，虽然GNU Make中的隐式规则也可以做到)。下面以hello-jni项目中的Android.mk文件为例讲解其中重要的几点。

```
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE    := hello-jni
LOCAL_SRC_FILES := hello-jni.c
include $(BUILD_SHARED_LIBRARY)
```

①`LOCAL_PATH := $(call my-dir)`：Android.mk文件的第一行必须要指明`LOCAL_PATH`，`my-dir`是编译系统提供的一个宏函数，这个宏函数会返回当前Android.mk文件所在的目录
②`include $(CLEAR_VARS)`：`CLEAR_VARS`是编译系统提供的一个变量，这个变量指向一个特殊的Makefile文件，它会清除所有除了`LOCAL_PATH`之外的其他的`LOCAL_XXX`变量。
③`LOCAL_MODULE := hello-jni`：必须要指定`LOCAL_MODULE`，它是指这个Android.mk要生成的目标，这个名称是一个**不包含空格的唯一的字符串**，编译系统会自动根据名称进行一定的修改，例如`foo.so`和`libfoo.so`得到的都是`libfoo.so`！在Java代码中进行加载的时候使用的是没有`lib`的module名。
④`LOCAL_SRC_FILES := hello-jni.c`：指定C/C++源文件列表，不要包含头文件。如果需要自定义C++源文件的后缀，可以配置`LOCAL_CPP_EXTENSION`参数。注意写法，我给个例子，一定要记住每行后面加上一个反斜线符，并且反斜线符后面不能再有任何内容，否则编译会报错！

```
LOCAL_SRC_FILES := hello-jni.c \
foo.c  \
boo.cpp
```

⑤`include $(BUILD_SHARED_LIBRARY)`：`BUILD_SHARED_LIBRARY`是编译系统提供的一个Makefile文件，它会根据你前面提供的参数来生成动态链接库，同理，如果是`BUILD_STATIC_LIBRARY`的话，便是生成静态链接库。

**最佳实践**：一般来说，`LOCAL_`作为前缀的一般定义LOCAL Module的变量，`PRIVATE_`或者`NDK_`或者`APP_`一般定义内部使用的变量，`lower-case`小写字母的名称一般也是定义内部使用的变量或者函数。如果你要在Android.mk文件定义自己的变量，建议使用`MY_`作为前缀！

```
MY_SOURCES := foo.c
ifneq ($(MY_CONFIG_BAR),)
   MY_SOURCES += bar.c
endif
LOCAL_SRC_FILES += $(MY_SOURCES)
```
Android.mk这篇文章中后面详细介绍了很多编译系统内置的变量和函数，以及该文件内可以设置的变量，此处就不再赘述了。

**[3]Application.mk文件**

Application.mk文件描述的是你的应用需要使用哪些native modules，这个文件不是必须的，小项目可以不用编写这个文件。这个文件可以放在两个不同的位置，最常用的是放在jni目录下，和Android.mk文件放在一块，也可以放在`$NDK/apps/<myapp>/`目录下(不推荐使用后者，如果使用的是后者，那么必须要显示指定`APP_PROJECT_PATH`)

①`APP_MODULES`：这个参数在NDK r4之前是一定要指定的，之后便是可选的，默认情况下，NDK将编译Android.mk文件中定义的所有的modules。
②`APP_CFLAGS`：这个参数用来指定编译C/C++文件选项参数，例如`-frtti -fexceptions`等等，而`APP_CPPFLAGS`是专门用来指定编译C++源文件的选项参数。
③`APP_ABI`：这个参数很重要，默认情况下，ndk-build将生成对应`armeabi`CPU架构的库文件，你可以指定其他的CPU架构，或者同时指定多个(自从NDK r7之后，设置为`all`可以生成所有CPU架构的库文件)！关于不同CPU架构的介绍在`CPU Arch ABIs`中介绍了，我不是很懂，此文不细讲。如果想要查看某个android设备是什么CPU架构，可以上网查设备的资料，或者通过执行`adb shell getprop ro.product.cpu.abi`得到，下面这段摘自[OpenCV for Android SDK](http://docs.opencv.org/doc/tutorials/introduction/android_binary_package/O4A_SDK.html)

```
armeabi, armv7a-neon, arm7a-neon-android8, mips and x86 stand forplatform targets:
   * armeabi is for ARM v5 and ARM v6 architectures with Android API 8+,
   * armv7a-neon is for NEON-optimized ARM v7 with Android API 9+,
   * arm7a-neon-android8 is for NEON-optimized ARM v7 with Android API 8,
   * mips is for MIPS architecture with Android API 9+,
   * x86 is for Intel x86 CPUs with Android API 9+.
If using hardware device for testing/debugging, run the following command to learnits CPU architecture:
*** adb shell getprop ro.product.cpu.abi ***
If you’re using an AVD emulator, go Window > AVD Manager to see thelist of availible devices. Click Edit in the context menu of theselected device. In the window, which then pop-ups, find the CPU field.
```

④`APP_STL`：指定STL，默认情况下ndk编译系统使用最精简的C++运行时库`/system/lib/libstdc++.so`，但是你可以指定其他的。详细的内容可以查看`$NDK/docs/CPLUSPLUS-SUPPORT.html`文件，这个文件可能并没有列出在document.html中！

```
system          -> Use the default minimal system C++ runtime library.
gabi++_static   -> Use the GAbi++ runtime as a static library.
gabi++_shared   -> Use the GAbi++ runtime as a shared library.
stlport_static  -> Use the STLport runtime as a static library.
stlport_shared  -> Use the STLport runtime as a shared library.
gnustl_static   -> Use the GNU STL as a static library.
gnustl_shared   -> Use the GNU STL as a shared library.
```

我们可以从文档的表格中看出它们对C++语言特性的支持程度，其中gnustl很不错，所以一般会配置为gnustl_static。如果选用的是gnustl的话，一般还需要在`C/C++ General`下的`Paths and Symbols`中的`GNU C`和`GNU C++`配置里添加`${NDKROOT}/sources/cxx-stl/gnu-libstdc++/4.6/include` 和 `${NDKROOT}/sources/cxx-stl/gnu-libstdc++/4.6/libs/armeabi-v7a/include` 这两项。

另外需要注意的是，如果你指定的是`xxx_shared`，想要在运行时加载它，并且其他的库是基于`xxx_shared`的话，一定记得要先加载`xxx_shared`，然后再去加载其他的库。

⑤`APP_PLATFORM`：指定目标android系统版本，注意，指定的是`API level`，一般情况下，这里可能会与`AndroidManifest.xml`文件中定义的`minSdkVersion`冲突而报错，处理办法是类似上一节中提到的修改`APP_PLATFORM`保证两个不冲突就行了。

**[4]Stable-APIS**

build system会自动加载C库，Math库以及C++支持库，所以你不需要通过`LOCAL_LDLIBS`指定加载他们。Android系统下有多个`API level`，每个`API level`都对应了一个Android的发布系统，对应关系如下所示。其中`android-6`，`android-7`和`android-5`是一样的NDK，也就是说他们提供的是相同的native ABIs。对应`API level`的头文件都放在了`$NDK/platforms/android-<level>/arch-arm/usr/include`目录下，这正是上一节中导入的项目中在`C/C++ General`下的`Paths and Symbols`中的`GNU C`和`GNU C++`配置。

```
Note that the build system automatically links the C library, the Math
library and the C++ support library to your native code, there is no
need to list them in a LOCAL_LDLIBS line.
There are several "API Levels" defined. Each API level corresponds to
a given Android system platform release. The following levels are
currently supported:
    android-3      -> Official Android 1.5 system images
    android-4      -> Official Android 1.6 system images
    android-5      -> Official Android 2.0 system images
    android-6      -> Official Android 2.0.1 system images
    android-7      -> Official Android 2.1 system images
    android-8      -> Official Android 2.2 system images
    android-9      -> Official Android 2.3 system images
    android-14     -> Official Android 4.0 system images
Note that android-6 and android-7 are the same as android-5 for the NDK,
i.e. they provide exactly the same native ABIs!
IMPORTANT:
    The headers corresponding to a given API level are now located
    under $NDK/platforms/android-<level>/arch-arm/usr/include
```

介绍几个比较重要的库：  
(1)C库(libc)：不需要指定 –lpthread –lrt，也就是说它会自动链接  
(2)C++库(lstdc++)：不需要指定 –lstdc++  
(3)Math库(libm)：不需要指定 –lm  
(4)动态链接器库(libdl)：不需要指定 –ldl   
(5)Android log(liblog)：**需要**指定 –llog  
(6)Jnigraphics库(libjnigraphics)：这个C语言库提供了对Java中Bitmap的操作，**需要**指定 –ljnigraphics，这个库是`android-8`新增加的内容，典型的使用方式是：  

```
Briefly, typical usage should look like:
    1/ Use AndroidBitmap_getInfo() to retrieve information about a
       given bitmap handle from JNI (e.g. its width/height/pixel format)
    2/ Use AndroidBitmap_lockPixels() to lock the pixel buffer and
       retrieve a pointer to it. This ensures the pixels will not move
       until AndroidBitmap_unlockPixels() is called.
    3/ Modify the pixel buffer, according to its pixel format, width,
       stride, etc.., in native code.
    4/ Call AndroidBitmap_unlockPixels() to unlock the buffer.
```

(7)The Android native application APIs：`android-9`新增加的内容，这些API使得你可以完全使用native code编写android app，但是一般情况下还是需要通过jni的，相关API如下：

```
The following headers correspond to these new native APIs (see comments
inside them for more details):

  <android/native_activity.h>

        Activity lifecycle management (and general entry point)

  <android/looper.h>
  <android/input.h>
  <android/keycodes.h>
  <android/sensor.h>

        To Listen to input events and sensors directly from native code.

  <android/rect.h>
  <android/window.h>
  <android/native_window.h>
  <android/native_window_jni.h>

        Window management, including the ability to lock/unlock the pixel
        buffer to draw directly into it.

  <android/configuration.h>
  <android/asset_manager.h>
  <android/storage_manager.h>
  <android/obb.h>
        Direct (read-only) access to assets embedded in your .apk. or
        the Opaque Binary Blob (OBB) files, a new feature of Android X.X
        that allows one to distribute large amount of application data
        outside of the .apk (useful for game assets, for example).

All the corresponding functions are provided by the "libandroid.so" library
version that comes with API level 9. To use it, use the following:

    LOCAL_LDLIBS += -landroid
```

**[5]NDK Build**

使用`ndk-build`命令(ndk r4之后引入的)实际上是GNU Make的封装，它等价于`make -f $NDK/build/core/build-local.mk [参数]`命令。系统必须要安装GNU Make 3.81以上版本，否则编译将报错！如果你安装了GNU Make 3.81，但是默认的make命令没有启动，那么可以在执行`ndk-build`之前定义GNUMAKE这个变量，例如`GNUMAKE=/usr/local/bin/gmake ndk-build`。  

**注意** 在Windows下进行NDK开发的话，一般使用的是Cygwin自带的Make工具，但是默认是使用NDK的awk工具，所以可能会报一个错误`Android NDK: Host 'awk' tool is outdated. Please define HOST_AWK to point to Gawk or Nawk !` 解决方案就是删除NDK自带的awk工具([参考网址](http://blog.csdn.net/achellies/article/details/7531440))，这也就是第一节中使用`ndk-build -v`命令得到的GNU Make信息输出不同了，嘿嘿，我这伏笔埋的够深吧！其实，也可以使用下面的方式直接覆盖系统的环境变量  

`NDK_HOST_AWK=<path-to-awk>
NDK_HOST_ECHO=<path-to-echo>
NDK_HOST_CMP=<path-to-cmp>`

如果还是不行的话，参见[StackOverflow上的解答](http://stackoverflow.com/questions/8384213/android-ndk-revision-7-host-awk-tool-is-outdated-error)  
在Windows先开发还有一个需要注意的是，如果是使用Cygwin对native code进行编译，那么需要在使用`ndk-build`之前调用`NDK_USE_CYGPATH=1`！(不过不用每次都使用)  

下面是ndk-build命令的可用参数，比较常用的是 `ndk-build NDK_DEBUG=1` 或者 `ndk-build V=1`

```
  ndk-build                  --> rebuild required machine code.
  ndk-build clean            --> clean all generated binaries.
  ndk-build NDK_DEBUG=1      --> generate debuggable native code.
  ndk-build V=1              --> launch build, displaying build commands.
  ndk-build -B               --> force a complete rebuild.
  ndk-build -B V=1           --> force a complete rebuild and display build
                                 commands.
  ndk-build NDK_LOG=1        --> display internal NDK log messages
                                 (used for debugging the NDK itself).
  ndk-build NDK_DEBUG=1      --> force a debuggable build (see below)
  ndk-build NDK_DEBUG=0      --> force a release build (see below)
  ndk-build NDK_HOST_32BIT=1 --> Always use toolchain in 32-bit (see below)
  ndk-build NDK_APPLICATION_MK=<file>
    --> rebuild, using a specific Application.mk pointed to by
        the NDK_APPLICATION_MK command-line variable.
  ndk-build -C <project>     --> build the native code for the project
                                 path located at <project>. Useful if you
                                 don't want to 'cd' to it in your terminal.
```

**[6]NDK GDB，Import Module，Prebuilts，Standalone Toolchains以及和CPU相关的三个内容**因为我没有涉及过，自己也不是很了解，所以此处暂时搁置了，以后如果用到以后补充。关于NDK调试环境的搭建可以参见[这位作者的实践博文](http://qiang106.iteye.com/blog/1830416)

**[7][Tips and Tricks 建议和技巧](http://blog.csdn.net/smfwuxiao/article/details/6612373)**  

#### 那些曾经的头疼的问题

**[1]使用Android SDK Manager下载SDK时失败或者很慢**  
在Windows下修改hosts文件：`C:\Windows\System32\drivers\etc`   
增加如下一行配置：`74.125.237.1 dl-ssl.google.com`

**[2]`Fatal signal 11 (SIGSEGV) at 0x00000004 (code=1), thread 23487 (mple)`**  
错误原因是因为访问了非法访问的内存地址，具体的原因可能是访问了null对象或者数组，很有可能是Java层传给Native层的对象是null，导致Native层访问了非法访问的地址。[参考网址1](http://stackoverflow.com/questions/14495242/android-fatal-signal-11-sigsegv-at-0x00000040-code-1-error?rq=1)   [参考网址2](http://stackoverflow.com/questions/10787676/fatal-signal-11-sigsegv-at-0x00000000-code-1)

**[3]使用ADB命令向AVD中复制文件或文件夹时报错**  
默认情况下avd对应的目录是只读的，去掉只读就好了。[参考网址](http://www.crifan.com/ddms_import_file_error_transfer_error_read_only_file_system/)

**[4]对android项目执行`add Native Support`报错**
使用`add Native Support`时一定要记住项目不能有jni目录！如果有的话，那就只能先删除(或者备份重要内容)，然后再执行`add Native Support`。

**[5]将String传递到Native层解析出现了乱码！**
使用自定义的将jstring转换成char*的函数，内容如下：

```
static char* jstringToString(JNIEnv* env, jstring jstr) {
    char* rtn = NULL;
    jclass clsstring = env->FindClass("java/lang/String");
    jstring strencode = env->NewStringUTF("utf-8"); //"gbk");//
    jmethodID mid = env->GetMethodID(clsstring, "getBytes",
            "(Ljava/lang/String;)[B");
    jbyteArray barr = (jbyteArray) env->CallObjectMethod(jstr, mid, strencode);
    jsize alen = env->GetArrayLength(barr);
    jbyte* ba = env->GetByteArrayElements(barr, JNI_FALSE);
    if (alen > 0) {
        rtn = (char*) malloc(alen + 1);
        memcpy(rtn, ba, alen);
        rtn[alen] = '\0';
    }
    env->ReleaseByteArrayElements(barr, ba, 0);
    return rtn;
}
```

哦了，还不痛快? 请看下节[OpenCV 在 Android NDK 开发中的应用](/blog/2013/11/18/android-ndk-and-opencv-development-3/)
