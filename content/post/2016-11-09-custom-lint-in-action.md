---
title: Custom Lint in Action
categories: ["android"]
date: "2016-11-09"
---
本文记录为Android项目自定义Lint检查规则的实践研究。<!--more-->

Android Lint是Google提供的静态代码检查工具，使用Lint可以对Android项目源码进行扫描和检查，发现代码潜在的问题，或者辅助开发者统一编码规范。

Lint工具以及现有的检查项的源码在[android studio源码(aosp的一部分)的tools/base/lint目录](https://android.googlesource.com/platform/tools/base/+/master/lint)下，其中cli子目录是用来生成lint报告结果的，libs目录下才是核心源码，包括了lint-api、lint-checks、lint-tests三个子目录，分别是lint核心API、自带的lint检查项以及lint测试代码。

**如何查看目前已经有哪些lint检查项呢？**
打开AS的设置，找到Editor下面的Inspections即可看到现有的检查项，它们对应的源码可在上面的lint-checks中查看或者在这里在线查看: [lint-checks](https://android.googlesource.com/platform/tools/base/+/master/lint/libs/lint-checks/src/main/java/com/android/tools/lint/checks)，这也是学习如何自定义lint规则最好的学习资料。

**如何自定义lint规则以及如何应用规则？**
关于这部分内容最主要的教学文档就是[Google-自定义Lint规则说明文档](http://tools.android.com/tips/lint-custom-rules)，对应的[google sample项目源码](https://github.com/googlesamples/android-custom-lint-rules)，思路大致是利用lint-api创建自己的lint规则，然后将自定义的lint规则打包成jar(保存在build/libs中)，并复制到`~/.android/lint`目录下，最后在Android应用源码目录下执行`./gradlew lint`即可。这种方案的缺点是它针对的是本机的所有项目，也就是会影响同一台机器其他项目的Lint检查。

```
mkdir ~/.android/lint; cp ./build/libs/custom-lint.jar ~/.android/lint/
```

除了执行`./gradlew lint`命令之外，还可以使用AS自带的更好的一个代码检查功能，选择Analyze菜单下面的Inspect Code选项，然后选择某个目录执行lint检查。

![img](/images/as_inspectcode.png)

待执行完成之后可以看到下面的结果，其中我们自定义的lint规则的结果显示在Android Lint这个Category下面

![img](/images/as_lintresult.png)

**注意**：测试发现AS这块可能存在bug，如果修改了`~/.android/lint`目录下的jar的话，AS并不会重新加载，需要重启AS才行。另外，在`~/.android/lint`目录下存放多个jar也是可以的。

**Google方案的改进：LinkedIn的aar方案**
LinkedIn提供了另一种思路：将jar放到一个aar中，然后Android项目依赖这个aar完成自定义lint检查。利用这种方案我们就可以针对项目进行自定义Lint规则，lint.jar只对当前项目有效。详情参考[LinkedIn-自定义Lint规则并封装成aar的方案](https://engineering.linkedin.com/android/writing-custom-lint-checks-gradle)，它对应的lint demo项目源码包含两部分，一部分是[自定义lint规则-CustomLint项目](https://github.com/yangcheng/CustomLint)，另一部分是在Android工程中[使用lint规则-LintDemoApp项目](https://github.com/yangcheng/LintDemoApp)。

(1)CustomLint项目
该项目分成了两部分，一部分是lintrules，它依赖lint-api实现自定义的lint规则并打包成jar，存放在build/libs目录下；另一部分是lintlib，它将lintrules得到的jar复制到build/intermediates/lint目录下，并封装成一个aar，保存在build/outputs/aar目录下。

(2)LintDemoApp项目
该项目是一个示例，利用上面得到的aar封装成一个Android Library项目，然后核心模块app依赖它，这样当执行lint时就会自动将自定义的lint规则添加到lint规则集合中了。

**推荐在公司内部实施的Lint检查方案**
将自定义的lint规则打包成jar，接着封装成aar，然后上传到公司内部的artifactory，最后集成到各个应用中，利用AS的Lint检查功能对应用进行Lint检查即可。注意，这种方式并不会对生成的apk的大小产生任何影响。

这里我已经创建好了一个为了演示用的应用[customlint](https://github.com/hujiaweibujidao/customlint)，其中添加了一个LogDetector的lint规则。

完整的实现流程记录如下：
1.新建一个Android项目，添加一个空的Activity即可。
2.新建一个Java Library项目，添加依赖`compile 'com.android.tools.lint:lint-api:24.5.0'`，并编写lint规则，然后在build.gradle中配置，最后生成jar。
**注意**：这里最好是先测试一下jar，将jar复制到`~/.android/lint`目录下，然后在终端输入`lint --list`查看自定义的lint规则是否已经添加上了。
3.新建一个Android Library项目，删除没有用的test和androidTest相关的依赖和源码目录，然后参考Linkedin的方案添加一些配置，将上一步得到的jar封装到最终生成的aar中，最后将生成的aar上传到bintray或者jitpack。
4.在Android项目的build.gradle文件中添加对上面的aar的依赖，然后在MainActivity中写两个lint检查时会出错的情况，然后选择Analyze下面的Inspect Code选项，目录设置为app模块的根目录，即可看到lint的检查结果。

![img](/images/custom_lint.png)

**注意：该项目的release 1.0.0版本的lintrules依赖的是24.5.0版本的lint-api，演示的LogDetector来自下面参考资料中的美团的LogDetector。但是目前该项目最新的release 1.0.1版本依赖的是25.2.0版本的lint-api，演示的LogDetector参考自lint工具自带的LogDetector。**

**其他参考资料**
[美团-Android自定义Lint实践](http://tech.meituan.com/android_custom_lint.html)
[segmentfault-自定义Lint规则简介](https://segmentfault.com/a/1190000004497435)
[Android Studio配合Lint检测缺失Permission](http://www.jianshu.com/p/7b3519dc1e5f)
[Gradle Lint support](http://avatarqing.github.io/Gradle-Plugin-User-Guide-Chinese-Verision/testing/lint_supportlint.html)

OK，感兴趣的话欢迎阅读[customlint](https://github.com/hujiaweibujidao/customlint)项目源码，感谢Linkedin和MeiTuan提供的技术文档和实践源码。
