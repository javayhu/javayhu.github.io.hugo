---
title: Ways to Use Icons on Android (1)
tags: ["android"]
date: "2016-06-24"
---
本节主要介绍几种Material Design图标的使用姿势。<!--more-->

本系列文章介绍的内容对应的Github项目地址：[IconFontApp](https://github.com/hujiaweibujidao/IconFontApp)

最近对IconFont特别感兴趣，通过使用IconFont一些常见的制作精良的小图标就可以直接在代码中非常方便的使用，免去了找图标并添加到项目中的很多麻烦。本系列估计也会有三篇文章，结合实践分享下我的摸索过程，也许大家会觉得有用呢。本节主要从Material Design图标入手，介绍它的几种使用姿势。

#### **1.Material Design图标简介**
Github网址：[https://github.com/google/material-design-icons](https://github.com/google/material-design-icons)
内容介绍网址：[http://google.github.io/material-design-icons/](http://google.github.io/material-design-icons/)

Material Design图标分为了`action`、`alert`、`file`、`notification`、`place`等类型，每种类型下都有一定数量的图标，而且这些图标还按照平台的不同进行了整理，包括`android`、`ios`、`web`平台，同时也包含了SVG格式的图片文件。其中`android`平台的图标又包括两种类型的，一种是存放在`drawable-xxxdpi`文件夹下的PNG格式文件，里面的图标有4种大小，分别是`18dp`、`24dp`、`36dp`和`48dp`；另一种是存放在`drawable-anydpi-v21`文件夹下的XML格式文件（Vectore Drawable），里面的图标大小都是`24dp`，颜色都是黑色。

#### **2.复制使用方式**
复制使用方式就是如果项目中我们需要某张Material Design风格的图片的话，我们可以直接拷贝PNG格式的文件或者XML格式的文件，区别是后者只支持Android Lollipop及以上版本（但是可以通过support library进行兼容）。

如果你不想进行复制操作的话，可以考虑Android Studio的`Android Drawable Importer`插件。
插件的Github网址：[https://github.com/winterDroid/android-drawable-importer-intellij-plugin](https://github.com/winterDroid/android-drawable-importer-intellij-plugin)

利用这个插件的`Icon Pack Drawable Importer`功能可以快速导入PNG或者JPG格式的图片文件，还可以设置大小和颜色。此外，利用它的`Vector Drawable Importer`功能就可以导入XML格式的Vector Drawable文件，导入之后可以在项目的`res/drawable`目录中看到导入的文件。

![img](/images/drawable_importer.png)

#### **3.依赖使用方式**
依赖使用方式是通过依赖一些封装好的第三方库来使用Material Design图标，例如项目`MaterialDesignIcons`和`Iconify`。

MaterialDesignIcons的Github网址：[https://github.com/MrBIMC/MaterialDesignIcons](https://github.com/MrBIMC/MaterialDesignIcons)
这个项目很简单，它完全复制Material Design图标的XML文件到res目录下作成一个library以供使用，所以我们都可以很快做出来。
此外，它的图标来源于[https://materialdesignicons.com/](https://materialdesignicons.com/)，除了Google官方的那些Material Design风格图标之外，还包含了一些社区（Community）创作的Material Design风格图标，加起来总共约有4000个图标，实在是够用了。

Iconify的Github网址：[https://github.com/JoanZapata/android-iconify](https://github.com/JoanZapata/android-iconify)
这个项目非常棒，首先它将Font Awesome、Material Design等图标都封装成简单可用的字体，通过自定义的TextView去解析自定义字体的文本来显示出图标。而且它还自定义了`IconDrawable`类，支持将图标作为Drawable使用，真的是炒鸡赞的项目！
该项目的设计非常好，易于扩展，它将来自Google的Material Design图标和来自Community的Material Design图标分拆成两个独立的模块以供使用。后面会简单介绍如何对它进行扩展。

下图显示了Iconify的使用方式：
![img](/images/iconify.png)

下面通过Iconify中的几个主要的类来介绍下Iconify的内部实现：
##### （1）`Icon`接口
描述图标的信息。每个图标都有一个key和character，key代表图标的名称，例如`fa-ok`，character代表图标对应的Unicode，例如`\u4354`。
```
/**
 * Icon represents one icon in an icon font.
 */
public interface Icon {
    /** The key of icon, for example 'fa-ok' */
    String key();//key代表图标字体的名称，例如`fa-ok`

    /** The character matching the key in the font, for example '\u4354' */
    char character();//character代表图标对应的Unicode码，例如`\u4354`
}
```
##### （2）`IconFontDescriptor`接口
描述图标字体的信息，包括它对应的ttf字体文件和图标集合。
```
/**
 * An IconFontDescriptor defines a TTF font file
 * and is able to map keys with characters in this file.
 */
public interface IconFontDescriptor {
    /**
     * The TTF file name.
     * @return a name with no slash, present in the assets.
     */
    String ttfFileName();//assets目录下的字体文件

    Icon[] characters();//图标字体集合
}
```
##### （3）`Iconify`类
最主要的核心类，调用`with`方法来添加图标字体集合。[查看源码](https://github.com/JoanZapata/android-iconify/blob/master/android-iconify/src/main/java/com/joanzapata/iconify/Iconify.java)
```
/**
 * Add support for a new icon font.
 * @param iconFontDescriptor The IconDescriptor holding the ttf file reference and its mappings.
 * @return An initializer instance for chain calls.
 */
public static IconifyInitializer with(IconFontDescriptor iconFontDescriptor) {
    return new IconifyInitializer(iconFontDescriptor);
}
```
##### （4）其他代码
自定义的`IconTextView`、`IconButton`、`IconToggleButton`以及`IconDrawable`等，核心实现在`ParseUtil`类中，它的`compute`方法会去解析设置的文本内容，从中提取出不同字体对应的图标，甚至设置其大小和颜色以及旋转动画效果。
**[简易版本的自定义字体的TextView可以参考[这篇文章](http://hujiaweibujidao.github.io/blog/2015/07/04/android-text-view-with-custom-font/)]**

##### （5）如何扩展？
如果想要扩展Iconify，只需要一个ttf字体文件和实现`IconFontDescriptor`接口的类就行了，可以参考[Font Awesome的图标字体集合的实现](https://github.com/JoanZapata/android-iconify/blob/master/android-iconify-fontawesome/src/main/java/com/joanzapata/iconify/fonts/FontAwesomeModule.java)。
为了方便使用，一般还会添加一个枚举，列举出这个图标字体集合中所有图标的key和character对应关系，以Font Awesome图标字体为例：
```
public enum FontAwesomeIcons implements Icon {
    fa_glass('\uf000'),
    fa_music('\uf001'),
    fa_search('\uf002'),
    fa_envelope_o('\uf003'),
    fa_heart('\uf004'),
    fa_star('\uf005'),
    fa_star_o('\uf006'),
    fa_user('\uf007'),
    fa_film('\uf008'),
    fa_th_large('\uf009'),
    fa_th('\uf00a'),
    fa_th_list('\uf00b'),
    ......
```

我比较喜欢Iconify的使用方式，简洁好用，嘿嘿，欢迎推荐其他的Material Design图标的使用姿势！

在实际的项目开发中肯定会有很多自定义的小图标或者来自不同来源的小图标，如果遇到这种情况该怎么办呢？这个时候我们可以通过对Iconify进行扩展来实现，但是扩展之前我们需要制作出自己的图标字体文件，这个该如何制作呢？请看下节！

