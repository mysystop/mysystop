---
layout: download
title: ntwdblib.dll文件下载
categories: php
description: ntwdblib.dll文件下载，解决找不到ntwdblib.dll的问题
keywords: ntwdblib.dll,mssql,php,php_mssql,php链接mssql
---
ntwdblib.dll文件下载，解决找不到ntwdblib.dll的问题

ntwdblib.dll控件常规安装方法（仅供参考）：

* 如果在运行某软件或编译程序时提示缺少、找不到ntwdblib.dll等类似提示，您可将从脚本之家下载来的ntwdblib.dll拷贝到指定目录即可
  (一般是system系统目录或放到软件同级目录里面)，或者重新添加文件引用。 
* 您从我们网站下载下来文件之后，先将其解压(一般都是rar压缩包), 然后根据您系统的情况选择X86/X64，X86为32位电脑，
  X64为64位电脑。默认都是支持32位系统的， 如果您不知道是X86还是X64，您可以看这篇文章。 
* 根据软件情况选择文件版本。
 此步骤比较复杂，如果是Windows的dll文件， 
    版本号以5.0开头的或含有 nt 一般是windows2000的文件。 
    版本号以5.1开头的或含有 xp、xpsp1、xpsp2、xpsp3 信息的一般是windowsXP的文件。 
    版本号以6.0开头的或含有 longhorn、vista 信息的一般是windowsVista的文件。 
    版本号以6.1开头的或含有 win7 信息的一般是windows7的文件。 如果不是windows的dll文件，则需要灵活查看版本号、描述、网友提供的信息、以及相关dll的版本号去判断。 
* 直接拷贝该文件到系统目录里：
    1、Windows 95/98/Me系统，将ntwdblib.dll复制到C:\Windows\System目录下。
    2、Windows NT/2000系统，将ntwdblib.dll复制到C:\WINNT\System32目录下。
    3、Windows XP/WIN7/Vista系统(64位系统对应64位dll文件，32位系统对应32位dll文件)，将ntwdblib.dll复制到C:\Windows\System32目录下。
    4、如果您的系统是64位的请将32位的dll文件复制到C:\Windows\SysWOW64目录具体的方法可以参考这篇文章：win7 64位旗舰版系统运行regsvr32.exe提示版本不兼容
* 打开"开始-运行-输入regsvr32 ntwdblib.dll"，回车即可解决。希望脚本之家为您提供的ntwdblib.dll对您有所帮助。


通过MYSYS博客下载dll的朋友，可将下面的代码保存为“注册.bat“，放到dll文件同级目录(只要在同一个文件夹里面有这两个文件即可)，双击注册.bat，就会自动完成ntwdblib.dll注册(win98不支持)。
下面是系统与dll版本对应的注册bat文件(64位的系统对应64位dll文件，32位系统对应32位的dll文件，如果64位的系统安装32位的dll文件，请将下面的system32替换为SysWOW64即可。)
注册.bat 内容如下:

```bat
@echo 开始注册
copy ntwdblib.dll %windir%\system32\
regsvr32 %windir%\system32\ntwdblib.dll /s
@echo ntwdblib.dll注册成功
@pause

```

点击这里下载[ntwdblib.zip][1]

[1]: http://www.mysys.top/files/dll/ntwdblib.zip