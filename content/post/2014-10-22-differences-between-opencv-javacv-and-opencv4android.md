---
title: "Differences between OpenCV JavaCV and OpenCV4Android"
date: "2014-10-23"
tags: ["android"]
---
OpenCV，JavaCV以及OpenCV4Android之间的关系 <!--more-->

最近我在考虑是否要改变XFace项目的技术方案，经过一番调研后我得到下面的结果。

本文将介绍OpenCV，JavaCV以及OpenCV for Android(以下简称OpenCV4Android)之间的区别，并以一个人脸识别的Android应用为例，详细介绍可以采用的实践方案。

OpenCV: [http://docs.opencv.org/index.html](http://docs.opencv.org/index.html)

OpenCV4Android: [OpenCV4Android_SDK.html](http://docs.opencv.org/doc/tutorials/introduction/android_binary_package/O4A_SDK.html)

JavaCV: [https://github.com/bytedeco/javacv](https://github.com/bytedeco/javacv)

### OpenCV，JavaCV，OpenCV4Android

#### (1) **JavaCV和OpenCV4Android没有关系**

OpenCV是C++版本的开源计算机视觉库；JavaCV是对OpenCV的Java封装，开发团队和OpenCV开发团队没有关系；OpenCV4Android也是对OpenCV的封装以使其能够应用于Android平台，开发团队是OpenCV开发团队的一部分，也就是OpenCV4Android和JavaCV没有任何关系！

参考网址：[https://groups.google.com/forum/#!topic/javacv/qJmBLvpV7cM](https://groups.google.com/forum/#!topic/javacv/qJmBLvpV7cM)

>android-opencv has no relation to JavaCV, so you should ask somewhere else for questions about it.. The philosophy of android-opencv (and of the OpenCV team as general) is to make OpenCV run on Android, which forces them to use Java, but otherwise they prefer to use C++ or Python. With JavaCV, my hope is to have it run on as many platforms as possible, including Android, since it supports (some sort of) Java, so we can use sane(r) and more efficient languages such as the Java and Scala languages. Take your pick!

#### (2) **JavaCV和OpenCV的性能比较**

大多数时候两者性能相差不大，某些OpenCV函数能够并行化处理而JavaCV不行，但是JavaCV还绑定了很多其他的图像处理库，功能也足够强大。

参考网址：[http://stackoverflow.com/questions/21207755/opencv-javacv-vs-opencv-c-c-interfaces](http://stackoverflow.com/questions/21207755/opencv-javacv-vs-opencv-c-c-interfaces)

>I'd like to add a couple of things to @ejbs's answer.       
First of all, you concerned 2 separate issues:       
Java vs. C++ performance       
OpenCV vs JavaCV       
Java vs. C++ performance is a long, long story. On one hand, C++ programs are compiled to a highly optimized native code. They start quickly and run fast all the time without pausing for garbage collection or other VM duties (as Java do). On other hand, once compiled, program in C++ can't change, no matter on what machine they are run, while Java bytecode is compiled "just-in-time" and is always optimized for processor architecture they run on. In modern world, with so many different devices (and processor architectures) this may be really significant. Moreover, some JVMs (e.g. Oracle Hotspot) can optimize even the code that is already compiled to native code! VM collect data about program execution and from time to time tries to rewrite code in such a way that it is optimized for this specific execution. So in such complicated circumstances the only real way to compare performance of implementations in different programming languages is to just run them and see the result.        
OpenCV vs. JavaCV is another story. First you need to understand stack of technologies behind these libraries.         
OpenCV was originally created in 1999 in Intel research labs and was written in C. Since that time, it changed the maintainer several times, became open source and reached 3rd version (upcoming release). At the moment, core of the library is written in C++ with popular interface in Python and a number of wrappers in other programming languages.
JavaCV is one of such wrappers. So in most cases when you run program with JavaCV you actually use OpenCV too, just call it via another interface. But JavaCV provides more than just one-to-one wrapper around OpenCV. In fact, it bundles the whole number of image processing libraries, including FFmpeg, OpenKinect and others. (Note, that in C++ you can bind these libraries too).         
So, in general it doesn't matter what you are using - OpenCV or JavaCV, you will get just about same performance. It more depends on your main task - is it Java or C++ which is better suited for your needs.        
There's one more important point about performance. Using OpenCV (directly or via wrapper) you will sometimes find that OpenCV functions overcome other implementations by several orders. This is because of heavy use of low-level optimizations in its core. For example, OpenCV's filter2D function is SIMD-accelerated and thus can process several sets of data in parallel. And when it comes to computer vision, such optimizations of common functions may easily lead to significant speedup.       


#### (3) **人脸识别的Android应用**

#### **对人脸识别算法的支持**

目前OpenCV的最新版本是2.4.10，OpenCV4Android是2.4.9，JavaCV的版本是0.9

OpenCV自然支持人脸识别算法，详细的使用教程看[这里](http://docs.opencv.org/modules/contrib/doc/facerec/index.html)

OpenCV4Android暂时不支持，但是可以通过建立一层简单的封装来实现，封装的方法看[这里](http://stackoverflow.com/questions/25830660/face-recognize-using-opencv4android-sdk-tutorial)

JavaCV现在已经支持人脸识别算法了，在Samples中可以找到一份样例代码[OpenCVFaceRecognizer.java](https://github.com/bytedeco/javacv/blob/master/samples/OpenCVFaceRecognizer.java)

#### **不可忽视的摄像头！**

因为是移动应用，所以要能够从移动设备中获取摄像头返回的数据是关键！而这个恰恰是这类应用要考虑的一个重要因素，因为它直接决定了你的应用需要使用的技术方案！

关于摄像头的使用其实我已经在前面的博文[Android Ndk and Opencv Development 3](/blog/2013/11/18/android-ndk-and-opencv-development-3/)中详细介绍过了，这里我引用部分内容，如果想了解更多的话，不妨先看下前面的内容。 [下面提到的`OpenCV library` 是 `OpenCV4Android SDK` 的一部分]

[其实还有一种获取摄像头数据的方式，那就是直接在Native层操作摄像头，OpenCV4Android SDK的Samples中提供了一个样例`native-activity`，这种方式其实是极其不推荐使用的，一方面代码不好写，不便操作；另一方面据说这部分的API经常变化，不便维护]

(1) 关于如何进行和OpenCV有关的摄像头开发

在没有OpenCV library的情况下，也就是我们直接使用Android中的Camera API的话，获取得到的图像帧是`YUV`格式的，我们在处理之前往往要先转换成`RGB(A)`格式的才行。

如果有了OpenCV library的话摄像头的开发就简单多了，可以参见OpenCV for Android中的三个Tutorial(`CameraPreview`, `MixingProcessing`和`CameraControl`)，源码都在OpenCV-Android sdk的samples目录下，这里简单介绍下：OpenCV Library中提供了两种摄像头，一种是Java摄像头-`org.OpenCV.Android.JavaCameraView`，另一种是Native摄像头-`org.OpenCV.Android.NativeCameraView` (可以运行CameraPreview这个项目来体验下两者的不同，其实差不多)。两者都继承自`CameraBridgeViewBase`这个抽象类，但是JavaCamera使用的就是Android SDK中的`Camera`，而NativeCamera使用的是OpenCV中的`VideoCapture`。

(2) 关于如何传递摄像头预览的图像数据给Native层

这个很重要！我曾经试过很多的方式，大致思路有：

①传递图片路径：这是最差的方式，我使用过，速度很慢，实时性很差，主要用于前期开发的时候进行测试，测试Java层和Native层的互调是否正常。   

②传递预览图像的字节数组到Native层，然后将字节数组处理成`RGB`或者`RGBA`的格式[具体哪种格式要看你的图像处理函数能否处理`RGBA`格式的，如果可以的话推荐转换成`RGBA`格式，因为返回的也是`RGBA`格式的]。网上有很多的文章讨论如何转换：一种方式是使用一个自定义的函数进行编码转换(可以搜索到这个函数，例如这篇文章[Camera image->NDK->OpenGL texture](http://nhenze.net/?p=253))，另一个种方式是使用OpenCV中的`Mat`和`cvtColor`函数进行转换，接着调用图像处理函数，处理完成之后，将处理的结果保存在一个整形数组中(实际上就是`RGB`或者`RGBA`格式的图像数据)，最后调用Bitmap的方法将其转换成bitmap返回。这种方法速度也比较慢，但是比第一种方案要快了不少，具体实现过程可以看推荐书籍[《Mastering OpenCV with Practical Computer Vision Projects》](https://github.com/MasteringOpenCV)，第一章`Cartoonifer and Skin Changer for Android`就是一个Android的应用实例。   

③使用OpenCV的摄像头：JavaCamera或者NativeCamera都行，好处是它进行了很多的封装，可以直接将预览图像的`Mat`结构传递给Native层，这种传递是使用`Mat`的内存地址(`long`型)，Native层只要根据这个地址将其封装成`Mat`就可以进行处理了，另外，它的回调函数的返回值也是`Mat`，非常方便！这种方式速度较快。具体过程可以参考OpenCV-Android sdk的samples项目中的`Tutorial2-MixedProcessing`。


#### **可选方案有哪些？**

综上所述，我们来总结下如果想要开发一个人脸识别的Android应用程序，大致会有哪些技术方案呢？

(1) 摄像头使用纯Android Camera API，将`YUV`格式的数据传入到Native层，转换成`RGB(A)` 格式，然后调用OpenCV人脸识别算法进行处理，最后将处理结果`RGB(A)` 格式数据返回给Java层。优点是对其他内容的依赖较少，灵活性好，开发者甚至可以对内部算法进行修改，缺点自然是需要开发者具有很强的技术水平，要同时熟练OpenCV和Android NDK开发，在三星Galaxy I9000上测试比较慢，有明显卡顿延迟。

这种方式可以参考书籍[《Mastering OpenCV with Practical Computer Vision Projects》](https://github.com/MasteringOpenCV) 的第一章`Cartoonifer and Skin Changer for Android` 的实现方式。 > [我测试通过的源码下载](/files/Cartoonifier_Android.zip)

最近发现一个项目也是采用这种方式，而且代码质量较高，可惜的是并没有公开Native层代码，而只是提供了Java层的SDK，[详情可见这里](https://github.com/Vinisoft/Face-Recognition-SDK-for-Android)

(2) 摄像头使用纯Android Camera API，将`YUV`格式的数据直接在Java层转换成`RGB(A)` 格式，直接传给JavaCV人脸识别算法进行处理，然后返回识别结果即可。优点是只依赖了JavaCV，缺点是从OpenCV算法转成JavaCV实现需要些工作量。

这种方式我没有试验过，转换的方式可以参考[这里](http://stackoverflow.com/questions/16471884/opencv-for-android-convert-camera-preview-from-yuv-to-rgb-with-imgproc-cvtcolor) **[我会尽快试验一下，如果可行我会将代码公开]**

(3) 摄像头使用OpenCV4Android Library，将得到的数据`Mat` 的内存地址传给Native层，Native层通过地址还原成`Mat`，然后调用OpenCV人脸识别算法进行处理，最后将处理结果`RGB(A)` 格式数据返回给Java层。优点是灵活性好，缺点是依赖了OpenCV4Android Library和OpenCV，所以需要掌握OpenCV和Android NDK开发，在三星Galaxy I9000上测试还行，如果算法处理比较慢的话会慢1-3s左右才返回结果。

这种方式可以参考OpenCV-Android sdk的samples项目中的`Tutorial2-MixedProcessing` [我的开源项目`XFace`采用的正是这种方案]

(4) 摄像头使用OpenCV4Android Library，Native层对OpenCV人脸识别算法类进行简单封装，然后将摄像头得到的数据`Mat` 直接传给OpenCV4Android Library的人脸识别算法，然后返回识别结果即可。优点是依赖还不算多而且可能要写的Native层代码也不多。

这种方式我试验过，利用前面提到过封装的方法，可以参考[这里](http://stackoverflow.com/questions/25830660/face-recognize-using-opencv4android-sdk-tutorial)，注意按照答案的例子在加载`facerec` 库之前要记得加载`opencv_java` 库才行！ >[我测试通过的源码下载](/files/NDKDemo.zip)

(5) 摄像头使用OpenCV4Android Library，然后将摄像头得到的数据`Mat` 直接传给JavaCV的人脸识别算法，然后返回识别结果即可。优点是看起来方案很不错，只需要写Java代码就行了，Native层可能只需要导入一些`*so` 文件到`jniLibs` 目录中就行了，缺点是依赖太多了！

这种方式可以参考[Github上的这个项目](https://github.com/ayuso2013/face-recognition)     > [我测试通过的源码下载](/files/face-recognition-ayuso.zip)

各种方案各有利弊，一方面要考虑技术方案是否可行，另一方面还要考虑该技术方案是否便于开发！哎，码农真是伤不起啊！


**补充部分**

这里假设你是按照我上一篇文章[Android NDK and OpenCV Development With Android Studio](/blog/2014/10/22/android-ndk-and-opencv-development-with-android-studio/) 的方式来创建的项目。

(1) 方案1中的部分代码

实现将`YUV` 格式数据转换成 `RGBA` 格式数据的Native层代码

```java
// Just show the plain camera image without modifying it.
JNIEXPORT void JNICALL Java_com_Cartoonifier_CartoonifierView_ShowPreview(JNIEnv* env, jobject,
        jint width, jint height, jbyteArray yuv, jintArray bgra)
{
    // Get native access to the given Java arrays.
    jbyte* _yuv  = env->GetByteArrayElements(yuv, 0);
    jint*  _bgra = env->GetIntArrayElements(bgra, 0);

    // Prepare a cv::Mat that points to the YUV420sp data.
    Mat myuv(height + height/2, width, CV_8UC1, (uchar *)_yuv);
    // Prepare a cv::Mat that points to the BGRA output data.
    Mat mbgra(height, width, CV_8UC4, (uchar *)_bgra);

    // Convert the color format from the camera's
    // NV21 "YUV420sp" format to an Android BGRA color image.
    cvtColor(myuv, mbgra, CV_YUV420sp2BGRA);

    // OpenCV can now access/modify the BGRA image if we want ...

    // Release the native lock we placed on the Java arrays.
    env->ReleaseIntArrayElements(bgra, _bgra, 0);
    env->ReleaseByteArrayElements(yuv, _yuv, 0);
}
```


(2) 方案4中的部分代码

`Android.mk` 文件

```
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

#opencv
OPENCVROOT:= /Volumes/hujiawei/Users/hujiawei/Android/opencv_sdk
OPENCV_CAMERA_MODULES:=on
OPENCV_INSTALL_MODULES:=on
OPENCV_LIB_TYPE:=SHARED
include ${OPENCVROOT}/sdk/native/jni/OpenCV.mk

LOCAL_SRC_FILES := facerec.cpp

LOCAL_LDLIBS += -llog
LOCAL_MODULE := facerec

include $(BUILD_SHARED_LIBRARY)
```

`Application.mk` 文件

```
APP_STL := gnustl_static
APP_CPPFLAGS := -frtti -fexceptions
APP_ABI := armeabi
APP_PLATFORM := android-16
```

`FisherFaceRecognizer` 文件

```
package com.android.hacks.ndkdemo;

import org.opencv.contrib.FaceRecognizer;

public class FisherFaceRecognizer extends FaceRecognizer {

    static {
        System.loadLibrary("opencv_java");//
        System.loadLibrary("facerec");//
    }

    private static native long createFisherFaceRecognizer0();

    private static native long createFisherFaceRecognizer1(int num_components);

    private static native long createFisherFaceRecognizer2(int num_components, double threshold);

    public FisherFaceRecognizer() {
        super(createFisherFaceRecognizer0());
    }

    public FisherFaceRecognizer(int num_components) {
        super(createFisherFaceRecognizer1(num_components));
    }

    public FisherFaceRecognizer(int num_components, double threshold) {
        super(createFisherFaceRecognizer2(num_components, threshold));
    }
}
```

之后你可以测试，当然你还可以做一个完整的例子来测试这个算法是否正确

```
facerec = new FisherFaceRecognizer();
textView.setText(String.valueOf(facerec.getDouble("threshold")));//1.7976xxxx
```
