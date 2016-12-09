
11-22 22:20:15.685 26958-26966/com.meizu.flyme.launcher I/System: FinalizerDaemon: finalize objects = 32

11-22 22:57:34.181 9457-9467/com.meizu.flyme.launcher I/art: Background sticky concurrent mark sweep GC freed 2371(128KB) AllocSpace objects, 24(7MB) LOS objects, 0% free, 97MB/97MB, paused 8.870ms total 34.514ms

11-23 09:41:04.947 5027-5027/com.meizu.flyme.launcher I/art: Starting a blocking GC Explicit
11-23 09:41:04.992 5027-5027/com.meizu.flyme.launcher I/art: Explicit concurrent mark sweep GC freed 6392(499KB) AllocSpace objects, 1(1064KB) LOS objects, 6% free, 60MB/64MB, paused 452us total 44.121ms

OPENGROK_TOMCAT_BASE=/usr/local/Cellar/tomcat/8.0.23/libexec opengrok/bin/OpenGrok deploy
OPENGROK_INSTANCE_BASE=opengrok opengrok/bin/OpenGrok index /Volumes/Transcend/aosp


E/MzDevelopmentSettings: Start activity fail:Unable to find explicit activity class {com.meizu.perfui/com.meizu.perfui.settings.SettingsActivity}; have you declared this activity in your AndroidManifest.xml?

busybox iostats 1


```
$ ./bin/OpenGrok deploy
Loading the default instance configuration ...
Installing /Users/hujiawei/Android/code/opengrok/bin/../lib/source.war to /usr/local/Cellar/tomcat/8.0.23/libexec/webapps ...

Start your application server (Tomcat),  if it is not already
running, or wait until it loads the just installed web  application.

OpenGrok should be available on <HOST>:<PORT>/source
  where HOST and PORT are configured in Tomcat.
```



```
$ ./bin/OpenGrok index /Volumes/Transcend/aosp
Loading the default instance configuration ...
WARNING: OpenGrok generated data path /Users/hujiawei/Android/code/opengrok/data doesn't exist
  Attempting to create generated data directory ...
WARNING: OpenGrok generated etc path /Users/hujiawei/Android/code/opengrok/etc  doesn't exist
  Attempting to create generated etc directory ...
  Creating default /Users/hujiawei/Android/code/opengrok/logging.properties ...
10:37:17 WARNING: cannot write latest cached revision to file: null
10:37:24 WARNING: cannot write latest cached revision to file: null
```

```
$ repo --version
repo version v1.12.33
       (from https://gerrit.googlesource.com/git-repo)
repo launcher version 1.23
       (from /Volumes/Transcend/tools/repo)
git version 2.10.0
Python 2.7.10 (v2.7.10:15c95b7d81dc, May 23 2015, 09:33:12)
[GCC 4.2.1 (Apple Inc. build 5666) (dot 3)]
```

[Abstract Syntax Tree](http://www.eclipse.org/articles/Article-JavaCodeManipulation_AST/)

The AST is comparable to the DOM tree model of an XML file. Just like with DOM, the AST allows you to modify the tree model and reflects these modifications in the Java source code.
