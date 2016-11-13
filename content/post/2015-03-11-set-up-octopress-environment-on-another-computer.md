---
title: "Set up Octopress environment on another computer"
date: "2015-03-11"
tags: ["dev"]
---
本文主要介绍如何在另一台电脑上搭建Octopress的环境。<!--more-->

最近换了机子，所以要在新机子上搭建Octopress的环境。本来因为新机整个系统环境就是和原来的一样可以不用配置的，可是不知道哪里弄错了，导致博客中写好的新内容不能push到remote。于是，又开始了一番折腾。<!--more-->

后来我发现下面的网址：[Octopress重装或者多台电脑上并行写作同步](http://94it.net/a/jingxuanboke/2014/0114/237386.html)

Octopress的git仓库(repository)有两个分支，分别是master和source。master存储的是博客网站本身，而source存储的是生成博客的源文件。

master的内容放在根目录的`_deploy`文件夹内，当你push源文件时会忽略，它使用的是`rake deploy`命令来更新的。

重装

如果本地已经配置过octopress，只是把octopress删掉重装。将source和master分支下的内容clone到本地即可(不需要再到官网上去clone全新的octopress)，具体作法：

1.首先将博客的源文件clone到本地的octopress文件夹内。

`$ git clone -b source git@github.com:username/username.github.com.git octopress`

2.将博客文件clone到octopress的_deploy文件夹内。

`$ cd octopress $ git clone git@github.com:username/username.github.com.git _deploy`

执行完这两步就OK了。注意这里第2步一定要，不然在`rake deploy`时会报错

`no such file or directory - _deploy`

如果是重新在一台全新的电脑上要和服务器上的进行同步，除了上面的操作之外，还需要：

```
cd octopress ruby --version # Should report Ruby 1.9.2
gem install bundler
bundle install
```

注意：这里不需要再次rake install 来安装默认主题，不然会把自定义的主题恢复到默认状态。

如果几台电脑上面都配置好了Otcopress，要在其中一台上写博客需要进行同步，更新source仓库即可。更新master并不是必须的，因为更改源文件之后还是需要`rake generate`，这个时候会自动进行 master更新。

```
$ cd octopress
$ git pull origin source # update the local source branch
$ cd ./_deploy
$ git pull origin master # update the local master branch
```
