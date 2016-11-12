---
title: When Math meets Android Animation (1)
categories: "android"
date: "2016-05-26"
---
当数学遇上动画：讲述`ValueAnimator`、`TypeEvaluator`和`TimeInterpolator`之间的恩恩怨怨(1)<!--more-->

其实关于`ValueAnimator`的内部工作原理大家也都清楚，本文只是选择从数学函数的角度来解析这个原理，方便理解。看完了本节之后我们就更加清楚如何借助`TypeEvaluator`和`TimeInterpolator`来帮助我们实现动画等知识。

本系列文章共有三篇，第一篇通过源码解析`ValueAnimator`类，第二篇通过实例解析`TimeInterpolator`和`TypeEvaluator`，第三篇分析常见动画背后的缓动函数，最后引出一个新的Android动画开发的辅助库[Yava](https://github.com/hujiaweibujidao/yava)。

### **1 Android动画基础知识**

(1)狭义而言，动画一般就是指某个View组件的某个或者某些属性值在一段时间内不断变化的过程，这个变化过程往往有个起始值、结束值和一系列的中间值，`ValueAnimator`就是用来反映这个属性值变化过程的重要类，所以本文的介绍主要是以分析`ValueAnimator`为主。
(2)如果将属性值的变化过程看做一个数学函数的话，从动画效果上来看它是连续的，但实际上它还是离散的，因为它实际上也就是通过插入中间值（简称插值）从而"一帧一帧"完成动画的，那每一帧在哪里取，取多少呢？这也就是`ValueAnimator`类主要完成的作用。

那到底`ValueAnimator`是怎么控制属性值的变化过程的呢？答案是借助`TimeInterpolator`和`TypeEvaluator`来帮忙！`TimeInterpolator`用来控制在哪里取，而`TypeEvaluator`用来控制取多少。（注：取多少个点进行插值是不确定的，例如动画持续时间1s，可能取60，也可能取54、57或者58个中间点进行插值）

先说本小节结论，**每一个`ValueAnimator`其实就是一个的`TimeInterpolator`和一个`TypeEvaluator`的结合体**。从数学的角度来看，`ValueAnimator`就是由`TimeInterpolator`和`TypeEvaluator`这两个简单函数组合而成的一个复合函数。用图来表述如下：

![img](/images/valueanimator_math.png)

你也可以将`TimeInterpolator`和`TypeEvaluator`看作是工厂流水线上的两个小员工，那么`ValueAnimator`就是车间主管啦。`TimeInterpolator`这个小员工面对的是产品的半成品，他负责控制半成品输出到下一个生产线的速度。而下一个生产线上的小员工`TypeEvaluator`的任务就是打磨半成品得到成品，最后将成品输出。

### **2 结合源码解释函数形式**

（1）假设`TimeInterpolator`是函数x=f(t)，t表示**动画已经完成的时间比率**（例如动画的总时长是10s，已经过了4s了，那么t=0.4），所以t的取值范围是[0,1]，0表示动画开始，1表示动画结束。该函数的返回值指的是**动画实际插值的时间点**，一般是0到1之间，但是也可以小于0（"下冲"）或者大于1（"上冲"）。
**该函数的作用是把当前时间进度映射成另一个值，这样动画参照的时间由此被"篡改"，动画的速度由此被改变。** （后面还有详细介绍）

参考接口`TimeInterpolator`的定义：
```
/**
 * A time interpolator defines the rate of change of an animation. This allows animations
 * to have non-linear motion, such as acceleration and deceleration.
 */
public interface TimeInterpolator {
    /**
     * Maps a value representing the elapsed fraction of an animation to a value that represents
     * the interpolated fraction. This interpolated value is then multiplied by the change in
     * value of an animation to derive the animated value at the current elapsed animation time.
     */
    float getInterpolation(float input);
}
```

（2）假设`TypeEvaluator`是函数y=g(x,a,b)，x就是前面函数f(t)篡改之后的插值的时间点，a、b分别表示属性动画的起始值和结束值。
**该函数的作用是通过起始值、结束值以及插值时间点来计算在该时间点的属性值应该是多少。**

参考接口`TypeEvaluator`的定义：
```
/**
 * Interface for use with the {@link ValueAnimator#setEvaluator(TypeEvaluator)} function. Evaluators
 * allow developers to create animations on arbitrary property types, by allowing them to supply
 * custom evaluators for types that are not automatically understood and used by the animation
 * system.
 */
public interface TypeEvaluator<T> {

    /**
     * This function returns the result of linearly interpolating the start and end values, with
     * <code>fraction</code> representing the proportion between the start and end values. The
     * calculation is a simple parametric calculation: <code>result = x0 + t * (x1 - x0)</code>,
     * where <code>x0</code> is <code>startValue</code>, <code>x1</code> is <code>endValue</code>,
     * and <code>t</code> is <code>fraction</code>.
     */
    public T evaluate(float fraction, T startValue, T endValue);
}
```

（3）假设`TimeInterpolator`和`TypeEvaluator`是上面两个简单函数，那么`ValueAnimator`也是一个函数，它其实就是表示`TimeInterpolator`的函数x=f(t)和表示`TypeEvaluator`的函数y=g(x,a,b)结合而成的复合函数`F=g(f(t),a,b)`。

参考`ValueAnimator`中`animateValue`方法的定义：
```
/**
 * This method is called with the elapsed fraction of the animation during every
 * animation frame. This function turns the elapsed fraction into an interpolated fraction
 * and then into an animated value (from the evaluator. The function is called mostly during
 * animation updates, but it is also called when the <code>end()</code>
 * function is called, to set the final value on the property.
 */
void animateValue(float fraction) {
    fraction = mInterpolator.getInterpolation(fraction); //TimeInterpolator 函数
    mCurrentFraction = fraction;
    int numValues = mValues.length;
    for (int i = 0; i < numValues; ++i) {
        mValues[i].calculateValue(fraction); //TypeEvaluator 函数
    }
    if (mUpdateListeners != null) { // 通知监听器
        int numListeners = mUpdateListeners.size();
        for (int i = 0; i < numListeners; ++i) {
            mUpdateListeners.get(i).onAnimationUpdate(this);
        }
    }
}
```

### **3 通俗解析各个击破**

#### **3.1 关于ValueAnimator**

(0)`ValueAnimator`就是一个的`TypeEvaluator`和一个`TimeInterpolator`的结合体，所以该类有两个方法分别用来设置动画的`TypeEvaluator`和`TimeInterpolator`。
(1)`setInterpolator`方法可以不调用，默认是加速减速插值器`AccelerateDecelerateInterpolator`，但是如果调用且传入的参数为null的话，那么就会被设置成线性插值器`LinearInterpolator` **(暂时不清楚为什么要这样做)**。
(2)`setEvaluator`方法也可以不调用，默认会根据属性值的类型设置一个`IntEvaluator`或者`FloatEvaluator`。后面会讲到这类`TypeEvaluator`可以看作是线性估值器`"LinearTypeEvaluator"`（**并没有这个说法，因故加上引号**）。

参考`ValueAnimator`的部分源码：
```
//默认的TimeInterpolator是AccelerateDecelerateInterpolator
// The time interpolator to be used if none is set on the animation
private static final TimeInterpolator sDefaultInterpolator = new AccelerateDecelerateInterpolator();

/**
* The time interpolator used in calculating the elapsed fraction of this animation. The
* interpolator determines whether the animation runs with linear or non-linear motion,
* such as acceleration and deceleration. The default value is
* {@link android.view.animation.AccelerateDecelerateInterpolator}
*
* @param value the interpolator to be used by this animation. A value of <code>null</code>
* will result in linear interpolation.
*/
@Override
public void setInterpolator(TimeInterpolator value) {
   if (value != null) {
       mInterpolator = value;
   } else {
       // 如果传入的TimeInterpolator是null的话就设置为LinearInterpolator
       mInterpolator = new LinearInterpolator();
   }
}

/**
 * The type evaluator to be used when calculating the animated values of this animation.
 * The system will automatically assign a float or int evaluator based on the type
 * of <code>startValue</code> and <code>endValue</code> in the constructor. But if these values
 * are not one of these primitive types, or if different evaluation is desired (such as is
 * necessary with int values that represent colors), a custom evaluator needs to be assigned.
 * For example, when running an animation on color values, the {@link ArgbEvaluator}
 * should be used to get correct RGB color interpolation.
 *
 * <p>If this ValueAnimator has only one set of values being animated between, this evaluator
 * will be used for that set. If there are several sets of values being animated, which is
 * the case if PropertyValuesHolder objects were set on the ValueAnimator, then the evaluator
 * is assigned just to the first PropertyValuesHolder object.</p>
 *
 * @param value the evaluator to be used this animation
 */
public void setEvaluator(TypeEvaluator value) {
    if (value != null && mValues != null && mValues.length > 0) {
        mValues[0].setEvaluator(value);
    }
}
```

(4)**调用`ValueAnimator`的`ofInt`方法时发生了什么**
`ValueAnimator`的`ofInt`方法是创建动画常用的方法，该方法会调用`ValueAnimator`的`setIntValues`，其中调用了`PropertyValuesHolder`的`setIntValues`方法，里面又调用了`KeyframeSet`的`ofInt`方法用来得到动画的帧集合，该方法的实现如下：

```
//根据提供的数字序列得到动画的核心帧集合
public static KeyframeSet ofInt(int... values) {
    int numKeyframes = values.length;//有多少个数字就有多少帧
    IntKeyframe keyframes[] = new IntKeyframe[Math.max(numKeyframes,2)];//至少有2帧
    if (numKeyframes == 1) {//如果只传入一个数字，那么该数字就是结束帧的值
        keyframes[0] = (IntKeyframe) Keyframe.ofInt(0f);
        keyframes[1] = (IntKeyframe) Keyframe.ofInt(1f, values[0]);
    } else {//如果传入多个数字，那么可以将整个动画时间间隔均分，每个数字按顺序在每个时间比率上占据一个属性值
        keyframes[0] = (IntKeyframe) Keyframe.ofInt(0f, values[0]);
        for (int i = 1; i < numKeyframes; ++i) {
            keyframes[i] = (IntKeyframe) Keyframe.ofInt((float) i / (numKeyframes - 1), values[i]);
        }
    }
    return new IntKeyframeSet(keyframes);
}
```

`Keyframe`的`ofInt`方法的签名为`Keyframe ofInt(float fraction, int value)`：前者就是动画已经完成的时间比率，后者是该帧的属性值，它表示在这个特定的时间比率对应的时刻，函数曲线会经过或者非常接近这个属性值(**可能是没有经过，而只是很接近很接近，毕竟是曲线拟合嘛**)。

上面得到的帧只是动画的几个核心帧，肯定不是动画的全部帧，那中间的其他帧是怎么计算的呢？
这个问题我们可以看下`KeyframeSet`的`getValue`方法，方法传入的参数就是动画的时间比率，返回值就是此帧的属性值。

```
/**
 * Gets the animated value, given the elapsed fraction of the animation (interpolated by the
 * animation's interpolator) and the evaluator used to calculate in-between values. This
 * function maps the input fraction to the appropriate keyframe interval and a fraction
 * between them and returns the interpolated value. Note that the input fraction may fall
 * outside the [0-1] bounds, if the animation's interpolator made that happen (e.g., a
 * spring interpolation that might send the fraction past 1.0). We handle this situation by
 * just using the two keyframes at the appropriate end when the value is outside those bounds.
 */
public Object getValue(float fraction) {
    // Special-case optimization for the common case of only two keyframes
    if (mNumKeyframes == 2) {//1.处理只有2帧的情况
        if (mInterpolator != null) {
            //先调用TimeInterpolator函数
            fraction = mInterpolator.getInterpolation(fraction);
        }
        //再调用TypeEvaluator函数
        return mEvaluator.evaluate(fraction, mFirstKeyframe.getValue(), mLastKeyframe.getValue());
    }
    //2.处理上冲和下冲的情况
    if (fraction <= 0f) {
        final Keyframe nextKeyframe = mKeyframes.get(1);
        final TimeInterpolator interpolator = nextKeyframe.getInterpolator();
        if (interpolator != null) {
            fraction = interpolator.getInterpolation(fraction);
        }
        final float prevFraction = mFirstKeyframe.getFraction();
        float intervalFraction = (fraction - prevFraction) / (nextKeyframe.getFraction() - prevFraction);
        return mEvaluator.evaluate(intervalFraction, mFirstKeyframe.getValue(), nextKeyframe.getValue());
    } else if (fraction >= 1f) {
        final Keyframe prevKeyframe = mKeyframes.get(mNumKeyframes - 2);
        final TimeInterpolator interpolator = mLastKeyframe.getInterpolator();
        if (interpolator != null) {
            fraction = interpolator.getInterpolation(fraction);
        }
        final float prevFraction = prevKeyframe.getFraction();
        float intervalFraction = (fraction - prevFraction) / (mLastKeyframe.getFraction() - prevFraction);
        return mEvaluator.evaluate(intervalFraction, prevKeyframe.getValue(), mLastKeyframe.getValue());
    }
    //3.处理正常的多帧的情况
    Keyframe prevKeyframe = mFirstKeyframe;
    //首先要遍历前面计算出的主要KeyFrame集合，看当前的fraction是处在哪个区间的
    for (int i = 1; i < mNumKeyframes; ++i) {
        Keyframe nextKeyframe = mKeyframes.get(i);
        if (fraction < nextKeyframe.getFraction()) {
            final TimeInterpolator interpolator = nextKeyframe.getInterpolator();
            final float prevFraction = prevKeyframe.getFraction();
            //将当前的fraction折算成在这个区间内的时间比率，这个计算有意思吧
            float intervalFraction = (fraction - prevFraction) / (nextKeyframe.getFraction() - prevFraction);
            // Apply interpolator on the proportional duration.
            if (interpolator != null) {
                //先调用TimeInterpolator函数
                intervalFraction = interpolator.getInterpolation(intervalFraction);
            }
            //再调用TypeEvaluator函数
            return mEvaluator.evaluate(intervalFraction, prevKeyframe.getValue(), nextKeyframe.getValue());
        }
        prevKeyframe = nextKeyframe;
    }
    // shouldn't reach here
    return mLastKeyframe.getValue();
}
```

举个简单的例子，下图中的`ValueAnimator`的`TimeInterpolator`是`LinearInterpolator`，它的`TypeEvaluator`是`IntEvaluator`，初始化的时候给定了5个数字，那么核心帧集合中有5帧，此时我们要求当fraction=0.4的时刻的value是多少。

![img](/images/keyframeset_getvalue.png)

#### **3.2 关于TimeInterpolator**

我们都知道时间是一秒一秒过去的，也就是线性的，匀速前进的。如果属性值从起始值到结束值是匀速变化的话，那么整个动画看起来就是慢慢地均匀地变化着。但是，如果我们想让动画变得很快或者变得很慢怎么办？答案是我们可以通过“篡改时间”来完成这个任务！这正是`TimeInterpolator`类的工作，它实际上就是一条函数曲线。

举个栗子！如下图所示，x轴表示时间的比率，y轴表示属性值。在不考虑`TypeEvaluator`的计算的情况下，假设属性值是从0变化到1，默认情况下线性插值器就和曲线y=x一样，在时间t的位置上的值为f(t)=t，**当t=0.5的时刻传给TypeEvaluator的是t=0.5的时刻的值0.5**。但是，当我们将`TimeInterpolator`设置为函数y=x^2或者y=x^(0.5)时，动画的效果就截然不同啦。在t=0.5的时刻，y=x^2=0.25 < 0.5，表示它将时间推迟了，**传给TypeEvaluator的是0.25时刻的值0.25**；而y=x^(0.5)=0.71 > 0.5，表示它将时间提前了，**传给TypeEvaluator的是0.71时刻的值0.71**。

此外，仔细观察曲线的斜率不难发现，**曲线y=x^2的斜率在不断增加，说明变化越来越快，作用在View组件上就是刚开始挺慢的，然后不断加速的效果；而曲线y=x^(0.5)的斜率在不断减小，说明变化越来越慢，作用在View组件上就是刚开始挺快的，然后不断减速的效果。**

![img](/images/interpolator.png)

**推荐在[cubic-bezier.com](http://cubic-bezier.com/)网站中简单绘制和上面两个曲线类似形状的曲线，然后选择线性曲线作为参考，查看方块的运动变化情况。**

Android的动画框架中已经给我们提供了不少实现了`TimeInterpolator`的插值器，包括AccelerateDecelerateInterpolator, AccelerateInterpolator, AnticipateInterpolator, AnticipateOvershootInterpolator, BounceInterpolator, CycleInterpolator, DecelerateInterpolator, LinearInterpolator, OvershootInterpolator, PathInterpolator。

基本上每个插值器其实就对应一条曲线，例如加速减速插值器`AccelerateDecelerateInterpolator`对应的曲线如下，斜率是先增加后减小。

![img](/images/adinterpolator.png)

**那除了Android系统自带的这些，还有哪些常见的`TimeInterpolator`呢？**

不妨看看这个项目[EaseInterpolator](https://github.com/cimi-chen/EaseInterpolator)，作者实现了30种常见动画的`TimeInterpolator`，每个`TimeInterpolator`的曲线形状大致如下图所示 （图片截自[easings.net](http://easings.net/)，项目EaseInterpolator实现了其中的30个效果）
这个项目中的`Ease[XXX]Interpolator`都实现了`Interpolator`接口，而`Interpolator`接口继承自`TimeInterpolator`接口。

![img](/images/easingfuctions.png)

#### **3.3 关于TypeEvaluator**

`TypeEvaluator`实际上也是一条函数曲线，它的输入是`TimeInterpolator`传进来的被“篡改”了的时间比率，还有动画的起始值和结束值信息，输出就是动画当前应该更新的属性值。假设`TimeInterpolator`是`LinearInterpolator`（**f(t)=t**），也就是说时间比率不被“篡改”的话，那么`ValueAnimator`对应的函数其实就简化成了`TypeEvaluator`函数（**F=g(x,a,b)=g(f(t),a,b)=g(t,a,b)**），即动画实际上只由`TypeEvaluator`来控制。

Android系统动画框架中提供了几个`TypeEvaluator`，例如IntEvaluator、FloatEvaluator、ArgbEvaluator、PointEvaluator、PathEvaluator等

`IntEvaluator`的`evaluate`方法的实现：（这类`TypeEvaluator`就是下一节提到的线性估值器`"LinearTypeEvaluator"`）
```
public Integer evaluate(float fraction, Integer startValue, Integer endValue) {
    int startInt = startValue;
    return (int)(startInt + fraction * (endValue - startInt));
}
```

**那除了Android系统自带的这些，还有哪些常见的TypeEvaluator呢？**

这个时候不妨看看[@代码家](https://github.com/daimajia)的经典项目[AnimationEasingFunctions](https://github.com/daimajia/AnimationEasingFunctions)，里面实现了28种常见动画的`TypeEvaluator`，每个`TypeEvaluator`的曲线形状和上面的截自[easings.net](http://easings.net/)的图片一样，代码家实现的动画效果也正是参考自那个项目的效果而想出来的。
项目中的`[XXX]Ease[YYY]`都继承自`BaseEasingMethod`，而`BaseEasingMethod`实现了`TypeEvaluator`接口。

看到这里的话，机智的你肯定发现了，为什么那些`TimeInterpolator`和`TypeEvaluator`的函数曲线形状一样一样的，到底`TimeInterpolator`和`TypeEvaluator`是啥关系啊？在实现动画上它们又有啥区别呢？

请继续看[下一节](/blog/2016/05/27/When-Math-meets-Android-Animation-2/)。
