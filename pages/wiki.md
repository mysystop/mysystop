---
layout: page
title: 维基wiki
description: 人越学越觉得自己无知
keywords: 维基, Wiki
comments: false
menu: 维基
permalink: /wiki/
---

> 记多少快捷键会让脑袋爆炸呢？

<ul class="listing">
{% for wiki in site.wiki %}
{% if wiki.title != "Wiki Template" %}
<li class="listing-item"><a href="{{ wiki.url }}">{{ wiki.title }}</a>&nbsp;{{ wiki.description }}</li>
{% endif %}
{% endfor %}
</ul>
