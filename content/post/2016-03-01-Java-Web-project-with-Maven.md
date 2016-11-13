---
title: Java Web project with Maven
tags: ["java"]
date: "2016-03-01"
---
最近需要构建一个Java web项目，然后做文本分析和挖掘，于是又体验了下Maven构建Java Web项目的快感。 <!--more-->

毕业需求是第一驱动力啊！毕业之后一定远离学术圈！

本教程的开发需求很简单，就是搭建一个Java Web项目，并且能够使用Maven将项目热部署到服务器端即可。

1.配置服务器端Tomcat的`conf/tomcat-users.xml`文件，注意要分配`manager-script`的权限，本教程中Tomcat版本是6.0。

```
<role rolename="admin-gui"/>
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<user username="admin" password="admin" roles="admin-gui,manager-gui,manager-script"/>
```

2.在本地的`{USER_HOME}/.m2/settings.xml`文件中插入一个server的配置，其中的id可以随便给定，账号密码是服务器端Tomcat的用户的账号密码。

```
<servers>
     <server>
       <id>tomcat6</id>
       <username>admin</username>
       <password>admin</password>
     </server>
</servers>
```

3.在本地使用Maven新建一个Java Web项目，其中的参数可以自行配置

```
mvn archetype:generate -DgroupId=edukb.org -DartifactId=annomatic -DarchetypeArtifactId=maven-archetype-webapp
```

4.IDE的话这里使用IntelliJ，打开IntelliJ之后选择`File -> Open...`，然后选中刚才目录中的`pom.xml`文件即可

5.项目打开之后，修改`pom.xml`文件，特别注意下`tomcat6-maven-plugin`插件的配置即可

```
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>edukb.org</groupId>
    <artifactId>annomatic</artifactId>
    <packaging>war</packaging>
    <version>1.0</version>

    <name>annomatic</name>
    <url>http://edukb.org</url>
    <description>For automatic annotations.</description>

    <dependencies>

        <!-- java web servlet+jsp -->
        <dependency>
            <groupId>org.apache.tomcat</groupId>
            <artifactId>servlet-api</artifactId>
            <version>6.0.29</version>
            <scope>provided</scope>
        </dependency>

        <dependency>
            <groupId>org.apache.tomcat</groupId>
            <artifactId>jsp-api</artifactId>
            <version>6.0.29</version>
            <scope>provided</scope>
        </dependency>

    </dependencies>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <build>
        <finalName>annomatic</finalName>
        <plugins>
            <!-- 热部署到Tomcat6服务器上 -->
            <plugin>
                <groupId>org.apache.tomcat.maven</groupId>
                <artifactId>tomcat6-maven-plugin</artifactId>
                <version>2.2</version>
                <configuration>
                    <path>/annomatic</path>
                    <url>http://{host}:{port}/manager/</url>
                    <server>tomcat6</server>
                    <username>admin</username>
                    <password>admin</password>
                    <update>true</update>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

6.在终端运行`mvn tomcat6:deploy`即可将项目部署到服务器端，如果已经部署过了就执行`mvn tomcat6:redeploy`更新

注意事项：如果使用的是Tomcat7，那么使用`tomcat7-maven-plugin`插件，并且url配置为`http://{host}:{port}/manager/text`

参考网址：
1.[开发过程使用Tomcat Maven插件持续快捷部署Web项目](http://www.open-open.com/lib/view/open1413071738078.html)
2.[maven+tomcat6-maven-plugin实现热部署及调试](http://www.tuicool.com/articles/J3imY3M)
3.[使用Maven自动部署Java Web项目到Tomcat问题小记](http://www.tuicool.com/articles/aM3aEf)
4.[使用Maven创建Web应用程序项目](http://www.yiibai.com/maven/create-a-web-application-project-with-maven.html)

OK，就是这样啦，hope it helps!
