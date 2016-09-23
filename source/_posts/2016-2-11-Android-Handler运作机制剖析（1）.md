---
title: Android--Handler运作机制剖析（一）
tags: Android
categories: Android
---

博主第一次使用Handler是为了在子线程中修改控件内容，因为Android不允许非UI线程修改控件，因此要用Handler通知UI线程去修改。今天抽空看了些文章和源码，理解一下背后的运行机制。

<!--more-->

## Handler, Looper, MessageQueue的关系

可以说，Handler背后的运作都是靠Looper支撑的，它们三者的关系可以这样表示

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

Handler中持有Looper的引用，当Handler通过sendMessage等方法发送Message时，这些Message会被放入queue中，之后Looper会不断地轮询queue，取出信息并执行。所以，如果没有Looper，Handler发送的消息只是简单地放入队列，而不会执行。下面从源码的角度慢慢剖析这些是怎么实现的。

## Handler中的Looper是怎么来的

这个问题要从构造函数中入手，平时实例化Handler的代码一般是这样的

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

mLooper引用的赋值会进一步调用Looper.myLooper函数

``` java
    // sThreadLocal.get() will return null unless you've called prepare().
    static final ThreadLocal<Looper> sThreadLocal = new ThreadLocal<Looper>();

    public static @Nullable Looper myLooper() {
        return sThreadLocal.get();
    }
```

这个`ThreadLocal`保存的是线程的一些局部变量，具体来讲，当我们调用它的get方法时，它会返回当前线程的Looper引用，这样，Handler就与所在线程的Looper绑定在一起了。那线程的Looper又是怎么来的呢？在揭示谜底前，博主先用一个例子铺垫。

新建一个Android工程，在一个子线程中实例化Handler

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

好，真相就是，线程的Looper是通过Looper.prepare()获得的，直接找它的源码呀

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

好了，现在我们知道调用prepare函数的时候，系统new了一个Looper并set到`ThreadLocal`里面去了，这样，这个线程对应的`TheadLocal`便持有了Looper，然后我们在实例化Handler的时候，`Looper`用myLooper方法从这个`ThreadLocal`中取出Looper，并跟Handler关联起来。至此，Handler实例化完成。读者可以试一下把上面例子中的MyThread类修改如下，看看能不能正常实例化Handler

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

注意，一定要在run方法中实例化，只有run方法运行的时候，系统才将cpu切换给子线程，run方法外面的作用域还都是UI线程的。可以看看Log中`handler`所在的线程是否是子线程。

## UI线程的Looper

那么为什么我要在子线程中实例化Handler呢？只是想让你感受下差别。想想你平时在UI线程中实例化Handler的时候肯定没调用Looper.prepare方法吧。我们没调用并不代表系统不会帮我们调用呀，我们来看看UI线程的Looper是怎么实例化的。

我们要打开一个叫做ActivityThread.java的文件，博主在AS中没法进入这个文件的源码，所以就直接在sdk的sources目录下寻找了（现在知道下载源码的重要性了吧^_^）。这个类的包名是android.app，找到这个文件后打开它，在文件最后找到main函数。

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

这个main是不是跟Java的main函数一模一样啊，Android的第一层编译处理用的仍然是Java compiler，因此语法上肯定得符合Java的规范啦，没有main函数怎么玩。官网有讲到整个build的流程[http://developer.android.com/intl/zh-cn/sdk/installing/studio-build.html](http://developer.android.com/intl/zh-cn/sdk/installing/studio-build.html) 。

作为整个应用程序的入口，我们所有的Activity都是从这个main函数启动的呢。所以，这个main函数也就是我们平时说的UI线程。然后你看最开始那里，调用了Looper的prepareMainLooper方法，从名字推测也能知道就是初始化UI线程的Looper啦，不放心的话，我们再看看源码

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

懂了吧，虽然拐了几个弯，道理都是一样的。在UI主线程中，系统通过`ThreadLocal`获得UI线程的Looper对象。所以你平时直接通过`Handler handler = new Handler();`是不会有问题的，因为这个Handler会跟主线程的sMainLooper绑定。

## Handler绑定Looper

讲到这里，对于Handler的Looper是怎么来的这个问题应该没有疑问了吧。那如果主线程声明的Handler想跟子线程的Looper绑定要怎么做呢？除了前面提到的在run方法中实例化Handler，Android提供了其他灵活的接口，我们可以用Handler的另一个构造函数

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

这个Looper居然是空的。其实也不足为奇，因为你在子线程中实例化的Looper，又在主线程中实例化Handler，稍微不同步就出差错了。那怎么让它们同步呢？就看你操作系统怎么学了。博主在原来的基础上加了判断

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

这样，UI线程在实例化Handler的时候，如果Looper是null的话，UI线程就会等待，直到子线程成功实例化looper并唤醒。是不是觉得博主有点机智啊^_^，其实我是参考了Android的源码写的，Android已经预料到这种问题，并提供了一个`HandlerThread`来帮我们处理同步的问题，这里就不细讲了，有兴趣的读者可以自行查看。（话说，博主在实际开发中并没有遇到在Handler中绑定其他Looper的例子，博主还比较小白😅）

扯了这么多，总算搞定了Looper来源的问题，一切才刚开始，下一篇文章我们再来慢慢剖析Looper是怎么工作的。











