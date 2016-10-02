---
layout: page
title: 书籍
description: 人越学越觉得自己无知
keywords: 维基, Wiki
comments: false
menu: 书籍
permalink: /book/
---

> 人丑需要多读书

<ul class="listing">
{% for book in site.book %}
{% if book.title != "Wiki Template" %}
<li class="listing-item"><a href="{{ book.url }}">《{{ book.title }}》</a>&nbsp;作者:{{ book.author }}&nbsp;{{ book.description }}</li>
{% endif %}
{% endfor %}
</ul>
