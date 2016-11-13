---
title: Head First Stanford NLP (4)
tags: ["algorithm"]
date: "2016-04-01"
---

(深入浅出Stanford NLP 深入篇) 本文介绍与Stanford CoreNLP源码相关的内容。<!--more-->

前面我们介绍过Stanford CoreNLP的server的本地搭建，但是在使用它对中文句子进行操作的时候一直显示不出效果，所以有必要通过源码研究下StanfordCoreNLPServer的具体实现，这样就可以知道如何对它进行配置。

#### 1. 导入CoreNLP项目到Eclipse中
Stanford CoreNLP的Github地址：[https://github.com/stanfordnlp/CoreNLP](https://github.com/stanfordnlp/CoreNLP)
从github上的源码和从[Stanford CoreNLP](http://stanfordnlp.github.io/CoreNLP/)上下载的3.6.0版本的zip文件解压之后的结果有很大差异，前者根目录下有`build.gradle`（Gradle）和`build.xml`（Ant）可供使用的build文件，但是后者根目录下是`build.xml`（Ant）和`pom.xml`文件（Maven）。

![img](/images/corenlp_download.png)

经过我的尝试，我发现使用Eclipse通过打开Ant的`build.xml`文件导入CoreNLP项目是最方便的，当然如果你熟悉Gradle或者Maven的话也可以使用其他的方式，貌似不太容易成功。用Eclipse导入CoreNLP的操作方式如下图所示：

![img](/images/corenlp_project.png)

导入完成之后找到`edu.stanford.nlp.pipeline.StanfordCoreNLPServer`点击右键运行即可将server跑起来了，默认是9000端口。

#### 2. 对CoreNLP进行中文支持的配置
通过阅读`StanfordCoreNLPServer`可以发现，它除了支持使用`-port`来配置启动的端口外，还支持使用`-props`来配置默认的属性文件。

在`edu.stanford.nlp.pipeline`目录下有一个对中文支持的配置文件`StanfordCoreNLP-chinese.properties`，内容如下，不过貌似当前最新版本的CoreNLP并没有`segment`这个annotator了，所以和它相关的配置并没有用，可以将其注释掉，`coref`相关的也可以注释掉如果不需要的话。

```
# Pipeline options - lemma is no-op for Chinese but currently needed because coref demands it (bad old requirements system)
annotators = segment, ssplit, pos, lemma, ner, parse, mention, coref

# segment
customAnnotatorClass.segment = edu.stanford.nlp.pipeline.ChineseSegmenterAnnotator

segment.model = edu/stanford/nlp/models/segmenter/chinese/ctb.gz
segment.sighanCorporaDict = edu/stanford/nlp/models/segmenter/chinese
segment.serDictionary = edu/stanford/nlp/models/segmenter/chinese/dict-chris6.ser.gz
segment.sighanPostProcessing = true

# sentence split
ssplit.boundaryTokenRegex = [.]|[!?]+|[ã]|[ï¼ï¼]+

# pos
pos.model = edu/stanford/nlp/models/pos-tagger/chinese-distsim/chinese-distsim.tagger

# ner
ner.model = edu/stanford/nlp/models/ner/chinese.misc.distsim.crf.ser.gz
ner.applyNumericClassifiers = false
ner.useSUTime = false

# parse
parse.model = edu/stanford/nlp/models/lexparser/chineseFactored.ser.gz

# coref
coref.sieves = ChineseHeadMatch, ExactStringMatch, PreciseConstructs, StrictHeadMatch1, StrictHeadMatch2, StrictHeadMatch3, StrictHeadMatch4, PronounMatch
coref.input.type = raw
coref.postprocessing = true
coref.calculateFeatureImportance = false
coref.useConstituencyTree = true
coref.useSemantics = false
coref.md.type = RULE
coref.mode = hybrid
coref.path.word2vec =
coref.language = zh
coref.print.md.log = false
coref.defaultPronounAgreement = true
coref.zh.dict = edu/stanford/nlp/models/dcoref/zh-attributes.txt.gz
```

很显然，如果希望Server支持中文的话就需要指定这些配置才行，但是中文的model文件自然是不能少的，不然会找不到相应的训练模型文件。从[Stanford CoreNLP](http://stanfordnlp.github.io/CoreNLP/)首页上下载chinese-model文件，然后将其添加到项目的build path中。最后在运行参数配置中输入下面的配置，同时将VM参数设置下，然后点击Run启动服务器。

![img](/images/corenlp_run.png)

(3)从源码角度解决问题
前面的操作看起来很成功，控制台输出了中文配置文件中的配置，也看到端口变成我们希望的8000，但是输入中文句子之后还是界面报错，为什么？
其实，如果你仔细debug下代码会发现，我们配置的中文配置文件的确是读取了，但是并没有最终传给StanfordCoreNLP的构造函数。
从源码中可以看出`StanfordCoreNLP`的`properties`来自`CoreNLPHandler`的`getProperties`方法，而`getProperties`方法是以`defaultProps`为基础根据请求的参数构建的新的properties，并没有接收从控制台传入的配置文件中的配置，那怎么让它接收那些配置呢？

解决方法很多很多，这里我是简单地将配置文件中的配置加入到`defaultProps`来实现，修改`StanfordCoreNLPServer`的构造函数，添加一个参数`Properties props`，并将props都加入到defaultProps中，最后修改main方法中的构造函数就行了。

```
#1.修改StanfordCoreNLPServer的构造函数
public StanfordCoreNLPServer(int port, int timeout, boolean strict, Properties props)

#2.在构造函数中添加一行代码
defaultProps = PropertiesUtils.asProperties(
        "annotators", "tokenize, ssplit, pos, lemma, ner, depparse, coref, natlog, openie",
        "coref.md.type", "dep",
        "inputFormat", "text",
        "outputFormat", "json",
        "prettyPrint", "false");

defaultProps.putAll(props); //添加这行代码，将props都加入到defaultProps中

#3.在StanfordCoreNLPServer的Main方法中修改一行代码
StanfordCoreNLPServer server = new StanfordCoreNLPServer(port, timeout, strict, props); //添加参数props
```

如果需要做依存结构句法分析的话，记得在中文配置文件中加上，否则加载的是英文的model文件，显示结果有误。

```
# depparse
depparse.model = edu/stanford/nlp/models/parser/nndep/CTB_CoNLL_params.txt.gz
```

重新运行StanfordCoreNLPServer即可看到下面的效果了，嘿嘿
![img](/images/corenlp_chinese.png)

如果不清楚的话，可以看我修改的代码的[提交记录](https://github.com/hujiaweibujidao/CoreNLP/commit/2182a24ad6512176ddcc61c4429cfd989f232953)。

还记得上篇提到的短语结构树的可视化工具Stanford Parser，它是内置于Stanford CoreNLP项目的，所以我们同样可以直接在项目里面右键运行，而且可以修改其中的配置，使得默认加载中文的parser，这样就不用每次选择parser了，对应的类是`edu.stanford.nlp.parser.ui.Parser`，感兴趣的可以尝试下。

OK，经过上面的几篇文章的折腾差不多对Stanford NLP有个了解了，剩下的就是根据自己的需求开发相应的NLP工具了。

最后的实践篇等我毕设写出来了再说，55555，从贵系毕业真是要跪了。。。

其他资源：

[使用CoreNLP进行中文分词的实践示例](https://blog.sectong.com/blog/corenlp_segment.html)
