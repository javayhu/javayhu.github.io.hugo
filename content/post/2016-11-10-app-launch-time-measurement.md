---
date: 2016-11-10T16:46:33+08:00
title: App Launch Time Measurement
tags: ["android"]
---
本文记录下分析应用启动时间的总结。 <!--more-->

关于应用启动时间测量的分析已经有不少不错的文章做了总结，下面是比较好的几篇：  
1.[Android性能优化典范-第6季](http://hukai.me/android-performance-patterns-season-6/)  
2.[测量Activity 的启动时间](http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2015/1101/3647.html)  
3.[Activity到底是什么时候显示到屏幕上的呢](http://mp.weixin.qq.com/s?__biz=MzIwOTQ1MjAwMg==&mid=2247483771&idx=1&sn=fc2a36bddd29a0bb9d6512ba7e9b71ad&chksm=9772eff6a00566e0424e3bccfcf61df5bff709739ece80c6641ca6cf742e9949c27f29bc48f0&mpshare=1&scene=1&srcid=1008ksnBumwlSEhlQl3Qe45O#rd)

上面的每篇都各有特色，我这篇也只是在他们的分析上记录下自己学习和研究过程的总结。  

### 1.查看display time

从Android KitKat版本开始，Logcat中会输出从程序启动到Activity显示到屏幕上所花费的时间，这个时间包含了进程启动的时间，比较适合测量程序的启动时间。

```
I ActivityManager: Displayed com.meizu.flyme.applaunch/.MainActivity: +379ms
//厂商定制过的OS可能会有些不同，例如FlymeOS中的输出
I ActivityManager: [AppLaunch] Displayed Displayed com.meizu.flyme.applaunch/.MainActivity: +480ms
```

上面信息的打印来自`ActivityRecord`类的`reportLaunchTimeLocked`方法，它的实现如下所示，整个过程和下面的fully drawn time类似，我们在下面会介绍它的详细实现过程。

![img](/images/reportLaunchTimeLocked.png)

除了看Logcat之外，我们还有其他的方式来查看上面的时间，例如使用`am start`的方式查看`TotalTime`

```
$ adb shell am start -W com.meizu.flyme.applaunch/.MainActivity
Starting: Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER] cmp=com.meizu.flyme.applaunch/.MainActivity }
Status: ok
Activity: com.meizu.flyme.applaunch/.MainActivity
ThisTime: 479
TotalTime: 479
WaitTime: 499
Complete
```

或者查看EventLog的方法来查看`am_activity_launch_time`

```
$adb shell logcat -b events
... I am_activity_launch_time: [0,200792421,com.meizu.flyme.applaunch/.MainActivity,478,478]
```

### 2.查看fully drawn time

通常应用启动的时候都会以异步加载的方式来加快应用的启动速度，但是上面的display time是不包含异步加载所耗费的时间，所以为了准确衡量应用的启动时间，我们可以在异步加载完毕之后调用`Activity.reportFullyDrawn()`方法来告诉系统加载完成，以便获取整个应用启动的耗时。

查看方式和输出结果类似上面的查看display time的过程

```
//Logcat中的输出
I ActivityManager: Fully drawn com.meizu.flyme.applaunch/.MainActivity: +2s319ms
//EventLog中的输出
... I am_activity_fully_drawn_time: [0,200792421,com.meizu.flyme.applaunch/.MainActivity,478,478]
```

下面是`Activity.reportFullyDrawn()`方法的实现，从注释来看，这个方法主要是用来帮助我们测量应用的启动时间，因为系统最多只能确定应用的window第一次绘制和显示的时间点，不能确定应用真正加载完成处于可以使用状态的时间点，所以需要开发者来显式调用这个方法以通知系统应用已经启动完毕可以使用了。

```java
/**
 * Report to the system that your app is now fully drawn, purely for diagnostic
 * purposes (calling it does not impact the visible behavior of the activity).
 * This is only used to help instrument application launch times, so that the
 * app can report when it is fully in a usable state; without this, the only thing
 * the system itself can determine is the point at which the activity's window
 * is <em>first</em> drawn and displayed.  To participate in app launch time
 * measurement, you should always call this method after first launch (when
 * {@link #onCreate(android.os.Bundle)} is called), at the point where you have
 * entirely drawn your UI and populated with all of the significant data.  You
 * can safely call this method any time after first launch as well, in which case
 * it will simply be ignored.
 */
public void reportFullyDrawn() {
    if (mDoReportFullyDrawn) {
        mDoReportFullyDrawn = false;
        try {
            ActivityManagerNative.getDefault().reportActivityFullyDrawn(mToken);
        } catch (RemoteException e) {
        }
    }
}
```

其中的`ActivityManagerNative`的`reportActivityFullyDrawn`方法会经过Binder调用到AMS的`reportActivityFullyDrawn`方法，最终会调用到`ActivityRecord`的`reportFullyDrawnLocked`方法，内容与`reportLaunchTimeLocked`方法类似。

```java
public void reportFullyDrawnLocked() {
    final long curTime = SystemClock.uptimeMillis();
    if (displayStartTime != 0) {
        reportLaunchTimeLocked(curTime);
    }
    final ActivityStack stack = task.stack;
    if (fullyDrawnStartTime != 0 && stack != null) {
        final long thisTime = curTime - fullyDrawnStartTime;
        final long totalTime = stack.mFullyDrawnStartTime != 0
                ? (curTime - stack.mFullyDrawnStartTime) : thisTime;
        if (SHOW_ACTIVITY_START_TIME) {
            Trace.asyncTraceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER, "drawing", 0);
            EventLog.writeEvent(EventLogTags.AM_ACTIVITY_FULLY_DRAWN_TIME,
                    userId, System.identityHashCode(this), shortComponentName,
                    thisTime, totalTime);//EventLog中的输出
            StringBuilder sb = service.mStringBuilder;
            sb.setLength(0);
            sb.append("Fully drawn ");
            sb.append(shortComponentName);
            sb.append(": ");
            TimeUtils.formatDuration(thisTime, sb);
            if (thisTime != totalTime) {
                sb.append(" (total ");
                TimeUtils.formatDuration(totalTime, sb);
                sb.append(")");
            }
            Log.i(TAG, sb.toString());//Logcat中的输出
        }
        if (totalTime > 0) {
            //service.mUsageStatsService.noteFullyDrawnTime(realActivity, (int) totalTime);
        }
        stack.mFullyDrawnStartTime = 0;
    }
    fullyDrawnStartTime = 0;
}
```

上面代码中有个起始时间(`fullyDrawnStartTime`)，它是在哪里设置的呢？它是在`ActivityStack`的`setLaunchTime`方法中设置的。  
**注：下面代码中的`Trace.asyncTraceBegin`和`Trace.asyncTraceEnd`实际上会调用到系统中`atrace`的`async_start`和`async_stop`(可以通过`adb shell atrace -h`查看到这两个命令的选项)。**

```java
void setLaunchTime(ActivityRecord r) {
    if (r.displayStartTime == 0) {
        r.fullyDrawnStartTime = r.displayStartTime = SystemClock.uptimeMillis();
        if (mLaunchStartTime == 0) {
            startLaunchTraces(r.packageName);
            mLaunchStartTime = mFullyDrawnStartTime = r.displayStartTime;
        }
    } else if (mLaunchStartTime == 0) {
        startLaunchTraces(r.packageName);
        mLaunchStartTime = mFullyDrawnStartTime = SystemClock.uptimeMillis();
    }
}

private void startLaunchTraces(String packageName) {
    if (mFullyDrawnStartTime != 0)  {
        Trace.asyncTraceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER, "drawing", 0);
    }
    Trace.asyncTraceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "launching: " + packageName, 0);
    Trace.asyncTraceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "drawing", 0);
}

private void stopFullyDrawnTraceIfNeeded() {
    if (mFullyDrawnStartTime != 0 && mLaunchStartTime == 0) {
        Trace.asyncTraceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER, "drawing", 0);
        mFullyDrawnStartTime = 0;
    }
}
```

那`setLaunchTime`方法是何时调用的呢？它是在`ActivityStackSupervisor.startSpecificActivityLocked`方法中调用的！  
`startSpecificActivityLocked`方法中会判断应用进程是否启动了，如果没有启动就调用`startProcessLocked`方法来启动进程，内部会调用`Process`类的`start`方法来启动新进程；否则调用`realStartActivityLocked`方法继续执行，这个方法会调用`scheduleLaunchActivity`方法，内部将会调用`Activity`的`onCreate`方法，开始Activity的生命周期。


```java
void startSpecificActivityLocked(ActivityRecord r, boolean andResume, boolean checkConfig) {
    // Is this activity's application already running?
    ProcessRecord app = mService.getProcessRecordLocked(r.processName,
            r.info.applicationInfo.uid, true);

    r.task.stack.setLaunchTime(r);//在这里设置launch start time

    if (app != null && app.thread != null) {
        try {
            if ((r.info.flags&ActivityInfo.FLAG_MULTIPROCESS) == 0 || !"android".equals(r.info.packageName)) {
                // Don't add this if it is a platform component that is marked
                // to run in multiple processes, because this is actually
                // part of the framework so doesn't make sense to track as a
                // separate apk in the process.
                app.addPackage(r.info.packageName, r.info.applicationInfo.versionCode, mService.mProcessStats);
            }
            realStartActivityLocked(r, app, andResume, checkConfig);
            return;
        } catch (RemoteException e) {
            Slog.w(TAG, "Exception when starting activity " + r.intent.getComponent().flattenToShortString(), e);
        }

        // If a dead object exception was thrown -- fall through to restart the application.
    }

    mService.startProcessLocked(r.processName, r.info.applicationInfo, true, 0,
            "activity", r.intent.getComponent(), false, false, true);
}
```

还有一种方式是录屏然后测量，和使用高速相机录像然后测量差不多，由于比较麻烦，此处不表。
