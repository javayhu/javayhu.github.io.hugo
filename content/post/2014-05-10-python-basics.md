---
title: "Python Basics"
date: "2014-05-10"
tags: ["dev","python"]
---
Python代码片段 <!--more-->

1.使用`glob`模块可以用通配符的方式搜索某个目录下的特定文件，返回结果是一个list

```python
import glob
flist=glob.glob('*.jpeg')
```

使用`os.getcwd()`可以得到当前目录，如果想切换到其他目录，可以使用`os.chdir('str/to/path')`，如果想执行Shell脚本，可以使用`os.system('mkdir newfolder')`。

对于日常文件和目录的管理, `shutil`模块提供了更便捷、更高层次的接口

```
import shutil
shutil.copyfile('data.db', 'archive.db')
shutil.move('/build/executables', 'installdir')
```

使用PyCharm中，在一个Project中新建一个Directory和新建一个Package之后，IDE都会创建对应的目录，并添加默认的`__init__.py`文件，但是，两者还是不一样的。
如果在它们的目录下各新建一个python脚本测试输出`os.getcwd()`，如果是在Directory中得到的是Project的根目录'/Users/hujiawei/PycharmProjects/leetcodeoj'；如果是在Package中得到的是Package的根目录，如'/Users/hujiawei/PycharmProjects/leetcodeoj/pypackage'。

2.如果要在代码中添加中文注释的话，最好在文档开头加上下面的编码声明语句。关于Python中的字符串编码可见[廖雪峰的python教程](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/001386819196283586a37629844456ca7e5a7faa9b94ee8000)。若代码打算用在国际化的环境中, 那么不要使用奇特的编码。Python 默认的 UTF-8, 或者甚至是简单的 ASCII 在任何情况下工作得最好。同样地，如果代码的读者或维护者只有很小的概率使用不同的语言，那么不要在标识符里使用非 ASCII 字符。

```
# coding=utf-8
或者
# -*- coding: utf-8 -*-
```

3.关于Python中的变量，摘自[廖雪峰的python教程](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/001386820042500060e2921830a4adf94fb31bcea8d6f5c000)

在Python中，变量名类似`__xxx__`的，也就是以双下划线开头，并且以双下划线结尾的，是特殊变量，特殊变量是可以直接访问的，不是private变量，所以，不能用`__name__`、`__score__`这样的变量名。

有些时候，你会看到以一个下划线开头的实例变量名(**两个下划线开头的也一样算，其实任何以下划线开头的都算**)，比如`_name`，这样的实例变量外部是可以访问的，但是，按照约定俗成的规定，当你看到这样的变量时，意思就是，**“虽然我可以被访问，但是，请把我视为私有变量，不要随意访问”**。

双下划线开头的实例变量是不是一定不能从外部访问呢？其实也不是。不能直接访问`__name`是因为Python解释器对外把`__name`变量改成了`_Student__name`，所以，仍然可以通过`_Student__name`来访问`__name`变量。但是强烈建议你不要这么干，因为不同版本的Python解释器可能会把`__name`改成不同的变量名。

总的来说就是，Python本身没有任何机制阻止你干坏事，一切全靠自觉。

上面说的有点绕，下面我写了两个python脚本，大家可以对照看下哪些能够访问，哪些不能，不能的情况下如何操作变得可以访问(注释后面的`yes`和`no`表示能不能被访问)。

也就是说，**默认呢，以一个下划线开始(不论结尾有没有下划线)的变量在外部都是可以直接访问的，但是不推荐这么做；以两个下划线开始和两个下划线结束的变量属于特殊变量，可以直接访问；而以两个下划线开始且结尾不是两个下划线(可以没有也可以有一个下划线)的变量属于私有变量，不能直接访问，虽然可以通过其他方式访问，但最好不要在外部访问。**

文件`APythonTestA.py`

```python
# coding=utf-8

class ListNode:

    _class_field10 = 'node class field 1-0'
    _class_field11_ = 'node class field 1-1'
    _class_field12__ = 'node class field 1-2'

    __class_field20 = 'node class field 2-0'
    __class_field21_ = 'node class field 2-1'
    __class_field22__ = 'node class field 2-2'

    def __init__(self, x):
        self.val = x
        self.next = None

_class_field10 = 'node class field 1-0'
_class_field11_ = 'node class field 1-1'
_class_field12__ = 'node class field 1-2'

__class_field20 = 'node class field 2-0'
__class_field21_ = 'node class field 2-1'
__class_field22__ = 'node class field 2-2'
```

文件`APythonTestB.py`

```python
# coding=utf-8
__author__ = 'hujiawei'
__doc__ = 'for python test 2'

import APythonTestA

if __name__ == '__main__':
    print(dir(APythonTestA.ListNode))
    node = APythonTestA.ListNode(4)
    # print(node._ListNode__class_field20) #yes
    print(node._class_field10) #yes
    print(node._class_field11_) #yes
    print(node._class_field12__) #yes
    # print(node.__class_field20) #no
    print(node._ListNode__class_field20)#yes
    # print(node.__class_field21_) #no
    print(node._ListNode__class_field21_)#yes
    print(node.__class_field22__) #yes

    print(dir(APythonTestA))
    print(APythonTestA._class_field10) #yes
    print(APythonTestA._class_field11_) #yes
    print(APythonTestA._class_field12__) #yes
    print(APythonTestA.__class_field20) #yes
    print(APythonTestA.__class_field21_) #yes
    print(APythonTestA.__class_field22__) #yes

# ['_ListNode__class_field20', '_ListNode__class_field21_', '__class_field22__', '__doc__', '__init__', '__module__', '_class_field10', '_class_field11_', '_class_field12__']
# node class field 1-0
# node class field 1-1
# node class field 1-2
# node class field 2-0
# node class field 2-1
# node class field 2-2
# ['ListNode', '__builtins__', '__class_field20', '__class_field21_', '__class_field22__', '__doc__', '__file__', '__name__', '__package__', '_class_field10', '_class_field11_', '_class_field12__']
# node class field 1-0
# node class field 1-1
# node class field 1-2
# node class field 2-0
# node class field 2-1
# node class field 2-2
```

4.关于Python中函数的参数，摘自[廖雪峰的python教程](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/001374738449338c8a122a7f2e047899fc162f4a7205ea3000)

Python的函数具有非常灵活的参数形态，既可以实现简单的调用，又可以传入非常复杂的参数。
默认参数一定要用不可变对象，如果是可变对象，运行会有逻辑错误！

要注意定义可变参数和关键字参数的语法：

`*args`是可变参数，args接收的是一个tuple；

`**kw`是关键字参数，kw接收的是一个dict。

以及调用函数时如何传入可变参数和关键字参数的语法：

可变参数既可以直接传入：`func(1, 2, 3)`，又可以先组装list或tuple，再通过`*args`传入：`func(*(1, 2, 3))；`

关键字参数既可以直接传入：`func(a=1, b=2)`，又可以先组装dict，再通过`**kw`传入：`func(**{'a': 1, 'b': 2})`。

使用`*args`和`**kw`是Python的习惯写法，当然也可以用其他参数名，但最好使用习惯用法。

5.关于Python的高级特性，参见[廖雪峰的python教程](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/0013868196169906eb9ca5864384546bf3405ae6a172b3e000)

切片，迭代，列表生成式，生成器

**除非特殊的原因，应该经常在代码中使用生成器表达式。但除非是面对非常大的列表，否则是不会看出明显区别的。**

使用生成器得到当前目录及其子目录中的所有文件的代码，下面代码来自[伯乐在线-python高级编程技巧](http://blog.jobbole.com/61171/)

```
import os
def tree(top):
    #path,folder list,file list
    for path, names, fnames in os.walk(top):
        for fname in fnames:
            yield os.path.join(path, fname)

for name in tree(os.getcwd()):
    print name
```
另一个使用生成器的代码示例：

```
num = [1, 4, -5, 10, -7, 2, 3, -1]

def square_generator(optional_parameter):
    return (x ** 2 for x in num if x > optional_parameter)

print square_generator(0)
# <generator object <genexpr> at 0x004E6418>

# Option I
for k in square_generator(0):
    print k
# 1, 16, 100, 4, 9

# Option II
g = list(square_generator(0))
print g
# [1, 16, 100, 4, 9]
```

6.关于Python的函数式编程，参见[廖雪峰的python教程](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/001386819866394c3f9efcd1a454b2a8c57933e976445c0000)，讲解得很好

高阶函数(使用函数作为参数或者返回一个函数的函数称为`高阶函数`)，匿名函数(lambda)，装饰器(decorator)和偏函数

用来测试一个函数花费的运行时间的装饰器，当然你也可以使用其他的方式，比如`Timer`来得到运行时间。下面代码来自[伯乐在线-python高级编程技巧](http://blog.jobbole.com/61171/)

```
def timethis(func):
    '''
    Decorator that reports the execution time.
    '''
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(func.__name__, end-start)
        return result
    return wrapper

@timethis
def countdown(n):
    while n > 0:
        n -= 1
```

其中代码

```
@timethis
def countdown(n):
```

就相当于：

```
def countdown(n):
...
countdown = timethis(countdown)
```

装饰器除了可以使用函数实现，也可以使用类来实现。

**对装饰器的类实现的唯一要求是它必须能如函数一般使用，也就是说它必须是可调用的。所以，如果想这么做这个类必须实现`__call__`方法。**

```
class decorator(object):

    def __init__(self, f):
        print("inside decorator.__init__()")
        f() # Prove that function definition has completed

    def __call__(self):
        print("inside decorator.__call__()")

@decorator
def function():
    print("inside function()")

print("Finished decorating function()")

function()

# inside decorator.__init__()
# inside function()
# Finished decorating function()
# inside decorator.__call__()
```

1. 语法糖`@decorator`相当于`function=decorator(function)`，在此调用decorator的`__init__`打印`“inside decorator.__init__()”`
2. 随后执行f()打印`“inside function()”`
3. 随后执行`“print(“Finished decorating function()”)”`
4. 最后再调用function函数时，由于使用装饰器包装，因此执行decorator的`__call__`打印 `“inside decorator.__call__()”`。

==我的批注：我觉得上面代码不是一般的使用方式，实际装饰器类应该是在`__init__`方法中设置好自己内部的函数f，然后在方法`__call__`中调用函数f，并包含一些其他的方法调用，大概如下：

```
class decorator(object):

    def __init__(self, f):
        print("inside decorator.__init__()")
        # f() # Prove that function definition has completed
        self.f=f

    def __call__(self):
        print("inside decorator.__call__() begin")
        self.f()
        print("inside decorator.__call__() end")

@decorator
def function():
    print("inside function()")

print("Finished decorating function()")

function()

# inside decorator.__init__()
# Finished decorating function()
# inside decorator.__call__() begin
# inside function()
# inside decorator.__call__() end
```

在提供一个装饰器的例子，实现自顶向下的带备忘录的DP算法来解决斐波那契数列求值，来源于[Python Algorithms- Mastering Basic Algorithms in the Python Language](http://link.springer.com/book/10.1007%2F978-1-4302-3238-4)

```
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
def fib(i):
    if i<2: return 1
    return fib(i-1)+fib(i-2)

print(fib(100))
```

7.Python中的值传递和引用传递

[参考阅读资料](http://www.pythoneye.com.cn/article/pythonpeixun45.html)

**python函数传递的是对象的引用值，非传值或传引用。但是如果对象是不可变的，感觉和c语言中传值差不多。如果对象是可变的，感觉和c语言中传引用差不多。**

运行下面的代码就清楚了

```
def foo(a):
    print "传来是对象的引用对象地址为{0}".format(id(a))
    a = 3 #形式参数a是局部变量，a重新绑定到3这个对象。
    print "变量a新引用对象地址为{0}".format(id(a))
    # print a

x = 5
print "全局变量x引用的对象地址为{0}".format(id(x))
foo(x)
print "变量x新引用对象地址为{0}".format(id(x))
print x
#由于函数内部a绑定到新的对象，也就修改不了全局变量x引用的对象5
# 全局变量x引用的对象地址为140462615725816
# 传来是对象的引用对象地址为140462615725816
# 变量a新引用对象地址为140462615725864
# 变量x新引用对象地址为140462615725816
# 5


def foo(a):
    """在函数内部直接修改了同一个引用指向的对象。
    也就修改了实际参数传来的引用值指向的对象。
    """
    a.append("can change object")
    return a

lst = [1,2,3]
print foo(lst)
print lst
#[1, 2, 3, 'can change object']
#[1, 2, 3, 'can change object']


def foo(a):
    """实际参数传来一个对象[1,2,3]的引用，当时形式参数
    （局部变量a重新引用到新的对象，也就是说保存了新的对象）
    当然不能修改原来的对象了。
    """
    a = ["python","java"]
    return a

lst = [1,2,3]
for item in foo(lst):
    print item
print lst
# python
# java
```

8.其他

(1)Python中`set([1,2,3])`是一个set，`{1,2,3,4,5}`也是一个set，`{1:2,2:4,3:6,4:8,5:10}`是一个dict，而且空的`{}`是一个dict！

set和dict的唯一区别仅在于没有存储对应的value，但是，set的原理和dict一样，所以，同样不可以放入可变对象，因为无法判断两个可变对象是否相等，也就无法保证set内部“不会有重复元素”。试试把list放入set，看看是否会报错。

<!--
(2)得到int类型的最大值使用`sys.maxint`，
-->
