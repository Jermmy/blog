---
title: Leetcode题解：98. validate binary search tree
date: 2018-02-09 08:54:35
tags: leetcode, 树
categories: 算法
---

## 题目

[原题](https://leetcode.com/problems/validate-binary-search-tree/description/)：Given a binary tree, determine if it is a valid binary search tree (BST).

Assume a BST is defined as follows:

- The left subtree of a node contains only nodes with keys **less than** the node's key.
- The right subtree of a node contains only nodes with keys **greater than** the node's key.
- Both the left and right subtrees must also be binary search trees.

**Example 1:**

```
    2
   / \
  1   3
```

Binary tree `[2,1,3]`, return true.

**Example 2:**

```
    1
   / \
  2   3
```

Binary tree `[1,2,3]`, return false.

<!--more-->

## 要求

这道题的要求是验证一棵树是否是二叉搜索树，难度中等。其实这应该是一道二叉树相关的基础题。

在寻找思路之前，我们应该明确二叉搜索树的定义：

1. 一个节点的左子树的所有节点都小于（不能**等于**）该节点的值；
2. 一个节点的右子树的所有节点都大于（不能**等于**）该节点的值；
3. 左右子树也必须是二叉搜索树。

## 思路

### 方法一

根据二叉搜索树的定义，很容易想到一种简单粗暴的方法：对于每一个节点，我们可以计算其左子树的最大值，判断这个最大值是否比当前节点值小，并计算右子树的最小值，判断最小值是否比当前节点大。只要这两点均满足，这棵树肯定是一棵二叉搜索树。

```c++
struct TreeNode {
  int val;
  TreeNode *left;
  TreeNode *right;
  TreeNode(int x) : val(x), left(NULL), right(NULL) {}
};

class Solution {
public:
    bool isValidBST(TreeNode* root) {
        if (root == NULL) return true;
        if (root->left != NULL && maxValue(root->left) >= root->val) return false;
        if (root->right != NULL && minValue(root->right) <= root->val) return false;
        return isValidBST(root->left) && isValidBST(root->right);
    }
private:
	int minValue(TreeNode* root) {
		TreeNode* cur = root;
		while (cur->left != NULL) {
			cur = cur->left;
		}
		return cur->val;
	}
	int maxValue(TreeNode* root) {
		TreeNode* cur = root;
		while (cur->right != NULL) {
			cur = cur->right;
		}
		return cur->val;
	}
};
```

### 方法二

在写这篇博文的时候，方法一是可以通过 leetcode 测试样例的，这多少出乎我的意料。因为方法一其实效率很低，对于树中的每个节点，我们都需要不断的计算左右子树的最大最小值，这里面存在很多重复计算的地方，不过从方法一可以 AC 这一点，也说明 leetcode 的测试样例是比较简单的。

方法二的目的就是为了克服方法一重复计算的毛病。在方法一中，我们每次计算左右子树的最大最小值，其实是为了给出当前节点值的边界，如果当前节点值在这个最大最小值之间，那这个节点是符合条件的。方法二沿用同样的思路，只不过在计算最大最小值的时候，我们不必再遍历左右子树，而是根据**当前节点值是左子树的最大值，且是右子树的最小值**这一原则，在每次递归调用的时候记录跟踪这个最大最小值。

```c++
class Solution {
public:
    bool isValidBST(TreeNode* root) {
        return _isValidBST(root, INT_MIN, INT_MAX);
    }
private:
	bool _isValidBST(TreeNode* root, int min, int max) {
		if (root == NULL) return true;
		if (root->val <= min || root->val >= max)
			return false;
		return _isValidBST(root->left, min, root->val) && _isValidBST(root->right, root->val, max);
	}
```

当二叉树比较大时，这种方法的效率比前一种要高。

遗憾的是，方法二现在已经通不过 leetcode 的测试样例了。当节点值刚好是最小值 `INT_MIN` 或最大值 `INT_MAX` 时，上面的方法就会出 bug。虽然我们可以把 `int` 类型改为 `long` 来避免这种 bug，不过，这种方法换汤不换药，没法根治问题，这才有了第三种方法。

### 方法三

相比方法二而言，方法三和方法一更相似。这一次，我们放弃使用 `min` 和 `max` 跟踪上下边界的做法，而是继续计算左右子树的最大最小值来判断。不过，我们不必用遍历的方法来计算，而是沿用方法二的思路，在每次递归调用时，记录一个**最大节点**和**最小节点**。效率上跟方法二一样，只是这一次我们是用树中的节点来确定一个最大最小边界，而不是借助一个外部设定的 `INT_MIN` 和 `INT_MAX`，因此可以避免边界检查的问题。

```c++
class Solution {
public:
    bool isValidBST(TreeNode* root) {
        return _isValidBST(root, NULL, NULL);
    }
private:
	bool _isValidBST(TreeNode* root, TreeNode* min, TreeNode* max) {
		if (root == NULL) return true;
		if (min != NULL && root->val <= min->val) return false;
		if (max != NULL && root->val >= max->val) return false;
		return _isValidBST(root->left, min, root) && _isValidBST(root->right, root, max);
	}

};
```

## 参考

+ [Leetcode Validate Binary Search Tree](http://wenzhiquan.github.io/2016/07/05/leetcode_98_medium_valid_binary_search_tree/)

