---
title: Android-自定义控件之FlowLayout(一)
tags: Android
---

（首先声明，这篇文章是博主在mooc上学习了hyman的视频[打造Android流式布局和热门标签](http://mooc.guokr.com/career/3170/%E6%89%93%E9%80%A0Android%E6%B5%81%E5%BC%8F%E5%B8%83%E5%B1%80%E5%92%8C%E7%83%AD%E9%97%A8%E6%A0%87%E7%AD%BE/)后总结的小知识）

### onMeasure()的两个参数

Android大大们自定义容器控件时，通常都会继承ViewGroup。继承后主要的工作便是覆写onMeasure和onLayout方法，重新制定布局文件测量以及显示子控件位置的策略。下面的onMesure函数摘自官网教程[http://developer.android.com/intl/zh-cn/reference/android/view/ViewGroup.html](http://developer.android.com/intl/zh-cn/reference/android/view/ViewGroup.html)

``` java
    /**
     * Ask all children to measure themselves and compute the measurement of this
     * layout based on the children.
     */
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec)
```

这个函数需要调用`measureChild`等方法来测量各种子View的宽高，以此来决定ViewGroup的宽高。这篇文章主要关注方法中传入的两个参数。以widthMeasureSpec为例，它包含的信息不仅仅包括ViewGroup的宽度（这个宽高是ViewGroup的父控件提供的建议宽高，ViewGroup可以直接采纳，也可以根据实际情况调整），同时包括宽度的测量模式。什么叫测量模式呢？比方说，如果你设定的ViewGroup的宽度为200dp，那么这个模式就是精确模式("EXACTLY")，如果宽度为wrap_content，则对应AT_MOST模式，表示要根据子View的内容撑到最大。事实上，Android提供的模式只有三中：EXACTLY、AT_MOST、UNSPECIFIED。对于指定了具体数值或设置为match_parent、fill_parent的，测量模式均为EXACTLY，而wrap_content则是AT_MOST模式，UNSPECIFIED暂不清楚什么时候被使用。

这些模式有什么作用呢？onMeasure方法不是要测量ViewGroup的宽高吗，如果测量模式是“确切”的(EXACTLY)，那我们其实不用做任何处理，直接从widthMeasureSpec和heightMeasureSpec这两个参数直接获取宽高即可，但如果是AT_MOST模式，就需要我们去测量各个子View的宽高，并按照我们的规则去计算ViewGroup最终的宽高。

那这些模式该如何得到呢？Android提供了一个类`MeasureSpec`，可以从onMeasure的两个参数获得宽高或者测量模式。具体做法是：

``` java
int sizeWidth = MeasureSpec.getSize(widthMeasureSpec);   // 获得宽度
int modeWidth = MeasureSpec.getMode(widthMeasureSpec);   // 获得宽度的测量模式
int sizeHeight = MeasureSpec.getSize(heightMeasureSpec);
int modeHeight = MeasureSpec.getMode(heightMeasureSpec);
```

如果modeWidth和modeHeight 的值都是MeasureSpec.EXACTLY，那么我们可以直接调用setMeasuredDimension(sizeWidth, sizeHeight)来设定ViewGroup的宽高（setMeasuredDimension是ViewGroup提供的用于设置其宽高的方法，一般在onMeasure方法的最后使用）。如果是AT_MOST模式，则需要在代码中重新测量宽高，最后再设进去，具体做法后面的文章再讲。

### 三个构造函数

继承ViewGroup后一般会提供三个构造函数

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

这三个函数的用途分别是什么？第一个构造函数一般是用户在代码中用new来定义一个实例会使用。第二个构造函数则是用户在xml中声明了该控件，且没有使用到自定义属性时用到。第三个构造函数同第二个类似，但它会在使用到自定义属性时被调用，第三个参数defStyle表示我们自定义的属性的资源索引(在R.java这个类中)。

### getLayoutParams

通常我们用View类的getLayoutParams方法得到LayoutParams，对应的是这个子View所在ViewGroup的LayoutParams。例如，如果子View在LinearLayout内，那这个LayoutParams就是LinearLayout.LayoutParams。那我们自己定义的ViewGroup的LayoutParams是怎么来的？ViewGroup提供了一个方法给开发者覆写

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

我们可以根据自己的需求，返回一个我们需要的`LayoutParams`(可以是`LayoutParams`也可以是它的子类)。在FlowLayout中，我们只需要知道子View之间的间隔，因此返回一个`MarginLayoutParams`。

``` java
    // 与当前ViewGroup对应的LayoutParams
    @Override
    public LayoutParams generateLayoutParams(AttributeSet attrs) {
        return new MarginLayoutParams(getContext(), attrs);
    }
```

