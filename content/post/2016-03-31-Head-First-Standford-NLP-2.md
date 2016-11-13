---
title: Head First Stanford NLP (2)
tags: ["algorithm"]
date: "2016-03-31"
---

(深入浅出Stanford NLP 进阶篇) 本文接着介绍Stanford NLP工具的使用方法。<!--more-->

从基础篇可以看出，Stanford NLP的使用主要是要熟悉其中的Annotator，所以本文以`ParserAnnotator`和`DependencyParseAnnotator`为例来介绍annotator的使用。前者是用来得到短语结构树，后者是用来得到依存结构树，这两个工具都在Stanford Parser中，所以如果只是需要这两个工具的话可以直接使用Stanford Parser，而不需要使用完整的CoreNLP。

### 1 ParserAnnotator (parse)

#### 1.1 [简要介绍](http://stanfordnlp.github.io/CoreNLP/parse.html)

Provides full syntactic analysis, using both the constituent and the dependency representations. The constituent-based output is saved in TreeAnnotation. We generate three dependency-based outputs, as follows: basic, uncollapsed dependencies, saved in BasicDependenciesAnnotation; collapsed dependencies saved in CollapsedDependenciesAnnotation; and collapsed dependencies with processed coordinations, in CollapsedCCProcessedDependenciesAnnotation. Most users of our parser will prefer the latter representation.

**Stanford NLP工具提供了两个句法分析工具，一个是短语成分分析(constituent parser)，另一个是依存关系分析(dependency parser)。前者的输出结果形式是`TreeAnnotation`；后者有三种形式，分别是`BasicDependenciesAnnotation`、`CollapsedDependenciesAnnotation`、`CollapsedCCProcessedDependenciesAnnotation`。大多数使用者都是利用后者的表示结果。**

#### 1.2 可选参数

(1)`parse.model`: parsing model to use. There is no need to explicitly set this option, unless you want to use a different parsing model (for advanced developers only). By default, this is set to the parsing model included in the stanford-corenlp-models JAR file.

parser使用的模型，默认在`stanford-corenlp-models.jar`中的`edu.stanford.models.lexparser`目录下有个英语的模型文件`englishPCFG.ser.gz`。如果导入了其他语言的model jar的话，也可以在jar相应目录下看到其他的模型文件，例如汉语的`chineseFactored.ser.gz`、`chinesePCFG.ser.gz`等。
<!-- `xinhuaFactored.ser.gz`、`xinhuaFactoredSegmenting.ser.gz`、`xinhuaPCFG.ser.gz` -->

(2)`parse.maxlen`: if set, the annotator parses only sentences shorter (in terms of number of tokens) than this number. For longer sentences, the parser creates a flat structure, where every token is assigned to the non-terminal X. This is useful when parsing noisy web text, which may generate arbitrarily long sentences. By default, this option is not set.

如果超过maxlen的长度的句子就不处理。

(3)`parse.flags`: flags to use when loading the parser model. The English model used by default uses “-retainTmpSubcategories”

加载model文件时使用的选项。

(4)`parse.originalDependencies`: Generate original Stanford Dependencies grammatical relations instead of Universal Dependencies. Note, however, that some annotators that use dependencies such as `natlog` might not function properly if you use this option. If you are using the Neural Network dependency parser and want to get the original SD relations, see the CoreNLP FAQ on how to use a model trained on Stanford Dependencies.

目前版本的parser输出结果的格式是Universal Dependencies的，如果想输出以前的SD relations，那么就可以加上这个选项，但是可能会影响其他的annotator。

(5)`parse.kbest` Store the k-best parses in KBestTreesAnnotation. Note that this option only has an effect if you parse sentences with a PCFG model.

#### 1.3 代码示例

```
private void dparse(String text) {
    Properties props = new Properties();
    props.setProperty("annotators", "tokenize, ssplit, pos, parse");//, depparse
    props.setProperty("parse.model", "edu/stanford/nlp/models/lexparser/chineseFactored.ser.gz");//使用汉语模型
    StanfordCoreNLP pipeline = new StanfordCoreNLP(props);

    // read some text in the text variable
    //String text = "I love apple"; // Add your text here!

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
            //String ne = token.get(CoreAnnotations.NamedEntityTagAnnotation.class);
        }

        // this is the parse tree of the current sentence
        Tree tree = sentence.get(TreeCoreAnnotations.TreeAnnotation.class);
        System.out.println(tree);

        System.out.println("=====");
    }

}
```

#### 1.4 扩展知识
关于Stanford Parser可以继续看[The Stanford Parser: A statistical parser](http://nlp.stanford.edu/software/lex-parser.shtml)
Stanford Parser是Stanford NLP项目中的一个子项目，包含在CoreNLP工具中。

A natural language parser is a program that works out the grammatical structure of sentences, for instance, which groups of words go together (as "phrases") and which words are the subject or object of a verb. Probabilistic parsers use knowledge of language gained from hand-parsed sentences to try to produce the most likely analysis of new sentences. These statistical parsers still make some mistakes, but commonly work rather well.

**Stanford Parser是一个基于统计的parser，利用人工标注的数据来分析一个新的句子最有可能的句法结构。**

This package is a Java implementation of probabilistic natural language parsers, both highly optimized PCFG and lexicalized dependency parsers, and a lexicalized PCFG parser.
The lexicalized probabilistic parser implements a factored product model, with separate PCFG phrase structure and lexical dependency experts, whose preferences are combined by efficient exact inference, using an A* algorithm. Or the software can be used simply as an accurate unlexicalized stochastic context-free grammar parser. Either of these yields a good performance statistical parsing system. A GUI is provided for viewing the phrase structure tree output of the parser.

The parser provides Universal Dependencies and Stanford Dependencies output as well as phrase structure trees. Typed dependencies are otherwise known grammatical relations. This style of output is available only for English and Chinese. For more details, please refer to the Stanford Dependencies webpage and the Universal Dependencies documentation.

**Stanford Parser提供了Universal Dependencies、Stanford Dependencies以及短语结构树(phrase structure trees)的输出结果。Typed dependencies(grammatical relations)格式的输出结果只支持英语和汉语。**

**Shift-reduce constituency parser** 这个parser的详情请看[这里](http://nlp.stanford.edu/software/srparser.shtml)
As of version 3.4 in 2014, the parser includes the code necessary to run a shift reduce parser, a much faster constituent parser with competitive accuracy. Models for this parser are linked below.

### 2 DependencyParseAnnotator (depparse)

#### 2.1 关于DependencyParseAnnotator的[说明](http://stanfordnlp.github.io/CoreNLP/depparse.html)

Provides a fast syntactic dependency parser. We generate three dependency-based outputs, as follows: basic, uncollapsed dependencies, saved in BasicDependenciesAnnotation; collapsed dependencies saved in CollapsedDependenciesAnnotation; and collapsed dependencies with processed coordinations, in CollapsedCCProcessedDependenciesAnnotation. Most users of our parser will prefer the latter representation.

前面提到过的，依存句法分析的结果包含`BasicDependenciesAnnotation`、`CollapsedDependenciesAnnotation`、`CollapsedCCProcessedDependenciesAnnotation`三种形式。

#### 2.2 可选参数

`depparse.model`: dependency parsing model to use. There is no need to explicitly set this option, unless you want to use a different parsing model than the default. By default, this is set to the UD parsing model included in the stanford-corenlp-models JAR file.

`depparse.extradependencies`: Whether to include extra (enhanced) dependencies in the output. The default is NONE (basic dependencies) and this can have other values of the GrammaticalStructure.Extras enum, such as SUBJ_ONLY or MAXIMAL (all extra dependencies).

#### 2.3 代码示例

```
private void dparse(String text) {
    Properties props = new Properties();
    props.setProperty("annotators", "tokenize, ssplit, pos, parse, depparse");//
    StanfordCoreNLP pipeline = new StanfordCoreNLP(props);

    // read some text in the text variable
    //String text = "I love apple"; // Add your text here!

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
            //String ne = token.get(CoreAnnotations.NamedEntityTagAnnotation.class);
        }

        // this is the parse tree of the current sentence
        Tree tree = sentence.get(TreeCoreAnnotations.TreeAnnotation.class);
        System.out.println(tree);

        // this is the Stanford dependency graph of the current sentence
        // Enhanced Dependencies CollapsedCCProcessedDependenciesAnnotation
        // Basic Dependencies BasicDependenciesAnnotation
        SemanticGraph dependencies = sentence.get(SemanticGraphCoreAnnotations.BasicDependenciesAnnotation.class);
        System.out.println(dependencies);

        System.out.println("=====");
    }

}
```

#### 2.4 扩展知识

关于Stanford Dependencies可以继续看[Stanford Dependencies](http://nlp.stanford.edu/software/stanford-dependencies.shtml)
Stanford Dependencies又是Stanford Parser中的一个子项目。

Since version 3.5.2 the Stanford Parser and Stanford CoreNLP output grammatical relations in the new Universal Dependencies representation. Take a look at the Universal Dependencies documentation for a detailed description of the new representation and its set of relations, and links to dependency treebank downloads.

自3.5.2版本开始，Stanford Parser和Stanford CoreNLP输出的语法关系(grammatical relations)的输出结果都是采用Universal Dependencies表示形式，它的具体格式内容参见[这里](http://universaldependencies.org/)。

**Neural-network dependency parser** 神经网络dependency parser，详情看[这里](http://nlp.stanford.edu/software/nndep.shtml)
In version 3.5.0 (October 2014) we released a high-performance dependency parser powered by a neural network. The parser outputs typed dependency parses for English and Chinese. The models for this parser are included in the general Stanford Parser models package.

**Neural-network dependency parser**
A dependency parser analyzes the grammatical structure of a sentence, establishing relationships between "head" words and words which modify those heads.
This parser supports English (with Universal Dependencies, Stanford Dependencies and CoNLL Dependencies) and Chinese (with CoNLL Dependencies). Future versions of the software will support other languages.

Stanford Dependency Parser是一个基于神经网络的parser，对于英语它支持输出Universal Dependencies、Stanford Dependencies和CoNLL Dependencies格式的结果，对于汉语它支持输出CoNLL Dependencies格式的结果。

**Dependency scoring** 对dependency parser的结果进行评分
The package includes a tool for scoring of generic dependency parses, in a class edu.stanford.nlp.trees.DependencyScoring. This tool measures scores for dependency trees, doing F1 and labeled attachment scoring. The included usage message gives a detailed description of how to use the tool.

ok，有点乱乱的，希望你能看明白，嘿嘿，enjoy！
