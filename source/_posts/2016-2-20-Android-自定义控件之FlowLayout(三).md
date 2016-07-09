---
layout: post
title: Android-自定义控件之FlowLayout(三)
---

（首先声明，这篇文章是博主在mooc上学习了hyman的视频[打造Android流式布局和热门标签](http://mooc.guokr.com/career/3170/%E6%89%93%E9%80%A0Android%E6%B5%81%E5%BC%8F%E5%B8%83%E5%B1%80%E5%92%8C%E7%83%AD%E9%97%A8%E6%A0%87%E7%AD%BE/)后总结的小知识）

### onLayout函数的作用

上一篇文章说到onMeasure函数会测量子View以及ViewGroup的宽高，而onLayout则是进一步确定子View在ViewGroup中的位置。

``` java
    /**
     * Position all children within this layout.
     */
    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom)
```

onLayout的参数表示这个View相对于父控件的位置，对于自定义ViewGroup而言，一般不会用到，我们暂时不管。

系统调用完onMeasure方法后，已经确定了ViewGroup以及内部子View的大小，之后会调用onLayout来摆放这些子View。具体操作是通过遍历子View并调用View.layout方法

``` java
/**
*Assign a size and position to a view and all of its descendants

This is the second phase of the layout mechanism. (The first is measuring). In this phase, each parent calls layout on all of its children to position them. This is typically done using the child measurements that were stored in the measure pass().

Derived classes should not override this method. Derived classes with children should override onLayout. In that method, they should call layout on each of their children.
*/
public void layout (int l, int t, int r, int b)
```

函数说明指出，在`onLayout`方法中，我们应该调用每个子View的`layout`方法，让子View自动布局到所需要的位置。需要注意的是，我们在`onMeasure`中调用`measureChild`方法来测量各个子控件，但其实这个方法内部也是调用了子View的`measure`方法来实现的，这是一种常用的分治策略。`layout`方法的四个参数的意义如下：

| Parameters |                                     |
| ---------- | ----------------------------------- |
| `l`        | Left position, relative to parent   |
| `t`        | Top position, relative to parent    |
| `r`        | Right position, relative to parent  |
| `b`        | Bottom position, relative to parent |

都是子View相对父控件的位置。因此，在onLayout中，我们只要根据我们的需求计算出子View的位置信息，并调用子View的`layout`方法即可。

可能有人会问ViewGroup的位置又怎么确定？当然是在ViewGroup的父控件中通过`onLayout`来调用ViewGroup的`layout`方法啦。

所以，onLayout方法的重点自然是计算子View的位置啦，由于不同需求的计算方法是不一样的，这里贴上`FlowLayout`的onLayout实现，仅仅是一个模板作用

``` java
    // 按行的方式记录子View
    private List<List<View>> mAllViews = new ArrayList<>();
    // 记录各行的高
    private List<Integer> mLineHeights = new ArrayList<>();

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        mAllViews.clear();
        mLineHeights.clear();
        // 当前ViewGroup宽度
        int width = getWidth();

        int lineWidth = 0;
        int lineHeight = 0;

        List<View> lineViews = new ArrayList<>();

        int cCount = getChildCount();

        for (int i = 0; i < cCount; i++) {
            View child = getChildAt(i);
            MarginLayoutParams lp = (MarginLayoutParams) child.getLayoutParams();
            int childWidth = child.getMeasuredWidth();
            int childHeight = child.getMeasuredHeight();

            // 换行
            if (childWidth + lineWidth + lp.leftMargin + lp.rightMargin > width - getPaddingLeft() - getPaddingRight()) {
                mLineHeights.add(lineHeight);
                mAllViews.add(lineViews);
                lineViews = new ArrayList<>();
                lineWidth = 0;
                lineHeight = childHeight + lp.topMargin + lp.bottomMargin;
            }

            lineWidth += childWidth + lp.leftMargin + lp.rightMargin;
            lineHeight = Math.max(lineHeight, childHeight + lp.topMargin + lp.bottomMargin);
            lineViews.add(child);
        }

        // 处理最后一行
        mLineHeights.add(lineHeight);
        mAllViews.add(lineViews);

        // 设置子View的位置
        int left = getPaddingLeft();
        int top = getPaddingTop();

        int lineNum = mAllViews.size();

        for (int i = 0; i < lineNum; i++) {
            lineViews = mAllViews.get(i);
            lineHeight = mLineHeights.get(i);

            for (int j = 0; j < lineViews.size(); j++) {
                View child = lineViews.get(j);
                if (child.getVisibility() == View.GONE) {
                    continue;
                }
                MarginLayoutParams lp = (MarginLayoutParams) child.getLayoutParams();
                int lc = left + lp.leftMargin;
                int tc = top + lp.topMargin;
                int rc = lc + child.getMeasuredWidth();
                int bc = tc + child.getMeasuredHeight();
              // 这里是onLayout产生作用的重点
                child.layout(lc, tc, rc, bc);
                left += child.getMeasuredWidth() + lp.rightMargin + lp.leftMargin;
            }

            top += lineHeight;
            left = getPaddingLeft();
        }

    }
```

###getWidth()和getMeasureWidth()

在测量或布局的时候需要用到子View的宽高，但系统提供了两个获取宽高的方法（这里以宽度为例，高度类比）：`getWidth()`, `getMeasureWidth()`。一开始博主傻傻分不清这两个函数到底有什么区别，后来看了郭霖的博客后豁然开朗[ Android视图绘制流程完全解析，带你一步步深入了解View(二)](http://blog.csdn.net/guolin_blog/article/details/16330267)。`getMeasureWidth()`是在`onMeasure()`之后得到的，而`getWidth()`则在`onLayout()`之后获得。简单来说，`getMeasureWidth()`方法中的值是通过`setMeasuredDimension()`方法来进行设置的，而`getWidth()`方法中的值则是通过视图右边的坐标减去左边的坐标计算出来的。所以，如果正常设计的话，这两个函数返回的值应该是一样的。所谓正常设计就是说，View需要多大的宽高我们就给它布局多大的空间。

比方说在调用layout的时候，如果传这样的参数：

```java
child.layout(0, 0, child.getMeasureWidth(), child.getMeasureHeight());
```

也就是说，我们尊重测量的时候，严格按测量的大小布局，这是两个函数等价。但如果这样传参：

```java
child.layout(0, 0, 200, 200);
```

那我们之前的测量结果就没有用到，此时`getMeasureWidth()`依然是测量出的宽度，而`getWidth()`就变成了200。





