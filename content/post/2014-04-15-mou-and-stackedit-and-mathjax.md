---
title: "Mou and StackEdit and Mathjax"
date: "2014-04-15"
tags: ["dev"]
---
本文记录使用Mou和Stackedit中出现的一些问题，使其能够正常渲染带数学公式的文章<!--more-->

如果Mou渲染Math公式有问题的话，尝试在第一行加上如下js，表示让Mou去加载Mathjax的脚本

```js
<!-- import js for mathjax -->
<script src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=default"></script>
```

该链接指向的是Mathjax的js，用来渲染Math公式，Mou支持Mathjax。为了减轻Octopress加载的负担，可以只在需要使用Mathjax的博文中添加一行js即可，不需要将它放在自定义的`head.html`文件中。

不知为何，最近加上了这句Math公式还是没有显示出来，貌似Mou并没有去加载这个js的样子，于是我尝试在浏览器中直接访问，将这个js中的所有内容复制进来，这样Mou有显示正常了，数学公式都没有问题！如果你不能访问，放心，我已经将这个js的源码放在[这个Gist中](https://gist.github.com/hujiaweibujidao/11146289)。

如果还是不行的话，那么建议使用[stackedit](https://stackedit.io/ )，感谢@beader的建议！还有一个问题是stackedit是在线编辑的，图片要保存到Google Driver中(或者有个特定的网址)，另外，它和Mou中内置的MathJax的渲染解析工具略有不同，例如对于行内Math公式的插入方式不同，Stackedit是以`$`为行内Math公式为标示符，Mou貌似不存在插入行内Math公式的方式，这时候可以在Mou中的Markdown文档中添加下面的代码让它支持行内Math公式。

```js
<!-- mathjax config similar to math.stackexchange -->
<script type="text/x-mathjax-config">
MathJax.Hub.Config({
  jax: ["input/TeX", "output/HTML-CSS"],
  tex2jax: {
    inlineMath: [ ['$', '$'] ],
    displayMath: [ ['$$', '$$']],
    processEscapes: true,
    skipTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code']
  },
  messageStyle: "none",
  "HTML-CSS": { preferredFont: "TeX", availableFonts: ["STIX","TeX"] }
});
</script>
<script src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML" type="text/javascript"></script>
```

测试：The *Gamma function* satisfying $\Gamma(n) = (n-1)!\quad\forall
n\in\mathbb N$ is via the Euler integra

$$
\Gamma(z) = \int_0^\infty t^{z-1}e^{-t}dt\,.
$$

如果文档是要放在Octopress中使用的话，推荐按照[这位博主的方式修改](http://blog-jfttt.herokuapp.com/blog/2013/12/26/add-latex/)，使用kramdown代替默认的rdiscount，然后在`footer.html`中加入上面的脚本内容。

>**过去的内容，也许不对...**   
>[但是，它还是存在些问题，关于inline Math公式的问题，推荐将Octopress中的Markdown引擎换成Kramdown，[参考教程](http://yanping.me/cn/blog/2012/03/10/octopress-with-latex/)，另外，使用inline Math和使用block Math一样，都是两个连着的美元符。
>bug：我发现在Math公式中写入`|`，即取绝对值符号的话会影响排版，暂时想到的解决方案是转义，换成`\\|`，它会换成双竖线，即取2范数的符号，不少情况下，不影响思考，嘿嘿。]

=== At Last ===

我现在的做法是，做一般的作业使用Mou，按照上面的方式肯定有一个可以，完成作业没有问题。
写Octopress博客中的文章用StackEdit，行内Math用`$`(某些情况下可以，但是有些情况下不行，不行的话还是使用`$$`，Kramdown支持`$$`形式的行内公式)，其他形式用`$$`。Stackedit支持直接将文档publish到Github的某个项目的某个分支下的某个文件夹中，文件名自己命名。如下图所示：

![image](/images/stackedit_publish.png)

注意，如果该目录下有相同名称的文件的话，会被覆盖掉，利用这个方式我们就可以update以前的文章啦！当然，Stackedit在你publish了一次之后会记住publish的目标位置，以后每次更新之后publish都会publish到那个目标位置。

那如果使用Stackedit打开一个Octopress中已经写好了的文章呢？我使用的方法是`Import from URL`功能，其中的`URL`是该Markdown文档的URL，可以在Github中找到并打开那个文档，点击`Raw`按钮就会进入这份文档的源代码页面，复制该页面的URL即可，比如这篇文章的URL是

```
https://raw.githubusercontent.com/hujiaweibujidao/hujiaweibujidao.github.io/source/source/_posts/2014-04-15-flying-on-mac.markdown
```

修改完了使用上面的方式覆盖即可。要让Octopress对这个页面进行重新渲染还需要在本地执行下面代码

```
git pull
rake generate
rake deploy
```

可以按照[Make Your Octopress Easy](/blog/2013/11/18/make-your-octopress-easy/)的方式建立一个shell脚本简化处理流程，方法略过。
