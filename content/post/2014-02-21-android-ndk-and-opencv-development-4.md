---
title: "Android Ndk and Opencv Development 4"
date: "2014-02-21"
tags: ["android"]
---
本节以[XFace项目](http://github.com/hujiaweibujidao/XFace.git)为例介绍Android NDK和OpenCV整合开发的流程<!--more-->

XFace项目地址：[https://github.com/hujiaweibujidao/XFace](https://github.com/hujiaweibujidao/XFace)

为便于开始进行XFace人脸识别系统研发，提供了已配置好安卓开发环境的Linux系统（64位的Ubuntu 12.04）虚拟机，在安装好VMware（版本在VMware 8以上）之后，打开Ubuntu 64 xface.vmwarevm目录中Ubuntu 64 xface.vmx，以用户名`xface`及密码`xface`登录后，直接打开桌面上的`Link to eclipse`，便可按本文档第二部分第3步运行XFace工程。如果想要自己搭建开发环境，请从第一部分开始做起。

##### 第一部分 搭建环境

***[注：以下所有下载的sdk都保存在虚拟机的`/home/xface/tools`目录下，也可以到百度网盘下载，地址是[http://pan.baidu.com/s/1mg2Wdx2](http://pan.baidu.com/s/1mg2Wdx2)，不同版本的配置方式可能有些变化，如果不是很清楚版本问题的话，推荐使用虚拟机中使用的版本]***

![img](/images/tools.png)

1.配置Java环境

①下载[Oracle JDK](http://www.oracle.com/technetwork/java/javase/downloads/index.html)，虚拟机中下载的版本是JDK1.7.0_40
②下载之后解压即可，解压路径为`/home/xface/android/jdk1.7.0`
③打开终端，输入`sudo gedit /etc/profile`，在文件末尾添加下面内容

```java
JAVA_HOME=/home/xface/android/jdk1.7.0
export PATH=$JAVA_HOME/bin:$PATH
```

如下图所示，后面环境配置中添加内容也是如此

![img](/images/etcprofile.png)

④重启虚拟机，打开终端输入`java -version`进行测试（重启虚拟机也可以等待下面的Android SDK和Android NDK环境都配置好了之后再重启也行）

![img](/images/javaversion.png)


2.配置Android SDK环境

①下载[Android Developer Tools](https://developer.android.com/sdk/index.html)，虚拟机中下载的是20130729版本
②下载之后解压即可，解压路径为`/home/xface/android/adt-bundle`
③打开终端，输入`sudo gedit /etc/profile`，在文件末尾添加下面内容

```
ANDROID_SDK_ROOT=/home/xface/android/adt-bundle/sdk
export PATH=${PATH}:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools
```
④因为Android SDK是32位的，而虚拟机中Ubuntu系统是64位的，所以需要添加ia32-libs库，在终端中执行下面命令（需要耗费漫长的时间等待）

```
sudo apt-get update
sudo apt-get install ia32-libs
```

⑤重启虚拟机，打开终端输入`adb version`进行测试

![img](/images/adbversion.png)


3.配置Android NDK环境

①下载[Android NDK](https://developer.android.com/tools/sdk/ndk/index.html)，虚拟机中下载的是r9c版本
②下载之后解压即可，解压路径为`/home/xface/android/adt-bundle/ndk`
③打开终端，输入`sudo gedit /etc/profile`，在文件末尾添加下面内容

```
ANDROID_NDK_ROOT=/home/xface/android/adt-bundle/ndk
export PATH=${PATH}:${ANDROID_NDK_ROOT}
```
④重启虚拟机，打开终端输入`ndk-build -v`进行测试

![img](/images/ndkversion.png)


4.配置OpenCV环境

①下载[OpenCV for Android](http://sourceforge.net/projects/opencvlibrary/files/opencv-android/)，虚拟机中使用的是2.4.4版本
②下载之后解压即可，解压路径为`/home/xface/android/opencv_sdk`

5.配置ADT开发环境

①运行`/home/xface/android/adt-bundle/eclipse`目录中的eclipse程序，设置默认的工作空间的路径，虚拟机中设置的路径为`/home/xface/android/workspace`
②打开`window->preferences`，查看Android SDK和NDK的配置，如果路径有问题则需要修改过来

Android SDK路径的设置

![img](/images/androidsdk.png)

Android NDK路径的设置

![img](/images/androidndk.png)

③打开`window->preferences`，找到左侧的`C/C++ Build->Environment`添加下面两个环境变量：

```
NDKROOT=/home/xface/android/adt-bundle/ndk
OPENCVROOT=/home/xface/android/opencv_sdk
```

![img](/images/environment.png)

④按如下步骤配置**万能的javah工具**的方法（这里javah工具的用途是根据Java类生成C++头文件）

(1)在菜单`Run`->`External Tools`->`External Tools Configurations`中新建`Program`，命名为`javah`
(2)`Location`设置为`/usr/bin/javah` [如果javah命令不是在这个位置，可以试试`${system_path:javah}`]
(3)`Working Directory`设置为`${project_loc}/bin/classes` [适用于Android项目开发]
(4)`Arguments`设置为`-jni -verbose -d "${project_loc}${system_property:file.separator}jni" ${java_type_name}`
(5)OK，以后只要选中要进行"反编译"的Java Class，然后运行这个External Tool就可以了！

![img](/images/javah.png)


⑤为了提高编写代码的速度，打开`window->preferences`，找到左侧`Java->Editor->Content Assist`，在`Auto activation triggers for Java`中添加26个英文字母，这样，在编写Java代码时任何一个字母被按下的话都会出现智能代码提示。

![img](/images/codeassist.png)

⑥为了验证环境没有问题，可以尝试新建一个Android Project并运行于移动设备上，虚拟机中eclipse下的项目xfacetest便是用来测试环境是否配置成功的默认Android应用程序，可以尝试插上手机，选中项目xfacetest点击右键，选择`Run As` -> `Android Application`，如果都没问题了，说明开发环境搭建成功了。

##### 第二部分 运行XFace

***[注：实验使用的XFace项目源代码是稍微精简的版本，可以到百度网盘下载，地址是[http://pan.baidu.com/s/1mg2Wdx2](http://pan.baidu.com/s/1mg2Wdx2)，下载之后解压即可，原始的XFace项目托管于Github，地址是[http://github.com/hujiaweibujidao/XFace.git](http://github.com/hujiaweibujidao/XFace.git)]***

XFace是一个小型的人脸识别程序，主要功能就是注册和识别人脸，界面分为3个，首先是主界面，使用者选择要进行的操作，sign up是注册，输入用户名然后保存头像即可；sign in是登录，其实就是人脸识别的过程。

![img](/images/xface.png)

XFace的源码保存在虚拟机中`/home/xface/android/xface`目录下，包括两个项目，一个是`OpenCV Library - 2.4.4`，这是XFace所需的OpenCV库项目，另一个是`XFace`，这个XFace核心的Android应用程序。下面介绍如何将这两个项目导入到Eclipse开发环境中，并在手机上运行。

1.运行Eclipse，选择`File->Import...`，在导入窗口中，选择`General`下面的`Existing Projects into Workspace`，然后点击`Next->`，在之后的窗口中，点击`Browser...`，选中`/home/xface/android/xface/`下的`OpenCV Library - 2.4.4`文件夹，建议勾选`Copy projects into workspace`（可以防止意外操作导致项目出现问题无法修复时可以删除该项目重新将其导入进来），点击`Finish`即可，如下图所示：

![img](/images/import.png)

2.按照步骤1中的导入操作导入`/home/xface/android/xface/`下的`XFace`项目，导入之后，如果报出问题，可以尝试以下步骤：选中项目`XFace`，点击右键，选择`Properties`，在属性配置窗口中，选择左侧的`Android`项，查看下面的`Library`的配置，如果有错误，则选中错误的项，点击`Remove`；如果内容为空则点击`Add...`，在弹出的窗口中选中步骤1中添加的`OpenCV Library - 2.4.4`项目即可，效果如下图所示：

![img](/images/library.png)

3.至此，开发环境搭建和项目导入部分都完成了，下面可以进行XFace程序了。首先插入设备（手机），如果是在虚拟机中运行，要确保手机是和虚拟机连接的，而不是和主机连接的（可以通过虚拟机右下角状态栏中`USB设备按钮`或者菜单`虚拟机`中的`USB和Bluetooth`进行设置）；然后，选中`XFace`项目，点击右键，选择`Run As -> Android Application`，然后选中插入的手机，点击`OK`即可。有些情况下可能在列表中没有出现设备，可以尝试以下步骤：首先要确保手机开启了USB调试功能(一般是`设置`->`开发人员选项`->选中`USB调试`)；其次可以尝试重新插入手机或者重启Eclipse；若还是不行尝试在终端输入`adb kill-server`和`adb devices`命令；若还是不行的话尝试重启电脑。实在是不行的话，将编译好的apk文件（保存在项目的`bin`目录下）拷贝到手机中直接运行。

##### 第三部分 XFace分析

1.项目结构和主要文件功能大致介绍

![img](/images/xfacecode.png)

2.关键部分介绍

(1)`jni`下的`edu_thu_xface_libs_XFaceLibrary.h`文件是由Java类`XFaceLibrary.java`通过javah工具生成的（现在要想重新生成需要将非native方法注释起来），Java类只是定义了三个重要的`native`方法，实际调用的是实现了头文件`edu_thu_xface_libs_XFaceLibrary.h`的另一个C++文件`xface.cpp`。

三个`native`方法如下：

```c++
	public static native long nativeInitFacerec(String datapath, String modelpath, int component, double threshold,
			int facerec);
	public static native int nativeFacerec(long xfacerec, String modelpath, long addr, int width, int height);
	public static native int nativeDestoryFacerec(long xfacerec);
```

对应得到的头文件中的三个方法（注意：这里方法的名称和参数类型都是严格遵守JNI规范的，不能随便修改）

```c++
/*
 * Class:     edu_thu_xface_libs_XFaceLibrary
 * Method:    nativeInitFacerec
 * Signature: (Ljava/lang/String;Ljava/lang/String;IDI)J
 */
JNIEXPORT jlong JNICALL Java_edu_thu_xface_libs_XFaceLibrary_nativeInitFacerec
  (JNIEnv *, jclass, jstring, jstring, jint, jdouble, jint);
/*
 * Class:     edu_thu_xface_libs_XFaceLibrary
 * Method:    nativeFacerec
 * Signature: (JLjava/lang/String;JII)I
 */
JNIEXPORT jint JNICALL Java_edu_thu_xface_libs_XFaceLibrary_nativeFacerec
  (JNIEnv *, jclass, jlong, jstring, jlong, jint, jint);
/*
 * Class:     edu_thu_xface_libs_XFaceLibrary
 * Method:    nativeDestoryFacerec
 * Signature: (J)I
 */
JNIEXPORT jint JNICALL Java_edu_thu_xface_libs_XFaceLibrary_nativeDestoryFacerec
  (JNIEnv *, jclass, jlong);
```

第一个方法是初始化人脸识别模块，参数分别是：datapath是已有的人脸数据保存的文件路径；modelpath是已生成的人脸识别模块保存的文件路径；component是人脸识别算法中使用的一个参数，表示主成分数；threshold也是人脸识别算法中使用的一个参数，表示阈值。后面两个参数目前都是使用默认值，分别是10和0.0。

第二个方法是人脸识别算法，参数分别是：xfacerec人脸识别算法模块对象的内存地址，之前的尝试，目前没有用了，可以忽视；modelpath是创建的人脸识别模块数据的文件保存的路径；addr是当前摄像头得到的一帧图片的灰度图像的内存地址；width和height分别是要进行识别的人脸图片压缩之后的大小，目前是240*360。

第三个方法是销毁人脸识别对象的方法，主要用于释放JNI层中开辟的内存空间。

(2)分析`FacerecCameraActivity`类

①人脸检测模块

这部分最重要的是`private CascadeClassifier mJavaDetector;`字段，它的初始化过程在方法`onCreate(Bundle savedInstanceState)`中，这里使用了重要的`lbpcascade_frontalface.yml`文件，该文件原本存放在`res/raw`目录下，初始化过程中将其拷贝到了SD卡中，并使用这个文件创建了`CascadeClassifier`。代码片段：

```java
try {
	// File cascadeDir = getDir("cascade", Context.MODE_PRIVATE);
	mCascadeFile = new File(CommonUtil.LBPCASCADE_FILEPATH);
	if (!mCascadeFile.exists()) {// if file not exist, load from raw, otherwise, just use it!
		// load cascade file from application resources
		InputStream is = getResources().openRawResource(R.raw.lbpcascade_frontalface);
		// mCascadeFile = new File(cascadeDir, "lbpcascade_frontalface.xml");
		FileOutputStream os = new FileOutputStream(mCascadeFile);
		byte[] buffer = new byte[4096];
		int bytesRead;
		while ((bytesRead = is.read(buffer)) != -1) {
			os.write(buffer, 0, bytesRead);
		}
		is.close();
		os.close();
	}
	mJavaDetector = new CascadeClassifier(mCascadeFile.getAbsolutePath());
	if (mJavaDetector.empty()) {
		Log.e(TAG, "Failed to load cascade classifier");
		mJavaDetector = null;
	} else
		Log.i(TAG, "Loaded cascade classifier from " + mCascadeFile.getAbsolutePath());
	// mNativeDetector = new DetectionBasedTracker(mCascadeFile.getAbsolutePath(), 0);// hujiawei
	// cascadeDir.delete();//
} catch (IOException e) {
	e.printStackTrace();
	Log.e(TAG, "Failed to load cascade. Exception thrown: " + e);
}
```

最后在摄像头的回调方法`onCameraFrame(CvCameraViewFrame inputFrame)`中对摄像头得到的图片帧进行人脸检测，将检测出来的人脸方框直接绘制在图片帧上立刻显示出来（该方法会在每次摄像头有新的一帧）。代码片段如下，其中mRgba是每次得到的图片的RGBA格式，mGray是每次得到的图片的灰度格式

```java
public Mat onCameraFrame(CvCameraViewFrame inputFrame) {
	// Log.i(TAG, inputFrame.gray().width() + "" + inputFrame.gray().height());
	// landscape 640*480 || portrait [320*240]-> 240*320!
	// when portrait mode, inputframe is 320*240, so pic is rotated!
	mRgba = inputFrame.rgba();
	mGray = inputFrame.gray();
	Core.flip(mRgba.t(), mRgba, 0);//counter-clock wise 90
	Core.flip(mGray.t(), mGray, 0);
	if (mAbsoluteFaceSize == 0) {
		int height = mGray.rows();
		if (Math.round(height * mRelativeFaceSize) > 0) {
			mAbsoluteFaceSize = Math.round(height * mRelativeFaceSize);
		}
		// mNativeDetector.setMinFaceSize(mAbsoluteFaceSize);//
	}
	MatOfRect faces = new MatOfRect();
	if (mJavaDetector != null) {// use only java detector
		mJavaDetector.detectMultiScale(mGray, faces, 1.1, 2, 2, // TODO: objdetect.CV_HAAR_SCALE_IMAGE
				new Size(mAbsoluteFaceSize, mAbsoluteFaceSize), new Size());
	}
	Rect[] facesArray = faces.toArray();
	for (int i = 0; i < facesArray.length; i++) {
		Core.rectangle(mRgba, facesArray[i].tl(), facesArray[i].br(), FACE_RECT_COLOR, 3);
	}
	Core.flip(mRgba.t(), mRgba, 1);//counter-clock wise 90
	Core.flip(mGray.t(), mGray, 1);
	return mRgba;
}
```

②人脸识别模块

因为人脸识别过程需要耗费一定的时间，如果每次图片帧传入的时候便进行处理，处理完了之后再显示的话会导致界面卡死，所以人脸识别过程是在另开辟的一个线程中执行的，线程代码如下，只要摄像头还在工作，也就是还会传回图像的话，那么这个线程便会取出其灰度图像传入到JNI层进行人脸识别操作，并将结果显示出来，此处消息的传递方式使用的是Android中的Handler机制。

```java
new Thread(new Runnable() {
	public void run() {
		Log.i(TAG, "bInitFacerec= " + bInitFacerec + " $$ bExitRecognition= " + bExitRecognition
				+ " $$ frameprocessing=" + bFrameProcessing);
		if (!bInitFacerec) {// facerec init?
			long result = XFaceLibrary.initFacerec();// it will take a lot of time!
			Message message = new Message();
			message.arg1 = (int) result;// 1/-1/-2
			message.arg2 = 0;
			handler.sendMessage(message);
			bInitFacerec = true;// no longer init!
		}
		while (!bExitRecognition) {// is recognition exits?
			if (!bFrameProcessing) {// is frame being processing?
				if (null == mGray || mGray.empty()) {//it's hard to say when it is called!
					Log.i(TAG, "gray mat is null");
					// return;// return when no data//can not return
				} else {
					bFrameProcessing = true;
					Log.i(TAG, "runFacerec! addr = " + mGray.getNativeObjAddr());// 2103032
					// Log.i(TAG, "data addr=" + mGray.dataAddr() + " $$ native addr=" +
					// mGray.getNativeObjAddr()
					// + " $$ native object=" + mGray.nativeObj);// $1 not equal $2,but $2=$3
					int result = XFaceLibrary.facerec(mGray);
					Message message = new Message();
					message.arg1 = result;
					message.arg2 = 1;
					handler.sendMessage(message);
					bFrameProcessing = false;
				}
			}
			try {
				Thread.currentThread().sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
	}
}).start();
```

3.XFace应用程序在手机SD卡中的相关文件

XFace应用程序的使用过程中会产生一些文件夹和文件，全部存放在SD卡的`xface`文件夹下。这部分内容可以参看文件`CommonUtil.java`文件，在包`edu.thu.xface.util`下。

`camera`文件夹存放摄像头拍照得到的头像；
`user`文件夹存放灰度化和压缩处理之后的头像；
`demo`文件夹存放测试或者示例程序的数据，目前为空；
`facedata.txt`文件存放人脸图片路径和人物的对应关系，文件中`图片路径;数字`表示该数字编号的人物的头像图片所在的路径；
`users.properties`文件用来保存用户的配置和注册用户的信息，文件中`total`代表总共注册的人数；后面的`数字=用户名`表示人物编号与人物名称的对应关系，`1=hujiawei`表示1号人物代表用户`hujiawei`，再根据`facedata.txt`文件中的内容便可以知道`hujiawei`用户头像图片存储的路径；最后的`facerecognizer=?`保存当前使用的人脸识别算法，例如`facerecognizer=eigenface`表示使用的是特征脸算法，XFace虽然内置了OpenCV中的三种人脸识别算法，但是目前只有`eigenface`和`fisherface`两种算法可行，第三种`lbphface`算法暂时不可行。
`facerec.yml`文件是OpenCV中人脸识别算法用来保存创建的识别模块数据的文件；
`lbpcascade_frontalface.yml`文件是OpenCV中进行人脸检测所需要的数据文件；


##### 第四部分 其他参考内容

其他的参考内容：

①[关于Android开发的书籍和资料](/blog/2013/12/14/yi-dong-kai-fa-zi-liao-hui-ji/)
文章最后附有两份Android开发入门课程PPT，以及一个Android小程序魔力8号球，百度网盘同样可以下载

②[关于在Ubuntu12.04下搭建android开发环境的教程](http://bujingyun23.blog.163.com/blog/static/181310243201210293950303/?suggestedreading&wumii)

③[关于在windows平台搭建android开发环境的教程](http://hujiaweiyinger.diandian.com/post/2013-10-30/setup_android_ndk_environment_and_solve_some_problems)
不推荐使用Windows进行开发，因为不仅要安装Cygwin，还要进行很多其他的配置，如果实在是不得已，可以尝试参考[这位博主的环境搭建过程](http://blog.csdn.net/pwh0996/article/details/8957764)

④[关于android ndk和opencv整合开发以及实例项目运行的教程](/blog/2013/11/18/android-ndk-and-opencv-developement/)
介绍Android NDK和OpenCV整合开发的环境搭建过程和实例项目测试，重点可以参考的是其中的人脸检测和眼镜检测的两个项目，XFace中的人脸检测便来源于此。

⑤[关于android ndk开发中的各种细节和问题的总结](/blog/2013/11/18/android-ndk-and-opencv-development-2/)
理解javah工具和Android.mk以及Application.mk文件的配置，如果是在Windows平台搭建环境的话，需要查看这部分关于`C/C++ Genernal -> Paths and Symbols`的配置

⑥[关于OpenCV中的人脸识别算法 - OpenCV FaceRecognizer documentation](http://bytefish.de/blog/opencv_facerecognizer_documentation/)
该博客作者是OpenCV2.4之后内置的人脸识别模块的原作者，他在他的博客中详细介绍了FaceRecognizer的API以及他使用的人脸识别算法，算法讲解部分可以参考[Face Recognition with Python/GNU Octave/Matlab](http://bytefish.de/blog/face_recognition_with_opencv2/)。
