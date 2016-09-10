---
title: Thinking in Java — 并发
date: 2016-09-10 10:50:00
tags: Java
---

今天温习一下Java多线程的知识（文中代码除非特别说明，否则均摘自《Thinking in Java》(第四版)）。

`Runnable`，`Thread`的简单使用表过不谈，只总结一下不熟悉的知识点。

<br\>

### 使用`Executor`

作者只是简单提了一下这个东西，具体知识属于进阶内容。

`Executor`可以认为是一个管理线程池的东西，它允许你管理异步任务的执行，而无须显示地管理线程的生命周期。`Executor`在Java SE5/6是启动线程的优选方法。

```java
import java.util.concurrent.*;

class LiftOff implements Runnable {
	protected int countDown = 10;
	private static int taskCount = 0;
	private final int id = taskCount++;
	public LiftOff() {}
	public LiftOff(int countDown) {
		this.countDown = countDown;
	}
	public String status() {
		return "#" + id + "(" + (countDown > 0 ? countDown : "LiftOff!") + "), ";
	}
	@Override
	public void run() {
		while (countDown-- > 0) {
			System.out.print(status());
			Thread.yield();
		}
	}
}

public class CachedThreadPool {
	public static void main(String[] args) {
		ExecutorService exec = Executors.newCachedThreadPool();
		for (int i = 0; i < 5; i++) {
			exec.execute(new LiftOff());
		}
		exec.shutdown();
	}
}
```

输出如下：

```shell
#0(9), #1(9), #3(9), #0(8), #2(9), #1(8), #2(8), #4(9), #2(7), #4(8), #2(6), #0(7), #2(5), #1(7), #3(8), #0(6), #1(6), #4(7), #0(5), #3(7), #4(6), #2(4), #3(6), #0(4), #1(5), #4(5), #2(3), #3(5), #0(3), #1(4), #4(4), #2(2), #3(4), #0(2), #1(3), #2(1), #4(3), #3(3), #0(1), #1(2), #2(LiftOff!), #4(2), #3(2), #0(LiftOff!), #1(1), #4(1), #3(1), #1(LiftOff!), #4(LiftOff!), #3(LiftOff!),
```

通常，我们会通过`Executors`的工厂方法得到一个`ExecutorService`服务，上例中我们使用了`CachedThreadPool`作为线程池，在程序执行的过程中，它会创建与所需数量相同的线程，然后在回收旧线程时开始复用线程。作者将它作为`Executors`的首选服务，另外还有`FixedThreadPool`和`SingleThreadPool`等。

使用这个类库方便的地方在于，我们只要实现好`Runnable`接口，至于线程的实例化、销毁等，全部交由`ExecutorService`管理即可。开发者只需要调用`execute()`方法将`Runnable`对象传入。关闭`ExecutorService`服务时，可以调用`shutdown()`方法，这样新的任务将无法提交给`ExecutorService`，等之前提交的所有任务执行完毕后，服务也会尽快退出。

<br\>

### 从线程产生返回值

众所周知，`Runnable`执行结束后是无法返回任何值的。如果希望任务在完成时能够返回一个值，那么可以实现`Callable`接口。`Callable`是一个泛型类，它的类型参数表示的是从`call`方法返回的值（call类似于Runnable的run方法）。还有一点，必须使用`ExecutorService.submit()`方法调用它。

```java
import java.util.concurrent.*;
import java.util.*;

class TaskWithResult implements Callable<String> {
	private int id;
	public TaskWithResult(int id) {
		this.id = id;
	}
	@Override
	public String call() {
		return "result of TaskWithResult " + id;
	}
}

public class CallableDemo {
	public static void main(String[] args) {
		ExecutorService exec = Executors.newCachedThreadPool();
		ArrayList<Future<String>> results = new ArrayList<Future<String>>();
		for (int i = 0; i < 10; i++) {
			results.add(exec.submit(new TaskWithResult(i)));
		}
		for (Future<String> fs : results) {
			try {
				System.out.println(fs.get());
			} catch(InterruptedException e) {
				e.printStackTrace();
			} catch(ExecutionException e) {
				e.printStackTrace();
			} finally {
				exec.shutdown();
			}
		}
	}
}
```

输出如下结果：（貌似没体现出多线程的特性）

```java
result of TaskWithResult 0
result of TaskWithResult 1
result of TaskWithResult 2
result of TaskWithResult 3
result of TaskWithResult 4
result of TaskWithResult 5
result of TaskWithResult 6
result of TaskWithResult 7
result of TaskWithResult 8
result of TaskWithResult 9
```

`submit()`方法会产生`Future`对象，它会对`Callable`返回结果的特定类型进行参数化。可以用`isDone()`来判断`Future`是否已经完成，然后用`get()`来获得线程返回的结果。上面的例子直接调用`fs.get()`，此时将阻塞直至结果返回。

更详细的用法请参考其他资料。

<br\>

### Join

关于join的用法，我总结成一句话（可能不全）：

假设A、B是两个线程，`A`执行的时候调用`B.join()`，`A`会被挂起直到`B`结束才执行。

`join()`方法还可以传入一个超时参数，这样超过指定时间线程也可以开始执行。

另外，调用`interrupt()`方法可以中断`join()`方法。

例子：

```java
class Sleeper extends Thread {
	private int duration;
	public Sleeper(String name, int sleepTime) {
		super(name);
		duration = sleepTime;
		start();
	}

	public void run() {
		try {
			sleep(duration);
		} catch(InterruptedException e) {
			System.out.println(getName() + " was interrupted. " + 
				"isInterrupted(): " + isInterrupted());
			return;
		}
		System.out.println(getName() + " has awakened");
	}
}

class Joiner extends Thread {
	private Sleeper sleeper;
	public Joiner(String name, Sleeper sleeper) {
		super(name);
		this.sleeper = sleeper;
		start();
	}
	public void run() {
		try {
			sleeper.join();
		} catch(InterruptedException e) {
			System.out.println("Interrupted");
		}
		System.out.println(getName() + " join completed");
	}
}

public class Joining {
	public static void main(String[] args) {
		Sleeper sleepy = new Sleeper("Sleepy", 1500),
		        grumpy = new Sleeper("Grumpy", 1500);
		Joiner dopey = new Joiner("Dopey", sleepy),
		       doc = new Joiner("Doc", grumpy);
		grumpy.interrupt();
	}
}
```

输出：

```shell
Grumpy was interrupted. isInterrupted(): false
Doc join completed
Sleepy has awakened
Dopey join completed
```

上面的例子中，`Joiner`线程在执行的时候，会先调用`Sleeper`线程的`join()`方法，这样，前者只有等后者执行完才会继续执行，除非被`interrupt()`打断。

这里要关注的应该是`join()`的使用时机，我认为，`join`的目的是为了线程间的同步，所以通常用法应该是：`A`执行到某一步的时候，需要等`B`执行完，才调用`B.join()`。

上面的例子中还有一个小tip，就是线程调用`interrupt()`方法后，该线程会设定一个标志位，表明被中断。但异常被捕获时会清理标志位，所以能看到为什么例子中的`isInterrupted()`方法会返回false。

<br\>

### Synchronized

#### 同步方法

同步是java为防止资源冲突提供的内置支持。

所有对象都自动含有单一的锁（也称为监视器）。当在对象上调用其任意`synchronized`方法时，该对象都被加锁，这时该对象上的其他`synchronized`方法只有等到前一个方法调用完毕并释放锁后才能被调用。所以，对于某个特定对象而言，其所有`synchronized`方法共享同一个锁。

针对每个类，也有一个锁（作为`Class`对象的一部分），所以`synchronized static`方法可以在类的范围内防止对static数据的并发访问。

什么时候应该上锁呢？Bruce建议：每个访问临界共享资源的方法都必须被同步，否则它们就不会正确地工作。

#### 临界区

除了将整个函数上锁的方式，还可以使用同步控制块的方式防止冲突。

```java
synchronized (object) {
  
}
```

这种方式相比前一种而言，更加灵活，且效率更高。

#### 同步对象

`synchronized`同步块必须给定一个同步对象，最合理的方式是使用当前对象，也就是`synchronized(this)`，在这种方式中，如果获得了`synchronized`块的锁，那么该对象其他的`synchronized`方法和临界区就不能被调用了。

也可以在其他对象上同步，请看下面的例子：

```java
class DualSynch {
	private Object syncObject = new Object();
	public synchronized void f() {
		for (int i = 0; i < 5; i++) {
			System.out.println("f()");
			Thread.yield();
		}
	}
	public synchronized void e() {
		for (int i = 0; i < 5; i++) {
			System.out.println("e()");
			Thread.yield();
		}
	}
	public void g() {
		synchronized (syncObject) {
			for (int i = 0; i < 5; i++) {
				System.out.println("g()");
				Thread.yield();
			}
		}
	}
}

public class SyncObject {
	public static void main(String[] args) {
		final DualSynch ds = new DualSynch();
		new Thread() {
			public void run() {
				ds.f();
			}
		}.start();
		new Thread() {
			public void run() {
				ds.e();
			}
		}.start();
		ds.g();
	}
}
```

我在原书代码的基础上增加了同步方法`public synchronized void e() `，这样更容易看到区别。`Thread.yield()`是为了使线程相互抢占cpu的现象更加明显。

输出如下：

```shell
f()
g()
f()
g()
g()
g()
f()
f()
f()
e()
e()
g()
e()
e()
e()
```

可以清楚地看到，虽然`f()`和`g()`都有同步代码块，但由于二者的同步对象不同（`f()`是this对象，而`g()`是syncObject），所以二者依然可以“同时”执行。但`e()`需要的对象先被`f()`占有了，所以必须等`f()`执行完释放同步对象后，`e()`才能执行。