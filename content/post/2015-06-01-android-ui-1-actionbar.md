---
title: "Head First Android ActionBar"
date: "2015-06-01"
categories: "android"
---
本文介绍Android ActionBar的使用 <!--more-->

最近在Android Studio中新建项目时发现Activity还是和以前一样，默认继承自`ActionBarActivity`，但是`ActionBarActivity` 却被标示为已经过时的API！对于这个问题，StackOverflow上已经有人回答了，请看[ActionBarActivity deprecated](http://stackoverflow.com/questions/29877692/why-was-actionbaractivity-deprecated)，然后你会发现自从Android的兼容支持库升级到21版本以后(`appcompat-v7-r21.1.0 `)，`ActionBarActivity` 被  `AppCompatActivity` 取代了！还有一个变化是建议使用`Toolbar`，而不要使用原来的`ActionBar` 了！所以，这两节的内容我打算总结下ActionBar和Toolbar的基本使用，因为Toolbar实际上是ActionBar的扩展，所以这一节还是介绍复杂的ActionBar，下一节再继续介绍Toolbar。

1.ActionBar的来源

ActionBar是从Android 3.0开始引入的，它是用于取代3.0之前的标题栏，并提供更为丰富的导航效果。

2.添加ActionBar

参考[Setting Up the Action Bar](https://developer.android.com/training/basics/actionbar/setting-up.html)

(1)支持Android 3.0以上版本(API level 11)

如果要支持Android 3.0以上版本(API level 11)，即`android:minSdkVersion="11"`，那么很简单，只要Activity的Theme是使用了`Theme.Holo` 系列主题其中一种或者继承自这些主题，那么Activity就默认包含了ActionBar。

(2)支持Android 2.1以上版本(API level 7)

如果要支持Android 2.1以上版本(API level 7)，即`android:minSdkVersion="7" `，那么就要使用兼容支持库`v7 appcompat`。导入AppCompat支持库之后，只要Activity的Theme是使用了`Theme.AppCompat` 兼容主题其中一种或者继承自这些兼容主题，然后让Activity继承自`appcompat`中的`ActionBarActivity` 类即可。

3.设置ActionBar的风格

参考[Styling the Action Bar](https://developer.android.com/training/basics/actionbar/styling.html)

下图是三种不同的来自`Theme.holo` 系列的ActionBar的样式，对应于`Theme.AppCompat` 系列分别是`Theme.AppCompat` 、`Theme.AppCompat.Light` 、`Theme.AppCompat.Light.DarkActionBar`。

![image](/images/theme_holo.png)

那么如何自定义呢？比如修改ActionBar的背景颜色该怎么办呢？和以前一样，我们可以继承默认的主题，然后修改默认主题中的某些样式来实现。

以修改ActionBar的背景颜色为例，如果是支持Android 3.0及以上版本的话可以用下面的方式，需要注意两点：(1)自定义`android:actionBarStyle` ；(2) 自定义的`actionBarStyle` 也要继承自某个`actionBarStyle` 样式。

```java
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- the theme applied to the application or activity -->
    <style name="CustomActionBarTheme"
           parent="@android:style/Theme.Holo.Light.DarkActionBar">
        <item name="android:actionBarStyle">@style/MyActionBar</item>
    </style>

    <!-- ActionBar styles -->
    <style name="MyActionBar"
           parent="@android:style/Widget.Holo.Light.ActionBar.Solid.Inverse">
        <item name="android:background">@drawable/actionbar_background</item>
    </style>
</resources>
```

如果是支持Android 2.1版本以上的话，可以用下面的方式，注意这里需要设置`background`和`android:background`两个属性的值：

```
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- the theme applied to the application or activity -->
    <style name="CustomActionBarTheme"
           parent="@style/Theme.AppCompat.Light.DarkActionBar">
        <item name="android:actionBarStyle">@style/MyActionBar</item>

        <!-- Support library compatibility -->
        <item name="actionBarStyle">@style/MyActionBar</item>
    </style>

    <!-- ActionBar styles -->
    <style name="MyActionBar"
           parent="@style/Widget.AppCompat.Light.ActionBar.Solid.Inverse">
        <item name="android:background">@drawable/actionbar_background</item>

        <!-- Support library compatibility -->
        <item name="background">@drawable/actionbar_background</item>
    </style>
</resources>
```

类似的，我们还可以修改其他的样式，例如文本颜色等等。

如果我们想让ActionBar如下图所示悬浮起来的话，可以修改`android:windowActionBarOverlay` 样式为`true`。

参考[Overlaying the Action Bar](https://developer.android.com/training/basics/actionbar/overlaying.html)

![image](/images/actionbar-overlay.png)

```
//**For Android 3.0 and higher only**
<resources>
    <!-- the theme applied to the application or activity -->
    <style name="CustomActionBarTheme"
           parent="@android:style/Theme.Holo">
        <item name="android:windowActionBarOverlay">true</item>
    </style>
</resources>

//**For Android 2.1 and higher**
<resources>
    <!-- the theme applied to the application or activity -->
    <style name="CustomActionBarTheme"
           parent="@android:style/Theme.AppCompat">
        <item name="android:windowActionBarOverlay">true</item>

        <!-- Support library compatibility -->
        <item name="windowActionBarOverlay">true</item>
    </style>
</resources>
```

在悬浮状态下，如果你又希望你的组件是一直处在ActionBar下面一直可见的，可以设置它的`padding` 或者 `margin`属性，值为`actionBarSize`。

```
//
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:paddingTop="?android:attr/actionBarSize">
    ...
</RelativeLayout>

//
<!-- Support library compatibility -->
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:paddingTop="?attr/actionBarSize">
    ...
</RelativeLayout>
//In this case, the ?attr/actionBarSize value without the prefix works on all versions, including Android 3.0 and higher.
```

4.添加Action Buttons

参考[Adding Action Buttons](https://developer.android.com/training/basics/actionbar/adding-buttons.html)

(4.1) 定义Action Buttons其实就是定义Menu，可以在`/res/menu` 新建菜单文件即可，如下所示：

```
<menu xmlns:android="http://schemas.android.com/apk/res/android" >
    <!-- Search, should appear as action button -->
    <item android:id="@+id/action_search"
          android:icon="@drawable/ic_action_search"
          android:title="@string/action_search"
          android:showAsAction="ifRoom" />
    <!-- Settings, should always be in the overflow -->
    <item android:id="@+id/action_settings"
          android:title="@string/action_settings"
          android:showAsAction="never" />
</menu>
```

当菜单项过多时，Android会分两种情况进行处理：
1、手机有MENU实体键：则按下Menu键后会显示剩余菜单项；
2、手机没有MENU实体键：则会在最左边显示一个Action OverFlow按钮，按下后会显示剩余项菜单。

属性 `android:showAsAction` 可以用来设置该菜单项的显示方式，共有5中属性值：
`never`：永远不会显示。只会在溢出列表中显示。
`ifRoom`：会显示在Item中，但是如果已经有4个或者4个以上的Item时会隐藏在溢出列表中。
`always`：无论是否溢出，总会显示。
`withText`：Title会显示。
`collapseActionView`：可拓展的Item。

**注意，如果你是为了兼容Android 2.1版本等低版本系统而使用了支持库`Support Library` 的话，你还需要自定义一个命名空间`NameSpace`，因为`showAsAction` 并不在`android:` 命名空间中**，如下所示：

```
<menu xmlns:android="http://schemas.android.com/apk/res/android"
      xmlns:yourapp="http://schemas.android.com/apk/res-auto" >
    <!-- Search, should appear as action button -->
    <item android:id="@+id/action_search"
          android:icon="@drawable/ic_action_search"
          android:title="@string/action_search"
          yourapp:showAsAction="ifRoom"  />
    ...
</menu>
```

(4.2) 然后在Activity的`onCreateOptionsMenu`中将Actions添加到ActionBar中

```
@Override
public boolean onCreateOptionsMenu(Menu menu) {
    // Inflate the menu items for use in the action bar
    MenuInflater inflater = getMenuInflater();
    inflater.inflate(R.menu.main_activity_actions, menu);
    return super.onCreateOptionsMenu(menu);
}
```

(4.3) 点击Action之后的处理就是处理`onOptionsItemSelected` 方法

**当用户选择一个Fragment的菜单项时，首先会调用Activity的onOptionsItemSelected()方法，如果该方法返回false，则调用Fragment实现的onOptionsItemSelected()方法。**

```
@Override
public boolean onOptionsItemSelected(MenuItem item) {
    // Handle presses on the action bar items
    switch (item.getItemId()) {
        case R.id.action_search:
            openSearch();
            return true;
        case R.id.action_settings:
            openSettings();
            return true;
        default:
            return super.onOptionsItemSelected(item);
    }
}
```

(4.4) 如何利用ActionBar实现应用内的导航呢？

如果是在Anroid 4.1(API level 16)以上版本或者使用支持库中的`ActionBarActivity`的话，只需要在Manifest文件中指定Activity的父Activity即可，这样系统就知道返回的时候是回到哪个Activity了。(好在使用Android Studio的时候，每次新建Activity的时候都可以选择父Activity然后帮我们在Manifest文件中写好了)

如下所示，Android 4.1以上版本看`android:parentActivityName` 属性，以下版本看`<meta-data>` 元素：

```
<application ... >
    ...
    <!-- The main/home activity (it has no parent activity) -->
    <activity
        android:name="com.example.myfirstapp.MainActivity" ...>
        ...
    </activity>
    <!-- A child of the main activity -->
    <activity
        android:name="com.example.myfirstapp.DisplayMessageActivity"
        android:label="@string/title_activity_display_message"
        android:parentActivityName="com.example.myfirstapp.MainActivity" >
        <!-- Parent activity meta-data to support 4.0 and lower -->
        <meta-data
            android:name="android.support.PARENT_ACTIVITY"
            android:value="com.example.myfirstapp.MainActivity" />
    </activity>
</application>
```

然后在Activity中`setDisplayHomeAsUpEnabled(true)` 即可

```
@Override
public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_displaymessage);

    getSupportActionBar().setDisplayHomeAsUpEnabled(true);
    // If your minSdkVersion is 11 or higher, instead use:
    // getActionBar().setDisplayHomeAsUpEnabled(true);
}
```

如果细想的话，还要考虑当前Activity和父Activity所处的Stack的情况，那么就复杂了，可以参考[Providing Up Navigation](https://developer.android.com/training/implementing-navigation/ancestral.html#NavigateUp)学习下如何处理不同的launchMode下的导航。

**关于Android getActionBar vs getSupportActionBar?**

这个一个经常出错的问题，可以看下这里[Android getActionBar vs getSupportActionBar?](http://stackoverflow.com/questions/28002209/android-getactionbar-vs-getsupportactionbar)，简言之，如果是支持Android 3.0以上版本(API level 11以上)使用`getActionBar` 即可，如果需要支持Android 2.1等低版本，那么肯定需要使用兼容支持库，那么就要使用其中的`getSupportActionBar` 才行。

其他的关于ActionBar的内容参见这篇文章[Android UI开发详解之ActionBar](http://www.open-open.com/lib/view/open1373981182669.html)，它还详细介绍了如果开发带Tab的ActionBar以及下拉模式的ActionBar等内容。

OK，ActionBar就介绍到这里，下面进入[第二节——Toolbar](/blog/2015/06/02/android-ui-2-toolbar/)。
