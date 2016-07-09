---
layout: post
title: Android-GridView设置选中状态
tags: Android
---

### Mark一个今天被坑了很久的小问题

#### 需求

实现脸萌的创作界面（如下）

 ![Screenshot_2016-06-28-09-37-07](/images/2016-6-29/Screenshot_2016-06-28-09-37-07.jpeg)

而工作重点是实现底下的格子页面，有选中效果，格子间有间隔线。

#### 方法

由于顶部的滑动条和底部的格子界面需要同步滑动，决定采用第三库[ViewPagerIndicator](https://github.com/LuckyJayce/ViewPagerIndicator)，底部自然是用ViewPager嵌套Fragment，Fragment的主要内容是格子页面。格子页面用GridView实现(不想用最新的RecyclerView，因为对Item点击事件的支持不好)。

#### 难点

仔细观察GridView的Item，发现其由一张图片、间隔线以及选中时的提示框组成。因此我用如下的布局文件实现(注意GridView的Item中最好不要放Button之类的，否则GridView的Item点击事件拿不到)：

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

        <ImageView
            android:id="@+id/image"
            android:layout_centerInParent="true"
            android:layout_width="match_parent"
            android:layout_height="match_parent" />

</LinearLayout>
```

`ImageView`主要放图片(ImageResource)和边框间隔线(BackgroundResource)，选中效果我一开始是用`GridView`的listSelector属性来做，然而此处遇到第一个坑，见下图：

 ![屏幕快照 2016-06-29 下午6.56.28]({{ site.baseurl }}/images/2016-6-29/屏幕快照 2016-06-29 下午6.56.28.png)

 ![屏幕快照 2016-06-29 下午6.56.52]({{ site.baseurl }}/images/2016-6-29/屏幕快照 2016-06-29 下午6.56.52.png)

在快速滚动GridView的时候，选中框出现滚动bug，找了好多资料，貌似没人遇到这种问题，只能作罢(另外，我在写selector文件的时候发现，当我把`state_selected`设为false时，GridView的表现反而是选中状态，不明所以)。我又上网查了其他方案，结果都是些怎么改变listSelector样式啊之类的。还有一些是建议在Item最外层的`LinearLayout`上加selector，然后在GridView的ItemClickListener中设置监听手动更换背景。我想，如果listSelector的思路不行的话，这个方法应该是唯一的解决方案了。于是，我将`LinearLayout`的background设为selector，然后在OnItemClickListener中手动设置，大致代码如下：

```java
gridView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
  @Override
  public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
    view.setSelected(position);
  }
});
```

然而这样做，虽然点击的时候会出现选中框，但滑动GridView，再滑回去时，选中框消失了。后来又试了在Adapter的getView方法中设置，都没什么效果。之后，我突然想起以前用ListView的时候，曾经踩过CheckBox的选中状态因为滚动而重置的情况，于是我猜测选中框的消失可能和适配器中View的重用有关。所以，干脆另辟蹊径，用一个boolean数组记录每个Item的选中状态，然后每次调用getView函数时，根据数组刷新Item，也就是放弃GridView中的setSelection方法，手动更换背景。于是得到最终的代码：

```java
gridView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
  @Override
  public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
    adapter.setSelected(position);
  }
});
```

以下是Adapter的部分代码:

```java
class GridAdapter extends BaseAdapter {

  Context mContext;
  ArrayList<Integer> icons;
  LayoutInflater inflater;
  boolean isSelected[];

  GridAdapter(Context context, ArrayList<Integer> icons) {
    this.mContext = context;
    this.icons = icons;
    this.inflater = LayoutInflater.from(mContext);
    this.isSelected = new boolean[icons.size()];
    for (int i = 0; i < icons.size(); i++) {
      isSelected[i] = false;
    }
    this.isSelected[0] = true;
  }

  @Override
  public View getView(int position, View convertView, ViewGroup parent) {
    if (convertView == null) {
      convertView = inflater.inflate(R.layout.item_gridview_edit, null, false);
      ImageView image = (ImageView) convertView.findViewById(R.id.image);
      image.setImageResource(icons.get(position));
      image.setBackgroundResource(R.drawable.shape_item_gridview_border);
    }
    if (isSelected[position]) {                     
      convertView.setBackgroundResource(R.drawable.shape_item_gridview_edit);
    } else {
      convertView.setBackgroundResource(R.color.color_homepage);
    }
    return convertView;
  }

  public void setSelected(int position) {
    for (int i = 0; i < isSelected.length; i++) {
      isSelected[i] = false;
    }
    this.isSelected[position] = true;
    notifyDataSetChanged();
  }

}
```

在OnItemClickListener中修改Adapter的数据并刷新View，在getView中根据boolean数组手动设置背景，结果证明有效。