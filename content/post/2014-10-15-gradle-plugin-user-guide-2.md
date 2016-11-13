---
title: "Gradle Plugin for Android Development User Guide 2"
date: "2014-10-15"
tags: ["android"]
---
Gradle Plugin for Android Development User Guide (2) <!--more-->

阅读本文前请先阅读第一部分：[gradle-plugin-user-guide-1](/blog/2014/10/15/gradle-plugin-user-guide-1/)

原文地址：[http://tools.android.com/tech-docs/new-build-system/user-guide](http://tools.android.com/tech-docs/new-build-system/user-guide)

### Testing

[现在我们可以直接将test application集成到我们的application project中，没有必要再创建一个独立的test project了]

Building a test application is integrated into the application project. There is no need for a separate test project anymore.

#### Basics and Configuration

[测试代码默认存放在`src/androidTest/` 目录下，使用Android Testing Framework 我们可以创建unit tests，instrumentation tests, 和 uiautomator tests.]

As mentioned previously, next to the `main` sourceSet is the `androidTest` sourceSet, located by default in `src/androidTest/`

From this sourceSet is built a test apk that can be deployed to a device to test the application using the `Android testing framework`. This can contain unit tests, instrumentation tests, and later uiautomator tests.

[test app的`AndroidManifest.xml` 文件是自动生成的，所以它不需要指定位置，此外，我们没必要设置test application的instrumentation节点的`targetPackage` 属性，因为它会被test app的package name填充进去，这也就是为什么test app的Manifest文件是自动生成的]

The sourceSet should not contain an `AndroidManifest.xml` as it is automatically generated.

There are a few values that can be configured for the test app: [test app可以指定的属性]

`testPackageName`       
`testInstrumentationRunner`        
`testHandleProfiling`        
`testFunctionalTest`         

As seen previously, those are configured in the defaultConfig object:

```java
android {
    defaultConfig {
        testPackageName "com.test.foo"
        testInstrumentationRunner "android.test.InstrumentationTestRunner"
        testHandleProfiling true
        testFunctionalTest true
    }
}
```

**The value of the `targetPackage` attribute of the instrumentation node in the test application manifest is automatically filled with the package name of the tested app, even if it is customized through the `defaultConfig` and/or the Build Type objects. This is one of the reason the manifest is generated automatically.**

Additionally, the sourceSet can be configured to have its own dependencies.
By default, the application and its own dependencies are added to the test app classpath, but this can be extended with

```
dependencies {
    androidTestCompile 'com.google.guava:guava:11.0.2'
}
```

[test app是通过任务`assembleTest` 来构建的，它不是main assemble任务的依赖项，所以它是在test运行时自动调用的。目前只有debug这个build type会被测试，当然也可以自定义]

**The test app is built by the task `assembleTest`. It is not a dependency of the main assemble task, and is instead called automatically when the tests are set to run.**

**Currently only one Build Type is tested. By default it is the `debug` Build Type, but this can be reconfigured with:**

```
android {
    ...
    testBuildType "staging"
}
```

#### Running tests

[前面提到过，在所有已连接的设备上进行check的任务是`connectedCheck`，它依赖任务`androidTest`，该任务的工作是并行地在所有已连接的设备上运行测试，任何一个设备测试失败的话，build就会失败。测试的结果会保存在XML文件中，存放在`build/androidTest-results` 目录下，当然也可以修改目标目录]

As mentioned previously, checks requiring a connected device are launched with the anchor task called `connectedCheck`.

This depends on the task `androidTest` and therefore will run it. This task does the following:  [`androidTest` 任务的工作流程]

1 Ensure the app and the test app are built (depending on `assembleDebug` and `assembleTest`)    
2 Install both apps      
3 Run the tests       
4 Uninstall both apps.      

If more than one device is connected, all tests are run in parallel on all connected devices. If one of the test fails, on any device, the build will fail.

All test results are stored as XML files under

`build/androidTest-results`

(This is similar to regular jUnit results that are stored under `build/test-results`)

This can be configured with

```
android {
    ...

    testOptions {
        resultsDir = "$project.buildDir/foo/results"
    }
}
```

**The value of `android.testOptions.resultsDir` is evaluated with `Project.file(String)`**

#### Testing Android Libraries

[测试android library project和测试一般的application差不多，区别在于整个library和它的依赖项都会被自动添加到test app，Manifest文件也被整合到test app的Manifest中。此外，`androidTest` 任务只能安装和卸载test APK]

Testing Android Library project is done exactly the same way as application projects.

The only difference is that the whole library (and its dependencies) is automatically added as a Library dependency to the test app. The result is that the test APK includes not only its own code, but also the library itself and all its dependencies.

The manifest of the Library is merged into the manifest of the test app (as is the case for any project referencing this Library).

The `androidTest` task is changed to only install (and uninstall) the test APK (since there are no other APK to install.)

Everything else is identical.

#### Test reports

[在进行单元测试时，Gradle会输出一份HTML文档形式的报告。Android插件在此之上进行扩展，输出一份整合了所有已连接设备的测试结果的测试报告]

When running unit tests, Gradle outputs an HTML report to easily look at the results.

The Android plugins build on this and extends the HTML report to aggregate the results from all connected devices.

#### Single projects

The project is automatically generated upon running the tests. Its default location is `build/reports/androidTests`

This is similar to the jUnit report location, which is `build/reports/tests`, or other reports usually located in `build/reports/<plugin>/`

The location can be customized with

```
android {
    ...

    testOptions {
        reportDir = "$project.buildDir/foo/report"
    }
}
```

The report will aggregate tests that ran on different devices.

#### Multi-projects reports

[对于多项目的测试，可以使用插件`android-reporting` 来将所有的测试结果输出到一个单一的报告中，而且这个设置必须是要设置在根项目的`build.gradle` 文件中]

In a multi project setup with application(s) and library(ies) projects, when running all tests at the same time, it might be useful to generate a single reports for all tests.

To do this, a different plugin is available in the same artifact. It can be applied with:

```
buildscript {
    repositories {
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:0.5.6'
    }
}

apply plugin: 'android-reporting'
```

This should be applied to the root project, ie in `build.gradle` next to `settings.gradle`

[在项目根目录下使用下面的命令可以保证运行所有的测试并聚合所有的测试结果，其中的`--continue` 选项能够保证即使某个设备在测试过程中出现了问题也不会打断其他的设备继续测试]

Then from the root folder, the following command line will run all the tests and aggregate the reports:

```
gradle deviceCheck mergeAndroidReports --continue
```

Note: the `--continue` option ensure that all tests, from all sub-projects will be run even if one of them fails. Without it the first failing test will interrupt the run and not all projects may have their tests run.

#### Lint support

[lint可以指出程序中可能出现的issue，android插件同样支持]

As of version 0.7.0, you can run lint for a specific variant, or for all variants, in which case it produces a report which describes which specific variants a given issue applies to.

You can configure lint by adding a `lintOptions` section like following. You typically only specify a few of these; this section shows all the available options.

```
android {
    lintOptions {
        // set to true to turn off analysis progress reporting by lint
        quiet true
        // if true, stop the gradle build if errors are found
        abortOnError false
        // if true, only report errors
        ignoreWarnings true
        // if true, emit full/absolute paths to files with errors (true by default)
        //absolutePaths true
        // if true, check all issues, including those that are off by default
        checkAllWarnings true
        // if true, treat all warnings as errors
        warningsAsErrors true
        // turn off checking the given issue id's
        disable 'TypographyFractions','TypographyQuotes'
        // turn on the given issue id's
        enable 'RtlHardcoded','RtlCompat', 'RtlEnabled'
        // check *only* the given issue id's
        check 'NewApi', 'InlinedApi'
        // if true, don't include source code lines in the error output
        noLines true
        // if true, show all locations for an error, do not truncate lists, etc.
        showAll true
        // Fallback lint configuration (default severities, etc.)
        lintConfig file("default-lint.xml")
        // if true, generate a text report of issues (false by default)
        textReport true
        // location to write the output; can be a file or 'stdout'
        textOutput 'stdout'
        // if true, generate an XML report for use by for example Jenkins
        xmlReport false
        // file to write report to (if not specified, defaults to lint-results.xml)
        xmlOutput file("lint-report.xml")
        // if true, generate an HTML report (with issue explanations, sourcecode, etc)
        htmlReport true
        // optional path to report (default will be lint-results.html in the builddir)
        htmlOutput file("lint-report.html")

   // set to true to have all release builds run lint on issues with severity=fatal
   // and abort the build (controlled by abortOnError above) if fatal issues are found
   checkReleaseBuilds true
        // Set the severity of the given issues to fatal (which means they will be
        // checked during release builds (even if the lint target is not included)
        fatal 'NewApi', 'InlineApi'
        // Set the severity of the given issues to error
        error 'Wakelock', 'TextViewEdits'
        // Set the severity of the given issues to warning
        warning 'ResourceAsColor'
        // Set the severity of the given issues to ignore (same as disabling the check)
        ignore 'TypographyQuotes'
    }
}
```

### Build Variants

One goal of the new build system is to enable creating different versions of the same application.

There are two main use cases: [同一套程序代码生成多种不同的结果的应用场景]

(1) Different versions of the same application

For instance, a free/demo version vs the “pro” paid application. [一个是展示应用，另一个是真正的付费应用]

Same application packaged differently for multi-apk in Google Play Store.
See [http://developer.android.com/google/play/publishing/multiple-apks.html ](http://developer.android.com/google/play/publishing/multiple-apks.html ) for more information.

(2) A combination of 1. and 2.

The goal was to be able to generate these different APKs from the same project, as opposed to using a single Library Projects and 2+ Application Projects.

#### Product flavors

[product flavor是一个项目的特别定制版的应用程序输出，单个项目可以有很多不同的product flavors，它们的名称不要和build type和sourceSet的名称相同]

A product flavor defines a customized version of the application build by the project. A single project can have different flavors which change the generated application.

**This new concept is designed to help when the differences are very minimum. If the answer to “Is this the same application?” is yes, then this is probably the way to go over Library Projects.**

Product flavors are declared using a productFlavors DSL container:

```
android {
    ....

    productFlavors {
        flavor1 {
            ...
        }

        flavor2 {
            ...
        }
    }
}
```

This creates two flavors, called flavor1 and flavor2.

Note: The name of the flavors cannot collide with existing Build Type names, or with the `androidTest` sourceSet.

[重要的式子：每个build type和product flavor的组合就是一个build variant]

 **Build Type + Product Flavor = Build Variant**  

As we have seen before, each Build Type generates a new APK.

Product Flavors do the same: the output of the project becomes all possible combinations of Build Types and, if applicable, Product Flavors.

**Each (Build Type, Product Flavor) combination is called a Build Variant.**

For instance, with the default `debug` and `release` Build Types, the above example generates four Build Variants:

`Flavor1 - debug`      
`Flavor1 - release`      
`Flavor2 - debug`      
`Flavor2 - release`      

[没有配置flavor的项目会有一个默认的flavor配置]

Projects with no flavors still have Build Variants, but the single default `flavor/config` is used, nameless, making the list of variants similar to the list of Build Types.

#### Product Flavor Configuration

Each flavors is configured with a closure:

```
android {
    ...

    defaultConfig {
        minSdkVersion 8
        versionCode 10
    }

    productFlavors {
        flavor1 {
            packageName "com.example.flavor1"
            versionCode 20
        }

        flavor2 {
            packageName "com.example.flavor2"
            minSdkVersion 14
        }
    }
}
```

[ProductFlavor对象和`android.defaultConfig` 对象有相同的属性，即可以使用类似的配置方式]

**Note that the `android.productFlavors.*` objects are of type `ProductFlavor` which is the same type as the `android.defaultConfig` object. This means they share the same properties.**

`defaultConfig` provides the base configuration for all flavors and each flavor can override any value. In the example above, the configurations end up being:

```
flavor1
packageName: com.example.flavor1
minSdkVersion: 8
versionCode: 20

flavor2
packageName: com.example.flavor2
minSdkVersion: 14
versionCode: 10
```

Usually, the Build Type configuration is an overlay over the other configuration. For instance, the Build Type's packageNameSuffix is appended to the Product Flavor's packageName.

[有些情况下，我们希望一个设置同时作用在build type和product flavor上，例如`signingConfig` 就是其中的一种配置，我们既可以设置所有的build type使用相同的SigningConfig，又可以设置某些flavor使用某个特定的SigningConfig]

There are cases where a setting is settable on both the Build Type and the Product Flavor. In this case, it’s is on a case by case basis.

For instance, `signingConfig` is one of these properties.

This enables either having all release packages share the same `SigningConfig`, by setting `android.buildTypes.release.signingConfig`, or have each release package use their own SigningConfig by setting each `android.productFlavors.*.signingConfig` objects separately.

#### Sourcesets and Dependencies

[和build type类似，product flavor也会产生自己的sourceSets，这些sourceSets和build type的sourceSets以及`android.sourceSets.main` 组合起来构建最终的APK]

Similar to Build Types, Product Flavors also contribute code and resources through their own sourceSets.

The above example creates four sourceSets:

`android.sourceSets.flavor1`   Location `src/flavor1/`        
`android.sourceSets.flavor2`   Location `src/flavor2/`       
`android.sourceSets.androidTestFlavor1`   Location `src/androidTestFlavor1/`      
`android.sourceSets.androidTestFlavor2`   Location `src/androidTestFlavor2/`     

Those sourceSets are used to build the APK, alongside `android.sourceSets.main` and the Build Type sourceSet.

The following rules are used when dealing with all the sourcesets used to build a single APK:  **[重点：在构建APK过程中处理所有源码和资源的规则]**

1 All source code (`src/*/java`) are used together as multiple folders generating a single output.  [所有的源代码都会整合到一起作为输出]

2 Manifests are all merged together into a single manifest. This allows Product Flavors to have different components and/or permissions, similarly to Build Types.  [所有的Manifest文件也都会整合成为一个Manifest文件，其中product flavor和build type类似，都可以有不同的components或者permissions]

3 **All resources (Android `res` and `assets`) are used using overlay priority where the Build Type overrides the Product Flavor, which overrides the main sourceSet.** [所有的资源文件按照优先级的不同采用覆盖的方式整合，product flavor覆盖main，build type覆盖product flavor] **[?这里的优先级总觉得有点问题?]**

4 Each Build Variant generates its own `R` class (or other generated source code) from the resources. Nothing is shared between variants. [每个Build Variant都会根据它的资源文件产生一个R清单类，并且在variants之间不进行共享]

5 Finally, like Build Types, Product Flavors can have their own dependencies. For instance, if the flavors are used to generate a ads-based app and a paid app, one of the flavors could have a dependency on an Ads SDK, while the other does not. [最后，build type和product flavor一样都可以有自己的依赖项]

```
dependencies {
    flavor1Compile "..."
}
```

In this particular case, the file `src/flavor1/AndroidManifest.xml` would probably need to include the internet permission.

Additional sourcesets are also created for each variants:

`android.sourceSets.flavor1Debug`   Location `src/flavor1Debug/`     
`android.sourceSets.flavor1Release`   Location `src/flavor1Release/`      
`android.sourceSets.flavor2Debug`    Location `src/flavor2Debug/`    
`android.sourceSets.flavor2Release`    Location `src/flavor2Release/`     

These have higher priority than the build type sourcesets, and allow customization at the variant level.

[这些sourceSets的优先级比build type的sourceSets高，而且可以在variant层进行自定义]

#### Building and Tasks

We previously saw that each Build Type creates its own `assemble<name>` task, but that Build Variants are a combination of Build Type and Product Flavor.

[当一个product flavor被使用时，更多的assemble类型的任务会被创建，它们分别针对了特定的variant或者build type或者flavor]

When Product Flavors are used, more assemble-type tasks are created. These are:  

`assemble<Variant Name>`      
`assemble<Build Type Name>`          
`assemble<Product Flavor Name>`        

1 allows directly building a `single variant`. For instance `assembleFlavor1Debug`.

2 allows building all APKs for a given `Build Type`. For instance `assembleDebug `will build both `Flavor1Debug` and `Flavor2Debug` variants.

3 allows building all APKs for a given `flavor`. For instance `assembleFlavor1` will build both `Flavor1Debug` and `Flavor1Release` variants.

The task `assemble` will build all possible variants.

#### Testing

[测试包含多个`flavor` 的项目]

Testing multi-flavors project is very similar to simpler projects.

The `androidTest` sourceset is used for common tests across all flavors, while each flavor can also have its own tests.

As mentioned above, sourceSets to test each flavor are created:

`android.sourceSets.androidTestFlavor1`    Location `src/androidTestFlavor1/`         
`android.sourceSets.androidTestFlavor2`    Location `src/androidTestFlavor2/`      

Similarly, those can have their own dependencies:

```
dependencies {
    androidTestFlavor1Compile "..."
}
```

Running the tests can be done through the main `deviceCheck` anchor task, or the main `androidTest` tasks which acts as an anchor task when flavors are used.

Each flavor has its own task to run `tests: androidTest<VariantName>`. For instance:

`androidTestFlavor1Debug`             
`androidTestFlavor2Debug`           

Similarly, test APK building tasks and install/uninstall tasks are per variant:

`assembleFlavor1Test`        
`installFlavor1Debug`        
`installFlavor1Test`        
`uninstallFlavor1Debug`        
`...`

Finally the HTML report generation supports aggregation by flavor.
The location of the test results and reports is as follows, first for the per flavor version, and then for the aggregated one:

`build/androidTest-results/flavors/<FlavorName>`        
`build/androidTest-results/all/`        
`build/reports/androidTests/flavors<FlavorName>`        
`build/reports/androidTests/all/`        

Customizing either path, will only change the root folder and still create sub folders per-flavor and aggregated `results/reports`.

#### Multi-flavor variants

[使用`flavorGroups`，此处有些复杂，如果有这种需求请细读原文]

In some case, one may want to create several versions of the same apps based on more than one criteria.

For instance, multi-apk support in Google Play supports 4 different filters.

Creating different APKs split on each filter requires being able to use more than one dimension of Product Flavors.

Consider the example of a game that has a demo and a paid version and wants to use the ABI filter in the multi-apk support. With 3 ABIs and two versions of the application, 6 APKs needs to be generated (not counting the variants introduced by the different Build Types).

However, the code of the paid version is the same for all three ABIs, so creating simply 6 flavors is not the way to go.Instead, there are two dimensions of flavors, and variants should automatically build all possible combinations.

This feature is implemented using Flavor Groups. Each group represents a dimension, and flavors are assigned to a specific group.

```
android {
    ...

    flavorGroups "abi", "version"

    productFlavors {
        freeapp {
            flavorGroup "version"
            ...
        }

        x86 {
            flavorGroup "abi"
            ...
        }
    }
}
```

The `android.flavorGroups` array defines the possible groups, as well as the order. Each defined Product Flavor is assigned to a group.

From the following grouped Product Flavors `[freeapp, paidapp]` and `[x86, arm, mips]` and the `[debug, release]` Build Types, the following build variants will be created:

```
x86-freeapp-debug
x86-freeapp-release
arm-freeapp-debug
arm-freeapp-release
mips-freeapp-debug
mips-freeapp-release
x86-paidapp-debug
x86-paidapp-release
arm-paidapp-debug
arm-paidapp-release
mips-paidapp-debug
mips-paidapp-release
```

The order of the group as defined by `android.flavorGroups` is very important.

Each variant is configured by several Product Flavor objects:
`android.defaultConfig`
One from the `abi` group
One from the `version` group

The order of the group drives which flavor override the other, which is important for resources when a value in a flavor replaces a value defined in a lower priority flavor.

The flavor groups is defined with higher priority first. So in this case:
`abi > version > defaultConfig`

Multi-flavors projects also have additional sourcesets, similar to the variant sourcesets but without the build type:

`android.sourceSets.x86Freeapp`   Location `src/x86Freeapp/`         
`android.sourceSets.armPaidapp`   Location `src/armPaidapp/`        
`etc...`

**These allow customization at the flavor-combination level. They have higher priority than the basic flavor sourcesets, but lower priority than the build type sourcesets.**

### Advanced Build Customization

####  Build options

##### Java Compilation options

```
android {
    compileOptions {
        sourceCompatibility = "1.6"
        targetCompatibility = "1.6"
    }
}
```

Default value is “1.6”. This affect all tasks compiling Java source code.

##### aapt options

```
android {
    aaptOptions {
        noCompress 'foo', 'bar'
        ignoreAssetsPattern "!.svn:!.git:!.ds_store:!*.scc:.*:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~"
    }
}
```

This affects all tasks using aapt.

##### dex options

```
android {
    dexOptions {
        incremental false
        preDexLibraries = false
        jumboMode = false
    }
}
```

This affects all tasks using dex.

##### Manipulating tasks

[简单的Java项目一般都是有限的任务一起工作然后得到一个输出，例如`classes` 任务是用来编译Java源代码的任务，在`build.gradle` 文件中可以使用`classes` 来引用]

Basic Java projects have a finite set of tasks that all work together to create an output.

The `classes` task is the one that compile the Java source code.
It’s easy to access from `build.gradle` by simply using `classes` in a script. This is a shortcut for `project.tasks.classes`.

[但是Android项目优点复杂，因为它可能有很多相同的任务，这些任务的名称是基于build type和product flavor来生成的]

In Android projects, this is a bit more complicated because there could be a large number of the same task and their name is generated based on the Build Types and Product Flavors.

In order to fix this, the android object has two properties:

`applicationVariants` (only for the app plugin)        
`libraryVariants` (only for the library plugin)       
`testVariants` (for both plugins)        

All three return a `DomainObjectCollection` of `ApplicationVariant`, `LibraryVariant`, and `TestVariant` objects respectively.

Note that accessing any of these collections will trigger the creations of all the tasks. This means no (re)configuration should take place after accessing the collections.

The `DomainObjectCollection` gives access to all the objects directly, or through filters which can be convenient.

```
android.applicationVariants.each { variant ->
    ....
}
```

All three variant classes share the following properties:

![image](/images/gradle4.png)

The ApplicationVariant class adds the following:

 ![image](/images/gradle5.png)

The LibraryVariant class adds the following:

 ![image](/images/gradle6.png)

The TestVariant class adds the following:

 ![image](/images/gradle7.png)

API for Android specific task types.

 ![image](/images/gradle8.png)

**The API for each task type is limited due to both `how Gradle works` and `how the Android plugin sets them up`.**

1 First, Gradle is meant to have the tasks be only configured for `input/output` location and possible optional flags. So here, the tasks only define (some of) the inputs/outputs.

2 Second, the input for most of those tasks is non-trivial, often coming from mixing values from the sourceSets, the Build Types, and the Product Flavors. To keep build files simple to read and understand, the goal is to let developers modify the build by tweak these objects through the DSL, rather than diving deep in the inputs and options of the tasks and changing them.

**Also note, that except for the `ZipAlign` task type, all other types require setting up `private data` to make them work. This means it’s not possible to manually create new tasks of these types.**

 [除了ZipAlign任务之外，其他类型的任务都需要private data才能工作，所以没有办法manual创建这些类型的新任务]

**This API is subject to change.** In general the current API is around giving access to the outputs and inputs (when possible) of the tasks to add extra processing when required). Feedback is appreciated, especially around needs that may not have been foreseen.

For Gradle tasks (`DefaultTask`, `JavaCompile`, `Copy`, `Zip`), refer to the Gradle documentation.

#### BuildType and Product Flavor property reference

coming soon.

For Gradle tasks (`DefaultTask`, `JavaCompile`, `Copy`, `Zip`), refer to the Gradle documentation.

#### Using sourceCompatibility 1.7

[兼容JDK 1.7的方式，使用某些特性时还需要注意项目`minSdkVersion` 的配置]

With `Android KitKat (buildToolsVersion 19)` you can use the `diamond operator`, `multi-catch`, `strings in switches`, `try with resources`, etc. To do this, add the following to your build file:

```
android {
    compileSdkVersion 19
    buildToolsVersion "19.0.0"

    defaultConfig {
        minSdkVersion 7
        targetSdkVersion 19
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_7
        targetCompatibility JavaVersion.VERSION_1_7
    }
}
```

Note that you can use `minSdkVersion` with a value earlier than 19, for all language features except `try with resources`. If you want to use `try with resources`, you will need to also use a `minSdkVersion` of 19.

You also need to make sure that Gradle is using version 1.7 or later of the JDK. (And version 0.6.1 or later of the Android Gradle plugin.)
