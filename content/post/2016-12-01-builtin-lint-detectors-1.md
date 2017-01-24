---
date: 2016-12-01T10:46:33+08:00
title: Builtin Lint Detectors (1)
tags: ["android"]
---
Lint工具中自带的与Android开发相关的lint检查项。 <!--more-->

本文主要介绍的是Lint工具中自带的与Android开发相关的lint检查项，通过查看lint检查项的描述及其代码实现，我发现这里面存在不少应用开发编码的Best Practice，有些是平常编码中非常常见的错误(这类问题建议看下对应的参考资料)，有些却有点隐晦(这类问题我们会仔细研究下)，这些lint检查项对于我们在平常编码过程中都会有不少启发。

这里先提一下如何在Java和XML代码中屏蔽掉某个lint检查项，这是在某个检查项开启但是某个特殊位置想忽略这个检查错误的一种方式。至于如何将检查项开启/关闭或者配置某个检查项忽略某些文件或文件夹等内容请参见之前的几篇Lint文档。  

在Java代码中屏蔽掉某个lint检查可以使用`@SuppressLint`这个注解，例如`@SuppressLint("UseSparseArrays")`  
在XML代码中屏蔽掉某个lint检查可以使用`tools:ignore`属性声明，例如`tools:ignore="ContentDescription"`  

下面是一些lint检查项的具体细节，我们一个个来介绍它们。  

**(1) Image without `contentDescription`**  
实现：`AccessibilityDetector`  
说明：`ImageView`和`ImageButton`需要有`contentDescription`属性来指定它的文字描述，除非它们声明了`tools:ignore="ContentDescription"`。此外，如果设置了`contentDescription`属性就不需要再设置`hint`属性了，它会将`hint`属性覆盖掉不显示。

**(2) Missing `labelFor` attribute**  
实现：`LabelForDetector`  
说明：`EditText`、`AutoCompleteTextView`以及`MultiAutoCompleteTextView`这三个特别的View，它们一般都是等待用户在里面输入内容，所以往往需要有其他的View例如`TextView`通过`labelFor`属性指向它们，这样的话`Textview`的内容也就表明前面三个View是在等待用户输入什么内容。

**(3) FrameLayout can be replaced with `<merge>` tag**  
实现：`MergeRootFrameLayoutDetector`  
说明：检查`FrameLayout`能否使用`merge`标签进行布局优化，在某些情况下，如果`Framelayout`是根布局，并且没有背景和padding的设置，那么它就有可能可以通过`merge`标签对布局进行优化，但是到底是否可以还是需要开发者自行决定。  
参考：[Android中的merge标签](http://www.cnblogs.com/dukc/p/5136310.html)

**(4) Handler reference leaks**  
实现：`HandlerDetector`  
说明：这是很常见的Handler导致内存泄露的情景。如果Handler被定义为内部类的话，它可能会阻止它的外部类被GC掉。如果这个Handler是在非主线程的`Looper`或者`MessageQueue`中使用的话不会有问题；但是如果是在主线程中使用的话，那么就需要进行修复，方法是：将Handler定义为静态内部类(static inner class)，在实例化Handler的时候将外部类的弱引用(WeakReference)传递给Handler，并且在Handler内部将所有对外部类的引用都改为弱引用的形式。  
参考：[Android Handler引起的内存泄露问题](http://droidyue.com/blog/2014/12/28/in-android-handler-classes-should-be-static-or-leaks-might-occur/)

**(5) HashMap can be replaced with `SparseArray`**  
实现：`JavaPerformanceDetector`  
说明：如果Map的key是Integer类型，推荐使用`SparseArray`，而不是HashMap。特别地，如果Map的value的类型是int的话，推荐使用`SparseIntArray`，因为它会避免int和Integer之间的封箱拆箱操作。同理，如果Map的value类型是long的话，推荐使用`SparseLongArray`。HashMap内部采用的是数组+链表的结构存储数据，但是SparseArray内部采用的是双数组的结构存储数据，而且key是按照int的大小顺序来存放的，所以查找、删除操作都会先进行二分查找，这就导致了在数据量很大的情况下，SparseArray的性能反而不如HashMap。其次，Android还提供了另一个ArrayMap的类，它类似SparseArray的存储结构，只是key可以不是int类型。这两个数据结构一般用于数据量在千级以下，否则性能差于HashMap。  
参考：[Android SparseArray和ArrayMap](http://blog.csdn.net/u010687392/article/details/47809295)

**(6) Memory allocation within drawing code**  
实现：`JavaPerformanceDetector`  
说明：在Android中，draw和layout的过程的调用非常频繁，我们应该避免在这两个过程中创建对象，因为创建对象就要分配内存，如果内存不够的话就会GC，GC太长的话可能会导致界面出现卡顿现象。解决方案一般是将对象创建的操作提前，然后在draw的过程中重复使用，比如对于`Bitmap.create`这类方法的调用就需要这么处理。这一点在众多性能优化的文章中反复提到，draw方法的调用时间必须要尽可能的短。

**(7) Should use `valueOf` instead of `new`**  
实现：`JavaPerformanceDetector`  
说明：对于封装类，例如`Integer`、`Long`、`Boolean`等，我们最好不要直接调用封装类的构造器方法，例如`new Integer(42)`，推荐使用封装类的`valueOf`这个工厂方法，例如`Integer.valueOf(42)`。  
为什么要这样做呢？我们看下Integer的`valueOf`方法的实现，它先会判断参数`i`的范围，如果它是在`IntegerCache`的缓存的int范围之内(一般默认情况下是[-128,127])的话就直接使用缓存的Integer，如果不是的话就还是使用`new Integer`来创建对象。

```java
//Integer的内部类IntegerCache的实现
private static class IntegerCache {
    static final int low = -128;
    static final int high;//默认是127
    static final Integer cache[];//通过new Integer创建了从low到high的Integer
    //...忽略静态初始块代码
}

public static Integer valueOf(int i) {
    assert IntegerCache.high >= 127;
    if (i >= IntegerCache.low && i <= IntegerCache.high)
        return IntegerCache.cache[i + (-IntegerCache.low)];
    return new Integer(i);
}
```

**(8) Inefficient layout weight**  
实现：`InefficientWeightDetector`  
说明：如果在一个LinearLayout中只定义了一个包含weight属性值的组件时，推荐直接指定这个组件的width或者height是`0dp`，这两种方式的效果是相同的，这个组件会占据父容器中的剩余空间(一般来说，剩余空间=父容器的总空间-没有设置`weight`属性值的子组件的空间之和)。它们的区别在于，如果设置了width或者height的属性值，那么就省掉了计算这个组件自己的大小的过程。这里我们需要注意效果等价的前提条件是在一个LinearLayout中只定义了一个包含weight属性值的组件，此外如果LinearLayout的orientation是horizontal的话，推荐将组件的`layout_width`设置为`0dp`，而如果LinearLayout的orientation是vertical的话，推荐将组件的`layout_height`设置为`0dp`。如下面的例子所示，推荐将`android:layout_weight="1"`改为`android:layout_width="0dp"`。

```xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <TextView
        android:layout_width="wrap_content"  //推荐改成 0dp
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:text="@string/app_name"/>

</LinearLayout>
```

参考：[从源码角度彻底分析layout_weight使用](http://www.jianshu.com/p/17da46223da9)  [彻底搞明白layout_weight](http://blog.csdn.net/fumier/article/details/48024407)

**(9) Suspicious 0dp dimension**  
实现：`InefficientWeightDetector`  
说明：当水平方向的LinearLayout中的子组件的大小只是依据它们的weight属性值来确定的时候，我们通常会使用`0dp`作为组件的width，因为这样可以省掉子组件的measure调用次数，这也就是前面的第(8)条。但是，如果我们没有给这个组件设置`weight`属性的话那么这个组件就会因为width为0而不可见；或者如果我们将LinearLayout的orientation设置为vertical的话，虽然这个组件的height不为0，但是因为width为0导致这个组件也会变得不可见。  

**(10) Nested layout weights**  
实现：`InefficientWeightDetector`  
说明：如果组件设置了`weight`属性的话，这个组件将会被measure两次。当一个weight属性值非零的组件中被包含在另一个weight属性值非零的组件的时候(也就是weight属性嵌套了)，这些组件被measure的次数将呈指数增长，如下所示，这种情况需要尽可能避免发生。

```xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    //...>

    <TextView
        //...
        android:layout_weight="1"/>

    <LinearLayout
        //...
        android:layout_weight="3">

        <TextView
            //...
            android:layout_weight="1" />
        <TextView
            //...
            android:layout_weight="2" />
    </LinearLayout>
</LinearLayout>
```

**(11) Missing `baselineAligned` attribute**  
实现：`InefficientWeightDetector`  
说明：当一个LinearLayout是水平方向布局且它的子组件都是Layout，并且至少有一个Layout有weight属性值时候，推荐将这个LinearLayout的`android:baselineAligned`属性值设置为`false`，这样的话将加快布局大小的计算速度。  
参考：[Android中LinearLayout的baselineAligned属性的作用](http://www.cnblogs.com/JohnTsai/p/4074643.html)

**(12) Missing explicit orientation**  
实现：`InefficientWeightDetector`  
说明：LinearLayout默认的orientation是horizontal(水平方向)，但是很容易被误解为是vertical(垂直方向)，所以当LinearLayout中有很多个子组件并且其中至少有个组件设置了`layout_width`是`match_parent`或者`fill_parent`的时候，lint就会提示要求显式设置orientation。
或者没有子组件但是定义了`id`属性值的时候，lint检查器就会提醒建议显式声明LinearLayout的orientation属性值。  

**(13) Layout has too many views**  
实现：`TooManyViewsDetector`  
说明：在一个单独的layout中不应该有太多的view，因为view太多了会影响性能，可以考虑使用Compound Drawable(例如TextView有上下左右共4个Compound Drawable)等技术来减少layout中的view的数目。默认的最大的view的数目是80，但是我们可以通过`ANDROID_LINT_MAX_VIEW_COUNT`这个环境变量来修改它。  

**(14) Layout hierarchy is too deep**  
实现：`TooManyViewsDetector`  
说明：布局嵌套太深同样非常影响性能，推荐使用flatter layout，例如RelativeLayout、GridLayout等。默认的最大深度是10，但是我们可以通过`ANDROID_LINT_MAX_DEPTH`这个环境变量来修改它。  

**(15) Missing recycle() calls**  
实现：`CleanupDetector`  
说明：很多资源例如`TypedArrays`、`VelocityTracker`等在使用完之后都需要调用`recycle()`方法将资源释放掉，其他的例如`Cursor`对象则需要在使用完之后调用`close()`方法来释放资源。  

**(16) Missing commit() calls**  
实现：`CleanupDetector`  
说明：`FragmentTransaction`在创建并使用了之后一般都要调用`commit`方法。   

**(17) Missing commit() on SharedPreference editor**  
实现：`CleanupDetector`  
说明：在`SharedPreference`调用了`edit()`方法之后，我们都需要在editor上调用`commit()`或者`apply()`方法来保存结果。  

**(18) Node can be replaced by a TextView with compound drawables**  
实现：`UseCompoundDrawableDetector`  
说明：如果一个LinearLayout中包含一个ImageView和一个Textview的话可以用一个单独的Textview(Compound Drawable)代替它，并使用`drawableLeft`、`drawableTop`等属性来设置图片和文本的对齐方式。此外，如果需要设置两个组件之间的间隔(margin)，可以使用`drawablePadding`属性。从源码实现上来看，如果LinearLayout有设置`background`或者ImageView有设置`scaleType`的话就不会提示这个问题。  

**(19) Overdraw: Painting regions more than once**  
实现：`OverdrawDetector`  
说明：如果你给一个root view设置了一个background，那么你应该自定义一个theme并设置theme的background是null，否则theme的background会先绘制上去，然后自定义的background再绘制上去并完全覆盖它，这就造成了过度绘制的问题。需要注意的是，这个检查器依赖于layout和activity之间的映射关系，这个关系的确定需要检查Java代码(所以`OverdrawDetector`既实现了`XmlScanner`又实现了`JavaPsiScanner`)。目前这个检查器使用的是一个不完全正确的模式匹配算法，所以它的检查结果可能有误。  

**(20) Obsolete layout params**  
实现：`ObsoleteLayoutParamsDetector`  
说明：这个检查器检查layout/view的layout参数，有些layout参数只在某些layout中存在，对于其他layout没有效果，比如`layout_weight`属性只会在LinearLayout中使用才有效，如果在其他的layout中使用的话会造成运行时多余的属性值处理而影响性能，所以最好是删除。  

**(21) Static Field Leaks**   
实现：`LeakDetector`   
说明：这个检查器检查是否存在类中定义的静态变量而造成的内存泄露问题。从源码实现来看，主要检查的是Java类中是否存在static修饰的`Context`、`View`、`Fragment`等类。

**(22) Tagged object leaks**  
实现：`ViewTagDetector`  
说明：在Android 4.0(API 14)之前，`View.setTag(int, object)`方法的实现是将objects存储在静态的map中，而且values是强引用的，所以，如果object中包含对某个context的引用的话，就可能造成对应的context的内存泄露。如果传入的是一个view，view对于创建它的context持有引用，同理，view holder通常也包含一个view，cursors也经常是和view关联的，它们都有可能会出现这种内存泄露的情况。注意这个问题只是有可能在4.0版本之前出现，之后这个内存泄露问题已经解决了，所以不检查。  

**(23) Unconditional Logging Calls**  
实现：`LogDetector`  
说明：`BuildConfig`类(它是从Tools 17开始有的)提供了一个变量`DEBUG`，用来表示这个代码是在release模式还是debug模式下。如果是在release模式下，通常我们需要将所有的日志输出部分的代码去掉，庆幸的是，编译器会自动地将所有代码中用`if(false)`包围的语句块删除掉，所以推荐打log的时候加上对`BuildConfig.DEBUG`的判断。  

**(24) Mismatched Log Tags**  
实现：`LogDetector`  
说明：这个检查项是检查打log时判断是否可以打印的tag与实际打印的log的tag是否是统一的，也就是`Log.isLoggable(tag)`和`Log.v(tag, ...)`这两个语句中的tag必须是一致的。

持续添加中...
