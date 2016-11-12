---
title: Learning Git by Animations
categories: "dev"
date: "2016-05-20"
---
看到一个动画版的Git教程([网址](http://learngitbranching.js.org/?demo))，动画效果真心不错，所以学了下，本文是记录其中的几个重点部分。<!--more-->

### HEAD

HEAD 是当前提交记录的符号名称 -- 其实就是你正在其基础进行工作的提交记录。HEAD 总是指向最近一次提交记录，表现为当前工作树。大多数修改工作树的 Git 命令都开始于改变 HEAD 指向。HEAD 通常指向分支名（比如 bugFix）。你提交时，改变了 bugFix 的状态，这一变化通过 HEAD 变得可见。

**分离HEAD**：分离HEAD实际上就是指HEAD并没有指向某个分支，而是指向了某个具体的提交记录。

**相对引用**：把`^`跟在引用名后面，表示寻找指定提交记录的父提交。例如`master^`表示master的父提交，`master^^`表示master的父父提交。如果要移动多步，可以使用`~`加上数字快速移动。

`git branch -f master HEAD~3`命令的含义是（强制）移动 master 指向 HEAD 的第3级父提交。

如下图，左边执行`git checkout C1`，中间执行`git checkout master^`，右边执行`git checkout HEAD~4`

![img](/images/git_head.png)

**多个父提交**：当有多个父提交记录的时候，该如何移动HEAD呢？

如下图，左边执行`git checkout master^`，右边执行`git checkout master^2`

解析：注意区别`git checkout master^2`和`git checkout master^^`

![img](/images/git_head_move.png)



**常见的两个合并分支的操作git merge和git rebase。**

### git merge

**merge**产生一个特殊的提交记录，它包含两个唯一父提交，有两个父提交的提交记录本质上指 “我想把这两个父提交本身及它们的父提交集合都包含进来”。

解析：`git merge [branch]`操作是将指定的分支合并到当前的分支，该操作会创建一个新的提交记录，但是不会改变当前分支。

如下图所示，从左到右执行了`git merge bugFix`

![img](/images/git_merge.png)



### git rebase

**rebase** 是在分支之间合并工作的第二种方法。rebase 就是取出一系列的提交记录，“复制”它们，然后把它们放在别的地方。rebasing 的优势是可以创造更线性的提交历史。

解析：`git rebase [branch]`操作也是用来合并分支，但是合并时并不产生新的提交记录，而是复制那个分支下的所有提交记录加入到当前的分支下面，同样地，**该操作不改变当前分支**。

下图先执行了`git rebase master`，后执行了`git checkout master; git rebase bugFix`

![img](/images/git_rebase.png)

**快捷命令`git rabase [branch A] [branch B]`，将分支B上的提交记录rebase到分支A**。



**常见的两个撤销更改的操作git reset和git revert。**

### git reset

`git reset` 把分支记录回退到上一个提交记录来实现撤销改动。你可以认为这是在"重写历史"。`git reset` 往回移动分支，原来指向的提交记录好像重来没有提交过一样。

解析：`git reset`修改的只是本地分支，这种“改写历史”的方法对别人的远端分支是无效的！

下图执行了`git reset C1`

![img](/images/git_reset.png)



### git revert

为了撤销更改并*传播*给别人，我们需要使用 `git revert`。它会在在我们要撤销的提交记录后面增加一个新提交，而且新提交记录 `C2'` 引入的*更改*是刚好是用来撤销 `C2`这个提交的。

解析：`git revert`命令就是通过增加新提交来撤销之前的修改，而且能够将撤销传播给协作者。

下图执行了`git revert HEAD`

![img](/images/git_revert.png)



### git cherry-pick

如果你想选择性地将一些提交“复制”到你当前的位置的话，可以考虑使用`git cherry-pick`，命令形式：`git cherry-pick <Commit 1> <Commit 2> <...>`

解析：`git cherry-pick`方便我们选择所需的提交记录加入到某个分支下，使用`git rebase -i`启动rebase的交互模式也可以完成该任务，它甚至可以对提交记录进行排序！

下图执行了`git cherry-pick C2 C4`，从图中可以看出该命令并没有去合并分支。

![img](/images/git_cherry.png)



### git tag

`git tag`可以永远地指向某个特定的 commit，即使再有新的commit进来的时候，它都不会移动。你不可以 "checkout" 到 tag 指定的 commit上，tag 的存在就像是一个在 commit tree 上的表示特定讯息的一个锚。

解析：`git tag`就是给某个提交记录做个标签，就像是“里程碑”一样。

如下图，执行`git tag v1 C1`

![img](/images/git_tag.png)



### 远端分支

远端分支（remote branch）一般命名为`<remote name>/<branch name>`，而远端名称一般都是`origin`。本地的远端分支仅伴随远端更新而更新，这个分支上创建的提交不会更新该分支，只会使其分离HEAD。



### git fetch

`git fetch`命令用于从远端仓库获取数据，当我们更新远端的仓库时, 我们的远端分支也会更新并映射到最新的远端仓库。

解析：`git fetch`完成了两个操作：（1）下载本地仓库未包含的提交对象；（2）更新我们的远端分支点(例如`o/master`)。但是，它不会修改本地的状态，例如master分支。

![img](/images/git_fetch.png)

复杂的fetch操作：`git fetch origin <source>:<destination>`

从远端指定的source位置拉取到本地指定的destination位置

如下图，执行`git fetch origin foo~1:bar`

![img](/images/git_fetch_more.png)



###  git pull

如前面`git fetch`所示，它不会修改master分支的状态，但是一般我们在执行了`git fetch`命令之后都需要执行`git rebase o/master`或者`git merge o/master`来修改master分支的状态，于是就有了`git pull`命令，它是`git fetch + git merge`两个命令的缩写，而`git pull --rebase`是`git fetch + git rebase`两个命令的缩写。

如下图，执行了`git pull`或者是`git fetch`+`git merge o/master`两个命令

![img](/images/git_pull.png)

如下图，可以是执行了`git pull --rebase`+`git push`或者是`git fetch`+`git rebase o/master`+`git push`三个命令

![img](/images/git_pull_rebase.png)



### git push

`git push`命令将本地提交记录push到远端仓库中，它还会自动同步本地的远端分支。

如果远端仓库中存在超前于本地仓库的提交记录的话，那么git push操作会失败，此时需要先获取远端提交记录（`git fetch`），在本地仓库完成合并过程，才能push。

复杂的push操作：`git push origin <source>:<destination>`

如下图，执行`git push origin foo^:master`：

![img](/images/git_push.png)



### 远端跟踪

本地的master分支被设定为跟踪origin/master分支（它就是隐含的merge和push的目的地），它们之间的连接关系就是远端跟踪（remote tracking）。

你可以让做任意分支跟踪 `o/master`, 然后分支就会隐含 push 的 destination(`o/master`) 以及 merge 的 target (`o/master`)。这意味着你可以在分支 `foo` 上执行 `git push`， 将工作推送到远端的`master`。有两种方法设置：

（1）第一种就是通过远端分支检出一个新的分支，执行：

`git checkout -b foo o/master`

虽然分支名不叫master，但是在执行`git push`的时候foo分支上的提交记录会同步到远端仓库

（2）第二种追踪远端分支的方法就是使用选项 : `git branch -u`：

`git branch -u o/master foo`

这样 `foo` 就会跟踪 `o/master` 了. 如果你处于 foo 分支, 那么可以省略 foo：

`git branch -u o/master`

如下图，两种方式变化到图三殊途同归。

从图一变化到图三执行了`git checkout -b foo o/master; git commit; git push`；

从图二变化到图三执行了`git branch -u o/master; git commit; git push`。

![img](/images/git_remote_track.png)

零碎知识点：

`git checkout -b [branch name]` = `git branch [branch name]` + `git checkout [branch name]`


