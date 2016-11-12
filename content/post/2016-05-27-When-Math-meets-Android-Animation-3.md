---
title: When Math meets Android Animation (3)
categories: "android"
date: "2016-05-27"
---
当数学遇上动画：讲述`ValueAnimator`、`TypeEvaluator`和`TimeInterpolator`之间的恩恩怨怨(3)<!--more-->

上一节我们得到一个重要的结论，借助`TimeInterpolator`或者`TypeEvaluator`**"单独"** 来控制动画所产生的动画效果殊途同归！

此外，上一节结尾我们还说到，项目[AnimationEasingFunctions](https://github.com/daimajia/AnimationEasingFunctions)和项目[EaseInterpolator](https://github.com/cimi-chen/EaseInterpolator)本质上是差不多的，都是定义了一些动画效果对应的函数曲线。前者是将其封装成了`TypeEvaluator`，后者是将其封装成了`Interpolator`！

这一节我们来研究下这些函数曲线。

### **1 缓动函数曲线**

下图显示了常见的这些函数曲线，到底这些函数曲线都是什么鬼呢？

![img](/images/easingfuctions.png)

这些函数曲线最早是由[Robert Penner](https://www.linkedin.com/in/robertpenner)提出来用于实现补间动画的`"Penner easing functions"`，这些曲线主要分成10类，包括`"BACK", "BOUNCE", "CIRCULAR", "ELASTIC", "EXPO", "QUAD", "CUBIC", "QUART", "QUINT", "SINE"`，每一类下面都有缓动进入、缓动退出以及缓动进入和退出三种效果，所以共有30个。这些效果对照着函数曲线来看其实也挺好理解，`"QUAD", "CUBIC", "QUART", "QUINT"`分别对应着二次、三次、四次以及五次曲线，`"SINE"`对应正弦函数曲线，`"EXPO"`对应指数函数曲线等等。其中`"BACK"`和`"ELASTIC"`有上冲和下冲的效果。

Robert Penner在Github上开源了[jQuery的版本实现](https://github.com/danro/jquery-easing/blob/master/jquery.easing.js)，随后也就有了很多不同语言版本的实现，例如Java版本的[jesusgollonet/processing-penner-easing](https://github.com/jesusgollonet/processing-penner-easing)以及代码家的Android版本的[AnimationEasingFunctions](https://github.com/daimajia/AnimationEasingFunctions)等等。

这些版本的实现都是4个参数的，分别是起始值`b`、数值间隔`c`（结束值-起始值）、当前时间`t`、时间间隔`d`。

```
//不带缓动，也就是前面说的“线性”估值器
function noEasing (t, b, c, d) {
	return c * (t / d) + b;
}

//带缓动效果，例如二次曲线形式
easeInQuad: function (t, b, c, d) { //缓动进入
	return c*(t/=d)*t + b;
},
easeOutQuad: function (t, b, c, d) {//缓动退出
	return -c *(t/=d)*(t-2) + b;
},
easeInOutQuad: function (t, b, c, d) {//缓动进入和退出
	if ((t/=d/2) < 1) return c/2*t*t + b;
	return -c/2 * ((--t)*(t-2) - 1) + b;
},
```

那为什么与之殊途同归的[EaseInterpolator](https://github.com/cimi-chen/EaseInterpolator)是1个参数的呢？

```
//QuadInOut Interpolator
public float getInterpolation(float input) {
  if((input /= 0.5f) < 1) {
    return 0.5f * input * input;
  }
  return -0.5f * ((--input) * (input - 2) - 1);
}
```

这是因为当`Interpolator`传入到后面的`TypeEvaluator`的时候就有了起始值、结束值以及时间间隔（时间间隔定义在缓动函数内部，只有部分缓动函数需要这个参数）这3个参数，可以参考下面的代码来理解，所以说，它们在本质上还是一样的！

```
fraction = getInterpolation(input)  ==> 这种1个参数形式其实也可以等效于 easingfunction(currentTime, 0, 1, totalTime)
value = evaluate(fraction, startValue, endValue) = startValue + fraction * (endValue - startValue)  
```

### **2 One more thing**

看到这里的话，我们就会想啦，如果我们把函数曲线抽象出来，然后再提供相应的转换方法，使其轻轻松松地转换成`Interpolator`和`TypeEvaluator`的话，如此，岂不善哉？

所以，我就站在众多巨人们的肩膀上，写了一个新项目[Yava](https://github.com/hujiaweibujidao/yava)，项目代码非常简单，而且代码很少只有4个重要的类，它实现的功能就是将抽象的函数曲线轻松转换成立即可用的`Interpolator`和`TypeEvaluator`，并且提供了常见的30个缓动函数(Easing Functions)的实现，它们既可以当做`Interpolator`来用，又可以当做`TypeEvaluator`来用，非常方便。

这里我直接把这4个重要类的代码贴出来吧。

(1) `IFunction`接口
```
/**
 * 函数接口：给定输入，得到输出
 */
public interface IFunction {
    float getValue(float input);
}
```

(2)`AbstractFunction`抽象类

```
/**
 * 抽象函数实现，既可以当做简单函数使用，也可以当做Interpolator或者TypeEvaluator去用于制作动画
 */
public abstract class AbstractFunction implements IFunction, Interpolator, TypeEvaluator<Float> {

    @Override
    public float getInterpolation(float input) {
        return getValue(input);
    }

    @Override
    public Float evaluate(float fraction, Float startValue, Float endValue) {
        return startValue + getValue(fraction) * (endValue - startValue);
    }
}
```

(3)`Functions`类
```
/**
 * 工具类，将自定义的函数快速封装成AbstractFunction
 */
class Functions {

    public static AbstractFunction with(final IFunction function) {
        return new AbstractFunction() {
            @Override
            public float getValue(float input) {
                return function.getValue(input);
            }
        };
    }
}
```

(4)`EasingFunction`枚举：包含了30个常见的缓动函数
```
/**
 * 常见的30个缓动函数的实现
 */
public enum EasingFunction implements IFunction, Interpolator, TypeEvaluator<Float> {

    /* ------------------------------------------------------------------------------------------- */
    /* BACK
    /* ------------------------------------------------------------------------------------------- */
    BACK_IN {
        @Override
        public float getValue(float input) {
            return input * input * ((1.70158f + 1) * input - 1.70158f);
        }
    },
    BACK_OUT {
        @Override
        public float getValue(float input) {
            return ((input = input - 1) * input * ((1.70158f + 1) * input + 1.70158f) + 1);
        }
    },
    BACK_INOUT {
        @Override
        public float getValue(float input) {
            float s = 1.70158f;
            if ((input *= 2) < 1) {
                return 0.5f * (input * input * (((s *= (1.525f)) + 1) * input - s));
            }
            return 0.5f * ((input -= 2) * input * (((s *= (1.525f)) + 1) * input + s) + 2);
        }
    },

    //other easing functions ......

    //如果这个function在求值的时候需要duration作为参数的话，那么可以通过setDuration来设置，否则使用默认值
    private float duration = 1000f;//目前只有ELASTIC***这三个是需要duration的，其他的都不需要

    public float getDuration() {
        return duration;
    }

    public EasingFunction setDuration(float duration) {
        this.duration = duration;
        return this;
    }

    //将Function当做Interpolator使用，默认的实现，不需要枚举元素去重新实现
    @Override
    public float getInterpolation(float input) {
        return getValue(input);
    }

    //将Function当做TypeEvaluator使用，默认的实现，不需要枚举元素去重新实现
    @Override
    public Float evaluate(float fraction, Float startValue, Float endValue) {
        return startValue + getValue(fraction) * (endValue - startValue);
    }

    //几个数学常量
    public static final float PI = (float) Math.PI;
    public static float TWO_PI = PI * 2.0f;
    public static float HALF_PI = PI * 0.5f;
}
```

这个项目的缓动函数的实现参考自[EaseInterpolator](https://github.com/cimi-chen/EaseInterpolator)中的实现，但是这个项目的代码和EaseInterpolator以及AnimationEasingFunctions这两个项目都完全不一样，非常简单易懂，既保留了原有项目应有的功能，同时为项目的使用场景提供了更多的可能，任何你想使用`Interpolator`或者`TypeEvaluator`都能使用它。

举个例子，以上一节中的弹跳动画效果为例，现在可以直接使用`EasingFunction.BOUNCE_OUT`作为`Interpolator`或者`TypeEvaluator`来使用：

第一种方式：使用线性插值器和自定义的TypeEvaluator

```
ObjectAnimator animator1 = new ObjectAnimator();
animator1.setTarget(textView1);
animator1.setPropertyName("translationY");
animator1.setFloatValues(0f, -100f);
animator1.setDuration(1000);
animator1.setInterpolator(new LinearInterpolator());
animator1.setEvaluator(EasingFunction.BOUNCE_OUT); //这里将EasingFunction.BOUNCE_OUT作为TypeEvaluator来使用
animator1.start();
```

第二种方式：使用自定义的Interpolator和"线性估值器"

```
ObjectAnimator animator2 = new ObjectAnimator();
animator2.setTarget(textView2);
animator2.setPropertyName("translationY");
animator2.setFloatValues(0f, -100f);
animator2.setDuration(1000);
animator2.setInterpolator(EasingFunction.BOUNCE_OUT); //这里将EasingFunction.BOUNCE_OUT作为Interpolator来使用
animator2.setEvaluator(new FloatEvaluator());
animator2.start();
```

如果你想使用自己定义的函数来制作动画，可以使用`Functions`的`with`方法，传入一个实现了`IFunction`接口的类就行，返回值你既可以当做`Interpolator`，也可以当做`TypeEvaluator`来使用

代码示例：

```
ObjectAnimator animator1 = new ObjectAnimator();
animator1.setTarget(textView1);
animator1.setPropertyName("translationY");
animator1.setFloatValues(0f, -100f);
animator1.setDuration(1000);
animator1.setInterpolator(new LinearInterpolator());
animator1.setEvaluator(Functions.with(new IFunction() { //自定义为TypeEvaluator
    @Override
    public float getValue(float input) {
        return input * 2 + 3;
    }
}));
animator1.start();
```

或者这样：

```
ObjectAnimator animator2 = new ObjectAnimator();
animator2.setTarget(textView2);
animator2.setPropertyName("translationY");
animator2.setFloatValues(0f, -100f);
animator2.setDuration(1000);
animator2.setInterpolator(Functions.with(new IFunction() { //自定义为Interpolator
    @Override
    public float getValue(float input) {
        return input * 2 + 3;
    }
}));
animator2.setEvaluator(new FloatEvaluator());
animator2.start();
```

为了方便查看定义出来的`Interpolator`和`TypeEvaluator`的效果，我将前面两个项目中的可视化部分整理到项目[Yava](https://github.com/hujiaweibujidao/yava)中，样例应用还包含了上一节的用来作验证的例子，最终效果如下：

![img](/images/yava.gif)

恭喜你终于看完了，也恭喜自己终于写完了。至此，你可能还有一个疑惑，那就是那些函数曲线是怎么想出来的？这个...我也不知道，我也想知道，别问我，去问[Robert Penner](https://www.linkedin.com/in/robertpenner)吧 😌

最后，我还准备写另一个Android动画效果库[wava](https://github.com/hujiaweibujidao/wava)，神一样的[代码家](https://github.com/daimajia)还做了一个超厉害的项目[AndroidViewAnimations](https://github.com/daimajia/AndroidViewAnimations)，目前我的`wava`只是基于它做些改进，后期我打算加上一些很特别的东西，暂时不表，欢迎关注项目[wava](https://github.com/hujiaweibujidao/wava) 😘   
