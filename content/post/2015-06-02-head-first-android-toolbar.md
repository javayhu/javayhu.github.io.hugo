---
title: "Head First Android Toolbar"
date: "2015-06-02"
tags: ["android"]
---
本文介绍Android Toolbar的使用 <!--more-->

上一节我们介绍了[ActionBar的使用](/blog/2015/06/01/android-ui-1-actionbar/)，这一节我们介绍`ActionBar` 的替代者——`Toolbar`，看看它有多大的能耐！

1.Toolbar的来源

参考[AppCompat v21 — Material Design for Pre-Lollipop Devices!](http://android-developers.blogspot.com/2014/10/appcompat-v21-material-design-for-pre.html)
参考[Android Support Library 22.1](http://android-developers.blogspot.in/2015/04/android-support-library-221.html)

首先要介绍下AppCompat，这个库起初是是为了让以前低版本的Android系统能够用上ActionBar而开发的兼容支持库**[right?]**，现在这个库能够为低版本系统提供很多方面的兼容。自从Android 5.0引入了Material Design之后，这个兼容支持库增加了一个任务，那就是为低版本的系统提供与Material Design兼容的组件。

**AppCompat (aka ActionBarCompat) started out as a backport of the Android 4.0 ActionBar API for devices running on Gingerbread, providing a common API layer on top of the backported implementation and the framework implementation. AppCompat v21 delivers an API and feature-set that is up-to-date with Android 5.0**

参考网址[Android Support Library 22.1](http://android-developers.blogspot.in/2015/04/android-support-library-221.html)中有一段Google工作人员录制的视频，介绍AppCompat。我的理解是大致如下图所示，如果没有AppCompat，我们开发的应用在不同版本的Android系统上显示起来会像上面一行的三个图片那样，没有统一的界面风格；而如果使用了AppCompat的话，就会像下面一行的三个图片那样，界面风格统一，操作方式一致，同时将Material Design的设计风格带到了以前低版本Android系统。

![image](/images/appcompat.png)

再来看下Toolbar，这是从AppCompat 21版本开始引入的，它的使用就像一个普通的View组件一样，同时它还可以充当ActionBar，这样我们设置的菜单项就会显示在它上面了。

**In this release, Android introduces a new Toolbar widget. This is a generalization of the Action Bar pattern that gives you much more control and flexibility. Toolbar is a view in your hierarchy just like any other, making it easier to interleave with the rest of your views, animate it, and react to scroll events. You can also set it as your Activity’s action bar, meaning that your standard options menu actions will be display within it.**

下面是我写的一个演示程序，得到的效果如下图所示，从左到右的Android系统版本分别是`5.1.0`、`4.4.4`、`2.3.7`，可以看出界面风格大致是一致的。

![image](/images/toolbar_polaris_demo.png)

2.Toolbar API简介

参考[Toolbar Class](https://developer.android.com/reference/android/support/v7/widget/Toolbar.html)

下面的内容摘自上面的[Toolbar Class](https://developer.android.com/reference/android/support/v7/widget/Toolbar.html) 中的介绍，大致内容就是说Toolbar可以像一个普通的View组件一样使用，同时它还可以充当ActionBar的功能，默认提供了很多种元素可以放置在Toolbar上，其中包括导航按钮、logo图标、标题和子标题、一个或多个自定义的View以及菜单项。大家可以看下下图大致感受下(图片来自[Using Toolbars in your apps](http://www.101apps.co.za/index.php/articles/using-toolbars-in-your-apps.html))

![image](/images/toolbar_whole.jpg)

A `Toolbar` is a generalization of action bars for use within application layouts. While an action bar is traditionally part of an Activity's opaque window decor controlled by the framework, a Toolbar may be placed at any arbitrary level of nesting within a view hierarchy. An application may choose to designate a Toolbar as the action bar for an Activity using the `setSupportActionBar()` method.

Toolbar supports a more focused feature set than ActionBar. From start to end, a toolbar may contain a combination of the following optional elements:

`A navigation button.` This may be an Up arrow, navigation menu toggle, close, collapse, done or another glyph of the app's choosing. This button should always be used to access other navigational destinations within the container of the Toolbar and its signified content or otherwise leave the current context signified by the Toolbar.

`A branded logo image.` This may extend to the height of the bar and can be arbitrarily wide.

`A title and subtitle.` The title should be a signpost for the Toolbar's current position in the navigation hierarchy and the content contained there. The subtitle, if present should indicate any extended information about the current content. If an app uses a logo image it should strongly consider omitting a title and subtitle.

`One or more custom views.` The application may add arbitrary child views to the Toolbar. They will appear at this position within the layout. If a child view's `Toolbar.LayoutParams` indicates a `Gravity` value of `CENTER_HORIZONTAL` the view will attempt to center within the available space remaining in the Toolbar after all other elements have been measured.

`An action menu.` The menu of actions will pin to the end of the Toolbar offering a few frequent, important or typical actions along with an optional overflow menu for additional actions.

**In modern Android UIs developers should lean more on a visually distinct color scheme for toolbars than on their application icon. The use of application icon plus title as a standard layout is discouraged on API 21 devices and newer.**

3.让Toolbar充当ActionBar

如何让Toolbar充当ActionBar？  
参考[Android Tips: Hello Toolbar, Goodbye Action Bar](http://blog.xamarin.com/android-tips-hello-toolbar-goodbye-action-bar/) 和 [Android Lollipop Toolbar Example](http://javatechig.com/android/android-lollipop-toolbar-example)。

(3.1)设置Theme

可以直接设置为`Theme.AppCompat.NoActionBar` 主题或者给原有Theme添加两个属性表示我们不使用ActionBar。

**注意，这里有个bug，很容易出现 `AppCompat does not support the current theme features` 的错误。** 例如下面的设置：

```java
<!-- Base application theme. -->
<style name="AppTheme" parent="Theme.AppCompat">
    <item name="android:windowNoTitle">true</item>
    <item name="windowActionBar">false</item>
</style>
```

正确的设置是要么直接设置为`Theme.AppCompat.NoActionBar` 主题；要么提供一个原有Theme的`.NoActionBar`扩展版本，如下所示：

参考[StackOverflow: AppCompat does not support the current theme features](http://stackoverflow.com/questions/29790070/upgraded-to-appcompat-v22-1-0-and-now-getting-illegalargumentexception-appcompa)

```
//**option 1**
<style name="AppTheme" parent="Theme.AppCompat.NoActionBar">
    <!-- Customize your theme here. -->

</style>

//**option 2**
<style name="AppTheme" parent="Theme.AppCompat">
    <!-- Customize your theme here. -->

</style>

<style name="AppTheme.NoActionBar">
    <!-- Both of these are needed -->
    <item name="windowActionBar">false</item>
    <item name="windowNoTitle">true</item>
</style>
//不需要ActionBar的Activity的Theme设置为AppTheme.NoActionBar就好了
```

(3.2)添加Toolbar

在Layout文件中添加Toolbar组件，就把它当做一个普通的View组件来使用即可

```
<Toolbar xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/toolbar"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:minHeight="?android:attr/actionBarSize"
    android:background="?android:attr/colorPrimary" />
```

(3.3)设置Toolbar为ActionBar

在Activity的`onCreate` 方法中调用`setSupportActionBar(Toolbar)` 方法。

```
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.Toast;


public class MainActivity extends AppCompatActivity {//ActionBarActivity  AppCompatActivity 都可以

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        //Caused by: java.lang.IllegalArgumentException: AppCompat does not support the current theme features

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
    }

}
```

显示结果如下：

![image](/images/toolbar_demo.png)

4.设置Toolbar的风格

可以直接给Toolbar添加`app:theme` 或者`app:popupTheme` 等属性设置其风格，属性值最好是继承自AppCompat的样式。此外，虽然可以这么设置，但是目前AppCompat对于以前低版本Android系统提供的Material Design支持还是很有限的，参见[Styling Material Toolbar in Android](http://blog.mohitkanwal.com/blog/2015/03/07/styling-material-toolbar-in-android/)。

```
<android.support.v7.widget.Toolbar
    android:id="@+id/toolbar"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="#2196F3"
    android:minHeight="?attr/actionBarSize"
    app:theme="@style/ThemeOverlay.AppCompat.Dark.ActionBar"
    app:popupTheme="@style/ThemeOverlay.AppCompat.Light">
</android.support.v7.widget.Toolbar>
```

**关于几个颜色值**

![image](/images/toolbar_theme_color.png)

OK，Toolbar介绍的差不多啦，估计大家应该能够随意地使用Toolbar啦。
