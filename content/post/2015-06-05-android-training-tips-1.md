---
title: "Android Training Summary (1) Getting Started"
date: "2015-06-05"
categories: "android"
---
[Android Training](http://developer.android.com/training/index.html) 中Getting Started部分的阅读笔记 <!--more-->

最近打算把[Android Training](http://developer.android.com/training/index.html)中的文章都读一遍，然后摘录下其中某些内容，这些内容对我而言可能是我不知道或者知道得不具体或者我觉得很重要的内容，所以纯粹是个人的阅读摘要，以备后用，如果感兴趣可以读下。

### 第一部分 Getting Started

#### 1.Building Your First App
简单演示使用Android Studio创建和运行一个android项目

#### 2.Adding the Action Bar
添加Action Bar，给它设置样式等，可以参考以前的博文[Android ActionBar](/blog/2015/06/01/android-ui-1-actionbar/)

#### 3.Supporting Different Devices
如何支持不同的语言、屏幕大小、系统版本
[关于Android各个系统版本和屏幕大小的市场占有率情况](http://developer.android.com/about/dashboards/index.html)

#### 4.Managing the Activity Lifecycle

Activity的生命周期图

![image](/images/basic-lifecycle.png)

(1)处理好Activity的生命周期需要做到
Does not crash if the user receives a phone call or switches to another app while using your app.       
Does not consume valuable system resources when the user is not actively using it.      
Does not lose the user's progress if they leave your app and return to it at a later time.     
Does not crash or lose the user's progress when the screen rotates between landscape and portrait orientation.

(2)一种特殊的在调用`onDestroy`方法之前不调用`onPause`和`onStop`的情况
**Note: The system calls `onDestroy()`` after it has already called `onPause()` and `onStop()` in all situations except one: when you call `finish()` from within the `onCreate()` method. In some cases, such as when your activity operates as a temporary decision maker to launch another activity, you might call `finish()` from within `onCreate()` to destroy the activity. In this case, the system immediately calls `onDestroy()` without calling any of the other lifecycle methods.**

(3)在`onPause`回调函数中一般要做以下几件事
Stop animations or other ongoing actions that could consume CPU.      
Commit unsaved changes, but only if users expect such changes to be permanently saved when they leave (such as a draft email).       
Release system resources, such as broadcast receivers, handles to sensors (like GPS), or any resources that may affect battery life while your activity is paused and the user does not need them.

(4)几种典型的Activity先stop然后restart的情况
The user opens the Recent Apps window and switches from your app to another app. The activity in your app that's currently in the foreground is stopped. If the user returns to your app from the Home screen launcher icon or the Recent Apps window, the activity restarts.

The user performs an action in your app that starts a new activity. The current activity is stopped when the second activity is created. If the user then presses the Back button, the first activity is restarted.

The user receives a phone call while using your app on his or her phone.

(5)如果Activity是在已经stop之后被系统销毁了，那么当Activity重新进入的时候View组件的状态会被系统自动恢复，例如之前用户写在EditText中的文本，但是其他的数据信息并不会恢复，如果希望保存然后恢复其他数据请看(6)。
**Note: Even if the system destroys your activity while it's stopped, it still retains the state of the `View` objects (such as text in an `EditText`) in a `Bundle` (a blob of key-value pairs) and restores them if the user navigates back to the same instance of the activity (the next lesson talks more about using a `Bundle` to save other state data in case your activity is destroyed and recreated).**

(6)如果Activity是系统因为资源不够了而被系统杀死的话，系统在杀死Activity之前会调用`onSaveInstanceState()`方法使用键值对形式的Bundle将当前Activity中的某些重要数据保存起来，然后在Activity重建的时候调用`onRestoreInstanceState()`恢复数据。
**When your activity is destroyed because the user presses Back or the activity finishes itself, the system's concept of that Activity instance is gone forever because the behavior indicates the activity is no longer needed. However, if the system destroys the activity due to system constraints (rather than normal app behavior), then although the actual Activity instance is gone, the system remembers that it existed such that if the user navigates back to it, the system creates a new instance of the activity using a set of saved data that describes the state of the activity when it was destroyed. The saved data that the system uses to restore the previous state is called the "instance state" and is a collection of key-value pairs stored in a `Bundle` object.**

如果我们将数据恢复的代码片段放在`onCreat`方法中的话需要判断`Bundle`是否为空，但是如果我们将数据恢复的代码片段放在`onRestoreInstanceState`方法中的话就不用了，这个方法在`onStart`方法之后被调用。

```java
//1
@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState); // Always call the superclass first

    // Check whether we're recreating a previously destroyed instance
    if (savedInstanceState != null) {
        // Restore value of members from saved state
        mCurrentScore = savedInstanceState.getInt(STATE_SCORE);
        mCurrentLevel = savedInstanceState.getInt(STATE_LEVEL);
    } else {
        // Probably initialize members with default values for a new instance
    }
    ...
}

//2
public void onRestoreInstanceState(Bundle savedInstanceState) {
    // Always call the superclass so it can restore the view hierarchy
    super.onRestoreInstanceState(savedInstanceState);

    // Restore state members from saved instance
    mCurrentScore = savedInstanceState.getInt(STATE_SCORE);
    mCurrentLevel = savedInstanceState.getInt(STATE_LEVEL);
}
```

#### 5.Building a Dynamic UI with Fragments

Fragment可以认为是一个能在不同Activity中复用的“子Activity”，它有自己的生命周期，而且它的生命周期依赖于Activity的生命周期。
(1)如果要兼容Android低版本系统(例如Android 1.6)，那么需要继承Support Library中的Fragment；如果你的应用的最低系统版本是Android 3.0(API level=11)的话就没有必要了，直接使用Fragment即可，需要注意的是两个Fragment API在某些方法上有略微的区别。
(2)FragmentActivity是Support Library中用来支持Android 3.0之前系统的处理Fragment的特殊Activity，如果你的应用的最低系统版本是Android 3.0(API level=11)的话就直接使用Activity即可。

**Note: `FragmentActivity` is a special activity provided in the Support Library to handle fragments on system versions older than API level 11. If the lowest system version you support is API level 11 or higher, then you can use a regular `Activity`.**

(3)Fragment可以直接在XML中插入到Activity中，但是这样的话运行时就没有办法改变了，如下代码所示：

```
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:orientation="horizontal"
    android:layout_width="fill_parent"
    android:layout_height="fill_parent">

    <fragment android:name="com.example.android.fragments.HeadlinesFragment"
              android:id="@+id/headlines_fragment"
              android:layout_weight="1"
              android:layout_width="0dp"
              android:layout_height="match_parent" />

    <fragment android:name="com.example.android.fragments.ArticleFragment"
              android:id="@+id/article_fragment"
              android:layout_weight="2"
              android:layout_width="0dp"
              android:layout_height="match_parent" />

</LinearLayout>
```

(4)如果希望能够在运行时添加、修改或者删除Fragment的话，可以使用`FragmentManager`来管理Fragment，并使用`FragmentTransaction`来操作Fragment的变化。
添加Fragment的方式：

```
// Add the fragment to the 'fragment_container' FrameLayout
getSupportFragmentManager().beginTransaction().add(R.id.fragment_container, firstFragment).commit();
```

替换Fragment需要注意，如果希望用户能够在Fragment替换之后回退到之前的Fragment的话需要在FragmentTransaction提交之前调用`addToBackStack()`。

**Keep in mind that when you perform fragment transactions, such as replace or remove one, it's often appropriate to allow the user to navigate backward and "undo" the change. To allow the user to navigate backward through the fragment transactions, you must call `addToBackStack()` before you commit the FragmentTransaction.**

**Note: When you remove or replace a fragment and add the transaction to the back stack, the fragment that is removed is stopped (not destroyed). If the user navigates back to restore the fragment, it restarts. If you do not add the transaction to the back stack, then the fragment is destroyed when removed or replaced.**

**The addToBackStack() method takes an optional string parameter that specifies a unique name for the transaction. The name isn't needed unless you plan to perform advanced fragment operations using the FragmentManager.BackStackEntry APIs.**


```
// Create fragment and give it an argument specifying the article it should show
ArticleFragment newFragment = new ArticleFragment();
Bundle args = new Bundle();
args.putInt(ArticleFragment.ARG_POSITION, position);
newFragment.setArguments(args);

FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();

// Replace whatever is in the fragment_container view with this fragment,
// and add the transaction to the back stack so the user can navigate back
transaction.replace(R.id.fragment_container, newFragment);
transaction.addToBackStack(null);

// Commit the transaction
transaction.commit();
```

#### 6.Saving Data

(1)得到SharedPreference

一个SharedPreference实际上对应了一个文件，其中保存了一些键值对信息，SharedPreference提供了简便的方法来读取和写入键值对信息。

**`getSharedPreferences()` — Use this if you need multiple shared preference files identified by name, which you specify with the first parameter. You can call this from any Context in your app.**

**`getPreferences()` — Use this from an Activity if you need to use only one shared preference file for the activity. Because this retrieves a default shared preference file that belongs to the activity, you don't need to supply a name.**


```
//1
Context context = getActivity();
SharedPreferences sharedPref = context.getSharedPreferences(
        getString(R.string.preference_file_key), Context.MODE_PRIVATE);

//2
SharedPreferences sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
```

操作键值对

```
//write
SharedPreferences sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
SharedPreferences.Editor editor = sharedPref.edit();
editor.putInt(getString(R.string.saved_high_score), newHighScore);
editor.commit();

//read
SharedPreferences sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
int defaultValue = getResources().getInteger(R.string.saved_high_score_default);
long highScore = sharedPref.getInt(getString(R.string.saved_high_score), defaultValue);
```

(2)Saving Files
Android系统的内部存储和外部存储的区别

![image](/images/android_storage.png)

在Manifest文件中使用`android:installLocation`属性可以设置应用安装时的安装目的地。

(3)保存到内部存储
`getFilesDir()`: Returns a File representing an internal directory for your app.         
`getFilesDir()`得到应用在内部存储中的一个目录，路径一般是`/data/data/{package_name}/files`

`getCacheDir()`:Returns a File representing an internal directory for your app's temporary cache files. **Be sure to delete each file once it is no longer needed and implement a reasonable size limit for the amount of memory you use at any given time, such as 1MB. If the system begins running low on storage, it may delete your cache files without warning.**       
`getCacheDir()`得到应用在内部存储中的缓存目录，，路径一般是`/data/data/{package_name}/cache`。如果系统运行时内部存储不够了的话，可能会删除某些缓存文件，而且不会提醒。


(4)快捷方法`openFileOutput()`和`openFileInput()`以及`createTempFile()`

```
public File getTempFile(Context context, String url) {
    File file;
    try {
        String fileName = Uri.parse(url).getLastPathSegment();
        file = File.createTempFile(fileName, null, context.getCacheDir());
    catch (IOException e) {
        // Error while creating file
    }
    return file;
}
```

(5)保存到外部存储
首先要检查外部存储的当前状态，如果SD卡已经拔出或者外存已经挂载到PC上了的时候外存是不可用的。

```
/* Checks if external storage is available for read and write */
public boolean isExternalStorageWritable() {
    String state = Environment.getExternalStorageState();
    if (Environment.MEDIA_MOUNTED.equals(state)) {
        return true;
    }
    return false;
}

/* Checks if external storage is available to at least read */
public boolean isExternalStorageReadable() {
    String state = Environment.getExternalStorageState();
    if (Environment.MEDIA_MOUNTED.equals(state) ||
        Environment.MEDIA_MOUNTED_READ_ONLY.equals(state)) {
        return true;
    }
    return false;
}
```

`Public files`       
Files that should be freely available to other apps and to the user. When the user uninstalls your app, these files should remain available to the user. For example, photos captured by your app or other downloaded files.     
`Public files`是指外存中的公共目录，这些目录对任何应用和用户都可用，其中的文件在应用被卸载的时候是不会被删除的。

`Private files`      
Files that rightfully belong to your app and should be deleted when the user uninstalls your app. Although these files are technically accessible by the user and other apps because they are on the external storage, they are files that realistically don't provide value to the user outside your app. When the user uninstalls your app, the system deletes all files in your app's external private directory.For example, additional resources downloaded by your app or temporary media files.       
`Private files`是指外存中的应用的私有目录，当应用卸载的时候系统会删除该目录下的文件。

**一些内部存储和外部存储的路径的获取方式**

```
Log.e(TAG, "getFilesDir()=" + getFilesDir().getAbsolutePath());
//getFilesDir()=/data/data/hujiaweibujidao.polarisdemo/files

Log.e(TAG, "getCacheDir()=" + getCacheDir().getAbsolutePath());
//getCacheDir()=/data/data/hujiaweibujidao.polarisdemo/cache

Log.e(TAG, "getExternalStorageDirectory()=" + Environment.getExternalStorageDirectory().getAbsolutePath());
//getExternalStorageDirectory()=/storage/emulated/0

Log.e(TAG, "getExternalStoragePublicDirectory()=" + Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES).getAbsolutePath());
//getExternalStoragePublicDirectory()=/storage/emulated/0/Pictures

Log.e(TAG, "getExternalFilesDir()=" + this.getExternalFilesDir(Environment.DIRECTORY_PICTURES).getAbsolutePath());
//getExternalFilesDir()=/storage/emulated/0/Android/data/hujiaweibujidao.polarisdemo/files/Pictures

Log.e(TAG, "getExternalCacheDir()=" + this.getExternalCacheDir().getAbsolutePath());
//getExternalCacheDir()=/storage/emulated/0/Android/data/hujiaweibujidao.polarisdemo/cache
```

(6)使用API中的常量例如`DIRECTORY_PICTURES`来给目录命名，这样的话系统就会自动正确地识别目录内文件的格式

**Regardless of whether you use `getExternalStoragePublicDirectory()` for files that are shared or `getExternalFilesDir()` for files that are private to your app, it's important that you use directory names provided by API constants like `DIRECTORY_PICTURES`. These directory names ensure that the files are treated properly by the system. For instance, files saved in `DIRECTORY_RINGTONES` are categorized by the system media scanner as ringtones instead of music.**

(7)获取当前可用的存储空间大小和总共的存储空间大小的方法分别是`getFreeSpace()`和`getTotalSpace()`，如果你大概知道要保存的文件的大小你可以调用这些有用的方法判断空间是否足够，但是如果你不知道的话，那就只能尝试保存文件，如果空间不够的话会捕捉到`IOException`。此外，如果你要保存的文件的大小小于`getFreeSpace()`返回的大小也不一定能够成功保存文件。

**However, the system does not guarantee that you can write as many bytes as are indicated by getFreeSpace(). If the number returned is a few MB more than the size of the data you want to save, or if the file system is less than 90% full, then it's probably safe to proceed. Otherwise, you probably shouldn't write to storage.**

(8)删除文件

```
//1
myFile.delete();

//2
myContext.deleteFile(fileName);
```

当应用被卸载时，系统会删除下面的目录：(1)应用的内部存储；(2)应用使用`getExternalFilesDir()`方式保存的文件。需要注意的是，你需要自己处理删除`getCacheDir()`目录下的文件。

(9)保存数据到数据库中
[Saving Data in SQL Databases](http://developer.android.com/training/basics/data-storage/databases.html)

**更多的关于Android Storage的内容可以看[Storage Options](http://developer.android.com/guide/topics/data/data-storage.html)**

#### 7.Interacting with Other Apps

(1)Intent有显式和隐式两种，其中给隐式Intent设置参数的方式有下面几种不同的方式

```
//1.uri
Uri number = Uri.parse("tel:5551234");
Intent callIntent = new Intent(Intent.ACTION_DIAL, number);

// Map point based on address
Uri location = Uri.parse("geo:0,0?q=1600+Amphitheatre+Parkway,+Mountain+View,+California");
// Or map point based on latitude/longitude
// Uri location = Uri.parse("geo:37.422219,-122.08364?z=14"); // z param is zoom level
Intent mapIntent = new Intent(Intent.ACTION_VIEW, location);

Uri webpage = Uri.parse("http://www.android.com");
Intent webIntent = new Intent(Intent.ACTION_VIEW, webpage);

//2.putExtra
//Send an email with an attachment:
Intent emailIntent = new Intent(Intent.ACTION_SEND);
// The intent does not have a URI, so declare the "text/plain" MIME type
emailIntent.setType(HTTP.PLAIN_TEXT_TYPE);
emailIntent.putExtra(Intent.EXTRA_EMAIL, new String[] {"jon@example.com"}); // recipients
emailIntent.putExtra(Intent.EXTRA_SUBJECT, "Email subject");
emailIntent.putExtra(Intent.EXTRA_TEXT, "Email message text");
emailIntent.putExtra(Intent.EXTRA_STREAM, Uri.parse("content://path/to/email/attachment"));
// You can also attach multiple items by passing an ArrayList of Uris

//Create a calendar event:
Intent calendarIntent = new Intent(Intent.ACTION_INSERT, Events.CONTENT_URI);
Calendar beginTime = Calendar.getInstance().set(2012, 0, 19, 7, 30);
Calendar endTime = Calendar.getInstance().set(2012, 0, 19, 10, 30);
calendarIntent.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, beginTime.getTimeInMillis());
calendarIntent.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endTime.getTimeInMillis());
calendarIntent.putExtra(Events.TITLE, "Ninja class");
calendarIntent.putExtra(Events.EVENT_LOCATION, "Secret dojo");
```

(2)判断是否有应用能够接收这个Intent的方法`queryIntentActivities()`，如果没有应用能够接收而直接invoke这个Intent的话会导致应用崩溃的。

```
PackageManager packageManager = getPackageManager();
List activities = packageManager.queryIntentActivities(intent,
        PackageManager.MATCH_DEFAULT_ONLY);
boolean isIntentSafe = activities.size() > 0;
```

(3)如果有多个应用能够处理这个隐式Intent的话，一般`startActivity`的话会出现一个选择对话框。这里有两种情况：一种情况是，用户一般会选择某个默认的自己喜欢的应用来打开这类隐式Intent，例如使用Chrome来打开某个网址，而不是使用其他的浏览器；另一种情况是，用户每次都可能会选择某一个不同的应用来处理，例如分享内容，这次可能选择微博，下次可能选择微信，所以这种情况下需要使用`Intent.createChooser`。

```
//1
// Build the intent
Uri location = Uri.parse("geo:0,0?q=1600+Amphitheatre+Parkway,+Mountain+View,+California");
Intent mapIntent = new Intent(Intent.ACTION_VIEW, location);

// Verify it resolves
PackageManager packageManager = getPackageManager();
List<ResolveInfo> activities = packageManager.queryIntentActivities(mapIntent, 0);
boolean isIntentSafe = activities.size() > 0;

// Start an activity if it's safe
if (isIntentSafe) {
    startActivity(mapIntent);
}

//2
Intent intent = new Intent(Intent.ACTION_SEND);
...

// Always use string resources for UI text.
// This says something like "Share this photo with"
String title = getResources().getString(R.string.chooser_title);
// Create intent to show chooser
Intent chooser = Intent.createChooser(intent, title);

// Verify the intent will resolve to at least one activity
if (intent.resolveActivity(getPackageManager()) != null) {
    startActivity(chooser);
}
```

(4)添加Intent-Filter
如果希望其他的应用程序能够启动我们的Activity，那么我们需要给我们的Activity定义Intent-Filter，定义Intent-Filter一般是要设置action、data和category三个参数

![image](/images/intent_filter.png)

```
//demo 1
<activity android:name="ShareActivity">
    <intent-filter>
        <action android:name="android.intent.action.SEND"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <data android:mimeType="text/plain"/>
        <data android:mimeType="image/*"/>
    </intent-filter>
</activity>

//demo 2
<activity android:name="ShareActivity">
    <!-- filter for sending text; accepts SENDTO action with sms URI schemes -->
    <intent-filter>
        <action android:name="android.intent.action.SENDTO"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <data android:scheme="sms" />
        <data android:scheme="smsto" />
    </intent-filter>
    <!-- filter for sending text or images; accepts SEND action and text or image data -->
    <intent-filter>
        <action android:name="android.intent.action.SEND"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <data android:mimeType="image/*"/>
        <data android:mimeType="text/plain"/>
    </intent-filter>
</activity>
```

启动另一个Activity之后默认返回的结果码是`RESULT_CANCELED`，此外，我们没有必要查看Activity是通过`startActivity()`还是通过`startActivityForResult()`启动的，只需要设置结果即可，如果是通过`startActivityForResult()`启动的Activity的话，系统会将结果传递给原来的Activity，否则结果就会被忽略。

**Note: There's no need to check whether your activity was started with `startActivity()` or `startActivityForResult()`. Simply call `setResult()` if the intent that started your activity might expect a result. If the originating activity had called `startActivityForResult()`, then the system delivers it the result you supply to `setResult()`; otherwise, the result is ignored.**
