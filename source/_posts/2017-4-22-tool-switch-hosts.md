---
title: 翻墙神器SwitchHosts
date: 2017-04-22 11:18:55
tags: [工具, TensorFlow]
categories: 工具
---

今天要介绍一个翻墙工具 **SwitchHosts**。

说真的，这个工具我已经听说很久了，但由于我一直都用着 Shadowsocks 纸飞机翻墙，就没怎么理睬它。直到今天，不得不去 TensorFlow 官网查点资料，却发现纸飞机也飞不到那里去，因此尝试了下 **SwitchHosts**，结果真是太感人了。

### SwitchHosts

**SwitchHosts** 的原理其实很简单，就是通过修改 host 文件，指定 IP 地址。只要 GFW 没有对 IP 进行封锁，那么我们就可以直接通过 IP 访问服务器，避开敏感词检测。

**SwitchHosts** 提供多种平台的版本，详情请移步[官网](https://github.com/oldj/SwitchHosts)。

<!--more-->

下面上个结果图，以示喜悦之情。

![switchhosts](/images/2017-4-22/switchhosts.png)

![tensorflow](/images/2017-4-22/tensorflow.png)

有人可能会说，既然 **SwitchHosts**，那还要 Shadowsocks 等付费产品干嘛。其实这是两种不同的翻墙工具。**SwitchHosts** 属于「穿墙」的思路，而 Shadowsocks 则属于借助代理的「翻墙」思路。前者虽然速度更快，但毕竟你没法掌握世界上所有站点的 IP，因此更适合特殊网站的翻墙，比如 TensorFlow 这样的。而且，由于 GFW 会对某些 IP 进行封锁（e.g. Google, Facebook），并不是每个网站都能通过修改 host 穿出去。Shadowsocks 是通过加密混淆来防止被 GFW 识别，虽然速度上偏慢，但对大多数网站适用。因此，两者相互结合，才是翻墙的最佳姿势。

### 参考

+ [SwitchHosts官网](https://github.com/oldj/SwitchHosts)
+ [目前热门科学上网方式介绍及优缺点简评](https://cokebar.info/archives/236)

