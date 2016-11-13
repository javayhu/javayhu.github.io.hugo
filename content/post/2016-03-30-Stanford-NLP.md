---
title: Head First Stanford NLP (1)
tags: ["algorithm"]
date: "2016-03-30"
---

(深入浅出Stanford NLP 基础篇) 本文主要介绍Stanford NLP工具的基本使用方法。 <!--more-->

**因为毕设缘故需要调研下Stanford NLP工具，我发现这套工具非常强大而且非常有趣，但是目前网上的资源太少，抑或是很久未更新了，所以我打算写一个深入浅出Stanford NLP系列，简单介绍这套工具以及它的使用。**

Stanford NLP工具是一套完整的NLP工具，包括分词，词性标注，命名实体识别，依存句法分析等等，其中的项目很多，包括CoreNLP，Parser等等，在[这里](http://nlp.stanford.edu/software/)可以查看所有的项目软件。
本文主要介绍其中的一个核心项目CoreNLP，项目主页：[CoreNLP](http://stanfordnlp.github.io/CoreNLP/index.html)。

英文介绍：Stanford CoreNLP is an integrated framework. Its goal is to make it very easy to apply a bunch of linguistic analysis tools to a piece of text. A CoreNLP tool pipeline can be run on a piece of plain text with just two lines of code. It is designed to be highly flexible and extensible. With a single option you can change which tools should be enabled and which should be disabled. Stanford CoreNLP integrates many of Stanford’s NLP tools, including the part-of-speech (POS) tagger, the named entity recognizer (NER), the parser, the coreference resolution system, sentiment analysis, bootstrapped pattern learning, and the open information extraction tools. Its analyses provide the foundational building blocks for higher-level and domain-specific text understanding applications.

![img](/images/standfordnlp.png)

#### 1.如何使用CoreNLP工具

(1)通过Maven来使用
后面两个dependency是导入model用的，支持的语言包括英语、汉语、法语、西班牙语和德语。默认情况下CoreNLP是支持英语的，其他语言的model需要独立下载。

```
<dependency>
    <groupId>edu.stanford.nlp</groupId>
    <artifactId>stanford-corenlp</artifactId>
    <version>3.6.0</version>
</dependency>
<dependency>
    <groupId>edu.stanford.nlp</groupId>
    <artifactId>stanford-corenlp</artifactId>
    <version>3.6.0</version>
    <classifier>models</classifier>
</dependency>
<dependency>
    <groupId>edu.stanford.nlp</groupId>
    <artifactId>stanford-corenlp</artifactId>
    <version>3.6.0</version>
    <classifier>models-chinese</classifier>
</dependency>
```

(2)直接使用源码
源码地址：[https://github.com/stanfordnlp/CoreNLP](https://github.com/stanfordnlp/CoreNLP)
**如果不需要修改源码或者自行部署server的话，推荐采用Maven方式来使用CoreNLP。**
**直接使用源码需要使用JDK 8，源码的使用方式请看后文。**

#### 2.简单上手CoreNLP

(1)在命令行中的使用
[http://stanfordnlp.github.io/CoreNLP/cmdline.html](http://stanfordnlp.github.io/CoreNLP/cmdline.html)

(2)在代码中使用Stanford CoreNLP API
[http://stanfordnlp.github.io/CoreNLP/api.html](http://stanfordnlp.github.io/CoreNLP/api.html)

The backbone of the CoreNLP package is formed by two classes: Annotation and Annotator. Annotations are the data structure which hold the results of annotators. Annotations are basically maps, from keys to bits of the annotation, such as the parse, the part-of-speech tags, or named entity tags. Annotators are a lot like functions, except that they operate over Annotations instead of Objects. They do things like tokenize, parse, or NER tag sentences. Annotators and Annotations are integrated by AnnotationPipelines, which create sequences of generic Annotators. Stanford CoreNLP inherits from the AnnotationPipeline class, and is customized with NLP Annotators.

CoreNLP主要由`Annotator`和`Annotation`组成，前者就像是函数，包括tokenize、parse、ner等等，它们作用在annotations上；后者就是annotator的输出，一般都是map结构。`StanfordCoreNLP`类继承自`AnnotationPipeline`，并且可以对annotators进行自定义。代码示例：

```
// creates a StanfordCoreNLP object, with POS tagging, lemmatization, NER, parsing, and coreference resolution
Properties props = new Properties();
props.setProperty("annotators", "tokenize, ssplit, pos, lemma, ner, parse, dcoref");
StanfordCoreNLP pipeline = new StanfordCoreNLP(props);

// read some text in the text variable
String text = "..."; // Add your text here!

// create an empty Annotation just with the given text
Annotation document = new Annotation(text);

// run all Annotators on this text
pipeline.annotate(document);

// these are all the sentences in this document
// a CoreMap is essentially a Map that uses class objects as keys and has values with custom types
List<CoreMap> sentences = document.get(CoreAnnotations.SentencesAnnotation.class);

for (CoreMap sentence : sentences) {
    // traversing the words in the current sentence
    // a CoreLabel is a CoreMap with additional token-specific methods
    for (CoreLabel token : sentence.get(CoreAnnotations.TokensAnnotation.class)) {
        // this is the text of the token
        String word = token.get(CoreAnnotations.TextAnnotation.class);
        // this is the POS tag of the token
        String pos = token.get(CoreAnnotations.PartOfSpeechAnnotation.class);
        // this is the NER label of the token
        String ne = token.get(CoreAnnotations.NamedEntityTagAnnotation.class);
    }

    // this is the parse tree of the current sentence
    Tree tree = sentence.get(TreeCoreAnnotations.TreeAnnotation.class);

    // this is the Stanford dependency graph of the current sentence
    SemanticGraph dependencies = sentence.get(SemanticGraphCoreAnnotations.CollapsedCCProcessedDependenciesAnnotation.class);
}

// This is the coreference link graph
// Each chain stores a set of mentions that link to each other,
// along with a method for getting the most representative mention
// Both sentence and token offsets start at 1!
Map<Integer, CorefChain> graph = document.get(CorefCoreAnnotations.CorefChainAnnotation.class);
```

(3)在代码中使用Simple CoreNLP API
[http://stanfordnlp.github.io/CoreNLP/simple.html](http://stanfordnlp.github.io/CoreNLP/simple.html)
顾名思义，Simple CoreNLP API是相对于Stanford CoreNLP API比较简单的API操作方式。

```
import edu.stanford.nlp.simple.*;

public class SimpleCoreNLPDemo {
    public static void main(String[] args) {
        // Create a document. No computation is done yet.
        Document doc = new Document("add your text here! It can contain multiple sentences.");
        for (Sentence sent : doc.sentences()) {  // Will iterate over two sentences
            // We're only asking for words -- no need to load any models yet
            System.out.println("The second word of the sentence '" + sent + "' is " + sent.word(1));
            // When we ask for the lemma, it will load and run the part of speech tagger
            System.out.println("The third lemma of the sentence '" + sent + "' is " + sent.lemma(2));
            // When we ask for the parse, it will load and run the parser
            System.out.println("The parse of the sentence '" + sent + "' is " + sent.parse());
            // ...
        }
    }
}
```

使用Simple CoreNLP API有以下优缺点：
![img](/images/simplenlp_advatanges.png)

需要注意的是其中的第二个缺点：if a dependency parse is requested, followed by a constituency parse, we will compute the dependency parse with the **Neural Dependency Parser**, and then use the **Stanford Parser** for the constituency parse. If, however, you request the constituency parse before the dependency parse, we will use the **Stanford Parser** for both.

Simple CoreNLP API并不支持所有的Annotator，但是基本上都支持。
![img](/images/simplenlp_annotators.png)

#### 3.CoreNLP中的Annotators

(1)Annotator的列表：
![img](/images/stanfordnlp_annotators.png)

(2)Annotator之间存在着依赖关系，例如pos依赖tokenize，ner依赖pos等
![img](/images/stanfordnlp_annotatordp.png)

(3)每个Annotator的具体细节请参考[这里](http://stanfordnlp.github.io/CoreNLP/annotators.html)
在这里可以看到每个annotator的可选的配置参数，将这些参数放到前面示例代码中的`props`变量中即可完成配置。

#### 4.部署CoreNLP Server
参考网址：[http://stanfordnlp.github.io/CoreNLP/corenlp-server.html](http://stanfordnlp.github.io/CoreNLP/corenlp-server.html)

(1)Stanford NLP有个在线演示网址：[新地址](http://corenlp.run/) [旧地址](http://nlp.stanford.edu:8080/corenlp/process)
它使用了开源标注工具[brat](http://brat.nlplab.org/index.html)，该工具同样可以在本地进行部署。
![img](/images/stanfordnlp_online.png)

(2)本地部署
这个演示用的server可以在本地进行部署，方法很简单。
在下载的CoreNLP的根目录下，执行下面两条语句，前者表示添加当前目录下的所有jar到classpath中，后者用来启动StanfordCoreNLPServer，如果不给定端口的话，会跑在默认的9000端口，在浏览器中输入`http://localhost:9000/`即可看到效果。

```
# Set up your classpath. For example, to add all jars in the current directory tree:
export CLASSPATH="`find . -name '*.jar'`"

# Run the server
java -mx4g -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer [port?]
```

(3)使用StanfordCoreNLPClient可以连接server并得到处理结果

```
StanfordCoreNLPClient pipeline = new StanfordCoreNLPClient(props, "localhost", 9000, 2);
```

(4)如果要自行管理server的启动和停止的话，可以使用下面的命令

```
#1.启动，加载的model越多的话需要的内存越多，如果可以的话推荐8g
#The memory requirements of the server are the same as that of CoreNLP,
#though it will grow as you load more models (e.g., memory increases if you load both
#the PCFG and Shift-Reduce constituency parser models).
#A safe minimum is 4gb; 8gb is recommended if you can spare it.
nohup java -mx4g edu.stanford.nlp.pipeline.StanfordCoreNLPServer 1337 &

#2.停止
wget "localhost:9000/shutdown?key=`cat /tmp/corenlp.shutdown`" -O -
```

(5)server默认开启的annotator包括`-annotators tokenize, ssplit, pos, lemma, ner, depparse, coref, natlog, openie`，但是并不包括`parse`。

#### 5.其他语言的工具包

参考网址：[http://stanfordnlp.github.io/CoreNLP/other-languages.html](http://stanfordnlp.github.io/CoreNLP/other-languages.html)

OK，暂时介绍到这里，enjoy！
