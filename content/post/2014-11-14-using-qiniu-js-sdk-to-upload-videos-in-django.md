---
title: "using Qiniu JS SDK to upload Videos in Django"
date: "2014-11-14"
categories: "dev"
---
使用七牛云存储服务来存储网站(Django开发)中用户上传的视频，特此记录下来，以防以后需要。<!--more-->

PS: 如何想要在SAE上使用Qiniu的话就需要将Qiniu Python SDK相关的源文件都拷贝到Django项目中，否则SAE会报找不到`qiniu`这个模块，因为SAE内置的预定义的模块列表中没有`qiniu`！

我想要的目标是可以上传视频，最好还能显示上传的进度

七牛提供了一个演示通过文件上传的网站：[http://jssdk.demo.qiniu.io](http://jssdk.demo.qiniu.io)

![image](/images/qiniu1.png)

该SDK是七牛提供的Javascript SDK，传送门: [七牛的Javascript SDK on Github](https://github.com/qiniupd/qiniu-js-sdk)

这个演示网站做得非常不错，演示了文件上传并显示了上传的进度，正是我想要的效果，所以我后面把这个JS SDK嵌入到Django项目中，测试其功能

下面这段代码演示的是在纯Python项目中如何将文件上传到七牛服务器，若还没有安装七牛的话请先运行 `pip install qiniu` [注意，我的版本是`6.1.8`，最近七牛的SDK发生了大变化，所以如果想要和我得到一样的效果请安装`6.1.8`版本，我的好友已经测试过其他的更新的版本都不行]

```python
# coding=utf-8
import os

__author__ = 'hujiawei'
__doc__ = 'qiniu sdk video demo'

import StringIO
import sys
import qiniu.conf
import qiniu.rs
import qiniu.io

BUCKET_NAME = "YOUR_BUCKET_NAME"
qiniu.conf.ACCESS_KEY = "YOUR_ACCESS_KEY"
qiniu.conf.SECRET_KEY = "YOUR_SECRET_KEY"

policy = qiniu.rs.PutPolicy(BUCKET_NAME)
uptoken = policy.token()
print(uptoken)

# ############ 示例：上传视频 ###############
# extra = qiniu.io.PutExtra()
# item = os.path.join(os.getcwd(), 'hellokitty.m4v')
# ret, err = qiniu.io.put_file(uptoken, None, item, extra)
# if err is not None:
#     sys.stderr.write('error: %s ' % err)

#ok: hamster.swf


# ############ 示例：上传图片 ###############
extra = qiniu.io.PutExtra()
extra.mime_type = "image/jpeg"
# print os.getcwd() #/Users/hujiawei/PycharmProjects/qiniusimple
item = os.path.join(os.getcwd(), 'coder.jpg')
ret, err = qiniu.io.put_file(uptoken, None, item, extra)
if err is not None:
    sys.stderr.write('error: %s ' % err)

# extra = qiniu.io.PutExtra()
# # extra.mime_type = "image/jpeg" #image/png 七牛能够自动识别mime-type
# # print os.getcwd() #/Users/hujiawei/PycharmProjects/qiniusimple
# item = os.path.join(os.getcwd(), 'apple.png')
# ret, err = qiniu.io.put_file(uptoken, None, item, extra)

############# 示例：上传字符串内容 ###############
# extra = qiniu.io.PutExtra()
# extra.mime_type = "text/plain"
# key = "hellotxt"
# data = StringIO.StringIO("hello!") # data 可以是str或readable对象
# ret, err = qiniu.io.put(uptoken, key, data, extra)
# if err is not None:
#     sys.stderr.write('error: %s ' % err)
```

本来我以为要在Django中使用这个SDK会很难，因为看到该项目的Github介绍还要安装`Node.js`等工具，可是实践了发现其实不难，如果只是想简单地使用它那么可以就把它们当做一个js库就行了，但是因为qiniu js sdk源码中的重要文件里面使用了不少相对路径，所以建议还是将sdk中的所有内容一起拷贝到Django项目中，保持其原有的相对位置。

需要的可以下载我制作的可运行的Django项目 [A Django site using Qiniu JS SDK](/files/qiniudemo.zip)

如果要正常运行，请先仔细阅读下面的内容：

1.修改`video/views.py`中的如下内容，具体填什么你懂得

```
BUCKET_NAME = "YOUR_BUCKET_NAME"
qiniu.conf.ACCESS_KEY = "YOUR_ACCESS_KEY"
qiniu.conf.SECRET_KEY = "YOUR_SECRET_KEY"
```

2.修改`static/js/main.js`中的内容，我设置了获取uptoken的请求URL为`/video/uptoken`，这样每次要上传一个文件的时候，这个URL就会被调用，它会返回一个JSON字符串，包含了`uptoken`的值，具体可见`video/views.py`中的`uptoken`方法；其次还设置了域名，你需要将它设置为你的七牛域名，例如`http://whyeduvideo.qiniudn.com/`

```
uptoken_url: '/video/uptoken',
domain: 'YOUR_DOMAIN_NAME',
```

其他的内容就不用修改了，直接运行项目，进入到`http://127.0.0.1:8000/video/`下就能看到

![image](/images/qiniu2.png)

如果你想要得到上传之后的文件在七牛服务器上的链接地址的话，请看下面的内容

在SDK的`js/ui.js`文件的189行的函数中，其中的变量`url`就是我们需要的，我们只需要通过js将这个变量赋值给界面中的其他元素中就行了，可以直接在下面的函数中进行赋值，也可以在`js/main.js`文件的`FileUploaded`函数中进行赋值，推荐后面一种方式。

下面代码中的`id='videourl'`是我自己添加的，用于后面的赋值操作

```
FileProgress.prototype.setComplete = function(up, info) {
    var td = this.fileProgressWrapper.find('td:eq(2) .progress');
    var res = $.parseJSON(info);
    var url;
    if (res.url) {
        url = res.url;
        str = "<div><strong>Link:</strong><a href=" + res.url + " target='_blank' id='videourl' > " + res.url + "</a></div>" +
            "<div class=hash><strong>Hash:</strong>" + res.hash + "</div>";
    } else {
        var domain = up.getOption('domain');
        url = domain + encodeURI(res.key);
        var link = domain + res.key;
        str = "<div><strong>Link:</strong><a href=" + url + " target='_blank'  id='videourl' > " + link + "</a></div>" +
            "<div class=hash><strong>Hash:</strong>" + res.hash + "</div>";
    }
```

在`js/main.js`文件的`FileUploaded`函数中进行赋值，下面的例子是将url赋值给表单中的一个隐藏的input组件。

```
 'FileUploaded': function(up, file, info) {
                var progress = new FileProgress(file, 'fsUploadProgress');
                progress.setComplete(up, info);

                $('#inputurl').val($('#videourl').attr("href"));//url

            },
```
