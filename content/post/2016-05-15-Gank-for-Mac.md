---
title: Gank for Mac
tags: ["dev"]
date: "2016-05-15"
---
干货集中营的Mac客户端Gank for Mac开发小记。 <!--more-->

临近毕业，花了几天时间看了下Swift的语法，主要看的是资料是 **[The Swift Programming Language](https://github.com/numbbbbb/the-swift-programming-language-in-chinese)**，在此非常感谢国内的翻译团队们的辛苦翻译，翻译质量相当不错。😘

看了一遍之后，感觉Swift的确是吸收了很多编程语言的诸多优点，从这个[知乎问答](https://www.zhihu.com/question/24007154)可见一斑，如此强大的新型编程语言还是非常值得一学的，加之苹果将其开源出来，势必吸引更多的开发者加入到开源的队伍中使其变得更加优秀。

看完The Swift Programming Language之后，我又把《从零开始学Swift》这门书前面几十个章节的源码看了一遍，没有书，只能猜测作者是想表达什么语法知识。（后来才想起来可以去图书馆找这本书，而且图书馆还真有这本书😂）

后来看到[这位开发者](https://github.com/judi0713)用Swift写的[开发者头条的Mac版客户端](http://walkginkgo.com/ios/2016/05/04/Toutiao.html?hmsr=toutiao.io&utm_medium=toutiao.io&utm_source=toutiao.io)感觉很有意思，想试着也写一个，想了想，正好干货集中营缺个Mac版客户端嘛，于是我就开始看[Toutiao for Mac的源码](https://github.com/judi0713/TouTiao)和[Product Hunt for Mac的源码](https://github.com/producthunt/producthunt-osx)。Toutiao for Mac是参考[Tailor的源码](https://github.com/kimar/Tailor)来写的，比较简单。Product Hunt for Mac也是使用Swift开发的，界面和代码都写得非常好，并且使用了[ReSwift](https://github.com/ReSwift/ReSwift)框架。但是我计划开发的这个应用太简单，用这个框架完全是小题大做了。借助这几个优秀的项目源码，我很快完成了Gank for Mac这个项目，项目地址：[Gank for Mac](https://github.com/hujiaweibujidao/Gank)，界面简洁清晰，功能简单完善，欢迎下载使用。

![image](/images/gank-screenshot.png)

最后，期待使用Swift开发Android的那一天，哈哈哈😄
