---
title: "Hadoop Installation - Single Node Setup"
date: "2014-05-12"
tags: ["dev"]
---
本文主要介绍Hadoop的搭建过程 <!--more-->

上学期在Mac上搭建好了Hadoop，因为这学期开学重装了系统就没了，以为不会再折腾，结果大数据作业又要整hadoop，于是乎，爱折腾的程序猿又来折腾咯，有过上一次安装的经历，这次简单多了，下面简单的列举主要步骤。

感谢下面两份教程：   
1.[en][Running Hadoop on Ubuntu Linux (Single-Node Cluster)](http://www.michael-noll.com/tutorials/writing-an-hadoop-mapreduce-program-in-python/)   
2.[cn][田俊童鞋的Hadoop的安装部署与配置](http://www.tianjun.ml/essays/16)

1.下载部分

(0)你肯定不是安装到本地的啦，先安装VMware吧，我会告诉你这货需要序列号吗?

(1)Ubuntu：[http://www.ubuntu.com/](http://www.ubuntu.com/)

随便这个Desktop版本下载，我的是12.04 LTS

(2)JDK：[http://hadoop.apache.org/](http://hadoop.apache.org/)

个人喜欢从Oracle上下载JDK来安装，不喜欢`apt-get`模式，我使用的是`JDK1.7`

(3)Hadoop：[http://hadoop.apache.org/](http://hadoop.apache.org/)

我使用的是上学期用的1.2.1版本，名称`hadoop-1.2.1-bin.tar.gz`

2.配置Java环境 [该部分直接摘自我之前[Android和OpenCV开发中的配置](/blog/2014/02/21/android-ndk-and-opencv-development-4/)]

①下载[Oracle JDK](http://www.oracle.com/technetwork/java/javase/downloads/index.html)，下载的版本是JDK1.7.0_40

②下载之后解压即可，解压路径为`/home/xface/android/jdk1.7.0`

③打开终端，输入`sudo gedit /etc/profile`，在文件末尾添加下面内容

```python
JAVA_HOME=/home/xface/android/jdk1.7.0
export PATH=$JAVA_HOME/bin:$PATH
```

如下图所示，后面环境配置中添加内容也是如此

![image](/images/etcprofile.png)

④打开终端输入`java -version`进行测试

![image](/images/javaversion.png)

3.配置Hadoop环境

(1)添加账户和组

```
sudo addgroup hadoop
sudo adduser --ingroup hadoop hduser
```

(2)安装openssh-server，并配置公钥

```
sudo apt-get update
sudo apt-get install openssh-server
su - hduser
ssh-keygen -t rsa -P ""
cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
ssh localhost #测试
```

(3)Disabling IPv6?

这步我没有操作，如果需要请参考上面的教程[Running Hadoop on Ubuntu Linux (Single-Node Cluster)](http://www.michael-noll.com/tutorials/writing-an-hadoop-mapreduce-program-in-python/)

(4)解压`hadoop-1.2.1-bin.tar.gz`，然后重命名为`hadoop`，接着修改文件夹所有者

```
mv hadoop-1.2.1 hadoop
chown -R hduser:hadoop hadoop
```

(5)修改文件`/etc/profile`中系统环境变量的配置

```
#set hadoop environment

HADOOP_HOME=/home/xface/hadoop/hadoop
export PATH=${PATH}:${HADOOP_HOME}/bin
```

(6)在hadoop安装目录下新建临时文件目录`tmp`和日志文件目录`logs`

```
sudo mkdir -p tmp
sudo chown hduser:hadoop tmp
# ...and if you want to tighten up security, chmod from 755 to 750...
sudo chmod 750 tmp #我习惯用777
#logs的配置和tmp一样
```

(7)配置hadoop的`conf`文件夹下的文件

①`hadoop-env.sh` 修改Java配置

```
export JAVA_HOME=/home/xface/android/jdk1.7.0
```

②`core-site.xml` 添加下面的配置

```
<property>
  <name>hadoop.tmp.dir</name>
  <value>/home/xface/hadoop/tmp</value>
  <description>A base for other temporary directories.</description>
</property>

<property>
  <name>fs.default.name</name>
  <value>hdfs://localhost:9000</value>
  <description>The name of the default file system.  A URI whose
  scheme and authority determine the FileSystem implementation.  The
  uri's scheme determines the config property (fs.SCHEME.impl) naming
  the FileSystem implementation class.  The uri's authority is used to
  determine the host, port, etc. for a filesystem.</description>
</property>
```

③`mapred-site.xml` 添加下面的配置

```
<property>
  <name>mapred.job.tracker</name>
  <value>localhost:9001</value>
  <description>The host and port that the MapReduce job tracker runs
  at.  If "local", then jobs are run in-process as a single map
  and reduce task.
  </description>
</property>
```

④`hdfs-site.xml` 添加下面的配置 [还可以配置namenode和datanode数据的保存位置，可以参见教程[田俊童鞋的Hadoop的安装部署与配置](http://www.tianjun.ml/essays/16)]

```
<property>
  <name>dfs.replication</name>
  <value>1</value>
  <description>Default block replication.
  The actual number of replications can be specified when the file is created.
  The default is used if replication is not specified in create time.
  </description>
</property>
```

(8)格式化namenode

```
hduser@ubuntu:~$ hadoop namenode -format
```

(9)执行`start-all.sh`启动测试

```
hduser@ubuntu:~$ start-all.sh
```

(10)执行`jps`查看进程

```
hduser@ubuntu:~$ jps
5620 JobTracker
5313 DataNode
5541 SecondaryNameNode
5897 Jps
5851 TaskTracker
5041 NameNode
```

OK！恭喜你！至此安装过程就大功告成了！如果比较心急，可以按照[推荐的教程](http://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-single-node-cluster/#running-a-mapreduce-job)运行个MapReduce任务试试看啦，哈哈哈

如果你需要配置成集群模式的话还是可以参考好友[田俊童鞋的Hadoop的安装部署与配置](http://www.tianjun.ml/essays/16)，如果喜欢的话不防看下好友的这篇[【翻译】Writing an Hadoop MapReduce Program in Python](http://www.tianjun.ml/essays/19)，不能推荐的更多，哈哈哈

安装过程中所有执行的命令及其输出见[这个Gist](https://gist.github.com/hujiaweibujidao/a83fca7b7f40d0029c60)
