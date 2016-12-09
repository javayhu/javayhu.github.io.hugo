---
title: How to get performance data in Android
tags: ["android"]
date: "2016-10-16"
---
本文记录下在Android平台上如何获取那些系统性能相关的数据。 <!--more-->

##### 1. CPU平均负载

读取文件节点`/proc/loadavg`，分别是1min/5min/15min内CPU的负载情况。  
读取方式的代码示例：
```java
private static final int[] LOAD_AVERAGE_FORMAT = new int[]{
       PROC_SPACE_TERM | PROC_OUT_FLOAT,                 // 0: 1 min
       PROC_SPACE_TERM | PROC_OUT_FLOAT,                 // 1: 5 mins
       PROC_SPACE_TERM | PROC_OUT_FLOAT                  // 2: 15 mins
};

public float mLoad1 = 0;
public float mLoad5 = 0;
public float mLoad15 = 0;
private final float[] mLoadAverageData = new float[3];

private void getLoadAverage() {
   final float[] loadAverages = mLoadAverageData;
   if (Process.readProcFile(FILE_PORC_LOAD, LOAD_AVERAGE_FORMAT, null, null, loadAverages)) {
       float load1 = loadAverages[0];
       float load5 = loadAverages[1];
       float load15 = loadAverages[2];
       if (load1 != mLoad1 || load5 != mLoad5 || load15 != mLoad15) {
           mLoad1 = load1;
           mLoad5 = load5;
           mLoad15 = load15;
       }
   }
}
```

##### 2. CPU的频率

CPU的核数：统计 `/sys/devices/system/cpu/` 目录下名称以`cpu`开始的文件夹的数目  
正在工作的核： `/sys/devices/system/cpu/online`  
注意：可能是`1-4`或者`2,3`或者`1-3,5-7`等各种组合形式  
正在工作的核的频率，例如cpu0的频率节点： `/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`

##### 3. 内存碎片化程度

文件节点：`/sys/kernel/debug/extfrag/unusable_index`

```
$ cat /sys/kernel/debug/extfrag/unusable_index                      
Node 0, zone      DMA 0.000 0.802 0.894 0.971 0.985 0.995 1.000 1.000 1.000 1.000 1.000
Node 0, zone  Movable 0.000 0.000 0.000 0.000 0.002 0.003 0.003 0.003 0.004 0.006 0.006
```

*(1)zone的个数不确定，名称也不确定*  
*(2)先计算单个zone的平均值，再计算zone的整体平均内存碎片化程度*  

参考资料：[https://chengyihe.wordpress.com/2015/11/28/kernel-mm-syskerneldebugextfragunusable_index/](https://chengyihe.wordpress.com/2015/11/28/kernel-mm-syskerneldebugextfragunusable_index/)

##### 4. 虚拟内存信息
vmstat是Virtual Meomory Statistics（虚拟内存统计）的缩写, 是实时系统监控工具。vmstat结果中r,b,in,cs是通过 `/proc/stat` 文件计算得到的，si,so,bi,bo是通过 `/proc/vmstat` 文件计算得到的。

需要注意的是，`/proc/vmstat` 文件中 pgpgin,pgpgout,pswpin,pswpout等值的单位是page，而vmstat命令返回的结果的单位是kb，所以需要进行单位转换，一般情况下，一页的大小是4KB。除此之外，时间间隔是从`/proc/uptime`中读取计算出的差值，该文件中保存的是系统从启动到当前时刻的时间，单位是秒。

关于中断in：vmstat命令的返回的in值指的是CPU在软中断上占用的时间差值，而不是中断数的差值。如果计算后者的话，可以从`/proc/stat`的intr中读取从系统启动到当前时刻总共发生的中断数来计算差值。

参考资料：[vmstat命令详解](http://www.cnblogs.com/ggjucheng/archive/2012/01/05/2312625.html)

##### 5. 内存信息

文件节点：`/proc/meminfo`，统计得到total, used, free, cached, buffers, active, inactive, swap total, swap free

```
$ cat /proc/meminfo
MemTotal:        2808452 kB
MemFree:          535824 kB
MemAvailable:     775404 kB
Buffers:           21840 kB
Cached:           302588 kB
SwapCached:        18792 kB
Active:           668900 kB
Inactive:         313524 kB
Active(anon):     511716 kB
Inactive(anon):   169452 kB
Active(file):     157184 kB
Inactive(file):   144072 kB
Unevictable:        4176 kB
Mlocked:               0 kB
SwapTotal:       1404224 kB
SwapFree:        1153856 kB
Dirty:                 4 kB
```

*1.swap cached 不等于 swap used, swap used = swap total - swap free*  
*2.Memory Free = MemFree + Cached + Buffers*  
*3.Memory Used = Memory Total - Memory Free*  

参考资料：[linux内存管理原理](http://www.cnblogs.com/zhaoyl/p/3695517.html) [buffers和cached的区别](http://linuxperf.com/?p=32) [active和inactive的区别](http://linuxperf.com/?p=97)

##### 6. CPU被占用的情况

CPU被占用的时间比数据的文件节点：`/proc/stat`

```
$ cat /proc/stat
cpu  229649 59778 316872 3688440 3308 6 357 0 0 0
cpu0 111250 7718 210302 3466017 764 6 209 0 0 0
```

jiffies是内核中的一个全局变量，用来记录自系统启动一来产生的节拍数。在linux中，一个节拍大致可理解为操作系统进程调度的最小时间片，不同linux内核可能值有不同，通常在1ms到10ms之间。

user (229649) 从系统启动开始累计到当前时刻，用户态的CPU时间（单位：jiffies），不包含nice值为负的进程  
nice (59778) 从系统启动开始累计到当前时刻，nice值为负的进程所占用的CPU时间（单位：jiffies）  
system (316872) 从系统启动开始累计到当前时刻，核心系统进程占用的时间（单位：jiffies）  
idle (3688440) 从系统启动开始累计到当前时刻，除硬盘IO等待时间以外其它等待时间（单位：jiffies）  
iowait (3308) 从系统启动开始累计到当前时刻，硬盘IO等待时间（单位：jiffies）  
irq (6) 从系统启动开始累计到当前时刻，硬中断时间（单位：jiffies）  
softirq (357) 从系统启动开始累计到当前时刻，软中断时间（单位：jiffies）  

上面结果中的后面三个数据在Android中不统计，所以  
`total = user + nice + system + idle + iowait + irq + softirq`  
百分比的计算方式一般是：  
`USER%=(user+nice)/total，SYS%=system/total，IOW%=iowait/total，IRQ%=(irq+softirq)/total`  

参考资料：[cpu被占用的时间比信息详解](http://www.cnblogs.com/yjf512/p/3383915.html)  

##### 7. 进程/线程的占用信息

进程数据文件的节点： `/proc/[pid]`  
线程数据文件的节点： `/proc/[pid]/task/[tid]`  

进程和线程的状态信息从`stat`文件中获取，名称从`cmdline`文件中获取，cpuset从`cpuset`文件中获取等。进程的`stat`文件中保存了该进程的`user time`和`system time`，两者之和可以用来对进程进行排序，一般进程和线程的排序方式都是按照它们占用的CPU时长来排序的。

*(1)Process.getPids方法既可以用来获取某个目录下的所有进程数组，也可以用来获取某个进程的task目录下的所有线程数组*  
*(2)Process.getPss方法可以用来统计进程的pss数据，但是很多进程的pss数据都没法获取到*  

参考资料：[关于/proc/pid/stat](http://blog.csdn.net/zjl_1026_2001/article/details/2294036)

进程和线程部分的实现相对有点难度，一方面要统计系统所有的进程和线程的信息，另一方面要对它们进行排序。不过庆幸的是Android系统源码中有一个[`LoadAverageService`](http://androidxref.com/6.0.0_r1/xref/frameworks/base/packages/SystemUI/src/com/android/systemui/LoadAverageService.java)，这个service也就是开发者选项中`显示CPU使用情况`的内部实现，它的代码非常具有参考价值，我们可以在它的基础上进行扩展开发自己的工具。

上面只是列举了部分常见的重要数据的获取方法，其他数据的获取方式也都差不多，主要是要知道当前平台的相应数据的文件节点，还需要注意的是是否具有文件的读权限。

下图是我最近开发的悟空监视器，入口在Flyme系统的开发者选项中(公司内部项目，源码不能公开，仅供参考，原理同上)

![img](/images/wukong.jpg)
