---
title: Ways to Use Icons on Android (2)
categories: "android"
date: "2016-06-25"
---
本节主要介绍几种图标字体的制作方法和Iconify扩展的使用姿势。<!--more-->

本系列文章介绍的内容对应的Github项目地址：[IconFontApp](https://github.com/hujiaweibujidao/IconFontApp)

上一节提到，如果项目中很多自定义的图标，或者是各种不同来源的图标，我们可以通过对Iconify进行扩展来实现，但是在扩展之前我们需要制作自己的图标字体文件，那么图标字体文件该如何制作呢？这个可以试试Fontello、Icomoon或者IconFont吧！

**(制作图标字体的方法有很多，可以参考[这里](http://www.uisdc.com/4-icon-font-production-method)，本文主要介绍的是如何快速利用已有的图标制作字体文件然后在应用中使用)**

#### **1.Fontello: icon font generator**
Fontello网址：[http://fontello.com/](http://fontello.com/)
Github地址：[https://github.com/fontello/fontello](https://github.com/fontello/fontello)

Fontello是个图标字体生成器，通过它可以把一些图标作成字体放到自己的项目中。在Fontello主页上可以访问大量专业级的开源图标，并支持添加自定义的图标（SVG格式），而且可以在网站上选择不同来源的图标合并到单个字体文件中。此外，它还可以自定义每个图标的名称以及对应的Unicode码，一切配置好了之后可以将图标字体下载下来放到项目中使用。如下图所示，我添加了两个Custom Icons，从Fontelico中选了6个图标，从Font Awesome中选了3个图标等，最终导出得到的图标字体文件就会包含这些我需要的图标。

![img](/images/fontello.png)

自定义图标名称和对应的Unicode：在页面顶部的配置中可以选择设置图标名称的前缀，例如`fe-`
![img](/images/fontello-name.png)
![img](/images/fontello-code.png) 

下载之后得到一个zip文件，解压之后打开`demo.html`可以看到该图标字体中的所有图标的名称和对应的Unicode
![img](/images/fontello-nocode.png) 
![img](/images/fontello-showcode.png)

同时，在解压后的`font`文件夹中有我们需要的ttf字体文件`fontello.ttf`，下面介绍下详细的扩展实现步骤。

(1)新建一个Android Studio项目，在`app`中添加对Iconify的依赖
```
compile 'com.joanzapata.iconify:android-iconify:2.2.2'
```
(2)新建`assets`文件夹，并将字体文件`fontello.ttf`拷贝到文件夹下
(3)新建`FontelloModule`类，实现`IconFontDescriptor`接口，内容如下：
```
public class FontelloModule implements IconFontDescriptor {

    @Override
    public String ttfFileName() {
        return "fontello.ttf";
    }

    @Override
    public Icon[] characters() {
        return FontelloIcons.values();
    }
}
```
(4)新建`FontelloIcons`枚举，实现`Icon`接口，内容如下：
```
public enum FontelloIcons implements Icon {
    fe_spin1('\uE800'),
    fe_spin2('\uE801'),
    fe_spin3('\uE802'),
    fe_spin4('\uE803'),
    fe_spin5('\uE804'),
    fe_github('\uE816');//注：这里我并没有把所有的图标都加上

    char character;

    FontelloIcons(char character) {
        this.character = character;
    }

    @Override
    public String key() {
        return name().replace('_', '-');
    }

    @Override
    public char character() {
        return character;
    }
}
```
(5)测试：在`activity_main.xml`布局文件中添加一个IconTextView
```
<com.joanzapata.iconify.widget.IconTextView
    android:id="@+id/iconTextView"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:layout_centerInParent="true"
    android:layout_centerHorizontal="true"
    android:text="{fe-github} {fe-spin1 spin} {fe-spin2 spin} {fe-spin3 spin} {fe-spin4 spin} {fe-spin5 spin}"
    android:textSize="20sp"
    android:textColor="@android:color/black"/>
```
然后在`MainActivity`的`onCreate`方法最后添加初始化操作
```
Iconify.with(new FontelloModule());
```

运行应用看到效果见文章末尾的截图，图标可以设置为旋转效果的哟，有点炫啊！

#### **2.IcoMoon**
IcoMoon网址：[https://icomoon.io/app/](https://icomoon.io/app/)
IcoMoon和Fontello一样，既可以添加自己的图标，又可以从其他的图标库中选择图片，而且也支持设置图标的名称和Unicode，最终还能导出得到图标字体文件。IcoMoon导出得到的zip文件和Fontello导出的结果类似，使用它的ttf文件对Iconify进行扩展的方式也一样。

#### **3.IconFont**
IconFont网址：[http://www.iconfont.cn/](http://www.iconfont.cn/)
IconFont可是中文的图标字体制作网站哟！该网站是阿里的UED团队做的吧，在该网站可以方便地管理图标和制作图标字体文件。网站的帮助中[Android端应用教程](http://www.iconfont.cn/help/iconuse.html)介绍了如何使用下载得到的IconFont，这个比较简单。但是，需要注意的是，下载下来的`demo.html`中看到的图标对应的编码用的是`UTF-8`表示的，并不是`Unicode`编码。此外，TextView的setText方法在使用的时候，如果传递的参数是`R.string.xxx`的形式的话，最终显示的时候对应的字符串会自动转成Unicode编码；但是如果传递的参数是某个字符串的话，该字符串默认会被视为Unicode编码，也就是说如果它原来不是Unicode编码这个时候显示就会出现异常！

看下下面的代码就清楚了，下面显示了4中不同的调用方式，并给出了不同方式下的显示结果
![iconfontapp_code](/images/iconfontapp_code.png)

关于如何将UTF-8编码的形式改成Unicode编码的形式可以参考其他的文档，但是这里的转换比较简单，只要抽取出其中的16位表示形式就行了，例如UTF-8编码的`&#xe601;`对应的Unicode编码就是`\ue601`，其中的16位表示形式是`e601`，其他的同理。

项目[IconFontApp](https://github.com/hujiaweibujidao/IconFontApp)运行起来的效果如下图所示：
![img](/images/iconfont.gif)

从上面的分析可以看出，图标字体文件的制作以及利用字体文件对Iconify进行扩展都还比较简单，唯一比较麻烦的是，如果项目中使用了大量的图标的话，编写图标集合的枚举类会比较无聊，所以下节可能会开发一个小脚本或者小插件来完成这个无聊的任务，噢啦，晚安！

余淮和耿耿终于在一起啦，好嗨森，嘿嘿，《最好的我们》和最好的我们真的快要结束啦，快要毕业咯！
