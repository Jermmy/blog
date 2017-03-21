---
title: Android--Handler运作机制剖析（一）
tags: Android
categories: Android
---

博主第一次使用 Handler 是为了在子线程中修改控件内容，因为 Android 不允许非 UI 线程修改控件，因此要用 Handler 通知 UI 线程去修改。今天抽空看了些文章和源码，理解一下背后的运行机制。

<!--more-->

## Handler, Looper, MessageQueue的关系

可以说，Handler 背后的运作都是靠 Looper 支撑的，它们三者的关系可以这样表示

``` java
class Handler {
  Looper mLooper;
  MessageQueue queue;    // 这个queue其实就是mLooper中的queue
  ...
}
final class Looper {
  MessageQueue queue;
  ...
} 
```

Handler 中持有 Looper 的引用，当 Handler 通过 sendMessage 等方法发送 Message 时，这些 Message 会被放入 queue 中，之后 Looper 会不断地轮询 queue，取出信息并执行。所以，如果没有 Looper，Handler 发送的消息只是简单地放入队列，而不会执行。下面从源码的角度慢慢剖析这些是怎么实现的。

## Handler中的Looper是怎么来的

这个问题要从构造函数中入手，平时实例化 Handler 的代码一般是这样的

``` java
Handler mHandler = new Handler();
```

这里面没有传入任何参数，博主从这个最基本的构造函数进入源码后，发现只是一句代码的事

``` java
public Handler() {
        this(null, false);
}
```

它会进一步调用下面这个构造函数

``` java
    public Handler(Callback callback, boolean async) {
        ...一些无关主题的代码

        mLooper = Looper.myLooper();
        if (mLooper == null) {
            throw new RuntimeException(
                "Can't create handler inside thread that has not called Looper.prepare()");
        }
        mQueue = mLooper.mQueue;
        mCallback = callback;
        mAsynchronous = async;
    }
```

mLooper 引用的赋值会进一步调用 Looper.myLooper 函数

``` java
    // sThreadLocal.get() will return null unless you've called prepare().
    static final ThreadLocal<Looper> sThreadLocal = new ThreadLocal<Looper>();

    public static @Nullable Looper myLooper() {
        return sThreadLocal.get();
    }
```

这个 `ThreadLocal` 保存的是线程的一些局部变量，具体来讲，当我们调用它的 get 方法时，它会返回当前线程的 Looper 引用，这样，Handler 就与所在线程的 Looper 绑定在一起了。那线程的 Looper 又是怎么来的呢？在揭示谜底前，博主先用一个例子铺垫。

新建一个 Android 工程，在一个子线程中实例化 Handler

``` java
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        MyThread thread = new MyThread();
        thread.start();

    }

    class MyThread extends Thread {
        Handler handler;

        @Override
        public void run() {
            handler = new Handler();
            Log.i("MyThread", "handler instantiation");
        }
    }
```

代码很简洁，先不要问为什么要在子线程中实例化，后面解释。跑起来后等待异常抛出：

``` java
E/AndroidRuntime: FATAL EXCEPTION: Thread-440
        java.lang.RuntimeException: Can't create handler inside thread that has not called Looper.prepare()
        at android.os.Handler.<init>(Handler.java:121)
```

好，真相就是，线程的 Looper 是通过 Looper.prepare() 获得的，直接找它的源码呀

``` java
     /** Initialize the current thread as a looper.
      * This gives you a chance to create handlers that then reference
      * this looper, before actually starting the loop. Be sure to call
      * {@link #loop()} after calling this method, and end it by calling
      * {@link #quit()}.
      */
    public static void prepare() {
        prepare(true);
    }

    private static void prepare(boolean quitAllowed) {
        if (sThreadLocal.get() != null) {
            throw new RuntimeException("Only one Looper may be created per thread");
        }
        sThreadLocal.set(new Looper(quitAllowed));
    }
```

好了，现在我们知道调用 prepare 函数的时候，系统 new 了一个 Looper 并 set 到 `ThreadLocal` 里面去了，这样，这个线程对应的 `TheadLocal` 便持有了 Looper，然后我们在实例化 Handler 的时候，`Looper `用 myLooper 方法从这个 `ThreadLocal` 中取出 Looper，并跟 Handler 关联起来。至此，Handler 实例化完成。读者可以试一下把上面例子中的 MyThread 类修改如下，看看能不能正常实例化 Handler

``` java
    class MyThread extends Thread {
        Handler handler;

        @Override
        public void run() {
            Looper.prepare();
            handler = new Handler();
            Log.i("MyThread", "handler instantiation");
            Log.i("MyThread", "" + Thread.currentThread());
            Log.i("MyThread", "" + handler.getLooper().getThread());
        }
    }
```

注意，一定要在 run 方法中实例化，只有 run 方法运行的时候，系统才将 cpu 切换给子线程，run 方法外面的作用域还都是 UI 线程的。可以看看 Log 中 `handler` 所在的线程是否是子线程。

## UI线程的Looper

那么为什么我要在子线程中实例化 Handler 呢？只是想让你感受下差别。想想你平时在 UI 线程中实例化 Handler 的时候肯定没调用 Looper.prepare 方法吧。我们没调用并不代表系统不会帮我们调用呀，我们来看看 UI 线程的 Looper 是怎么实例化的。

我们要打开一个叫做 ActivityThread.java 的文件，博主在 AS 中没法进入这个文件的源码，所以就直接在 sdk 的 sources 目录下寻找了（现在知道下载源码的重要性了吧^_^）。这个类的包名是 android.app ，找到这个文件后打开它，在文件最后找到 main 函数。

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

这个 main 是不是跟 Java 的 main 函数一模一样啊，Android 的第一层编译处理用的仍然是 Java compiler ，因此语法上肯定得符合 Java 的规范啦，没有 main 函数怎么玩。官网有讲到整个 build 的流程[http://developer.android.com/intl/zh-cn/sdk/installing/studio-build.html](http://developer.android.com/intl/zh-cn/sdk/installing/studio-build.html) 。

作为整个应用程序的入口，我们所有的 Activity 都是从这个 main 函数启动的呢。所以，这个 main 函数也就是我们平时说的 UI 线程。然后你看最开始那里，调用了 Looper 的 prepareMainLooper 方法，从名字推测也能知道就是初始化 UI 线程的 Looper 啦，不放心的话，我们再看看源码

``` java
    /**
     * Initialize the current thread as a looper, marking it as an
     * application's main looper. The main looper for your application
     * is created by the Android environment, so you should never need
     * to call this function yourself.  See also: {@link #prepare()}
     */
    public static void prepareMainLooper() {
        prepare(false);
        synchronized (Looper.class) {
            if (sMainLooper != null) {
                throw new IllegalStateException("The main Looper has already been prepared.");
            }
            sMainLooper = myLooper();
        }
    }

    private static void prepare(boolean quitAllowed) {
        if (sThreadLocal.get() != null) {
            throw new RuntimeException("Only one Looper may be created per thread");
        }
        sThreadLocal.set(new Looper(quitAllowed));
    }

    /**
     * Return the Looper object associated with the current thread.  Returns
     * null if the calling thread is not associated with a Looper.
     */
    public static @Nullable Looper myLooper() {
        return sThreadLocal.get();
    }
```

懂了吧，虽然拐了几个弯，道理都是一样的。在UI主线程中，系统通过 `ThreadLocal` 获得 UI 线程的 Looper 对象。所以你平时直接通过 `Handler handler = new Handler();` 是不会有问题的，因为这个 Handler 会跟主线程的 sMainLooper 绑定。

## Handler绑定Looper

讲到这里，对于 Handler 的 Looper 是怎么来的这个问题应该没有疑问了吧。那如果主线程声明的 Handler 想跟子线程的 Looper 绑定要怎么做呢？除了前面提到的在 run 方法中实例化 Handler，Android 提供了其他灵活的接口，我们可以用 Handler 的另一个构造函数

``` java
    /**
     * Use the provided {@link Looper} instead of the default one.
     *
     * @param looper The looper, must not be null.
     */
    public Handler(Looper looper) {
        this(looper, null, false);
    }
```

先在子线程中实例化Looper，再把这个Looper赋值给Handler就行啦。具体可以看下面这个例子：

``` java
    Handler handler;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        MyThread thread = new MyThread();
        thread.start();
        handler = new Handler(thread.looper);
        Log.i("main thread", "" + handler.getLooper().getThread());
    }

    class MyThread extends Thread {
        Looper looper;

        @Override
        public void run() {
            Looper.prepare();
            looper = Looper.myLooper();
            Log.i("sub thread", "" + Thread.currentThread());
        }
    }
```

代码很简单对吧，跑起来看挂不挂，反正我是挂了，什么异常呢

``` java
Caused by: java.lang.NullPointerException
       at android.os.Handler.<init>(Handler.java:157)
       at com.xxx.myapplication.MainActivity.onCreate(MainActivity.java:19)
```

这个 Looper 居然是空的。其实也不足为奇，因为你在子线程中实例化的 Looper，又在主线程中实例化 Handler，稍微不同步就出差错了。那怎么让它们同步呢？就看你操作系统怎么学了。博主在原来的基础上加了判断

``` java
    Handler handler;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        MyThread thread = new MyThread();
        thread.start();
        handler = new Handler(thread.getLooper());
        Log.i("main thread", "" + handler.getLooper().getThread());
    }

    class MyThread extends Thread {
        Looper looper;

        @Override
        public void run() {
            Looper.prepare();
            synchronized (this) {
                looper = Looper.myLooper();
                notifyAll();
            }
            Log.i("sub thread", "" + Thread.currentThread());
        }

        public Looper getLooper() {
            synchronized (this) {
                while (looper == null) {
                    try {
                        wait();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }
            return looper;
        }
    }
```

这样，UI 线程在实例化 Handler 的时候，如果 Looper 是 null 的话，UI 线程就会等待，直到子线程成功实例化 looper 并唤醒。是不是觉得博主有点机智啊^_^，其实我是参考了 Android 的源码写的，Android 已经预料到这种问题，并提供了一个 `HandlerThread` 来帮我们处理同步的问题，这里就不细讲了，有兴趣的读者可以自行查看。（话说，博主在实际开发中并没有遇到在 Handler 中绑定其他 Looper 的例子，博主还比较小白😅）

扯了这么多，总算搞定了 Looper 来源的问题，一切才刚开始，下一篇文章我们再来慢慢剖析 Looper 是怎么工作的。











