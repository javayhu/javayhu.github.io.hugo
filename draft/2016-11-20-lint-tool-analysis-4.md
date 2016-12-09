---
date: 2016-11-20T10:46:33+08:00
title: Lint Tool Analysis (4)
tags: ["android"]
published: false
---
Lint工具的源码分析(4)  <!--more-->

When custom (third-party) lint rules are integrated in the IDE, they are not available as native IDE inspections, so the explanation text (which must be statically registered by a plugin) is not available. As a workaround, run the lint target in Gradle instead; the HTML report will include full explanations.

lint命令行工具的源码，lint命令行输出结果的源码

```bash
# Set up prog to be the path of this script, including following symlinks,
# and set up progdir to be the fully-qualified pathname of its directory.
prog="$0"
while [ -h "${prog}" ]; do
    newProg=`/bin/ls -ld "${prog}"`
    newProg=`expr "${newProg}" : ".* -> \(.*\)$"`
    if expr "x${newProg}" : 'x/' >/dev/null; then
        prog="${newProg}"
    else
        progdir=`dirname "${prog}"`
        prog="${progdir}/${newProg}"
    fi
done
oldwd=`pwd`
progdir=`dirname "${prog}"`
cd "${progdir}"
progdir=`pwd`
prog="${progdir}"/`basename "${prog}"`
cd "${oldwd}"
#prog=/Users/hujiawei/Android/android_sdk/tools/lint
#progdir=/Users/hujiawei/Android/android_sdk/tools

#查找 lint.jar 文件，一般情况下在 <android_sdk>/tools/lib 下
jarfile=lint.jar
frameworkdir="$progdir"
libdir="$progdir"
if [ ! -r "$frameworkdir/$jarfile" ] #jar文件不存在
then
    #dirname "$progdir" => /Users/hujiawei/Android/android_sdk/
    frameworkdir=`dirname "$progdir"`/tools/lib
    libdir=`dirname "$progdir"`/tools/lib
fi
if [ ! -r "$frameworkdir/$jarfile" ]
then
    frameworkdir=`dirname "$progdir"`/framework
    libdir=`dirname "$progdir"`/lib
fi
if [ ! -r "$frameworkdir/$jarfile" ]
then
    echo `basename "$prog"`": can't find $jarfile"
    exit 1
fi
#frameworkdir=/Users/hujiawei/Android/android_sdk/tools/lib
#libdir=/Users/hujiawei/Android/android_sdk/tools/lib

# Check args. 如果lint后面接debug了的话会绑定8050端口便于调试
if [ debug = "$1" ]; then
    # add this in for debugging
    java_debug=-agentlib:jdwp=transport=dt_socket,server=y,address=8050,suspend=y
    shift 1
else
    java_debug=
fi

javaCmd="java"

jarpath="$frameworkdir/$jarfile"

#os_opts为空
#配置com.android.tools.lint.bindir
#添加lint.jar到classpath中
#运行com.android.tools.lint.Main类的main方法
#com.android.tools.lint.Main类是在lint.jar中的

exec "$javaCmd" \
    -Xmx1024m $os_opts $java_debug \
    -Dcom.android.tools.lint.bindir="$progdir" \
    -Djava.awt.headless=true \
    -classpath "$jarpath" \
    com.android.tools.lint.Main "$@"
```
