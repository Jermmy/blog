---
title: Android-自定义控件之FlowLayout(二)
tags: Android
categories: Android
---

（首先声明，这篇文章是博主在mooc上学习了hyman的视频[打造Android流式布局和热门标签](http://mooc.guokr.com/career/3170/%E6%89%93%E9%80%A0Android%E6%B5%81%E5%BC%8F%E5%B8%83%E5%B1%80%E5%92%8C%E7%83%AD%E9%97%A8%E6%A0%87%E7%AD%BE/)后总结的小知识）

<!--more-->

### onMeasure实现过程

这篇文章总结一下onMeasure函数该如何完成测量过程。

再次看看官网对onMeasure函数的说明

``` java
    /**
     * Ask all children to measure themselves and compute the measurement of this
     * layout based on the children.
     */
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec)
```

前面讲过，我们通过该函数两个参数来确定ViewGroup的宽高及其测量模式。但同时，这个函数需要让子View去测量它们自己的宽高，这样，我们才能在ViewGroup中得到子View的宽高。让子View去测量自己的方法是调用ViewGroup提供的`measureChild`方法。调用该方法后，可以通过子View的`getMeasuredWidth`或`getMeasuredHeight`方法分别获得子View的宽高。之后通过我们自己的策略确定ViewGroup的宽高。前面讲过，如果是EXACTLY模式，那么宽高的值直接就是`onMeasure`传进来的参数值，如果是AT_MOST模式，则需要根据子View的宽高自行测量，最后通过`setMeasureDimension`方法将宽高作为参数传给ViewGroup。

下面的代码是FlowLayout的onMeasure函数的实现方法：

``` java
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        // 如果布局文件的宽高使用match_parent或fill_parent，mode对应的是EXACTLY模式
        // 如果布局文件的宽高使用wrap_content，mode对应的是AT_MOST模式
        // EXACTLY模式中ViewGroup的宽高已经确定，AT_MOST模式中需要自己设定
        int sizeWidth = MeasureSpec.getSize(widthMeasureSpec);
        int modeWidth = MeasureSpec.getMode(widthMeasureSpec);
        int sizeHeight = MeasureSpec.getSize(heightMeasureSpec);
        int modeHeight = MeasureSpec.getMode(heightMeasureSpec);

        // 以下计算当模式设定为AT_MOST时宽高的值

        // 计算出的ViewGroup的宽和高
        int width = 0;
        int height = 0;
        // 每一行的宽高
        int lineWidth = 0;
        int lineHeight = 0;
        int cCount = getChildCount();
        for (int i = 0; i < cCount; i++) {
            View child = getChildAt(i);
            // 测量子View的宽和高
            measureChild(child, widthMeasureSpec, heightMeasureSpec);
            // 得到子View的LayoutParams，子View的LayoutParams是由父布局的LayoutParams决定的
            MarginLayoutParams lp = (MarginLayoutParams) child.getLayoutParams();

            int childWidth = child.getMeasuredWidth() + lp.leftMargin + lp.rightMargin;
            int childHeight = child.getMeasuredHeight() + lp.topMargin + lp.bottomMargin;
            if (lineWidth + childWidth > sizeWidth - getPaddingLeft() - getPaddingRight()) {
                width = Math.max(width, lineWidth);
                lineWidth = childWidth;
                height += lineHeight;
                lineHeight = childHeight;
            } else {
                lineWidth += childWidth;
                lineHeight = Math.max(lineHeight, childHeight);
            }

            if (i == cCount - 1) {
                width = Math.max(width, lineWidth);
                height += lineHeight;
            }
        }

        Log.i(TAG, "sizeWidth====>" + sizeWidth + "  sizeHeight===>" + sizeHeight);
        Log.i(TAG, "width====>" + width + "  height===>" + height);

        setMeasuredDimension(
                modeWidth == MeasureSpec.AT_MOST ? width + getPaddingLeft() + getPaddingRight() : sizeWidth,
                modeHeight == MeasureSpec.AT_MOST ? height + getPaddingTop() + getPaddingBottom() : sizeHeight
        );

    }
```