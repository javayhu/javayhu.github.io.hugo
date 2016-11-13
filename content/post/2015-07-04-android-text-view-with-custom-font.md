---
title: "Android Text View with Custom Font"
date: "2015-07-04"
tags: ["android"]
---
本文以自定义TextView为例简单实践下如何自定义View，它能够根据设置的xml属性采用不同的字体显示文字<!--more-->

效果如下图所示：

![images](/images/fonttextview.png)

如果你是使用Android Studio的话，那么Custom View操作很简单，只需要`new -> UI Component -> Custom View`就好了，IDE会自动帮你生成一些有用的代码，然后根据实际需要修改就行了，这里我还是一个个文件创建吧。

你可以从[这个网站](http://www.1001freefonts.com/)下载免费的字体文件(需要是`ttf`格式的)。

(1)新建文件`res/values/attrs_font_textview.xml`，其中定义一下我们的TextView的属性fontType，用来指明使用的字体。

```java
<resources>
    <declare-styleable name="FontTextView">
        <attr name="fontType" format="string"/>
    </declare-styleable>
</resources>
```

(2)新建自定义的FontTextView类

这个类继承自TextView类，没啥特别的，就是在调用完父类的构造函数之后执行`init()`方法设置对应的字体就好啦，关键在于如何得到xml文件中定义的fontType属性值的部分代码。

```
package hujiawei.xiaojian.view;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Typeface;
import android.util.AttributeSet;
import android.widget.TextView;

import hujiawei.xiaojian.R;
import hujiawei.xiaojian.util.FontManager;

public class FontTextView extends TextView {

    private String fontType = "shadow";

    public FontTextView(Context context) {
        super(context);
        init(null, 0);
    }

    public FontTextView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(attrs, 0);
    }

    public FontTextView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        init(attrs, defStyle);
    }

    private void init(AttributeSet attrs, int defStyle) {
        final TypedArray array = getContext().obtainStyledAttributes(
                attrs, R.styleable.FontTextView, defStyle, 0);

        fontType = array.getString(R.styleable.FontTextView_fontType);
        Typeface font = FontManager.getInstance(getContext().getAssets()).getFont("shadow");
        if (fontType.equalsIgnoreCase("bling")) {
            font = FontManager.getInstance(getContext().getAssets()).getFont("bling");
        } else if (fontType.equalsIgnoreCase("planet")) {
            font = FontManager.getInstance(getContext().getAssets()).getFont("planet");
        }
        setTypeface(font, Typeface.NORMAL);

        array.recycle();
    }

}
```

仔细看上面的代码你会发现一个FontManager类，这个类是个单例类，专门用来管理字体的，因为加载字体是比较费时的操作。

```
package hujiawei.xiaojian.util;

import android.content.res.AssetManager;
import android.graphics.Typeface;

import java.util.HashMap;
import java.util.Map;

public class FontManager {

    private static FontManager instance;
    private AssetManager assetManager;
    private Map<String, Typeface> fonts;

    private FontManager(AssetManager assetManager) {
        this.assetManager = assetManager;
        fonts = new HashMap<String, Typeface>();
    }

    public static FontManager getInstance(AssetManager assetManager) {
        if (instance == null) {
            instance = new FontManager(assetManager);
        }
        return instance;
    }

    public Typeface getFont(String asset) {
        if (fonts.containsKey(asset))
            return fonts.get(asset);

        String path = "fonts/" + asset + ".ttf";
        Typeface font = Typeface.createFromAsset(assetManager, path);
        fonts.put(asset, font);

        return font;
    }

}
```

(3)接着就是新建一个布局文件来测试下效果啦，下面的布局文件的显示效果就是本文开始的那个效果图。

```
<RelativeLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context="polaris.ui.PolarisActivity">

    <TextView
        android:id="@+id/textView"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="40dp"
        android:text="@string/hello_world"/>

    <hujiawei.xiaojian.view.FontTextView
        android:id="@+id/bling"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_below="@+id/textView"
        android:text="Bling Font"
        android:textSize="40dp"
        android:textColor="@android:color/holo_orange_dark"
        app:fontType="bling"/>

    <hujiawei.xiaojian.view.FontTextView
        android:id="@+id/planet"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_below="@+id/bling"
        android:text="Planet Font"
        android:textSize="40dp"
        android:textColor="@android:color/holo_blue_dark"
        app:fontType="planet"/>

    <hujiawei.xiaojian.view.FontTextView
        android:id="@+id/shadow"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_below="@+id/planet"
        android:text="Shadow Font"
        android:textSize="40dp"
        android:textColor="@android:color/holo_green_light"
        app:fontType="shadow"/>

</RelativeLayout>
```

OK，Enjoy! :-)
