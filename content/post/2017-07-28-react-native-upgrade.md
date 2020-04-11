---
date: 2017-07-28T10:46:33+08:00
title: React Native Upgrade
tags: ["dev"]
---
本文主要分享Android和iOS端升级RN到0.44.0版本的经验。<!--more-->

**文中的代码和图片我都反复检查过了，基本上没有泄露公司的重要信息的数据，如若发现有泄露的话请立即告知我 ;-)**

今天收到一封不知来自哪个国家的友人的感谢邮件，说是我之前的一篇文章帮助到了他，这才看了看自己的博客，发现我真的有很久没分享东西了。毕业一年有余，换了一次工作，一直忙忙碌碌，日子很充实，收获很多，其实真的很想都分享出来，但是周末却总是变得懒散不想动，慢慢地就积压了很多想分享的内容。这次终于战胜自己，重新开始分享，希望能够坚持下去。

首先，我要告诉大家一件事情，我正式开始做iOS啦，撒花~ 现在产品迭代中交给我的需求如果工作量不是很大的话，那么Android和iOS端就都交给我一个人搞啦，真好。

其次，我开始正式接触React Native啦，撒花again~ RN在我们的产品中也是比较重要的模块，首页以及多个二级界面都是RN完成的，体验还好，但是带来的crash也不少！

考虑到我们的RN版本有点老，问题较多，所以最近对RN进行一次升级，升级到0.44.0版本，并对Android和iOS的RN模块进行代码改造。期间我主要是完成Android和iOS端RN模块代码的改造工作，另一位前端同学配合一起解决升级过程出现的问题。

作为一个接到RN升级任务的RN小白，下面我就大致介绍下自己完成这个任务时遇到的坑，希望能有所帮助。  

#### **1.替换RN新版本的依赖库，同时更新相关配置**  

我们的项目不是直接基于RN开始的，而是已有的项目集成RN。此外，RN集成的方式也不是源码集成，而是使用RN源码编译生成的静态库。

(1)对于Android来说，项目中依赖的是RN源码下ReactAndroid项目构建得到的aar文件(你还可以继续精简成一个jar文件)。

**如何生成这个aar文件呢？**

按照[官网教程](http://facebook.github.io/react-native/docs/tutorial.html)下载RN源码并配置好RN环境之后，在源码根目录下新建`gradle.properties`文件(用来配置gradle的代理)和`local.properties`文件(用来指定`sdk.dir`和`ndk.dir`)，执行`./gradlew :ReactAndroid:installArchives`即可看到源码下多了一个android目录，其中就放着我们需要的aar文件。默认的名称是`1000.0.0-master`，如果你想修改生成的aar的名称，可以通过修改`ReactAndroid/gradle.properties`文件中的`VERSION_NAME`来实现。

**tips**：  
1.编译RN源码的时候需要配置NDK，版本必须是`r10e`，不能是更高版本，[点击进入下载地址](https://developer.android.google.cn/ndk/downloads/older_releases.html)。

2.更新RN的aar文件之后，除了需要修改部分API的调用方式之外，还要修改gradle脚本中依赖库的版本号以及混淆规则！


```
//libraries for RN 0.44.0
compile 'javax.inject:javax.inject:1'
compile 'com.facebook.fbui.textlayoutbuilder:textlayoutbuilder:1.0.0'
compile 'com.facebook.fresco:fresco:1.0.1'
compile 'com.facebook.fresco:imagepipeline-okhttp3:1.0.1'
compile 'com.facebook.soloader:soloader:0.1.0'
compile 'com.google.code.findbugs:jsr305:3.0.0'
compile 'com.squareup.okhttp3:okhttp:3.4.1'
compile 'com.squareup.okhttp3:okhttp-urlconnection:3.4.1'
compile 'com.squareup.okhttp3:okhttp-ws:3.4.1'
compile 'com.squareup.okio:okio:1.9.0'
compile 'org.webkit:android-jsc:r174650'

//import RN aar
compile(name: 'react-native-0.44.0', ext: 'aar')
```

混淆规则 (注意最后一句，不加会产生问题，不过我觉得这可能不是解决问题最好的方式)

混淆内容较多，请看这个[gist](https://gist.github.com/hujiaweibujidao/26229de59e143c4f802cdfba95f286a1)

3.默认情况下，以上编译操作生成的aar文件中只包含`armeabi-v7a`和`x86`两种ABI下的so文件，如果运行时提示找不到so文件，那么可能就是你的`abiFilter`配置错了。但是如果你的应用的`abiFilter`只能配置为`armeabi`的话，可以考虑下面的做法：先解压aar文件，在jni目录下新建`armeabi`文件 夹，并将`armeabi-v7a`下面的so复制到`armeabi`中，然后删除`x86`和`armeabi-v7a`目录，最后重新压缩生成aar文件。

![img](/images/rn_android_aar.png)

(2)对于iOS来说，项目中依赖的是11个RN Xcode子项目生成的静态库(.a)文件。

**如何生成RN静态库呢？**

这里可以通过`react-native init`命令创建一个新的RN demo项目，然后修改`package.json`文件，将RN版本调整为`0.44.0`版本，然后执行`npm install`，最后打开ios目录下的Xcode项目即可。

**tips**：  
1.RN升级到0.44.0版本之后，Deployment Target要设置为`8.0`以上 (实际上从0.36版本的RN就需要做这个配置了)。

2.项目中除了要引入11个静态库文件，还需要引入RN相关的头文件，这些头文件可以在上面的demo项目的构建结果中找到，一般路径为`/Users/[user]/Library/Developer/Xcode/DerivedData/[demo-project]/Build/Products/[Release-xxx]/include`，引入之后别忘了添加到`Header Search Path`中。

3.一定要以`release`模式构建demo应用，否则生成静态库中RN环境实际上是dev环境，在手机摇晃的情况下会弹出RN的调试菜单！出现异常时还会显示RN的红屏界面！

4.生成静态库的时候要根据项目的配置来确定支持的平台，例如有可能项目需要的是同时支持armv7, arm64, i386, x86_64平台的静态库，那么这个时候就需要使用`lipo`命令，其中`lipo -info`命令可以查看一个静态库支持的平台，`lipo -create`命令可以将支持不同平台的静态库合并。

![img](/images/rn_ios_staticlibs.png)

5.如果项目依赖高版本的RN静态库，可以正常加载低版本的RN打出来的bundle文件；反之，如果项目依赖的是低版本的RN静态库，那么加载高版本的RN打出来的bundle文件的时候会报错`DeviceInfo native module is not installed correctly`。

6.iOS端RN升级之后出现过cookie失效的问题，这个问题修改下JS端的代码，在请求的时候添加`credentials`。


#### **2.关键路径日志补全，将RN源码内部重要日志定向到应用日志中**

在应用输出的日志中补全关键路径的信息，例如bundle加载时使用的bundle文件位置、版本，bundle更新重载时使用的bundle文件位置、版本等。这里还做了个功能是将RN源码内部的重要日志定向到应用日志中，这样的话可以丰富应用日志的内容，方便在遇到问题的时候定位问题。

(1)对于Android来说，日志重定向功能是依靠`FLog`的`setLoggingDelegate`方法来实现的，只要实现自定义的`LoggingDelegate`就可以将RN源码端的日志定向到应用日志中

![img](/images/rn_android_log.png)

(2)对于iOS来说，日志重定向功能是依靠`RCTAddLogFunction`方法来实现的

![img](/images/rn_ios_log.png)

#### **3.重点流程耗时统计，关键事件数据上报**

RN模块很容易出现问题，所以对它的重点流程的数据统计和上报也是非常重要的。例如bundle加载耗时多少，RN环境初始化耗时多少，bundle加载失败了多少次等等，这些数据都需要进行上报，以便后期提供更好的容错机制。

一般来说，大家都想知道的是bundle加载耗时多少、RN环境初始化耗时多少、RN界面渲染耗时多少这三个数据。

(1)对于Android来说，在RN的Android端源码中，`ReactMarker`会在很多重要事件的起始和结束设置标志，而`ReactMarkerListener`可以监听这些重要事件，所以如果我们设置了ReactMarkerListener的话，就能够在事件发生的时候收到回调从而统计耗时。

![img](/images/rn_android_time.png)

(2)对于iOS来说，在RN的iOS端源码中，`RCTBridge`的`PerformanceLogger`会在重要事件的起始和结束时设置tag并统计耗时，通过它可以直接取出各项事件的耗时数据。

![img](/images/rn_ios_time.png)

#### **4.完善bundle的更新时机，实现bundle立即生效方案**

一般来说，为了方便和稳定，应用一般是在当次运行过程中下载好更新的bundle，但是在下次启动的时候才让新bundle生效。那如果想要实现在应用不重启的情况下让bundle当次立即生效怎么办呢？(**需要注意的是，往往重新加载bundle文件的时候bundle文件位置可能不是原来那个位置**)

(1)对于iOS来说，在RN的iOS端源码中`RCTBridge`提供了`reload`方法来重新加载bundle文件，还提供了`setBundleURL`方法来设置bundle文件的位置，所以iOS端RN离线包立即生效方案就是先设置新的bundle文件位置，然后再调用`reload`方法进行重载即可，不需要修改RN源码再重新编译。

![img](/images/rn_ios_reload.png)

(2)对于Android来说，RN的Android端源码并没有提供修改bundle文件位置的方法，所以这里修改了RN源码中的`ReactInstanceManager`类，删掉`mBundleLoader`变量的`final`修饰符，并为其提供set方法。和iOS端类似，RN离线包立即生效就是先根据新的bundle文件的位置设置ReactInstanceManager的`JSBundlerLoader`，然后调用`recreateReactContextInBackground`方法即可。

![img](/images/rn_android_reload.png)

**tips**:  
1.无论是Android端还是iOS端，bundle重载时最好要检查下当前屏幕是竖屏还是横屏，因为bundle重载的时候会重新加载和渲染之前已经attached的RN View(假设是按照竖屏来布局的)，如果bundle重载时手机是横屏，那么这个RN View会按照横屏进行布局，这样回来的时候界面就会显示异常了。

2.最好不要在应用当前处于RN界面的时候进行bundle重新加载，因为可能造成不可预计的数据异常或者界面显示异常，我们出现过一种数据异常导致应用crash的情况。

3.Android端的立即生效方案也许不是best practice，或许可以不修改源码就能够重新设置bundle位置，但是我目前没有细究，所以用了上面的方案。

4.不是所有应用都需要bundle立即生效的策略，如果没有必要这么做的话就尽量不要做，以免带来更多的问题。此外，如果你发现这个策略加上之后出现了很多新的RN相关的crash的话，那建议还是不要这么做的好，毕竟稳定性更加重要。

#### **5.Bundle文件加载容错机制**

默认情况下我们发出去的app中自带一个稳定版本的bundle，在其他bundle加载失败的情况下，就使用app自带的bundle文件进行容错。目前Android端还没有做这个功能，iOS因为可以接收到bundle加载失败的通知所以实现了这个功能。

![img](/images/rn_ios_bundle_fail.png)

除了bundle文件加载容错机制外，一般还要在RN界面出现crash的时候降级到H5的容灾方案，这块目前还在计划开发中。因为要做到完整的容灾的话，可能需要能够拦截到RN模块大部分的异常，虽然RN源码提供了拦截方法，但是这只是其中的部分异常，还有不少异常情况并没有被拦截到。

#### **6.给iOS端的RN开发阶段新增调试功能**

众所周知，Android的RN调试菜单中可以指定server和port，这样就可以从network上加载指定的bundle文件，但是iOS的RN调试菜单中却没有这个功能，所以我实现了一个简易的针对iOS端开发阶段加载指定server上的bundle文件的调试功能，原理是利用`RCTBundleURLProvider`的`jsBundleURLForBundleRoot:packagerHost:enableDev:enableMinification`方法。

![img](/images/rn_ios_debug.png)

OK，可能花了一晚上只是写了一堆废话吧，谢谢你看完，如果内容有什么错误或者想咨询的可以通过邮件联系我，因为多说关闭了，本想着什么时候换成网易云跟帖，结果前段时间听说也要关闭了，所以我想算了吧，不想再去接入其他的评论系统了。

很明显，本文并没有提到RN专题中常见的性能优化和组件定制，这块我的经验尚浅，待有朝一日熟悉了再来说吧，晚安。
