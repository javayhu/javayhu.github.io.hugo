---
title: "Hello Octopress"
date: "2013-11-17"
categories: "dev"
---
Hello world! Hello Octopress! <!--more-->

曾经因为很多问题的答案都在[**博客园**](http://www.cnblogs.com)上，于是我在那里驻扎了，但是，它的广告让我不能忍！
后来因为[**点点博客**](http://www.diandian.com)的小清新我瞬间就爱上了它，于是我搬家了，但是，它的冷清让我想要离开！
再后来[**Wordpress**](http://wordpress.com)进入了我的眼帘，苦于没有host，只好在BAE上安营，但是，它的龟速简直让我发指！
最后我终于走进了我一直忽视了的[**Octopress**](http://octopress.org/)，那一瞬间，我才发现，这才是我想要的！这才是我想要的博客！

> A blogging framework for hackers.         -- Parker Moore

今天从早上开始一直到晚上终于把Octopress搭建和配置好了，好开心啊有木有！
下面介绍安装过程：[不是很轻松，但是也不会很难哟！]
安装步骤如下：

[安装rbenv和ruby](http://octopress.org/docs/setup/rbenv/)
请确保ruby版本是1.9.3以上！我试过，如果版本低的话会出错，但是如果版本很高的话也有可能出错(我试过1.9.3-p2xx)，建议就安装1.9.3-p0，也可以使用[rvm](http://octopress.org/docs/setup/rvm/)来管理ruby版本，我两个都试过了，推荐使用rbenv。

```
brew update
brew install rbenv
brew install ruby-build
rbenv install 1.9.3-p0
rbenv rehash
rbenv global 1.9.3-p0  #建议增加这句修改系统全局的ruby版本
ruby --version  #查看系统ruby版本
```

[注：如果install 1.9.3-p0时报错，提示llvm不行，需要安装gcc时按照提示的命令执行即可：`brew tap homebrew/dupes ; brew install apple-gcc42`]

[安装Octopress](http://octopress.org/docs/setup/)
这部分耗时会长一些，其中的octopress目录名称可以随便修改，例如myblog等，`gem list`命令可以查看已经安装好了的依赖包，`rake install`就类似`make install`进行安装(Octopress的主题)，一定要确保这里执行的命令都是正确执行了的，否则后面可能出错。

```
git clone git://github.com/imathis/octopress.git octopress
cd octopress
gem install bundler
rbenv rehash    # If you use rbenv, rehash to be able to run the bundle command
bundle install
rake install
```

[发布到Github上](http://octopress.org/docs/deploying/github/)
以前个人博客是在位于`http://username.github.com`这个域名下，现在改成了`http://username.github.io`，所以大家可以看到两种不同域名下的博客。另外，[Github Pages](https://help.github.com/categories/20/articles)分为两类，一类是个人或者组织的博客，另一类是项目的介绍博客，这里只介绍如果搭建不介绍后者，但是两者基本上相同。

首先新建repository，名称为`username.github.io`，其中`username`是你的github用户名，拷贝repository的SSH地址，类似`git@github.com:username/username.github.io.git`。然后执行下面代码``，它主要是进行以下操作(不难理解，我就不翻译了，原文看着舒坦，嘿嘿)：

- Ask for and store your Github Pages repository url.
- Rename the remote pointing to imathis/octopress from 'origin' to 'octopress'
- Add your Github Pages repository as the default origin remote.
- Switch the active branch from master to source.
- Configure your blog's url according to your repository.
- Setup a master branch in the _deploy directory for deployment.

```
rake setup_github_pages #按照提示输入你的repository的SSH地址
rake generate #生成静态网页，记住，每次有修改之后都需要执行一次或者多次才能查看新的预览！
rake deploy  #发布网页，这里会提交代码到github
rake preview #本地预览，默认端口是4000，可以修改
git add .
git commit -m 'your message'
git push origin source  #一定记着要提交source下的内容
```

需要注意的是，如果你是Github新手的话，可能遇到`Permission denied (publickey)`，这说明你还没有添加key给当前用户，解决方案请参考[Error:Permission denied (publickey)](https://help.github.com/articles/error-permission-denied-publickey)和[Github help:Generating SSH Keys](https://help.github.com/articles/generating-ssh-keys)来为当前用户创建publickey，

通过命令`ssh -T billy.anyteen@github.com`可以查看Github是否识别当前用户，如果不能识别会返回`Permission denied (publickey)`，否则便是`Hi username! You've successfully authenticated, but GitHub does not # provide shell access.`

另外，极力推荐一个[Git的简明教程](http://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000)，作者廖雪峰是一位资深的开发者，著有畅销书籍《Spring 2.0核心技术与最佳实践》等，最近又推出了Python简明教程，非常实用！

大功告成！

① 大致介绍下Octopress的目录结构(摘自[小明明s à domicile](http://www.dongwm.com/archives/qian-yi-octpressyi-ji-zi-ding-yi/))

```
├─ config.rb  #指定额外的compass插件
├─ config.ru  
├─ Rakefile   #rake的配置文件,类似于makefile,这个我修改了一些内容
├─ Gemfile    #bundle要下载需要的gem依赖关系的指定文件
├─ Gemfile.lock  #这些gem依赖的对应关系,比如A的x本依赖于B的y版本,我也修改了
├─ _config.yml  #站点的配置文件
├─ public/  #在静态编译完成后的目录,网站只需要这个目录下的文件树
├─ _deploy/  #deploy时候生成的缓存文件夹,和public目录一样
├─ sass/  #css文件的源文件,过程中会compass成css
├─ plugins/  #放置自带以及第三方插件的目录,ruby程序
│  └── xxx.rb
└─ source/  #这个是站点的源文件目录,public目录就是根据这个目录下数据生成的
   └─ _includes/
      └─ custom/  #自定义的模板目录,被相应上级html include
         └─ asides/  #边栏模板自定义模板目录
      └─ asides/  #边栏模板目录
      └─ post/  #文章页面相应模板目录
   └─ _layouts/  #默认网站html相关文件,最底层
   └─ _posts/  #新增以及从其它程序迁移过来的数据都存在这里
   └─ stylesheets/ #css文件目录
   └─ javascripts/  #js文件目录
```

② 一些配置内容

[关于如何配置Octopress](http://octopress.org/docs/configuring/)
[关于如何创建新的page或者post以及本地预览](http://octopress.org/docs/blogging/)
[关于如何修改主题和默认的样式](http://octopress.org/docs/theme/)
[Octopress支持的第三方主题下载和预览网站](http://opthemes.com/)
[关于侧边栏和主题的定制，添加新浪微博，多说评论，分类标签云等等](http://812lcl.github.io/blog/2013/10/26/octopressce-bian-lan-ji-ping-lun-xi-tong-ding-zhi/)

[注意，使用多说的话，shortname不是你的个人资料中的名称，而是新建的站点给定的！另外，对于[这里](http://havee.me/internet/2013-02/add-duoshuo-commemt-system-into-octopress.html)提到的升级问题，可以干脆直接删除data-title]

最有用的资料总能在这里找到：[Octopress的官方文档](http://octopress.org/docs/)

③ 关于[Jekyll](http://jekyllrb.com/docs/home/)

Octopress是基于Jekyll的，所以对Jekyll有一定的了解是很有必要的，Jekyll主页中记录了Jekyll的方方面面，最好是了解下Directory Structure，Configuration，Writing Posts，Creating Pages等等内容，这对后面的Octopress的使用会有很大帮助的。

④ 关于本地编写博客

对于Markdown编辑器，我觉得Mou可能不是最好的，但是，它是很精巧的！我简直爱不释手，希望之后能够在我的博客中实现数学公式的编辑，这样会很方便，哈哈

哦了，今天就到这里啦！哈哈哈，晚安，Octopress！^_^
