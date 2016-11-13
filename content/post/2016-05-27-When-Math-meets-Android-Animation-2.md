---
title: When Math meets Android Animation (2)
tags: ["android"]
date: "2016-05-27"
---
当数学遇上动画：讲述`ValueAnimator`、`TypeEvaluator`和`TimeInterpolator`之间的恩恩怨怨(2)<!--more-->

[上一节](/blog/2016/05/26/when-math-meets-android-animation-1/)的结论是，`ValueAnimator`就是由`TimeInterpolator`和`TypeEvaluator`这两个简单函数组合而成的一个复合函数。如下图所示：

![img](/images/valueanimator_math.png)

上一节我们还将`TimeInterpolator`和`TypeEvaluator`看作是工厂流水线上的两个小员工，那么`ValueAnimator`就是车间主管，`TimeInterpolator`这个小员工面对的是产品的半成品，他负责控制半成品输出到下一个生产线的速度，而下一个生产线上的小员工`TypeEvaluator`的任务就是打磨半成品得到成品，最后将成品输出。

本小节进一步深究`TimeInterpolator`和`TypeEvaluator`在动画实现过程中承担的作用以及它们之间的联系与差异。
还是先说结论，借助`TimeInterpolator`或者`TypeEvaluator`**"单独"**来控制动画所产生的动画效果殊途同归！

### **1 两种特殊情况下的ValueAnimator**

(1)上一节提到过，假设`TimeInterpolator`是`LinearInterpolator`（线性插值器，**f(t)=t**），也就是说时间比率不被“篡改”的话，那么`ValueAnimator`对应的函数其实就简化成了`TypeEvaluator`函数（**F=g(x,a,b)=g(f(t),a,b)=g(t,a,b)**），即动画实际上只由`TypeEvaluator`来控制。

这里可以理解为，`TimeInterpolator`这个员工请假了，但是工厂为了不停止生产安排了一个自动机器人代替他的工作，它只会匀速地将半成品输入到下一个生产线。

(2)同理，我们假设`TypeEvaluator`是`“LinearTypeEvaluator”`（线性估值器，并没有这个说法，所以加上引号，计算方式就是**g(x,a,b)=a+x*(b-a)**）的话，那么`ValueAnimator`对应的函数也可以简化，**F=g(x,a,b)=g(f(t),a,b)=a+f(t)*(b-a)**，即动画实际上只由`TimeInterpolator`来控制。

同样的，这里可以理解为，`TypeEvaluator`这个员工请假了，默认也有个自动机器人采用默认的操作将半成品加工成最终成品输出。

(3)综上所述，我们来思考上一节留下的问题，即`TimeInterpolator`和`TypeEvaluator`到底啥关系？
其实`TimeInterpolator`是用来控制动画速度的，而`TypeEvaluator`是用来控制动画中值的变化曲线的。
虽然它们本质的作用是不同的，但是它们两个既可以联手来控制动画，也可以`"单独"`来控制动画（**并非真的单独，而是另一方有个默认操作**）。
单独控制动画的典型例子就是上一节提到的[EaseInterpolator](https://github.com/cimi-chen/EaseInterpolator)和[AnimationEasingFunctions](https://github.com/daimajia/AnimationEasingFunctions)，这两个项目对于制作动画起到殊途同归作用。

为什么说`TimeInterpolator`和`TypeEvaluator`对于制作动画有着殊途同归的作用呢？
不难想象，**在某些定制的情况下，上面两种特殊情况下的构造出来的`ValueAnimator`所产生的动画效果是一样的！**
那如何来验证我们的这个结论呢？我们可以通过构造两个不同的特殊情况下的`ValueAnimator`来验证。

下面的代码显示了两个`ValueAnimator`，都是在1s中内将float类型的数值从0变化到1。第一个`ValueAnimator`使用的是`LinearInterpolator`和自定义的`TypeEvaluator`，第二个`ValueAnimator`使用的是自定义的`TimeInterpolator`和`"LinearTypeEvaluator"`。打印输出的是两个`ValueAnimator`每次值变化的时候的大小。

```
ValueAnimator animator1 = new ValueAnimator();
animator1.setFloatValues(0.0f, 1.0f);
animator1.setDuration(1000);
animator1.setInterpolator(new LinearInterpolator());//传入null也是LinearInterpolator
animator1.setEvaluator(new TypeEvaluator() {
    @Override
    public Object evaluate(float fraction, Object startValue, Object endValue) {
        return 100 * fraction;
    }
});
animator1.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
    @Override
    public void onAnimationUpdate(ValueAnimator animation) {
        Log.e("demo 1", "" + animation.getAnimatedValue());
    }
});

ValueAnimator animator2 = new ValueAnimator();
animator2.setFloatValues(0.0f, 1.0f);
animator2.setDuration(1000);
animator2.setInterpolator(new Interpolator() {
    @Override
    public float getInterpolation(float input) {
        return 100 * input;
    }
});
animator2.setEvaluator(new TypeEvaluator() {
    @Override
    public Object evaluate(float fraction, Object startValue, Object endValue) {
        return fraction;
    }
});
animator2.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
    @Override
    public void onAnimationUpdate(ValueAnimator animation) {
        Log.e("demo 2", "" + animation.getAnimatedValue());
    }
});

animator1.start();
animator2.start();
```

打印输出的结果如下图所示，从图中可以看出，两个`ValueAnimator`的在真实时间序列中的输出结果是一样的，也就说明如果将它们作用在同一个View组件的某个属性上的话，那么产生的动画效果是完全一样的。例如，可以将两个`ValueAnimator`改成`ObjectAnimator`，并将其作用在两个不同的TextView的`translationY`属性上，你可以看到一样的动画效果。所以说，在特殊的单独控制动画的情况下，`TimeInterpolator`和`TypeEvaluator`对于制作动画有着殊途同归的作用。（注意结论的前提，那就是在我们理解了`ValueAnimator`内部动画原理之后自己定制的一些特殊情况，它们并非总是能够产生一样的动画效果）

![img](/images/valuaanimator.png)

### **2 简单动画实例分析：弹跳！**

经过前面的分析，我们差不多理解了`ValueAnimator`是怎么借助`TimeInterpolator`和`TypeEvaluator`来实现动画的了。在实现动画的时候，为了简便，我们常常可以选择将`TimeInterpolator`设置为`LinearInterpolator`或者将`TypeEvaluator`设置为`"LinearTypeEvaluator"`这两种特殊的方式。

举个栗子！假设我们要来实现弹跳的动画效果。首先我们要确定一个弹跳效果的函数曲线，自己想不太好想，我们先来看看项目[EaseInterpolator](https://github.com/cimi-chen/EaseInterpolator)中的`EaseBounceOutInterpolator`内部表示的函数曲线的形态。如下图所示，它是一个分段函数，每个段内都是一个简单的二次曲线。如果将这个曲线作用在View组件的`translationY`属性上，那么组件将在垂直方向上来回地跳动从而就形成了弹跳的效果。

![img](/images/bounce_curve.png)

我们先看下`EaseBounceOutInterpolator`的核心方法`getInterpolation`的实现，它其实就是刻画了上面的函数曲线。
```
//传入的参数input就是动画的时间比率值fraction
public float getInterpolation(float input) {
  if (input < (1 / 2.75))
    return (7.5625f * input * input);
  else if (input < (2 / 2.75))
    return (7.5625f * (input -= (1.5f / 2.75f)) * input + 0.75f);
  else if (input < (2.5 / 2.75))
    return (7.5625f * (input -= (2.25f / 2.75f)) * input + 0.9375f);
  else
    return (7.5625f * (input -= (2.625f / 2.75f)) * input + 0.984375f);
}
```

我们再看下[AnimationEasingFunctions](https://github.com/daimajia/AnimationEasingFunctions)项目中实现这个效果的Easing函数类`BounceEaseOut`，它继承自`BaseEasingMethod`，而`BaseEasingMethod`类实现了`TypeEvaluator`接口。
`BounceEaseOut`类整理出来得到的核心方法`evaluate`的实现如下：
```
@Override
public final Float evaluate(float fraction, Number startValue, Number endValue) {
    float t = mDuration * fraction;//已经过去的时间
    float b = startValue.floatValue();//起始值
    float c = endValue.floatValue() - startValue.floatValue();//结束值与起始值之间的差值
    float d = mDuration;//总的时间间隔，t/d 就是已经过去的时间占总时间间隔的比率

    if ((t /= d) < (1 / 2.75f)) {
        return c * (7.5625f * t * t) + b;
    } else if (t < (2 / 2.75f)) {
        return c * (7.5625f * (t -= (1.5f / 2.75f)) * t + .75f) + b;
    } else if (t < (2.5 / 2.75)) {
        return c * (7.5625f * (t -= (2.25f / 2.75f)) * t + .9375f) + b;
    } else {
        return c * (7.5625f * (t -= (2.625f / 2.75f)) * t + .984375f) + b;
    }
}
```

仔细看下这两个函数的实现很不难发现，如果`EaseBounceOutInterpolator`+`"LinearEvaluator"`（IntEvaluator或者FloatEvaluator）得到的结果与`LinearInterpolator`+`BounceEaseOut`(TypeEvaluator)得到的结果是一样的啊！我们可以再写个例子作用在两个View上看下效果。

例子代码，作用在两个不同的TextView上的两个不同的ObjectAnimator：
```
//第一个ObjectAnimator
final ObjectAnimator animator1 = new ObjectAnimator();
animator1.setTarget(textView1);
animator1.setPropertyName("translationY");
animator1.setFloatValues(0f, -100f);
animator1.setDuration(1000);
animator1.setInterpolator(new LinearInterpolator());//使用线性插值器
animator1.setEvaluator(new TypeEvaluator<Number>() {//自定义的TypeEvaluator
    @Override
    public Number evaluate(float fraction, Number startValue, Number endValue) {
        float t = animator1.getDuration() * fraction;//已经过去的时间
        float b = startValue.floatValue();//起始值
        float c = endValue.floatValue() - startValue.floatValue();//结束值与起始值之间的差值
        float d = animator1.getDuration();//总的时间间隔，t/d 就是已经过去的时间占总时间间隔的比率

        if ((t /= d) < (1 / 2.75f)) {
            return c * (7.5625f * t * t) + b;
        } else if (t < (2 / 2.75f)) {
            return c * (7.5625f * (t -= (1.5f / 2.75f)) * t + .75f) + b;
        } else if (t < (2.5 / 2.75)) {
            return c * (7.5625f * (t -= (2.25f / 2.75f)) * t + .9375f) + b;
        } else {
            return c * (7.5625f * (t -= (2.625f / 2.75f)) * t + .984375f) + b;
        }
    }
});
animator1.start();

//第二个ObjectAnimator
final ObjectAnimator animator2 = new ObjectAnimator();
animator2.setTarget(textView2);
animator2.setPropertyName("translationY");
animator2.setFloatValues(0f, -100f);
animator2.setDuration(1000);
animator2.setInterpolator(new TimeInterpolator() {//自定义的TimeInterpolator
    @Override
    public float getInterpolation(float input) {
        if (input < (1 / 2.75))
            return (7.5625f * input * input);
        else if (input < (2 / 2.75))
            return (7.5625f * (input -= (1.5f / 2.75f)) * input + 0.75f);
        else if (input < (2.5 / 2.75))
            return (7.5625f * (input -= (2.25f / 2.75f)) * input + 0.9375f);
        else
            return (7.5625f * (input -= (2.625f / 2.75f)) * input + 0.984375f);
    }
});
animator2.setEvaluator(new FloatEvaluator());//使用"线性估值器"
animator2.start();
```

接下来看下效果吧，两个动画效果一模一样，这下你相信我说的了吧？哈哈哈，殊途同归！

![img](/images/bounce_animation.gif)

其他的动画效果也是一样的，也就是说项目[AnimationEasingFunctions](https://github.com/daimajia/AnimationEasingFunctions)和项目[EaseInterpolator](https://github.com/cimi-chen/EaseInterpolator)本质上是差不多的，都是定义了一些动画效果对应的函数曲线。前者是将其封装成了TypeEvaluator，后者是将其封装成了Interpolator！
（注：`Interpolator`继承自`TimeInterpolator`，而且接口内部是空的，所以和`TimeInterpolator`本质是一样的，它是为了兼容低版本而添加的。）

本文只是想验证本文开头的结论，借助`TimeInterpolator`或者`TypeEvaluator`**"单独"**来控制动画所产生的动画效果殊途同归！当然，你肯定可以同时使用自定义的`TimeInterpolator`和自定义的`TypeEvaluator`结合来控制动画，但是很显然，这种情况下的动画不容易控制。
从数学中函数的角度上来说那就是复合函数肯定比简单函数复杂，我们解决问题的时候要可能化繁为简，所以自然会考虑将`ValueAnimator`这个复杂函数简化成特殊情况下的简单函数`TimeInterpolator`或者`TypeEvaluator`来处理对吧？

关于`ValueAnimator`和`TimeInterpolator`、`TypeEvaluator`之间的恩恩怨怨讲到这里其实已经讲得差不多了，猜猜下一节我会说啥？~(≧▽≦)/~

请继续看[下一节](/blog/2016/05/28/when-math-meets-android-animation-3/)。
