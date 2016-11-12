---
title: Head First Stanford NLP (3)
categories: "algorithm"
date: "2016-03-31"
---

(深入浅出Stanford NLP 可视化篇) 本文介绍与Stanford NLP相关的一些可视化工具。<!--more-->

前面进阶篇主要介绍了Stanford NLP中的`ParserAnnotator`和`DependencyParseAnnotator`的使用。前面也提到过，前者是用来得到短语结构树，后者是用来得到依存结构树，这两个工具都在Stanford Parser中，所以如果只是需要这两个工具的话可以直接使用Stanford Parser，而不需要使用完整的CoreNLP。本文主要介绍这两种树相关的可视化工具的使用。

1.短语结构树的可视化
我们经常能够看到如下图所示的句子的短语结构树，这个是如何生成的呢？
![img](/images/stanfordnlp_tree.png)

实际上，Stanford Parser中就自带了这个工具，[Stanford Parser传送门](http://nlp.stanford.edu/software/lex-parser.shtml)。
下载之后解压即可得到Stanford Parser的几个相关的jar和一些数据、模型等文件，其中`lexparser-gui.sh`文件就是我们要找的可视化工具。
执行`./lexparser-gui.sh`即可看到操作界面，然后选择文件以及parser的model文件，最后点击Parse即可看到结果。
model文件的选择可以直接选择model.jar然后按照提示选择其中的文件，也可以先将model.jar解压，然后直接选择其中的文件。

![img](/images/parser.png)

另一个采用`d3.js`制作的可视化短语结构树的工具，网址[http://nlpviz.bpodgursky.com/home](/http://nlpviz.bpodgursky.com/home)

![img](/images/corenlpviz.png)

2.依存结构树的可视化
(0)[Stanford CoreNLP Server](/blog/2016/03/30/Stanford-NLP/)
依存结构树的可视化工具可以使用上篇中提到的本地部署的server，它使用brat工具来进行可视化。

![img](/images/stanfordnlp_online.png)

(1)[GrammarScope](http://grammarscope.sourceforge.net/)
它的使用方式是先要将parser或者corenlp相关的jar复制到grammarscope的根目录的`stanford`目录下，然后进入工具的设置界面，在`Provider`中选择`Parser`或者`CoreNLP`，其他的可能需要配置的就是model文件，然后打开包含句子的文件即可看到结果。

![img](/images/grammarscope.png)

(2)[DependenSee](http://chaoticity.com/dependensee-a-dependency-parse-visualisation-tool/)
它的使用方式是引入`DependenSee.2.0.5.jar`，写段代码即可将结果输出到图片文件中，但是对中文支持较差。

![img](/images/DependenSee.png)

(3)[Dependency Viewer](http://nlp.nju.edu.cn/tanggc/tools/DependencyViewer.html)
国产的一个用于可视化显示、编辑、统计CONLL格式依存树的工具，可惜只有Windows版本。

![img](/images/dependencyViewer.png)

(4)其他工具
国内很多中文自然语言处理工具都具有在线演示功能，一般也都包括了依存句法结果的可视化。
哈工大语言技术平台演示地址：[http://www.ltp-cloud.com/demo/](http://www.ltp-cloud.com/demo/)
BosonNLP在线演示地址：[http://bosonnlp.com/demo](http://bosonnlp.com/demo)

ok，enjoy！
