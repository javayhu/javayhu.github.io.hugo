---
title: Pury Project Analysis
categories: "android"
date: "2016-10-09"
---
本文总结下对Android平台的性能分析工具Pury的源码分析。 <!--more-->
    
Pury的源码：[https://github.com/NikitaKozlov/Pury](https://github.com/NikitaKozlov/Pury)

Pury is a profiling library for measuring time between multiple independent events. Events can be triggered with one of the annotations or with a method call. All events for a single scenario are united into one report.

感兴趣的话可以先阅读[关于Pury作者为啥开发Pury的介绍](https://medium.com/@nikita.kozlov/pury-new-way-to-profile-your-android-application-7e248b5f615e#.oozl48dch)，最精彩的是关于Pury的内部设计架构和它的局限性的介绍：

Performance measurements are done by `Profilers`. Each `Profiler` contains a list of `Runs`. Multiple `Profilers` can work in parallel, but only a single `Run` per each `Profiler` can be active. Once all `Runs` in a single `Profiler` are finished, result is reported. Amount of runs defines by `runsCounter` parameter.

`Run` has a root `Stage` inside. Each `Stage` has a name, an order number and an arbitrary amount of nested `Stages`. `Stage` can have only one active nested `Stage`. If you stop a parent `Stage`, then all nested `Stages` are also stopped.

![img](/images/pury.jpeg)

以下是我的源码阅读总结：

**1. 源码结构**

1.1 annotations：纯Java应用，已发布到maven上，名称是pury-annotations，其中主要是定义了`MethodProfiling`，`StartProfiling`和`StopProfiling`三个注解

1.2 pury：核心工程，依赖了annotations和aspectj，已发布到maven上，名称是pury

```
compile 'com.nikitakozlov.pury:annotations:1.0.1'
compile 'org.aspectj:aspectjrt:1.8.6'
```

1.3 example：应用示例，依赖了pury，演示了几个场景下的几个方法的监控示例

**2. 使用方法**

注解形式所支持的5个参数

`profilerName` — name of the profiler is displayed in the result. Along with runsCounter identifies the Profiler.
`runsCounter` — amount of runs for Profiler to wait for. Result is available only after all runs are stopped.
`stageName` — identifies a stage to start. Name is displayed in the result.
`stageOrder` — stage order reflects the hierarchy of stages. In order to start a new stage, it must be bigger then order of current most nested active stage. Stage order is a subject to one more limitation: first start event must have order number equal zero.
`enabled` — if set to false, an annotation is skipped.

`Profiler is identified by combination of profilerName and runsCounter`. So if you are using same profilerName, but different runsCounter, then you will get two separate results, instead of a combined one.

profiler对应一个需要监控的场景，runsCounter是指监控场景需要执行的次数
stage对应这个场景下需要监控的方法，stageOrder是指监控方法的对应层级
**需要注意的是Profiler是由profilerName和runsCounter两个共同决定的，也就是说如果profilerName相同但是runsCounter不同的话是两个不同的监控场景，最终会得到两个独立的结果。**

下面是一个采用注解的方式实现监控的例子，它监控了数据加载这个事件。

```
@StartProfiling(profilerName = StartApp.PROFILER_NAME, stageName = StartApp.SPLASH_LOAD_DATA,
        stageOrder = StartApp.SPLASH_LOAD_DATA_ORDER)
private void loadData() {
    new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {

        @Override
        public void run() {
            onDataLoaded();
            startMainActivity();
        }
    }, 1000);
}

@StopProfiling(profilerName = StartApp.PROFILER_NAME, stageName = StartApp.SPLASH_SCREEN)
private void onDataLoaded() {

}
```

监控App Start场景下的方法调用时长的输出示例，它表示监控的场景名(ProfilerName)是`App Start`，这个场景总共耗时1182ms，这个场景下有6个stage，分别是`App Start`、`Splash Screen`、`Splash Load Data`、`Main Activity Launch`、`onCreate()`和`onStart()`，下面的输出显示了每个stage的运行时间。

```
Profiling results for App Start:
App Start --> 0ms
  Splash Screen --> 5ms
    Splash Load Data --> 37ms
    Splash Load Data <-- 1042ms, execution = 1005ms
  Splash Screen <-- 1042ms, execution = 1037ms
  Main Activity Launch --> 1043ms 
    onCreate() --> 1077ms 
    onCreate() <-- 1100ms, execution = 23ms
    onStart() --> 1101ms 
    onStart() <-- 1131ms, execution = 30ms
  Main Activity Launch <-- 1182ms, execution = 139ms
App Start <-- 1182ms
```

监控Pagination场景下的方法调用时长的输出示例，它统计了Pagination这个场景下的3个stage，分别是`Get Next Page`、`Load`和`Process`，每个stage都会运行5次并统计avg、min和max用时。

```
Profiling results for Pagination:
Get Next Page --> 0ms
  Load --> avg = 1.80ms, min = 1ms, max = 3ms, for 5 runs
  Load <-- avg = 258.40ms, min = 244ms, max = 278ms, for 5 runs
  Process --> avg = 261.00ms, min = 245ms, max = 280ms, for 5 runs
  Process <-- avg = 114.20ms, min = 99ms, max = 129ms, for 5 runs
Get Next Page <-- avg = 378.80ms, min = 353ms, max = 411ms, for 5 runs
```

**3. 核心代码分析**

**3.1 annotations工程中的注解**

annotations中的注解有6个，分别是`MethodProfiling`、`MethodProfilings`、`StartProfiling`、`StartProfilings`、`StopProfiling`和`StopProfilings`，因为有些方法可能存在多个注解，所以每个都对应会有一个复数形式的。这些注解作用的对象可以是普通的方法，也可以是类的构造器。

```java
/**
 * Combination of {@link StartProfiling} and {@link StopProfiling}. If stage name is empty, then stage name from method's name and class will be generated.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target({ ElementType.CONSTRUCTOR, ElementType.METHOD })
public @interface MethodProfiling {
    /**
     * Profiler Name, used in results.
     */
    String profilerName() default "";

    /**
     * Name of stage to start. Used in results. If stage name is empty, then stage name from method's name and class will be generated.
     */
    String stageName() default "";

    /**
     * Stage order must be bigger then order of current most nested active stage.
     * First profiling must starts with value 0.
     */
    int stageOrder() default 0;

    /**
     * Amount of runs to average. Result will be available only after all runs are stopped.
     */
    int runsCounter() default 1;

    /**
     * Set to false if you want to skip this annotation.
     */
    boolean enabled() default true;
}
```

**3.2 pury工程中的注解处理类**

pury工程中的注解处理类有3个，分别是`ProfileMethodAspect`、`StartProfilingAspect`和`StopProfilingAspect`类。

下面是`ProfileMethodAspect`的源码，其中定义了4个PointCut以及1个Around Advice。方法`weaveJoinPoint`是核心方法，它的主要执行流程是：假设我们对方法M提供了MethodProfiling注解，weaveJointPoint先会根据注解提供的参数去获取并启动所有相关的stage，也就是该方法所在的所有场景(profiler)下的对应stage，然后调用方法M使其执行，最后再停止所有的stage。

```java
@Aspect
public class ProfileMethodAspect {
    private static final String POINTCUT_METHOD =
            "execution(@com.nikitakozlov.pury.annotations.MethodProfiling * *(..))";

    private static final String POINTCUT_CONSTRUCTOR =
            "execution(@com.nikitakozlov.pury.annotations.MethodProfiling *.new(..))";


    private static final String GROUP_ANNOTATION_POINTCUT_METHOD =
            "execution(@com.nikitakozlov.pury.annotations.MethodProfilings * *(..))";

    private static final String GROUP_ANNOTATION_POINTCUT_CONSTRUCTOR =
            "execution(@com.nikitakozlov.pury.annotations.MethodProfilings *.new(..))";

    @Pointcut(POINTCUT_METHOD)
    public void method() {
    }

    @Pointcut(POINTCUT_CONSTRUCTOR)
    public void constructor() {
    }

    @Pointcut(GROUP_ANNOTATION_POINTCUT_METHOD)
    public void methodWithMultipleAnnotations() {
    }

    @Pointcut(GROUP_ANNOTATION_POINTCUT_CONSTRUCTOR)
    public void constructorWithMultipleAnnotations() {
    }

    @Around("constructor() || method() || methodWithMultipleAnnotations() || constructorWithMultipleAnnotations()")
    public Object weaveJoinPoint(ProceedingJoinPoint joinPoint) throws Throwable {
        ProfilingManager profilingManager = ProfilingManager.getInstance();
        List<StageId> stageIds = getStageIds(joinPoint);
        for (StageId stageId : stageIds) {
            profilingManager.getProfiler(stageId.getProfilerId())
                    .startStage(stageId.getStageName(), stageId.getStageOrder());
        }

        Object result = joinPoint.proceed();

        for (StageId stageId : stageIds) {
            profilingManager.getProfiler(stageId.getProfilerId())
                    .stopStage(stageId.getStageName());
        }

        return result;
    }

    private List<StageId> getStageIds(ProceedingJoinPoint joinPoint) {
        if (!Pury.isEnabled()) {
            return Collections.emptyList();
        }

        Annotation[] annotations =
                ((MethodSignature) joinPoint.getSignature()).getMethod().getAnnotations();
        List<StageId> stageIds = new ArrayList<>();
        for (Annotation annotation : annotations) {
            if (annotation.annotationType() == MethodProfiling.class) {
                StageId stageId = getStageId((MethodProfiling) annotation, joinPoint);
                if (stageId != null) {
                    stageIds.add(stageId);
                }
            }
            if (annotation.annotationType() == MethodProfilings.class) {
                for (MethodProfiling methodProfiling : ((MethodProfilings) annotation).value()) {
                    StageId stageId = getStageId(methodProfiling, joinPoint);
                    if (stageId != null) {
                        stageIds.add(stageId);
                    }
                }
            }
        }
        return stageIds;
    }

    private StageId getStageId(MethodProfiling annotation, ProceedingJoinPoint joinPoint) {
        if (!annotation.enabled()) {
            return null;
        }
        ProfilerId profilerId = new ProfilerId(annotation.profilerName(), annotation.runsCounter());
        String stageName = annotation.stageName();
        if (stageName.isEmpty()) {
            CodeSignature codeSignature = (CodeSignature) joinPoint.getSignature();
            String className = codeSignature.getDeclaringType().getSimpleName();
            String methodName = codeSignature.getName();
            stageName = className + "." + methodName;
        }

        return new StageId(profilerId, stageName, annotation.stageOrder());
    }
}
```

`StartProfilingAspect`和`StopProfilingAspect`与之类似，只不过前者定义的是`@Before` advice，而后者定义的是`@After` advice。

**3.3 核心类Pury**

Pury是pury工程的核心工具类，除了可以设置自定义的Logger以及设置enabled状态之外，它还提供了`startProfiling`和`stopProfiling`两个方法来实现代码调用的方法来对方法进行监控。

```java
public final class Pury {
    static volatile Logger sLogger;
    static volatile boolean sEnabled = true;

    public static void setLogger(Logger logger) {
        sLogger = logger;
    }

    public synchronized static Logger getLogger() {
        if (sLogger == null) {
            sLogger = new DefaultLogger();
        }
        return sLogger;
    }

    public static boolean isEnabled() {
        return sEnabled;
    }

    public synchronized static void setEnabled(boolean enabled) {
        if (!enabled) {
            ProfilingManager.getInstance().clear();
        }
        sEnabled = enabled;
    }

    /**
     *
     * @param profilerName used to identify profiler. Used in results.
     * @param stageName Name of stage to start. Used in results.
     * @param stageOrder Stage order must be bigger then order of current most nested active stage.
     *                   First profiling must starts with value 0.
     * @param runsCounter used to identify profiler. Amount of runs to average.
     *                    Result will be available only after all runs are stopped.
     */
    public static void startProfiling(String profilerName, String stageName, int stageOrder, int runsCounter) {
        ProfilerId profilerId = new ProfilerId(profilerName, runsCounter);
        ProfilingManager.getInstance().getProfiler(profilerId).startStage(stageName, stageOrder);
    }

    /**
     *
     * @param profilerName used to identify profiler. Used in results.
     * @param stageName  Name of stage to stop. Used in results.
     * @param runsCounter used to identify profiler. Amount of runs to average.
     *                    Result will be available only after all runs are stopped.
     */
    public static void stopProfiling(String profilerName, String stageName, int runsCounter) {
        ProfilerId profilerId = new ProfilerId(profilerName, runsCounter);
        ProfilingManager.getInstance().getProfiler(profilerId).stopStage(stageName);
    }
}
```

**Profiler是由profilerName和runsCounter两个共同决定的**

```java
ProfilerId profilerId = new ProfilerId(profilerName, runsCounter);
```

**在某个监控场景下启动和停止某个方法的监控**

```java
ProfilingManager.getInstance().getProfiler(profilerId).startStage(stageName, stageOrder);

ProfilingManager.getInstance().getProfiler(profilerId).stopStage(stageName, stageOrder);
```

**3.4 其他包和类**

pury工程的其他类都存放在`internal.profile`包和`internal.result`两个包中，前者定义了`Profiler`、`Stage`、`StopWatch`等相关类，后者定义了`ProfileResultProcessor`、`ProfileResult`等各种处理结果和相应的处理类。

**4. 其他内容**

4.1 Pury的优缺点

个人认为，pury提供了方法调用和注解两种使用形式，实现了对某个场景及该场景下方法级别的监控，甚至可以设置场景的出现次数并自动计算场景下方法的min/avg/max三种执行时长，其功能足以满足一般的应用的场景响应时间监控的需求。不同于[Hugo](https://github.com/JakeWharton/hugo)项目，后者只是对一个方法的监控，不能做到Pury这样针对场景的监控。

Pury存在一个明显的缺点就是方法的层级必须指定，而且必须正确指定。一般来说，方法调用的堆栈往往可能会很深，明确指定方法的层级有时候会比较麻烦，当方法的调用流程发生变化的时候不易于维护。实际上，通过分析方法调用的情况来自动配置方法层级应该是可以做到的(类似TraceView工具)。

4.2 Pury使用的gradle插件

发布到maven使用的gradle插件是`https://raw.githubusercontent.com/nuuneoi/JCenter/master/installv1.gradle`
实现注解解析的gradle插件是`com.nikitakozlov.weaverlite`，这个是作者自己封装的插件[WeaverLite](https://github.com/NikitaKozlov/WeaverLite)

Pury的源码就分析到这里吧，感兴趣的建议再扫一遍源码看下，还是会有挺多收获的。


