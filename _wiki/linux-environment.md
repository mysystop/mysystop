---
layout: wiki
title: Linux环境变量
categories: Linux
description: Linux环境变量设置.
keywords: Linux,环境变量,环境变量知识
---
### 前置知识
vi编辑器命令简单使用

    1. 编辑新文件 vi 文件名
    2. 进入插入状态 按i键
    3. 退出编辑状态到命令模式 ,按两次ESC键
    4. 删除行,移动光标到要删除行,连续按两次d,如:dd
    5. 保存,退回到命令模式,按:wq ,保存并退出vi.

### 一、Linux的变量种类
按变量的生存周期来划分，Linux变量可分为两类：
1. 永久的：需要修改配置文件，变量永久生效。

2. 临时的：使用export命令声明即可，变量在关闭shell时失效。
    
### 二、设置变量的三种方法
1. 在/etc/profile文件中添加变量【对所有用户生效（永久的）】

用VI在文件/etc/profile文件中增加变量，该变量将会对Linux下所有用户有效，并且是“永久的”。

例如：编辑/etc/profile文件，添加CLASSPATH变量
```
vi /etc/profile
```
添加内容如下:
```
export CLASSPATH=./JAVA_HOME/lib;$JAVA_HOME/jre/lib
```

注：修改文件后要想马上生效还要运行
```
source /etc/profile
```
不然只能在下次重进此用户时生效。

2. 在用户目录下的.bash_profile文件中增加变量【对单一用户生效（永久的）】

用VI在用户目录下的.bash_profile文件中增加变量，改变量仅会对当前用户有效，并且是“永久的”。

例如：编辑guok用户目录（/home/guok）下的.bash_profile
```
vi /home/guok/.bash.profile
```
添加如下内容：
```
export CLASSPATH=./JAVA_HOME/lib;$JAVA_HOME/jre/lib
```

注：修改文件后要想马上生效还要运行
```
source /home/guok/.bash_profile
```
不然只能在下次重进此用户时生效。

3. 直接运行export命令定义变量【只对当前shell（BASH）有效（临时的）】

在shell的命令行下直接使用 \[export 变量名=变量值]

定义变量，该变量只在当前的shell（BASH）或其子shell（BASH）下是有效的，shell关闭了，变量也就失效了，再打开新shell时就没有这个变量，需要使用的话还需要重新定义。
### 三、PATH声明，其格式为:
```
PATH=$PATH:<PATH 1>:<PATH 2>:<PATH 3>:------:<PATH N>
```

你可以自己加上指定的路径，中间用冒号隔开。环境变量更改后，在用户下次登陆时生效。

如果想立刻生效，则可执行下面的语句：
```
source .bash_profile
```

需要注意的是，最好不要把当前路径”./”放到PATH里，这样可能会受到意想不到的攻击。

完成后，可以通过$ echo $PATH查看当前的搜索路径。这样定制后，就可以避免频繁的启动位于shell搜索的路径之外的程序了。