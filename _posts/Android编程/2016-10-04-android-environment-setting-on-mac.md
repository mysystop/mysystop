---
layout: post
title: 在mac上Android环境变量设置
categories: Android编程
description: Android环境变量设置,解决错误SDK location not found.
keywords: Android,环境变量,environment,sdk.dir,react-native,ANDROID_HOME,SDK location not found,local.properties
---
### 报错信息
SDK location not found. Define location with sdk.dir in the local.properties file or with an ANDROID_HOME environment variable

### 出错原因

错误信息提示说明环境变量ANDROID_HOME没有设置好,无法找到SDK的位置,则解决方案只要设置一下Android的环境变量,问题得到解决.

### 解决方案

1. 打开终端,输入 sudo ~/.bash_profile ,编辑配置文件
内容如下:
   ```
      export ANDROID_HOME=~/Library/Android/sdk
      export PATH=$PATH:$ANDROID_HOME/platform-tools
      export PATH=${PATH}:${ANDROID_HOME}/tools
   ```
按ESC键,:wq 保存退出vi.

2. 让新的环境变量生效,命令行输入:
   ```
   source ~/.bash_profile

   ```
3. 测试是否生效,命令行输入:
   ```
   adb

   ```
   如果有输出 adb 的帮助信息,则说明设置成功.