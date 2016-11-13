---
title: "Bootcamp an open source Django site"
date: "2014-09-16"
tags: ["dev"]
---
一个Django开发的开源网站Bootcamp <!--more-->

最近接了一个项目，用Django开发一个网站，于是打算看看用Django开发的开源网站，推荐一个网站 [djangosites](https://www.djangosites.org/with-source/)，上面有大量用django开发的网站源码。最后我找到了Bootcamp，一个包含了Feed、Article和QA三部分的社交网站，界面简洁大方，功能基本齐全，相当适合我这个新手拿来学习

试用Bootcamp网址： [http://trybootcamp.vitorfs.com/](http://trybootcamp.vitorfs.com/)

Bootcamp源码： [https://github.com/vitorfs/bootcamp](https://github.com/vitorfs/bootcamp)

Bootcamp安装说明： [https://github.com/vitorfs/bootcamp/wiki/Installing-and-Running-Bootcamp](https://github.com/vitorfs/bootcamp/wiki/Installing-and-Running-Bootcamp)

安装过程很简单，以下是我安装过程中遇到的一些问题和关键步骤：

(1)安装psycopg2报错 `Error: pg_config executable not found.`

参考网址： [http://stackoverflow.com/questions/11618898/pg-config-executable-not-found](http://stackoverflow.com/questions/11618898/pg-config-executable-not-found)

解决方案：`brew install postgresql`

(2)新建文件`.env`，配置数据库为mysql

```python
DEBUG=True
SECRET_KEY='mys3cr3tk3y'
DATABASE_URL='mysql://root:@localhost/bootcamp'  
```

(3)同步数据库，运行 `python manage.py syncdb`

```
hujiawei-MacBook-Pro:bootcamp hujiawei$ python manage.py syncdb
Syncing...
Creating tables ...
Creating table auth_permission ...

You just installed Django's auth system, which means you don't have any superusers defined.
Would you like to create one now? (yes/no): yes
Username (leave blank to use 'hujiawei'): hujiawei
Email address: ...
Installing indexes ...
Installed 0 object(s) from 0 fixture(s)

Synced:
 > django.contrib.auth ...

Not synced (use migrations):
 -
(use ./manage.py migrate to migrate these)
```

(4)除去项目中的google痕迹，加速页面的加载

`base.html`中删除`ga.js`

```html
<!--
<script src="{{ STATIC_URL }}js/ga.js"></script>
-->
```

`static/css/bootcamp.css`中修改字体库url，改成360的CDN

```html
@import url(http://fonts.useso.com/css?family=Audiowide);
```

网站界面如下：

![image](/images/others/bootcamp.png)
