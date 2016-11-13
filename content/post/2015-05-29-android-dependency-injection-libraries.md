---
title: "Android Dependency Injection Libraries"
date: "2015-05-31"
tags: ["android"]
---
本文总结并对比了三种Android依赖注入库：Butter Knife、RoboGuice、Android Annotations的使用 <!--more-->

最近在研究一个开源项目[Coding-Android Client](https://coding.net/u/coding/p/Coding-Android/git)，即Coding的安卓客户端，目前只看了小部分，但是感觉写得还是很赞的，学习到了很多的知识。因为这个项目是使用了Android Annotations的，看的时候虽然大致能明白各个注解是什么意思，但是感觉还是有必要详细了解下Android的各个依赖注入类库的功能特性和使用方式，于是便有了这篇总结。

目前而言，Android依赖注入类库比较火的主要有[Butter Knife](http://jakewharton.github.io/butterknife/)，[RoboGuice](https://github.com/roboguice/roboguice)，[Android Annotations](https://github.com/excilys/androidannotations)。(这里不考虑Dragger)

下面的导入方式都是指在使用Gradle的情况下进行的。

####1.Butter Knife

导入方式：`compile 'com.jakewharton:butterknife:6.1.0'`

毫无疑问，Butter Knife是这三者当中功能最简单的，详情可以查看[这里](http://jakewharton.github.io/butterknife/)。它主要功能就是注入View组件，使用方式如下：

```java
class ExampleActivity extends Activity {
  @InjectView(R.id.title) TextView title;
  @InjectView(R.id.subtitle) TextView subtitle;
  @InjectView(R.id.footer) TextView footer;

  @Override public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.simple_activity);
    ButterKnife.inject(this);
    // TODO Use "injected" views...
  }
}
```

需要注意的是，它需要加上`ButterKnife.inject(this);`这句去执行注入操作。对于非Activity中可以使用`ButterKnife.inject(this, view);`来进行注入操作。

```
public class FancyFragment extends Fragment {
  @InjectView(R.id.button1) Button button1;
  @InjectView(R.id.button2) Button button2;

  @Override public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
    View view = inflater.inflate(R.layout.fancy_fragment, container, false);
    ButterKnife.inject(this, view);
    // TODO Use "injected" views...
    return view;
  }
}
```

对于事件监听的注入，Butter Knife也提供了下面几种方式来操作：

```
//Listeners can also automatically be configured onto methods.

@OnClick(R.id.submit)
public void submit(View view) {
  // TODO submit data to server...
}

//All arguments to the listener method are optional.

@OnClick(R.id.submit)
public void submit() {
  // TODO submit data to server...
}

//Define a specific type and it will automatically be cast.

@OnClick(R.id.submit)
public void sayHi(Button button) {
  button.setText("Hello!");
}

//Specify multiple IDs in a single binding for common event handling.

@OnClick({ R.id.door1, R.id.door2, R.id.door3 })
public void pickDoor(DoorView door) {
  if (door.hasPrizeBehind()) {
    Toast.makeText(this, "You win!", LENGTH_SHORT).show();
  } else {
    Toast.makeText(this, "Try again", LENGTH_SHORT).show();
  }
}
```

####2.RoboGuice

导入方式：

```
compile 'org.roboguice:roboguice:3.+'
provided 'org.roboguice:roboblender:3.+'
```

大名鼎鼎的RoboGuice是Google的产物，功能自然是相当丰富的啦，基本上能使用注解的地方都支持了。基本的View注入、Resource注入、Service注入操作都很简单，代码如下所示：

```
    @ContentView(R.layout.main)
    class RoboWay extends RoboActivity {
        @InjectView(R.id.name)             TextView name;
        @InjectView(R.id.thumbnail)        ImageView thumbnail;
        @InjectResource(R.drawable.icon)   Drawable icon;
        @InjectResource(R.string.app_name) String myName;
        @Inject                            LocationManager loc;

        public void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            name.setText( "Hello, " + myName );
        }
    }
```

注意，它的重点在于需要继承自`Robo*`组件，例如`Robo*Activities`, `RoboService`、`RoboIntentService`和`RoboContentProvider`等等。除此之外呢，RoboGuice渗透到开发中的很多方面，例如它支持

(1)[在TestCase中使用注入](https://github.com/roboguice/roboguice/wiki/Your-First-Testcase)     
(2)[在自定义的View中使用注入](https://github.com/roboguice/roboguice/wiki/Your-First-Injection-into-a-Custom-View-class)      
(3)[在context-based events中使用注入](https://github.com/roboguice/roboguice/wiki/Using-Events-in-your-RoboGuice-application)       

当然啦，这自然不是RoboGuice最大的亮点啦，我个人认为最大的亮点是对POJO的注入，就像Spring的依赖注入一样简单才行嘛。如下所示，`Foo`类的对象`foo`会被自动注入，所以我们就能够直接使用。当然啦，其实RoboGuice是通过调用了`Foo`的默认构造函数来得到这个`foo`实例的，不过RoboGuice还可以自定义使用哪个构造函数来生成这个注入的对象。

```
class MyActivity extends RoboActivity {
    @Inject Foo foo; // this will basically call new Foo();
}
```

除了上面的POJO注入之外，RoboGuice还提供了两个非常实用的注解`@Singleton`和`@ContextSingleton`。顾名思义，前者是在整个应用的生命周期中是单例，而后者是在对应的Context的生命周期中是单例。**在使用的时候一定要考虑好对象的生命周期，因为使用不当的话容易导致内存泄露。**

使用`@Singleton`的情况：

```
class MyActivity extends RoboActivity {
    @Inject Foo foo; // this will basically call new Foo();
}

@Singleton //a single instance of Foo is now used though the whole app
class Foo {
}

//In that case :
new MyRoboActivity().foo = new MyRoboActivity().foo
```

使用`@ContextSingleton`的情况：

```
@ContextSingleton //a single instance of Foo is now used per context
class Foo {
}

public MyActivity extends RoboActivity {
  @Inject Foo foo;
  @Inject Bar bar;
}

public class Foo {
  @Inject Bar bar;
}

@ContextSingleton
public class Bar {
}

//In that case :
new MyRoboActivity().foo != new MyRoboActivity().foo
MyRoboActivity a = new MyRoboActivity();
a.bar == a.foo.bar
```

**RoboGuice 3.0添加了一个新的作用域`FragmentSingleton`**

```
public MyFragment extends RoboFragment {
  @Inject Foo foo;
  @Inject Bar bar;
}

public class Foo {
  @Inject Bar bar;
}

@FragmentSingleton
public class Bar {
}

//In that case:
myFragment.bar = myFragment.foo.bar
new MyFragment().bar = new MyFragment().foo.bar
```

**关于RoboGuice和Butter Knife的对比**

图片来源：[dependency-injection-roboguice-butterknife](http://java.dzone.com/articles/dependency-injection-roboguice)

![image](/images/roboguice-butterknife.png)

**实现原理**

RoboGuice是在运行时通过反射来实现的，而Butter Knife是在编译的时候就将代码转换好了的。下面的Android Annotations也是在编译的时候完成的，只不过对于每个采用注解增强了的组件类`MyClass`都会生成一个对应的组件类`MyClass_`。

####3.Android Annotations

导入方式：[Building-Project-Gradle](https://github.com/excilys/androidannotations/wiki/Building-Project-Gradle)

```
buildscript {
    repositories {
      mavenCentral()
    }
    dependencies {
        // replace with the current version of the Android plugin
        classpath 'com.android.tools.build:gradle:1.2.2'
        // replace with the current version of the android-apt plugin
        classpath 'com.neenbedankt.gradle.plugins:android-apt:1.4'
    }
}

repositories {
    mavenCentral()
    mavenLocal()
}

apply plugin: 'com.android.application'
apply plugin: 'android-apt'
def AAVersion = 'XXX'

dependencies {
    apt "org.androidannotations:androidannotations:$AAVersion"
    compile "org.androidannotations:androidannotations-api:$AAVersion"
}

apt {
    arguments {
        androidManifestFile variant.outputs[0].processResources.manifestFile
        // if you have multiple outputs (when using splits), you may want to have other index than 0

        // You can set optional annotation processing options here, like these commented options:
        // logLevel 'INFO'
        // logFile '/var/log/aa.log'
    }
}

android {
    compileSdkVersion 22
    buildToolsVersion "22.0.1"

    defaultConfig {
        minSdkVersion 9
        targetSdkVersion 22
    }
}
```

很明显，Android Annotations的导入是最麻烦的，但是好在导入操作只是操作一次嘛，将就一下吧。从上面可以看出，Android Annotations是通过`apt`工具在编译时将`MyClass`转换成`MyClass_`的。此外，对于`apt`工具编译的过程还可以设置很多的参数，[详细参数列表参见这里](https://github.com/excilys/androidannotations/wiki/CustomizeAnnotationProcessing)。

对于Android Annotations的功能，它基本上覆盖了Butter Knife和RoboGuice中的所有主要功能，[详细的功能列表参见这里](https://github.com/excilys/androidannotations/wiki/Cookbook)。下面是一个代码示例，实在是太强大了，大家感受下：

```
import java.util.Date;
import java.util.concurrent.TimeUnit;

import org.androidannotations.annotations.Background;
import org.androidannotations.annotations.Click;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.LongClick;
import org.androidannotations.annotations.SystemService;
import org.androidannotations.annotations.Touch;
import org.androidannotations.annotations.Transactional;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.annotations.res.BooleanRes;
import org.androidannotations.annotations.res.ColorRes;
import org.androidannotations.annotations.res.StringRes;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

@EActivity(R.layout.my_activity)
public class MyActivity extends Activity {

	@ViewById
	EditText myEditText;

	@ViewById(R.id.myTextView)
	TextView textView;

	@StringRes(R.string.hello)
	String helloFormat;

	@ColorRes
	int androidColor;

	@BooleanRes
	boolean someBoolean;

	@SystemService
	NotificationManager notificationManager;

	@SystemService
	WindowManager windowManager;

	/**
	 * AndroidAnnotations gracefully handles support for onBackPressed, whether you use ECLAIR (2.0), or pre ECLAIR android version.
	 */
	public void onBackPressed() {
		Toast.makeText(this, "Back key pressed!", Toast.LENGTH_SHORT).show();
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		// windowManager should not be null
		windowManager.getDefaultDisplay();
		requestWindowFeature(Window.FEATURE_INDETERMINATE_PROGRESS);
	}

	@Click
	void myButtonClicked() {
		String name = myEditText.getText().toString();
		setProgressBarIndeterminateVisibility(true);
		someBackgroundWork(name, 5);
	}

	@Background
	void someBackgroundWork(String name, long timeToDoSomeLongComputation) {
		try {
			TimeUnit.SECONDS.sleep(timeToDoSomeLongComputation);
		} catch (InterruptedException e) {
		}

		String message = String.format(helloFormat, name);

		updateUi(message, androidColor);

		showNotificationsDelayed();
	}

	@UiThread
	void updateUi(String message, int color) {
		setProgressBarIndeterminateVisibility(false);
		textView.setText(message);
		textView.setTextColor(color);
	}

	@UiThread(delay = 2000)
	void showNotificationsDelayed() {
		Notification notification = new Notification(R.drawable.icon, "Hello !", 0);
		PendingIntent contentIntent = PendingIntent.getActivity(this, 0, new Intent(), 0);
		notification.setLatestEventInfo(getApplicationContext(), "My notification", "Hello World!", contentIntent);
		notificationManager.notify(1, notification);
	}

	@LongClick
	void startExtraActivity() {
		Intent intent = ActivityWithExtra_.intent(this).myDate(new Date()).myMessage("hello !").get();
		intent.putExtra(ActivityWithExtra.MY_INT_EXTRA, 42);
		startActivity(intent);
	}

	@Click
	void startListActivity(View v) {
		startActivity(new Intent(this, MyListActivity_.class));
	}

	@Touch
	void myTextView(MotionEvent event) {
		Log.d("MyActivity", "myTextView was touched!");
	}

	@Transactional
	int transactionalMethod(SQLiteDatabase db, int someParam) {
		return 42;
	}

}
```

**How it works?**

对于下面的使用`E*`(Enhance)注解的组件类，AA(Android Annotations)会在不同的源码目录下的相同包下生成一个对应的组件类。

```
package com.some.company;
@EActivity
public class MyActivity extends Activity {
  // ...
}

//自动生成下面的类

package com.some.company;
public final class MyActivity_ extends MyActivity {
  // ...
}
```

当我们在`AndroidManifest.xml`文件中注册Activity的时候需要注册后者

```
<activity android:name=".MyListActivity_" />
```

因为组件类变了，所以AA还提供了一套机制供开发者来构建Intent来实现组件跳转。

```
// Starting the activity
MyListActivity_.intent(context).start();

// Building an intent from the activity
Intent intent = MyListActivity_.intent(context).get();

// You can provide flags
MyListActivity_.intent(context).flags(FLAG_ACTIVITY_CLEAR_TOP).start();

// You can even provide extras defined with @Extra in the activity
MyListActivity_.intent(context).myDateExtra(someDate).start();

// You can also use the startActivityForResult() equivalent
MyListActivity_.intent(context).startForResult();
```

同样的，对于启动和绑定Service也有类似的机制

```
// Starting the service
MyService_.intent(context).start();

// Building an intent from the activity
Intent intent = MyService_.intent(context).build();

// You can provide flags
MyService_.intent(context).flags(Intent.FLAG_GRANT_READ_URI_PERMISSION).start();
```

Android Annotations其实还提供了很多其他的功能，例如它还能实现简单的Rest API、能注入选项菜单、能处理SQLite Transactions等等，需要了解的请看Android Annotations的详细文档吧。

OK，关于Android的依赖注入类库就介绍到这里吧，开发时具体选择哪个因人而异，也因项目而异，各有各的特点。Enjoy it！
