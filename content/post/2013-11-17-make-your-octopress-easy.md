---
title: "Make Your Octopress Easy"
date: "2013-11-18"
tags: ["dev"]
---
写了几个`shell`脚本让你在Octopress上写博客更加轻松些，至少让我轻松了很多，哈哈哈。 <!--more-->

我特别头疼于类似新建文章`new_post["postname"]`这些个命令，那个下划线可能会记成短破折线，时间长了我可能就不记得这个命令了，当然，如果你是ruby开发者那就肯定不会这样啦，我这年龄大了，记忆力不行了，很难记住那么多的命令啦，还有就是我希望只要打开Terminal就可以调用这些命令，而不用每次切换目录，而且每次我新建了一个文章之后，Mou能够直接启动并打开这个新建的文章让我编辑，想想，这个世界是不是美好多了？哈哈哈

操作步骤：

**[1]新建环境变量`OCTOPRESS_HOME`，它是你的octopress的根目录，并添加到`PATH`中**

[下面是我在Mac上的操作，其他系统自行修改]

```java
sudo nano ~/.bash_profile  #打开并修改.bash_profile文件，下面两行是在该文件中的修改
export OCTOPRESS_HOME=/Users/hujiawei/git/octopress  #添加OCTOPRESS_HOME变量
export PATH=${PATH}:${OCTOPRESS_HOME}  #添加到path中
source ~/.bash_profile  
echo $OCTOPRESS_HOME  #验证是否变量存在
echo $PATH  #验证path是否设置成功
```

**[2]编写几个`shell`脚本，放在`OCTOPRESS_HOME`目录下，作用分别如下：**

- gen：等价于`rake generate`操作

```
#! /bin/bash
path=$OCTOPRESS_HOME
cd "$path"
#pwd
rake generate
echo "generate ok"
```

- dep：等价于`rake deploy`操作

```
#! /bin/bash
path=$OCTOPRESS_HOME
cd "$path"
#pwd
rake generate
rake deploy
echo "generate and deploy ok"
```

- pre：等价于`rake preview`操作

[注意，这里我是在子线程中启动预览的，所以你按下了Ctrl+C会也不会把预览给终止了，是不是瞬间又感觉这个世界又美好了很多啊，哈哈]

```
#! /bin/bash
path=$OCTOPRESS_HOME
cd "$path"
#pwd
#rake watch
rake preview &
#echo "watch and preview ok"
```

- gmit：等价于`git add/commit/push`几个操作的组合

```
#! /bin/bash
if [ $# -ne 1 ]
then
    echo "Usage - gmit  message"
    exit 1
fi
path=$OCTOPRESS_HOME
cd "$path"
#pwd
git add .
git commit -m "$1"
git push origin source
echo "git commit and push ok"
```

- newpost：等价于`new_post[""] + open Mou`操作组合

```
#! /bin/bash
if [ $# -ne 1 ]
then
    echo "Usage -newpost  postname"
    exit 1
fi
path=$OCTOPRESS_HOME
cd "$path"
#pwd
filepath=`rake new_post["$1"]`
#echo "$filepath"
#Creating new post: source/_posts/2013-11-18-test5.markdown
OLD_IFS="$IFS"
IFS=" "
arr=($filepath)
filepath=${arr[3]}
IFS="$OLD_IFS"
postpath="$path/$filepath"
#echo "$postpath"
#open Mou with the file
open -a Mou $postpath
```

- newpage：等价于`new_page[""] + open Mou`操作组合

```
#! /bin/bash
if [ $# -ne 1 ]
then
    echo "Usage - newpage  pagename"
    exit 1
fi
path=$OCTOPRESS_HOME
cd "$path"
echo "$path"
filepath=`rake new_page["$1"]`
echo "$filepath"
#Creating new page: source/projects/index.markdown
OLD_IFS="$IFS"
IFS=" "
arr=($filepath)
filepath=${arr[3]}
IFS="$OLD_IFS"
postpath="$path/$filepath"
echo "$postpath"
#open Mou with the file
open -a Mou $postpath
```

**[3]使用`chmod 777 xxx`修改脚本的权限，测试执行下**

```
cd $OCTOPRESS_HOME
chmod 777 gen  #其他文件类似
chmod 777 pre
chmod 777 dep
chmod 777 gmit
chmod 777 newpost
chmod 777 newpage
gen
newpost "test new post" #当这条命令完成生成了Markdown文件之后，你会发现Mou闪电般的将文件打开了，等着你输入呢！
```

OK！Enjoy the world of Octopress！
