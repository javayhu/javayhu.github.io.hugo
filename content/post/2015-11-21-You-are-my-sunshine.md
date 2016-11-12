---
title: You are My Sunshine
categories: "life"
date: "2015-11-21"
---

代码小情诗**《You are my sunshine》**  <!--more-->

![img](/images/miaosuwulimi.jpg)

```
/**
* 代码情诗：You are my sunshine
* <p/>
* 灵感来自英文歌曲《You are my sunshine》
* <p/>
* hujiawei 15/11/21
*/
public class YouAreMySunshine {

    //情诗主要内容
    public void poem() {
        //You are my sunshine my only sunshine
        I me = new I();
        You you = MySunshine.getSingleInstance();/*你是我的唯一的太阳*/

        //You make me happy when skies are gray
        if (Sky.isGray(you)) {
            you.makeMeHappy(me);/*当天空一片灰暗的时候你会逗我开心*/
        }

        //You'll never know dear how much I love you
        while (true) {
            you.neverKnow(Love.howMuch(me,you));/*你永远不知道我有多么得爱你*/
        }

        //Please don't take my sunshine away
        try {
            you.finalize();
        } catch (Throwable throwable) {
            you = MySunshine.getSingleInstance();/*当GC销毁你的时候我再造一个你*/
        }
    }

    //天空
    static class Sky {
        //天空是否是灰色的，由你是否开心决定 ↖(^ω^)↗
        static boolean isGray(You you) {
            return !you.happy();
        }
    }

    //我
    static class I {
        //我开心啦 ~\(≧▽≦)/~
        public void happy() {
        }
    }

    //你
    static class You {
        //你是否开心，希望你一直开心 (>^ω^<)
        public boolean happy() {
            return true;
        }

        //你能使我开心 ~\(≧▽≦)/~
        public void makeMeHappy(I me) {
            me.happy();
        }

        //你不知道我有多么爱你 (@﹏@)
        public void neverKnow(String howMuch) {
        }

        //"Garbage Collector (GC) 要 take you away" ~~o(>_<)o ~~
        @Override
        protected void finalize() throws Throwable {
            super.finalize();
        }
    }

    //我的太阳
    static class MySunshine extends You {
        //我的太阳我来"造" ↖(^ω^)↗
        private MySunshine() {
        }

        //"单例模式" (⊙o⊙)
        public static MySunshine getSingleInstance() {
            return MySunshineHolder.instance;
        }

        //"为了单例模式的多线程安全" (⊙o⊙)
        static class MySunshineHolder {
            private static MySunshine instance = new MySunshine();
        }
    }

    //爱
    static class Love{
        static final String INFINITE = "INFINITE";
        //我有多爱你，当然是无限爱啦 Y^o^Y
        public static String howMuch(I me, You you){
            return Love.INFINITE;
        }
    }

}
```
