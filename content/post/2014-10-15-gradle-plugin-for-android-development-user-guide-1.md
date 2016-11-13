---
title: "Gradle Plugin for Android Development User Guide 1"
date: "2014-10-13"
tags: ["android"]
---
Gradle Plugin for Android Development User Guide (1) <!--more-->

终于有点时间可以学学一直打算了解的Gradle，毕竟打算以后在移动开发这条路上走到黑的话就要与时俱进，首先自然得用Google推荐的Android Studio，就目前来看，它除了还未完全支持NDK之外，很多方面都是完爆Eclipse+ADT Plugin的，而新的构建系统Gradle更是不能不了解的内容，于是找了些有用的资料开始上手看。如果你一般都是进行常规的Android SDK的开发而且对Gradle没啥兴趣的话那么直接看这篇官网教程就行了[http://developer.android.com/sdk/installing/studio-build.html](http://developer.android.com/sdk/installing/studio-build.html)。

而本篇文章来自[http://tools.android.com/](http://tools.android.com/)的`Gradle Plugin User Guide`我想应该是最好的读物了，于是细细地通读了一下，边读边注解，注意不是翻译，因为宝贵的时间有限而且原文并不难懂，所以只能是挑重要的内容注解一下，以便以后用到的时候能够更快的检索到重要信息。

文中标有`[?]`的地方表示我没有理解，如有理解了的或者文中有任何错误烦请留言告知，不胜感激！

原文地址：[http://tools.android.com/tech-docs/new-build-system/user-guide](http://tools.android.com/tech-docs/new-build-system/user-guide)

因为注解完之后文章变得特别长，所以分成2部分，第二部分地址：[/blog/2014/10/15/gradle-plugin-user-guide-2](/blog/2014/10/15/gradle-plugin-user-guide-2/)

### Introduction

This documentation is for the Gradle plugin version 0.9. Earlier versions may differ due to non-compatible we are introducing before 1.0.

### Goals of the new Build System

The goals of the new build system are:

Make it easy to reuse code and resources       
Make it easy to create several variants of an application, either for multi-apk distribution or for different flavors of an application      
Make it easy to configure, extend and customize the build process     
Good IDE integration    

### Why Gradle?

Gradle is an advanced build system as well as an advanced build toolkit allowing to create custom build logic through plugins.

Here are some of its features that made us choose Gradle:      

Domain Specific Language (DSL) to describe and manipulate the build logic      
Build files are Groovy based and allow mixing of declarative elements through the DSL and using code to manipulate the DSL elements to provide custom logic.      
Built-in dependency management through Maven and/or Ivy.       
Very flexible. Allows using best practices but doesn’t force its own way of doing things.       
Plugins can expose their own DSL and their own API for build files to use.
Good Tooling API allowing IDE integration      

[总结起来就是：DSL(Domain Specific Language ) + Groovy based Build files + Maven/Ivy based Dependency Management + Plugin Supported]

### Requirements

Gradle 1.10 or 1.11 or 1.12 with the plugin 0.11.1      
SDK with Build Tools 19.0.0. Some features may require a more recent version.

### Basic Project

A Gradle project describes its build in a file called `build.gradle` located in the root folder of the project.

####  Simple build files

The most simple Java-only project has the following `build.gradle`:

```java
apply plugin: 'java'
```

This applies the Java plugin, which is packaged with Gradle. The plugin provides everything to build and test Java applications.

The most simple Android project has the following `build.gradle`:

```
buildscript {
    repositories {
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:0.11.1'
    }
}

apply plugin: 'android'

android {
    compileSdkVersion 19
    buildToolsVersion "19.0.0"
}
```

There are 3 main areas to this Android build file:

(1) `buildscript { ... }` configures the code driving the build.
In this case, this declares that it uses the Maven Central repository, and that there is a classpath dependency on a Maven artifact. This artifact is the library that contains the Android plugin for Gradle in version 0.11.1

**Note: This only affects the code running the build, not the project. The project itself needs to declare its own repositories and dependencies. This will be covered later.**

[注意：这里定义的repository和dependency只是build需要的，项目还需要定义自己的repository和dependency]

(2) Then, the android plugin is applied like the Java plugin earlier.

(3) Finally, `android { ... } `configures all the parameters for the android build. This is the entry point for the Android DSL.

**By default, only the compilation target, and the version of the build-tools are needed. This is done with the compileSdkVersion and buildtoolsVersion properties.**

[默认情况下，只有编译目标和编译工具的版本号是必须要给定的。以前的build系统需要在项目的根目录下的`project.properties` 文件中指定`target` (例如`target=android-18`)，它对应的就是这里的 `compilation target`，不过此处的值只是一个int值，代表Android API version]

The compilation target is the same as the target property in the `project.properties` file of the old build system. This new property can either be assigned a int (the api level) or a string with the same value as the previous target property.

**Important: You should only apply the android plugin. Applying the java plugin as well will result in a build error.**

[注意：这里只能使用android插件，写成java插件会出现build错误]

Note: You will also need a `local.properties` file to set the location of the SDK in the same way that the existing SDK requires, using the `sdk.dir` property.

Alternatively, you can set an environment variable called `ANDROID_HOME`. There is no differences between the two methods, you can use the one you prefer.

关于设置Android SDK的位置有两种方式：

（1）在项目根目录的`local.properties` 文件中指定`sdk.dir` 的值，如果包含ndk的话同时还要指定`ndk.dir` 的值

```
sdk.dir=/Volumes/hujiawei/Users/hujiawei/Android/android_sdk
ndk.dir=/Volumes/hujiawei/Users/hujiawei/Android/android_ndk
```
（2）在系统中设置环境变量`ANDROID_HOME`

####  Project Structure

The basic build files above expect a default folder structure. Gradle follows the concept of convention over configuration, providing sensible default option values when possible.    

[Gradle遵循大家约定俗成的Android项目目录结构和项目配置，一个基本的项目开始时包含了两个源码集合，即main source code和test source code，它们各自的源码目录下有分别包含了Java source code和Java resource]

The basic project starts with two components called `“source sets”`. The main source code and the test code. These live respectively in:

```
src/main/
src/androidTest/
```

Inside each of these folders exists folder for each source components.
For both the Java and Android plugin, the location of the Java source code and the Java resources:

```
java/
resources/
```

For the Android plugin, extra files and folders specific to Android:

```
AndroidManifest.xml
res/
assets/
aidl/
rs/
jni/
```

Note: `src/androidTest/AndroidManifest.xml` is not needed as it is created automatically.

[Android插件对于Android项目还指定了一些其他的目录，注意test目录下的`AndroidManifest.xml` 文件不需要提供，因为它会自动创建，后面会提到为什么]

####  Configuring the Structure

[当我们的项目原本的目录结构和上面默认的目录结构不同时，我们可以进行配置，使用`sourceSets` 节点来修改目录结构]

When the default project structure isn’t adequate, it is possible to configure it. According to the Gradle documentation, reconfiguring the `sourceSets` for a Java project can be done with the following:

```
sourceSets {
    main {
        java {
            srcDir 'src/java'
        }
        resources {
            srcDir 'src/resources'
        }
    }
}
```

**Note: srcDir will actually add the given folder to the existing list of source folders (this is not mentioned in the Gradle documentation but this is actually the behavior).**

[`srcDir` 会自动将给定的目录加入到默认的已有的源码目录列表中，然而`srcDirs` 会覆盖默认的源码目录设置]

To replace the default source folders, you will want to use `srcDirs` instead, which takes an array of path. This also shows a different way of using the objects involved:

```
sourceSets {
    main.java.srcDirs = ['src/java']
    main.resources.srcDirs = ['src/resources']
}
```

For more information, see the Gradle documentation on the [Java plugin here](http://www.gradle.org/docs/current/userguide/java_plugin.html).

[Android插件使用和上面相似的语法来完成配置，只不过它的`sourceSets` 节点是定义在 `android` 中的]

The Android plugin uses a similar syntaxes, but because it uses its own `sourceSets`, this is done within the `android` object.

Here’s an example, using the old project structure for the main code and remapping the `androidTest` sourceSet to the `tests` folder:

```
android {
    sourceSets {
        main {
            manifest.srcFile 'AndroidManifest.xml'
            java.srcDirs = ['src']
            resources.srcDirs = ['src']
            aidl.srcDirs = ['src']
            renderscript.srcDirs = ['src']
            res.srcDirs = ['res']
            assets.srcDirs = ['assets']
        }

        androidTest.setRoot('tests')
    }
}
```

Note: because the old structure put all source files (java, aidl, renderscript, and java resources) in the same folder, we need to remap all those new components of the sourceSet to the same src folder.

[`setRoot()` 会将整个sourceSet包括其中的子目录一起移动到新的目录中，这是Android插件特定的，Java插件没有此功能]

Note: `setRoot()` moves the whole sourceSet (and its sub folders) to a new folder. This moves `src/androidTest/*` to `tests/*`

This is Android specific and will not work on Java sourceSets.

The ‘migrated’ sample shows this. [?]

### Build Tasks

####  General Tasks

[使用plugin的好处是它会自动地帮我们创建一些默认的build task]

Applying a plugin to the build file automatically creates a set of build tasks to run. Both the Java plugin and the Android plugin do this.

The convention for tasks is the following: [下面是默认的build tasks]

`assemble`   The task to assemble the output(s) of the project       
`check`   The task to run all the checks.       
`build`   This task does both assemble and check      
`clean`    This task cleans the output of the project        

**[任务assemble，check，build实际上什么都没有做，它们只是anchor task，需要添加实际的task它们才知道如何工作，这样的话就可以不管你是什么类型的项目都可以调用相同名称的build task。例如如果使用了`findbugs` 插件的话，它会自动创建一个新的task，而且check task会依赖它，也就有是说，每当check task执行的时候，这个新的task都会被调用而执行]**

**The tasks assemble, check and build don’t actually do anything. They are anchor tasks for the plugins to add actual tasks that do the work.**

This allows you to always call the same task(s) no matter what the type of project is, or what plugins are applied.

For instance, applying the `findbugs` plugin will create a new task and make `check` depend on it, making it be called whenever the `check` task is called.

From the command line you can get the high level task running the following command:   `gradle tasks`      
For a full list and seeing dependencies between the tasks run:  `gradle tasks --all`

[在Android Studio的Terminal中运行结果如下]

![image](/images/gradle1.png)

Note: Gradle automatically monitor the declared inputs and outputs of a task. Running the build twice without change will make Gradle report all tasks as UP-TO-DATE, meaning no work was required. This allows tasks to properly depend on each other without requiring unneeded build operations.

**[Gradle会监视一个任务的输入和输出，重复运行build结果都没有变化的话Gradle会提示所有的任务都是UP-TO-DATE，这样可以避免不必要的build操作]**

####  Java project tasks

[Java插件主要创建了两个新的task，其中`jar` task是`assemble` task的依赖项，`test` task是`check` task的依赖项]

The Java plugin creates mainly two tasks, that are dependencies of the main anchor tasks:

`assemble`  ->   `jar`   This task creates the output.       
`check`  ->    `test`  This task runs the tests.       

**[任务jar直接或者间接地依赖其他的任务，例如用来编译Java代码的任务`classes`； 测试代码是由`testClasses` 任务来编译的，但是你不需要去调用这个task，因为`test` 任务依赖于`testClasses` 和 `classes` 任务]**

The `jar` task itself will depend directly and indirectly on other tasks: `classes` for instance will compile the Java code.

** The tests are compiled with `testClasses`, but it is rarely useful to call this as `test` depends on it (as well as `classes`). **

In general, you will probably only ever call `assemble` or `check`, and ignore the other tasks.

You can see the full set of tasks and their descriptions for the [Java plugin here](http://gradle.org/docs/current/userguide/java_plugin.html).

####  Android tasks

The Android plugin use the same convention to stay compatible with other plugins, and adds an additional anchor task:

`assemble`    The task to assemble the output(s) of the project        
`check`   The task to run all the checks.            
`connectedCheck`   Runs checks that requires a connected device or emulator, they will run on all connected devices in parallel. **[在已连接的设备和模拟器上并行运行check任务]**                
`deviceCheck`   Runs checks using APIs to connect to remote devices. This is used on CI servers.  **[使用APIs来连接远程设备以运行check任务]**                           
`build`   This task does both assemble and check       
`clean`    This task cleans the output of the project

The new anchor tasks are necessary in order to be able to run regular checks without needing a connected device.Note that build does not depend on deviceCheck, or connectedCheck.

**[任务build并不依赖deviceCheck和connectedCheck这两个任务]**

An Android project has at least two outputs: a debug APK and a release APK. Each of these has its own anchor task to facilitate building them separately:

[Android项目至少有两个输出：一个debug模式的APK，另一个是release模式deAPK，每种模式都有自己的anchor task以便于将它们的build过程分开]

`assemble`     
`assembleDebug`      
`assembleRelease`     

They both depend on other tasks that execute the multiple steps needed to build an APK. The `assemble` task depends on both, so calling it will build both APKs.

**Tip: Gradle support camel case shortcuts for task names on the command line.**

[Gradle支持在命令行中使用某个task的名称的camel case缩写调用这个task]

 For instance:   `gradle aR`  is the same as typing  `gradle assembleRelease`，as long as no other task match `‘aR’`

The `check` anchor tasks have their own dependencies:

`check`        
`lint`      
`connectedCheck`      
`connectedAndroidTest`      
`connectedUiAutomatorTest `(not implemented yet)      
`deviceCheck`      

This depends on tasks created when other plugins implement test extension points.

**Finally, the plugin creates `install/uninstall` tasks for all build types (debug, release, test), as long as they can be installed (which requires signing).**

[Android插件还会对所有build type创建它们的`install/uninstall` 任务，只要它们可以被安装，安装需要签名]

### Basic Build Customization

The Android plugin provides a broad DSL to customize most things directly from the build system.

####  Manifest entries

[通过DSL我们可以在`build.gradle` 文件中指定那些定义在AndroidManifest文件中的内容，不过能够指定的内容有限]

Through the DSL it is possible to configure the following manifest entries:

`minSdkVersion`      
`targetSdkVersion`     
`versionCode`     
`versionName`     
`applicationId` (the effective packageName -- see [ApplicationId versus PackageName](http://tools.android.com/tech-docs/new-build-system/applicationid-vs-packagename) for more information)      
`Package Name` for the test application     
`Instrumentation test runner`     

Example:

```
android {
    compileSdkVersion 19
    buildToolsVersion "19.0.0"

    defaultConfig {
        versionCode 12
        versionName "2.0"
        minSdkVersion 16
        targetSdkVersion 16
    }
}
```

The `defaultConfig` element inside the android element is where all this configuration is defined.

**Previous versions of the Android Plugin used `packageName` to configure the manifest 'packageName' attribute. Starting in 0.11.0, you should use `applicationId` in the `build.gradle` to configure the manifest 'packageName' entry. This was disambiguated to reduce confusion between the application's packageName (which is its ID) and java packages.**

[从Gradle Plugin 0.11.0 版本开始在`build.gradle` 文件中使用`applicationId` 而不是 `packageName` 来指定AndroidManifest文件中的`packageName`]

The power of describing it in the build file is that it can be dynamic.
For instance, one could be reading the version name from a file somewhere or using some custom logic:

[将上面那些内容定义在build文件中的魔力就在于它们可以是动态的，如下所示]

```
def computeVersionName() {
    ...
}

android {
    compileSdkVersion 19
    buildToolsVersion "19.0.0"

    defaultConfig {
        versionCode 12
        versionName computeVersionName()
        minSdkVersion 16
        targetSdkVersion 16
    }
}
```

[注意不要使用当前域中已有的getter方法作为自定义的函数名，否则会发生冲突]

**Note: Do not use function names that could conflict with existing getters in the given scope. For instance instance `defaultConfig { ...}` calling `getVersionName()` will automatically use the getter of `defaultConfig.getVersionName()` instead of the custom method.**

If a property is not set through the DSL, some default value will be used. Here’s a table of how this is processed.

![image](/images/gradle2.png)

**[第2列是当你在build script中使用自定义逻辑去查询第1列元素对应的默认结果，如果结果不是你想要的话，你可以指定另一个结果，但是在build时如果这个结果是null的话，build系统就会使用第3列中的结果]**

The value of the 2nd column is important if you use custom logic in the build script that queries these properties. For instance, you could write:

```
if (android.defaultConfig.testInstrumentationRunner == null) {
    // assign a better default...
}
```

If the value remains null, then it is replaced at build time by the actual default from column 3, but the DSL element does not contain this default value so you can't query against it.

This is to prevent parsing the manifest of the application unless it’s really needed.

#### Build Types

[默认情况下，Android插件会自动将原项目编译成debug和release两个版本，它们的区别在于调试程序的功能和APK的签名方式。debug版本使用`key/certificate` 来签名，而release版本在build过程中并不签名，它的签名过程发生在后面。Android插件允许我们自定义build type]

By default, the Android plugin automatically sets up the project to build both a debug and a release version of the application.

**These differ mostly around the ability to debug the application on a secure (non dev) devices, and how the APK is signed.**

**The debug version is signed with a `key/certificate` that is created automatically with a known `name/password` (to prevent required prompt during the build). The release is not signed during the build, this needs to happen after.**

This configuration is done through an object called a `BuildType`. By default, 2 instances are created, a `debug` and a `release` one.

The Android plugin allows customizing those two instances as well as creating other Build Types. This is done with the `buildTypes` DSL container:

```
android {
    buildTypes {
        debug {
            applicationIdSuffix ".debug"
        }

        jnidebug.initWith(buildTypes.debug)
        jnidebug {
            packageNameSuffix ".jnidebug"
            jnidebugBuild true
        }
    }
}
```

The above snippet achieves the following:

Configures the default debug Build Type:

(1) set its package to be `<app appliationId>.debug` to be able to install both debug and release apk on the same device

(2) Creates a new BuildType called jnidebug and configure it to be a copy of the debug build type.

(3) Keep configuring the jnidebug, by enabling debug build of the JNI component, and add a different package suffix.

[在buildTypes容器中创建一个新的build type很简单，要么调用`initWith()` 方法继承自某个build type或者直接使用花括号来配置它]

Creating new Build Types is as easy as using a new element under the buildTypes container, either to call `initWith()` or to configure it with a closure.

The possible properties and their default values are:

![image](/images/gradle3.png)

In addition to these properties, Build Types can contribute to the build with code and resources.

**[对于每个build type都会生成一个对应的`sourceSet`，默认的位置是`src/<buildtypename>/` ，所以build type的名称不能是`main`或者`androidTest`，而且它们相互之间不能重名]**

For each Build Type, a new matching `sourceSet` is created, with a default location of  `src/<buildtypename>/`

This means the Build Type names cannot be main or androidTest (this is enforced by the plugin), and that they have to be unique to each other.

Like any other source sets, the location of the build type source set can be relocated:

```
android {
    sourceSets.jnidebug.setRoot('foo/jnidebug')
}
```

[类似其他的sourceSet，build type的source set的位置也可以重新定义，此外，对于每个build type，都会自动创建一个名为`assemble<BuildTypeName>` 的任务，而且自动称为`assemble` 任务的依赖项]

Additionally, for each Build Type, a new `assemble<BuildTypeName>` task is created.

The `assembleDebug` and `assembleRelease` tasks have already been mentioned, and this is where they come from. When the debug and release Build Types are pre-created, their tasks are automatically created as well.

The `build.gradle` snippet above would then also generate an `assembleJnidebug` task, and `assemble` would be made to depend on it the same way it depends on the `assembleDebug` and `assembleRelease` tasks.

Tip: remember that you can type gradle aJ to run the assembleJnidebug task.

Possible use case: [使用场景]

Permissions in debug mode only, but not in release mode      
Custom implementation for debugging     
Different resources for debug mode (for instance when a resource value is tied to the signing certificate).      

**[build type的code/resources的处理过程: (1)Manifest整合进app的Manifest; (2)code就作为另一个源码目录; (3)resources覆盖原有的main resources]**

The code/resources of the BuildType are used in the following way:

The manifest is merged into the app manifest      
The code acts as just another source folder     
The resources are overlayed over the main resources, replacing existing values.

#### Signing Configurations     

Signing an application requires the following:

A keystore      
A keystore password     
A key alias name     
A key password     
The store type     

The location, as well as the key name, both passwords and store type form together a Signing Configuration (type `SigningConfig`)     

**[对一个应用程序进行签名需要5个信息，这些信息组合起来就是类型SigningConfig。默认情况下，debug的配置使用了一个已知密码的keystore和已知密码的默认key，其中的keystore保存在`$HOME/.android/debug.keystore` 文件中，如果没有的话它会自动被创建]**

By default, there is a `debug` configuration that is setup to use a debug keystore, with a known password and a default key with a known password.The debug keystore is located in `$HOME/.android/debug.keystore`, and is created if not present.

The debug Build Type is set to use this debug SigningConfig automatically.It is possible to create other configurations or customize the default built-in one. This is done through the signingConfigs DSL container:

[默认情况下，debug的build过程会自动使用debug SigningConfig，当然我们可以自己定义]

```
android {
    signingConfigs {
        debug {
            storeFile file("debug.keystore")
        }

        myConfig {
            storeFile file("other.keystore")
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
        }
    }

    buildTypes {
        foo {
            debuggable true
            jniDebugBuild true
            signingConfig signingConfigs.myConfig
        }
    }
}
```

The above snippet changes the location of the debug keystore to be at the root of the project. This automatically impacts any Build Types that are set to using it, in this case the debug Build Type.

It also creates a new Signing Config and a new Build Type that uses the new configuration.

**[只有当debug keystore是放在默认的位置，即使修改了keystore文件的名称，keystore也会被自动创建，但是如果改变了默认位置的话则不会被自动创建。此外，设置keystore的位置一般使用相对于项目根目录的路径，虽然也可以使用绝对路径，但是并不推荐这样做]**

Note: Only debug keystores located in the default location will be automatically created. Changing the location of the debug keystore will not create it on-demand. Creating a SigningConfig with a different name that uses the default debug keystore location will create it automatically. In other words, it’s tied to the location of the keystore, not the name of the configuration.

Note: Location of keystores are usually relative to the root of the project, but could be absolute paths, though it is not recommended (except for the debug one since it is automatically created).

Note:  If you are checking these files into version control, you may not want the password in the file. The following Stack Overflow post shows ways to read the values from the console, or from environment variables.
http://stackoverflow.com/questions/18328730/how-to-create-a-release-signed-apk-file-using-gradle

We'll update this guide with more detailed information later.

#### Running ProGuard

[对ProGuard的支持是通过Gradle plugin for ProGuard 4.10来实现的，给build type添加`runProguard` 属性即可自动生成相应的task]

ProGuard is supported through the Gradle plugin for ProGuard version 4.10.

The ProGuard plugin is applied automatically, and the tasks are created automatically if the Build Type is configured to run ProGuard through the `runProguard` property.

```
android {
    buildTypes {
        release {
            runProguard true
            proguardFile getDefaultProguardFile('proguard-android.txt')
        }
    }

    productFlavors {
        flavor1 {
        }
        flavor2 {
            proguardFile 'some-other-rules.txt'
        }
    }
}
```

Variants use all the rules files declared in their build type, and product flavors.

**[默认情况下有两个proguard rule 文件，它们存放在Android SDK目录中，默认是`$ANDROID_HOME/tools/proguard/` 目录下 ，使用`getDefaultProguardFile()` 可以得到它们的完整路径]**

There are 2 default rules files

`proguard-android.txt`       
`proguard-android-optimize.txt`        

They are located in the SDK. Using `getDefaultProguardFile()` will return the full path to the files. They are identical except for enabling optimizations.

###Dependencies, Android Libraries and Multi-project setup

Gradle projects can have dependencies on other components. These components can be external binary packages, or other Gradle projects.

#### Dependencies on binary packages

#### Local packages

To configure a dependency on an external library jar, you need to add a dependency on the `compile` configuration.

```
dependencies {
    compile files('libs/foo.jar')
}

android {
    ...
}
```

[注意dependencies是标准Gradle API的一部分，所以不是在android元素中声明]

**Note: the dependencies DSL element is part of the standard Gradle API and does not belong inside the android element.**

[`compile` 的配置是用来编译main application的，所以其中的所有元素都会加入到编译的类路径中，同样也会打包进最终的APK中]

**The `compile` configuration is used to compile the main application. Everything in it is added to the compilation classpath and also packaged in the final APK.**

There are other possible configurations to add dependencies to:

`compile`: main application       
`androidTestCompile`: test application      
`debugCompile`: debug Build Type      
`releaseCompile`: release Build Type.      

**[对应每个build type都有一个对应的`<buildtype>Compile`， 它们的dependencies也都可以自行定义使其不同。如果希望不同的build type表现出不同的结果时，我们便可以使用这种方式让它们依赖不同的library]**

Because it’s not possible to build an APK that does not have an associated Build Type, the APK is always configured with two (or more) configurations: `compile` and `<buildtype>Compile`.

Creating a new Build Type automatically creates a new configuration based on its name.

This can be useful if the debug version needs to use a custom library (to report crashes for instance), while the release doesn’t, or if they rely on different versions of the same library.

#### Remote artifacts

[Gradle支持Maven和Ivy资源库]

Gradle supports pulling artifacts from Maven and Ivy repositories.

First the repository must be added to the list, and then the dependency must be declared in a way that Maven or Ivy declare their artifacts.

```
repositories {
    mavenCentral()
}


dependencies {
    compile 'com.google.guava:guava:11.0.2'
}

android {
    ...
}
```

**[`mavenCentral()` 方法返回的就是Maven Repository的URL，Gradle同时支持remote 和 local repositories，此外，Gradle能够处理dependency之间的相互依赖，然后自动pull所需要的dependencies]**

Note: `mavenCentral()` is a shortcut to specifying the URL of the repository. Gradle supports both remote and local repositories.

Note: Gradle will follow all dependencies transitively. This means that if a dependency has dependencies of its own, those are pulled in as well.

For more information about setting up dependencies, read the [Gradle user guide here](http://gradle.org/docs/current/userguide/artifact_dependencies_tutorial.html), and [DSL documentation here](http://gradle.org/docs/current/dsl/org.gradle.api.artifacts.dsl.DependencyHandler.html).

#### Multi project setup

[使用multi-project setup可以使得Gradle项目依赖其他的Gradle项目，它通常是通过将所有的项目作为某个指定的根项目的子目录来实现的。]

Gradle projects can also depend on other gradle projects by using a multi-project setup.

A multi-project setup usually works by having all the projects as sub folders of a given root project.

For instance, given to following structure:

```
MyProject/
 + app/
 + libraries/
    + lib1/
    + lib2/
```

We can identify 3 projects. Gradle will reference them with the following name:

```
:app
:libraries:lib1
:libraries:lib2
```

**Each projects will have its own `build.gradle` declaring how it gets built. Additionally, there will be a file called `settings.gradle` at the root declaring the projects.**

[每个项目都有自己的`build.gradle` 文件声明它的build过程，此外，根项目下还有一个`settings.gradle` 文件用来指定这些子项目]

This gives the following structure:

```
MyProject/
 | settings.gradle
 + app/
    | build.gradle
 + libraries/
    + lib1/
       | build.gradle
    + lib2/
       | build.gradle
```

The content of `settings.gradle` is very simple:

```
include ':app', ':libraries:lib1', ':libraries:lib2'
```

This defines which folder is actually a Gradle project. [它声明了哪个目录是一个Gradle项目]

The `:app` project is likely to depend on the libraries, and this is done by declaring the following dependencies:

```
dependencies {
    compile project(':libraries:lib1')
}
```

More general information about [multi-project setup here](http://gradle.org/docs/current/userguide/multi_project_builds.html).

#### Library projects

**[如果前面例子中的两个library projects都是Java项目的话，那么app这个Android项目就使用它们的输出jar文件即可，但是如果你需要引用library project中的资源或者代码的话，那它们必须是Android Library Projects]**

In the above multi-project setup, `:libraries:lib1` and `:libraries:lib2` can be Java projects, and the `:app` Android project will use their jar output.

However, if you want to share code that accesses Android APIs or uses Android-style resources, these libraries cannot be regular Java project, they have to be `Android Library Projects`.

#### Creating a Library Project

A Library project is very similar to a regular Android project with a few differences.

Since building libraries is different than building applications, a different plugin is used. Internally both plugins share most of the same code and they are both provided by the same `com.android.tools.build.gradle` jar.

**[创建Library Project使用的是不同的插件，即`android-library`，它和`android` 插件共享很多的代码(所以大部分的配置都和前面提到的一模一样)，并且这个插件的源码也是在`com.android.tools.build.gradle` 这个jar包中]**

```
buildscript {
    repositories {
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:0.5.6'
    }
}

apply plugin: 'android-library'

android {
    compileSdkVersion 15
}
```

This creates a library project that uses API 15 to compile. SourceSets, and dependencies are handled the same as they are in an application project and can be customized the same way.

#### Differences between a Project and a Library Project

**[一个Library Project的主要输出是一个aar包，它是编译后的代码与资源的集合，它同样可以生成test apk来独立地测试这个library。Library Project和普通Project的assemble task是一样的，所以它们的behave没啥区别。此外，因为它可以有不同的build type和product flavor，所以它可以得到很多个不同的aar]**

A Library project's main output is an .aar package (which stands for Android archive). It is a combination of compile code (as a jar file and/or native .so files) and resources (manifest, res, assets).

**A library project can also generate a test apk to test the library independently from an application. **

The same anchor tasks are used for this (`assembleDebug`, `assembleRelease`) so there’s no difference in commands to build such a project.

For the rest, libraries behave the same as application projects. **They have build types and product flavors, and can potentially generate more than one version of the aar.**

[大多数的build type的配置都不会应用于Library Project中，当然它还是可以进行配置的]

**Note that most of the configuration of the Build Type do not apply to library projects. However you can use the custom sourceSet to change the content of the library depending on whether it’s used by a project or being tested.**

#### Referencing a Library

Referencing a library is done the same way any other project is referenced:

```
dependencies {
    compile project(':libraries:lib1')
    compile project(':libraries:lib2')
}
```

Note: if you have more than one library, then the order will be important. This is similar to the old build system where the order of the dependencies in the `project.properties` file was important.  

[注：如果你有很多的library projects，那么你要根据它们相互之间的依赖关系确定一个正确的顺序，就类似以前build系统中的`project.properties` 文件一样，以前需要如下地声明`android.library.reference`]

```
android.library.reference.1=path/to/libraryproject
```

#### Library Publication

[默认情况下，library project只会publish它的release variant，所有其他的project都是引用这个variant，但是你还是可以通过配置`defaultPublishConfig` 控制将哪个variant进行publish，而且你也可以设置为publish所有variant]

By default a library only publishes its release variant. This variant will be used by all projects referencing the library, no matter which variant they build themselves. This is a temporary limitation due to Gradle limitations that we are working towards removing.

You can control which variant gets published with

```
android {
    defaultPublishConfig "debug"
}
```

**Note that this publishing configuration name references the full variant name. Release and debug are only applicable when there are no flavors. ** If you wanted to change the default published variant while using flavors, you would write:

```
android {
    defaultPublishConfig "flavor1Debug"
}
```

**It is also possible to publish all variants of a library. We are planning to allow this while using a normal project-to-project dependency (like shown above), but this is not possible right now due to limitations in Gradle (we are working toward fixing those as well).**

Publishing of all variants are not enabled by default. To enable them:

```
android {
    publishNonDefault true
}
```

It is important to realize that publishing multiple variants means publishing multiple aar files, instead of a single aar containing multiple variants. Each aar packaging contains a single variant.

[publish一个variant意味着使得这个aar包作为Gradle项目的输出，它可以用于publish到maven repository，也可以被其他项目作为依赖项目被引用]

**Publishing an variant means making this aar available as an output artifact of the Gradle project. This can then be used either when publishing to a maven repository, or when another project creates a dependency on the library project.**

Gradle has a concept of default" artifact. This is the one that is used when writing:

```
compile project(':libraries:lib2')
```

To create a dependency on another published artifact, you need to specify which one to use:

```
dependencies {
    flavor1Compile project(path: ':lib1', configuration: 'flavor1Release')
    flavor2Compile project(path: ':lib1', configuration: 'flavor2Release')
}
```

Important: Note that the published configuration is a full variant, including the build type, and needs to be referenced as such.

**Important: When enabling publishing of non default, the Maven publishing plugin will publish these additional variants as extra packages (with classifier). This means that this is not really compatible with publishing to a maven repository. You should either publish a single variant to a repository OR enable all config publishing for inter-project dependencies.** [?]
