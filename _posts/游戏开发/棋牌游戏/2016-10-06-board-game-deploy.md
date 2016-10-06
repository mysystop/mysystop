---
layout: post
title: 棋牌游戏服务器架构:部署
categories: 游戏开发
description: 棋牌游戏服务器架构:部署
keywords: 游戏设计,棋牌游戏,部署
---


      先看一下，下面这张可能的部署图吧。

![](http://pic002.cnblogs.com/images/2012/151655/2012091600092037.jpg)

图1  系统布署图

      在这个图中，可以看到，客户端的形式多种多样，可能是pc上的一个可执行文件，也可能是通过浏览器打开的一个网页，甚至于手机客户端。它们都通过internet连接到游戏服务器。

      在这个部署中有1个CenterServer,1个LogServer,3个LogonServer和很多个RoomServer(只显示了德州扑克的两个房间)。这些Server有可能分布在同一台机器上，也可以分布在不同的机器之上。这对扩容来说是极为方便地。在玩家数量增大，系统不足以承载其网络负载时，只需要买更多的机器，架设更多的RoomServer或者LogonServer就行了。

     这里再分析一下一个中心服务器最多可支持多少玩家同时在线。假定1台机器最多可以有5000个连接，也就是说我给可买5000个机器作为LogServer + RoomServer, LogServer的数目不会太多，可以忽略，所以最多有RoomServer可以管理最多5000X5000个用户同时在线。

## 1布署数据库

      选定作为数据库服务器的机器以后，要先安装postgresql数据库，然后导入ServerInfoDB(CenterServer使用), UserInfoDB(LogonServer、RoomServer、LogServer使用),UserScoreDB(RoomServer使用)，还有有关各个游戏逻辑的数据库，比如TexasPokerDB等等。这些数据库不一定要放在一台机器上，可以布置在不同的机器上，因为本架构是支持分布式数据库的，你只要记住每个数据库所在机器的

## 2启动服务器

### 2.1 启动CenterServer

      首先要修改中心服务器配置，主要包括两个方面的配置：­网络配置和数据库配置。

      网络配置包括: 监听端口、最大连接数。这里的最连接数它的是最多支持多少个LogonServer + RoomServer。因为只有这两种Server会连接CenterServer。

      数据库配置包括：ServerInfoDB所在机器的IP地址，端口号，连接要用的用户名和密码

      配置好以后，就可以直接启动中心服务器了，中心服务器会根据这些配置信息来管理游戏列表，房间列表等信息。

###  2.2 启动LogonServer

      第一步也是配置服务器，主要的配置信息为:

      网络配置: 监听端口和最大连接数。　这里的最连接数控制这个LogonServer最多同时支持多少人同时登录。

      数据库配置:主要是配置UserInfoDB的地址，端口连接所用的用户名和密码。

      CenterServer相关配置: 主要有中心服务器所在IP,端口。需要CenterServer的相关信息是因为LogonServer会定时地从CenterServer中更新游戏列表和房间信息。

      配置好以后就可以启动LogonServer了。

### 2.3 启动LogServer

      这个服务器做的工作比较简单，就是处理玩家的查看游戏过程用的。主要有以下配置项:

      网络配置: 监听端口和最大连接数。　

      数据库配置: GameLogDB所在的IP,端口，连接所用的用户名和密码

      配置好以后启动即可。

### 2.4 配置RoomServer

      玩家的大部分操作都是由这种服务器来响应，启动一个RoomServer实例相当于开启一个新的房间，所以要扩容，基本上只需要增加机器并开启更多的RoomServer即可,其配置包括:

      房间基本信息: 房间类型(vip房间，比赛房间，普通房间等), 桌子数，每个桌子的椅子数等等。

      网络配置: 监听端口和最大连接数。这个最大连接数就是本房间最多支持多少玩家同时在线玩游戏。

      数据库配置: 包括UserInfoDB,具体游戏的DB(比如TexasPokerDB)的地址，端口，以及用户名和密码。

      CenterServer相关配置：这个配置和LogonServer一样，需要这个配置也是因为RoomServer会定时地从     CenterServer中更新游戏列表和房间信息发送给客户端。

     最后启动这个房间。在配置房间以后，玩家就可以通过客户端或者网页进行游戏了。

