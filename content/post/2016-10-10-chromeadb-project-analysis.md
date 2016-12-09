---
title: ChromeADB Project Analysis
tags: ["android"]
date: "2016-10-10"
---
本文记录的是chromeadb项目的源码阅读总结。 <!--more-->

chromeadb项目源码：[https://github.com/importre/chromeadb](https://github.com/importre/chromeadb)  
chromeadb工具的本质就是利用adb命令以可视化的方式提供了一些简便操作和数据查看的功能。

![img](/images/chromeadb.png)

从该项目的目前提交记录以及[issue](https://github.com/importre/chromeadb/issues/12)来看，这个项目已经被放弃了，因为Google的Chrome浏览器未来将不支持Chrome扩展应用。此外，项目源码用的是Angular JS来开发的，我并不是很熟悉，所以主要是阅读下源码理解其大致的实现流程。要体验ChromeADB的MousePad功能还需要安装一个应用[chromeadb_for_android](https://github.com/importre/chromeadb_for_android)，这个应用我们也会稍微介绍一下。

### 1.源码结构
1.1 项目根目录是package.json、Gruntfile.js、bower.json等相关说明和依赖管理文件；  
1.2 test目录下是测试代码；  
1.3 src目录下是核心源码，其中assets目录是资源文件夹，里面都是图片；styles目录是样式文件`chromeadb.css`；views目录是各个子界面的模板页面，例如`packages.html`、`controller.html`等；scripts目录是控制脚本，例如`chromeadb.js`、`controllers.js`等。  

### 2.核心文件及代码分析
**2.1 index.html**    
控制应用的主界面布局，界面顶部显示设备连接的操作，中间左侧显示设备列表和设备信息，中间右侧显示packages、processes、memory以及disk等信息，界面底部显示chromeadb的github地址。

```html
<div>
    <ul class="nav nav-pills nav-justified" id="mytab">
        <li>
            <a href="#packages" data-toggle="tab"
               ng-click="loadPackages(devInfo.serial);">Packages</a>
        </li>
        <li>
            <a href="#controller" data-toggle="tab"
               ng-click="initMousePad(devInfo.serial);">Controller</a>
        </li>
        <li>
            <a href="#processes" data-toggle="tab"
               ng-click="loadProcessList(devInfo.serial);">Process List</a>
        </li>
        <li>
            <a href="#meminfo" data-toggle="tab"
               ng-click="loadMemInfo(devInfo.serial);">App Memory Info</a>
        </li>
        <li>
            <a href="#diskspace" data-toggle="tab"
               ng-click="loadDiskSpace(devInfo.serial);">Disk Space</a>
        </li>
    </ul>
</div>
```

**2.2 utils.js**  
定义一些通用的方法以供其他地方调用，例如services.js中就利用了这些方法来转换数据。

```js
/* exported arrayBufferToString */
/* exported arrayBufferToBinaryString */
/* exported stringToArrayBuffer */
/* exported newZeroArray */
/* exported getChartId */
/* exported integerToArrayBuffer */

function arrayBufferToString(buf, callback) {
  var b = new Blob([new Uint8Array(buf)]);
  var f = new FileReader();
  f.onload = function (e) {
    callback(e.target.result);
  };
  f.readAsText(b);
}

function arrayBufferToBinaryString(buf, callback) {
  var b = new Blob([new Uint8Array(buf)]);
  var f = new FileReader();
  f.onload = function (e) {
    callback(e.target.result);
  };
  f.readAsBinaryString(b);
}
```

**2.3 background.js**  
应用启动时的初始化，应用是从这里开始的。

```js
chrome.app.runtime.onLaunched.addListener(function () {
  chrome.app.window.create('../index.html', {
    minWidth: 800,
    minHeight: 600,
    width: 1280,
    height: 800
  });
});
```

**2.4 chromeadb.js**  
控制转发中心，点击不同的tab显示不同的html模板文件所在的界面，这里创建了chromeADB这个module。

```js
var adb = angular.module('chromeADB', ['ngRoute', 'ngSanitize']);

adb.config(function ($routeProvider) {//配置url路由控制转发
  $routeProvider
    .when('/', {
      redirectTo: '/packages'
    })
    .when('/packages', {
      templateUrl: chrome.runtime.getURL('../views/packages.html')
    })
    .when('/controller', {
      templateUrl: chrome.runtime.getURL('../views/controller.html')
    })
    .when('/processes', {
      templateUrl: chrome.runtime.getURL('../views/processes.html')
    })
    .when('/meminfo', {
      templateUrl: chrome.runtime.getURL('../views/meminfo.html')
    })
    .when('/diskspace', {
      templateUrl: chrome.runtime.getURL('../views/diskspace.html')
    });
});
```

**2.5  chrome.js**  
主要有三个初始化方法，这里会初始化chrome.socket，后面的SocketService会用到。这里还初始化了初始化ChromeRuntime，这个在上面的路由转发中用到了。

```js
//initCmdToResp(); //三个初始化方法
//initChromeSocket(chrome);
//initChromeRuntime(chrome);

function initCmdToResp() {
  cmdToResp = {
    '000ehost:devices-l': ['OKAY', '005B',
        '048233d1d151e3cc device usb:1A120000 product:aosp_mako ' +
        'model:AOSP_on_Mako device:mako'],
    '001fhost:transport:048233d1d151e3cc': ['OKAY'],
    '0016shell:pm list packages': ['OKAY',
      'package:com.android.settings\npackage:com.android.musicfx'],
    '0015shell:dumpsys meminfo': ['OKAY', 'OKAY',
        'Applications Memory Usage (kB):\n' +
        'Uptime: 95848872 Realtime: 211090246\n\nTotal PSS by process:\n' +
        '71959 kB: com.google.android.googlequicksearchbox (pid 892 / activities)\n' +
        '71580 kB: com.android.chrome (pid 7876 / activities)']
  };
}

function initChromeSocket(chrome) {//初始化chrome.socket
  if (chrome.socket) {
    return;
  }

  chrome.socket = {
    create: function (type, options, callback) {
      var createInfo = {
        'socketId': 10
      };

      window.setTimeout(function () {
        callback(createInfo);
      }, timeoutDelay);
    },

    destroy: function (socketId) {
    },

    connect: function (socketId, hostname, port, callback) {
      var result = 1;
      window.setTimeout(function () {
        callback(result);
      }, timeoutDelay);
    },

    read: function (socketId, bufferSize, callback) {
      window.setTimeout(function () {
        var resp = cmdToResp[curCmd];
        if (resp) {
          resp = cmdToResp[curCmd].splice(0, 1)[0];
        }
        if (typeof resp === 'undefined') {
          initCmdToResp();
        }
        stringToArrayBuffer(resp, function (bytes) {
          var readInfo = {
            'resultCode': resp ? 1 : 0,
            'data': bytes
          };
          callback(readInfo);
        });
      }, timeoutDelay);
    },

    write: function (socketId, data, callback) {
      curCmd = data;
      var writeInfo = {
        bytesWritten: data.length
      };
      window.setTimeout(function () {
        callback(writeInfo);
      }, timeoutDelay);
    }
  };

  window.arrayBufferToString = function (buf, callback) {
    callback(buf);
  };

  window.stringToArrayBuffer = function (str, callback) {
    callback(str);
  };
}

function initChromeRuntime(chrome) {//初始化ChromeRuntime
  if (!chrome.runtime) {
    return;
  }

  if (!chrome.runtime.getURL) {
    chrome.runtime.getURL = function (url) {
      return url;
    };
  }
}
```

**2.6 parser.js**  
主要是利用正则表达式来提供一些解析adb命令返回结果的方法

```js
/* exported parseProcessList */
/* exported parseDeviceInfoList */
/* exported parsePackageList */
/* exported makeCommand */
/* exported parseMemInfo */
/* exported parsePackageMemInfo */
/* exported parseDiskSpace */
/* exported parseResolution */

/**
 * Parses the result of $scope.loadPackages().
 *
 * @param data
 * @returns {Array}
 */
function parsePackageList(data) {//解析包列表
  var lines = data.trim().split('\n');

  for (var i = 0; i < lines.length; i++) {
    lines[i] = lines[i].replace(/^package:/, '').trim();
  }

  return lines;
}
```

**2.7 services.js**  
利用前面初始化好的chrome.socket来建立一个socketService，这个service负责和指定的host和port进行连接并提供数据读写服务的功能，这里的host和port是指adb-server的host和port，所以一般拿手机连接PC的话，这里host和port通常分别就是127.0.0.1和5037。

```js
  function connect(createInfo, host, port) {//建立连接
    var defer = $q.defer();

    if (typeof port !== 'number') {
      port = parseInt(port, 10);
    }

    chrome.socket.connect(createInfo.socketId, host, port, function (result) {
      if (result >= 0) {
        $rootScope.$apply(function () {
          defer.resolve(createInfo);
        });
      } else {
        chrome.socket.destroy(createInfo.socketId);
        defer.reject(createInfo);
      }
    });

    return defer.promise;
  }

  function write(createInfo, str) {//写
    var defer = $q.defer();

    stringToArrayBuffer(str, function (bytes) {
      writeBytes(createInfo, bytes)
        .then(function (createInfo) {
          defer.resolve(createInfo);
        });
    });

    return defer.promise;
  }

  function read(createInfo, size) {//读
    var defer = $q.defer();

    chrome.socket.read(createInfo.socketId, size, function (readInfo) {
      if (readInfo.resultCode > 0) {
        // console.log(readInfo);
        arrayBufferToString(readInfo.data, function (str) {
          $rootScope.$apply(function () {
            var param = {
              createInfo: createInfo,
              data: str
            };
            defer.resolve(param);
          });
        });
      } else {
        defer.reject(readInfo);
      }
    });

    return defer.promise;
  }
```

**2.8 controllers.js**  
核心控制脚本

2.8.1 loadDevices  
命令：adb devices -l

```
➜  ~ adb devices -l
List of devices attached
8f9d6dd9   device usb:337641472X product:OnePlus3 model:ONEPLUS_A3000 device:OnePlus3
```

parseDeviceInfoList方法的作用就是从输出结果中解析出设备的序列号(serial)、usb、product、model、device、state等信息

2.8.2 loadPackages  
命令：adb shell pm list packages

```
➜  ~ adb shell pm list packages
package:com.oneplus.calculator
package:net.oneplus.weather
package:com.oneplus.GpioSwitch
package:com.qualcomm.qti.auth.sampleextauthservice
package:com.oneplus.market
package:com.android.providers.telephony
package:com.android.engineeringmode
package:com.android.providers.calendar
package:com.oneplus.opbugreport
```

parsePackageList方法的作用就是从输出结果中解析出包的列表

```js
function parsePackageList(data) {
  var lines = data.trim().split('\n');

  for (var i = 0; i < lines.length; i++) {
    lines[i] = lines[i].replace(/^package:/, '').trim();
  }

  return lines;
}
```

2.8.3 其他与package相关的方法  
installPackage：adb shell pm install -r <package>  
uninstallPackage：adb shell pm uninstall <package>  
stopPackage：adb shell am force-stop <package>  
clearData：adb shell pm clear <package>  
removeApkFile：adb shell rm -rf <packagePath>  

从源码来看，chromeadb实现应用安装的方法是先将apk文件保存到手机的`/data/local/tmp/`目录，然后执行`adb shell pm install -r <packagePath>`方法来安装应用的(这个操作步骤和Android Studio中安装apk的逻辑是一样的)。

2.8.4 loadProcessList  
命令：adb shell ps  
parseProcessList方法用于从输出结果中解析出进程列表，Android 4.4版本之前和之后的输出结果的格式略有差异，所以需要两个不同的正则表达式。

```js
function parseProcessList(data) {
  // parse oldstyle ps result
  var ore = new RegExp(/^(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+([a-fA-F0-9]+)\s+([a-fA-F0-9]+ \w)\s+(.+)/m);
  // parse 4.4 or above ps result
  var nre = new RegExp(/^(\d+)\s+(\d+)\s+(\d+m?)\s+(\w+\s*<?)\s+(.+)/m);
  var lines = data.trim().split('\n');
  var line;

  for (var i = 0; i < lines.length; i++) {
    line = lines[i].trim();
    if (0 === i) {
      line = line.trim().split(/\s+/);
    } else {
      var parsed = ore.exec(line);
      line = !!parsed ? parsed : nre.exec(line);
      line.splice(0, 1);
    }
    lines[i] = line;
  }
  return lines;
}
```

2.8.5 loadMemInfo  
命令：adb shell dumpsys meminfo  

```
➜  ~ adb shell dumpsys meminfo
Applications Memory Usage (kB):
Uptime: 46425131 Realtime: 178910170

Total PSS by process:
   113261 kB: com.oneplus.hydrogen.launcher (pid 2240 / activities)
   108423 kB: system (pid 1340)
   106778 kB: surfaceflinger (pid 487)
    99988 kB: com.android.systemui (pid 1803 / activities)
    94085 kB: org.tensorflow.demo (pid 5773 / activities)
    46489 kB: com.oneplus.card (pid 2572)
```

parseMemInfo方法用来解析进程的内存占用情况，主要是先找到`Total PSS by process`这个标识，然后将后面的pid、processName、pss数据解析出来即可。

```js
function parseMemInfo(data) {
  // \1: memory (kb)
  // \2: process name
  // \3: pid
  var re = new RegExp(/^(\d+)\s+kB:\s+(\S+)\s\(pid\s+(\d+).*/);
  var lines = data.trim().split('\n');
  var line;
  var pss = 0;
  var ret = [];

  for (var i = 0; i < lines.length; i++) {
    line = lines[i].trim();

    if (line.length === 0) {
      continue;
    }

    if (line.indexOf('Total PSS by process') >= 0) {
      pss++;
      continue;
    }

    if (pss === 1) {
      line = re.exec(line);
      if (line) {
        ret.push({
          process: line[2],
          pid: line[3],
          kb: line[1] + ' KB',
          mb: parseInt(parseFloat(line[1]) / 1024 + 0.5) + ' MB'
        });
      } else {
        break;
      }
    }
  }
  return ret;
}
```

命令：adb shell dumpsys meminfo [pid/package]  
带pid/package参数的dumpsys meminfo可以得到该进程的详细内存占用信息

```
➜  ~ adb shell dumpsys meminfo 2240
Applications Memory Usage (kB):
Uptime: 47043593 Realtime: 179528632

** MEMINFO in pid 2240 [com.oneplus.hydrogen.launcher] **
                   Pss  Private  Private  Swapped     Heap     Heap     Heap
                 Total    Dirty    Clean    Dirty     Size    Alloc     Free
                ------   ------   ------   ------   ------   ------   ------
  Native Heap    14274    14204        0        0    21248    18580     2667
  Dalvik Heap    59432    59408        0        0    67386    60326     7060
 Dalvik Other      801      800        0        0                           
        Stack      440      440        0        0                           
......
```

这个数据输出结果由parsePackageMemInfo这个方法来解析，它会去解析Native Heap和Dalvik Heap中`Size`、`Alloc`和`Free`这几列的信息，chromeadb工具会这些数据来绘制曲线图！

```js
function parsePackageMemInfo(data) {
  var lines = data.trim().split('\n');
  var line, tempLine, length;
  var ret = [];
  var cnt = 0;
  var found = false;
  var idxOfSize, idxOfAlloc, idxOfFree;

  for (var i = 0; i < lines.length; i++) {
    line = lines[i].trim();
    tempLine = line.split(/\s+/);
    length = tempLine.length;

    if (!found) {
      idxOfSize = tempLine.indexOf('Size');
      idxOfAlloc = tempLine.indexOf('Alloc');
      idxOfFree = tempLine.indexOf('Free');

      if (idxOfSize >= 0 && idxOfAlloc >= 0 && idxOfFree >= 0) {
        idxOfSize = length - idxOfSize;
        idxOfAlloc = length - idxOfAlloc;
        idxOfFree = length - idxOfFree;
        found = true;
        continue;
      }
    }

    if (found && (tempLine[0] === 'Native' || tempLine[0] === 'Dalvik')) {
      ret.push({
        area: tempLine[0],
        size: tempLine[length - idxOfSize],
        alloc: tempLine[length - idxOfAlloc],
        free: tempLine[length - idxOfFree]
      });
      cnt++;
    }

    if (cnt >= 2) {
      break;
    }
  }
  return ret;
}
```

曲线图示例：

![img](/images/chromeadb_chart.png)


2.8.6 loadDiskSpace  
命令：adb shell df

```
➜  ~ adb shell df
Filesystem               Size     Used     Free   Blksize
/                        2.7G     4.7M     2.7G   4096
/dev                     2.8G   124.0K     2.8G   4096
/sys/fs/cgroup           2.8G    12.0K     2.8G   4096
/mnt                     2.8G     0.0K     2.8G   4096
/system                  2.8G     1.9G   906.7M   4096
...
```

解析输出结果的parseDiskSpace方法

```js
function parseDiskSpace(data) {
  var lines = data.trim().split('\n');
  var line, head, body = [];

  for (var i = 0; i < lines.length; i++) {
    line = lines[i].trim().split(/\s+/);
    if (i === 0) {
      head = line;
    } else {
      body.push(line);
    }
  }
  return {head: head, body: body};
}
```

2.8.7 controller面板下的操作  
sendText：adb shell input text <text>  
onClickButton：adb shell input keyevent <keyCode>  

chromeadb在controller面板中还有一个MousePad功能，但是这个功能需要先在手机上安装chromeadb_for_android应用。[ChromeADB for Android这个应用的源码地址](https://github.com/importre/chromeadb_for_android)，这个项目创建于2年前，可能不太好编译，建议直接创建新项目然后拷贝源码过来进行编译。

应用安装完成之后，刷新Controller面板可以发现MousePad中出现了黑色的面板，在面板中移动鼠标的话可以同时看到在手机界面上对应的移动位置，如下图所示 （应用需要悬浮窗权限，所以需要给该应用开启该权限）

![img](/images/chromeadb_mousepad_controller.png)

### 3.chromeadb_for_android应用源码分析
从chromeadb的源码来看，chromeadb会启动这个应用中的ChromeAdbService，然后实现各种移动和点击操作，所以ChromeAdbService是该应用的核心。

```java
public class ChromeAdbService extends Service implements TailerListener {

    private File mEventFile = new File("/sdcard/chromeadb.event");//监听这个事件文件
    private ImageView mCursorImage;//指针imageview
    private String mPrevLine;//上次读取的文件中那一行字符串
    private Tailer mTailer;//用于监听指定事件文件的Tailer(跟踪者)
    private WindowManager mWindowManager;
    private WindowManager.LayoutParams mLayoutParam;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startTailer();
        addMouseCursor();
        setCursorPosToCenter();
        return super.onStartCommand(intent, flags, startId);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopTailer();
        removeMouseCursor();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void addMouseCursor() {//添加鼠标指针imageview到window上
        if (mCursorImage == null) {
            mCursorImage = new ImageView(this);
            mCursorImage.setImageResource(R.drawable.cursor);
        }

        if (mLayoutParam == null) {
            mLayoutParam = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                            | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT);
            mLayoutParam.gravity = Gravity.LEFT | Gravity.TOP;
            mLayoutParam.flags |= WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN;
        }

        if (mWindowManager == null) {
            mWindowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
            mWindowManager.addView(mCursorImage, mLayoutParam);
        }
    }

    @SuppressLint("NewApi")
    private void setCursorPosToCenter() {//初始化的时候将指针移动到中央
        if (mWindowManager == null || mCursorImage == null) {
            return;
        }

        Display display = mWindowManager.getDefaultDisplay();
        int x, y;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR2) {
            Point size = new Point();
            display.getSize(size);
            x = size.x;
            y = size.y;
        } else {
            x = display.getWidth();
            y = display.getHeight();
        }

        move(x >> 1, y >> 1);
    }

    private void removeMouseCursor() {//删除指针imageview
        if (mCursorImage != null && mWindowManager != null) {
            mWindowManager.removeView(mCursorImage);
            mCursorImage = null;
        }
    }

    public void move(int touchX, int touchY) {//移动指针到指定的x,y坐标位置
        if (mLayoutParam == null || mWindowManager == null || mCursorImage == null) {
            return;
        }

        mLayoutParam.x = touchX;
        mLayoutParam.y = touchY;
        mWindowManager.updateViewLayout(mCursorImage, mLayoutParam);
    }

    private void startTailer() {//开始监听事件文件
        try {
            if (mEventFile.exists()) {
                mEventFile.delete();
            }
            mEventFile.createNewFile();
        } catch (IOException e) {
            Toast.makeText(this, e.getMessage(), Toast.LENGTH_SHORT).show();
            return;
        }

        if (mTailer != null) {
            mTailer.stop();
        }

        //这部分代码可以改成直接使用Tailer的create方法来创建Tailer
        mTailer = new Tailer(mEventFile, this, 10, true);
        Thread thread = new Thread(mTailer);
        thread.start();
    }

    private void stopTailer() {//停止监听事件文件
        if (mTailer != null) {
            mTailer.stop();
            mTailer = null;
        }

        if (mEventFile != null && mEventFile.exists()) {
            mEventFile.delete();
        }
    }

    @Override
    public void init(Tailer tailer) {
    }

    @Override
    public void fileNotFound() {
        mTailer.stop();
    }

    @Override
    public void fileRotated() {
    }

    @Override
    public void handle(String s) {
        //TailerListener接口的回调，当事件文件发生变化的时候，这个方法会回调
        if (mPrevLine != null && mPrevLine.equals(s)) {
            return;
        }

        String coords = Command.getCoordinates(s);
        if (coords != null) {
            moveCursor(coords);
        }

        mPrevLine = s;
    }

    private void moveCursor(String coords) {//根据解析得到的新坐标位置来移动指针
        try {
            final String[] points = coords.split(",");
            for (int i = 0; i < points.length; i += 2) {
                int x = Integer.parseInt(points[i]);
                int y = Integer.parseInt(points[i + 1]);
                Message msg = mHandler.obtainMessage();
                Bundle data = new Bundle();
                data.putInt("x", x);
                data.putInt("y", y);
                msg.setData(data);
                mHandler.sendMessage(msg);
            }
        } catch (Exception e) {
        }
    }

    private final Handler mHandler = new Handler() {

        @Override
        public void handleMessage(Message msg) {
            Bundle data = msg.getData();
            if (data != null) {
                int x = data.getInt("x", 0);
                int y = data.getInt("y", 0);
                move(x, y);
            }
        }
    };

    @Override
    public void handle(Exception e) {
    }
}
```

chromeadb_for_android应用的代码看起来很简单，那么chromeadb是如何将坐标发送到事件文件中的呢？其实就是执行类似下面的命令`adb shell echo move 522,1108,530,1108 >> /sdcard/chromeadb.event`而已。ChromeAdbService这个服务会监听那个文件的变化，一旦有新的数据过来了就会解析参数执行相应的命令。

### 4.与adbserver通信的秘密
通过前面的分析我们知道了chromeadb实际上是连接adbserver，将命令通过socket发送给adbserver，然后adbserver去执行命令并返回结果给chromeadb。那通过socket发送的是什么内容呢？

parse.js文件中有一个很重要的方法`makeCommand`，这个方法用来构造发送的数据，从方法内容来看就是在命令的前面填充4位十六进制形式的数字，表示命令的总长度，方便server那边解析。例如想要发送`shell:dumpsys snowden`命令，那么实际发送的数据是`0015shell:dumpsys snowden`。

```js
function makeCommand(cmd) {
  var hex = cmd.length.toString(16);//先计算命令长度对应的十六进制
  while (hex.length < 4) {//前面不足四位的话补0
    hex = '0' + hex;
  }
  cmd = hex + cmd;
  return cmd;
}
```

那adbserver那边返回的数据又是什么形式的呢？从controllers.js文件中的`getReadAllPromise`方法我们可以大致看出返回结果的结构，一般先是`OKAY`，然后是返回结果的长度，最后是返回结果的内容。例如发送`000ehost:devices-l`，得到的结果是`OKAY0054M96GAEP9PT63B          device usb:337641472X product:m9690 model:m9690 device:m9690`，也就是当前有一个设备，序列号是`M96GAEP9PT63B`，后面内容是它的信息。

```js
$scope.getNewCommandPromise = function (cmd) {
  return socketService.create()
    .then(function (createInfo) {
      return socketService.connect(createInfo, $scope.host, $scope.port);
    })
    .then(function (createInfo) {
      var cmdWidthLength = makeCommand(cmd);
      console.log('command:', cmdWidthLength);//hujiawei
      return socketService.write(createInfo, cmdWidthLength);
    })
    .then(function (param) {
      return socketService.read(param.createInfo, 4);//前四个字节 OKEY
    })
    .catch(function (param) {
      $scope.initVariables();
      $scope.logMessage = {
        cmd: 'Connection Error',
        res: 'run \"$ adb start-server\"'
      };
    });
};

$scope.getCommandPromise = function (cmd, createInfo) {
  var cmdWidthLength = makeCommand(cmd);
  console.log('command:', cmdWidthLength);//hujiawei
  return socketService.write(createInfo, cmdWidthLength)
    .then(function (param) {
      return socketService.read(param.createInfo, 4);
    });
};

//先执行命令1，再执行命令2，都成功的话读取所有数据
$scope.getReadAllPromise = function (cmd1, cmd2) {
  return $scope.getNewCommandPromise(cmd1)
    .then(function (param) {
      //console.log(param);
      if (param.data === 'OKAY') {//成功执行命令1
        return $scope.getCommandPromise(cmd2, param.createInfo);
      }
    })
    .then(function (param) {
      //console.log(param);
      if (param && param.data === 'OKAY') {//成功执行命令2
        return socketService.readAll(param.createInfo, arrayBufferToString);
      }
    })
    .catch(function (param) {
      $scope.initVariables();
      $scope.logMessage = {
        cmd: 'Connection Error',
        res: 'Cannot find any devices'
      };
    });
};
```

可以使用下面的代码来验证这个与adbserver通信方式

```java
public class Snowden {

    public static void main(String[] args) {
        try {

            Socket socket = new Socket();
            SocketAddress remoteAddr = new InetSocketAddress("localhost", 5037);
            socket.connect(remoteAddr, 60000);

            OutputStream os = socket.getOutputStream();
            InputStream is = socket.getInputStream();

            os.write("000ehost:devices-l".getBytes());
            //os.write("001chost:transport:M96GAEP9PT63B".getBytes());
            //os.write("0015shell:dumpsys snowden".getBytes());//OKAYOKAYCan't find service: snowden

            String line = null;
            BufferedReader reader = new BufferedReader(new InputStreamReader(is));
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
                //"OKAY0054M96GAEP9PT63B          device usb:337641472X product:m9690 model:m9690 device:m9690";
            }

            is.close();
            os.close();
            socket.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
```

### 5.总结

虽然chromeadb工具的功能有限而且未来可能真的不会再有新的进展，但是利用当前这个版本进行扩展使用更多有用的功能还是非常方便的，例如我最近利用之前开发的手机版本的悟空监视器改造了一个新的斯诺登监视器。

![img](/images/SnowdenMonitor.png)
