---
date: 2017-09-25T10:46:33+08:00
title: Camera development experience on Android
tags: ["android"]
---
本文主要总结下Android端相机相关开发的经验。<!--more-->

众所周知，Android平台不仅系统碎片化严重，而且不同手机的硬件配置差异导致开发某些模块的时候坑比较多，相机模块就是其中之一。为什么呢？首先，Android系统目前已经提供了两套Camera API，其中Camera 2 API是从Android 5.0(API Level 21)开始提供的。你可能会想了，那岂不是现在市面上很多机型都可以使用Camera 2 API啦？然而并不是，原因就是下面要说的第二点，很多Android手机对Camera 2 API的支持都不到位，即使是很多现在刚发的新机，它们有些依然只支持老的Camera API！这就导致做相机开发的时候不得不根据手机的实际情况切换不同的Camera API。

很显然，自己从零开始构建这么一个Camera模块是比较困难的，这里推荐Google提供的一个非官方库[cameraview](https://github.com/google/cameraview)，CameraView这个项目可以帮助Android开发者快速创建一个可以适配不同Android系统和不同Android设备，并且包含各种基本功能的相机界面，它的使用正如它的说明文档中那样，引入一个自定义的CameraView，其他一切和Camera有关的事情都由它来处理。如果你的需求是相机预览、切换前后摄像头、切换闪光灯、切换预览图片的比例以及拍照等功能的话，那么这款小巧的库是一个不错的选择。

既然已经有cameraview这个轮子了，那这篇文章是不是就完结了？图森破！前面提到过，这个库是非官方库，所以它已经有很长时间没有更新了，issues中堆了很多已知bug竟然没人去解！但是，又能怎样呢？还不是只能原谅它，难不成要自己撸一个？(看完cameraview的代码你就知道撸一个这个库多么不容易，需要很熟悉Camera API和Camera 2 API，而且要适配那么多机型也确实是困难啊，一个版本迭代的时间根本做不完呐)

言归正传，这次自己做相机模块的需求开发之前调研了几个轮子，最终还是决定使用cameraview这个库，因为它比较小巧简洁，没有多余的废代码或者废功能，也方便我自己定制相机界面。Github上还有几个star特别高的Camera模块封装，比如[CameraKit-Android](https://github.com/wonderkiln/CameraKit-Android)，但是个人感觉有点复杂了，连视频录制的功能都有了，可能不适用于小场景下界面和功能上的定制。

本文主要说的是自己在做相机模块需求或者说使用cameraview的过程中遇到了哪些问题以及相应的解决方案，最终我对cameraview进行了一番enhancement，感兴趣可以看下这个库[CameraView](https://github.com/hujiaweibujidao/cameraview)，主要改进的点已经在README文档中说明了，可能最有用的是补齐重要路径的log以及修复几个上线后的crash bug吧。


**1. 简述cameraview组件的设计**

通过阅读cameraview组件的源码可知，内部设计如下图表所示：

![img](/images/cameraview_overview.png)

其中的核心类是自定义的`CameraView`组件，它支持通过xml来设置摄像头、宽高比、闪光灯等属性，相机相关的各项工作实际上是通过`PreviewImpl`和`CameraViewImpl`这两个抽象类来完成的。

`PreviewImpl`是用来实现相机预览的，内部可能是用SurfaceView或者TextureView来实现，所以它的实现子类有两个，`TextureViewPreview`和`SurfaceViewPreview`。因为`TextureView`是从Android 4.0(API level 14)开始才有的(TexturView算是SurfaceView的一个增强版)，所以在Android 4.0之后使用的是`TextureViewPreview`，在Android 4.0之前只能使用`SurfaceViewPreview`。

`CameraViewImpl`是用来实现相机开启、设置相机参数以及实现各种相机功能的核心类，根据API level的不同分为三个实现子类，`Camera1`、`Camera2`和`Camera2Api23`，其中`Camera2`是为Android 5.0(API level 21)及以上系统提供的，`Camera2Api23`继承自`Camera2`，是为Android 6.0(API level 23)及以上系统提供的。

`PreviewImpl`和`CameraViewImpl`的创建代码如下：

![img](/images/cameraview_chooseimpl.png)

搞清楚了前面的图表再去阅读cameraview的源码就清晰很多了，其他的类都是围绕着CameraView而展开的。

`Size`就是描述宽和高，例如800x600、400x300或者640x360等；  
`AspectRatio`就是描述Size的宽高比，例如800x600和400x300这两个Size都是4:3，但是640x360是16:9；  
`SizeMap`就是维护`AspectRatio`到`Size`的映射列表，例如{"4:3": {800x600, 400x300}, "16:9": {640x360}} 这种形式；  
`DisplayOrientationDetector`就是用来监测相机界面屏幕旋转，然后通知相关组件应对屏幕旋转的变化，例如对预览画面进行调整。  


**2. 关于Camera1和Camera2的选择**

下面详细说下Camera1和Camera2的选择问题，它实际上并不是那么简单地根据API level然后选择创建对应的CameraViewImpl的实现子类就可以了。这里还有一个小细节，那就是如果是选择了Camera2，但是在启动相机的时候发现这个手机对Camera2的支持很弱怎么办？从源码来看，这个时候cameraview会自动将它降级为Camera1，然后使用之前设置的相机参数尝试重新启动相机。这种情况在很多手机上都存在，从我手头上测试的机型来看，小米 5/4c、Vivo X7、Meizu MX6/Pro6、Galaxy S4、Huawei H60-L11等机型都是这样子的(后面有表格记录了该数据)。

![img](/images/cameraview_start.png)

看到这段代码的时候我先是一愣，哟嚯，还有这种操作，666，转瞬一想，微微一笑，因为我发现这段代码很明显是可以优化的。首先，PreviewImpl之前是创建好了的，这里切换CameraViewImpl是不需要改变PreviewImpl的，所以这里没有必要重新调用`createPreviewImpl`方法；其次，对于某个手机来说，如果它是Android 5.0以上的系统，但是对Camera 2 API的支持就是很差怎么办？如果按照这段代码的逻辑，将导致这个手机每次启动相机的时候都会先用Camera2试一次，发现不行再用Camera1试一次，很明显这样会减慢相机的启动速度。其实，我们只要记录下这个手机上是否之前使用Camera2启动失败转而使用Camera1启动成功的事件，如果有这个记录的话，那么选择CameraViewImpl的时候就直接使用Camera1，不要再用Camera2了！哈哈，真是机智如我 😎

相应的修改已经体现在我改进之后的[CameraView](https://github.com/hujiaweibujidao/cameraview)库中，大致代码如下：

![img](/images/cameraview_start_enhancement.png)


**3. AspectRatio的选择**

下面看下AspectRatio的选择问题，前面提到AspectRatio实际上就是图像的宽高比，可能是4:3，也可能是16:9，也可能是其他的比例。另外，我们还需要知道相机模块这里有好几个地方需要设置宽高比，这里建议阅读[Android相机开发那些坑](https://zhuanlan.zhihu.com/p/20559606)这篇文章，其中详细解析了下面的三个尺寸之间的关系：

SurfaceView/TextureView尺寸：即自定义相机应用中用于显示相机预览图像的View的尺寸，当它铺满全屏时就是屏幕的大小。这里SurfaceView/TextureView显示的预览图像暂且称作手机预览图像。在CameraView组件的源码中有个属性adjustViewBounds，如果设置为false的话，那么它就会铺满CameraView组件所占的空间，如果设置为true的话，那么会根据AspectRatio的设置按照这个宽高比显示预览图像。

Previewsize：相机硬件提供的预览帧数据尺寸。预览帧数据传递给SurfaceView，实现预览图像的显示。这里预览帧数据对应的预览图像暂且称作相机预览图像。

Picturesize：相机硬件提供的拍摄帧数据尺寸。拍摄帧数据可以生成位图文件，最终保存成.jpg或者.png等格式的图片。这里拍摄帧数据对应的图像称作相机拍摄图像。

为了保证相机模块的显示和工作正常，通常建议上三个尺寸的宽高比是一样的，如果比例不一致的话就可能导致图像变形，而且这个比例最好是4:3或者16:9这样比较普遍支持的比例，否则输出结果千奇百怪，例如华为H60-L11这款手机，它就不支持输出16:9这个比例的图片，但是好在4:3这个比例还是支持的。

在细读了cameraview原始的AspectRatio、Previewsize和Picturesize的尺寸选择的代码之后，我觉得这块的代码不够严谨，例如输出图像的大小默认就是这个比例下能够输出的最大大小。

不过老实说，这块代码的确是不好写，因为不同应用的需求不同，例如我这边产品要求输出图片最好是1920x1080这个大小(16:9)，那么我就会优先选择16:9这个比例，而不是cameraview中默认的4:3这个比例。所以这里我修改了cameraview原始的AspectRatio的选择以及Previewsize和Picturesize的选择的代码，让CameraView优先使用16:9这个比例，不支持的话那就使用4:3这个比例，在支持16:9这个比例的时候优先使用1920x1080这个输出图像大小，如果不支持的话那就尝试其他的大小，在4:3这个比例下的逻辑类似，大致代码如下：(不同应用要根据自己的需求修改哦)

![img](/images/cameraview_aspectratio.png)

![img](/images/cameraview_picturesize.png)

下表是我利用一些测试手机收集得到的数据，从表格数据中不难看出，除了Google的最新亲儿子Pixel之外，其他手机对Camera 2 API的支持都比较弱，导致要切换到Camera1。另外，大部分手机都支持16:9的图像比例，而且大部分手机也都支持输出1920x1080这个大小的图像，但是有些手机不支持从而选择了1280x720这个输出大小，甚至选择了4:3这个比例下的2048x1536这个输出大小。

![img](/images/cameraview_compatlist.png)

[注1：当时收集数据的时候没有去注意Preview Picture Size，所以这一栏基本为空。其中Meizu MX 6为什么是从一个大小变到另一个大小呢？因为当时自己的比例和尺寸选择策略导致预览图像大小是960x540，这个大小导致预览画面非常模糊，后来debug发现了这个问题，于是想办法调整策略使其变成1920x1080，调整后显示就不再模糊啦]

[注2：不过即使是保证了三个尺寸的比例是一致的，在某些手机上还是会出现一些奇怪的现象，比如cameraview的issues列表中的[这个](https://github.com/google/cameraview/issues/153)和[这个](https://github.com/google/cameraview/issues/192)，也就是保存的图片和预览时看到的图片不一样！这个现象我在一台华为荣耀手机上必现，暂时还没有很好的解决方案，好在问题机型并不多，可以延期解决]


**4. 相机拍照**

相机拍照也存在着不少潜在的坑，下面我们来说道说道。下面的代码片段是Camera1这个类中相机拍照的实现，它的大致流程是，在相机开启的情况下，如果相机能自动对焦的话，那么就先调用`autoFocus`方法自动对焦，对焦完成之后就调用`takePictureInternal`方法进行拍照，如果不能自动对焦的话，那么就直接调用`takePictureInternal`方法进行拍照。`takePictureInternal`方法的实现就是先看`isPictureCaptureInProgress`是否是false，如果是的话那么就将其置为true，然后立即调用`takePicture`进行拍照，成功之后再将`isPictureCaptureInProgress`置为false。

![img](/images/cameraview_takepicture.png)

这段代码有什么问题呢？从我这边的测试来看，其中主要存在着下面三个问题：

1.部分手机上`autoFocus`方法调用可能很耗时：我在一台魅族MX6手机上测试发现对焦特别慢，界面表现就是点击了拍照按钮，大概有5-8秒的时间在自动对焦，这是一个非常不好的体验。针对这个问题，我设定了一个最短对焦时间，如果这台手机没能在最短对焦时间之内完成对焦的话，那么就直接调用`takePictureInternal`去进行拍照，也就是可能牺牲拍出来的图片效果以获得更好的拍照体验。

2.`isPictureCaptureInProgress`这个变量的问题：因为debug另一个问题让我发现一个由`isPictureCaptureInProgress`变量带来的新问题，场景是如果用户点击拍照，在拍照结果还没来得及出现之前立即按下Home键退出到桌面，这个时机很难控制，但是还是有办法复现的，一旦复现了，那么`isPictureCaptureInProgress.set(false)`这句是没有被调用的，这将导致之后都没法再调用`takePicture`进行拍照了。这个的解决方案是在`Camera1`的`stop`方法中将`isPictureCaptureInProgress`重置为false。

3.某些手机上调用`autoFocus`方法会crash掉：这个问题是应用灰度之后发现的，也许是自动对焦过程出现了什么问题吧，我这里的处理是暂时将其catch住了，出现异常的话就直接调用`takePictureInternal`方法。在[Android相机开发那些坑](https://zhuanlan.zhihu.com/p/20559606)中也有提到过这个问题，“在拍照按钮事件响应中执行camera.autofocus或camera.takepicture前，一定要检验camera有没有设置预览Surfaceview并开启了相机预览。这里有个方法可以判断预览状态：Camera.setPreviewCallback是预览帧数据的回调函数，它会在SurfaceView收到相机的预览帧数据时被调用，因此在里面可以设置是否允许对焦和拍照的标志位。”

改进之后的takePicture过程代码如下

![img](/images/cameraview_takepicture2.png)


**5. 相机权限**

众所周知，从Android 6.0开始，Android系统引入了动态权限的机制，所以如果你的应用的targetSDK设置在23及以上的话，你需要在运行的时候检查相机权限是否授予了，如果没有授予的话就要申请。对于Android 6.0以下的系统，只要在AndroidManifest.xml文件中声明相机权限就可以了。

这次是真的可以了？你心里肯定知道答案一定是否。国产手机现在定制之后的系统基本上都有了自己的权限管理机制，往往还有个系统应用“安全中心”来帮忙管理权限，所以还要兼容这些不同的权限管理机制。

下面的`checkCameraPermission`方法是用来检查相机权限，并且在权限授予的情况下开启相机的过程，这个方法会在(包含CameraView的)Activity的`onResume`方法中被调用。

![img](/images/cameraview_checkpermission.png)

如果targetSDK设置在23以下的话，那么就只会走第一个`if`这个分支，我们重点说下这个分支的情况，下面的`else`分支的分析可以参考其他文档，例如[Android M 新的运行时权限开发者需要知道的一切](http://www.jianshu.com/p/e1ab1a179fbb)。

在Android 6.0以下系统中，`ContextCompat.checkSelfPermission`这个方法返回的结果一定是true，如果是原生系统的话，那么就是真的已经具有这个权限了。但是在众多的国产系统中，其实并没有，在上面代码执行到`mCameraView.start()`的时候系统会拦截这个操作，然后弹出系统自定义的权限申请对话框，各家还不样，例如小米手机、VIVO手机和华为手机上有个20秒钟的倒计时，魅族手机上没有显示倒计时。

![img](/images/cameraview_permission.png)

如果倒计时结束了还没有点击允许的话那就表示拒绝了，那么打开相机就会失败或者异常。一旦是因为权限没有授予然后启动相机失败了的话，可以考虑弹出一个对话框告知用户，然后让用户跳转到应用对应的权限授予界面去开启权限。具体跳转到哪里可以参考[这份代码](https://github.com/hkq325800/JumpPermissionManagement/blob/master/JumpPermissionManagement.java)，它处理了不同的定制系统跳转到对应权限授予界面的逻辑。

这里需要注意的是，原生系统的设置中都有个“应用“选项，进入之后可以找到对应应用的详情界面，但是只有部分系统支持在这里直接管理这个应用的权限，所以说让用户跳转到这里是不可以的。更值得注意的是，小米系统在这里有个bug，小米系统在这个应用详情中看似支持直接修改权限，但是权限修改之后根本就没有用，只有到系统中的安全中心改权限才有效！


**6. 输出图像**

你以为不同手机的坑就上面这些？NO！三星手机告诉你，你还是太年轻了！某一天，测试同学拿着一台三星手机过来问你，“为什么我是竖着拍照，怎么上传到服务器之后再点开查看的时候图片是横着的呢？”，这个时候你接过手机，打开文件管理找到这张图片的保存路径，然后一看这张图，发现它明明是竖着的，此时你肯定会想这锅一定要甩出去，回道，“这一定是后台开发同学的bug！一定是他旋转了图片！”。结果一问后台同学，他说，“我不会旋转图片的，不是我的锅”，然后没有再回复你了。此时此刻，你才焕然大悟，想到了三星手机那个一直存在的bug，拍照得到的图片会自动旋转90！哎，看来cameraview并没有兼容这种情况啊！

但是，细读下cameraview的代码你会发现，这不算是cameraview的锅，拍照(takePicture)的时候最终会回调`onPictureTaken`方法，其参数是`byte[] data`，一般情况下我们都只是将这个字节数组保存到某个文件中即可得到拍照的图片。但是，我们并没有去检查这个图片的EXIF信息，因为大多数时候其中的degree这个元数据都是0，可是在三星手机上无论你是竖着拍照还是横着拍照，这个值都是90！

这时候你可能会想了，那为什么在文件管理中看到的这张图是竖着的呢？很显然，三星内置的相册(或者文件管理)在显示图片的时候会考虑图片的EXIF信息，实际上这图是横着的，结果显示给你看的时候这图旋转回来了，变成了竖着的。那怎么办呢？难道要针对三星手机在竖屏下拍照做个特殊处理？

我这里的做法是将data数据保存到图片之后，再去读取下它的EXIF信息，如果它的degree不是0，那么就根据degree信息将图片旋转下，然后重新保存下来。(注：这里并没有去修改degree为0)

![img](/images/cameraview_exif.png)

[注：关于三星手机的这个问题可以看下[这个issue](https://github.com/google/cameraview/issues/22)]


**7. 手动对焦**

一开始还不知道，等交互出来的时候才发现，cameraview这个组件缺了手动对焦的功能，但是好在有热心的开发者对cameraview进行了enhancement，使其支持了手动对焦，还给官方的cameraview提了PR，可惜官方没有理人家，所以代码并没有合入到cameraview组件中，但是这个手动对焦的代码基本可用，对应的代码提交记录可以参见[lin18/cameraview的这次提交](https://github.com/lin18/cameraview/commit/47b8a4e493cdb5f1085333577d55b749443047e9)，可能你和我一样，只需要稍微修改下对焦的样式就可以看到效果了。

前面提到过，部分手机上在某些情况下调用`autoFocus`这个自动对焦方法会导致crash，所以为了安全起见，我将引入的手动对焦代码中的`autoFocus`方法的调用都做了保护，其中有一处值得说道下，下面是lin18/cameraview在Camera1中新加的代码，这里出现的crash有好几例。

![img](/images/cameraview_resetfocus.png)

上面代码在部分手机上调用`setParameters`的时候出现了crash，我猜测原因是这个手机可能并不支持`FOCUS_MODE_CONTINUOUS_PICTURE`这种对焦模式吧，lin18之前的代码中设置FocusMode都会先判断这个Camera是否支持，而这次并没有判断，也许正是这个原因导致`setParameters`的时候出现了crash吧。

改进之后的`resetFocus`方法，增加是否支持的判断逻辑和try-catch保护

![img](/images/cameraview_resetfocus2.png)	


OK，以上就是我这次做Android端自定义相机模块需求开发的总结，撒花完结啦，希望能有点作用~~~

**At last，从前面的内容可以看出官方推出的非正式组件cameraview存在着不少的问题，issues中堆积了不少手机兼容性问题和异常crash问题，use it at your own risk。这个库并不适合所有的自定义相机场景的开发，但是如果它能够达到你的基本诉求的话，也是一个不错的库。最后，如果你决定使用cameraview的话，推荐使用我改进过后的[CameraView](https://github.com/hujiaweibujidao/cameraview) 😎**


**补充资料**

1.关于TextureView和SurfaceView的区别：[Android TextureView简易教程](http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2014/1213/2153.html)  
2.关于Android端相机开发的坑：[Android相机开发那些坑](https://zhuanlan.zhihu.com/p/20559606)  
3.关于Camera API的使用的官方文档：[Camera API](https://developer.android.com/guide/topics/media/camera.html)  
4.关于Camera API的使用：[Android Camera 相机开发详解](http://www.jianshu.com/p/7dd2191b4537)  
5.关于运行时权限：[Android M 新的运行时权限开发者需要知道的一切](http://www.jianshu.com/p/e1ab1a179fbb)  

