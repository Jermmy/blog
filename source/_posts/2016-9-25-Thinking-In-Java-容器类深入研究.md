---
title: Thinking in Java — 容器类深入研究
date: 2016-09-25 10:22:52
tags: [Java, 容器]
categories: Java
---

容器已经是现代编程语言必备的组件了。（注：由于一些常用容器的使用已经非常熟悉，因此本文着眼于我不熟悉的容器）

### 完整的容器分类法

下面这张图摘自《Thinking in Java》，是Java中容器类很好的概览图

![full_container_taxonomy_thinking_in_java](images/2016-9-25/full_container_taxonomy_thinking_in_java.png)

<!--more-->

Java SE5中新添加的接口有：

+ `Queue`接口及其实现`PriorityQueue`和各种风格的`BlockingQueue`；
+ `ConcurrentMap`接口及其实现`ConcurrentHashMap`（用于多线程）；
+ `CopyOnWriteArrayList`和`CopyOnWriteArraySet`，它们也是用于多线程机制的；
+ `EnumSet`和`EnumMap`，为使用`enum`而设计的`Set`和`Map`的特殊实现；
+ 在`Collections`类中的多个便利方法。

<br\>

### Set和存储顺序

#### HashSet, TreeSet, LinkedHashSet

`Set`是一种集合类，它需要一种方式来维护存储顺序。不同的Set实现类具有不同的存储行为，通常我们使用内置数据类型（如：`String`）的时候不需要考虑存储顺序，因为这些数据类型已经被设计为可以在容器内部使用。但如果是使用我们自定义的数据类型，就有必要了解一些内部机制了。

| 类型            | 说明                                       |
| ------------- | ---------------------------------------- |
| Set           | 存入`Set`的每个元素都必须是唯一的，因为`Set`不保存重复元素。加入`Set`的元素必须定义`equals()`方法以确保对象的唯一性。`Set`和`Collection`有完全一样的接口。Set接口不保证维护元素的次序。 |
| HashSet       | 为快速查找而设计的`Set`。存入`HashSet`的元素必须定义`hashCode()` |
| TreeSet       | 保持次序的`Set`，底层为树结构。使用它可以从`Set`中提取有序的序列。元素必须实现`Comparable`接口 |
| LinkedHashSet | 具有`HashSet`的查询速度，且内部使用链表维护元素的顺序（插入的次序）。于是在使用迭代器遍历`Set`时，结果会按元素插入的次序显示。元素也必须定义`hashCode()`方法 |

（作者推荐，如果没有其他限制，默认使用`HashSet`）

必须为散列存储和树形存储创建一个 `equals()`方法，但是`hashCode()`只有在这个类将会被置于`HashSet`或者`LinkedHashSet`时才是必须的。好的编程习惯是：在覆盖`equals()`方法时，同时覆盖`hashCode()`。

看一个例子：

```java
import java.util.*;

class SetType {
	int i;
	public SetType(int n) { i = n; }
	public boolean equals(Object o) {
		return o instanceof SetType && (i == ((SetType)o).i);
	}
	public String toString() { return Integer.toString(i); }
}

class HashType extends SetType {
	public HashType(int n) { super(n); }
	public int hashCode() { return i; }
}

class TreeType extends SetType implements Comparable<TreeType> {
	public TreeType(int n) { super(n); }
	public int compareTo(TreeType arg) {
		return (arg.i < i ? -1 : (arg.i == i ? 0 : 1));
	}
}

public class TypesForSets {
	static <T> Set<T> fill(Set<T> set, Class<T> type) {
		try {
			for (int i = 0; i < 10; i++) {
				set.add(type.getConstructor(int.class).newInstance(i));
			}
		} catch(Exception e) {
			throw new RuntimeException(e);
		}
		return set;
	}
	static <T> void test(Set<T> set, Class<T> type) {
		fill(set, type);
		fill(set, type);   // Try to add duplicates
		fill(set, type);
		System.out.println(set);
	}
	public static void main(String[] args) {
		test(new HashSet<HashType>(), HashType.class);
		test(new LinkedHashSet<HashType>(), HashType.class);
		test(new TreeSet<TreeType>(), TreeType.class);
		// Things that don't work:
		test(new HashSet<SetType>(), SetType.class);
		test(new HashSet<TreeType>(), TreeType.class);
		test(new LinkedHashSet<SetType>(), SetType.class);
		test(new LinkedHashSet<TreeType>(), TreeType.class);
		try {
			test(new TreeSet<SetType>(), SetType.class);
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}
		try {
			test(new TreeSet<HashType>(), HashType.class);
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}
	}
}
```

输出：

```shell
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
[9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
[5, 8, 1, 7, 3, 7, 9, 1, 9, 6, 7, 8, 4, 0, 3, 4, 9, 3, 2, 0, 5, 2, 1, 6, 6, 5, 4, 2, 8, 0]
[6, 1, 7, 8, 0, 6, 3, 0, 9, 1, 2, 8, 0, 7, 2, 9, 7, 4, 5, 5, 2, 9, 1, 6, 4, 3, 5, 3, 4, 8]
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
java.lang.ClassCastException: SetType cannot be cast to java.lang.Comparable
java.lang.ClassCastException: HashType cannot be cast to java.lang.Comparable
```

这个例子分别演示了`HashSet`、`LinkedHashSet`、`TreeSet`的用法。`test()`函数会往集合`Set`中放入相同的元素（通过三个`fill()`），通过不同的`SetType`可以看到：`HashSet`、`LinkedHashSet`会根据`hashCode()`保持元素的唯一性（注意`SetType`、`TreeType`由于没有覆写`hashCode()`函数，所以使用了默认的hashCode()方法，导致每个元素的hash结果都不一样），`TreeSet`则根据`Comparable`接口判断元素的唯一性。

#### SortedSet

`SortedSet`是一个接口定义，它保证内部的元素处于排序状态。

例子：

```java
import java.util.*;

public class SortedSetDemo {
	public static void main(String[] args) {
		SortedSet<String> sortedSet = new TreeSet<String>();
		Collections.addAll(sortedSet, "one two three four five six seven eight".split(" "));
		System.out.println(sortedSet);
		String low = sortedSet.first();
		String high = sortedSet.last();
		System.out.println(low);
		System.out.println(high);
		Iterator<String> it = sortedSet.iterator();
		for (int i = 0; i <= 6; i++) {
			if (i == 3) low = it.next();
			if (i == 6) high = it.next();
			else it.next();
		}
		System.out.println(low);
		System.out.println(high);
		System.out.println(sortedSet.subSet(low, high));
		System.out.println(sortedSet.headSet(high));
		System.out.println(sortedSet.tailSet(low));
	}
}
```

输出：

```shell
[eight, five, four, one, seven, six, three, two]
eight
two
one
two
[one, seven, six, three]
[eight, five, four, one, seven, six, three]
[one, seven, six, three, two]
```

这里记住`SortedSet`的几个接口：

`Object first()` 返回容器中的第一个元素；

`Object last()` 返回容器中的最末一个元素；

`SortedSet subSet(fromElement, toElement)` 生成Set的子集，范围从fromElement（包含）到toElement（不包含）；

`SortedSet headSet(toElement)` 生成此Set的子集，由小于toElement的元素组成；

`SortedSet tailSet(fromElement)` 生成此Set的子集，由大于或等于fromElement的元素组成。 

<br\>

### 队列

除了并发应用，`Queue`在Java SE5中仅有的两个实现是`LinkedList`和`PriorityQueue`，它们的差异在于排序行为而不是性能。

#### 优先级队列

`PriorityQueue`的使用：

```java
import java.util.*;

public class ToDoList extends PriorityQueue<ToDoList.ToDoItem> {
	static class ToDoItem implements Comparable<ToDoItem> {
		private char primary;
		private int secondary;
		private String item;
		public ToDoItem(String td, char pri, int sec) {
			primary = pri;
			secondary = sec;
			item = td;
		}
		public int compareTo(ToDoItem arg) {
			if (primary > arg.primary) return 1;
			if (primary == arg.primary)
				if (secondary > arg.secondary)
					return 1;
				else if (secondary == arg.secondary)
					return 0;
			return -1;
		}
		public String toString() {
			return Character.toString(primary) + secondary + ": " + item;
		}
	}
	public void add(String td, char pri, int sec) {
		super.add(new ToDoItem(td, pri, sec));
	}
	public static void main(String[] args) {
		ToDoList toDoList = new ToDoList();
		toDoList.add("Empty trash", 'C', 4);
		toDoList.add("Feed dog", 'A', 2);
		toDoList.add("Feed bird", 'B', 7);
		toDoList.add("Mow lawn", 'C', 3);
		toDoList.add("Water lawn", 'A', 1);
		toDoList.add("Feed cat", 'B', 1);
		while (!toDoList.isEmpty()) {
			System.out.println(toDoList.remove());
		}
	}
}
```

输出：

```shell
A1: Water lawn
A2: Feed dog
B1: Feed cat
B7: Feed bird
C3: Mow lawn
C4: Empty trash
```

<br\>

### 理解Map

#### Map 的基本实现

| 类型                | 说明                                       |
| ----------------- | ---------------------------------------- |
| HashMap           | Map基于散列表的实现（它取代了`Hashtable`）。插入和查询“键值对”的开销是固定的。可以通过构造器设置容量和负载因子，以调整容器的性能。 |
| LinkedHashMap     | 类似于`HashMap`，但是迭代遍历它时，取得“键值对”的顺序是其插入次序，或者是最近最少使用（LRU）的次序。只比`HashMap`慢一点；而在迭代访问时反而更快，因为它使用链表维护内部次序。 |
| TreeMap           | 基于红黑树的实现。查看“键”或“键值对”时，它们会被排序（次序由`Comparable`或`Comparator`决定）。TreeMap的特点在于，所得到的结果是经过排序的。`TreeMap`是唯一的带有`subMap()`方法的Map，它可以返回一个子树。 |
| WeakHashMap       | 弱键（weak kay）映射，允许释放映射所指向的对象；这是为解决某类特殊问题而设计的。如果映射之外没有引用指向某个“键”，则此“键”可以被垃圾收集器回收。 |
| ConcurrentHashMap | 一种线程安全的Map，它不涉及同步加锁，效率更高。                |
| IdentifyHashMap   | 使用==代替equals()对“键”进行比较的散列映射。专为解决特殊问题而设计的。 |

之前讲`Set` 的时候说过，一般情况下，`HashSet`的效率是最高的。Map也不例外，`HashMap`应该是开发者首选。因为`HashMap`内部使用散列码提高了搜索速度。散列的速度远高于线性搜索，甚至树结构的搜索。

由于`Map`的使用与`Set`基本一样，这里便不再举例说明。

#### SortedMap

与`SortedSet`一样，`SortedMap`是一个接口定义，其唯一的实现类（Java SE5）是`TreeMap`，插入`SortedMap`的键必须实现`Comparable`接口。

#### LinkedHashMap

为了提高访问速度，`LinkedHashMap`散列化所有的元素，但是在遍历键值对时，却以元素的插入顺序返回键值对。此外，可以在构造器中设定`LinkedHashMap`，使之采用基于访问的最近最少使用算法。

<br\>

### 散列与散列码

#### HashMap底层原理

如果使用自定义的类作为`HashMap`，那么这个类必须覆写`equals()`和`hashCode()`方法。理由是：`HashMap`是一种拉链式的哈希数组，类似于数据库中静态哈希存储结构。在`HashMap`中会有一个类似`list[]`的数组，Key的`hashCode()`用来计算这个Key对应数组哪个位置，之后再将对应的Value插入到这个位置的`list`后面，为了判断这个Key是否已经存在，`HashMap`又会调用Key的`equals()`函数对list做一次线性扫描（可能会有优化），只有不存在这个Key时才将Value插入list。

基于以上原理，`hashCode()`的结果可以相同，但`equals()`的结果一定要有所区分！

#### 覆盖hashCode()

设计hash函数要避开几个雷区：

1. hashCode不能依赖于对象中易变的数据，这样，可能业务逻辑上原本相同的对象，get和put的位置不同；
2. hashCode不能依赖于具有唯一性的对象信息，尤其是this，这样逻辑上相同的两个实例对象会产生不同的hashCode



















