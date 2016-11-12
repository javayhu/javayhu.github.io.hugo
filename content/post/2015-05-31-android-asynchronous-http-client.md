---
title: "Android Asynchronous Http Client"
date: "2015-05-31"
categories: "android"
---
本文总结了著名的Android的异步网络请求库Asynchronous Http Client的使用 <!--more-->

最近在阅读[Coding的安卓客户端源码](https://coding.net/u/coding/p/Coding-Android/git)，因为该源码使用了[android-async-http](https://github.com/loopj/android-async-http)，所以有必要先研究一下它的使用，以下内容基本上来自官网教程，我主要是做了翻译或者注解。

#### 1.Asynchronous Http Client for Android简介

Android开源库中鼎鼎大名的网络库[Asynchronous Http Client for Android](http://loopj.com/android-async-http/)，顾名思义，是一个实现网络异步请求的类库，它是基于Apache的HttpClient类库开发的，所有的HTTP请求都是在非UI线程中进行的，你也可以在Service或者后台线程中使用它。

**An asynchronous callback-based Http client for Android built on top of Apache’s HttpClient libraries.** All requests are made outside of your app’s main UI thread, but any callback logic will be executed on the same thread as the callback was created using Android’s Handler message passing. You can also use it in Service or background thread, library will automatically recognize in which context is ran.

它的功能异常强大，主要包括：

1.Make asynchronous HTTP requests, handle responses in anonymous callbacks

异步发送HTTP请求，并以匿名回调的形式处理HTTP结果

2.HTTP requests happen outside the UI thread

HTTP请求自动在非UI线程中操作

3.GET/POST params builder (`RequestParams`)

提供了GET和POST请求参数的构建器(`RequestParams`)

4.Multipart file uploads with no additional third party libraries

不需要添加其他第三方类库实现多文件上传的功能

5.Streamed JSON uploads with no additional libraries

不需要添加其他第三方类库实现流式的JSON格式数据上传

6.Handling circular and relative redirects

处理[circular]和相对的重定向

7.Tiny size overhead to your application, only 90kb for everything

体积小，只有90kb大小

8.Automatic smart request retries optimized for spotty mobile connections

针对移动设备的连接优化过的自动请求重试

9.Automatic gzip response decoding support for super-fast requests

自动解码gzip格式的请求结果

10.Binary protocol communication with `BinaryHttpResponseHandler`

二进制形式的协议通信，使用`BinaryHttpResponseHandler`

11.Built-in response parsing into JSON with `JsonHttpResponseHandler`

内置将HTTP结果解析成JSON字符串，使用`JsonHttpResponseHandler`

12.Saving response directly into file with `FileAsyncHttpResponseHandler`

直接将请求结果保存到文件，使用`FileAsyncHttpResponseHandler`

13.Persistent cookie store, saves cookies into your app’s `SharedPreferences`

持久地将Cookie信息保存到应用的`SharedPreferences`中

14.Integration with Jackson JSON, Gson or other JSON (de)serializing libraries with `BaseJsonHttpResponseHandler`

集成了Jackson JSON，Gson和其他的JSON(反)序列化操作库，使用`BaseJsonHttpResponseHandler`

15.Support for SAX parser with SaxAsyncHttpResponseHandler

支持SAX解析库，使用`SaxAsyncHttpResponseHandler`

16.Support for languages and content encodings, not just UTF-8

支持语言和内容编码，不仅仅是UTF-8

17.Requests use a threadpool to cap concurrent resource usage

HTTP请求会使用一个线程池来维护并发的资源使用 **[?]**


#### 2.导入方式

Gradle

```java
dependencies {
  compile 'com.loopj.android:android-async-http:1.4.5'
}
```

#### 3.使用方式

##### 3.1 基本使用方式

从下面的示例代码中，我们可以看出首先是创建`AsyncHttpClient`类的对象实例，然后向指定的URL发送GET或者POST请求，请求结果的回调处理由匿名类`AsyncHttpResponseHandler`来完成，主要包括了四个回调函数。`AsyncHttpResponseHandler`类有很多的子接口，分别对应了不同的请求结果的处理方式，例如`JsonHttpResponseHandler`、`BinaryHttpResponseHandler`、`FileAsyncHttpResponseHandler`等等。

```
//需要导入的包
import com.loopj.android.http.*;

//使用的示例
AsyncHttpClient client = new AsyncHttpClient();
client.get("http://www.google.com", new AsyncHttpResponseHandler() {

    @Override
    public void onStart() {
        // called before request is started
    }

    @Override
    public void onSuccess(int statusCode, Header[] headers, byte[] response) {
        // called when response HTTP status is "200 OK"
    }

    @Override
    public void onFailure(int statusCode, Header[] headers, byte[] errorResponse, Throwable e) {
        // called when response HTTP status is "4XX" (eg. 401, 403, 404)
    }

    @Override
    public void onRetry(int retryNo) {
        // called when request is retried
	}
});
```

##### 3.2 推荐的使用方式

创建静态(`static`)的Http Client

由一个类来提供一个static的`AsyncHttpClient`类对象实例，并通过该实例来发送GET或者POST请求。

```
import com.loopj.android.http.*;

public class TwitterRestClient {
  private static final String BASE_URL = "http://api.twitter.com/1/";

  private static AsyncHttpClient client = new AsyncHttpClient();

  public static void get(String url, RequestParams params, AsyncHttpResponseHandler responseHandler) {
      client.get(getAbsoluteUrl(url), params, responseHandler);
  }

  public static void post(String url, RequestParams params, AsyncHttpResponseHandler responseHandler) {
      client.post(getAbsoluteUrl(url), params, responseHandler);
  }

  private static String getAbsoluteUrl(String relativeUrl) {
      return BASE_URL + relativeUrl;
  }
}
```

这样的话，使用起来就很方便啦

```
import org.json.*;
import com.loopj.android.http.*;

class TwitterRestClientUsage {
    public void getPublicTimeline() throws JSONException {
        TwitterRestClient.get("statuses/public_timeline.json", null, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                // If the response is JSONObject instead of expected JSONArray
            }

            @Override
            public void onSuccess(int statusCode, Header[] headers, JSONArray timeline) {
                // Pull out the first event on the public timeline
                JSONObject firstEvent = timeline.get(0);
                String tweetText = firstEvent.getString("text");

                // Do something with the response
                System.out.println(tweetText);
            }
        });
    }
}
```

#### 4.其他特性

##### 4.1 `PersistentCookieStore`

This library also includes a `PersistentCookieStore` which is an implementation of the Apache HttpClient `CookieStore` interface that automatically saves cookies to `SharedPreferences` storage on the Android device.

`PersistentCookieStore`实现了Apache HttpClient类库中的`CookieStore`接口，并能够自动将cookies信息保存到应用的`SharedPreferences`中。这个功能想必大家以前也都实现过吧，这下终于不用重复造轮子了。

使用方法：

```
//1.创建client
AsyncHttpClient myClient = new AsyncHttpClient();

//2.创建PersistentCookieStore，并设置给client
//set this client’s cookie store to be a new instance of PersistentCookieStore, constructed with an activity or application context
PersistentCookieStore myCookieStore = new PersistentCookieStore(this);
myClient.setCookieStore(myCookieStore);

//3.OK！从服务器端收到的cookies会自动地保存到SharedPreferences中
//Any cookies received from servers will now be stored in the persistent cookie store.

//4.如果你想添加自己的cookies进行保存，只需要创建cookie然后addCookie即可
BasicClientCookie newCookie = new BasicClientCookie("cookiesare", "awesome");
newCookie.setVersion(1);
newCookie.setDomain("mydomain.com");
newCookie.setPath("/");
myCookieStore.addCookie(newCookie);
```

##### 4.2 `RequestParams`

使用`RequestParams`创建GET或POST请求的参数，创建的方式很多：

```
//1.先创建RequestParams然后添加参数
RequestParams params = new RequestParams();
params.put("key", "value");
params.put("more", "data");

//2.创建RequestParams时就指定参数
RequestParams params = new RequestParams("single", "value");

//3.从Map的键值对中创建RequestParams
HashMap<String, String> paramMap = new HashMap<String, String>();
paramMap.put("key", "value");
RequestParams params = new RequestParams(paramMap);
```

##### 4.3 上传文件

`RequestParams`支持上传文件，使用方式也有几种：

```
//1.添加InputStream到RequestParams中
InputStream myInputStream = blah;
RequestParams params = new RequestParams();
params.put("secret_passwords", myInputStream, "passwords.txt");

//2.添加File对象到RequestParams中
File myFile = new File("/path/to/file.png");
RequestParams params = new RequestParams();
try {
    params.put("profile_picture", myFile);
} catch(FileNotFoundException e) {}

//3.添加字节数组byte array到RequestParams中
byte[] myByteArray = blah;
RequestParams params = new RequestParams();
params.put("soundtrack", new ByteArrayInputStream(myByteArray), "she-wolf.mp3");
```

##### 4.4 下载文件

使用`FileAsyncHttpResponseHandler`可以下载二进制数据(例如图片)并保存到文件中

```
AsyncHttpClient client = new AsyncHttpClient();
client.get("http://example.com/file.png", new FileAsyncHttpResponseHandler(/* Context */ this) {
    @Override
    public void onSuccess(int statusCode, Header[] headers, File response) {
        // Do something with the file `response`
    }
});
```

##### 4.5 HTTP Basic Auth credentials

Some requests may need `username/password` credentials when dealing with API services that use HTTP Basic Access Authentication requests. You can use the method `setBasicAuth()` to provide your credentials.

有些请求需要身份验证，这时候你可以使用`setBasicAuth()`来提供你的用户名和密码等信息。

Set `username/password` for any host and realm for a particular request. By default the `Authentication Scope` is for any host, port and realm.

默认情况下，身份认证的作用域是对于任何主机任何端口的。

```
AsyncHttpClient client = new AsyncHttpClient();
client.setBasicAuth("username","password/token");
client.get("http://example.com");
```

You can also provide a more specific Authentication Scope (recommended)

你同样可以提供更加针对性的身份认证信息。(推荐方式)

```
AsyncHttpClient client = new AsyncHttpClient();
client.setBasicAuth("username","password", new AuthScope("example.com", 80, AuthScope.ANY_REALM));
client.get("http://example.com");
```

OK，介绍完毕，可以看出，这个小小的类库不仅功能很强大，而且提供的操作接口也是相当简单的。Enjoy it！
