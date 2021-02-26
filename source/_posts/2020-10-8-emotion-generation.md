---
title: 女朋友让我做一个表情包生成器，然后。。。
date: 2020-10-08 16:55:42
tags: [深度学习]
categories: 深度学习
mathjax: true
---

一个月前，女朋友让我做一个生成表情包的工具，趁着国庆的尾巴搞了一下，一番操作后，终于让懂王喜笑颜开了。

<center>
  <img src="/images/2020-10-8/Trump_1.gif" height="400px">
</center>

<!--more-->

说起表情包生成，我最先想到的便是 2018 年的一篇论文 GANimation。这篇论文的新颖之处在于把表情和脸部肌肉的变化联系在一起。要知道，自从有了 GAN 后，主流研究都是把表情变化当作模态迁移「domain transfer」来研究的，比如比较出名的 StarGAN：

<center>
  <img src="/images/2020-10-8/starGAN.jpg" width="500px">
</center>

所谓模态迁移，就是说我们把人物图片分成不同的数据分布，微笑属于一种数据分布，悲伤属于另一种，然后通过 GAN 网络把一种数据分布转换为另一种，这样就达到表情变换的作用。

不过，我一直认为表情是很难分类的，不同表情之间可以有交集的部分，同一种表情也有强弱之分。而模态迁移把表情固定成了事先设定的几类，这种思路不仅限制了表情的类别，同时也不容易搞清楚模型本身在做什么事情。

而 GANimation 则是把表情变化和脸部肌肉的运动结合在一起，通过控制不同肌肉的变化来实现表情变化。这种方法理论上可以控制生成任意表情，同时，由于我们可以通过控制肌肉变化的力度来控制算法模型，因此也更能搞清楚模型背后的机理。

好了，前面说了这么多废话，那 GANimation 到底是如何实现的呢？要了解这一点，首先需要知道人类是如何控制表情变化的。这个问题并不复杂，早在 1970 年的时候，就有人研究了各式各样的表情，并把它们和特定的肌肉联系在一起，他们把这种肌肉的变化称为 Action Unit「AU」：

<center>
  <img src="/images/2020-10-8/action-unit.jpg" width="700px">
</center>

比如，当你惊恐的时候，你的眉毛就会由中间翘起；当你严肃生气的时候，你的眉毛就会从两边翘起。

把这些 Action Unit 组合起来，就构成了一种种表情。如此一来，就可以通过控制 Action Unit，来达到控制表情的目的。再结合 GAN 的强大之处，就可以灵活地控制每一种表情的变化：

<center>
  <img src="/images/2020-10-8/network.jpg" width="700px">
</center>

当然啦，这个模型本身并没有脱离模态迁移的套路，不过，相比前面的 StarGAN，它可以更连续地控制每一种表情的变化力度，相当于把表情变化这个任务分解得更加精细，因此我个人觉得实用性更好一些。

是骡子是马，还是要拉出来溜溜。这篇论文的作者没有放出他们训练好的模型，不过好在 github 上有一些开源实现，而且效果还不错。我找了完成度最高的[代码](https://github.com/donydchen/ganimation_replicate)，并尝试了一下作者提供的模型，感觉效果还不错。比如拿懂王做的实验：

<center>
  <img src="/images/2020-10-8/trump_good.gif">
</center>

还有安倍酱的效果：

<center>
  <img src="/images/2020-10-8/anbei_good.gif">
</center>

甚至这位：

<center>
  <img src="/images/2020-10-8/monalisa_good.gif">
</center>

当然，也有一些不协调的例子：

<center>
  <img src="/images/2020-10-8/trump_bad.gif">
  <img src="/images/2020-10-8/anbei_bad.gif">
  <img src="/images/2020-10-8/monalisa_bad.gif">
</center>

有些图很明显把胡子也生成出来了，这可能是因为模型是在欧美人的数据集上训练的，而欧美人的胡子普遍较多，导致模型受到数据集的影响产生自己的**偏好**。

另外，懂王的表情看起来也比安倍好一点，除了懂王本人更符合欧美人的特征外，也说明了，有些人天生适合做表情包。

不过，这个模型的效果也只能试试 demo，离真正上线使用还隔着好几个 StyleGAN 的距离。毕竟这是两年前的论文，模型结构也存在欠缺之处。不过这个思路基本是可行的，如果能用一些更先进的技术稍加改进，应该会有更不错的效果。

## 参考

+ [GANimation: Anatomically-aware Facial Animation from a Single Image](https://arxiv.org/abs/1807.09251)

PS: 之后的文章更多的会发布在公众号上，欢迎有兴趣的读者关注我的个人公众号：AI小男孩，扫描下方的二维码即可关注
<center>
  <img src="/images/wechat.jpg" width="500px">
</center>