---
title: "Google APAC 2015 University Graduates Test Round D"
date: "2014-11-09"
categories: "algorithm"
---
Google APAC 2015 University Graduates Test Round D <!--more-->

前段时间才知道的Google APAC比赛，于是乎注册了今天下午的比赛，Round D，总共四道题，只过了两道，完了之后现在过了三道。这三道都不难只是觉得很奇怪，不熟悉这种比赛模式，它是让你下载输入文件，然后你在给定时间内提交输出文件和源程序即可，对于每道题目都有一个小测试集和大测试集。

我以为一般大测试集肯定不好过的，但是纳闷的是其实也很好过，所以本来第二题暴力很简单就能过，我以为要优化，写了半天还是错了，于是在比赛前暴力了一下，结果竟然过了，哎，请理解俺这个菜鸟。

废话不多说了，下面是前三题的解题报告

[我的代码总是冗长冗长的，可读性高，但是花的时间总是比别人长，所以我真心不适合比赛，汗⊙﹏⊙]

###[Problem A. Cube IV](https://code.google.com/codejam/contest/6214486/dashboard#s=p0)

问题A是说在S*S个方格中，每个方格代表一个房间，房间有一个房间编号，从1到S的平方，每个里面有一个人，这个人可以从一个房间A移动到另一个房间B，但是必须满足房间B的编号比房间A的编号大1才行，问哪个房间的人能够移动的距离最远，最远的距离又是多少？如果两个人能够移动的距离相同，输出房间号小的那个人。

思路：自始至终维护结果r和d，从房间号最大的那个房间开始DFS，遇到房间号小1的房间就进入，一直下去直到不能移动了，修改r和d的值，然后从比上次停下来的房间小1的房间开始继续DFS，如果他移动的距离更多的话，那么就修改d和r即可，一直下去就能得到最终解。


```java
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.Scanner;

//https://code.google.com/codejam/contest/6214486/dashboard#s=p0

public class ProblemA {

    private static int s;
    private static int[][] p;

    public static void main(String[] args) throws Exception {
        PrintStream out = new PrintStream(new BufferedOutputStream(new FileOutputStream("data/out.txt")));
        System.setOut(out);
        System.setErr(out);
        Scanner scanner = new Scanner(new FileInputStream("data/in.txt"));
        int t = scanner.nextInt();
        int c = 1;
        while (t-- > 0) {
            s = scanner.nextInt();
            p = new int[s][s];
            for (int i = 0; i < s; i++) {
                for (int j = 0; j < s; j++) {
                    p[i][j] = scanner.nextInt();
                }
            }
            System.out.print("Case #" + c + ": ");
            solve();
            c++;
        }
        out.flush();
        out.close();
    }

    private static void solve() {
        int r = 0, d = 1, max = s * s;
        while (max > 0 && max >= d) {
            Point maxp = findPoint(max);
            Result result = new Result(1, 1);
            dfs(maxp, result);
            if (result.d >= d) {
                r = result.r;
                d = result.d;
            }
            max = max - result.d;//
        }
        System.out.println(r + " " + d);
    }

    private static void dfs(Point current, Result result) {
        //left
        Point left = current.left();
        if (left != null && p[left.x][left.y] == p[current.x][current.y] - 1) {
            result.r = p[left.x][left.y];
            result.d++;
            dfs(left, result);
            return;
        }
        //right
        Point right = current.right();
        if (right != null && p[right.x][right.y] == p[current.x][current.y] - 1) {
            result.r = p[right.x][right.y];
            result.d++;
            dfs(right, result);
            return;
        }
        //up
        Point up = current.up();
        if (up != null && p[up.x][up.y] == p[current.x][current.y] - 1) {
            result.r = p[up.x][up.y];
            result.d++;
            dfs(up, result);
            return;
        }
        //down
        Point down = current.down();
        if (down != null && p[down.x][down.y] == p[current.x][current.y] - 1) {
            result.r = p[down.x][down.y];
            result.d++;
            dfs(down, result);
            return;
        }
    }

    private static Point findPoint(int max) {
        for (int i = 0; i < s; i++) {
            for (int j = 0; j < s; j++) {
                if (p[i][j] == max) {
                    return new Point(s, i, j);
                }
            }
        }
        return null;
    }

}

class Point {

    int s;
    int x;
    int y;

    Point(int s, int x, int y) {
        this.s = s;
        this.x = x;
        this.y = y;
    }

    Point up() {
        if (x - 1 >= 0) return new Point(this.s, this.x - 1, this.y);
        return null;
    }

    Point down() {
        if (x + 1 < s) return new Point(this.s, this.x + 1, this.y);
        return null;
    }

    Point left() {
        if (y - 1 >= 0) return new Point(this.s, this.x, this.y - 1);
        return null;
    }

    Point right() {
        if (y + 1 < s) return new Point(this.s, this.x, this.y + 1);
        return null;
    }
}

class Result {

    int r;
    int d;

    Result(int r, int d) {
        this.r = r;
        this.d = d;
    }
}

```


###[Problem B. GBus count](https://code.google.com/codejam/contest/6214486/dashboard#s=p1)

问题B是说在一些城市之间有一些公交车，给你这些车的起点和终点的数据，假设某辆公交车是从1到10，那么城市1、城市2、城市3等一直到城市10都被经过了，现在要求的是有多少辆车经过了某个城市？

思路：这简直不能叫做思路！纯暴力就行了！遍历所有公交车的线路，统计判断该城市是否在这个线路上即可。这样就已经可以过了！比赛时我想了写优化，大致思路是假设城市编号为c，公交车的线路为 $a_{i}$ 和 $b_{i}$，首先对所有公交线路按照 $a_{i}$ 排序，保留那些 $a_{i}<=c$ 的线路，然后对这些线路按照 $b_{i}$ 排序，保留那些 ${b_{i}>=c}$ 的线路，最后保留下来的线路的个数就是最终的解。[但是我的代码有问题，即下面的`solve`方法，提交了几次都报错]

```
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.*;

//https://code.google.com/codejam/contest/6214486/dashboard#s=p1

public class ProblemB {

    private static int n, p;
    private static ArrayList<Bus> buses;
    private static ArrayList<Integer> cities;

    public static void main(String[] args) throws Exception {
        PrintStream out = new PrintStream(new BufferedOutputStream(new FileOutputStream("data/out.txt")));
        System.setOut(out);
        System.setErr(out);
        Scanner scanner = new Scanner(new FileInputStream("data/in.txt"));

        int t = scanner.nextInt();
        int c = 1;
        while (t-- > 0) {
            buses = new ArrayList<Bus>();
            cities = new ArrayList<Integer>();
            n = scanner.nextInt();
            for (int i = 0; i < n; i++) {
                buses.add(new Bus(scanner.nextInt(), scanner.nextInt()));
            }
            p = scanner.nextInt();
            for (int i = 0; i < p; i++) {
                cities.add(scanner.nextInt());
            }
            System.out.print("Case #" + c + ": ");
            solve2();
            System.out.println();
            c++;
        }

        out.flush();
        out.close();
    }

    //暴力解决
    private static void solve2() {
        int key, sum;
        for (int i = 0; i < p; i++) {
            key = cities.get(i);
            sum = 0;
            for (Bus bus : buses) {
                if (key >= bus.x && key <= bus.y) {
                    sum++;
                }
            }
            System.out.print(sum + " ");
        }
    }

    //非暴力解决，但是仍然存在问题
    private static void solve() {
        Comparator<Bus> cf = new Comparator<Bus>() {
            @Override
            public int compare(Bus o1, Bus o2) {
                if (o1.x > o2.x) {
                    return 1;
                } else if (o1.x < o2.x) {
                    return -1;
                }
                return 0;
            }
        };
        Comparator<Bus> ct = new Comparator<Bus>() {
            @Override
            public int compare(Bus o1, Bus o2) {
                if (o1.y > o2.y) {
                    return 1;
                } else if (o1.y < o2.y) {
                    return -1;
                }
                return 0;
            }
        };

        Collections.sort(buses, cf);

        int left, right, key;
        for (int i = 0; i < p; i++) {
            key = cities.get(i);
            left = bs_f(buses, key);//从left开始都是大于key的数字
            List<Bus> flist = buses.subList(0, left);//left=0, size=0
            if (flist.size() > 0) {
                Collections.sort(flist, ct);
                right = bs_t(flist, key);//从right开始都是大于等于key的数字
                List<Bus> tlist = flist.subList(right, flist.size());
                System.out.print(tlist.size() + " ");
            } else {
                System.out.print("0 ");
            }
        }
    }

    private static int bs_f(List<Bus> lbus, int r) {
        int len = lbus.size();
        int left = 0, right = len - 1, mid = 0;
        while (left <= right) {
            mid = (left + right) / 2;
            if (r < lbus.get(mid).x) {
                right = mid - 1;
            } else if (r >= lbus.get(mid).x) {
                left = mid + 1;
            }
        }
        return left;
    }

    private static int bs_t(List<Bus> lbus, int r) {
        int len = lbus.size();
        int left = 0, right = len - 1, mid = 0;
        while (left <= right) {
            mid = (left + right) / 2;
            if (r <= lbus.get(mid).y) {
                right = mid - 1;
            } else if (r > lbus.get(mid).y) {
                left = mid + 1;
            }
        }
        return left;
    }

}

class Bus {

    int x;
    int y;

    Bus(int x, int y) {
        this.x = x;
        this.y = y;
    }
}

```


###[Problem C. Sort a scrambled itinerary](https://code.google.com/codejam/contest/6214486/dashboard#s=p2)

问题C是说给你一些航班的信息，包括起点城市和终点城市，但是顺序乱了，让你来确定这些航班整合起来最后是从哪里到哪里之后又到了哪里。

思路：这题很简单，起点是入度为0的点，终点是出度为0的点，一个while循环就能搞定，就这样简单的思路这道题目就可以过。


```
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.*;

//https://code.google.com/codejam/contest/6214486/dashboard#s=p2

public class ProblemC {

    private static Map<String, String> flights;
    private static Map<String, City> citymap;

    public static void main(String[] args) throws Exception {
        PrintStream out = new PrintStream(new BufferedOutputStream(new FileOutputStream("data/out.txt")));
        System.setOut(out);
        System.setErr(out);
        Scanner scanner = new Scanner(new FileInputStream("data/in.txt"));

        int t = scanner.nextInt();
        int c = 1;
        while (t-- > 0) {
            System.out.print("Case #" + c + ": ");
            flights = new HashMap<String, String>();
            citymap = new HashMap<String, City>();
            int p = scanner.nextInt();
            String from, to;
            City cf, ct;
            for (int i = 0; i < p; i++) {
                from = scanner.next();
                to = scanner.next();

                if (citymap.containsKey(from)) {
                    cf = citymap.get(from);
                } else {
                    cf = new City();
                    citymap.put(from, cf);
                }
                cf.name = from;
                cf.out = 1;

                if (citymap.containsKey(to)) {
                    ct = citymap.get(to);
                } else {
                    ct = new City();
                    citymap.put(to, ct);
                }
                ct.name = to;
                ct.in = 1;

                flights.put(from, to);
            }
            solve();
            c++;
            System.out.println();
        }

        out.flush();
        out.close();
    }

    private static void solve() {
        String from = null;
        Set<Map.Entry<String, City>> entries = citymap.entrySet();
        for (Map.Entry<String, City> entry : entries) {
            //System.out.println("name=" + entry.getValue().name + " in=" + entry.getValue().in + " out=" + entry.getValue().out);
            if (entry.getValue().in == 0) {
                from = entry.getKey();
                break;
            }
        }

        String next;
        String current = from;
        while (current != null && flights.containsKey(current)) {
            next = flights.get(current);
            System.out.print(citymap.get(current).name + "-" + citymap.get(next).name + " ");
            current = next;
        }
    }

}

class City {

    String name;
    int in = 0;
    int out = 0;

}

```


[Problem D. Itz Chess](https://code.google.com/codejam/contest/6214486/dashboard#s=p3)

问题D是说在国际象棋的棋盘上放了一些棋子，在当前位置下有些棋子可以杀死其他的棋子，问共有多少个可以杀死的情况。

思路：我没啥特别的思路，就是根据每类棋子的不同攻击方式编写相应的检验函数看它是否能够将某个棋子杀死。

小数据集的测试样例貌似都是关于K和P的，我都通过了，但是大数据测试集没有通过，估计是哪类棋子的攻击检验函数有问题，暂时不知道问题在哪，若有发现的请告知，谢谢。

```
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;

//https://code.google.com/codejam/contest/6214486/dashboard#s=p3

public class ProblemD {

    private static int[][] board;
    private static List<Chess> chesses;

    public static void main(String[] args) throws Exception {
        PrintStream out = new PrintStream(new BufferedOutputStream(new FileOutputStream("data/out.txt")));
        System.setOut(out);
        System.setErr(out);
        Scanner scanner = new Scanner(new FileInputStream("data/D-large-practice.in.txt"));

        int t = scanner.nextInt();
        for (int w = 1; w <= t; w++) {
            System.out.print("Case #" + w + ": ");
            board = new int[9][9];
            chesses = new ArrayList<Chess>();
            for (int i = 0; i < 9; i++) {
                for (int j = 0; j < 9; j++) {
                    board[i][j] = 0;//默认是空的字符
                }
            }
            int n = scanner.nextInt();
            String line;
            int x, y;
            char c;
            for (int i = 0; i < n; i++) {
                line = scanner.next();
                x = line.charAt(1) - '1' + 1;//行
                y = 8 - (line.charAt(0) - 'A');//列
                c = line.charAt(3);
                board[x][y] = 1;
                chesses.add(new Chess(x, y, c));
            }

            //for (int i = 0; i < 9; i++) {
            //    for (int j = 0; j < 9; j++) {
            //        System.out.print(board[i][j] + " ");
            //    }
            //    System.out.println();
            //}

            solve();

            System.out.println();
        }

        out.flush();
        out.close();
    }

    private static void solve() {
        int sum = 0;
        for (int i = 0, l = chesses.size(); i < l; i++) {
            for (int j = 0; j < l; j++) {
                if (kill(chesses.get(i), chesses.get(j))) {
                    sum++;
                    //System.out.println(" ko");
                } //else System.out.println();
            }
        }
        System.out.print(sum);
    }

    //判断棋子c1是否能够杀死c2
    private static boolean kill(Chess c1, Chess c2) {
        if (c1.x == c2.x && c1.y == c2.y) return false;
        //System.out.print(c1.c + " (" + c1.x + "," + c1.y + ") " + c2.c + " (" + c2.x + "," + c2.y + ")");
        switch (c1.c) {
            case 'K':
                return k_kill(c1, c2);
            case 'Q':
                return q_kill(c1, c2);
            case 'R':
                return r_kill(c1, c2);
            case 'B':
                return b_kill(c1, c2);
            case 'N':
                return n_kill(c1, c2);
            case 'P':
                return p_kill(c1, c2);
        }
        return false;
    }

    //王
    private static boolean k_kill(Chess c1, Chess c2) {
        if (((Math.abs(c1.x - c2.x) == 1) || (Math.abs(c1.x - c2.x) == 0))
                && ((Math.abs(c1.y - c2.y) == 1) || (Math.abs(c1.y - c2.y) == 0))) return true;
        return false;
    }

    //后
    private static boolean q_kill(Chess c1, Chess c2) {
        if (r_kill(c1, c2) || b_kill(c1, c2)) return true;
        return false;
    }

    //车
    private static boolean r_kill(Chess c1, Chess c2) {
        if (c2.x != c1.x && c2.y != c1.y) return false;
        if (c2.x == c1.x) {//同一行
            int from = Math.min(c2.y, c1.y);
            int to = Math.max(c2.y, c1.y);
            for (int k = from + 1; k < to - 1; k++) {
                if (board[c1.x][k] != 0) {
                    return false;
                }
            }
            return true;
        }
        if (c2.y == c1.y) {//同一列
            int from = Math.min(c2.x, c1.x);
            int to = Math.max(c2.x, c1.x);
            for (int k = from + 1; k < to - 1; k++) {
                if (board[k][c1.y] != 0) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    //象
    private static boolean b_kill(Chess c1, Chess c2) {
        if (Math.abs(c1.x - c2.x) != Math.abs(c1.y - c2.y)) return false;
        int xdir = c1.x > c2.x ? -1 : 1;//direction!!!
        int ydir = c1.y > c2.y ? -1 : 1;
        for (int i = c1.x + xdir, j = c1.y + ydir; i != c2.x && j != c2.y; i = i + xdir, j = j + ydir) {
            if (board[i][j] != 0) {
                return false;
            }
        }
        return true;
    }

    //马
    private static boolean n_kill(Chess c1, Chess c2) {
        if (Math.abs(c1.x - c2.x) == 1 && Math.abs(c1.y - c2.y) == 2) {
            return true;
        }
        if (Math.abs(c1.y - c2.y) == 1 && Math.abs(c1.x - c2.x) == 2) {
            return true;
        }
        return false;
    }

    //兵
    private static boolean p_kill(Chess c1, Chess c2) {
        if (Math.abs(c1.x - c2.x) == 1 && c1.y - c2.y == 1) return true;
        return false;
    }
}

class Chess {

    int x;
    int y;
    char c;

    Chess(int x, int y, char c) {
        this.x = x;
        this.y = y;
        this.c = c;
    }
}
```
