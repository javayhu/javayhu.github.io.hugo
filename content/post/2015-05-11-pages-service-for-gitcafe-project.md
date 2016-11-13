---
title: "Pages Service for GitCafe Project"
date: "2015-05-11"
tags: ["dev"]
---
本文简单介绍如何在GitCafe的项目中使用Pages服务 <!--more-->

参考网址：[WIKI for GitCafe Pages](https://gitcafe.com/GitCafe/Help/wiki/Pages-%E7%9B%B8%E5%85%B3%E5%B8%AE%E5%8A%A9#wiki)


1.在GitCafe上新建项目，假设名为`resourcerepository`

2.克隆项目到本地，并进入该项目目录

```
git clone git@gitcafe.com:hujiawei/resourcerepository.git
```

3.新建分支`gitcafe-pages`，然后提交该分支

```
git checkout -b gitcafe-pages
git push -u origin gitcafe-pages
```

4.添加一个测试文件，例如`index.html`

```
echo "Hello, hujiawei" > index.html
```

5.提交测试文件到GitCafe

```
git add index.html
git commit -m "test"
git push
```
6.通过访问`username.gitcafe.io/projectname/`，例如`http://hujiawei.gitcafe.io/resourcerepository/`即可看到页面显示`Hello, hujiawei`
