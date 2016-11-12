---
title: "Using Git with multiple Public Keys"
date: "2015-05-16"
categories: "dev"
---
本文介绍如何同时使用多个Git的公私钥 <!--more-->

很多时候，如果我们在多个网站有了Git账号，例如Github、GitCafe、CodingNet等，当我们与不同网站的代码库进行连接的时候可能会因为我们没有配置或者配置不当，导致我们需要重复输入账号密码的问题，本文就是介绍如何同时使用多个公秘钥。

内容参考自GitCafe帮助文档[如何同时使用多个公秘钥](https://gitcafe.com/GitCafe/Help/wiki/%E5%A6%82%E4%BD%95%E5%90%8C%E6%97%B6%E4%BD%BF%E7%94%A8%E5%A4%9A%E4%B8%AA%E5%85%AC%E7%A7%98%E9%92%A5#wiki)

之前我已经配置了三个GitCafe的账号，下面以配置CodingNet为例，介绍整个配置过程。

1.生成新的SSH秘钥

记得把以下命令中的`YOUR_EMAIL@YOUREMAIL.COM`改为你的 Email 地址

```
ssh-keygen -t rsa -C "YOUR_EMAIL@YOUREMAIL.COM" -f ~/.ssh/codingnet
```

2.生成过程中会出现以下信息，按屏幕提示操作，并记得输入 `passphrase` 口令(可以为空)。这将在 `~/.ssh/` 目录下生成 `codingnet` 和 `codingnet.pub` 文件，记住千万不要把私钥文件 `codingnet` 透露给任何人。

```
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/hujiawei/.ssh/codingnet.
Your public key has been saved in /Users/hujiawei/.ssh/codingnet.pub.
The key fingerprint is:
f6:66:dd:e9:f4:72:c7:dc:90:86:50:f0:4f:ba:ff:64 hujiawei090807@gmail.com
The key's randomart image is:
+--[ RSA 2048]----+
|          ..     |
|           ..    |
|           .. .  |
|          .  +   |
|        S  ..... |
|       . . ..o+. |
|          + o.++E|
|         o   +.+*|
|              o++|
+-----------------+
```

3.在 SSH 用户配置文件 `~/.ssh/config` 中指定对应服务所使用的公秘钥名称，如果没有 `config` 文件的话就新建一个，并输入以下内容


```
Host git.coding.net www.coding.net
  IdentityFile ~/.ssh/codingnet
```

4.添加 `codingnet.pub` 中的内容到 Coding.net 网站，注意，不需要保留文件结尾的邮件地址

复制文件内容到剪切板中
```
pbcopy < ~/.ssh/codingnet.pub
```

![image](/images/codingnet.png)

5.最后测试配置文件是否正常工作

```
ssh -T git@git.coding.net
```

如果提示是否继续连接的话输入`yes`，这样就会永久地将连接信息添加到文件`know_hosts`中。最后如果连接成功的话，会出现成功的信息。

```
Coding.net Tips : [Hello hujiawei! You've connected to Coding.net by SSH successfully! ]
```

6.完成

测试通过后，你就可以使用独立的一套公秘钥来使用 CodingNet 了。

Enjoy！
