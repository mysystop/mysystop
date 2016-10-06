---
layout: post
title: Go语言基础：并发
categories: Go语言编程
description: Go语言基础：并发
keywords: Go,Golang,Golang服务器,并发
---

# 并行与并发
理论式的概念：
并行：多件事在同一时刻发生。 
并发：多件事在同一时间间隔发生。

5岁小孩都能看懂的解释：

![golang并发](/images/posts/golang/2016-10-06-golang-concurrent.png)

摘自：[浅谈并发与并行(一)][1]和 Concurrent and Parallel Programming 
上文如果用程序员的语言来讲，CPU处理器相当于上图的咖啡机的角色，任务相当于队列中的人。

# 并发与并行的区别：
一定要仔细阅读此文：[并发和并行的区别][2] 。这篇文章提到了网络服务器并发连接数、吐吞量、宽带的概念，对于初学者应该很受用。

```
并发和并行从宏观上来讲都是同时处理多路请求的概念。但并发和并行又有区别，并行是指两个或者多个事件在同一时刻发生；而并发是指两个或多个事件在同一时间间隔内发生。

在操作系统中，并发是指一个时间段中有几个程序都处于已启动运行到运行完毕之间，且这几个程序都是在同一个处理机上运行，但任一个时刻点上只有一个程序在处理机上运行。

①程序与计算不再一一对应，一个程序副本可以有多个计算
②并发程序之间有相互制约关系，直接制约体现为一个程序需要另一个程序的计算结果，间接制约体现为多个程序竞争某一资源，如处理机、缓冲区等。
③并发程序在执行中是走走停停，断续推进的。

在网络服务器上，并发是指同一时刻能处理的连接数，比如，服务器能建立1000个TCP连接，即服务器同时维护了1000个socket，这个服务器的并发量就是1000，但是服务器可能只有单核或者8核，16核等，
总之对这1000个socket连接的处理也是分时来做的。每个socket服务器处理的时间如果是1s，那么该服务器1s内可以处理完1000个请求，如果每个socket处理100ms的话，那么该服务器1s内可以处理10000个请求。

在这里我们先抛出一些概念，如果这些概念都弄清楚了，并发和并行基本就清楚了。

会话：在我们用电脑工作时，打开的一个窗口或一个Web页面，我们可以把它叫做一个“会话”，扩展到web服务器上，要维护很多个用户的web页面访问，我们可以认为服务器管理了多个“会话”。

并发连接数：网站有时候报错：“HTTP Error 503. The service is unavailable”。但刷一两下又正常，估计很可能是超过网站的最大并发连接数了。并发连接指网络流量管理设备或代理服务器对其业务信息流的处理能力，
是能够同时处理的点对点连接的最大数目，它反映出设备对多个连接的访问控制能力和连接状态跟踪能力，这个参数的大小直接影响到设备所能支持的最大信息点数。

并发可以理解为服务器最多维护多少个会话数，并行则不一样，它关系的是有多少个会话是在同时进行，假如有两台服务器（进程），可能并行的数量是2，而并发的数量是1000。我们还可以对比下吞吐量和带宽的概念。

吞吐量与带宽的区分：吞吐量和带宽是很容易搞混的一个词，两者的单位都是Mbps。先来看两者对应的英语，吞吐量：throughput；带宽：Max net bitrate。当讨论通信链路的带宽时，
一般是指链路上每秒所能传送的比特数，它取决于链路时钟速率和信道编码在计算机网络中又称为线速。
可以说以太网的带宽是10Mbps。但是需要区分链路上的可用带宽（带宽）与实际链路中每秒所能传送的比特数（吞吐量）。
通常更倾向于用“吞吐量”一词来表示一个系统的测试性能。这样，因为实现受各种低效率因素的影响，所以由一段带宽为10Mbps的链路连接的一对节点可能只达到2Mbps的吞吐量。
这样就意味着，一个主机上的应用能够以2Mbps的速度向另外的一个主机发送数据。

带宽可以理解成是并行，即同时可以有10M 个bit（0，1）在线路中传输。而吞吐量类似并发，指主机每秒可以处理2M个bit。比喻有些不是很恰当，但仔细体会下，有些类似之处。
```
   
# Goruntine
## goruntine原理
我们知道Go从语言层面就支持了并发，而goruntine是go并发设计的核心。goruntine说到底是协程【Go Web 编程里是线程，也是对的，因为协程类似于用户态线程】。具体原理实现参考： 
1. 以goroutine为例看协程的相关概念 
2. goroutine与调度器 
3. 廖雪峰：协程 
4. 知乎：协程的好处是什么？ 
5. 知乎：golang的goroutine是如何实现的？ 
这些参考文章建议读者好好看看。 
# 了解了协程、goruntine的实现机制
接下来学习如何启动goruntine。

## 启动goruntine
goroutine 通过关键字 go 就启动了一个 goroutine。
```go
go hello(a, b, c)//普通函数前加go
```
例子：
```go
package main

import (
    "fmt"
    "runtime"
)

func say(s string) {
    for i := 0; i < 5; i++ {
        runtime.Gosched() //表示让cpu将控制权给其他人
        fmt.Println(s)
    }
}

func main() {
    runtime.GOMAXPROCS(1)
    go say("world")
    say("hello")
}
```
输出：
```sh
hello
world
hello
world
hello
world
hello
world
hello
```
很简单，在函数前加一个go关键词就启动了goruntine。

# Channel
## channel是什么
channel是一种通信通道，goruntine之间的数据通信通过channel来实现。goruntine通过channel发送或者接收消息。

## channel的基本操作语法：
cl := make(chan int) //创建一个无缓冲的int型channel，可以根据需求创建bool、string等类型的channel
c1 := make(chan int, 4) //创建有缓冲的int型channel
cl <- x //发送x到channel cl
x := <- cl //从cl中接收数据，并赋值给x
### 无缓冲的例子：
```go
package main

import (
    "fmt"
    "time"
)

func sendChan(cl chan string) {
    fmt.Println("[send_start]")
    cl <- "hello world" // 向cl中加数据，如果没有其他goroutine来取走这个数据，那么挂起sendChan, 直到getChan函数把"hello world"这个数据拿走
    fmt.Println("[send_end]")
}

func getChan(cl chan string) {
    fmt.Println("[get_start]")
    s := <-cl // 从cl取数据，如果cl中还没放数据，那就挂起getChan线程，直到sendChan函数中放数据为止
    fmt.Println("[get_end]" + s)
}

func main() {
    cl := make(chan string)

    go sendChan(cl)
    go getChan(cl)

    time.Sleep(time.Second)
}
```
输出：
```
[send_start]
[get_start]
[get_end]hello world
[send_end]
```
上面的例子存在3个goruntine，注意main也在一个goruntine中。如果函数main中没有 time.Sleep(time.Second)，你会发现什么输出都不会有，为什么呢？是因为另外两个goruntine还没来得及跑，主函数main就已经退出了。 
所以需要让main等一下，time.Sleep(time.Second)就是让main停顿一秒再输出。 
无缓冲的channel的接收和发送都是阻塞的，也就是说：

* 数据流入无缓冲信道, 如果没有其他goroutine来拿走这个数据，那么当前线阻塞
* 从无缓冲信道取数据，必须要有数据流进来才可以，否则当前goroutine阻塞

### 有缓冲的例子：
```go
package main

import (
    "fmt"
    "time"
)

func sendChan(cl chan int, len int) {
    fmt.Println("sendChan_enter")
    for i := 0; i < len; i++ {
        fmt.Println("# ", i)
        cl <- i //cl的存储第4个数据的时候，会阻塞当前goruntine，直到其它goruntine取走一个或多个数据
    }
    fmt.Println("sendChan_end")
}

func getChan(cl chan int, len int) {
    fmt.Println("getChan_enter")
    for i := 0; i < len; i++ {
        data := <-cl
        fmt.Println("$ ", data)//当cl的数据为空时，阻塞当前goruntine，直到新的数据写入cl
    }
    fmt.Println("getChan_end")
}

func main() {
    cl := make(chan int, 3)// 写入3个元素都不会阻塞当前goroutine, 存储个数达到4的时候会阻塞

    go sendChan(cl, 10)
    go getChan(cl, 5) 

    time.Sleep(time.Second)
}
```
输出：
```sh
sendChan_enter
#  0
#  1
#  2
#  3
getChan_enter
$  0
$  1
$  2
$  3
#  4
#  5
#  6
#  7
#  8
$  4
getChan_end
```
### 为什么sendChan_end没有输出？ 
getChan取完5个数据后，getChan这个goruntine就会挂起，而sendChan线程因为数据填满，无法将剩余的数据写入chanl而挂起，最后因main所在的goruntine超时1秒结束而结束。故而看不到sendChan_end的输出。

有缓冲的channel是可以无阻塞的写入，当缓冲填满时，再次写入新的数据时，当前goruntine会发生阻塞，直到其它goruntine从channel中取走一些数据：
有缓冲的channel可以无阻塞的获取数据，当数据取空时，再次取新的数据时，当前的goruntine会发生阻塞，直到其它goruntine往channel写入新的数据
### close
生产者【发送channel的goruntine】通过关键字 close 函数关闭 channel。关闭 channel 之后就无法再发送任何数据了, 在消费方【接收channel的goruntine】可以通过语法 v, ok := <-ch 测试 channel 是否被关闭。如果 ok 返回 false,那么说明 channel 已经没有任何数据并且已经被关闭。

不过一般用得少，网上关于它的描述也不多。

### select
语法结构类似于switch。
```go
select {
    case cl<-x:
        go语句
    case <-cl:
        go语句
    default: //可选，
        go语句
}
```

* 每个case只能是channel的获取或者写入，不能是其它语句。
* 当每个case都无法执行，如果有default，执行default；如果没有default，当前goruntine阻塞。
* 当多个case都可以执行的时候，随机选出一个执行。
* 关于select的用法，强烈推荐阅读：【GOLANG】Go语言学习-select用法

[1]:http://www.cnblogs.com/yangecnu/p/3164167.html 
[2]:http://blog.csdn.net/coolmeme/article/details/9997609