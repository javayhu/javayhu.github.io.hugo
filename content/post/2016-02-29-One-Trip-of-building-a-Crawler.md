---
title: One Trip of building a Crawler
tags: ["java"]
date: "2016-02-29"
---
最近需要从网上抓取大量的数据，于是体验了一下爬虫程序的开发和部署，主要是学会了一些实用工具的操作。 <!--more-->

本教程的开发需求是编写一个包含爬虫程序的Java项目，并且能够方便地服务器端编译部署和启动爬虫程序。

### 1.爬虫程序的开发
爬虫程序的开发比较简单，下面是一个简单的例子，其主要功能是爬取汉文学网中的新华字典中的所有汉字详情页面并保存到文件中。爬虫框架使用的是Crawl4j，它的好处是只需要配置爬虫框架的几个重要参数即可让爬虫开始工作：
(1)爬虫的数据缓存目录；
(2)爬虫的爬取策略，其中包括是否遵循robots文件、请求之间的延时、页面的最大深度、页面数量的控制等等；
(3)爬虫的入口地址；
(4)爬虫在遇到新的页面的url是通过`shouldVisit`来判断是否要访问这个url；
(5)爬虫访问(`visit`)那些url时具体的操作，比如将内容保存到文件中。

```
package data.hanwenxue;

import core.CommonUtil;
import data.CrawlHelper;
import edu.uci.ics.crawler4j.crawler.CrawlConfig;
import edu.uci.ics.crawler4j.crawler.CrawlController;
import edu.uci.ics.crawler4j.crawler.Page;
import edu.uci.ics.crawler4j.crawler.WebCrawler;
import edu.uci.ics.crawler4j.fetcher.PageFetcher;
import edu.uci.ics.crawler4j.parser.HtmlParseData;
import edu.uci.ics.crawler4j.robotstxt.RobotstxtConfig;
import edu.uci.ics.crawler4j.robotstxt.RobotstxtServer;
import edu.uci.ics.crawler4j.url.WebURL;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;

/**
 * 汉文学网的数据抓取工具，新华字典 http://zd.hwxnet.com/
 * <p/>
 * @author hujiawei 16/2/26
 */
public class ZDCrawlController extends WebCrawler {

    static Logger logger = LoggerFactory.getLogger(ZDCrawlController.class);

    //页面缓存路径
    public static final String PAGE_CACHE = "resources/cache_zd";

    //爬虫的起始页面模式
    public static final String BASE_URL = "http://zd.hwxnet.com/pinyin.html";//从拼音索引页面开始爬取

    //需要访问的页面的前缀
    public static final String PREFIX_URL = "http://zd.hwxnet.com/search";
    public static final String PREFIX_URL_PINYIN = "http://zd.hwxnet.com/pinyin";

    //爬虫的数目
    public static final int NUMBER_OF_CRAWLER = 4;

    /**
     * 启动爬虫
     */
    public void startCrawl() throws Exception {
        ////控制爬虫的缓存目录
        CrawlConfig config = new CrawlConfig();
        config.setCrawlStorageFolder(PAGE_CACHE);//如果目录不存在会创建

        config.setPolitenessDelay(1000);//控制请求之间的延时
        //config.setMaxDepthOfCrawling(2);//控制爬虫的最大深度
        //config.setMaxPagesToFetch(40);//控制最多要爬取的页面数目
        config.setIncludeBinaryContentInCrawling(false);//控制是否爬取二进制文件，例如图片、pdf等
        config.setResumableCrawling(true);//控制爬虫是否能够从中断中恢复 -> 设置为true的话重新运行将恢复到原来的进度

        //创建爬虫控制器
        PageFetcher pageFetcher = new PageFetcher(config);
        RobotstxtConfig robotstxtConfig = new RobotstxtConfig();
        //robotstxtConfig.setEnabled(false);//设置为不遵守robotstxt中的规定
        RobotstxtServer robotstxtServer = new RobotstxtServer(robotstxtConfig, pageFetcher);
        CrawlController controller = new CrawlController(config, pageFetcher, robotstxtServer);

        //添加爬虫的seed，即入口地址
        controller.addSeed(BASE_URL);

        //启动爬虫
        controller.start(ZDCrawlController.class, NUMBER_OF_CRAWLER);
    }

    /**
     * 控制某些url页面是否需要访问
     *
     * @param page page
     * @param url  url
     * @return 返回true表示需要访问，false表示不需要访问
     */
    @Override
    public boolean shouldVisit(Page page, WebURL url) {
        return url.getURL().startsWith(PREFIX_URL) || url.getURL().startsWith(PREFIX_URL_PINYIN);
    }

    /**
     * 控制抓取到的页面的处理方式
     *
     * @param page page
     */
    @Override
    public void visit(Page page) {
        int docid = page.getWebURL().getDocid();
        String url = page.getWebURL().getURL();
        //logger.info("info: {} {}", docid, url);
        if (null == url && url.equalsIgnoreCase("")) return;
        if (url.startsWith(PREFIX_URL_PINYIN)) return;

        String id, fileName;

        if (page.getParseData() instanceof HtmlParseData) {
            fileName = PAGE_CACHE + File.separator;//+ String.valueOf(docid)
            id = parseId(url);
            fileName = fileName + id + ".html";
            byte[] content = page.getContentData();
            CrawlHelper.savePage(fileName, content);
        }
    }

    //从url中获取id
    private String parseId(String url) {
        if (null == url || url.equalsIgnoreCase("")) return "";
        return url.substring(url.lastIndexOf("/") + 1, url.lastIndexOf("."));
    }


    public static void main(String[] args) {
        logger.error("============================================================================");
        logger.error("================================开始抓取数据==================================");
        logger.error("============================================================================");

        long start = System.currentTimeMillis();

        ZDCrawlController controller = new ZDCrawlController();
        try {
            controller.startCrawl();
        } catch (Exception e) {
            e.printStackTrace();
        }

        long end = System.currentTimeMillis();

        logger.error("============================================================================");
        logger.error("================================结束抓取数据==================================");
        logger.error("============================================================================");

        logger.error("抓取新华字典数据耗时约 " + CommonUtil.formatTime(end - start));
    }

}
```

### 2.项目的Maven化
我大致估算上面代码会运行半天左右，所以有必要将它放到服务器上去执行，因为实验室经常需要关闭电源总闸，不能保证一直运行。但是原始项目比较大，上面只是几只爬虫中的一只而已，所以我想将项目在服务器端部署一次，然后再依次启动爬虫。这个时候想到了Maven，项目之前只是使用Maven管理依赖项，并没有利用Maven太多其他的功能，于是先将项目Maven化，将结构调整为常见的Maven项目的形式。

```
<build>
    <!--配置构建项目时目录的类型-->
    <sourceDirectory>src/main/java</sourceDirectory>
    <testSourceDirectory>src/test/java</testSourceDirectory>
    <resources>
        <resource>
            <directory>resources</directory>
        </resource>
    </resources>
    <testResources>
        <testResource>
            <directory>resources</directory>
        </testResource>
    </testResources>
</build>
```

项目结构图
![image](/images/semanticweb_intellij.png)

使用Maven命令即可启动爬虫程序 `mvn exec:java -Dexec.mainClass="data.hanwenxue.ZDCrawlController"`

### 3.配置服务器端环境
服务器是我最不熟悉的CentOS，但是没办法，目前我也就只有这么一台可用的Server，硬着头皮干吧。

(1)安装Java 8
因项目中某个模块需要JDK 8，所以需要安装Java 8

```
1.wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u20-b26/jdk-8u20-linux-x64.rpm -O jdk-8u20-linux-x64.rpm
2.su - root
3.yum install jdk-8u20-linux-x64.rpm
4.Java8安装到/usr/java目录下
```

(2)安装Maven 3
采用Maven来管理项目，编译和运行程序

```
1.wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
2.yum install apache-maven
3.修改.bash_profile文件，添加JAVA_HOME的配置，将其设置为之前安装的JDK 8
export JAVA_HOME=/usr/java/jdk1.8.0_20
export PATH=$PATH:${JAVA_HOME}
4.mvn -v 测试下
```

(3)配置Git
利用Git来同步服务器端和我本机的代码

```
1.yum install git
2.新建ssh key并添加到Github配置中，参考https://help.github.com/articles/generating-an-ssh-key/
3.测试连接 ssh -T git@github.com
```

### 4.在服务器端运行爬虫
服务器端一次需要启动很多个爬虫，而且在断开ssh连接的时候这些爬虫要一直能够继续执行，这里需要用到一个很有意思的工具screen，除了上面的功能外，我还可以在下次ssh连接之后恢复之前的会话，相关教程请参考：[linux screen 命令详解](http://www.cnblogs.com/mchina/archive/2013/01/30/2880680.html)

具体的操作步骤如下：
(0)ssh连接服务器：`ssh username@host -p port`；
(1)克隆项目代码：`git clone xxx`；
(2)编译源码：`mvn compile`；
(3)新建screen：`screen -S yyy`；
(4)在新建的screen中启动爬虫：例如`mvn exec:java -Dexec.mainClass="data.hanwenxue.ZDCrawlController"`
(5)重复步骤3和4，启动完所有的爬虫。

下图是新华字典的爬虫的最后输出，显示总共耗时约6个小时
![image](/images/crawl_zd.png)

OK，就是这样，暂记于此，hope it helps！
