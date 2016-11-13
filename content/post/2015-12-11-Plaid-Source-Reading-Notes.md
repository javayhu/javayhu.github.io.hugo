---
title: Plaid Source Reading Notes
tags: ["android"]
date: "2015-12-11"
published: false
---
Plaid源码阅读笔记。 <!--more-->

1.AndroidManifest文件中的`activity-alias`使用

```
<!-- use an alias in case we want to change the launch activity later without breaking
     homescreen shortcuts.  Note must be defined after the targetActivity -->
<activity-alias
    android:name=".Launcher"
    android:label="@string/app_name"
    android:targetActivity=".ui.HomeActivity">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity-alias>
```

2.在`application`中配置`meta-data`

```
<!-- Glide configurations for image loading -->
<meta-data
    android:name="io.plaidapp.util.glide.GlideConfiguration"
    android:value="GlideModule" />
<meta-data
    android:name="com.bumptech.glide.integration.okhttp.OkHttpGlideModule"
    android:value="GlideModule" />
```

甚至可以在AndroidManifest文件中获取到在Gradle配置的数据，比如下面的配置不同的渠道
```
//AndroidManifest
<meta-data
    android:name="UMENG_CHANNEL"
    android:value="${UMENG_CHANNEL_VALUE}" />

//build.gradle
productFlavors {
    playStore {
        manifestPlaceholders = [UMENG_CHANNEL_VALUE: "playStore"]
    }
    miui {
        manifestPlaceholders = [UMENG_CHANNEL_VALUE: "miui"]
    }
    wandoujia {
        manifestPlaceholders = [UMENG_CHANNEL_VALUE: "wandoujia"]
    }
}
```

3.Gradle中`buildConfigField`的配置
通过在Gradle文件中配置的`buildConfigField`可以在自动生成的`BuildConfig`文件中获取到，可以给不同的buildType设置不同的值。

在`build.gralde`中添加一些BuildConfig字段
```
defaultConfig {
    applicationId "io.awesome"
    minSdkVersion 16
    targetSdkVersion 23
    versionCode 1
    versionName "1.0"

    buildConfigField "String", "DRIBBBLE_CLIENT_ID", "\"${dribbble_client_id}\""
    buildConfigField "String", "DRIBBBLE_CLIENT_SECRET", "\"${dribbble_client_secret}\""
    buildConfigField "String", "DRIBBBLE_CLIENT_ACCESS_TOKEN", "\"${dribbble_client_access_token}\""
}
```

对于其中引用的字段值可以放在`gradle.properties`中配置
```
# Dribbble API
dribbble_client_id = xxx
dribbble_client_secret = yyy
dribbble_client_access_token = zzz
```

待Gradle Sync之后在文件`app/build/source/BuildConfig/Build Varients/package name/BuildConfig`就会看到添加的字段

```
public final class BuildConfig {
  public static final boolean DEBUG = Boolean.parseBoolean("true");
  public static final String APPLICATION_ID = "io.awesome";
  public static final String BUILD_TYPE = "debug";
  public static final String FLAVOR = "";
  public static final int VERSION_CODE = 1;
  public static final String VERSION_NAME = "1.0";
  // Fields from default config.
  public static final String DRIBBBLE_CLIENT_ACCESS_TOKEN = "xxx";
  public static final String DRIBBBLE_CLIENT_ID = "yyy";
  public static final String DRIBBBLE_CLIENT_SECRET = "zzz";
}
```

4.在Gradle中定义`supportLibVersion`做到supportlib的版本统一

```
ext {
    archivesBaseName = "plaid-${android.defaultConfig.versionName}"
    supportLibVersion = '23.1.0'
}

dependencies {
    compile "com.android.support:support-v4:${supportLibVersion}"
    compile "com.android.support:palette-v7:${supportLibVersion}"
    compile "com.android.support:recyclerview-v7:${supportLibVersion}"
    compile "com.android.support:cardview-v7:${supportLibVersion}"
    compile "com.android.support:design:${supportLibVersion}"
    compile "com.android.support:customtabs:${supportLibVersion}"
    ...
}
```

5.

ItemTouchHelper.SimpleCallback



401 Unauthorized

https://dribbble.com/oauth/authorize?client_id=6524bd42d3fa3e35eda63d3e0afce0db8b96575b1db4f7580344a9cb2dd89495&redirect_uri=plaid%3A%2F%2Fdribbble-auth-callback&scope=public+write+comment+upload
