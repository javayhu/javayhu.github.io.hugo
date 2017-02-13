---
date: 2017-01-24T10:46:33+08:00
title: How to know your application’s battery stats
tags: ["android"]
---
本文简单总结下关于Android应用的耗电量的统计分析方法和工具。<!--more-->

众所周知，Android系统内置了应用的耗电量统计分析功能，但是并没有提供相应的API和文档，只是可以查看耗电量排行榜前10的应用的耗电百分比。此外，随着Android系统版本的迭代，各个版本耗电量统计的方式略有不同，但庆幸的是其统计模型并没有什么大变化。本文在前人的研究基础上总结Android平台的耗电量统计相关的计算方法和辅助工具。

**(1)Android系统是如何进行应用的耗电量统计的？**

如果想了解Android系统是如何对应用进行耗电量统计计算的话建议先阅读：[Android耗电统计算法](http://gityuan.com/2016/01/10/power_rank/)这篇文章，**作者是小米的MIUI系统工程师Gityuan(如果你想了解Android系统中常见模块的实现细节的话，非常推荐阅读这位开发者的博客，他的博客中文章的质量都非常高)**，此文从Android 6.0系统源码的角度详细分析了应用的耗电量的计算方法。阅读上文可知，耗电量计算包括软件耗电量计算和硬件耗电量计算，并且有各自的计算方法。  

下图是软件的耗电量统计项以及它的功耗计算公式：

![img](/images/battery_software.png)

下图是硬件的功耗计算公式：

![img](/images/battery_hardware.png)

其他文章推荐：  
1.[Android性能专项测试之耗电量统计API](http://blog.csdn.net/itfootball/article/details/49155979)  
该文也是以Android 6.0系统源码来分析应用耗电量统计  
2.[深入浅出Android App耗电量统计](http://www.cnblogs.com/hyddd/p/4402621.html)  
该文是耗电量统计方面最早的文章，分析的是Android 4.3系统源码中的应用耗电量统计  
3.[Android应用的耗电量统计](http://blog.csdn.net/tangdl86/article/details/46958175)  
该文是在上面的文章2的基础上做的分析，分析的是Android 5.1系统源码

下面是从源码的分析得出的对于电量统计的通俗介绍：  
耗电量计算的方法很有趣，有点象在超市购物：有一张“价格表”，记录每种硬件1秒钟耗多少电。有一张“购物清单”，记录apk使用了哪几种硬件，每种硬件用了多长时间。假设某个应用累计使用了60秒的cpu，cpu1秒钟耗1mAh，那这个应用就消耗了60mAh的电，实际的算法比这个例子复杂很多。从这里可以看出，Android自带的耗电量统计的准确性，受两个大方面的因素影响：  

一是那张“价格表”，由`PowerProfile`类提供，它用于获取各个组件的电流数值，而`power_profile.xml`是一个可配置的功耗数据文件。手机的硬件是各不相同的，所以每一款手机都会有一张自己的“价格表”。这张表的准确性由手机厂商负责，所以，尽量用大厂的机子，并且只使用该厂商提供的Android系统。  

二是那张“购物清单”，这是Android的`BatteryStatsService`类提供的。上文说到的`BatteryStatsHelper`类使用AIDL调用`BatteryStatsService`类的`getStatisticsStream`方法获取相关数据。

下面是其中几个模块的耗电量计算方式

WIFI模块的耗电量和应用流进流出的流量总量、wifi扫描时间、wifi模块运行时间有关
![img](/images/battery_wifi.png)

Sensor模块的耗电量与sensor的使用时间成正比
![img](/images/battery_sensor.png)

Wakelock的耗电量与wakelock的时间成正比
![img](/images/battery_wakelock.png)

从上面几篇文章中可以看出，**各个Android版本的系统源码中耗电量统计的方式虽略有不同，但是大致的统计模型是不变的，而且统计的方式越来越科学可靠。Google官方对耗电量的统计给出的解释都是不能代表真实数据，只能作为参考值，因为受power_profile.xml的干扰太大，如果手机厂商没有严格设置这个文件，那可想而知出来的值可能是不合理的。**

**(2)普通的应用开发者可以怎么统计应用的耗电量？**

由于权限的限制，普通的应用开发者并不太容易统计应用的耗电量。前面的推荐文章3中也提到过获取应用耗电量的权限控制，内容如下：Android4.4以前的版本，未对耗电量统计的代码做权限限制，只需要使用java反射等手段，就可以调用相关的内部类和隐藏接口。自Android4.4开始，Android严格限制了权限，普通应用即使在AndroidManifest.xml中申明使用`android.permission.BATTERY_STATS`，也获取不到相关的统计数据。

统计应用耗电量的工具：

**1.GT的Powerstat (腾讯开发的应用耗电量统计工具)**  
项目地址：[http://gt.tencent.com/](http://gt.tencent.com/)  
Powerstat的功能很强大，但是要求手机是root过的 (所以有个备用的高配电脑，随时能够编译Android源码，再有个备用安卓机，刷着原生的userdebug/debug版固件，这个世界不要太美好啊)

Powerstat用户手册中有说明：Android 电量测试工具 Powerstat V1.x 版本支持 Android4.1~4.4的系统(4.4及以上系统上需要系统签名，在已获取root权限的情况下，可将apk包置于`/system/priv-app/`目录下，作为系统应用运行)。工具的 V1.x2 版本在V1.x 版本的基础上进行开发，细分耗电项，增加定时自动保存功能，适配Android5.0。同样，在 Android4.4 及以上系统也需要root权限才能安装使用。

Powerstat的应用耗电量计算方法基本上和系统的应用耗电量计算方法是一样的，它是通过各种方式包括反射的方法来获取应用在一段时间内的数据(例如占用的CPU时间、流进流出的数据量等)，然后利用系统的统计类`BatteryStatsHelper`做些修改来计算应用的耗电量。比较有意思的是其中有个用来计算应用的屏幕耗电量的类。为啥屏幕耗电量计算这么麻烦呢？因为在测试的过程中测试应用并非一直在前台，为了计算的应用耗电量准确些，需要将屏幕的总耗电量按照应用在前台的时间进行分配。计算方法就是根据屏幕总耗电量和所有应用的forground cpu time总和来计算每个forground cpu time消耗的电量，并根据每个应用占用的forground cpu time来计算其对应的屏幕耗电量。这个就类似统计一个应用占用的内存时我们常常关注PSS，而不是USS的道理是一样的，共享库占用的内存要均摊到使用了它的每个应用中。

**2.Battery Historian (Google官方出品)**  
项目源码：[https://github.com/google/battery-historian](https://github.com/google/battery-historian)  
Battery Historian是Google提供的针对Android 5.0及以上系统使用的分析电量相关信息的工具。  

Battery Historian is a tool to inspect battery related information and events on an Android device running Android 5.0 Lollipop (API level 21) and later, while the device was not plugged in. It allows application developers to visualize system and application level events on a timeline with panning and zooming functionality, easily see various aggregated statistics since the device was last fully charged, and select an application and inspect the metrics that impact battery specific to the chosen application. It also allows an A/B comparison of two bugreports, highlighting differences in key battery related metrics.

目前BatteryHistorian工具有两个版本：  

**2.1 Battery Historian 1.x**  
第一个版本是python语言写的，只有一个Python脚本文件 historian.py，这个文件可以从第一版本的最后一次提交记录中下载(https://github.com/google/battery-historian/tree/b711e0a8345147f449fd017e21913a8a6b8bd638) ，第一版本的使用步骤如下：

```
$ adb shell dumpsys batterystats > xxx.txt  //得到整个设备的电量消耗信息
$ adb shell dumpsys batterystats > com.package.name > xxx.txt //得到指定app相关的电量消耗信息
```

得到了原始的电量消耗数据之后，我们需要通过 historian.py 脚本把数据信息转换成可读性更好的html文件

```
$ python historian.py xxx.txt > xxx.html
```

打开这个转换过后的html文件，可以看到类似TraceView生成的列表数据，其中的数据信息量很大

旧版本的详细使用流程以及分析过程可以参考[Batterystats & Battery Historian Walkthrough](https://developer.android.com/studio/profile/battery-historian.html) 和 [Battery Historian Charts](https://developer.android.com/studio/profile/battery-historian-charts.html)，其中有些术语可能不太好理解，这里有个简略的[中文的解释版本](http://www.cnblogs.com/sjjg/p/5451519.html)

下图很重要，它对不同类别的电量消耗进行了解释

![img](/images/battery_categories.png)

**2.2 Battery Historian 2.x**  
第二个版本是go语言写的，代码很多，功能也更加完善，但是环境配置也更加复杂！

首先，我们需要将Battery Historian工具在本地跑起来，要跑起来可以选择使用docker，也可以选择编译源码。
(1)如果是使用Mac或Linux平台的话，推荐直接通过docker运行Battery Historian来完成

```
docker -- run -p <port>:9999 gcr.io/android-battery-historian:2.1 --port 9999
```

之后在浏览器中输入 http://localhost:<port> 就可以查看，然后上传bugreport文件进行分析了。

(2)如果是使用Windows平台的话，也可以使用docker，但是机子要在BIOS中开启虚拟化，这里我选择源码编译方式，主要流程有：    
1.首先下载配置Java环境 (要配置PATH)  
2.接着下载配置Git环境 (要配置PATH)  
3.接着下载配置Python 2.7环境 (要配置PATH)  
4.接着下载配置Go环境 (要配置PATH和GOPATH以及GOBIN)  
5.前面的配置其实很快就能完成，接下来就是下载Battery Historian的源码来进行编译了  

```
$ go get -d -u github.com/google/battery-historian/…
```

下载完成之后，代码会下载到配置的GOPATH中，可以去检查下

```
$ cd $GOPATH/src/github.com/google/battery-historian
```

切换到那个目录，然后执行setup.go开始编译源码

```
go run setup.go
```

如果遇到下面的问题的话别担心，按照提示将对应url的文件下载下来放在要求的目录即可

![img](/images/go-compiler-error.png)

上面的步骤都完成之后就可以启动Battery Historian了，默认端口是9999

```
$ go run cmd/battery-historian/battery-historian.go
```

待控制台输出`listening on port:9999`的时候，可以打开浏览器输入 http://localhost:9999 就可以看到

![img](/images/battery-historian-web.png)

其次，这个版本的输入是bugreport文件，根据系统版本不同它的获取方式略有差别：
如果是Android 7.0及以上版本的话可以通过 `adb bugreport bugreport.zip` 来获取bugreport
如果是Android 6.0及以下版本的话可以通过 `adb bugreport > bugreport.txt` 来获取bugreport

获取到bugreport文件之后，我们就可以将其上传到Battery Historian上进行分析，下面是它的输出结果(注意如果是在开发网的话需要开启临时访问外网才行)

![img](/images/battery-historian-chart.png)

在页面的下方我们可以查看这段时间内系统的状态system stats，也可以选择某个应用查看应用的状态app stats

![img](/images/battery-historian-appstats.png)

其中我们可以看到`Device estimated power use`中显示了估算的应用耗电量值为 `0.18%`

Battery Historian还有个比较功能，在首页选择 Switch to Bugreport Comparisor，然后就可以上传两个不同的bugreport文件，submit之后就可以看到它们的对比结果了，这个功能用来分析同一个应用的两个不同版本前后的耗电量非常有用。

![img](/images/battery_historian_compare.png)

需要注意的是，一般开始统计数据之前需要使用下面的命令将以前的累积数据清空

```
adb shell dumpsys batterystats --reset
```

By default, Android does not record timestamps for application-specific userspace wakelock transitions even though aggregate statistics are maintained on a running basis. If you want Historian to display detailed information about each individual wakelock on the timeline, you should enable full wakelock reporting using the following command before starting your experiment:  

```
adb shell dumpsys batterystats --enable full-wake-history
```

关于bugreport相关的知识推荐阅读[Android adb bugreport工具分析和使用](http://blog.csdn.net/createchance/article/details/51954142)这篇文章，作者简单地从源码角度分析了`adb bugreport`命令的运行原理，结论是bugreport其实是启动了dumpstate服务来输出数据，其中数据来源包括：
1.系统属性   
2./proc和/sys节点文件   
3.执行shell命令获得相关输出   
4.logcat输出   
5.Android Framework Services信息基本使用dumpsys命令通过binder调用服务中的dump函数获得信息   

下面是其他的几篇关于battery-historian使用的文章可供参考  
(1)[Android性能专项测试之battery-historian使用](http://blog.csdn.net/itfootball/article/details/44084159)  
(2)[Android性能专项测试之Batterystats](http://blog.csdn.net/itfootball/article/details/49004699)  
(3)[Battery Historian 2.0 for windows环境搭建](http://www.07net01.com/linux/2016/01/1207924.html)  

**3.关于电量方面的Android性能优化**  
电量方面的性能优化可以参考
[性能优化典范中的Android性能优化之电量篇](http://hukai.me/android-performance-battery/)  

(1)为了减少电量的消耗，在蜂窝移动网络下，最好做到批量执行网络请求，尽量避免频繁的间隔网络请求  
(2)使用Job Scheduler，应用需要做的事情就是判断哪些任务是不紧急的，可以交给Job Scheduler来处理，Job Scheduler集中处理收到的任务，选择合适的时间，合适的网络，再一起执行  
