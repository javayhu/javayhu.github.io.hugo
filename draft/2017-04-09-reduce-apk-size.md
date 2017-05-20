---
date: 2017-04-09T10:46:33+08:00
title: Reduce your apk's size
tags: ["android"]
---
本文总结下自己的Android APK瘦身实践。<!--more-->

关于APK的瘦身，网上已经有了不少不错的文章，而且还总是有更好更不错的文章出现，下面重点推荐几份资料：  

(1) [Android减包 - 使用APK Analyzer分析你的APK](http://mp.weixin.qq.com/s/jj727RQGmPooKaJwPyVUlA) 和 [Android减包 － 减少APK大小](http://mp.weixin.qq.com/s/ox4WFLMZG63wuoD6_-rCyQ)    
这两篇文章的作者都是damonxia(夏正冬)，腾讯天天P图团队工程师。如果是刚开始计划如何瘦身的话，那么可以先阅读这两篇文章，掌握APK Analyzer工具的使用以及Google官方的瘦身推荐操作。APK Analyzer工具非常有用，利用它既可以从APK的内部结构和大小分布来指导我们的瘦身过程，又可以利用它的比较功能观察我们的每步瘦身操作前后的APK大小变化情况。

(2) [apk瘦身系列](http://blog.chengyunfeng.com/?p=879)  
这位作者是真心赞，写了一个瘦身系列，满满的8篇干货，全面分析了apk瘦身的一些常见操作，非常推荐阅读。

03-11: apk 瘦身系列⑧：Native libraries 优化 (0)  
03-11: apk 瘦身系列⑦：图片优化、Shape 和 VectorDrawables (0)  
03-11: apk 瘦身系列⑥：图片优化、Zopfli & WebP (1)  
03-11: apk 瘦身系列⑤：使用 product flavors 来发布多个 apk (0)  
03-11: apk 瘦身系列④：使用分割ABI 和 屏幕密度的方式来发布多个 apk (0)  
03-10: apk 瘦身系列③：删除没用的资源文件 (1)  
03-10: apk 瘦身系列②：减少代码的尺寸 (1)  
03-09: apk 瘦身系列①：解剖 apk (2)  

(3) 
