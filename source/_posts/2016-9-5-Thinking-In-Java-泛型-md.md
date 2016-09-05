---
title: 2016-9-5-Thinking-In-Java-泛型.md
date: 2016-09-05 23:24:10
tags: Java
---

刚开始学JavaSe的时候，买了一本业界经典的《Thinking in Java》，后来证明对于初学者来说完全是错误的决定。现在趁着大四有点时间，准备从头将一些重要的知识学一遍。

今天要学的是泛型（文中代码均摘自《Thinking in Java》）。

### 什么是泛型

泛型是Java SE5引入的概念之一。所谓泛型就是指 “适用于许许多多的类型”，即让程序自己去识别参数类型，而不是事先就将类型信息写死在代码中。Java SE5之前是没法使用泛型的，这给Java泛型的设计添加了很多麻烦。

### 与C++的比较

书里关于泛型的介绍涵盖了整整一章，而且几乎是书里最厚的一章。初学时的我靠着一点C++模板的基础，学了点语法糖就混过去了。然而事实上Java的泛型远不如C++灵活，有点类似补丁的作用。

C++泛型的代码一般是这样的：

```c++
#include <iostream>
using namespace std;

template<class T>
class Manipulator {
	T obj;
public:
	Manipulator(T x) {
		obj = x;
	}
	void manipulate() {
		obj.f();
	}
};

class HasF {
public:
	void f() {
		cout << "HasF::f()" << endl;
	}
};

int main() {
	HasF hf;
	Manipulator<HasF> manipulator(hf);
	manipulator.manipulate();
}
```

结果会输出：HasF::f()

但如果同样翻译成Java版的：

```java
class Manipulator<T> {
	private T obj;
	public Manipulator(T x) {
		obj = x;
	}
	public void manipulate() {
		obj.f();
	}
}

class HasF {
    public void f() {
        System.out.println("HasF.f()");
    }
};

public class Manipulation {
	public static void main(String[] args) {
		HasF hf = new HasF();
		Manipulator<HasF> manipulator = new Manipulator<HasF>(hf);
		Manipulator.manipulate();
	}
}
```

编译器却会报错：Error: cannot find symbol: method f()

为什么C++里的泛型T可以找到f方法呢？很简单，当你实例化这个模板时，C++编译器会进行检查，因此在Manipulator\<HasF\>被实例化时，它检查到HasF存在一个f方法，所以编译通过，否则会报错。但Java的编译器却走了相反的道路：它干脆将类型信息“擦除”了。在Java的编译器看来，Manipulator\<T\>中的T都被默认当作Object类型，因此找不到f方法。因此，为了实现上面的功能，我们要给定泛型的边界，以此告知编译器只能接受遵循这个边界的类型。具体做法是使用 `extends` 关键字，将上面代码中的\<T\>改为\<T extends HasF\>。这样编译器知道T必须是HasF或其子类，因此可以调用f方法。

但聪明的读者很快会发现这种做法完全可以这样实现：

```java
class Manipulator3 {
	private HasF obj;
	public Manipulator3(HasF x) {
		obj = x;
	}
	public void manipulate() {
		obj.f();
	}
}
```

这样泛型还有什么卵用呢？

Bruce在书中说了这样一段话：只有当你希望使用的类型参数比某个具体类型（以及它的所有子类型）更加“泛化”时——也就是说，当你希望代码能够跨多个类工作时，使用泛型才有所帮助。

而事实上，以我浅薄的见识，泛型的主要作用是可以利用编译器来检查类型。例如：ArrayList\<String\>总比ArrayList\<Object\>的作用要强些吧，至少当你传入非String类型（包括String的子类）的对象时，前者能够报错。

### “擦除”的来历

所谓“擦除”，我的理解是：在编译期间，Java的编译器不会像C++的编译器一样去将类型参数T实例化。为什么Java要提供这种看似鸡肋的泛型呢？根本原因在于Java从诞生之初就没考虑过引入泛型功能。因此，JavaSE5之前的类库都不具有泛型功能。为了能够兼容之前的类库，不得不弱化泛型的能力。总之，这是为了减少bug出现而提出的折中方案。

### “擦除”的问题

因为“擦除”抹去了所有类型信息，所以转型、instanceof操作都无法使用了。对于这样的代码：

```java
class Foo<T> {
    T var;
}

Foo<Cat> f = new Foo<Cat>();
```

我们还要时刻牢记：在编译器看来，你的Cat都是Object类型的，除非你使用 `extends`。





“根据我的经验，理解了边界所在，你才能成为程序高手。因为只有知道了某个技术不能做到什么，你才能更好地做到所能做的（部分原因是，不必浪费时间在死胡同里乱转）”

 ——Bruce Eckel