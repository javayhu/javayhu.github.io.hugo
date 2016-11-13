---
title: "Publish Gradle Android Library to jCenter Repository"
date: "2015-05-28"
tags: ["android"]
---
本文主要介绍如何通过Gradle将Android库项目上传到jCenter仓库中。 <!--more-->

经常使用开源项目的童鞋肯定很喜欢以Maven或者Gradle的形式来导入其他的开源库，但是那些开源库是怎么放到开源库的仓库中的呢？之前Android Studio默认使用的Maven Central仓库，现在改为使用jCenter仓库，感兴趣可以阅读[Android Studio – Migration from Maven Central to JCenter](http://blog.bintray.com/2015/02/09/android-studio-migration-from-maven-central-to-jcenter/)这篇文章了解下为什么。

#### 必要知识：Gradle

这里只是列举一些必要的关于Gradle的知识，具体的详细介绍可以参考其他文档，例如Gradle官网的[Gradle User Guide](https://docs.gradle.org/current/userguide/userguide.html)或者[http://tools.android.com/](http://tools.android.com/)的[Gradle Plugin User Guide](http://tools.android.com/tech-docs/new-build-system/user-guide)(也可以阅读我的注解版本[gradle-plugin-user-guide](http://hujiaweibujidao.github.io/blog/2014/10/13/gradle-plugin-user-guide-1/))。

关于如何在Android Studio中使用Gradle，可以看下这篇教程[Gradle Tutorial : Part 6 : Android Studio + Gradle](http://rominirani.com/2014/08/19/gradle-tutorial-part-6-android-studio-gradle/)。

下面是从[Gradle入门系列教程](http://blog.jobbole.com/71999/) (英文原版教程[点这里](http://www.petrikainulainen.net/programming/gradle/getting-started-with-gradle-introduction/))中摘取的重要知识，可以对Gradle做个大致了解。

(1)每一次Gradle的构建(build)都包含一个或者多个项目(project)，每个项目中又包含一个或者多个任务(task)

(2)Gradle的设计理念是：所有有用的特性都由Gradle插件提供。Gradle插件能够在项目中添加新任务；为新加入的任务提供默认配置；加入新的属性，可以覆盖插件的默认配置属性；为项目加入新的依赖。

(3)本质上说，仓库是一种存放依赖的容器，每一个项目都具备一个或多个仓库。Gradle支持以下仓库格式：Ivy仓库；Maven仓库；Flat directory仓库。

在加入Maven仓库时，Gradle提供了三种“别名”供我们使用，它们分别是：

`mavenCentral()`别名，表示依赖是从`Central Maven 2`仓库中获取的。    
`jcenter()`别名，表示依赖是从`Bintary’s JCenter Maven`仓库中获取的。    
`mavenLocal()`别名，表示依赖是从本地的Maven仓库中获取的。      

声明仓库示例(将Central Maven 2 仓库加入到构建中)：

```python
repositories {
    mavenCentral()
}
```

(4)最普遍的依赖称为外部依赖，这些依赖存放在外部仓库中。一个外部依赖可以由以下属性指定：

`group`属性指定依赖的分组（在Maven中，就是`groupId`）。    
`name`属性指定依赖的名称（在Maven中，就是`artifactId`）。     
`version`属性指定外部依赖的版本（在Maven中，就是`version`）。    

声明依赖格式：

```
dependencies {
    compile 'groupId:artifactId:version'
}
```
#### 使用`gradle-bintray-plugin`插件

下面进入今天的主题，讨论如何通过Gradle将Android库项目上传到jCenter仓库中。这方面的博客还是有一些的，考虑到我以后会经常用到，还是打算写一篇自己的心得体会。参考网址如下：

①[使用Gradle发布Android开源项目到JCenter](http://blog.csdn.net/maosidiaoxian/article/details/43148643)

②[Publishing Gradle Android Library to jCenter Repository](https://www.virag.si/2015/01/publishing-gradle-android-library-to-jcenter/)

中文版本 [使用Gradle发布项目到JCenter仓库](http://zhengxiaopeng.com/2015/02/02/%E4%BD%BF%E7%94%A8Gradle%E5%8F%91%E5%B8%83%E9%A1%B9%E7%9B%AE%E5%88%B0JCenter%E4%BB%93%E5%BA%93/)

详细步骤如下：

1.注册Bintray账号

网址：[https://bintray.com/](https://bintray.com/)

2.记录API Key

个人设置界面的左下角`API key`，复制保存该字符串

3.新建AS项目和库项目

在AS中新建项目，例如`Polaris`，再在项目中新建Module，选择Android Library Module，例如`lib4polaris`。

4.打开项目根目录下的`local.properties`文件(如果没有就新建一个)，输入你的Bintray账号的信息

```
bintray.user= [your name]
bintray.apikey= [your api key]
```

5.打开项目根目录下的`build.gradle`文件，修改`dependencies`部分，注意gradle需要使用`1.1.2`版本，如果使用的是`1.1.0`版本会出错的。另外添加两个重要的插件，其中`android-maven-plugin`插件用于生成JavaDoc和Jar文件等，`gradle-bintray-plugin`插件是用于上传项目到Bintray。

```
    dependencies {
        //when using gradle 1.1.0, there will be an error: Cannot call getBootClasspath() before setTargetInfo() is called
        //https://www.virag.si/2015/01/publishing-gradle-android-library-to-jcenter/
        classpath 'com.android.tools.build:gradle:1.1.2' //

        classpath 'com.jfrog.bintray.gradle:gradle-bintray-plugin:1.0'
        classpath 'com.github.dcendents:android-maven-plugin:1.2'

        // NOTE: Do not place your application dependencies here; they belong
        // in the individual module build.gradle files
    }
```

6.打开库项目`lib4polaris`中的`build.gralde`文件，修改成以下内容，其中注释了`#CONFIG#`的地方都可以根据实际情况进行修改。下面的内容中添加了很多操作，例如定义pom并打包aar，打包javadocjar和sourcejar，上传到Jcenter仓库等。

更多关于配置上传到Bintray的参数可以参见项目[gradle-bintray-plugin](https://github.com/bintray/gradle-bintray-plugin)。


```
apply plugin: 'com.android.library'

apply plugin: 'com.github.dcendents.android-maven'
apply plugin: 'com.jfrog.bintray'

version = "1.0.0"                                                              // #CONFIG# // project version

android {
    compileSdkVersion 22
    buildToolsVersion "22.0.1"
    resourcePrefix "polaris_"                                                  // #CONFIG# // resource prefix

    defaultConfig {
        minSdkVersion 9
        targetSdkVersion 22
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    compile fileTree(dir: 'libs', include: ['*.jar'])
    compile 'com.android.support:appcompat-v7:22.1.1'
    compile 'com.android.support:support-v4:22.1.1'
}


def siteUrl = 'https://github.com/hujiaweibujidao/Polaris'                    // #CONFIG# // project homepage
def gitUrl = 'https://github.com/hujiaweibujidao/Polaris.git'                 // #CONFIG# // project git url
def issueUrl = 'https://github.com/hujiaweibujidao/Polaris/issues'            // #CONFIG# // project issue url
group = "hujiaweibujidao.github.io"                                           // #CONFIG# // Maven Group ID for the artifact (pageckage name is ok)


//generate javadoc and jar

install {
    repositories.mavenInstaller {
        // generates POM.xml with proper parameters
        pom {
            project {
                packaging 'aar'
                name 'Polaris Library For Android'                             // #CONFIG# // project title
                url siteUrl
                // Set your license
                licenses {
                    license {
                        name 'The Apache Software License, Version 2.0'
                        url 'http://www.apache.org/licenses/LICENSE-2.0.txt'
                    }
                }
                developers {
                    developer {
                        id 'hujiaweibujidao'                                  // #CONFIG# // your user id (you can write your nickname)
                        name 'hujiawei'                                       // #CONFIG# // your user name
                        email 'hujiawei090807@gmail.com'                      // #CONFIG# // your email
                    }
                }
                scm {
                    connection gitUrl
                    developerConnection gitUrl
                    url siteUrl
                }
            }
        }
    }
}

task sourcesJar(type: Jar) {
    from android.sourceSets.main.java.srcDirs
    classifier = 'sources'
}

task javadoc(type: Javadoc) {
    source = android.sourceSets.main.java.srcDirs
    classpath += project.files(android.getBootClasspath().join(File.pathSeparator))
}

task javadocJar(type: Jar, dependsOn: javadoc) {
    classifier = 'javadoc'
    from javadoc.destinationDir
}

artifacts {
    archives javadocJar
    archives sourcesJar
}


//bintray upload

Properties properties = new Properties()
properties.load(project.rootProject.file('local.properties').newDataInputStream())
bintray {
    user = properties.getProperty("bintray.user")
    key = properties.getProperty("bintray.apikey")
    configurations = ['archives']
    pkg {
        repo = "maven"
        name = "polaris"                                                   // #CONFIG# project name in jcenter
        desc = 'A helpful library for Android named Polaris.'
        websiteUrl = siteUrl
        vcsUrl = gitUrl
        issueTrackerUrl = issueUrl
        licenses = ["Apache-2.0"]
        labels = ['android']
        publish = true
        publicDownloadNumbers = true
    }
}
```

7.选择工具栏中的`Sync projects with Gradle files`对项目进行重建，然后可以看到Gradle视图中的Task中出现了`bintrayUpload`，双击即可将项目上传到Bintray中。

![image](/images/polaris_bintray.png)

8.在详情页中找到Maven Central标签，鼠标放上去它会提示你去提交到jCenter进行审核，点击进入后，写点内容就可以了，等待审核需要一定的时间。

![image](/images/jcenter_include.png)

9.审核通过之后，就可以在项目中通过很简单的方式来使用这个库项目了。



10.前面指定了项目关联的Git网址，但是实际上并没有上传Github上，下面的操作可以简单地在Android Studio中实现。

![image](/images/share_project_on_github.png)

上传之后即可在Github中看到你的该项目。

题外话：

1.关于搜索顺序

下面其实是一次搜索报错，然后列出了Gradle搜索该library的顺序，感觉还是蛮有信息量的。

```
Could not find hujiaweibujidao.github.io:polaris:1.0.1.
Searched in the following locations:
    https://jcenter.bintray.com/hujiaweibujidao/github/io/polaris/1.0.1/polaris-1.0.1.pom
    https://jcenter.bintray.com/hujiaweibujidao/github/io/polaris/1.0.1/polaris-1.0.1.jar
    file:/Users/hujiawei/Android/android_sdk/extras/android/m2repository/hujiaweibujidao/github/io/polaris/1.0.1/polaris-1.0.1.pom
    file:/Users/hujiawei/Android/android_sdk/extras/android/m2repository/hujiaweibujidao/github/io/polaris/1.0.1/polaris-1.0.1.jar
    file:/Users/hujiawei/Android/android_sdk/extras/google/m2repository/hujiaweibujidao/github/io/polaris/1.0.1/polaris-1.0.1.pom
    file:/Users/hujiawei/Android/android_sdk/extras/google/m2repository/hujiaweibujidao/github/io/polaris/1.0.1/polaris-1.0.1.jar
```

从上面的输出可以看出，先是在Bintray上的对应位置找，如果没找到尝试在本地的android目录下的m2repository中找，如果还是没有找到，就在本地的google目录下的m2repository中找，如果还是没有找到，那就提示出错。

2.关于版本

有些时候同一个版本号多次执行`bintrayUpload`任务会报错，这个时候有两种选择，要么修改`version`，要么在Bintray中删除该版本。

另外，如果提示`xxx.jar`等文件找不到，可以先执行`install`任务，然后再执行`bintrayUpload`任务。

3.关于引用

审核通过之后，我先是使用`hujiaweibujidao.github.io:polaris:1.0.0`作为引用来导入，可是发现一直提示找不到！最后在Bintray中的`Files`中发现，pom以及jar等文件的命名是以`lib4polaris-x.y.z`开头的，也就是默认情况下是以我创建的Android Library Module的名称作为开始，因为上传本身也是发生在这个库项目的`build.gradle`中的。所以，如果改为使用`hujiaweibujidao.github.io:lib4polaris:1.0.0`即可引用到了。但是，如何自定义`artifactId`呢？这里有个对于该问题的讨论你可以试下，[https://github.com/dcendents/android-maven-gradle-plugin/issues/9](https://github.com/dcendents/android-maven-gradle-plugin/issues/9)，其中msdx最后给出了他的方案，详情可以参考他的项目[https://github.com/msdx/gradle-publish](https://github.com/msdx/gradle-publish)。

#### 使用`bintray-release`插件

该插件使得上传library到Bintray上更加简单，项目源码地址：[novoda/bintray-release](https://github.com/novoda/bintray-release)

参考教程：[上传android library 到bintray](http://www.jianshu.com/p/499a086e3bab)
