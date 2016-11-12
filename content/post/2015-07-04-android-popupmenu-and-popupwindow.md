---
title: "Android PopupMenu and PopupWindow"
date: "2015-07-04"
categories: "android"
---
本文通过一个实例简单介绍下PopupMenu和PopupWindow的区别和各自使用方式。 <!--more-->

实例的代码使用了Android Annotations，但是代码读起来应该是没有障碍的，如果不太了解AA的话，可以参考下[此文](/blog/2015/05/31/android-annotations/)。

1.PopupMenu和PopupWindow

PopupMenu显示效果类似上下文菜单(Menu)，而PopupWindow的显示效果实际上类似对话框(Dialog)，两者效果如下图所示：

PopupMenu显示效果

{% img /images/showmenu1.png 144 256 %} {% img /images/showmenu2.png 144 256 %}

PopupWindow显示效果

![image](/images/showwindow1.png)

2.实例基础代码

我们要实现的界面就是上面所示的界面，上下各有两个按钮，点击按钮分别在正确的位置弹出PopupMenu或者PopupWindow，下面是界面代码：

```
<RelativeLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context="hujiawei.xiaojian.ui.PopupwindowActivity">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_alignParentTop="true"
        android:orientation="vertical">

        <Button
            android:id="@+id/window"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="show popup window"/>

        <Button
            android:id="@+id/menu"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_below="@id/window"
            android:text="show popup menu"/>

    </LinearLayout>

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_alignParentBottom="true"
        android:orientation="vertical">

        <Button
            android:id="@+id/bottomwindow"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="show popup window"/>

        <Button
            android:id="@+id/bottommenu"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_below="@id/window"
            android:text="show popup menu"/>

    </LinearLayout>

</RelativeLayout>
```

3.实现PopupMenu

PopupMenu的实现稍微简单点，因为它就是普通的菜单！

(1)在`res/menu`文件夹下新建文件`menu_popupmenu.xml`

```
<?xml version="1.0" encoding="utf-8"?>
<menu
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">

    <item
        android:id="@+id/item_movies"
        android:title="Movies"
        android:visible="true"
        app:showAsAction="ifRoom|withText"/>
    <item
        android:id="@+id/item_music"
        android:title="Music"
        android:visible="true"
        app:showAsAction="ifRoom|withText"/>
    <item
        android:id="@+id/item_photo"
        android:title="Photo"
        android:visible="true"
        app:showAsAction="ifRoom|withText"/>

</menu>
```

(2)然后在Activity中创建Menu并处理MenuItem的点击事件

```
@Click({R.id.menu, R.id.bottommenu})
void menu(View view) {
    PopupMenu popupMenu = new PopupMenu(this, view);
    popupMenu.setOnMenuItemClickListener(this);
    popupMenu.inflate(R.menu.menu_popupmenu);
    popupMenu.show();
}

public boolean onMenuItemClick(MenuItem item) {
    switch (item.getItemId()) {
        case R.id.item_photo:
            toastUtil.showShortToast("Photo");
            return true;
        case R.id.item_movies:
            toastUtil.showShortToast("Movies");
            return true;
        case R.id.item_music:
            toastUtil.showShortToast("Music");
            return true;
    }
    return false;
}
```

从上面的代码可以看出，不论是点击上面的还是下面的`show popup menu`按钮，结果都是弹出在当前按钮附近显示PopupMenu (因为这里设置了button view为anchor view)，而且它会自适应位置，在按钮的左下角或者左上角显示。

4.实现PopupWindow

实现PopupWindow稍微复杂些，但是自定义性更强，它可以将任意界面设置为PopupWindow。

(1)新建布局文件`layout/window_popup.xml`，作为PopupWindow，其中只有4个按钮，最后一个是取消按钮，用于关闭PopupWindow

```
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:layout_marginLeft="@dimen/activity_horizontal_margin"
    android:layout_marginRight="@dimen/activity_horizontal_margin"
    android:background="@android:color/background_dark"
    android:orientation="vertical">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical">

        <Button
            android:id="@+id/music"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Music"/>

        <Button
            android:id="@+id/movie"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Movie"/>

        <Button
            android:id="@+id/photo"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Photo"/>

    </LinearLayout>

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="10dp"
        android:orientation="vertical">

        <Button
            android:id="@+id/cancel"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="Cancel"/>
    </LinearLayout>

</LinearLayout>
```

(2)在Activity中控制PopupWindow的显示和事件处理

```
@Click
void window(View view) {
    if (popupWindow != null && popupWindow.isShowing()) {
        return;
    }
    LinearLayout layout = (LinearLayout) getLayoutInflater().inflate(R.layout.window_popup, null);
    popupWindow = new PopupWindow(layout,
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT);

    popupWindow.setAnimationStyle(R.style.Popupwindow);//包括进入和退出两个动画
    popupWindow.showAtLocation(view, Gravity.LEFT | Gravity.BOTTOM, 0, 0);
    //popupWindow.showAsDropDown(view);

    setButtonListeners(layout);
}

@Click
void bottomwindow(View view) {
    if (popupWindow != null && popupWindow.isShowing()) {
        return;
    }
    LinearLayout layout = (LinearLayout) getLayoutInflater().inflate(R.layout.window_popup, null);
    popupWindow = new PopupWindow(layout,
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT);

    popupWindow.setAnimationStyle(R.style.Popupwindow);
    int[] location = new int[2];
    view.getLocationOnScreen(location);
    popupWindow.showAtLocation(view, Gravity.LEFT | Gravity.BOTTOM, 0, -location[1]);
    //popupWindow.showAsDropDown(view);

    setButtonListeners(layout);
}

private void setButtonListeners(LinearLayout layout) {
    Button music = (Button) layout.findViewById(R.id.music);
    music.setOnClickListener(new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            if (popupWindow != null && popupWindow.isShowing()) {
                toastUtil.showShortToast("music");
                popupWindow.dismiss();
            }
        }
    });

    Button movie = (Button) layout.findViewById(R.id.movie);
    movie.setOnClickListener(new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            if (popupWindow != null && popupWindow.isShowing()) {
                toastUtil.showShortToast("movie");
                popupWindow.dismiss();
            }
        }
    });

    Button photo = (Button) layout.findViewById(R.id.photo);
    photo.setOnClickListener(new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            if (popupWindow != null && popupWindow.isShowing()) {
                toastUtil.showShortToast("photo");
                popupWindow.dismiss();
            }
        }
    });

    Button cancel = (Button) layout.findViewById(R.id.cancel);
    cancel.setOnClickListener(new View.OnClickListener() {
        @Override
        public void onClick(View view) {
            if (popupWindow != null && popupWindow.isShowing()) {
                popupWindow.dismiss();
            }
        }
    });
}
```

从上面代码可以看出，点击上面和下面的按钮代码略微不同，因为这里我希望PopupWindow一直是从界面的底部慢慢滑入进入的，所以要控制下位置。关于PopupWindow的显示位置，它既提供了`showAtLocation`方法精确控制，也提供了`showAsDropDown(view)`方法简单控制。

滑入滑出的动画效果代码如下，需要注意的是，PopupWindow需要两个动画：一个进入，一个退出，如果只给定一个动画，可能会看不到动画的效果。

```
/res/values/styles.xml

<style name="Popupwindow">
    <item name="android:windowEnterAnimation">@anim/slide_in_bottom</item>
    <item name="android:windowExitAnimation">@anim/slide_out_bottom</item>
</style>

/res/anim/slide_in_bottom.xml

<?xml version="1.0" encoding="utf-8"?>
<translate xmlns:android="http://schemas.android.com/apk/res/android"
           android:interpolator="@android:anim/decelerate_interpolator"
           android:fromYDelta="100%" android:toYDelta="0"
           android:duration="400"/>

/res/anim/slide_out_bottom.xml

<?xml version="1.0" encoding="utf-8"?>
<translate xmlns:android="http://schemas.android.com/apk/res/android"
           android:interpolator="@android:anim/accelerate_interpolator"
           android:fromYDelta="0" android:toYDelta="100%"
           android:duration="200"/>
```

(3)使用PopupWindow还有不少需要注意的地方，例如你上面看到的代码中很多判断popupwindow是否为null或者是否正在显示等，有一个情况是，如果用户点击返回键，默认情况下Activity就要退出了，这个时候PopupWindow没有dismiss，容易出现内存泄露的报错，所以我们要处理下这个问题，如果用户点击返回键的时候PopupWindow正在显示的话那么就dismiss PopupWindow就好了。

```
@Override
public void onBackPressed() {
    if (popupWindow != null && popupWindow.isShowing()) {
        popupWindow.dismiss();
    }else{
        super.onBackPressed();
    }
}
```

OK，差不多就是这些了，希望会有帮助，Enjoy！:-)
