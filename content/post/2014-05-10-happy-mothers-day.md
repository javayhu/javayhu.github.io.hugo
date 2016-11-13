---
title: "Happy Mother's Day"
date: "2014-05-10"
tags: ["life"]
---
老妈，节日快乐！祝您永远幸福健康！<!--more-->

![image](/images/mothersday.png)

使用的Python代码，[源代码来源不记得了，可以看下这里](http://pythontip.sinaapp.com/coding/skulpt/)。


```python
import turtle
import random

def main():
    tList = []
    head = 0
    numTurtles = 10
    for i in range(numTurtles):
        nt = turtle.Turtle()   # Make a new turtle, initialize values
        nt.setheading(head)
        nt.pensize(2)
        nt.color(random.randrange(256),random.randrange(256),random.randrange(256))
        nt.speed(10)
        nt.tracer(30,0)
        tList.append(nt)       # Add the new turtle to the list
        head = head + 360/numTurtles

    for i in range(100):
        moveTurtles(tList,15,i)

    w = tList[0]
    w.up()
    w.goto(-130,40)
    w.write("You are my favorite lady!",True,"center","20px Arial")
    w.goto(-130,-35)
    w.write("Happy Mother's Day",True,"center","24px Arial")

def moveTurtles(turtleList,dist,angle):
    for turtle in turtleList:   # Make every turtle on the list do the same actions.
        turtle.forward(dist)
        turtle.right(angle)

main()
```
