---
title: "Fix Homebrew for OS X 10.10 Yosemite"
date: "2015-06-12"
categories: "dev"
---
本文主要解决系统升级到OS X 10.10 Yosemite后Homebrew出现的一些问题。<!--more-->

不记得自己是什么时候将系统升级到Yosemite了，后来也不记得怎么配置系统的环境了，最近发现Homebrew总是出现问题，运行`brew update`总是报错，于是今天查了下文档解决了下这个问题。

首先的报错内容如下

```python
hujiawei-MBPR:~ hujiawei$ brew update
error: Your local changes to the following files would be overwritten by merge:
	Library/Formula/jasper.rb
	Library/brew.rb
Please, commit your changes or stash them before you can merge.
Aborting
Error: Failure while executing: git pull -q origin refs/heads/master:refs/remotes/origin/master
```

好吧，这个时候我才意识到Homebrew在本地实际上是一个git repository，于是进入`/usr/local/`中进行查看

```
hujiawei-MBPR:~ hujiawei$ ls -al /usr/local
total 152
drwxrwxr-x   25 root      admin    850  6 12 21:35 .
drwxr-xr-x@  14 root      wheel    476  6  7 00:19 ..
-rw-r--r--@   1 hujiawei  admin  21508  5 20  2014 .DS_Store
drwxr-xr-x   14 hujiawei  admin    476  6 12 22:32 .git
-rw-r--r--    1 hujiawei  admin    301  6 12 21:35 .gitignore
-rw-r--r--    1 hujiawei  admin    261  6 12 21:35 .yardopts
-rw-r--r--    1 hujiawei  admin   3161  6 12 21:35 CODEOFCONDUCT.md
-rw-r--r--    1 hujiawei  admin   1103  6 12 21:35 CONTRIBUTING.md
drwxr-xr-x   32 hujiawei  admin   1088  6  7 09:20 Cellar
drwxr-xr-x    4 hujiawei  admin    136 10 17  2014 Frameworks
-rw-r--r--    1 hujiawei  admin   1241  6 12 21:35 LICENSE.txt
drwxr-xr-x   13 hujiawei  admin    442  6 12 21:35 Library
-rw-r--r--    1 hujiawei  admin   2121  6 12 21:35 README.md
-rw-r--r--    1 hujiawei  admin  23801  6 12 21:35 SUPPORTERS.md
drwxr-xr-x  253 hujiawei  admin   8602  6 12 21:35 bin
drwxr-xr-x    4 hujiawei  admin    136 10 26  2014 djcelery
drwxr-xr-x    4 hujiawei  admin    136 10 17  2014 etc
drwxr-xr-x   82 hujiawei  admin   2788  4 15 23:48 include
drwxr-xr-x  238 hujiawei  admin   8092  4 15 23:48 lib
drwxr-xr-x    5 hujiawei  admin    170 10 17  2014 man
lrwxr-xr-x    1 root      wheel     27  2  1 13:46 mysql -> mysql-5.6.11-osx10.7-x86_64
drwxr-xr-x   17 root      wheel    578 10 17  2014 mysql-5.6.11-osx10.7-x86_64
drwxr-xr-x   31 hujiawei  admin   1054 10 17  2014 opt
drwxr-xr-x   20 hujiawei  admin    680  6  6 21:35 share
drwx------    3 hujiawei  admin    102 10 17  2014 var
```

也不记得之前为什么改了其中两个Ruby文件，所以这里直接使用`git checkout -- <file>`来覆盖掉本地的修改，完了之后再次执行`brew update`，但是，接着还是报错，内容是如下

```
hujiawei-MBPR:bin hujiawei$ brew update
/usr/local/bin/brew: /usr/local/Library/brew.rb: /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby: bad interpreter: No such file or directory
/usr/local/bin/brew: line 26: /usr/local/Library/brew.rb: Undefined error: 0
```

发现原来Ruby环境有问题了，原因是这样的，以前Mac系统中Ruby的版本是1.8，而Yosemite中内置的Ruby版本是2.0，所以找不到1.8版本的Ruby，所以需要修改`brew.rb`文件修改Ruby的路径。

参考网址[Fix Homebrew for OS X 10.10 Yosemite](http://jcvangent.com/fixing-homebrew-os-x-10-10-yosemite/)

操作如下：

(1)打开文件`/usr/local/Library/brew.rb`

(2)修改第一行，把`1.8`改成`Current`就好啦

```
 #!/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby -W0

/将上面这行改成下面这行 ===>

#!/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby -W0
```

(3)然后回到`/usr/local`目录，提交本地修改，之后再执行`brew update`即可

这样Homebrew应该没啥问题了，哈哈

2016年9月更新

今天执行`brew update`又报错，内容如下
```
error: insufficient permission for adding an object to repository database .git/objects
fatal: failed to write object
fatal: unpack-objects failed
Error: Failure while executing: git pull -q origin refs/heads/master:refs/remotes/origin/master
```

已经很久没有更新brew了，更加不记得这段日子干了啥。可以尝试下面的操作，进入到`/usr/local`目录，执行`git pull`，然后肯定会有冲突出现，因为上面我们修改了`Library/brew.rb`文件，只要解决这个冲突再执行`brew update`就好了。从打印输出的内容来看，brew的变化很大。

