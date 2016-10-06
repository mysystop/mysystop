---
layout: post
title: 棋牌游戏服务器架构:总体设计
categories: 游戏开发
description: 棋牌游戏服务器架构:总体设计
keywords: 游戏设计,棋牌游戏
---

      首先要说明的是, 这个棋牌游戏的服务器架构参考了网狐棋牌的架构。网狐棋牌最令人印象深刻的是其稳定性和高网络负载。它的一份压力测试报告上指出：一台双核r的INTEL Xeon 2.8CPU加上2G内存和使用共享100M光纤的机子能够支持5000人同时在线游戏。

      在研究其服务器框架后发现，它的网络部分确实是比较优化的。它主要采用了Windows提供的IO完成端口来实现其网络组件。本服务器虽然参考了其设计，但是还是有很大的不同，因为这个服务器框架主要是用在linux系统之上，而网狐棋牌是基于Windows平台的，严重依赖于windows sdk。这个架构延续了网狐棋牌在网络组件所作的努力，这个棋牌的服务器也使用异步IO作为网络的工作方式，更为彻底的是其数据库也是采用异步架构。boost::asio提供了一个异步框架，所以它的几个核心组件: TCPServerService, TimerService, DatabaseService, AsyncService中都可以看到boost::asio的影子。

，  图1是总体架构图。从图上我们看到服务器的整体架构分为三层：Libraries, Core和Applications。Core层基于Libraries实现，而Applications使用Core层提供的服务，并且要监听Core层的异步事件(Socket、Database等)。

![](http://pic002.cnblogs.com/images/2012/151655/2012091519331385.jpg)

　　　图1  棋牌游戏服务器端总架构

Libraries 主要由4个库组成，其中boost::thread是一个跨平台的线程库，boost::asio是跨平台的异步IO库，protobuf则是用来序列化服务器和客户端协议的, libpq是开源数据库postgresql提供的客户端的官方接口，支持异步数据库操作。

Core 主要由4个Service组成，它们建立在Libraries的基础之上。给应用层提供了网络，数据库和定时器功能。AsyncService主要是Core内部自己使用。TimerService提供定时器功能，TCPServerServic管理着客户端来的连接。而DatabaseService提供基本的数据库访问功能。

Applications是基于Core实现的4种服务器，它们管理着游戏信息，提供登录以及处理游戏逻辑的功能。下面是用户与这些服务器交互的一个经典流程:

      1) 客户端将用户名和密码发送给LogonServer登录，在登录验证成功以后，将游戏列表返回给客户端。

      2) 玩家选择具体游戏进入房间时，客户端发送请求给RoomServer，RoomServer将房间的信息返回给客户端显示

      3) 玩家选择桌子坐下，游戏开始。客户端将游戏动作发送给相应的RoomServer, RoomServer将操作解析后转发给游戏逻辑模块进行处理，并将处理结果返回给客户端。

这几个服务器这间的关系是:

      1) CenterServer维护游戏列表信息和房间信息;

      2) LogonServer定时从CenterServer取回游戏列表信息和房间信息;

      3) RoomServer在启动时向CenterServer注册，在关闭时从CenterServer注销， 以玩家进入房间时通知CenterServer更新在线人数。同时像LogonServer一样定时连接CenterServer更新游戏列表和房间信息。

## 1 Libraries层

      boost::asio是一个异步IO库，提供了一个通用的异步框架，并提供了基本的socket的异步接口，它的主要功能是响应程序的异步IO请求，在操作完成以后，将其加入到一个完成队列之中, 在这个完成队列上有一些工作线程在等着，这些工作线程从完成队列上取出已经完成的操作，调用上层应用提供的一个完成函数--completaion handler。asio库是通过学实现Proactor模式来完成这些工作的，在Windows是直接基于I/O completion port，而在类Unix系统中，是基于epool等函数使用Reactor模式来模拟的。 

      libpq是开源数据库postgresql提供的客户端接口库。这里选用postgresql是因为postgresql的跨平台性以及其稳定性和高性能，另一方面是由于我对这个数据库比较地熟悉。Libpq也对数据库的连接、查询、更新等提供了异步实现。可以和boost::asio结合在一起提供统一地异步操作接口。

      boost::thread库是用C++实现的一个跨平台的线程库, 在C++11中，它已经被纳入到了标准库中。这个库在这里主要用来实现一个线程池，作为boost::asio的工作线程。主要是由Core层的AsyncService来维护。代码的其他地方不直接启动线程。但是在异步操作的完成函数中，对那些共享数据需要加锁保护。

      protobuf库是Google发布的一个开源的用来序列化对象的高性能的库，它支持多种语言，比如C++,Java,flash 等等。同时还将字节序等琐碎的东西封装起来了，方便上层应用。

## 2 Core层

      核心层由4个Service: AsyncService、TCPServerService、TimerService、DatabaseService组成。下面是关于它们的基本描述. 

      AttemptService是Core内部使用的，它封装了boost::asio和ThreadPool的功能，提供给其他几个Service使用。从名字上可以看出，他的主要功能是给其他几个Service提供异步调度，这是通过boost::asio提供的功能来实现的，而ThreadPool是提供给boost::asio作为工作线程的。

      TCPServerService有一个连接池,管理着客户端来的连接。内部通过AsyncService将socket读写完成消息，通过应用层注册进来的TCPServiceObserver通知到调到应用层去。它和Applications的交互包括:

      1)  Applications 调用 SetObserver注册用来接收网络读写完成消息;

      2)  Applications 调用 SendData 发送数据;

      3)  Core在accept, recv完成后调用 Applications注册的Observer。

      TimerService提供了定时器的功能,Applications层可以直接使用它来创建定时器，取消定时器。设定时间到来时，TimerService会调用创建定时器时指定的一个回调函数。

      DatabaseService封装了libpq,提供数据库的基本操作。主要管理数据库连接，执行查询操作，执行存储过程等。它的实现中有一个连接池。和socket操作一样，它提供的数据库操作都是异步执行的，所以Applications层需要实现DBServiceObserver来监听操作结果。

## 3 Applications

      前面的无论是libraries还是core,都是死的，只有applications加入了逻辑，它们是棋牌服务器的主休。下面是关于它们的比较详细的信息

### 3.1 CenterServer

![](http://pic002.cnblogs.com/images/2012/151655/2012091522162547.jpg)

            图2  CenterServer与外界的交互图

      CenterServer不直接与玩家进行交互,它主要的功能是管理游戏列表和房间信息，包括:

      1\. 游戏类型信息：　棋牌游戏、休闲游戏、视频游戏等。

      2\. 游戏种类：　比如在棋牌游戏这个大类之下有：德州扑克、斗地主、升级等。

      3\. 站点信息：　因为这个服务器架构完全支持分布式，所以还保存有站点的信息

      4\. 房间信息：　维护当前有哪些房间以及房间当前的在线人数。

      CenterServer中有关游戏列表的信息是它在启动的时候从ServerInfoDB这个数据库加载的, 而它的房间信息来自RoomServer，RoomServer在启动时将自己注册进来，在关闭的时候从CenterServer中注销自己。同时在玩家进入房间的时候，还会要求CenterServer更新在线人数。

　　CenterServer还应该响应LogonServer和RoomServer的请求，将游戏列表和房间信息返回给它们。

### 3.2 LogonServer 

![](http://pic002.cnblogs.com/images/2012/151655/2012091522265556.jpg)

              图3 LogonServer与外界交互图

      LogonServer提供注册新的游戏玩家服务并且处理游戏玩家的登录请求。

      LogonServer需要和UserInfoDB交互，这些交互包括:

      1\. 在注册的时候写入注册玩家的信息。

      2.在玩家登录的时候与数据库玩家信息进行核对。

      LogonServer会定时地向CenterServer发送更新游戏列表和房间信息的请求，因为这些信息在不断地变化，而LogonServer需要在玩家登录时将这些信息返回给他们。

### 3.3 LogServer

![](http://pic002.cnblogs.com/images/2012/151655/2012091523012981.jpg)

  图4  LogServer与外界的交互图

      有时候，玩家可能会对游戏的过程产生怀疑，或者想回顾整个游戏的过程。这就需要服务器将游戏的过程以Log的形式存储起来，供玩家检查用。LogServer的就是用来响应玩家的核查的请求，然后从GameLogDB中将整个游戏过程返回给客户端，客户端以视频地方式显示给玩家。 

      玩家在请求检查的时候，客户端会将这局游戏的以及玩家的信息id发送到LogServer, LogServer根据游戏id的信息从GameLogDB取出日志信息返回给玩家。游戏的过程可以用结构化语言描述出来，本来postgresql直接支持Json，也就是说Log可以以JSON的形式存在数据库之中，但是由于可能会有字节序的问题，所以Log的信息也要用protobuf序列化了再存入数据库。LogServer在从数据库中读出日志后不用反序列化直接返回给客户端反序列化。

### 3.4 RoomServer

      RoomServer可能是最重要的一类Server了，一个RoomServer会和一个游戏模块结合在一起。它管理着游戏的一个房间，处理玩家进入房间，找桌子座下的请求，并将游戏相关的消息转发给游戏模块进行处理。不仅不同的游戏会有不同的RoomServer，即便是同一游戏，也可能有多个RoomServer， 比如对于德州扑克来说，就可能有vip房间，普通房间等等，同一类型的房间也可能有Room1,Room2,这个可以根据玩家量按需架设。图5给出了RoomServer与外界交互的图。

![](http://pic002.cnblogs.com/images/2012/151655/2012091523122591.jpg)

图5 RoomServer与外界的交互图 

      RoomServer启动的时候，先要发送请求给CenterServer进行注册，在关闭时要从CenterServer中注销。同时还会定时通知CenterServer更新在线人数, 定时从CenterServer上取回最新的游戏列表和房间信息。

      RoomServer需要和玩家进行交互。玩家进入房间，找桌子座下等的请求都由RoomServer来处理，而游戏操作。比如说加注、发牌等 RoomServer会直接转发给游戏模块进行处理。

      RoomServer管理着一个在线用户列表，在玩家进入房间，离开房间时这个列表随之更新。这个列表中有关玩家的详细信息是从数据库UserInfoDB中加载到的。 玩家在进行游戏时，由于输赢的关系，他的积分或者游戏币会随着变化，为了记录这些变化, 需要与GameDB进行交互。

      管理员可以通过RoomServer来发布消息、踢出玩家、警告玩家、设置玩家权限、设置房间属性等活动。

      玩家也可以通过RoomServer参与聊天(包括大厅公聊和私聊)。

## 4 交互协议

      客户端和服务器进行交互时，传递的包需要使用protobuf来序列化。一个请求由一个container组成，container中可以包含一个或者多个请求包/应答包。每一个请求包和应答包都有如下基本结构:

![](http://pic002.cnblogs.com/images/2012/151655/2012091522590333.jpg)

图6 服务器和客户端通信的Package结构

nMainCmd 指示请求的类别，比如说游戏请求，房间管理请求等

nSubCmd  指请求的具体是什么，比如加注、踢出玩家等

nDataSize  指示pData字段的长度

pData     可以是任何消息，如果是一个结构，需要用protobuf序列化

## 5 数据库

Database主要有3个: ServerInfoDB、UserInfoDB, GameDB。

ServerInfoDB: 主要存储的是游戏列表的信息。这些信息包括—游戏种类列表、游戏类型列表和站点信息。

UserInfoDB: 主要存储玩家相关的全局信息，包括玩家的 ID 号码，帐户名字，密码，二级密码，头像，经验数值，登陆次数，注册地址，最后登陆地址等玩家属性信息。

GameDB:  主要存储的是玩家的游戏相关信息，例如游戏积分，胜局，和局，逃局，登陆时间等信息