---
title: "Problem: Longest Common Subsequence"
date: "2014-05-19"
categories: "algorithm"
---
最长公共子序列(LCS)是典型的动态规划问题，如果不理解动态规划请移步先看[这篇动态规划的总结](/blog/2014/07/01/python-algorithms-dynamic-programming/)，否则本文中的代码实现会不理解的哟！<!--more-->

LCS问题的一个变种就是求最长单调递增子序列，它的一种简易求解方法就是先将原序列A进行排序得到序列B，然后求解序列A和序列B的最长公共子序列。

1.问题描述

![image](/images/algos/lcs1.png)

2.最优子结构和子问题重叠

![image](/images/algos/lcs2.png)

3.5种实现方式

根据LCS的递推公式

$$
c[i][j]=  \left\{
  \begin{array}{l l}
    0 & \quad \text{i=0 或者 j=0}\\
    c[i-1][j-1]+1 & \quad \text{i,j>0,且$x_{i}=y_{j}$}\\
    max({c[i][j-1],c[i-1][j]}) & \quad \text{i,j>0,且$x_{i} \ne y_{j}$}
  \end{array} \right.
$$

(1)从中可以看出计算c[i][j]时只需要2行即可，前一行(i-1)和当前行(i)，每行的长度是min{m,n}，首先初始化前一行都为0，然后计算当前行的值，当要计算下一行之前将当前行的值复制到前一行中即可。

(2)从递推公式中还可以看出计算当前行i的话，其实只需要一行再加上O(1)的额外空间就行了。因为计算c[i][j]只需要前一行中c[i-1][k] (k>=j-1)的数据，对于k<j-1的数据都是没有用的，而当前行c[i][l](l<=j-1)的数据都是有用的，要用来计算下一行的值，所以，可以在计算当前行的时候，将当前行的前面计算好的部分复制到前一行中对应位置上，但是c[i][j-1]除外，因为c[i-1][j-1]也是需要的，所以需要额外的O(1)的空间保存c[i][j-1]。

LCS的五种实现：分别为0：直接递归；1：带备忘录的递归；2：使用二维数组保存结果的迭代；3：使用2个一维数组保存结果的迭代；4：使用1个一维数组和额外的O(1)空间保存结果的迭代。

```python
def lcs0(i,j):
    #string starts at index 0, not 1
    if i<0 or j<0: return 0 #attention to this!!!
    if x[i]==y[j]:  return lcs0(i-1,j-1)+1
    return max(lcs0(i-1,j),lcs0(i,j-1))

x,y='abcde','oaob'
lenx,leny=len(x),len(y)
print(lcs0(lenx-1,leny-1)) #2

from functools import wraps

def memo(func):
    cache={}
    @wraps(func)
    def wrap(*args):
        if args not in cache:
            cache[args]=func(*args)
        return cache[args]
    return wrap

@memo
def lcs1(i,j):
    #string starts at index 0, not 1
    if i<0 or j<0: return 0 #attention to this!!!
    if x[i]==y[j]:  return lcs1(i-1,j-1)+1
    return max(lcs1(i-1,j),lcs1(i,j-1))

x,y='abcde','oaob'
lenx,leny=len(x),len(y)
print(lcs1(lenx-1,leny-1)) #2

def lcs2(x,y):
    lenx,leny=len(x),len(y)
    minlen,maxlen=0,0
    if lenx<leny: minlen,maxlen=lenx,leny; x,y=y,x
    else: minlen,maxlen=leny,lenx;
    #s is maxlen * minlen
    s=[[0 for j in range(minlen)] for i in range(maxlen)]
    for i in range(maxlen): #so, let x be the longer string!!!
        for j in range(minlen):
            if x[i]==y[j]: s[i][j]=s[i-1][j-1]+1
            else: s[i][j]=max(s[i-1][j],s[i][j-1])
    return s

x,y='abcde','oaob'
s=lcs2(x,y)
print(s) #[[0, 1, 1, 1], [0, 1, 1, 2], [0, 1, 1, 2], [0, 1, 1, 2], [0, 1, 1, 2]]

def lcs3(x,y):
    lenx,leny=len(x),len(y)
    minlen,maxlen=0,0
    if lenx<leny: minlen,maxlen=lenx,leny; x,y=y,x
    else: minlen,maxlen=leny,lenx;
    #s is maxlen * minlen
    pre=[0 for j in range(minlen)]
    cur=[0 for j in range(minlen)]
    for i in range(maxlen): #so, let x be the longer string!!!
        for j in range(minlen):
            if x[i]==y[j]: cur[j]=pre[j-1]+1
            else: cur[j]=max(pre[j],cur[j-1])
        pre[:]=cur[:]
    return cur

x,y='abcde','oaob'
s=lcs3(x,y)
print(s) #[2, 2, 2, 2]

def lcs4(x,y):
    lenx,leny=len(x),len(y)
    minlen,maxlen=0,0
    if lenx<leny: minlen,maxlen=lenx,leny; x,y=y,x
    else: minlen,maxlen=leny,lenx;
    #s is maxlen * minlen
    s=[0 for j in range(minlen)]
    t=0
    for i in range(maxlen): #so, let x be the longer string!!!
        for j in range(minlen):
            if x[i]==y[j]: s[j]=t+1
            else: s[j]=max(s[j],s[j-1])
            t=s[j]
    return s

x,y='abcde','oaobce'
s=lcs4(x,y)
print(s) #[3, 3, 3, 3, 4]
```


