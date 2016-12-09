---
title: "Python"
date: "2014-05-18"
---
的确，正如偶像Bruce Eckel所说，**"Life is short, you need Python"！**
如果你正在考虑学Java还是Python的话，那就别想了，选Python吧，你的人生会有更多的时间做其他有意思的事情。
研究生之前我没学python是有原因的：首先，我怕蛇，很怕很怕，而这货的logo竟然就是蛇，我因故而避之；其次，我不喜欢脚本语言，我会shell，但是写的时候不是很爽，只是在处理些文件操作或者字符串操作的时候才会想起它，听说python脚本神马的，我便又避之。

但是，上了研究生发现用Python的人很多，而且这货简直被神化了，无所不能，吊炸天的Edx的后台竟然就是用的Python，于是花了一个下午刷了本《Head First Python》，感觉没啥特别，只是写起来轻便，甚至还能开发Android，让我大吃一惊。后来，又接着看了些Python书，发现真的如此，很多时候用Java写了几十行的代码用Python几行就搞定了，而且它同样拥有大量的第三方模块，于是我就这么走进了Python的世界。Python要入门很简单，毕竟我搞Java这么多年了，这俩太多的相似点了，看完书之后写写数据结构，写写算法，熟悉一些高级特性，使用一些第三方模块之后应该就算入门了吧。现在，做任何事情，我首先想到的是用Python如何实现?！嘿嘿，**"Life is short, go start Python"！**

本人才疏学浅，学识大多浅尝辄止，故文章若有错误，不论是文字笔误还是理解有错，烦请您留言以告知，感激不尽！
**Python分类下的系列文章，不断更新中，如果你迫不及待地想要看看写得如何可以先试试这篇[Python Algorithms - C4 Induction and Recursion and Reduction](/blog/2014/07/01/python-algorithms---c4-induction-and-recursion-and-reduction/)，如果觉得好就留言点个赞呗，如果觉得不好那就直接关掉这个博客网站吧**

**[感谢@Google爱好者给该系列的命名，我很喜欢，叫做“码农与蛇的故事”]**

1.Python基础知识篇  
[Python Basics](/blog/2014/05/10/python-basics/) 和 [Python Advances](/blog/2014/05/16/good-python-articles/)
前者是Python基础的简单总结(大部分摘自[网上恩师@廖雪峰老师的Python教程](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000))，后者推荐了些关于Python高级特性的好文章(大部分摘自[伯乐在线Python分类的文章](http://blog.jobbole.com/category/python/))

2.Python数据结构篇  
数据结构篇主要是阅读[Problem Solving with Python](http://interactivepython.org/courselib/static/pythonds/index.html) [该网址链接可能会比较慢]时写下的阅读记录，当然，也结合了部分[算法导论](http://en.wikipedia.org/wiki/Introduction_to_Algorithms)中的内容，此外还有不少wikipedia上的内容，所以内容比较多，可能有点杂乱。这部分主要是介绍了如何使用Python实现常用的一些数据结构，例如堆栈、队列、二叉树等等，也有Python内置的数据结构性能的分析，同时还包括了搜索和排序(在算法设计篇中会有更加详细的介绍)的简单总结。每篇文章都有实现代码，内容比较多，简单算法一般是大致介绍下思想及算法流程，复杂的算法会给出各种图示和代码实现详细介绍。

**这一部分是下面算法设计篇的前篇，如果数据结构还不错的可以直接看算法设计篇，遇到问题可以回来看数据结构篇中的某个具体内容充电一下，我个人认为直接读算法设计篇比较好，因为大家时间也都比较宝贵，如果你会来读这些文章说明你肯定有一定基础了，后面的算法设计篇中更多的是思想，这里更多的是代码而已，嘿嘿。**

(1)[搜索](/blog/2014/05/06/python-data-structures---c1-search/)   
简述顺序查找和二分查找，详述Hash查找(hash函数的设计以及如何避免冲突)

(2)[排序](/blog/2014/05/07/python-data-structures---c2-sort/)  
简述各种排序算法的思想以及它的图示和实现

(3)[数据结构](/blog/2014/05/08/python-data-structures---c3-data-structures/)  
简述Python内置数据结构的性能分析和实现常用的数据结构：栈、队列和二叉堆

(4)[树总结](/blog/2014/05/09/python-data-structures---c4-trees/)  
简述二叉树，详述二叉搜索树和AVL树的思想和实现

3.Python算法设计篇  
算法设计篇主要是阅读[Python Algorithms: Mastering Basic Algorithms in the Python Language](http://link.springer.com/book/10.1007%2F978-1-4302-3238-4)[**点击下载**]之后写下的读书总结，原书大部分内容结合了经典书籍[算法导论](http://en.wikipedia.org/wiki/Introduction_to_Algorithms)，内容更加细致深入，主要是介绍了各种常用的算法设计思想，以及如何使用Python高效巧妙地实现这些算法，这里有别于前面的数据结构篇，部分算法例如排序就不会详细介绍它的实现细节，而是侧重于它内在的算法思想。这部分使用了一些与数据结构有关的第三方模块，因为这篇的重点是算法的思想以及实现，所以并没有去重新实现每个数据结构，但是在介绍算法的同时会分析Python内置数据结构以及第三方数据结构模块的优缺点，也就意味着该篇比前面都要难不少，但是我想我的介绍应该还算简单明了，因为我用的都是比较朴实的语言，并没有像算法导论一样列出一堆性质和定理，主要是对着某个问题一步步思考然后算法就出来了，嘿嘿，除此之外，里面还有很多关于python开发的内容，精彩真的不容错过！

这里每篇文章都有实现代码，但是代码我一般都不会分析，更多地是分析算法思想，所以内容都比较多，即便如此也没有包括原书对应章节的所有内容，因为内容实在太丰富了，所以我只是选择经典的算法实例来介绍算法核心思想，除此之外，还有不少内容是原书没有的，部分是来自算法导论，部分是来自我自己的感悟，嘻嘻。该篇对于大神们来说是小菜，请一笑而过，对于菜鸟们来说可能有点难啃，所以最适合的是和我水平差不多的，对各个算法都有所了解但是理解还不算深刻的半桶水的程序猿，嘿嘿。

本篇的顺序按照原书[Python Algorithms: Mastering Basic Algorithms in the Python Language](http://link.springer.com/book/10.1007%2F978-1-4302-3238-4)的章节来安排的(章节标题部分相同部分不同哟)，为了节省时间以及保持原著的原滋原味，部分内容(一般是比较难以翻译和理解的内容)直接摘自原著英文内容。

**1.你也许觉得很多内容你都知道嘛，没有看的必要，其实如果是我的话我也会这么想，但是如果只是归纳一个算法有哪些步骤，那这个总结也就没有意义了，我觉得这个总结的亮点在于想办法说清楚一个算法是怎么想出来的，有哪些需要注意的，如何进行优化的等等，采用问答式的方式让读者和我一起来想出某个问题的解，每篇文章之后都还有一两道小题练手哟**

**2.你也许还会说算法导论不是既权威又全面么，基本上每个算法都还有详细的证明呢，读算法导论岂不更好些，当然，你如果想读算法导论的话我不拦着你，读完了感觉自己整个人都不好了别怪小弟没有提醒你哟，嘻嘻嘻，左一个性质右一个定理实在不适合算法科普的啦，没有多少人能够坚持读完的。但是码农与蛇的故事内容不多哟，呵呵呵**

**3.如果你细读本系列的话我保证你会有不少收获的，需要看算法导论哪个部分的地方我会给出提示的，嘿嘿。温馨提示，前面三节内容都是介绍基础知识，所以精彩内容从第4节开始哟，么么哒 O(∩_∩)O~**

(1)[Python Algorithms - C1 Introduction](/blog/2014/07/01/python-algorithms---c1-introduction/)   
本节主要是对原书中的内容做些简单介绍，说明算法的重要性以及各章节的内容概要。

(2)[Python Algorithms - C2 The basics](/blog/2014/07/01/python-algorithms---c2-the-basics/)   
**本节主要介绍了三个内容：算法渐近运行时间的表示方法、六条算法性能评估的经验以及Python中树和图的实现方式。**

(3)[Python Algorithms - C3 Counting 101](/blog/2014/07/01/python-algorithms---c3-counting-101/)   
原书主要介绍了一些基础数学，例如排列组合以及递归循环等，但是本节只重点介绍计算算法的运行时间的三种方法

(4)[Python Algorithms - C4 Induction and Recursion and Reduction](/blog/2014/07/01/python-algorithms---c4-induction-and-recursion-and-reduction/)   
**本节主要介绍算法设计的三个核心知识：Induction(推导)、Recursion(递归)和Reduction(规约)，这是原书的重点和难点部分**

(5)[Python Algorithms - C5 Traversal](/blog/2014/07/01/python-algorithms---c5-traversal/)   
**本节主要介绍图的遍历算法BFS和DFS，以及对拓扑排序的另一种解法和寻找图的(强)连通分量的算法**

(6)[Python Algorithms - C6 Divide and Combine and Conquer](/blog/2014/07/01/python-algorithms---c6-divide-and-combine-and-conquer/)   
**本节主要介绍分治法策略，提到了树形问题的平衡性以及基于分治策略的排序算法**

(7)[Python Algorithms - C7 Greedy](/blog/2014/07/01/python-algorithms---c7-greedy/)   
**本节主要通过几个例子来介绍贪心策略，主要包括背包问题、哈夫曼编码和最小生成树等等**

(8)[Python Algorithms - C8 Dynamic Programming](/blog/2014/07/01/python-algorithms---c8-dynamic-programming/)   
**本节主要结合一些经典的动规问题介绍动态规划的备忘录法和迭代法这两种实现方式，并对这两种方式进行对比**

(9)[Python Algorithms - C9 Graphs](/blog/2014/07/01/python-algorithms---c9-graphs/)   
**本节主要介绍图算法中的各种最短路径算法，从不同的角度揭示它们的内核以及它们的异同**

~~原书后面的2个章节(网络流和NP)暂未总结，后期如果阅读之后有所感悟必将添加到该系列，感谢阅读~~

该书的中文翻译版本已经出版，以后就不会再更新啦，有时间我也买来读一读 ~\(^o^)/~
