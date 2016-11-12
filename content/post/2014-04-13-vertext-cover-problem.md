---
title: "Problem: Vertext Cover Problem"
date: "2014-04-13"
categories: "algorithm"
---
顶点覆盖问题可以用几种不同的算法来实现，本文使用的是分支限界法来实现<!--more-->

#### 1.问题描述

给定一个N个点M条边的无向图G（点的编号从1至N），问是否存在一个不超过K个点的集合S，使得G中的每条边都至少有一个点在集合S中。

例如，如下图所示的无向图G（报告中算法分析过程中一直使用下面的图G）  

(1)如果选择包含点1,2,6这3个点的集合S不能满足条件，因为边(3,7)两个端点都不在S中。

![image](/images/exp1-3.png)

(2)如果选择包含点1,2,6,7这4个点的集合S虽然满足条件，但是它使用了4个点，其实可以使用更少的点，如下面(3)所示

![image](/images/exp1-2.png)

(3)如果选择包含点1,3,5这3个点的集合S便满足条件，使得G中的每条边都至少有一个点在集合S中。

![image](/images/exp1-1.png)


#### 2.解题思路

我的解题思路基于分支定界和贪心两个策略，用一个优先队列维护当前可行的节点，每个节点维护着该节点情况下还可以选择的顶点数目k、需要覆盖的剩余边数e、顶点的状态state、顶点的边数edge等信息，这些节点的排序遵循下面的贪心策略，节点的扩展遵循下面的分支定界策略。总体思路是：

①将原图数据构造成一个解空间树的节点，利用定界策略判断是否有解，如果无解直接退出，如果有可能有解则插入到优先队列中；
②若优先队列不为空，那么便从优先队列中取出第一个可行的节点，进入步骤③，如果优先队列为空则退出；
③判断当前节点是否满足解的条件，如果满足便输出解退出，如果不满足便进入步骤④；
④检查当前节点是否可以扩展，不能扩展的话便进入②继续循环，如果能扩展的话则扩展，然后验证扩展到左右节点是否有解，将有解的扩展节点插入到优先队列中，然后进入②继续循环。

下面分别介绍下分支定界和贪心这两个策略：

##### (1)分支定界策略   

首先，界的选择。在一个确定的无向图G中，每个顶点的边即确定了，那么对于该无向图中k个顶点能够覆盖的最多的边数e也就可以确定了！只要对顶点按照边的数目降序排列，然后选择前k个顶点，将它们的边数相加即能得到一个边数上界！因为这k个顶点相互之间可能有边存在也可能没有，所以这是个上界，而且有可能达到。以图G为例，各个顶点的边数统计，并采用降序排列的结果如下：

![image](/images/exp1-f3.png)

假设取k=3个点，那么有Up(e)=(3+3+2)=8 > 7 条边（7为图G的总边数），也就是说，如果从图G中取3个点，要覆盖8条边是有可能的。但是，如果取k=2个点，那么有Up(e)=(3+3)=6 < 7 条边，说明从图G中取2个点，是不可能覆盖G中的全部7条边的！基于这个上界，可以在分支树中扩展出来的节点进行验证，已知它还可以选择的顶点数目以及还需要覆盖的边的条数，加上顶点的状态（下面会分析说明）即可判断当前节点是否存在解！如果不存在即可进行剪枝了。

其次，顶点的状态。该策略中顶点有三种状态，分别为已经选择了的状态S1，不选择的状态S2，可以选择的状态S3。其中，不选择的状态S2对应解空间树中的右节点，不选择该节点，然后设置该节点为不选择状态S2。这点很重要，因为有了这个状态，可以使得上界的判断更为精确，因为只能从剩余顶点集中选择那些状态S3的顶点，状态S1和S2都不行，那么上界便会更小，也就更加精确，从而利于剪枝！

##### (2)贪心策略   

贪心的策略是指可行的结点都是按照还需要覆盖的剩余边数的降序排列，即，每次选择的节点都是可行节点中还需要覆盖的边数最小的那个节点，因为它最接近结果了。

##### (3)例子分析

以图G为例，此时e=7（要覆盖的边数），取k=3，图G用邻接矩阵保存为全局数据，计算每个顶点的边数，然后降序排列。

步骤①判断是否可能有解，Up(e)=3+3+2=8>7，可能有解，那么将图G构造成一个解空间树的节点，它包含了还能选择的点数k=3，还需要覆盖的边数e=7，每个顶点的边数以及按边数大小的降序排列（上表），每个顶点的状态（初始时都是可选择的状态S3）。然后，将该节点插入到优先队列中，该优先队列是用最小堆实现的，按照前面的贪心策略对队列中的节点进行降序排列。

步骤②取出了优先队列中的根节点，很显然，还需要覆盖的边数为7，不为0，所以还不满足条件。接下来要检查是否能够进行扩展，从顶点集合中选择状态为可以选择的顶点中边数最多的点，该点存在为顶点2，接着进行扩展，扩展左节点时将还能选择的点数k-1=2，然后计算选择了该点之后删除了几条未覆盖的边，得到还需要覆盖的边数e=4，然后更新所有其他顶点的边数，并重新排序，最后将顶点2的状态设置为已经选择了；扩展右节点时，只要将顶点2的状态设置为不能选择，还能选择的点数k(=3)，还需要覆盖的边数e(=7)保持不变。扩展完了之后，同样判断左右节点是否可能有解，如果有解，将该节点插入到优先队列中。这里左右节点都有解，那么将左右节点都插入到优先队列中，因为左节点还需要覆盖的边数e=4小于右节点的e=7，所以根据贪心策略，左节点在右节点的前面。上面两个步骤的图示如下，其中标明了顶点状态颜色。

![image](/images/exp1-f1.png)

算法然后继续进入步骤②，此时取出的是节点是刚才插入的左节点，很显然，还需要覆盖的边数为4，不为0，所以还不满足条件。接下来要检查是否能够进行扩展，从顶点集合中选择状态为可以选择的顶点中边数最多的点，该点存在为顶点3，接着进行扩展，扩展左节点时将还能选择的点数k-1=1，然后计算选择了该点之后删除了几条未覆盖的边，得到还需要覆盖的边数e=2，然后更新所有其他顶点的边数，并重新排序，最后将顶点3的状态设置为已经选择了；扩展右节点时，只要将顶点3的状态设置为不能选择，还能选择的点数k(=3)，还需要覆盖的边数e(=7)保持不变。扩展完了之后，同样判断左右节点是否可能有解，如果有解，将该节点插入到优先队列中。这里左右节点都不可能有解，那么直接进入步骤②继续循环。上面这一步的图示如下：

![image](/images/exp1-f2.png)

算法按照上面的方式不断进行，最后满足条件的分支的过程是：
①不选择顶点2；②选择顶点3；③选择顶点1；④选择顶点5。

最后得到的满足条件的解是选择顶点1,3,5。

#### (4)复杂度分析

该算法优先队列使用的是最小堆实现的(O(nlgn))，对顶点按照边排序使用的是快速排序算法(O(nlgn))，解空间树的深度最多为顶点数目n，每层都要进行分支定界，所以每层的时间复杂度为O(nlgn)，所以算法总的时间复杂度为O(n^2 lgn)。但是，为了实现分支定界，每个节点保存的信息量较多，空间复杂度较大。(有木有分析错了，我不太会分析复杂度)

青橙OJ系统的结果为：时间 156ms  空间 1.0MB

本人对指针领悟能力有限，C++也是一知半解，OJ只能用C或者C++，所以下面的C++代码效率不高，仅供参考，:-)

```cpp
#include <iostream>
#include <vector>
using namespace std;
#define MAX_NODE 101
#define INDEBUG 0
int8_t graph[MAX_NODE][MAX_NODE];//int -> int8_t
//int edges[MAX_NODE];//0 is redudent
//int nodes[MAX_NODE];//the order of node
int t,m,n,k,a,b;
class VCNode {//Vertex Cover Node
public:
    int p;//points can be used
    int e;//edges to cover!!
    int index[MAX_NODE];//the index of each node in array [node], index[k]=i!!
    int edge[MAX_NODE];//MAX_NODE the edge number of each node, edge[i]=j!!
    int node[MAX_NODE];//the order of the node
    int state[MAX_NODE];//the state of each node ** 0 can be used / 1 used / -1 can not be used
//    int graph[MAX_NODE][MAX_NODE];//the graph on the node//no need,just use the global graph
    // node k is in index[k]=i position in array [node]
    // node i has number of edge[i]=j edges
};
class Minheap {//Min Heap
public:
    vector<VCNode> nodes;

    void insert(VCNode node);
    VCNode popmin();
//  void print();
};
void Minheap::insert(VCNode node) {
    nodes.push_back(node);
    //  cout << "size is " << nodes.size() << endl;//
    int curpos = (int)nodes.size() - 1; // current position
    int parent = (curpos - 1) / 2; //parent position
    while (curpos != parent && parent >= 0) { //parent is still in heap
        if (nodes[parent].e > nodes[curpos].e) { //swap parent and child
            VCNode temp = nodes[parent];
            nodes[parent] = nodes[curpos];
            nodes[curpos] = temp;
        } else {
            break; //no longer level up!!!
        }
        curpos = parent; //when curpos=parent=0, exit!!!
        parent = (curpos - 1) / 2; //relocate the parent position
    }
}
VCNode Minheap::popmin() {
    VCNode node;
    if (nodes.size() > 0) { //have nodes left
        node = nodes[0]; //get the first element
        nodes.erase(nodes.begin()); //remove the first element
        if (nodes.size() > 0) { //at least have one element more
            VCNode last = nodes[nodes.size() - 1]; //get the last element
            nodes.pop_back(); //pop the last element
            nodes.insert(nodes.begin(), last); //put it in the first place
            int csize = (int)nodes.size(); //current size
            int curpos = 0; //current position

            // rebuild the minheap
            while (curpos < (csize / 2)) { //reach to the last parent node!!
                int left = 2 * curpos + 1; //left child
                int right = 2 * curpos + 2; //right child
                int min = left; //min store the min child
                if (right < csize) { //have left and right childs
                    if (nodes[right].e < nodes[left].e) {
                        min = right;
                    }
                }
                if (min < csize) { //min child exist!!
                    if (nodes[min].e < nodes[curpos].e) { //need to swap current position with child
                        VCNode temp = nodes[min];
                        nodes[min] = nodes[curpos];
                        nodes[curpos] = temp;
                    }else { //min child no exits!! exit!!
                        break; //can break now!!
                    }
                }
                curpos = min;
            }
        }
    }
    return node;
}
//void Minheap::print() {
//  cout << "print heap" << endl;
//  for (int i = 0; i < (int)nodes.size(); i++) {
//      cout << "edge: " << nodes[i].e << " node: " << nodes[i].p << endl;
//  }
//  cout << "heap end" << endl;
//}
// print array
void printArray(int a[], int start, int end){
    if (INDEBUG) {
        cout << "print array form " << start << " to " << end << endl;
        for (int i=start; i<=end; i++) {
            cout << a[i] << " ";
        }
        cout << endl << "print array end" << endl;
    }
}
// print the graph
void printGraph(int graph[][MAX_NODE]){
    if (INDEBUG) {
        for(int i=1;i<=n;i++){//0 no need
            for(int j=1;j<=n;j++){
                cout << graph[i][j] << " ";
            }
            cout << endl;
        }
    }
}
// partition function for quick sort
int partition2(int a[], int low, int high, int b[]){
    int key = a[high];
    int i=low-1;
    for (int j=low; j<high; j++) {
        if (a[j]>=key) {
            i++;
            swap(a[i], a[j]);
            swap(b[i], b[j]);
        }
    }
    swap(a[high], a[i+1]);
    swap(b[high], b[i+1]);
    return i+1;
}
// quick sort
void quicksort2(int a[], int low, int high, int b[]) {
    if (low < high) {
        int p = partition2(a,low,high, b);
        quicksort2(a, low, p-1, b);
        quicksort2(a, p+1, high, b);
    }
}
// sum of the first k elements with state==0!!!
int sumofkmax(int edges[], int p, int nodes[], int state[]){
    quicksort2(edges, 1, n, nodes);
    int sum=0,count=0;
    // edges[i] corresponse to nodes[i], its state is state[nodes[i]]
    for(int i=1;i<=n;i++){//attention to i range!!
        if (state[nodes[i]]==0) {
            sum+=edges[i];
            count++;
            if (count == p) {//enough!
                break;
            }
        }
    }
    return sum;
}
// verify the current node can be achievable
bool verify(int edges[], int p, int e, int nodes[], int state[]){
    //caculate the sum of the first p max elements in array edges!!
    int sum = sumofkmax(edges, p, nodes, state);
    // edge of nodes[i] is edges[i]!!!
    if(sum >= e){// may be this can be achieved
        return true;
    }
    return false;
}
// build the index of node in array [index]
void buildIndex(int node[],int index[]){
    for (int i=1; i<=n; i++) {
        index[node[i]] = i;
    }
}
// get the next node: state==0 && order first!!!
int nextNode(int state[], int nodes[]){
    for (int i=1; i<=n; i++) {
        if (state[nodes[i]]==0) {
            return nodes[i];
        }
    }
    return -1;
}
// generate the left child
VCNode genLeft(VCNode curnode, int label){
    VCNode left;//choose node label!
    left.p = curnode.p - 1;//remove one node
    left.e = curnode.e;
    for (int i=0; i<=n; i++) {//first copy all infos
        left.index[i]=curnode.index[i];
        left.state[i]=curnode.state[i];//init node state
        left.edge[i]=curnode.edge[i];//copy edge info
        left.node[i]=curnode.node[i];//copy node info
//        for (int j=0; j<=n; j++) {
//            left.graph[i][j] = curnode.graph[i][j];
//        }
    }
    // following code will not use curnode anymore!!


    ///
    int sum=0;//removed edge
    for (int j=1; j<=n; j++) {
        //new
        if (label < j && left.state[j]!=1 && graph[label][j]==1 ) {//row!
            sum++;
//            left.graph[label][j]=0;
            left.edge[left.index[j]]--;//how to cut it down
        }else if(label > j && left.state[j]!=1 && graph[j][label]==1 ){ // col
            sum++;
//            left.graph[j][label]=0;
            left.edge[left.index[j]]--;//how to cut it down
        }
    }
    ///

    left.state[label] = 1;//use label directly!
    left.edge[left.index[label]] = 0;//only use index!!
//    cout << "remove edge sum is " << sum << endl;
    quicksort2(left.edge, 1, n, left.node);
    left.e = left.e - sum;//remove some edges
    buildIndex(left.node, left.index);

    if (INDEBUG) {
        cout << "======== " << label << " gen left begin===========" << endl;
        cout << "edge is " << left.e << " node is " << left.p << endl;
        cout << "array edge:" << endl;
        printArray(left.edge,1,n);
        cout << "array node:" << endl;
        printArray(left.node, 1, n);
        cout << "array index:" << endl;
        printArray(left.index, 1, n);
        cout << "array state:" << endl;
        printArray(left.state, 1, n);
//        printGraph(left.graph);
        cout << "======== " << label << " gen left end===========" << endl;
    }

    return left;
}
// generate the right child
VCNode genRight(VCNode curnode, int label){
    VCNode right;//choose node label!
    right.p = curnode.p;//remain
    right.e = curnode.e;
    for (int i=0; i<=n; i++) {//first copy all infos
        right.index[i]=curnode.index[i];
        right.state[i]=curnode.state[i];//init node state
        right.edge[i]=curnode.edge[i];//copy edge info
        right.node[i]=curnode.node[i];//copy node info
//        for (int j=0; j<=n; j++) {
//            right.graph[i][j] = curnode.graph[i][j];
//        }
    }
    // following code will not use curnode anymore!!
    right.state[label] = -1;//use label directly!

    if (INDEBUG) {
        cout << "======== " << label << " gen right begin===========" << endl;
        cout << "edge is " << right.e << " node is " << right.p << endl;
//        cout << "array edge:" << endl;
//        printArray(right.edge,1,n);
//        cout << "array node:" << endl;
//        printArray(right.node, 1, n);
//        cout << "array index:" << endl;
//        printArray(right.index, 1, n);
//        cout << "array state:" << endl;
//        printArray(right.state, 1, n);
//        printGraph(right.graph);
        cout << "======== " << label << " gen right end===========" << endl;
    }

    return right;
}
// greedy find a way to solve VCP
void greedyFind(int edges[], int nodes[]/*, int graph[][MAX_NODE]*/){
    VCNode node;
    node.e = m;
    node.p = k;

    for (int i=0; i<=n; i++) {
        node.index[i]=0;
        node.state[i]=0;//init node state
        node.edge[i]=edges[i];//copy edge info
        node.node[i]=nodes[i];//copy node info
//        for (int j=0; j<=n; j++) {
//            node.graph[i][j] = graph[i][j];
//        }
    }
    buildIndex(node.node, node.index);

    Minheap minheap;
    minheap.insert(node);

    while (minheap.nodes.size() > 0) {
        // get the heap top node to extend
        VCNode curnode = minheap.popmin();

//        if (INDEBUG) {
//            cout << "...current graph..." << endl;
//            printGraph(curnode.graph);
//        }

        // validate the current node
        if (curnode.e == 0) {
            int points = k - curnode.e;
            cout << points << endl;
            int count = 1;
            for (int i=1; i<=n; i++) {
                if (curnode.state[i]==1) {
                    if(count == points){
                        cout << i;
                    }else{
                        cout << i << " ";
                    }
                    count++;
                }
            }
            cout << endl;
            return;
        }

        // generate child nodes
        int label = nextNode(curnode.state, curnode.node);//the label of the node
        if (label != -1) {
            // node i is in index[k] position in array [node]
            // node i has number of edge[i] edges
            VCNode left = genLeft(curnode, label);
            VCNode right = genRight(curnode, label);
            if (verify(left.edge, left.p, left.e, left.node, left.state)) {
//                cout << "insert " << label << " left" << endl;
                minheap.insert(left);
            }
            if (verify(right.edge, right.p, right.e, right.node, right.state)) {
//                cout << "insert " << label << " right" << endl;
                minheap.insert(right);
            }
        }

    }

    // if not find, then return -1
    cout << -1 << endl;

}
int main() {
//    freopen("/Volumes/hujiawei/Users/hujiawei/workspace/appleworkspace/algorithmworks/Exp1-2/Exp1-2/in3.txt", "rt", stdin);//
    cin >> t;
    while(t-->0){
        cin >> n >> m >> k;
//        int graph[n+1][MAX_NODE];
        for (int i=0; i<= n; i++) {
            for (int j=0; j<= n; j++) {
                graph[i][j]=0;
            }
        }
        int edges[n+1], nodes[n+1], state[n+1];
        for (int i=0; i<= n; i++) {
            edges[i]=0;
            state[i]=0;
            nodes[i]=i;
        }
        int temp = m;
        while(temp-->0){
            cin >> a >> b;
            graph[min(a, b)][max(a,b)]=1;
//          graph[a][b]=1;
//          graph[b][a]=1;//just save half a<=b
            edges[a]++;
            edges[b]++;
        }
        bool flag = verify(edges, k, m, nodes, state);

        if (!flag) {//must not be achieved!!!
            cout << -1 << endl;
        }else{
            greedyFind(edges,nodes/*,graph*/);
        }
    }

    return 0;
}
```
