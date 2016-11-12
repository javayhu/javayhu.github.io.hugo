---
title: Build Android Source Code on Mac
categories: "android"
date: "2016-10-03"
published: true
---
本文记录下搭建Android源码编译环境的流程。 <!--more-->

趁着国庆长假，抽出些时间来记录下最近倒腾的一些内容，第一个需要记录的自然是Android源码编译的流程。上班第一天就干了一件事，编译Android 6.0源码，第二天就是编译Flyme系统啦！但是编完系统之后刷到PRO6里面还有点小鸡冻呢！

**Ubuntu系统下的Android源码编译环境搭建**

如果是在Ubuntu系统下进行编译的话，中文文档请参考[自己动手编译最新Android源码及SDK](http://blog.csdn.net/dd864140130/article/details/51718187)或者Gityuan写的编译最新的7.0源码的文章[搭建Android 7.0的源码环境](http://gityuan.com/2016/08/20/Android_N/)，英文文档主要看Google官方的文档，包括[前提要求篇](https://source.android.com/source/requirements.html)、[环境准备篇](https://source.android.com/source/initializing.html)以及[源码编译篇](https://source.android.com/source/building.html)，如果磁盘空间充足并且网络环境通畅的话，编译通过是没啥问题的。

特别需要注意以下几点：
0.磁盘空间的大小
按照Google官方的说法是，checkout代码至少需要100GB空间，单个编译的话至少需要150GB空间，多类型的编译的话至少需要200GB空间(实际我下载完代码之后大约占用了50GB左右)。而且，如果你是在虚拟机的Linux中编译的话，还需要满足至少有16GB的RAM/swap。

1.Ubuntu系统的版本和JDK的版本
Ubuntu系统推荐使用14.04，而且安装好系统之后如果有提示软件更新，建议更新一下。此外，推荐在设置中设置软件更新的远程服务器，将其设置为China下的aliyun服务器，这样速度会快很多。

JDK版本需要根据你要编译的Android系统版本来确定，而且还需要注意是Oracle JDK还是Open JDK！可以在系统中多安装几个版本的JDK，以后使用`update-alternatives --config`命令来切换。

2.Android源码的分支
详细的分支列表可以在[这里](https://source.android.com/source/build-numbers.html#source-code-tags-and-builds)查看，当然，repo init的时候也可以不指定分支。

**Mac系统下的Android源码编译环境搭建**

关于是否在自己的MBP上搭建android编译环境的问题我纠结了很久，原因是自己的磁盘剩余空间真的不多了，后来在网上找到了Mac笔记本的扩容卡，对于我这款MBP来说最大可以扩容256GB！虽然有点贵，但是，为了Android，豁出去啦！

在Mac系统上进行Android源码编译的话可以参考[Mac下设置Android源代码编译环境](http://www.jianshu.com/p/f0356e3ea330)这篇文章，主要步骤分别是创建大小写敏感的磁盘、安装依赖包、下载Android源码然后编译就行了。

对于第一步，创建磁盘操作我是直接将买来的扩容卡格式化成OS X Extended(Case-sensitive Journaled)格式。

![img](/images/osx_extended.png)

第二步是安装JDK、Xcode、MacPorts，这三个在我当前的系统中都已经有了，检查下版本是否可以就行，之后就是通过MacPorts安装几个依赖包，`POSIXLY_CORRECT=1 sudo port install gmake libsdl git gnupg`。

这一步我遇到了一个坑，简单描述下：我目前的系统一直以来都是通过系统的更新而升级过来的，所以大概有2年左右的时间没有重装了（嗯，我就是在夸Mac系统好☺️），系统环境也慢慢变得相当复杂了。之前用MacPorts，后来用Homebrew，但是大家都知道`brew doctor`的时候总是会提醒MacPorts如何如何的，建议你移动它的位置，后来我貌似是移动了还是怎么的，系统的MacPorts不能正常工作了，利用安装工具反复安装了很多次都卡在了最后的`Running package scripts`这个步骤，翻墙状态下安装也是如此，最后的解决方案是利用MacPorts的源码安装一次就好啦！还有就是，不管你的MacPorts是否正常，建议执行一次`sudo ports -v selfupdate`进行更新升级一次，如果失败可能是网络连接的问题，可以试试MacPorts的其他镜像。

第三步是下载Android源码，大家都知道在国内的话需要找镜像，我选择的是清华大学的[TUNA镜像](https://mirrors.tuna.tsinghua.edu.cn/help/AOSP/)。建议下载它的初始化包，大约20多GB，待解压并且完成repo sync之后建议将这个初始化包保存到移动硬盘中存起来，然后删除本地的初始化包，这样可以省下大量的磁盘空间。

对于Mac系统最后还需要在`~/.bash_profile`中设置`ulimit -S -n 1024`以增加最大文件打开数量。

最后一步是执行编译，lunch时我选择`aosp_arm64_eng`为target，并启动6个线程进行编译`make -j6`。





