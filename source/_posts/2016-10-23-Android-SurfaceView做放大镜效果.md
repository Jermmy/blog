---
title: Android：在SurfaceView上做放大镜效果
date: 2016-10-23 21:40:17
tags: [Android, SurfaceView]
categories: Android
---

一开始遇到这个需求的时候，觉得应该是一个再普通不过的功能，于是上网查了下怎么实现放大镜效果。果不其然，很快就google出一堆如何在`ImageView`或者其他`View`上实现放大镜的方法，但当我把同样的思路用在`SurfaceView`上时，却遇到一个极坑的问题。于是特意写这篇文章记录实现的思路。

简单起见，我们要实现的是下图展示的功能，当手指触及SurfaceView时，放大手指所指的位置，放大镜出现在手指左上方。

  ![ezgif.com-video-to-gif](/images/2016-10-23/ezgif.com-video-to-gif.gif)

#### 预备知识

1. Android canvas基本用法，推荐这篇文章：

   http://blog.csdn.net/harvic880925/article/details/39080931

2. SurfaceView的初级使用

<!--more-->

<br\>

#### 普通View的实现思路

`SurfaceView`放大镜的实现思路和普通`View`基本一样，所以有必要了解普通`View`的放大镜如何实现。

其实归根到底是`Canvas`的作用。

思路是这样的：当用户手指触碰到View时，捕获指尖位置(`onTouch()`方法)，然后用`Canvas`在该位置左上角裁减出一个圆形区域作为放大镜的位置，在该位置画出放大后的图片。当用户移动手指时，就不断刷新`View`（通过`invalidate()`方法调用`onDraw()`），这样就实现了放大镜效果。

接下来细化每一个细节问题。

1. 如何裁出那个圆？

   `Canvas`表示一个图层，在这个图层上可以进行任意的平移旋转等操作，同时可以通过`clipXXX()`等方面裁减这个图层。因此，我们可以事先定义好一个圆形的`Path`，并通过`clipPath()`方法在指尖左上角的位置裁出一个圆形区域。

   当然，在这之前，你要把`Canvas`移动到裁减的位置。`Canvas`的操作默认都是以(0,0)坐标为起点执行的，对应到手机UI的坐标系，也就是屏幕左上角。而移动的操作可以通过`translate()`函数来完成。

   为了方便理解，我简陋地做了几张图：

    ![屏幕快照 2016-10-24 上午10.29.35](/images/2016-10-23/屏幕快照 2016-10-24 上午10.29.35.png)

   假设上图中，绿色部分代表`View`，图中那个红点是用户指尖的位置。

   接下来，我们要平移`Canvas`到合适的位置，并裁剪出放大镜的区域。

      ![屏幕快照 2016-10-24 上午10.33.27](/images/2016-10-23/屏幕快照 2016-10-24 上午10.33.27.png)

   上面这张图，假设带虚线的绿色框是移动后的`Canvas`，至于为什么要移动到这个位置，跟我的`Path`的设置有关：

   ```java
   mPath = new Path();
   mPath.addCircle(RADIUS, RADIUS, RADIUS, Path.Direction.CW);
   ```

   如果以（0，0）点作为标准，这个`Path`会以（RADIUS，RADIUS）这个点为圆心，以RADIUS为半径形成一个圆。因此，如果`Canvas`移动到上图的位置，`Path`对应的就是那个蓝色圆的位置。

   接下来，用`Canvas`裁剪出这个`Path`，

   ```java
   canvas.clipPath(mPath);
   ```

   这个时候，`Canvas`会在图层上裁出图中那个蓝色圆。也就是说，下次做画的时候，只有那个蓝色圆的位置会被绘制。

2. 如何制作放大效果？

   这一步使用了`Matrix`的作用。简单来讲，只要我们将`Bitmap`绘制成n倍大小，同时保证蓝色圆的圆心与红点对应原`Bitmap`同一位置即可。后一步保证放大的区域确实是手指触碰的区域。

   简单起见，这里以放大两倍为例。

   假设`Canvas`仍然在（0，0）位置，那么放大两倍后的`Canvas`就如下面的蓝色区域所示，注意原来的红点坐标也被放大了：

     ![屏幕快照 2016-10-24 上午10.52.59](/images/2016-10-23/屏幕快照 2016-10-24 上午10.52.59.png)

   需要注意的是，裁减出来的那个蓝色圆是不会动的（我觉得这个API的设计有点奇怪）。

   接下来要做的就是让蓝色区域的红点和蓝色圆的圆心重合，这样当`Canvas`绘制放大两倍的`Bitmap`的时候，就相当于把指尖位置的区域放大后，再画到蓝色圆的区域，也就是放大镜的效果。

   移动的操作其实很简单，按照上图的标示，横坐标要左移`x+RADIUS`，纵坐标上移`y+RADIUS`，换成向量表示就是`translate(-x-RADIUS, -y-RADIUS)`。

   但要注意，我们之前已经平移过`Canvas`了，所以要把之前平移的距离算上（如下图所示）

    ![屏幕快照 2016-10-24 上午11.05.18](/images/2016-10-23/屏幕快照 2016-10-24 上午11.05.18.png)

   所以最后总的平移向量为：`translate(-2*x+RADIUS, -2*y+RADIUS)`。

   `onDraw()`函数如下：

   ```java
       protected void onDraw(Canvas canvas) {
         canvas.drawBitmap(bitmap, matrix, null);

         if (isTouching) {
           // 剪切出放大区域
           canvas.translate(mX - 2 * RADIUS, mY - 2 * RADIUS);
           canvas.clipPath(mPath);
           // 画放大后的图
           canvas.translate(RADIUS - mX * 2, RADIUS - mY * 2);
           canvas.drawBitmap(bitmap, scaleMatrix, null);
         }
       }
   ```

   <br\>

   #### `SurfaceView`的放大镜实现

   完成了普通`View`的放大镜效果后，`SurfaceView`照理来说应该也就不是问题，毕竟`SurfaceView`也是`View`的子类。但真正实现的时候，却遇到一个很大的问题。

   仔细观察上面`onDraw()`的代码，可以发现，放大效果最终是通过`Matrix`将`Bitmap`放大后再重绘一遍。但应用到`SurfaceView`时，我发现根本无法拿到`SurfaceView`的`Bitmap`。后来查了各种资料，发现大家普遍遇到这个问题，有人甚至通过Linux底层的驱动来获取这个`SurfaceView`的Frame，不过这要在手机root的前提下实现。后来我尝试通过截屏的思路获取`SurfaceView`的截图，却发现截图是一片漆黑。导致该问题的根本原因在于`SurfaceView`的实现机制与普通的`View`完全是两码事。于是，只能另辟蹊径去获得这个`Bitmap`。思路其实也很简单，我们自己实例化一个`Canvas`和`Bitmap`，将`SurfaceView`上绘制的结果重新画一遍，这样就相当于间接获得了`SurfaceView`的`Bitmap`，绘制函数的代码如下：

   ```java
       private void draw() {
           try {
               Canvas canvas = surfaceHolder.lockCanvas();
               // 画一层底色,防止SurfaceView闪烁
               canvas.drawColor(Color.BLACK);

               if (bitmap != null) {
                   canvas.drawBitmap(bitmap, matrix, null);
               }
               if (isTouching) {
                  // 将SurfaceView上的结果在自己的Bitmap上重新画一遍
                  drawSurfaceToBitmap();

                  // 剪切出放大区域
                  canvas.translate(mX - 2 * RADIUS, mY - 2 * RADIUS);
                  canvas.clipPath(mPath);
                  // 画放大后的图
                  canvas.translate(RADIUS - mX * 2, RADIUS - mY * 2);
                  // magBitmap是我们自己的Bitmap
                  canvas.drawBitmap(magBitmap, magMatrix, null);
              }

              surfaceHolder.unlockCanvasAndPost(canvas);

          } catch (NullPointerException e) {
              e.printStackTrace();
          }
      }
   ```


当然，由于这个例子里绘制的图片是一张静态的背景图，所以可以直接使用这张背景图的`Bitmap`，但如果绘制的是一张动图，就只能将所有绘制的操作重新画在自己的`Bitmap`上了。

   另外，如果`SurfaceView`的绘制流程过于复杂，可能会导致不流畅（毕竟画了两次），需要使用多线程来执行`draw()`函数，这应该也是使用`SurfaceView`的正确姿势。


<br\>

#### 参考

[Android放大镜的实现](http://chroya.iteye.com/blog/924577)

[自定义控件之绘图篇（四）：canvas变换与操作](http://blog.csdn.net/harvic880925/article/details/39080931)

[setScale,preScale和postScale的区别](http://www.eoeandroid.com/blog-659748-5465.html)