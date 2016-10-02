---
layout: page
title: 关于
description: 软件工程师一枚
keywords: 郭二爷,老郭,软件工程师,Java工程师,PHP工程师,Golang工程师
comments: true
menu: 关于
permalink: /about/
---



## 坚信

* 熟能生巧
* 努力改变人生

## 联系

* GitHub：[@mysys](https://github.com/mysys)

## Skill Keywords

#### Software Engineer Keywords
<div class="btn-inline">
    {% for keyword in site.skill_software_keywords %}
    <button class="btn btn-outline" type="button">{{ keyword }}</button>
    {% endfor %}
</div>

#### Mobile Developer Keywords
<div class="btn-inline">
    {% for keyword in site.skill_mobile_app_keywords %}
    <button class="btn btn-outline" type="button">{{ keyword }}</button>
    {% endfor %}
</div>

#### Windows Developer Keywords
<div class="btn-inline">
    {% for keyword in site.skill_windows_keywords %}
    <button class="btn btn-outline" type="button">{{ keyword }}</button>
    {% endfor %}
</div>
