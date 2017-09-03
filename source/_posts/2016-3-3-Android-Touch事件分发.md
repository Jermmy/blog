---
title: Android Touch事件分发过程
tags: Android
categories: Android
---

最近在系统学习 Android 一些底层的实现。今天花了一天时间，查阅各种文章源码，决定对 Touch 事件的分发过程做一次梳理。

<!--more-->

网上有大把的文章介绍这类主题，但能够从源头说起的不多，博主搜到了一篇 [Android 事件分发机制详解](http://stackvoid.com/details-dispatch-onTouch-Event-in-Android/) ，感觉讲得比较全面，而且分析过程也比较适合对底层理解不多的新手（比如我）。

说起 Touch 事件的分发，当然还是得从手指 touch 到屏幕说起啦（大部分文章直入主题说是 `Activity` 的 `dispatchTouchEvent()` 方法开启分发过程，可博主比较喜欢刨根问底）。很自然地我们会想到是屏幕把 touch 这个信号传到了，这么底层的东西自然而然也要由 Linux 来提供支持。如果你有点进去上面那篇文章的话，你会知道这个信号经由 Linux 处理封装后，会通过内核中的 `InputManager` 模块将事件传给 Android 的 `WindowManagerService` ，后者可以认为是 Android 系统提供的服务了，博主是把它当作 Android 系统的常驻服务进程对待的。`WindowManagerService `得到这个事件后，中间又经历多方曲折，最终会把它传递到 `PhotoWindow` 的内部类 `DecorView` 的 `dispatchTouchEvent()` 函数这里（其实这里博主不是很确定是不是这样，因为上面那篇文章分析的代码比较旧，和博主看的 5.0 的代码有很大的不同，`WindowManagerService` 的代码博主实在没有能力看懂，但我想虽然细节变了很多，但总体的框架还是要保持兼容的，所以这种猜测应该是正确的）。

## PhotoWindow和DecorView

好吧，既然锁定了位置，就该看看这个 `PhotoWindow` 和 `DecorView `是何方神圣。为了搞清楚这个问题，我们不得不从后往前推。

突破点是 Activity !

相信如果你也研究过该主题并阅读过一些文章的话，你一定对 `Activity` 的`dispatchTouchEvent()` 方法不陌生。

```java
    /**
     * Called to process touch screen events.  You can override this to
     * intercept all touch screen events before they are dispatched to the
     * window.  Be sure to call this implementation for touch screen events
     * that should be handled normally.
     *
     * @param ev The touch screen event.
     *
     * @return boolean Return true if this event was consumed.
     */
    public boolean dispatchTouchEvent(MotionEvent ev) {
        if (ev.getAction() == MotionEvent.ACTION_DOWN) {
            onUserInteraction();
        }
        // 这里getWindow()得到的是跟这个Activity绑定的PhoneWindow
        if (getWindow().superDispatchTouchEvent(ev)) {
            return true;
        }
        return onTouchEvent(ev);
    }
```

这里就是函数源码，我们逐句看下。首先第一个判断语句，当我们发出 down 这个动作时，会执行 `onUserInteraction()`，这个方法是空的，是让开发者自己去覆写实现一些功能。那么重点就放在中间那一块了，getWindow() 得到的是什么？博主一路跟踪进去，得到下面这些重要信息：

```java
    private Window mWindow;

    public Window getWindow() {
        return mWindow;
    }

    final void attach(Context context, ActivityThread aThread,
            Instrumentation instr, IBinder token, int ident,
            Application application, Intent intent, ActivityInfo info,
            CharSequence title, Activity parent, String id,
            NonConfigurationInstances lastNonConfigurationInstances,
            Configuration config, String referrer, IVoiceInteractor voiceInteractor) {
        attachBaseContext(context);

        mFragments.attachHost(null /*parent*/);

        mWindow = new PhoneWindow(this);
        mWindow.setCallback(this);
        mWindow.setOnWindowDismissedCallback(this);
        mWindow.getLayoutInflater().setPrivateFactory(this);
      ....
    }
```

原来 `mWindow `是 Window 类型的引用， 重点是在 attach 函数里，我们发现 mWindow 被实例化为 `PhotoWindow` 。前面说 Touch 事件的分发也跟这个 window 有关，那么这个 `PhotoWindow` 到底是什么呢？博主搜了一圈，发现这篇文章 [Android ViewTree and DecorView](http://www.cnblogs.com/jinsdu/archive/2013/01/03/2840565.html) 对它的阐述还是很不错的。我们常说，`Activity` 是应用程序的窗口，严格来讲，`PhotoWindow` 才是。在 Window 这个类文件里，你可以找这样一段说明：

```java
/**
 * Abstract base class for a top-level window look and behavior policy.  An
 * instance of this class should be used as the top-level view added to the
 * window manager. It provides standard UI policies such as a background, title
 * area, default key processing, etc.
 *
 * <p>The only existing implementation of this abstract class is
 * android.policy.PhoneWindow, which you should instantiate when needing a
 * Window.  Eventually that class will be refactored and a factory method
 * added for creating Window instances without knowing about a particular
 * implementation.
 */
public abstract class Window {
  .......
```

第二段里说道，抽象类 `Window` 的唯一实现类是 `PhotoWindow`。我们可以认为，每个 Activity 其实都绑定着一个 `PhotoWindow`，并由它来控制整个视图的显示。

回到 dispatchTouchEvent 函数，我们已经找到了 getWindow 的返回值，那就去 `PhotoWindow` 的 superDispatchTouchEvent 方法里瞧瞧：

```java
    @Override
    public boolean superDispatchTouchEvent(MotionEvent event) {
        return mDecor.superDispatchTouchEvent(event);
    }

```

我们貌似看到一点 `DecorView` 的影子，继续跟踪这个 mDecor：

```java
    // This is the top-level view of the window, containing the window decor.
    private DecorView mDecor;

    @Override
    public final View getDecorView() {
        if (mDecor == null) {
            installDecor();
        }
        return mDecor;
    }

    private void installDecor() {
        if (mDecor == null) {
            mDecor = generateDecor();
            mDecor.setDescendantFocusability(ViewGroup.FOCUS_AFTER_DESCENDANTS);
            mDecor.setIsRootNamespace(true);
            if (!mInvalidatePanelMenuPosted && mInvalidatePanelMenuFeatures != 0) {
                mDecor.postOnAnimation(mInvalidatePanelMenuRunnable);
            }
        }
        ......
   }

    protected DecorView generateDecor() {
        return new DecorView(getContext(), -1);
    }
```

没得说，`mDecor` 就是 `DecorView`。它是 `PhotoWindow ` 的内部类，前面说 `PhotoWindow` 才代表手机窗口，但窗口内那些的具体元素，其实是 `DecorView` 负责管理的，简单点说，每次我们创建完 `Activity `后，不管我们有没有定义 layout 布局，Activity 所在的窗口的最外层都会被套上一层布局（你可以新建一个 Activity，但不要调用 setContentView 方法，看跑起来是怎样的），这层布局就是这里的 `DecorView` ，也就是说它才是整个 ViewTree 的根节点，而我们的布局只是内容布局，所以叫 ContentView。

好了，现在我们知道 `PhotoView` 和 `DecorView `都代表什么之后，暂时把 Activity 放下，回到文章开头。我们前面说 `WindowManagerService `会将 touch 事件传递到 `DecorView `的 dispatchTouchEvent 函数，这个函数代码不多：

```java
        @Override
        public boolean dispatchTouchEvent(MotionEvent ev) {
            final Callback cb = getCallback();
            return cb != null && !isDestroyed() && mFeatureId < 0 ? cb.dispatchTouchEvent(ev)
                    : super.dispatchTouchEvent(ev);
        }
```

这里又出现一个 `Callback `的类，这个 getCallback 其实是 `Window` 类中定义的方法，而 `Callback`

也是其内部声明的接口：

```java
   /**
     * API from a Window back to its caller.  This allows the client to
     * intercept key dispatching, panels and menus, etc.
     */
    public interface Callback {

        .....

        /**
         * Called to process touch screen events.  At the very least your
         * implementation must call
         * {@link android.view.Window#superDispatchTouchEvent} to do the
         * standard touch screen processing.
         *
         * @param event The touch screen event.
         *
         * @return boolean Return true if this event was consumed.
         */
        public boolean dispatchTouchEvent(MotionEvent event);

        ....
    }
```

这个接口内部声明了包括 `dispatchTouchEvent()` 在内的众多函数接口，我们比较关心这个 Callback 的赋值，

```java
    /**
     * Set the Callback interface for this window, used to intercept key
     * events and other dynamic operations in the window.
     *
     * @param callback The desired Callback interface.
     */
    public void setCallback(Callback callback) {
        mCallback = callback;
    }
```

其实，这个方法在我们前面分析的时候已经出现过了，还记得 Activity 绑定 PhotoWindow 的 attach 方法吗？

```java
    final void attach(Context context, ActivityThread aThread,
            Instrumentation instr, IBinder token, int ident,
            Application application, Intent intent, ActivityInfo info,
            CharSequence title, Activity parent, String id,
            NonConfigurationInstances lastNonConfigurationInstances,
            Configuration config, String referrer, IVoiceInteractor voiceInteractor) {
        ....

        mWindow = new PhoneWindow(this);
        mWindow.setCallback(this);
        mWindow.setOnWindowDismissedCallback(this);
        mWindow.getLayoutInflater().setPrivateFactory(this);
        ....
    }
```

Callback 就是在这里实现了赋值，而传进去的参数就是当前窗口的 Activity 类（ Activity 实现了 Callback 接口）。重新回到 `DecorView` 的 dispatchTouchEvent 函数：

```java
        @Override
        public boolean dispatchTouchEvent(MotionEvent ev) {
            final Callback cb = getCallback();
            return cb != null && !isDestroyed() && mFeatureId < 0 ? cb.dispatchTouchEvent(ev)
                    : super.dispatchTouchEvent(ev);
        }
```

这里拿到 Callback（也就是 Activity ）之后，return 语句中判断这个 Activity 是否为空，有没有被 destroy，然后根据 mFeatureId 的值来决定调用哪个 dispatchTouchEvent 函数。mFeatureId 在 DecorView 的构造函数中被赋值为 －1，所以一般都会调用 cb.dispatchTouchEvent(ev)，也就是 Activity 的 dispatchTouchEvent 函数。终于，我们又绕了回去。

总结一下其实很简单，`WindowManagerService `将事件分发给 `DecorView` 的 dispatchTouchEvent 函数，接着再分发给 `Activity` 的 dispatchTouchEvent 函数。从这里开始，我们就可以跟大多数文章那样分析 `Activity` 的 dispatchTouchEvent 函数了。

## ViewGroup.dispatchTouchEvent

前面我们在肢解 `Activity` 的 dispatchTouchEvent 函数分析 PhotoWindow 的同时，已经逐渐把事件分发的流程也理了一下

```java
   // Activity类 
   public boolean dispatchTouchEvent(MotionEvent ev) {
        if (ev.getAction() == MotionEvent.ACTION_DOWN) {
            onUserInteraction();
        }
        // 这里getWindow()得到的是跟这个Activity绑定的PhoneWindow
        if (getWindow().superDispatchTouchEvent(ev)) {
            return true;
        }
        return onTouchEvent(ev);
    }
```

```java
    // PhotoWindow类
    @Override
    public boolean superDispatchTouchEvent(MotionEvent event) {
        return mDecor.superDispatchTouchEvent(event);
    }
```

仔细跟踪梳理的话，我们会发现，第二个 if 语句最后会执行 `DecorView` 的 superDispatchTouchEvent 函数

```java
        public boolean superDispatchTouchEvent(MotionEvent event) {
            return super.dispatchTouchEvent(event);
        }
```

这个函数简单粗暴地将任务扔给父类 `FrameLayout`，而后者最终会调用 `ViewGroup` 的 dispatchTouchEvent 函数。关于这个函数的讲解，网上已经有很多文章了，所以这里也不细讲（好吧，我承认我也不是很懂）。下面还是保留大段源码，希望有朝一日看懂后继续写注释：

```java
@Override
public boolean dispatchTouchEvent(MotionEvent ev) {

    .......

    boolean handled = false;
  if (onFilterTouchEventForSecurity(ev)) {
    final int action = ev.getAction();
    final int actionMasked = action & MotionEvent.ACTION_MASK;

    // 如果这是一个down的动作，就把之前触摸的记录全部清空
    // 所以说down是触摸事件的开始
    // Handle an initial down.
    if (actionMasked == MotionEvent.ACTION_DOWN) {
      // Throw away all previous state when starting a new touch gesture.
      // The framework may have dropped the up or cancel event for the previous gesture
      // due to an app switch, ANR, or some other state change.
      cancelAndClearTouchTargets(ev);
      resetTouchState();
    }

    // 检查这个事件是否会被ViewGroup拦截，onInterceptTouchEvent方法默认返回false
    // 也就是不拦截，我们可以覆写这个方法来拦截所有事件。
    // 这里还是涉及到TouchTarget这个概念，在ViewGroup中可以找到这个类的定义，
    // 博主就是一直搞不懂这个东西，所以很多地方看不明白
    // Check for interception.
    final boolean intercepted;
    if (actionMasked == MotionEvent.ACTION_DOWN
        || mFirstTouchTarget != null) {
      // 在判断是否拦截之前，还要注意是否允许拦截，
      // 可以通过requestDisallowInterceptTouchEvent来设置mGroupFlags，
      // 比如ViewPager会调用父节点这个方法来防止事件被拦截
      final boolean disallowIntercept = (mGroupFlags & FLAG_DISALLOW_INTERCEPT) != 0;
      if (!disallowIntercept) {
        intercepted = onInterceptTouchEvent(ev);
        ev.setAction(action); // restore action in case it was changed
      } else {
        intercepted = false;
      }
    } else {
      // 如果这不是down的动作，且TouchTarget链表中没有任何触摸记录，
      // 就默认这个事件被ViewGroup拦截了
      // 其实我搞不懂这种情况该如何理解
      // There are no touch targets and this action is not an initial down
      // so this view group continues to intercept touches.
      intercepted = true;
    }

    // 检查动作是否被取消，但我不知道MotionEvent.ACTION_CANCEL
    // 在实际中代表什么
    // Check for cancelation.
    final boolean canceled = resetCancelNextUpFlag(this)
      || actionMasked == MotionEvent.ACTION_CANCEL;

    // Update list of touch targets for pointer down, if needed.
    final boolean split = (mGroupFlags & FLAG_SPLIT_MOTION_EVENTS) != 0;
    TouchTarget newTouchTarget = null;
    boolean alreadyDispatchedToNewTouchTarget = false;

    // 如果动作没被取消或拦截，就执行下面一大串代码
    // 在这里卡了一天，主要还是TouchTarget不理解
    // 我简单的理解是把当前触摸点所在的子View找出来
    if (!canceled && !intercepted) {
      if (actionMasked == MotionEvent.ACTION_DOWN
          || (split && actionMasked == MotionEvent.ACTION_POINTER_DOWN)
          || actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
        final int actionIndex = ev.getActionIndex(); // always 0 for down
        final int idBitsToAssign = split ? 1 << ev.getPointerId(actionIndex)
          : TouchTarget.ALL_POINTER_IDS;

        // Clean up earlier touch targets for this pointer id in case they
        // have become out of sync.
        removePointersFromTouchTargets(idBitsToAssign);

        final int childrenCount = mChildrenCount;
        if (newTouchTarget == null && childrenCount != 0) {
          final float x = ev.getX(actionIndex);
          final float y = ev.getY(actionIndex);
          // Find a child that can receive the event.
          // Scan children from front to back. 
          // 这里的buildOrderedChildList方法是用了插入排序把子View放入队列，
          // Z轴小的在队列前面，大的在外面。Z轴大的表示离屏幕远，更加靠外，
          // 因此Z轴大的View会覆盖Z轴小的View
          final ArrayList<View> preorderedList = buildOrderedChildList();
          final boolean customOrder = preorderedList == null
            && isChildrenDrawingOrderEnabled();
          final View[] children = mChildren;
          // 这里从preorderedList的后面找起，其实是从Z轴大的View逐步
          // 遍历到Z轴小的View
          for (int i = childrenCount - 1; i >= 0; i--) {
            final int childIndex = customOrder
              ? getChildDrawingOrder(childrenCount, i) : i;
            final View child = (preorderedList == null)
              ? children[childIndex] : preorderedList.get(childIndex);
            // 如果这个子View不能接收事件 或者 这个事件的坐标不在子View的范围内
            // 继续循环查找
            if (!canViewReceivePointerEvents(child)
                || !isTransformedTouchPointInView(x, y, child, null)) {
              continue;
            }

            // 找到目标子View，退出循环
            newTouchTarget = getTouchTarget(child);
            if (newTouchTarget != null) {
              // Child is already receiving touch within its bounds.
              // Give it the new pointer in addition to the ones it is handling.
              newTouchTarget.pointerIdBits |= idBitsToAssign;
              break;
            }

            // 会进入下面的代码段的前提是，这个事件的坐标在子view的范围内，
            // 但TouchTarget链表中没有这个View的记录，这怎么理解？果然还是TouchTarget
            // 的问题！！
            resetCancelNextUpFlag(child);
            if (dispatchTransformedTouchEvent(ev, false, child, idBitsToAssign)) {
              // Child wants to receive touch within its bounds.
              mLastTouchDownTime = ev.getDownTime();
              if (preorderedList != null) {
                // childIndex points into presorted list, find original index
                for (int j = 0; j < childrenCount; j++) {
                  if (children[childIndex] == mChildren[j]) {
                    mLastTouchDownIndex = j;
                    break;
                  }
                }
              } else {
                mLastTouchDownIndex = childIndex;
              }
              mLastTouchDownX = ev.getX();
              mLastTouchDownY = ev.getY();
              newTouchTarget = addTouchTarget(child, idBitsToAssign);
              alreadyDispatchedToNewTouchTarget = true;
              break;
            }
          }
          // 提醒一下，ArrayList的插入函数是深拷贝，结束循环要clear一下，
          // 以前一直以为是简单地拷贝引用！
          if (preorderedList != null) preorderedList.clear();
        }

        if (newTouchTarget == null && mFirstTouchTarget != null) {
          // Did not find a child to receive the event.
          // Assign the pointer to the least recently added target.
          newTouchTarget = mFirstTouchTarget;
          while (newTouchTarget.next != null) {
            newTouchTarget = newTouchTarget.next;
          }
          newTouchTarget.pointerIdBits |= idBitsToAssign;
        }
      }
    }

    // mFirstTouchTarget是TouchTarget链表的头，
    // 如果头都是空的，证明这条列表就不存在，那是否意味着当前
    // 整个触摸事件的发生过程中，没有触及到任何子view？
    // 如果真是这样的话，那事件只能仍交给ViewGroup处理了。
    // 事实上，看dispatchTransformedTouchEvent的函数定义我们发现：
    // ViewGroup会继续传递给它的父类的dispatchTouchEvent方法。
    // 好吧，继续不懂。
    // Dispatch to touch targets.
    if (mFirstTouchTarget == null) {
      // No touch targets so treat this as an ordinary view.
      handled = dispatchTransformedTouchEvent(ev, canceled, null,
                                              TouchTarget.ALL_POINTER_IDS);
    } else {
      // 下面这里才是真正将事件交给子View的过程
      // 
      // Dispatch to touch targets, excluding the new touch target if we already
      // dispatched to it.  Cancel touch targets if necessary.
      TouchTarget predecessor = null;
      TouchTarget target = mFirstTouchTarget;
      while (target != null) {
        final TouchTarget next = target.next;

        // 如果这个触摸点是我们前面已经找出来的newTouchTarget
        // 就默认已经处理过了，因为前面有一个if语句中确实向这个触摸点的子View分发了事件
        if (alreadyDispatchedToNewTouchTarget && target == newTouchTarget) {
          handled = true;
        } else {
          final boolean cancelChild = resetCancelNextUpFlag(target.child)
            || intercepted;

          // 这里给TouchTarget链中的各个子View分发事件
          if (dispatchTransformedTouchEvent(ev, cancelChild,
                                            target.child, target.pointerIdBits)) {
            handled = true;
          }
          if (cancelChild) {
            if (predecessor == null) {
              mFirstTouchTarget = next;
            } else {
              predecessor.next = next;
            }
            target.recycle();
            target = next;
            continue;
          }
        }
        predecessor = target;
        target = next;
      }
    }

    // Update list of touch targets for pointer up or cancel, if needed.
    if (canceled
        || actionMasked == MotionEvent.ACTION_UP
        || actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
      resetTouchState();
    } else if (split && actionMasked == MotionEvent.ACTION_POINTER_UP) {
      final int actionIndex = ev.getActionIndex();
      final int idBitsToRemove = 1 << ev.getPointerId(actionIndex);
      removePointersFromTouchTargets(idBitsToRemove);
    }
  }

  .....

  return handled;
}
```

虽然很多代码细节没搞懂，但事件分发都是交给这个函数处理的，这里就截取代码片段了：

```java
/**
     * Transforms a motion event into the coordinate space of a particular child view,
     * filters out irrelevant pointer ids, and overrides its action if necessary.
     * If child is null, assumes the MotionEvent will be sent to this ViewGroup instead.
     */
private boolean dispatchTransformedTouchEvent(MotionEvent event, boolean cancel,
                                              View child, int desiredPointerIdBits) {
    final boolean handled;

    .....

    // 如果函数传进来的子View是空的，直接调用父类的分发函数(递归)
    // 否则，会调用子View的dispatchTouchEvent函数
    // Perform any necessary transformations and dispatch.
    if (child == null) {
      handled = super.dispatchTouchEvent(transformedEvent);
    } else {
      final float offsetX = mScrollX - child.mLeft;
      final float offsetY = mScrollY - child.mTop;
      transformedEvent.offsetLocation(offsetX, offsetY);
      if (! child.hasIdentityMatrix()) {
        transformedEvent.transform(child.getInverseMatrix());
      }

      handled = child.dispatchTouchEvent(transformedEvent);
    }

    // Done.
    transformedEvent.recycle();
    return handled;
}
```

从前面 `ViewGroup` 的 dispatchTouchEvent 函数我们已经发现：`ViewGroup` 会将事件分发给 TouchTarget 链上的各个子 View，然后通过 dispatchTransformedTouchEvent 函数来调用子View自己的 dispatchTransformedTouchEvent 函数。如果子 View 是一个 `ViewGroup` ，那么它会跟我们前面分析的一样，继续走 ViewGroup 的分发流程，如果子 View 是一个普通的 View，比如说是一个 Button，那么会调用 Button 的 dispatchTouchEvent 函数，因为大部分控件都没有覆写 View 的这个方法，所以我们继续将目光转向这个函数：

```java
/**
     * Pass the touch screen motion event down to the target view, or this
     * view if it is the target.
     *
     * @param event The motion event to be dispatched.
     * @return True if the event was handled by the view, false otherwise.
     */
public boolean dispatchTouchEvent(MotionEvent event) {
  boolean result = false;

  // 调试用，不理会
  if (mInputEventConsistencyVerifier != null) {
    mInputEventConsistencyVerifier.onTouchEvent(event, 0);
  }

  // 判断这个动作是否是down，是的话调用stopNestedScroll方法
  // 这个方法我按照官方文档理解是停止滚动，比如说当滚动ScrollView时，如果按下手指
  // 则应该停止滚动。Androiod里的每一个View都自带滚动特性。
  final int actionMasked = event.getActionMasked();
  if (actionMasked == MotionEvent.ACTION_DOWN) {
    // Defensive cleanup for new gesture
    stopNestedScroll();
  }

  if (onFilterTouchEventForSecurity(event)) {
    //noinspection SimplifiableIfStatement
    // 如果我们设置了OnTouchListener，且这个View是Enabled的，就执行OnTouchListener.onTouch
    // 所以如果我们在onTouch函数中返回true，那么这个事件就在这里被直接消费了
    // 这样后一个if语句就不会执行，这个函数也基本结束，返回true
    ListenerInfo li = mListenerInfo;
    if (li != null && li.mOnTouchListener != null
        && (mViewFlags & ENABLED_MASK) == ENABLED
        && li.mOnTouchListener.onTouch(this, event)) {
      result = true;
    }

    // 如果前面onTouch没有消费掉事件(返回false)，这里还会进入onTouchEvent函数
    if (!result && onTouchEvent(event)) {
      result = true;
    }
  }

  if (!result && mInputEventConsistencyVerifier != null) {
    mInputEventConsistencyVerifier.onUnhandledEvent(event, 0);
  }

  // Clean up after nested scrolls if this is the end of a gesture;
  // also cancel it if we tried an ACTION_DOWN but we didn't want the rest
  // of the gesture.
  if (actionMasked == MotionEvent.ACTION_UP ||
      actionMasked == MotionEvent.ACTION_CANCEL ||
      (actionMasked == MotionEvent.ACTION_DOWN && !result)) {
    stopNestedScroll();
  }

  return result;
}
```

相比前面 ViewGroup ，这个方法好看多了。这里面主要的焦点都落在中间两句 if 语句那里。我们平时传入的 `OnTouchListener` 就是在这里执行的，而 onTouchEvent 函数会继续调用 `OnClickListener` 回调（当然 OnTouchListener 不能消费掉事件，否则系统认为你这个 View 后续不需要再处理事件）。可以说，View 收到触摸事件后的逻辑操作都集中在 onTouchEvent 函数里面。具体我也不深入分析了，主要是在动作是 ACTION_UP 的时候执行 performClick 方法，这个方法里面回调我们的 `OnClickListener`  接口。

最后我们回顾一下整个流程，Activity 的 dispatchTouchEvent 方法会调用整个窗口根节点 `DecorView` 的 superDispatchTouchEvent，而后者其实直接调用了 ViewGroup 的事件分发函数。在 ViewGroup 分发的过程中，会判断是否要进行拦截，这个过程系统留了接口让开发者自己去决定（也就是 onInterceptTouchEvent 函数）。如果没有拦截，会将事件逐个分发给 TouchTarget 链上的子 View，不管这个子 View 是 ViewGroup 还是一般的 View，只要其中一个消费了事件（返回 true ），最顶层的 `ViewGroup ` 就返回 true，回到 Activity 里，就是在第二条判断语句返回 true，那后面的 Activity 自身的 onTouchEvent 函数也就不会执行了。

另外，在 View 的分发过程中，如果 onTouch 消费了事件，onClick 也不会再执行。













