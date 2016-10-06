---
layout: post
title: 棋牌游戏服务器架构:详细设计(二) 应用层设计
categories: 游戏开发
description: 棋牌游戏服务器架构:详细设计(二) 应用层设计
keywords: 游戏设计,棋牌游戏,棋牌游戏服务器架构,应用层设计
---

      这里的应用层，指的是CenterServer、LogonServer、LogServer、RoomServer等几个服务器，另外还包括游戏模块的设计。不过游戏模块和前４个服务器的设计很不相同。这里先说一下服务器应用的详细设计。

      这上面提到的４个服务器都需要响应客户端(这里的客户端的意思是泛指)的请求，进行数据库操作，同时还要能够配置，以及显示系统运行的状态信息等。这里会采用MVC模式来组织应用层逻辑。

![](http://pic002.cnblogs.com/images/2012/151655/2012091616591731.jpg)

 图1  Application层基本结构

      IController从ITCPServiceObserver继承而来，会与ITCPServerService进行交互，因此它需要解析客户端发过来的请求，如果需要作数据操作，则转发给IModel处理。

      IModel从DBServiceObserver继承而来，一些获取数据及存储数据的操作由它完成，这是通过IDatabaseServicer提供的服务完成的。

      IView实现了IObserver接口，主要用来显示IController和IModel的一些状态信息以及其他消息。

      Applications中的内个Server只要按照其任务实现IController,IModel和IView就行了。

### 1  Center Server详细设计

       CenterServer的主要功能是维护游戏列表和房间信息。游戏列表是从ServerInfoDB中加载到的，下面是一个简略的结构图。

![](http://pic002.cnblogs.com/images/2012/151655/2012091617081676.jpg)

图2 CenterServer维护的信息结构

      因为前面已经详细介绍了应用层架构，所以这里只是列出IModel的实现，至于IController的实现，则是解析请求。要么用ServerList中取出游戏列表信息和房间信息返回之。要么向ServerList中添加房间，删除房间以及让ServerList更新在线人数等。

      CenterServer在处理请求时产生的输出信息会让IView输出显示。

### 2  Logon Server 详细设计

![](http://pic002.cnblogs.com/images/2012/151655/2012091617221165.jpg)

图3  LogonServer结构图

      IController的实现LogonController有以下几个任务:

      1) 转发注册请求给LogonHandler让其处理;

      2) 转发登录请求给LogonHander让其处理;

      3) 定时使用CenterSocket发送请求给CenterServer, 取回的游戏列表和房间信息存入ServerList这中。

      IModel的实现LogonHandler的主要功能就是注册用户以及验证登录。

      CenterSocket是用来向CenterServer发送请求的。

      ServerList存的数据和CenterServer中的ServerList一样，但是其实现不同，它存的是LogonController从CenterServer中取回来的。

### 3  LogServer详细设计

      LogServer的实现比较简单，下面是其结构图

![](http://pic002.cnblogs.com/images/2012/151655/2012091617542350.jpg)

图4 LogServer结构图

      LogServer从IController继承下来，它接收玩家核查游戏过程的请求，并将其转发给LogFetcher处理，处理完成后，将结果返回给玩家。

      LogFetcher实现了IModel, 它的任务很简单，就是去数据库取得游戏过程的日志。

### 4  Room Server 详细设计

      RoomServer是最重要的一类Server,玩家的大多数操作都由它来响应，其结构图如图5所示。

![](http://pic002.cnblogs.com/images/2012/151655/2012091619281716.jpg)

 图5 RoomServer结构图

      UserManager继承自IModel, 主要任务是管理在线玩家，RoomController在接收到玩家进入房间的请求后，就会根据玩家的的用户名和密码从UserInfoDB中加载该玩家的详细信息，生成一个UserItem, 加入在线队列。UserManager同时还会维护一个离线队列，存储那些请求离线或者掉线的玩家。

      RoomController实现了IController接口。它主要有以下几个功能:

      1) 将进入房间的请求交和UserManager处理.

      2) 启动时通过CenterSocket向CenterServer注册，关闭时从其中注销，同时定时通过CenterSocket从CenterServer取回游戏列表和房间信息(由于空间问题，图中没有画出来，基本和LogonServer差不多)。

      3) 将游戏相关的请求转交给TableMgr处理.

      4) 处理聊天及管理请求。

       TableMgr管理着这个房间里的桌子。而Table则是处理公共棋牌游戏逻辑的地方。主要包括找椅子坐下，离开等。而具体地游戏命令比如德州扑克的加注等会由Table转发给GameModule进行处理。处理结果由RoomController返回给玩家。

### 5  Game Module详细设计

      这里以德州扑克为例，来说明一个游戏的逻辑的结构,

![](http://pic002.cnblogs.com/images/2012/151655/2012091619031454.jpg)

图6 德州扑克游戏模块结构

      这里虽然给出的是德州扑克的结构图，但是其他游戏也有类似的结构。

      每一个游戏模块都必须要实现两个接口ITableObserver，游戏的主要逻辑就在放在这里面，因为桌子会将玩家的操作信息转化以后传递过来，所以这里是处理洗牌，发牌，玩家投注处理的最佳场所。另外一个必须实现的接口是IGameServiceMgr,这个接口是游戏模块暴露给桌子的工厂接口，桌子通过它才能创建出TexasPokerTableObserver。

      IGameServiceMgr中方法说明:

      1) CreateTableObserver  创建游戏逻辑处理的实现,这里会创建并返回TexasPokerTableObserver。

      2) GetGameAttrib  返回游戏的属性，主要包括: 游戏的名称　，游戏描述，游戏模块的名称，客户端模块名称，游戏数据库名称等

      3) RectifyRoomOption　由于一些游戏对房间有特殊要求，所以RoomServer需要调用这个接口调整房间的一些设置

      4) CreateAndroidUser　创建机器人的监听者, 其角色相当于现实中的玩家。

      TexasPokerRule主要封装了德州扑克的一些基本规则，如果选出最大牌型、比较牌型的大小，洗牌，找出赢家等。