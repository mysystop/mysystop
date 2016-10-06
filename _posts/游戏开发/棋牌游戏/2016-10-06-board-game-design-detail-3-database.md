---
layout: post
title: 棋牌游戏服务器架构:详细设计(三) 数据库设计
categories: 游戏开发
description: 棋牌游戏服务器架构:详细设计(三) 数据库设计
keywords: 游戏设计,棋牌游戏,棋牌游戏服务器架构,数据库设计
---

主要有3类Database: ServerInfoDB,UserInfoDB和GameDB。 ServerInfoDB<span>主要存储的是游戏列表的信息,UserInfoDB存储玩家的全局信息，而GameDB就是积分以及积分变化情况。下面分别加以描述。</span>

### 1. ServerInfoDB

      ServerInfoDB主要存储游戏列表信息。主要有以下几个表:

      1. GameTypeInfo,其主要字段为:

          TypeID：类型标识 ID 

          TypeName：类型名字，例如棋牌类，休闲类

          Enable：控制游戏大厅是否显示该类型，默认为 1，即为默认显示

      2. GameKindInfo,其主要字段为:

          KindID: 游戏的唯一标识

          TypeID: 外键(GameTypeInfo的主键)，该游戏所属类型

          KindName: 游戏名称, 比如德州扑克，斗地主等。

          ProcessName: 客户端进程名称

          MaxVersion: 客户端进程的最低版本，若是登录时发现客户端版本低于这个值，要求其更新。

          Enable: 控制游戏大厅是否显示该游戏，默认为1。

      3. GameStationInfo 站点信息表:

          StationID:  站点标识

          StationName: 站点名称

          Enable: 这个站点是玩家可以选择的，这个标识控制是否显示给玩家,默认为1

### 2 UserInfoDB

      这个数据库主要存储玩家的全局信息，有两个表: UserAccounts和ClubList:

      1. UserAccounts的主要字段:

          UserID：玩家的唯一标识，注册的时候自动生成，不能修改

          Accounts：帐户名字，具有唯一性，不能重复，能修改

          LogonPass：玩家帐户的密码，采用通用加密算法 MD5 加密记录

          Gender：性别

          LogonNullity：帐户禁止标志，影响玩家登录广场和登录游戏房间

          ServiceNullity：服务禁止标志，保留供网站系统使用或者将来系统扩展使用

          UserRight：玩家权限标志，每一位代表一种权限， 比如旁观权限，大厅公聊权限，私聊权限等。

          ManageRight：管理权限标志，第一位代表一种管理权限，比如踢出玩家，发布消息等。

          FaceID：玩家头像索引号码

          ClubID：外键(ClubList的主键)，玩家社团 ID 号码

          MemberOrder：会员等级标识

          Experience：玩家经验数值，表示玩家游戏的总局数，可以通过修改每个游戏的经验数值增加方案得到策略的改变

          AllLogonTimes：玩家成功登陆的总次数

          RegisterDate：玩家的注册日期

          LastLogonDate：玩家最后登陆的日期

          RegisterIP：玩家帐户的注册所在的 IP 地址

          LastLogonIP：玩家最后使用此帐户登陆的 IP 地址

          Question：密码找回提示问题

          Answer：密码找回回答问题

          QQ：玩家注册QQ号码

          ConnectPerson：联系人姓名

          PhoneNO：电话号码

          Address：家庭住址

          Email：电子邮箱

      2. ClubList是用来存储社团列表的，主要字段包括:

          ClubID：社团的唯一标识号码，注册的时候自动生成，不能修改

          ClubName：社团名字

          ClubQQ：与社团对应的QQ群号码

          ClubAdmin：社团管理员(外键)

          ClubNotice：社团公告,预留字段

### 3 GameDB

      这个DB主要存储玩家的游戏相关信息，例如游戏积分，胜局，和局，逃局，登陆时间等信息。

      1. GameScore

          UserID：玩家标识号码

          Score：玩家的积分数值

          WinCount：游戏胜利局数

          LostCount：游戏输局局数

          DrawCount： 游戏和局局数

          FleeCount： 游戏逃跑局数

          UserRight：玩家在此游戏中的普通权限数值，在登陆房间的时候与玩家房间权限进行或操作

          ManageRight：玩家在此游戏中的管理权限数值，在登陆房间的时候与玩家房间权限进行或操作

          PlayTimeCount：玩家在此类游戏中的游戏时间

          AllLogonTimes：玩家进入此类游戏的总次数

          RegisterDate：玩家首次进入此类游戏的时间

          LastLogonDate：玩家最后一次进入此类游戏的时间

          RegisterIP：玩家首次进入此类游戏的 IP 地址

          LastLogonIP：玩家最后一次进入此类游戏的IP 地址

       2. GameLogonLog:

          ID：Log的索引ID，自增长。

          UserID：外键，玩家 ID 号码

          Score：玩家进入房间时刻的积分数值

          WinCount：玩家进入房间时刻的游戏胜利局数

          LostCount：玩家进入房间时刻的游戏输局局数

          DrawCount：玩家进入房间时刻的游戏和局局数

          FleeCount：玩家进入房间时刻的游戏逃跑局数

          KindID：玩家进入的房间的类型标识号码 

          ServerID：玩家进入房间的房间标识号码

          ClientIP：玩家进入房间的连接IP地址

          LogonTime：玩家进入房间的时间

       3. GameScorelog:

          ID：LogID,自增长

          UserID：外键，玩家 ID 号码

          LeftTime：玩家离开房间的时间

          Score：玩家在游戏房间游戏所产生的积分改变的数值

          WinCount：玩家在游戏房间游戏所产生的胜利局数改变的数值

          LostCount：玩家在游戏房间游戏所产生的输局局数改变的数值

          DrawCount：玩家在游戏房间游戏所产生的和局局数改变的数值

          FleeCount：玩家在游戏房间游戏所产生的逃跑局数改变的数值

          Experience：玩家在游戏房间游戏所产生的经验数值改变的数值

          PlayTimeCount：玩家在游戏房间游戏所产生的游戏时间的数值

          OnLineTimeCount：玩家在游戏房间游戏所产生的在线时间的数值

          KindID：玩家进入的房间的类型标识号码

          ServerID：玩家进入房间的房间标识号码

          ClientIP：玩家进入房间的连接IP地址