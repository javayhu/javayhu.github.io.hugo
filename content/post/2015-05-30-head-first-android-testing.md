---
title: "Head First Android Testing 1"
date: "2015-05-30"
categories: "android"
---
深入浅出Android测试教程 (1) <!--more-->

最近想写一个自己的库项目，以后开发都基于这个库项目来开发，于是乎，为了保证库项目中的代码功能没有问题，简单学了一些Android测试的内容，对于没有搞过测试的我来说，过程还是挺纠结的，现记录下来以备后用。

Android测试包含很多类型，例如Unit Tests，Instrumentation Tests以及各种其他的UI Tests等等。本次深入浅出教程只介绍前面两种测试，内容参考自[android_testing_google_slides](/files/android_testing_google_slides.pdf)和Google Sample项目[android-testing](https://github.com/hujiaweibujidao/android-testing)，感兴趣可以阅读示例感受下。

###第一部分 Unit Tests

Unit Test又叫JVM Tests 或者Local Tests，就是指直接运行在Java虚拟机而不是Dalvik虚拟机中的测试。

从1.1.0 RC1版本的Android Studio(Gradle插件从1.1版本)开始支持Unit Tests，使用方法教程可参考[unit-testing-support](http://tools.android.com/tech-docs/unit-testing-support)。

**How it works?**

Unit tests run on a local JVM on your development machine. Our gradle plugin will compile source code found in `src/test/java` and execute it using the usual Gradle testing mechanisms. At runtime, tests will be executed against a modified version of `android.jar` where all `final` modifiers have been stripped off. This lets you use popular mocking libraries, like `Mockito`.

①New source set `test/` for unit tests     
②Mockable `android.jar`     
③Mockito to stub dependencies into the Android framework      

测试步骤：

(1)配置`build.gradle`

```python
apply plugin: 'com.android.application'
android {
    ...
    testOptions {
       unitTests.returnDefaultValues = true // Caution!
    }
}
dependencies {
    // Unit testing dependencies
    testCompile 'junit:junit:4.12'
    testCompile 'org.mockito:mockito-core:1.10.19'
}
```

(2)配置`Build Variants`，选择`Unit Tests`

![image](/images/builde_variants.png)

(3)编写Unit Test程序，放在`src/test/java`目录下

```java
import android.content.Context;
import android.test.suitebuilder.annotation.SmallTest;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import java.io.Serializable;

import polaris.util.ObjectUtil;

import static org.hamcrest.core.Is.is;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThat;

@RunWith(MockitoJUnitRunner.class)
@SmallTest
public class UnitTestSample {

    @Mock
    Context mMockContext; //Use MockitoJUnitRunner for easier initialization of @Mock fields.

    ObjectUtil objectUtil;
    private static final String fileName = "demo";

    @Before
    public void setUp() throws Exception {
        objectUtil = new ObjectUtil(mMockContext);
    }

    @Test
    public void testAdd() throws Exception {
        int result = 2 + 2;
        assertThat(result, is(4));
    }

    @Test
    public void testMod() throws Exception {
        int result = 7 % 3;
        assertThat(result, is(1));
    }

    @Test
    public void testAppName() throws Exception {//ok
        //can not find symbol class R
        //when(mMockContext.getString(R.string.app_name)).thenReturn("polaris");
        //assertThat(mMockContext.getString(R.string.app_name), is("polaris"));

        assertNotNull(mMockContext);
        assertNotNull(objectUtil);
    }

    @Test
    public void testSaveAndLoad() throws Exception {//fail
        User user = new User(1, "hujiawei");
        objectUtil.save(user, fileName);

        user = (User) objectUtil.load(fileName);
        assertThat(user.name, is("hujiawei"));
    }

    static class User implements Serializable {
        int id;
        String name;

        User(int id, String name) {
            this.id = id;
            this.name = name;
        }
    }

    public void tearDown() throws Exception {
    }

}
```

其中`ObjectUtil`类是一个用来保存和读取Object对象的工具类，并采用了Android Annotation注解注入Context。Android Annotation对`EBean`类的构造函数有个限制，要么不提供构造函数只用默认的构造函数，要么提供一个只包含参数Context的构造函数。

```
package polaris.util;

import android.content.Context;

import org.androidannotations.annotations.EBean;
import org.androidannotations.annotations.RootContext;

import java.io.File;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

/**
 * object tool
 * non singleton https://github.com/excilys/androidannotations/wiki/Enhance%20custom%20classes
 *
 * @author hujiawei
 * @date 15/5/30 09:41
 */
@EBean(scope = EBean.Scope.Default)
public class ObjectUtil {

    @RootContext
    Context context;

    //Error:(19, 1) error: @org.androidannotations.annotations.EBean annotated element should have only one constructor

//    public ObjectUtil() {
//
//    }

    public ObjectUtil(Context context) {
        this.context = context;
    }

    /**
     * save Object
     */
    public void save(Object data, String fileName) {
        File file = new File(context.getFilesDir(), fileName);
        if (file.exists()) {
            file.delete();
        }

        try {
            ObjectOutputStream oos = new ObjectOutputStream(context.openFileOutput(fileName, Context.MODE_PRIVATE));
            oos.writeObject(data);
            oos.close();
        } catch (Exception e) {//NPE
            e.printStackTrace();
        }
    }

    /**
     * load Object
     */
    public Object load(String fileName) {
        Object data = null;
        File file = new File(context.getFilesDir(), fileName);
        if (file.exists()) {
            try {
                ObjectInputStream ois = new ObjectInputStream(context.openFileInput(fileName));
                data = ois.readObject();
                ois.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        return data;
    }

}
```

(4)配置测试的运行参数

![image](/images/unittest_configuration.png)

(5)运行测试有两种方式，可以简单地和运行普通程序一样点击Run按钮，结果会显示在下面的Run视图窗口中，也可以在终端运行`./gradlew test`，结果将放在`/build/reports/test/debug/`中，打开`index.html`文件即可。前者只运行当前测试的运行参数中配置的测试类和方法，而后者会检测整个项目中的所有Unit Test并进行测试。

上面四个测试中只有前三个是通过的，最后一个没能通过。(最后一个测试方法的问题出在`ObjectOutputStream`对象创建的时候，因为当前处于Unit Test中，没有设备或者模拟器所以没法直接写文件，对于这类特殊的测试就不能使用Unit Test，而是使用第二节中的Instrumentation Test，其中我们可以看到这个测试方法会通过的)

![image](/images/unittest_run.png)

![image](/images/unittest_html.png)

**关于Running from Gradle**

To run your unit tests, just execute the test task: `./gradlew test --continue`. If there are some failing tests, links to HTML reports (one per build variant) will be printed out at the end of the execution.

[使用命令`./gradlew test --continue`可以运行Unit Test，如果有错可以在HTML报告文件中查看错误原因]

This is just an anchor task, actual test tasks are called testDebug and testRelease etc. If you want to run only some tests, using the `gradle --tests` flag, you can do it by running `./gradlew testDebug --tests='*.MyTestClass'`.

[使用`gradle --tests`可以指定运行的测试类]

Because `test` is just a shorthand for `"testDebug testRelease"`, the `--continue` flag is needed if you want to make sure all tests will be executed in all build combinations. Otherwise Gradle could stop after `testDebug` (failing tests cause the task to "fail") and not execute `testRelease` at all.

[`test`是包含了`testDebug`和`testRelease`两部分测试的，如果不加上`--continue`并且`testDebug`出错了的话，`testRelease`便不会执行了]


**关于问题"Method ... not mocked."**

The `android.jar` file that is used to run unit tests does not contain any actual code - that is provided by the Android system image on real devices. Instead, all methods throw exceptions (by default). This is to make sure your unit tests only test your code and do not depend on any particular behaviour of the Android platform (that you have not explicitly mocked e.g. using `Mockito`). If that proves problematic, you can add the snippet below to your `build.gradle` to change this behavior:

```
android {
  // ...
  testOptions {
    unitTests.returnDefaultValues = true
  }
}
```

[文件`android.jar`中并不包含实际的代码，所有方法都只是空盒子，默认情况下都会抛出异常，这就使得你的Unit Test不会依赖于Android系统的某些特定行为，但是也会带来其他的问题(如果你没有使用显式地`Mock`的话)，如果遇到这类问题可以尝试在`builde.gradle`文件中加上上面的配置修改原有的抛出异常的行为。]
