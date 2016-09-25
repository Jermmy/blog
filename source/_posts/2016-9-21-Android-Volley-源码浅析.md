---
title: Android Volley源码浅析
date: 2016-09-21 22:01:25
tags: Android
categories: Android
---

Volley，中文翻译为“万箭齐发”，也就是适合大规模的小数据包发送的场景。Google于2013年I/O大会上发布这个类库，试图弥补`UrlConnection`封装性太差的问题（Android原生系统中用于网络请求的组件一般是`HttpUrlConnection`和`HttpClient`两种，后者适合Android2.2及以前的版本，但在API23开始便被舍弃了，前者适合于Android2.3及以上版本）。由于Volley自带异步线程回调机制，可以代替`AsyncTask`繁琐的接口，另外加上Volley的缓存功能，因此总体来说是一个大的改进。

<!--more-->

<br\>

### 开发者接口

`Volley`通常的使用接口如下：

```java
RequestQueue mRequestQueue = Volley.newRequestQueue(mContext.getApplicationContext());
Request request = new Request();
// 实现回调接口
request.listener = new Response.Listener() {...};
request.errorListener = new Response.ErrorListener() {...};

mRequestQueue.add(request);
```

简单来讲，开发者需要关注的类只有`RequestQueue`、`Request`，所以接下来就把目标集中在这两个类上。

<br\>

### 浅析源代码

1. `Volley.java`（片段）

```java
    public static RequestQueue newRequestQueue(Context context, HttpStack stack) {
        File cacheDir = new File(context.getCacheDir(), "volley");
        String userAgent = "volley/0";

        try {
            String network = context.getPackageName();
            PackageInfo queue = context.getPackageManager().getPackageInfo(network, 0);
            userAgent = network + "/" + queue.versionCode;
        } catch (NameNotFoundException var6) {
            ;
        }

        if(stack == null) {
            if(VERSION.SDK_INT >= 9) {
                stack = new HurlStack();
            } else {
                stack = new HttpClientStack(AndroidHttpClient.newInstance(userAgent));
            }
        }

        BasicNetwork network1 = new BasicNetwork((HttpStack)stack);
        RequestQueue queue1 = new RequestQueue(new DiskBasedCache(cacheDir), network1);
        queue1.start();
        return queue1;
    }

    public static RequestQueue newRequestQueue(Context context) {
        return newRequestQueue(context, (HttpStack)null);
    }
```

`Volley`内部创建`RequestQueue`的时候，会根据版本号创建不同的`HttpStack`，因为开头说过Android的两大网络组件适用的系统版本号不同。在实例化`RequestQueue`的时候，Android传入两个组件：`DiskBasedCache`, `BasicNetwork`。前面也提到过，`Volley`内部除了做网络请求，还会缓存请求，而这两个组件分别对应这两种功能。注意缓存目录是app内部的cache file。

下面进入`RequestQueue`内部。

2. `RequestQueue.java`（片段）

```java
    public RequestQueue(Cache cache, Network network, int threadPoolSize, ResponseDelivery delivery) {
        this.mSequenceGenerator = new AtomicInteger();
        this.mWaitingRequests = new HashMap();
        this.mCurrentRequests = new HashSet();
        this.mCacheQueue = new PriorityBlockingQueue();
        this.mNetworkQueue = new PriorityBlockingQueue();
        this.mCache = cache;
        this.mNetwork = network;
        this.mDispatchers = new NetworkDispatcher[threadPoolSize];
        this.mDelivery = delivery;
    }

    public RequestQueue(Cache cache, Network network, int threadPoolSize) {
        this(cache, network, threadPoolSize, new ExecutorDelivery(new Handler(Looper.getMainLooper())));
    }

    public RequestQueue(Cache cache, Network network) {
        this(cache, network, 4);
    }

    public void start() {
        this.stop();
        this.mCacheDispatcher = new CacheDispatcher(this.mCacheQueue, this.mNetworkQueue, this.mCache, this.mDelivery);
        this.mCacheDispatcher.start();

        for(int i = 0; i < this.mDispatchers.length; ++i) {
            NetworkDispatcher networkDispatcher = new NetworkDispatcher(this.mNetworkQueue, this.mNetwork, this.mCache, this.mDelivery);
            this.mDispatchers[i] = networkDispatcher;
            networkDispatcher.start();
        }

    }
```

这一段代码基本把所有重要的组件涵盖了。其中最重要的变量分别是：`mCacheQueue`, `mNetworkQueue`, `mCache`, `mNetwork`, `mDispatchers`,  `mCacheDispatcher`,  `mDelivery`。接下来不会深入去了解这些组件的细节，只大概分析一下它们的作用。

`mDispatchers`和`mCacheDispatcher`分别是负责网络请求以及本地缓存的任务线程（继承自`Thread`），其中网络线程默认实例化了四条。

`mCacheQueue`, `mNetworkQueue`是存放`Request`的队列，缓存线程和网络线程会分别从这两个队列获取`Request`。队列类型是`PriorityBlockingQueue`，是java并发库的一种队列实现，能够对队列内的元素进行优先级排序（实现Request的优先级请求），同时是属于阻塞性队列（Blocking，如果没有元素，会使相应的线程陷入阻塞，而不是空转）。

`mCache`, `mNetwork`是之前传入的`DiskBasedCache`, `BasicNetwork`。这两个组件分别是为了解析缓存的请求和网络请求使用的。可以认为是请求解析类。

`mDelivery`主要用于回调接口的调用，Volley将它实例化成`ExecutorDelivery`，从构造函数中可以看出，Volley将它和Handler（绑定MainLooper）绑定，从而可以和UI线程交互。

<br\>

### 总体架构图

 ![屏幕快照 2016-09-22 上午12.27.08](/images/2016-9-21/屏幕快照 2016-09-22 上午12.27.08.png)