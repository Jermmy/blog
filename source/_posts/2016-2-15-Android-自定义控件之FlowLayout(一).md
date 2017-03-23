---
title: Android-自定义控件之FlowLayout(一)
tags: Android
categories: Android
---

（首先声明，这篇文章是博主在 mooc 上学习了 hyman 的视频[打造Android流式布局和热门标签](http://mooc.guokr.com/career/3170/%E6%89%93%E9%80%A0Android%E6%B5%81%E5%BC%8F%E5%B8%83%E5%B1%80%E5%92%8C%E7%83%AD%E9%97%A8%E6%A0%87%E7%AD%BE/)后总结的小知识）

<!--more-->

### onMeasure()的两个参数

Android 自定义容器控件时，通常都会继承 ViewGroup 。继承后主要的工作便是覆写 onMeasure 和 onLayout 方法，重新制定布局文件测量以及显示子控件位置的策略。下面的 onMesure 函数摘自官网教程[http://developer.android.com/intl/zh-cn/reference/android/view/ViewGroup.html](http://developer.android.com/intl/zh-cn/reference/android/view/ViewGroup.html)

``` java
    /**
     * Ask all children to measure themselves and compute the measurement of this
     * layout based on the children.
     */
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec)
```

这个函数需要调用 `measureChild` 等方法来测量各种子 View 的宽高，以此来决定 ViewGroup 的宽高。这篇文章主要关注方法中传入的两个参数。以 widthMeasureSpec 为例，它包含的信息不仅仅包括 ViewGroup 的宽度（这个宽高是 ViewGroup 的父控件提供的建议宽高， ViewGroup 可以直接采纳，也可以根据实际情况调整），同时包括宽度的测量模式。什么叫测量模式呢？比方说，如果你设定的 ViewGroup 的宽度为 200 dp，那么这个模式就是精确模式「EXACTLY」，如果宽度为 wrap_content，则对应「AT_MOST」模式，表示要根据子 View 的内容撑到最大。事实上，Android 提供的模式只有三中：「EXACTLY」、「AT_MOST」、「UNSPECIFIED」。对于指定了具体数值或设置为 match_parent 、 fill_parent 的，测量模式均为「EXACTLY」，而 wrap_content 则是「AT_MOST」模式，「UNSPECIFIED」暂不清楚什么时候被使用。

这些模式有什么作用呢？ onMeasure 方法不是要测量 ViewGroup 的宽高吗，如果测量模式是“确切”的(「EXACTLY」)，那我们其实不用做任何处理，直接从 widthMeasureSpec 和 heightMeasureSpec 这两个参数直接获取宽高即可，但如果是「AT_MOST」模式，就需要我们去测量各个子 View 的宽高，并按照我们的规则去计算 ViewGroup 最终的宽高。

那这些模式该如何得到呢？Android提供了一个类 `MeasureSpec `，可以从 onMeasure 的两个参数获得宽高或者测量模式。具体做法是：

``` java
int sizeWidth = MeasureSpec.getSize(widthMeasureSpec);   // 获得宽度
int modeWidth = MeasureSpec.getMode(widthMeasureSpec);   // 获得宽度的测量模式
int sizeHeight = MeasureSpec.getSize(heightMeasureSpec);
int modeHeight = MeasureSpec.getMode(heightMeasureSpec);
```

如果 modeWidth 和 modeHeight 的值都是 `MeasureSpec.EXACTLY `，那么我们可以直接调用 `setMeasuredDimension(sizeWidth, sizeHeight)` 来设定 ViewGroup 的宽高（ setMeasuredDimension 是 ViewGroup 提供的用于设置其宽高的方法，一般在 onMeasure 方法的最后使用）。如果是「AT_MOST」模式，则需要在代码中重新测量宽高，最后再设进去，具体做法后面的文章再讲。

### 三个构造函数

继承 ViewGroup 后一般会提供三个构造函数

``` java
public CustomLayout(Context context) {
  super(context);
}

public CustomLayout(Context context, AttributeSet attrs) {
  this(context, attrs, 0);
}

public CustomLayout(Context context, AttributeSet attrs, int defStyle) {
  super(context, attrs, defStyle);
}
```

这三个函数的用途分别是什么？第一个构造函数一般是用户在代码中用 new 来定义一个实例会使用。第二个构造函数则是用户在 xml 中声明了该控件，且没有使用到自定义属性时用到。第三个构造函数同第二个类似，但它会在使用到自定义属性时被调用，第三个参数 defStyle 表示我们自定义的属性的资源索引(在 R.java 这个类中)。

### getLayoutParams

通常我们用 View 类的 getLayoutParams 方法得到 LayoutParams ，对应的是这个子 View 所在 ViewGroup 的 LayoutParams。例如，如果子 View 在 LinearLayout 内，那这个 LayoutParams 就是 LinearLayout.LayoutParams。那我们自己定义的 ViewGroup 的 LayoutParams 是怎么来的？ ViewGroup 提供了一个方法给开发者覆写

``` java
    /**
     * Returns a new set of layout parameters based on the supplied attributes set.
     *
     * @param attrs the attributes to build the layout parameters from
     *
     * @return an instance of {@link android.view.ViewGroup.LayoutParams} or one
     *         of its descendants
     */
    public LayoutParams generateLayoutParams(AttributeSet attrs) {
        return new LayoutParams(getContext(), attrs);
    }
```

我们可以根据自己的需求，返回一个我们需要的 `LayoutParams` (可以是 `LayoutParams` 也可以是它的子类)。在 FlowLayout 中，我们只需要知道子 View 之间的间隔，因此返回一个 `MarginLayoutParams`。

``` java
    // 与当前ViewGroup对应的LayoutParams
    @Override
    public LayoutParams generateLayoutParams(AttributeSet attrs) {
        return new MarginLayoutParams(getContext(), attrs);
    }
```

