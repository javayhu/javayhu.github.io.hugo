---
title: "Head First Android Testing 2"
date: "2015-05-31"
tags: ["android"]
---
深入浅出Android测试教程 (2) <!--more-->

###第二部分 Instrumentation Tests

Instrumentation Tests又叫Device or Emulator Tests，即运行在设备或者模拟器上的测试。使用`AndroidJunitRunner`来运行，测试代码存放在`androidTest`目录下。

①Run on Device or Emulator
②Run With `AndroidJUnitRunner`
③Located `androidTest/` source set

使用它需要依赖Android Support Repository，所以需要通过SDK Manager下载最新版本的Support Repository。

参考网址[Testing Support Library](http://developer.android.com/tools/testing-support-library/index.html)提到，以前用来做测试的`InstrumentationTestRunner` 类只支持Junit 3，而新的`AndroidJunitRunner`类支持Junit 4。

测试步骤：

(1)配置`build.gradle`

其中`testInstrumentationRunner "android.support.test.runner.AndroidJUnitRunner"`一定要设置，否则可能会出现找不到测试的错误，另外，如果还是使用了其他的库依赖的话，也可以继续添加上去。`AndroidJUnitRunner`是一个功能很强大的测试工具类，支持以下几个特性：

①A new test runner for Android JUnit3/JUnit4 Support
②Instrumentation Registry
③Test Filtering
④Intent Monitoring/Stubbing
⑤Activity/Application Lifecycle Monitoring


```java
apply plugin: 'com.android.application'
android { ...
       defaultConfig {
           ...
           testInstrumentationRunner ‘android.support.test.runner.AndroidJUnitRunner’
        }
}
dependencies {
        // AndroidJUnit Runner dependencies
        androidTestCompile 'com.android.support.test:runner:0.2'
        androidTestCompile 'org.hamcrest:hamcrest-library:1.1'
}
```

(2)配置`Builde Variants`，选择`Android Instrumentation Tests`

![image](/images/instrumentationtest_buildvariants.png)

(3)编写Instrumentation Test程序，放在`src/androidTest/java`目录下

类`ObjectUtil`还是和前面的Unit Test中一样，只是添加一个新的测试类

```
import android.content.Context;
import android.support.test.InstrumentationRegistry;
import android.support.test.filters.RequiresDevice;
import android.support.test.runner.AndroidJUnit4;
import android.test.suitebuilder.annotation.SmallTest;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.io.Serializable;

import polaris.util.ObjectUtil;

import static org.hamcrest.core.Is.is;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThat;

@RunWith(AndroidJUnit4.class)
@SmallTest
public class InstrumentationTestSample {

    Context mMockContext;

    ObjectUtil objectUtil;
    private static final String fileName = "demo";

    @Before
    public void setUp() throws Exception {
        mMockContext = InstrumentationRegistry.getContext();
        objectUtil = new ObjectUtil(mMockContext);
    }

    @Test
    public void testNotNull() {//ok
        //can not find symbol class R
        //when(mMockContext.getString(R.string.app_name)).thenReturn("polaris");
        //assertThat(mMockContext.getString(R.string.app_name), is("polaris"));

        assertNotNull(mMockContext);
        assertNotNull(objectUtil);
    }

    @Test
    public void testSaveAndLoad() {//fail
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

    @After
    public void tearDown() throws Exception {
    }

}
```

(4)配置测试的运行参数

![image](/images/instrumentation_configuration.png)

(5)运行测试有两种方式，可以简单地和运行普通程序一样点击Run按钮，结果会显示在下面的Run视图窗口中，也可以在终端运行`./gradlew connectedAndroidTest`，结果将放在`/build/outputs/reports/androidTests/connected/`中，打开`index.html`文件即可。前者只运行当前测试的运行参数中配置的测试类和方法，而后者会检测整个项目中的所有Instrumentation Test并进行测试。

![image](/images/instrumentation_run.png)

![image](/images/instrumentation_html.png)


**Instrumentation Registry**

通过Instrumentation Registry我们可以获取很多Android运行状态下的组件。

You can use the `InstrumentationRegistry` class to access information related to your test run. This class includes the `Instrumentation` object, target app `Context` object, test app `Context` object, and the command line arguments passed into your test. This data is useful when you are writing tests using the UI Automator framework or when writing tests that have dependencies on the `Instrumentation` or `Context` objects.

```
@Before
public void accessAllTheThings() {
  mArgsBundle = InstrumentationRegistry.getArguments();
  mInstrumentation = InstrumentationRegistry.getInstrumentation();
  mTestAppContext = InstrumentationRegistry.getContext();
  mTargetContext = InstrumentationRegistry.getTargetContext();
}
```

**￼Test Filters**

通过Test Filters我们可以指定测试时的最小SDK版本或者是否必须使用设备。

`@RequiresDevice`: Specifies that the test should run only on physical devices, not on emulators.

`@SdkSupress`: Suppresses the test from running on a lower Android API level than the given level. For example, to suppress tests on all API levels lower than 18 from running, use the annotation @SDKSupress(minSdkVersion=18).

`@SmallTest`, `@MediumTest`, and `@LargeTest`: Classify how long a test should take to run, and consequently, how frequently you can run the test.

```
@SdkSuppress(minSdkVersion=15)
@Test
public void featureWithMinSdk15() {
...
}

@RequiresDevice
@Test
public void SomeDeviceSpecificFeature() {
...
}
```

可以看出Instrumentation Test的功能还是很强大的，这里只是冰山一角，感兴趣可以继续阅读更多的资料去学习，Enjoy it！
