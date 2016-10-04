---
layout: post
title: PHP链接sqlserver2005
categories: php
description: php,mssql,php链接sqlserver,ntwdblib.dll
keywords: Mac OS X, Zeal
---

为了php连接sql2005 ,我在网络上找了一大堆资料在我的csdn博客中.晚上3:05分时候终于搞定了
php连接sql2005的问题,现在整合,同时把FAQ整合上.
我前面写的教程:
### 1.连接前配置系统:

   检查文件 php5.2.5/ntwdblib.dll 默认下面有一个,不能连接再替换.

   下载正确版本的 ntwdblib.dll (2000.80.194.0)，地址： [ntwdblib.dll下载][1]

![查看NTWDBLIB.DLL文件的版本号](/images/posts/php/mssql-ntwdblibdllversion.png)
### 2.配置php
a. 打开php.ini将extension=php_mssql.dll的注释符号去掉。

![配置php.ini开启php_mssql.dll扩展](/images/posts/php/mssql-extension-php_mssqldll.png)

b. 打开php.ini将mssql.secure_connection = Off改为on。

![打开php配置文件中mssql.secure_connection开关](/images/posts/php/mssql-secure_connection-on.png)

c. 将php_mssql.dll拷贝到php.ini中extension_dir 指定的目录或者系统system32目录下。
(php_mssql.dll在php的压缩安装包中有)。

![php_mssql_dll](/images/posts/php/mssql-php_mssql_dll.png)

以上步骤完成后需要重启apache。

注意：
* 实际使用中发现 如果通过php压缩文件手工安装php到iis下，必须重启机器而不仅仅是iis。

### 3.配置sqlserver 
a. 运行 SQL Server 配置管理器：SQL Server Configuration Manager，打开协议 Protocols 

b. 允许命名管道 "named pipes" 和 "tcp/ip" 

c. 右键点击 "tcp/ip"，打开属性 Properties 标签 "IP addresses" 

d. 在 TCP 动态端口 "TCP Dynamic Ports" 填入 1433 

e. 重启 SQL Server


### 4.使用以下方式连接MS SQL Server 2005： 
代码如下：
```php
//链接数据库 
 $conn=mssql_connect('localhost','sa','123456'); 
   mssql_select_db('gu_dde',$conn); 
//query语句   
 $Query="select * from dde_top"; 
 $AdminResult=mssql_query($Query); 
//输出结果 
 $Num=mssql_num_rows($AdminResult); 
 for($i=0;$i<$Num;$i++) 
   { 
 $Row=mssql_fetch_array($AdminResult); 
 echo($Row[1]); 
 echo("
"); 
   }   
?>
```
输入http://127.0.0.1

![php链接sqlserver2005输出股票代码数据](/images/posts/php/php-echo-stocknumber.png)

### 5. FAQ常见问题:

#### 1. Fatal error: Call to undefined function mssql_connect()

报错:
```
Fatal error: Call to undefined function mssql_connect()
```
解决:

使用MSSQL_系列函数 

要使用这两种都需要在php.ini进行设定：  
(1)允许 DCOM，需要将php.ini中的 ;com.allow_dcom=TRUE前的分号";"去掉。 
(2)使用MSSQL扩展，需要php.ini中的 ;extension=php_mssql.dll前的分号";"去掉。(关键)  
(3)确认extension_dir为正确路径,以本机为例：extension_dir = "c:/AppServ5.2.6/php/ext"。  
(4)如果仍然机器报错说找不到c:/AppServ5.2.6/php/ext/php_mssql.dll但明明存在这个文件。 

解决方法：将php_mssql.dll,ntwdblib.dll拷贝到系统目录/system32下重启测试。。

(注:上面两个dll文件不在相同目录下，我的为c:/AppServ5.2.6/php/ext/php_mssql.dll；c:/AppServ5.2.6/php/ntwdblib.dll) 
另外设置好了后记得重启服务器哦。
    
#### 2. mssql_connect() Unable to connect to server

* 确认SQLServer2005服务器正常.检查 TCP/IP已经启用
![确认sqlserver开启了tcp/ip端口](/images/posts/php/mssql-sqlserver-sscm.png)

同时右键查看属性:

![右键查看sqlserver开启了tcp/ip端口](/images/posts/php/mssql-tcp-ip-port.png)

已经启用是否选择是

确认服务器正确之后,再确认ntwdblib.dll 文件位置是否放到了 c:/windows/system32下
同时要保证ntwdblib.dll 这个文件的版本和sqlserver的版本对应:

下面是对应关系:
* ntwdblib.dll 版本为 2000.2.8.0 是 对应 SqlServer2000(这个是网络查资料和猜测,没装2000)
* ntwdblib.dll 版本为 2000.80.194.0 是 对应 SqlServer2005(这个是用实验证明可以用,本人就是用笔记本装了2005)
* ntwdblib.dll 版本为 2000.80.2039 是 对应 SqlServer2008(这个是猜测没有装2008)
 
### 6.其他问题:

如果php apache Sql Server2000都在同一台机器上，访问基本没有问题了。
如果Sql Server2000和php机器是分离的，需要确认ping sqlserver所在机器的机器名能通，如过不通，
修改php所在机器的/system32/drivers/etc下的hosts文件，增加一行 sqlserver所在机器的机器ip   sqlserver所在机器的机器名字。
如果还是无法访问，需要确认php所在的机器有无暗转mdac。要不索性安装一下sqlserver的客户端好了。

解决问题如下:

* 下载两个文件 php_mssql.dll 和 ntwdblib.dll

* php_mssql.dll 如果这个没有复制到c:/windows/system32下,就很容易出现
 
* ntwdblib2093.dll 这个文件要注意版本,不然后面搞得很郁闷.


博客朋友遇到的问题:

* 我是远程连接，报message: 用户 'NT AUTHORITY\ANONYMOUS LOGON' 登录失败。
后来将php.ini中mssql.secure_connection恢复为Off，居然成功了！请问这个有什么影响？



[1]: http://www.mysys.top/download/ntwdblib-dll/
