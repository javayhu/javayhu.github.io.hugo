---
title: Fab and Dialog Morphing Animation
tags: ["android"]
date: "2015-12-13"
---
Fab and Dialog Morphing Animation on Android. <!--more-->

最近在读[Plaid](https://github.com/nickbutcher/plaid)的源码，发现fab和dialog之间切换的动画效果好舒服，于是就研究了下，将其从Plaid项目中抽离出来，然后再改进了些代码，更加方便易懂，也更加简单易用。效果如下，[项目源码地址](https://github.com/hujiaweibujidao/FabDialogMorph)

![image](/images/fabdialog.gif)

#### 实现原理分析
1.在前面的[《Android群英传》的读书笔记](/blog/2015/11/29/Android-Heroes-Reading-Notes-5/)中提到过Activity共享元素过渡动画的实现方式

**共享元素过渡动画**：一个共享元素过渡动画决定两个Activity之间的过渡怎么共享它们的视图，包括了
`changeBounds`：改变目标视图的布局边界；
`changeClipBounds`：裁剪目标视图的边界；
`changeTransform`：改变目标视图的缩放比例和旋转角度；
`changeImageTransform`：改变目标图片的大小和缩放比例。
使用方式：假设Activity从A跳转到B，那么将A中原来的`startActivity`改为如下代码：
```
//单个共享元素的调用方式
startActivity(intent,ActivityOptions.makeSceneTransitionAnimation(this, view, "share").toBundle());
//多个共享元素的调用方式
startActivity(intent,ActivityOptions.makeSceneTransitionAnimation(this,
                Pair.create(view, "share"),
                Pair.create(fab, "fab")).toBundle());
```
然后在B的onCreate方法中添加如下代码：
```
//声明需要开启Activity过渡动画
getWindow().requestFeature(Window.FEATURE_CONTENT_TRANSITIONS);
```
其次还要在Activity A和B的布局文件中为共享元素组件添加`android:transitionName="xxx"`属性。

2.源码中的Dialog实际上是Activity，并设置了`android:windowIsTranslucent`为`true`，所以从fab到dialog的动画效果实际上是Activity的过渡动画。但是，如果单纯的只是使用Activity的共享元素过渡动画，将fab作为共享元素的话，效果并不好，不是那么的舒服。

3.为了让过渡效果更加舒服，这里添加了两个渐变效果，一个是`color`，从fab的颜色到dialog的背景颜色的渐变；另一个是`cornerRadius`，即圆角幅度的渐变。请看下面的代码实现：
```
/**
 * MorphTransition扩展自ChangeBounds(共享元素的动画的一种)，它在原有动画基础上添加了color和cornerRadius的动画效果，这个类实际上是整合了MorphFabToDialog和MorphDialogToFab两个类的作用
 * <p/>
 * A transition that morphs a circle into a rectangle, changing it's background color.
 */
public class MorphTransition extends ChangeBounds {

    private static final String PROPERTY_COLOR = "color";
    private static final String PROPERTY_CORNER_RADIUS = "cornerRadius";
    private static final String[] TRANSITION_PROPERTIES = {
            PROPERTY_COLOR,
            PROPERTY_CORNER_RADIUS
    };

    private int startColor = Color.TRANSPARENT;
    private int endColor = Color.TRANSPARENT;
    private int startCornerRadius = 0;
    private int endCornerRadius = 0;
    private boolean isShowViewGroup = false;

    public MorphTransition(int startColor, int endColor, int startCornerRadius, int endCornerRadius, boolean isShowViewGroup) {
        super();
        setStartColor(startColor);
        setEndColor(endColor);
        setStartCornerRadius(startCornerRadius);
        setEndCornerRadius(endCornerRadius);
        setIsShowViewGroup(isShowViewGroup);
    }

    public MorphTransition(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @Override
    public String[] getTransitionProperties() {
        return TRANSITION_PROPERTIES;
    }

    @Override
    public void captureStartValues(TransitionValues transitionValues) {
        super.captureStartValues(transitionValues);
        final View view = transitionValues.view;
        if (view.getWidth() <= 0 || view.getHeight() <= 0) {
            return;
        }
        transitionValues.values.put(PROPERTY_COLOR, startColor);
        transitionValues.values.put(PROPERTY_CORNER_RADIUS, startCornerRadius);//view.getHeight() / 2
    }

    @Override
    public void captureEndValues(TransitionValues transitionValues) {
        super.captureEndValues(transitionValues);
        final View view = transitionValues.view;
        if (view.getWidth() <= 0 || view.getHeight() <= 0) {
            return;
        }
        transitionValues.values.put(PROPERTY_COLOR, endColor);//ContextCompat.getColor(view.getContext(), R.color.dialog_background_color)
        transitionValues.values.put(PROPERTY_CORNER_RADIUS, endCornerRadius);
    }

    @Override
    public Animator createAnimator(final ViewGroup sceneRoot, TransitionValues startValues, final TransitionValues endValues) {
        Animator changeBounds = super.createAnimator(sceneRoot, startValues, endValues);
        if (startValues == null || endValues == null || changeBounds == null) {
            return null;
        }

        Integer startColor = (Integer) startValues.values.get(PROPERTY_COLOR);
        Integer startCornerRadius = (Integer) startValues.values.get(PROPERTY_CORNER_RADIUS);
        Integer endColor = (Integer) endValues.values.get(PROPERTY_COLOR);
        Integer endCornerRadius = (Integer) endValues.values.get(PROPERTY_CORNER_RADIUS);

        if (startColor == null || startCornerRadius == null || endColor == null || endCornerRadius == null) {
            return null;
        }

        MorphDrawable background = new MorphDrawable(startColor, startCornerRadius);
        endValues.view.setBackground(background);

        Animator color = ObjectAnimator.ofArgb(background, background.COLOR, endColor);
        Animator corners = ObjectAnimator.ofFloat(background, background.CORNER_RADIUS, endCornerRadius);

        ////......

        AnimatorSet transition = new AnimatorSet();
        transition.playTogether(changeBounds, corners, color);
        transition.setDuration(300);
        transition.setInterpolator(AnimationUtils.loadInterpolator(sceneRoot.getContext(), android.R.interpolator.fast_out_slow_in));
        return transition;
    }

    public void setEndColor(int endColor) {
        this.endColor = endColor;
    }

    public void setEndCornerRadius(int endCornerRadius) {
        this.endCornerRadius = endCornerRadius;
    }

    public void setStartColor(int startColor) {
        this.startColor = startColor;
    }

    public void setStartCornerRadius(int startCornerRadius) {
        this.startCornerRadius = startCornerRadius;
    }

    public void setIsShowViewGroup(boolean isShowViewGroup) {
        this.isShowViewGroup = isShowViewGroup;
    }
}
```

4.上面的代码中用到了`MorphDrawable`类，它继承自`Drawable`，并添加了前面提到的那两个属性以用于产生属性动画，默认是没有为那两个属性添加`set/get`方法的，所以需要进行扩展。关于属性动画可以看[以前的读书笔记](/blog/2015/11/27/Android-Heros-Reading-Notes-3/)，重要代码如下：

```
/**
 * 形态和颜色可以发生变化的Drawable，形态变化是通过cornerRadius来实现的，颜色变化是通过paint的color来实现的
 * 该类在Drawable的基础上添加了cornerRadius和color两个属性，前者是float类型，后者是int类型
 * <p/>
 * A drawable that can morph size, shape (via it's corner radius) and color.  Specifically this is
 * useful for animating between a FAB and a dialog.
 */
public class MorphDrawable extends Drawable {

    private Paint paint;
    private float cornerRadius;

    public static final Property<MorphDrawable, Float> CORNER_RADIUS = new Property<MorphDrawable, Float>(Float.class, "cornerRadius") {

        @Override
        public void set(MorphDrawable morphDrawable, Float value) {
            morphDrawable.setCornerRadius(value);
        }

        @Override
        public Float get(MorphDrawable morphDrawable) {
            return morphDrawable.getCornerRadius();
        }
    };

    public static final Property<MorphDrawable, Integer> COLOR = new Property<MorphDrawable, Integer>(Integer.class, "color") {

        @Override
        public void set(MorphDrawable morphDrawable, Integer value) {
            morphDrawable.setColor(value);
        }

        @Override
        public Integer get(MorphDrawable morphDrawable) {
            return morphDrawable.getColor();
        }
    };

    public MorphDrawable(@ColorInt int color, float cornerRadius) {
        this.cornerRadius = cornerRadius;
        paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        paint.setColor(color);
    }

    public float getCornerRadius() {
        return cornerRadius;
    }

    public void setCornerRadius(float cornerRadius) {
        this.cornerRadius = cornerRadius;
        invalidateSelf();
    }

    public int getColor() {
        return paint.getColor();
    }

    public void setColor(int color) {
        paint.setColor(color);
        invalidateSelf();
    }

    @Override
    public void draw(Canvas canvas) {
        canvas.drawRoundRect(getBounds().left, getBounds().top, getBounds().right, getBounds()
                .bottom, cornerRadius, cornerRadius, paint);//hujiawei
    }

    @Override
    public void getOutline(Outline outline) {
        outline.setRoundRect(getBounds(), cornerRadius);
    }

    @Override
    public void setAlpha(int alpha) {
        paint.setAlpha(alpha);
        invalidateSelf();
    }

    @Override
    public void setColorFilter(ColorFilter cf) {
        paint.setColorFilter(cf);
        invalidateSelf();
    }

    @Override
    public int getOpacity() {
        return paint.getAlpha();
    }

}
```

5.有了前面的准备之后，就可以在dialog中配置进入和退出的动画效果了，重要代码如下：
```
//DialogActivity.java
public void setupSharedEelementTransitions2() {
    ArcMotion arcMotion = new ArcMotion();
    arcMotion.setMinimumHorizontalAngle(50f);
    arcMotion.setMinimumVerticalAngle(50f);

    Interpolator easeInOut = AnimationUtils.loadInterpolator(this, android.R.interpolator.fast_out_slow_in);

    //hujiawei 100是随意给的一个数字，可以修改，需要注意的是这里调用container.getHeight()结果为0
    MorphTransition sharedEnter = new MorphTransition(ContextCompat.getColor(this, R.color.fab_background_color),
            ContextCompat.getColor(this, R.color.dialog_background_color), 100, getResources().getDimensionPixelSize(R.dimen.dialog_corners), true);
    sharedEnter.setPathMotion(arcMotion);
    sharedEnter.setInterpolator(easeInOut);

    MorphTransition sharedReturn = new MorphTransition(ContextCompat.getColor(this, R.color.dialog_background_color),
            ContextCompat.getColor(this, R.color.fab_background_color), getResources().getDimensionPixelSize(R.dimen.dialog_corners), 100,  false);
    sharedReturn.setPathMotion(arcMotion);
    sharedReturn.setInterpolator(easeInOut);

    if (container != null) {
        sharedEnter.addTarget(container);
        sharedReturn.addTarget(container);
    }
    getWindow().setSharedElementEnterTransition(sharedEnter);
    getWindow().setSharedElementReturnTransition(sharedReturn);
}
```

6.从上面的分析可以看出，这个方案比较容易扩展，只要是该类型的动画，使用开始和结束时的对应颜色和圆角值就可以构造相应的`MorphTransition`，将`MorphTransition`设置为Activity的进入或者退化动画即可生效啦。同理，如果有类似共享元素过渡动画效果的时候，也就知道应该做哪些步骤来实现它啦，看Plaid真是受益匪浅啊，推荐大家一起看。

以上是我的分析和理解，有任何问题欢迎大家指点 ↖(^ω^)↗
