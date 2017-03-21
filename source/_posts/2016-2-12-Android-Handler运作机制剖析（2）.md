---
title: Android—Handler运作机制剖析（二）
tags: Android
categories: Android
---

书接上文，我们忽悠完了 Handler 与 Looper 之间的关系以及 Looper 的由来，今天该讲讲 Looper 是怎么帮助 Handler 工作，以及如何支撑整个 app 运转的。对，你没听错，Looper 就是这么强大。

<!--more-->

## Looper的作用

之前说过，Handler 发送的 Message 会被放入 MessageQueue 中，然后由 Looper 来轮询这个队列并执行消息。首先，为了证明 MessageQueue 确实是由 Looper 来轮询的，不妨先看个例子

``` java
    MyHandler handler = new MyHandler();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        MyThread thread = new MyThread();
        handler.sendEmptyMessage(0);
        thread.start();
    }

    class MyThread extends Thread {
        MyHandler handler;

        @Override
        public void run() {
            Looper.prepare();
            handler = new MyHandler();
            handler.sendEmptyMessage(1);
        }
    }

    class MyHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case 0:
                    Log.i("MyHandler", "main thread");
                    break;
                case 1:
                    Log.i("MyHandler", "sub thread");
                    break;
            }
        }
    }
```

我在两条线程中分别用 Handler 发送消息，但在 Log 中只看到一条记录：

``` java
com.xxx.myapplication I/MyHandler: main thread
```

也就是说，主线程的 Handler 发送的消息被执行了，而子线程的没有。为了探究是什么原因导致这样的区别，博主稍微修改了例子中的 `MyThread` 类：

``` java
    class MyThread extends Thread {
        MyHandler handler;

        @Override
        public void run() {
            Looper.prepare();
            handler = new MyHandler();
            handler.sendEmptyMessage(1);
            Looper.loop();
        }
    }
```

再次运行程序后，发现 Log 中出现了两条记录：

``` java
com.xxx.myapplication I/MyHandler: sub thread
com.xxx.myapplication I/MyHandler: main thread
```

结果跟我们想要的吻合了。于是，不难猜测 Handler 发送的消息其实是由 `Looper` 的 loop 方法执行的。我们再重头来看下整个消息从发送到被执行的过程。

## Handler发送消息

首先，我们看下 Handler 的 sendEmptyMessage 方法背后都在做什么。博主一路跟踪 sendEmptyMessage 的源码，发现最终会调用这个函数

``` java
    public boolean sendMessageAtTime(Message msg, long uptimeMillis) {
        MessageQueue queue = mQueue;
        if (queue == null) {
            RuntimeException e = new RuntimeException(
                    this + " sendMessageAtTime() called with no mQueue");
            Log.w("Looper", e.getMessage(), e);
            return false;
        }
        return enqueueMessage(queue, msg, uptimeMillis);
    }
```

（有心的读者可以跟踪 `Handler` 另外两个常用的方法 sendMessage 或 post ，你会发现最终调用的都是上面这个函数）

这个函数做的事情也非常简单，就是调用 enqueueMessage 方法把 Message 放入 MessageQueue 中（ enqueueMessage 我就没有进一步跟踪进去了，它不是文章重点）。

至此，`Handler `发送消息的过程就结束了。

## Looper轮询MessageQueue

从上面的例子我们已经看出，如果没有调用 Looper 的 loop 方法，Handler 发送的消息是没法交给 handleMessage 方法执行的。所以，重头戏都在 loop 方法本身。博主裁剪了一些跟主题无关的源码，你会看到这个方法的重点是一个死循环

``` java
    /**
     * Run the message queue in this thread. Be sure to call
     * {@link #quit()} to end the loop.
     */
    public static void loop() {
        final Looper me = myLooper();
        if (me == null) {
            throw new RuntimeException("No Looper; Looper.prepare() wasn't called on this thread.");
        }
        final MessageQueue queue = me.mQueue;

        ...无关主题的代码

        for (;;) {
            Message msg = queue.next(); // might block
            if (msg == null) {
                // No message indicates that the message queue is quitting.
                return;
            }
            ...无关主题的代码
              
            msg.target.dispatchMessage(msg);
          
            ...无关主题的代码
            }

            msg.recycleUnchecked();
        }
    }
```

在 for 循环里面，Looper 会不断地从 queue 里面取出 Message，并通过 dispatchMessage 来执行消息。 msg.target 指的就是发送 msg 的 `Handler` 本身。我们再到 dispatchMessage 方法里面去看下

``` java
    /**
     * Handle system messages here.
     */
    public void dispatchMessage(Message msg) {
        if (msg.callback != null) {
            handleCallback(msg);
        } else {
            if (mCallback != null) {
                if (mCallback.handleMessage(msg)) {
                    return;
                }
            }
            handleMessage(msg);
        }
    }
```

看到 handleMessage 方法，一切就水落石出了。这个方法先判断 msg.callback 是否为空，如果你对这个 callback 不熟悉，可以跟踪 `Handler` 的 post 方法，这个 `callback` 就是 post 传进去的 Runnable 对象，如果 callback 不为空，则直接执行它即可。否则，会进入 else 语句。`mCallback `是 `Handler` 暴露给开发者的接口，博主基本没用过，一般情况下也是 null 的，所以 else 语句大多数情况是执行我们覆写的 handleMessage 方法。

到此，大概的流程我们已经分析完了，总结一下：`Handler `发送 `Message` 到 `MessageQueue` ，`Looper` 会一直轮询 `MessageQueue` ，取出消息并重新交给 `Handler` 执行，所以，消息的发送和执行者都是 `Handler` ，而 `Looper` 则起到分发消息的作用。

## 如何结束轮询

现在，我们遇到的另一个问题是：既然 loop 方法在做一个不断循环地操作，我们要怎样才能让它停下来呢？如果仔细观察 for 循环内部的话，你会发现跳出循环的唯一方法是当 msg 为 null 时执行的 return 语句。

那 msg 什么时候为 null 呢？我们自己传一个空的 Message 进去？如果这样做的话，你的程序会抛出 `NullPointerException` 。正确的做法是调用 Looper 的 quit 方法，博主重新修改了最开始那个例子

``` java
    MyHandler handler = new MyHandler();
    Button btn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        btn = (Button) findViewById(R.id.btn);
        final MyThread thread = new MyThread();
        handler.sendEmptyMessage(0);
        thread.start();

        btn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                thread.quitLoop();
            }
        });
    }

    class MyThread extends Thread {
        MyHandler handler;
        Looper looper;

        @Override
        public void run() {
            Looper.prepare();
            synchronized (this) {
                looper = Looper.myLooper();
                notifyAll();
            }
            handler = new MyHandler();
            handler.sendEmptyMessage(1);
            Looper.loop();
            Log.i("MyThread", "finish loop");
        }

        public void quitLoop() {
            synchronized (this) {      // 这里加锁的原因是为了防止线程间不同步，导致looper还没初始化就被调用
                while (looper == null) {
                    try {
                        wait();             
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
                looper.quit();    // 结束loop方法
            }
        }
    }

    class MyHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case 0:
                    Log.i("MyHandler", "main thread");
                    break;
                case 1:
                    Log.i("MyHandler", "sub thread");
                    break;
            }
        }
    }
```

博主在 `Looper.loop()` 之后打了个 Log，并加入一个 Button 来调用 quitLoop 方法。运行起来后，loop 之后的 Log 一直没打印出来，只有点击按钮后才出现。证明 quit 方法确实终止了 loop 循环。关于 quit，还有另一个 quitSafely 函数，从名称上看就能猜出后者比前者安全。由于博主平时并没有使用过这两个方法，就不深入源码细讲了😅。

## UI线程的Looper轮询

文章最开始还有一个悬而未解的问题，为什么子线程 Handler 发送的消息没有被处理，而 UI 线程的消息却能被接收处理呢？要知道问题的答案，我们又得看回 ActivityThread.java 中的 main 函数（不清楚地请看回上一篇文章[Android--Handler运作机制剖析（一）](https://jermmy.github.io/2016/02/12/2016-2-11-Android-Handler%E8%BF%90%E4%BD%9C%E6%9C%BA%E5%88%B6%E5%89%96%E6%9E%90%EF%BC%881%EF%BC%89/  )），这里照搬一下代码

``` java
    public static void main(String[] args) {
        ......无关主题的代码

        Looper.prepareMainLooper();

        ActivityThread thread = new ActivityThread();
        thread.attach(false);

        if (sMainThreadHandler == null) {
            sMainThreadHandler = thread.getHandler();
        }

        if (false) {
            Looper.myLooper().setMessageLogging(new
                    LogPrinter(Log.DEBUG, "ActivityThread"));
        }

        // End of event ActivityThreadMain.
        Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
        Looper.loop();

        throw new RuntimeException("Main thread loop unexpectedly exited");
    }
```

应该能看到 Looper.loop 这一条语句吧，UI 线程也是这样不断轮询的。前面说过，我们整个 app 都是在这个 main 函数中执行的，那是否意味着我们整个 UI 线程，包括所有 Activity 的事件，其实都是在 Looper.loop 中执行的呢？答案就在 ActivityThread.java 那整整五千行的代码中。博主能力有限，暂时还搞不定它😅（感觉能把这个类看懂的同学 Android 的应用层框架也基本熟练掌握了）。在网上找到的关于这个类的解析，不是讲得太深奥就是讲得更深奥，博主找了几篇比较有启发性的（[Looper.loop死循环问题](http://krelve.com/android/75.html)这是找到的第一篇），大概翻了一下 ActivityThread.java 的代码，基本猜出 UI 线程的轮询在做什么事了，这里也可以简单说下。

在 main 函数中有这样一句

``` java
  if (sMainThreadHandler == null) {
    sMainThreadHandler = thread.getHandler();
  }
```

这个 sMainThreadHandler 是一个 Handler 类，loop 方法中接收和处理的消息也来自这个对象。我们进一步看看 thread.getHandler() 返回的内容是什么

``` java
    final Handler getHandler() {
        return mH;
    }
```

是一个叫 mH 的家伙，这个成员在最开始有声明

``` java
    final H mH = new H();
```

居然又来了个 H 类，再找找吧

``` java
    private class H extends Handler {
        public static final int LAUNCH_ACTIVITY         = 100;
        public static final int PAUSE_ACTIVITY          = 101;
        public static final int PAUSE_ACTIVITY_FINISHING= 102;
        public static final int STOP_ACTIVITY_SHOW      = 103;
        public static final int STOP_ACTIVITY_HIDE      = 104;
        public static final int SHOW_WINDOW             = 105;
        public static final int HIDE_WINDOW             = 106;
        ......
        
        public void handleMessage(Message msg) {
            if (DEBUG_MESSAGES) Slog.v(TAG, ">>> handling: " + codeToString(msg.what));
            switch (msg.what) {
                case LAUNCH_ACTIVITY: {
                    Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "activityStart");
                    final ActivityClientRecord r = (ActivityClientRecord) msg.obj;

                    r.packageInfo = getPackageInfoNoCheck(
                            r.activityInfo.applicationInfo, r.compatInfo);
                    handleLaunchActivity(r, null);
                    Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
                } break;
                case RELAUNCH_ACTIVITY: {
                    Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "activityRestart");
                    ActivityClientRecord r = (ActivityClientRecord)msg.obj;
                    handleRelaunchActivity(r);
                    Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
                } break;
              ......
```

代码太长，只截取了片段，到此我们不再深入了。其实从 H 类中的变量名以及函数名等，我们也能大概猜到，整个 App 中的事件，包括 Activity 的启动、销毁，Intent 跳转等，都是通过 mH 发出信息后，在 loop 中提取，再交回给 mH 去执行的，具体来讲，就是通过上面代码中的 handleLaunchActivity 这类函数去处理。所以，main 函数在走到 Looper.loop() 后，我们的 app 就一直在 loop 循环中不断地接收消息，并执行。而我们平时经常使用的如 startActivity 这样的函数，最后也是通过 mH 发出消息执行相应的处理函数来完成的。所以说，整个 app 都是靠 Looper 以及 Handler 的相互合作运转的。

至此，整个 Handler 的运作机制算是忽悠完了。这其中还有很多值得慢慢品味的地方，像 Message 的获取这些小细节，还是很能提高 app 的运行效率的。为了不让自己空虚堕落，之后博主会继续找时间研究代码写文章的😐。