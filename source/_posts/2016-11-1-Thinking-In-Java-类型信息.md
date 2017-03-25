---
title: Thinking in Java — 类型信息
date: 2016-11-01 21:33:26
tags: [Java]
categories: Java
---

这一章将讨论Java是如何让我们在运行时识别对象和类的信息的。主要有两种方式：1、“传统的”RTTI，它假定我们在编译时已经知道了所有的类型；2、“反射”机制，它允许我们在运行时发现和使用类的信息。

<!--more-->

### `Class`对象

要理解RTTI在java中的工作原理，首先必须知道类型信息在运行时是如何表示的。这项工作由称为`Class`的特殊对象完成。事实上，`Class`对象就是用来创建类的所有的“常规”对象。

类是程序的一部分，每个类都有一个`Class`对象。换言之，每当编写一个新类，就会产生一个`Class`对象（保存在.class文件）。这个工作由被称为“类加载器”（ClassLoader）的子系统完成。

类加载器子系统实际上包含一条类加载器链，但是只有一个**原生类加载器**，它是JVM实现的一部分。原声类加载器加载所谓的：可信类：，包括Java API类。

**所有的类都是在对其第一次使用时，动态加载到JVM的。**当程序创建第一个对类的静态成员的引用时，就会加载这个类，这说明**构造器也是类的静态方法**。

因此，java程序在开始运行之前并非被完全加载，而是按需加载。类加载器首先检查这个类的Class对象是否已经加载。如果尚未加载，默认的类加载器就会根据类名查找.class文件。这个类的字节码被加载时，会接受验证，以确保其没有被破坏，并且没有包括不良Java代码。

<br\>

#### `Class`提供的常用API

| 方法                      | 说明                      |
| ----------------------- | ----------------------- |
| `Class.forName("name")` | 获得某个类的Class对象的引用        |
| `getName()`             | 获得该Class对象的完整名称         |
| `getSimpleName()`       | 获得该Class对象的名称（不包括包名）    |
| `isInterface()`         | 是否是接口                   |
| `getInterfaces()`       | 获得该Class实现的所有接口的Class对象 |
| `getSuperClass()`       | 获得该Class继承的父类的Class对象   |

<br\>

#### 使用类字面常量

Java提供了另一种方法来生成对Class对象的引用，即`.class`。这样做比使用`forName()`更加安全，因为它会在编译期受到检查，故不必使用`try`语句。

为了使用类而做的准备工作实际包含三步：

1. 加载。这是由类加载器完成的。该步骤将查找字节码，并创建一个Class对象；
2. 链接。验证类中的字节码，为静态域分配存储空间。如果必须的话，将解析这个类创建的对其他类的引用；
3. 初始化。如果该类具有超类，则对其初始化。执行静态初始化器和静态初始化块。

有趣的是，使用`.class`来创建对Class的引用时，不会自动初始化Class对象。

```java
import java.util.*;

class Initable {
	static final int staticFinal = 47;
	static final int staticFinal2 = ClassInitialization.rand.nextInt(1000);
	static {
		System.out.println("Initializing Initable");
	}
}

class Initable2 {
	static int staticNonFinal = 147;
	static {
		System.out.println("Initializing Initable2");
	}
}

class Initable3 {
	static int staticNonFinal = 74;
	static {
		System.out.println("Initializing Initable3");
	}
}

public class ClassInitialization {
	public static Random rand = new Random(47);
	public static void main(String[] args) throws Exception {
		Class initable = Initable.class;
		System.out.println("After creating Initable ref");

		System.out.println(Initable.staticFinal);

		System.out.println(Initable.staticFinal2);

		System.out.println(Initable2.staticNonFinal);

		Class initable3 = Class.forName("Initable3");
		System.out.println("After creating Initable3 ref");
		System.out.println(Initable3.staticNonFinal);
	}
}
```

输出：

```shell
After creating Initable ref
47
Initializing Initable
258
Initializing Initable2
147
Initializing Initable3
After creating Initable3 ref
74
```

上面这个例子需要注意两点：

1. 在使用`Initable.class`获得`Initable`的Class的引用时，并没有输出`static`静态代码区的内容，也就是说此时`Initable`类并没有加载；
2. 输出`Initable.staticFinal`时，静态代码段同样没有执行，因为这个变量是个“编译期常量”，不需要初始化类就可以加载。但输出`Initable.staticFinal2`时则执行了加载操作，因为这不是一个编译期常量。


<br\>

### 类型转换前先做检查

迄今为止，我们已知的RTTI形式包括：

1. 传统的类型转换，如果执行了一个错误的类型转换，就会抛出一个`ClassCastException`异常；
2. 代表对象的类型的`Class`对象。通过查询`Class`对象可以获取运行时所需的信息。

<br\>

### 反射：运行时的类信息

Java的`Class`类和`java.lang.reflect`类库一起对反射的概念进行了支持，该类库包含了`Field`、`Method`以及`Constructor`类（每个类都实现了`Member`接口）。这些类型的对象是由JVM在运行时创建的，用以表示未知类里对应的成员。

当通过反射与一个未知类型的对象打交道时，JVM只是简单地检查这个对象，看它属于哪个特定的类（就像RTTI）。在用它做其他事情之前必须先加载那个类的`Class`对象。因此，那个类的**.class**文件对于JVM来说必须是可获取的：要么在本地机器上，要么可以通过网络取得。所以RTTI和反射之间真正的区别只在于：对RTTI来说，编译器在编译时打开和检查**.class**文件；对于反射机制来说，**.class**文件在编译时是不可获取的，所以在运行时打开和检查**.class**文件。