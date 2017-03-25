---
layout: post
title: Java-Deep and shallow copy
tags: Java
categories: Java
date: 2016-7-28
---

最近将一段 C++ 算法代码改成 Java 版本迁移到 android 平台的时候，发现我的 Java 底子有点薄。比方说，连 Java 深拷贝和浅拷贝都没搞清。

<!--more-->

### 深拷贝和浅拷贝

其实，Java 里面大部分赋值操作都属于浅拷贝。比如下面这个例子：

```java
    public static void main(String[] args) {
        ArrayList<Integer> l1 = new ArrayList<Integer>();
        l1.add(0);
        ArrayList<Integer> l2 = l1;
        l2.add(1);
        System.out.println(l1);
        System.out.println(l2);
    }
```

输出结果为：

```java
[0, 1]
[0, 1]
```

也就是说，l1 和 l2 指向的是同一份内存空间（这一点在 C++ 写多了后就容易遗忘）。

那现在我想实现深拷贝，也就是修改 l2 的值，却不影响 l1，该怎么做呢？Java 问世的时候就已经提供了解决方案，那就是 `Object` 的 `clone` 方法。看下面的例子：

```java
 public class Person implements Cloneable {
    int age;
    public Person(int a) {
        age = a;
    }

    public Person clone() {
        return new Person(age);
    }

    public String toString() {
        return "age: " + age;
    }
  }
```

我们定义了一个 Person 类，并实现 `Cloneable` 接口和 `Object` 中的 clone 方法。这个方法会返回一个新的 Person 实例，其中成员变量和原 Person 一样，但它们属于不同的内存空间。其实我看了 `Cloneable` 接口的代码后，发现这个接口是空的，也就是说，它只是起到一个标识符的作用。但实际操作的时候我发现不实现这个接口也能正常运行，暂时没搞明白是否一定要实现它。下面看 main 函数：

```java
public class Test {
  
    public static void main(String[] args) {
    	ArrayList<Person> l1 = new ArrayList<Person>();
    	l1.add(new Person(3));
        ArrayList<Person> l2 = (ArrayList<Integer>)l1.clone();
        l2.add(l1.get(0));
        l2.add(l1.get(0).clone());
        System.out.println("(l2 == l1)? " + (l2 == l1));
        System.out.println("l2.get(0)==l1.get(0)? " + (l2.get(0)==l1.get(0)));
        System.out.println("l2.get(1)==l1.get(0)? " + (l2.get(1)==l1.get(0)));
        System.out.println("l2.get(2)==l1.get(0)? " + (l2.get(2)==l1.get(0)));
    	System.out.println(l1);
    	System.out.println(l2);
    }

}
```

输出结果：

```java
(l2 == l1)? false
l2.get(0)==l1.get(0)? true
l2.get(1)==l1.get(0)? true
l2.get(2)==l1.get(0)? false
[age: 3]
[age: 3, age: 3, age: 3]
```

可以看到，只有最后一次 `l2.add(l1.get(0).clone());` 的时候做了内存的拷贝，之前的不管是新建 ArrayList 还是 add 元素，链表内部的元素都只是简单拷贝一下引用，指向的内存地址是一模一样的。

好了，既然 clone 方法可以返回新的内存空间，那是不是每次要用到深拷贝的时候就覆写这个方法即可呢？是的，这种做法肯定是有效的，但还要看你覆写的方式对不对。比如上面的例子中，我特意使用了 ArrayList 的 clone 方法，但是原本 `l1` 的元素还是被浅拷贝到 `l2`，虽然 `l1` 和 `l2` 这两个链表的内存不在一块了，但它们内部含有的Person引用却还是指向同一块地址，这就很蛋疼了。我比较好奇为什么内置的数据结构这一点也没做完善，就翻看了一下源码(Android平台的)：

```java
    /**
     * Returns a new {@code ArrayList} with the same elements, the same size and
     * the same capacity as this {@code ArrayList}.
     *
     * @return a shallow copy of this {@code ArrayList}
     * @see java.lang.Cloneable
     */
    @Override public Object clone() {
        try {
            ArrayList<?> result = (ArrayList<?>) super.clone();
            result.array = array.clone();
            return result;
        } catch (CloneNotSupportedException e) {
           throw new AssertionError();
        }
    }
```

人家的说明里面已经很明显地告知这是一个 shallow copy。我看到源码里面对元素数组做了一遍 clone: `result.array = array.clone();`，显然就是这一步导致浅拷贝，于是又上网查了一下 Java 数组的 clone 实现，一句话就让真相大白于天下了：Java 数组的 clone 方法会逐个复制数组内的值。什么意思呢？如果这个数组是基本数据类型的话，就直接复制元素值，由于基本数据类型不是对象，直接赋值就相当于做了“深拷贝”，但如果数组里的元素都是一个个引用呢？也是直接复制这些引用的值，换句话说，数组的 clone 方法就是新建一个数组，然后这个把引用的值拷贝一遍，这样，两个数组内的元素指向的内存地址还是一样的。这就是为什么调用 ArrayList 的 clone 方法是浅拷贝的原因（因为 ArrayList 里面只能存放对象）。就是这个问题坑了我不少时间，毕竟 C++ 每次 push_back 都是深拷贝，我就惯性思维了囧。那我还是想对 ArrayList 做深拷贝怎么办呢？其实方法也很简单很弱智，直接 new 一个新的ArrayList，然后遍历一下，`add(l1.get(i).clone())` 就可以了，注意强制类型转换。

看到这里，如果稍加思考的话会发现一个问题：要想让 `clone` 方法真正实现深拷贝，我们要逐个 clone 对象内部的对象，比方说，如果我有一个 `Company` 类，内部又有一个 `Department` 类，然后内部继续嵌套 `Director` 类、`Employee` 类之类的，那每次覆写 clone 方法的时候，我们都要把内部所有这些类都 clone 一遍，而且一旦添加或删除某个类，还要再修改一遍，简直蛋疼，有没有什么方法可以一键拷贝呢？有的，Java 提供了另一种序列化的方法，让虚拟机自动帮我们做这些繁琐的操作。因为目前项目里不会涉及到这些，所以暂时就不写了，后面的参考链接会详细讲解如何使用。

### 参考：

[Java对象克隆（Clone）及Cloneable接口、Serializable接口的深入探讨](http://blog.csdn.net/kenthong/article/details/5758884)

[Java基础笔记 – 对象的深复制与浅复制 实现Cloneable接口实现深复制 序列化实现深复制](http://www.itzhai.com/java-based-notebook-the-object-of-deep-and-shallow-copy-copy-copy-implement-the-cloneable-interface-serializing-deep-deep-copy.html#read-more)

[java 数组复制:System.arrayCopy 深入解析](http://liliugen.iteye.com/blog/1229603)

[Java 数组 浅拷贝与深拷贝](http://www.cppblog.com/baby-fly/archive/2010/11/16/133763.html)

[How to clone ArrayList and also clone its contents?](http://stackoverflow.com/questions/715650/how-to-clone-arraylist-and-also-clone-its-contents)

