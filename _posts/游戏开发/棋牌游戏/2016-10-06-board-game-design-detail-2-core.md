---
layout: post
title: 棋牌游戏服务器架构:详细设计(一) 内核设计
categories: 游戏开发
description: 棋牌游戏服务器架构:详细设计(一) 内核设计
keywords: 游戏设计,棋牌游戏,棋牌游戏服务器架构,详细设计,内核设计
---

      内核的几个组件被设计成Service,也就是说这几个模块都要实现如下接口:

![](http://pic002.cnblogs.com/images/2012/151655/2012091613224966.jpg)

图1  IService接口

      Start方法用来启动服务。

      Stop 方法用来关闭服务。

      IsService 方法用于查询当前服务是否正在工作。

      内核中的几个Service都不能够直接创建，Applications在使用这些Service的时候首先要得到一个IServiceMgr的实例，这被实现成了一个另类地单例模式。IServiceMgr的接口定义如下:

![](http://pic002.cnblogs.com/images/2012/151655/2012091613264275.jpg)

图2  IServiceMgr接口

      IServiceMgr提供两类接口:

      1) 获取Service的接口，这样直接得到具体的Service,是因为内核的Service比较固定。没有必要用GetService(strServiceName)这种方法。

          GetAsyncService    返回AsyncService的实例

          GetDBService        返回DatabaseService的实例

          GetTCPService       返回TCPServerService的实例

          GetTimerService    返回定时器实例

       2) 一个静态的单例方法Instance。它申明在接口层，但是需要在IServiceMgr的实现中去实现它。它返回IServiceMgr的实例。

      由于IServiceMgr的实现只是简单地将IAttemptService，ITCPServerServer,　IDatabaseService,ITimerService的实现组合在了一起，所以它的实现不会详细描述。

## 1 AsyncService详细设计

![](http://pic002.cnblogs.com/images/2012/151655/2012091613363317.jpg)

图3  AsyncService的详细设计

      AsyncService主要是提供给其他３个Service使用的，它实现了IService接口和IAsyncService接口。因为与异步相关的功能基本上都被boost::asio实现，所以AsyncService主要只是管理boost::asio的实例 。IAsyncService只提供了一个方法:

      GetIOService      返回一个可用的boost::asio::io_service的实例

      AsyncService组合了boost::asio和ThreadPool，其中boost::asio::io_service的数目和机器的cpu总数相同，而ThreadPool中线程总数为２倍的cpu数。所有ThreadPool中的线程都将作为工作线程，它们的入口函数都是io_service::run。

## 2 TimerService详细设计

![](http://pic002.cnblogs.com/images/2012/151655/2012091613475470.jpg)

图4  TimerService的结构图

      TimerService实现了IService和ITimerService接口。ITimerService提供如下接口:

       1) SetTimer(timerId,milisecs,timerFunc,repeatTimes)    设置一个id为timerId的定时器，这个定时器会被激            

           发repeatTimes次，每两次被小激发的时间间隔为millsecs毫秒。每次被激发都会调用 timerFunc这个函数。

       2) KillTimer(timerId)   取消id为timerId的定时器。

       3) KillAllTimer()           取消所有的定时器，一般用在系统关闭时调用。

       TimerService管理着一些TimerItem,Applications层用一个新的timerId,调用SetTimer时，TimerService就会创建一个新的TimerItem, 而在调用KillTimer时，就会销毁掉与其相关的那个TimerItem。TimerService的实现依赖与AsyncService,因为定时器本质上也是异步操作。将由AsyncService中的io_service来统一调度。      

       需要注意以下几点:

        1) 传给SetTimer的timerFunc这个函数要是线程安全的，因为不确定会在哪个工作线程的context中调用它，同时             如果你的好几个定时器公用同一个timerFunc, 就可能对共享资源造成竞争。

        2) SetTimer进如果发现已经存在相同id的TimerItem, 不会创建一个新的TimerItem,而是取消先前的定时器。修            改其参数后启动。

## 3 TCPServerService详细设计

![](http://pic002.cnblogs.com/images/2012/151655/2012091614251754.jpg)

图5  TCPServerService结构图

      TCPServerService实现了IService接口和ITCPServerService接口。ITCPServerService的几个主要接口说明:

      1) SendData  通过指定的ISocketItem发送数据, 数据在一般情况下由4个参数: MainCmd, SubCmd, Data, DataSize (可以参与总休设计中关于协议的部分的描述) 。有的时候Data为空，就不需要Data和DataSize这两个参数了。

      2) SendDataBatch 给所有连接发送数据。这是批量发送的，所有连接池中对应的客户端都会收到。

      3) CloseSocket  关闭指定的连接。

      4) SetObserver 设置监听者。用以接收异步通知。

      TCPServerService 管理着一个客户端来的连接池。这个连接池由SocketItem组成,每一个SocketItem都与一个整数标识对应，Applications使用这个标识来发送数据和接收数据。SocketItem主要提供下面几个接口:

      1) GetIndex    获取与其对应的唯一标识

      2) GetRound   由于每个SocketItem都是可以重用的，所以为了防止混乱，比如说一个SocketItem在前一时刻对应着client1, 但是现在对应着client2。client1曾经的一个请求现在才要返回，这时如果没有GetRound就会把client1的处理结果错误地返回给client2。从这里也可以看出，每个SocketItem的round是在连接建立的时候会增加。

      3) IsConnected  是否处于连接状态。

      4) SendData  发送数据。

      5) GetClientAddress 得到客户端的IP地址

      6) GetConnectTimer 获取连接时间。

      7) Close  关闭连接。

      也许你会问了，我怎么只看到发送数据的接口，而没有接收数据的接口呢？因为这是个异步架构，在有连接到来，或者数据到来的时候，你会收到通知的。前提条件是你调用SetObserver设置了监听者。TCPServerService的监听都需要实现ITCPServiceObserver接口, TCPServerService通过这个接口提供的方法来通知你连接和读取事件:

      1) OnSocketAccept  在新连接到达时，会调用你这里面的内容。

      2) OnSocketRead  在数据读取完成后，会调用你提供的这个方法做进一步处理。

      3) OnSocketClose  告诉你连接将要关闭。

      需要注意的是如果你这三个方法中有共享的数据，要加锁保护。因为工作线程可能会产生竞争状态。

      和TimerService一样，TCPServerService的异步调度依赖于IAsyncService。

##  4 DatabaseService详细设计

![](http://pic002.cnblogs.com/images/2012/151655/2012091614553542.jpg)

图6  DatabaseService结构图

      可以对比一下DatabaseService和TCPServerService的结构图，你会发现他们是那么地相似。对的，它们的设计思路如出一辙。DatabaseService实现了IService和IDatabaseService这两个接口。IDatabaseService主要只提供了3个接口:

      1) Connect  连接到一个数据库

      2) Query   进行查询。 这里有两点要注意：1) Query以后不会立马得到结果，因为这是异步的; 2) 存储过程的调用也得使用这个方法，你只要将query语句写成 'select stroage_procedure(param1,param2,...)' 就行了。

      3) SetObserver 设置观察者。因为查询是异步的，所以你要设一个观察者来得到通知。

      DatabaseService管理着一些数据库连接DBConnect, 每一个DBConnect也与一个整数标识相关联，可以通过GetIndex获得。同时你可以通过IsConnect来查询这个DBConnect是否处于连接状态。

       在实现IDBServiceObserver时，你需要实现下面两个方法:

       1) OnDBConnect  在数据库连接建立时会调用

       2) OnQueryEnd  在这里你可以得到一个表示查询结果的QueryResult对象。你可以通过它知道查询的状态，以及结果信息。