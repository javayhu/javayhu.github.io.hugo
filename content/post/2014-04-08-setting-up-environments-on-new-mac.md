---
title: "Setting Up Environments on New Mac"
date: "2014-04-08"
categories: "dev"
---
本文介绍在新苹果机上搭建各种开发环境的过程<!--more-->

1.安装Java 7u51 ［直接在[官网](http://www.java.com/zh_CN/download/manual.jsp)下载dmg点击安装即可]

`JAVA_HOME=/Library/Java/JavaVirtualMachines/1.7.0_51.jdk/Contents/Home`

为了保证Eclipse和Matlab等需要JRE 6的应用程序能够运行，还需要 ［`1.7.0.jdk`部分可能需要修改］
[个人猜测，因为Mac OS X早期系统和Mavericks中将JDK存放的位置不同，很多程序按照以前的位置去查找，所以找不到，不能正常启动]

`sudo mkdir /System/Library/Java/JavaVirtualMachines`
`sudo ln -s /Library/Java/JavaVirtualMachines/1.7.0.jdk /System/Library/Java/JavaVirtualMachines/1.6.0.jdk`

实际上上面的操作还是会导致系统存在两个JRE（6和7），不过已经算是很好的解决方案了

网址：[http://apple.stackexchange.com/questions/58203/mountain-lion-with-java-7-only](http://apple.stackexchange.com/questions/58203/mountain-lion-with-java-7-only)

2.安装HomeBrew

网址：[https://raw.github.com/Homebrew/homebrew/go/install](https://raw.github.com/Homebrew/homebrew/go/install)
网址：[http://linfan.info/blog/2012/02/25/homebrew-installation-and-usage/](http://linfan.info/blog/2012/02/25/homebrew-installation-and-usage/) [Homebrew使用教程]

执行`ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"`，如果还没有安装Xcode，则需要安装CLT(Command Line Tools) `"xcode-select --install"`

Homebrew会将安装的软件包存放在`/usr/local/`目录下，例如`/usr/local/bin`存放一些可执行文件，`/usr/local/lib`存放一些公共库，通过homebrew安装的软件包存放在`/usr/local/Cellar`目录下。
通过`brew doctor`命令可以检查系统中软件包可能存在的一些问题。添加`export PATH=/usr/local/bin:$PATH`到`~/.bash_profile`文件中，这样默认先使用Homebrew安装的应用程序，而不是使用系统。[注：Homebrew不会破坏系统的一些软件或者环境变量，另外，Homebrew下载的安装包存放在`/Library/Caches/Homebrew`目录中，创建的Formula存放在`/usr/local/Library/Formula`目录中]

```java
hujiawei-MacBook-Pro:~ hujiawei$ ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
==> This script will install:
/usr/local/bin/brew
/usr/local/Library/...
/usr/local/share/man/man1/brew.1
...
==> Installation successful!
You should run `brew doctor' *before* you install anything.
Now type: brew help
```

3.安装git

网址：[https://help.github.com/articles/generating-ssh-keys](https://help.github.com/articles/generating-ssh-keys)

`brew install git`，然后按照网址提示添加`ssh－key`

```
hujiawei-MacBook-Pro:.ssh hujiawei$ ssh-add ~/.ssh/id_rsa
Identity added: /Users/hujiawei/.ssh/id_rsa (/Users/hujiawei/.ssh/id_rsa)
hujiawei-MacBook-Pro:.ssh hujiawei$ pbcopy < ~/.ssh/id_rsa.pub
hujiawei-MacBook-Pro:.ssh hujiawei$ pbcopy < ~/.ssh/id_rsa.pub
hujiawei-MacBook-Pro:.ssh hujiawei$ ssh -T git@github.com
Warning: Permanently added the RSA host key for IP address '192.30.252.128' to the list of known hosts.
Hi hujiaweibujidao! You've successfully authenticated, but GitHub does not provide shell access.
```

4.配置python环境

网址：[http://penandpants.com/2012/02/24/install-python/](http://penandpants.com/2012/02/24/install-python/)

使用Homebrew安装了python之后，python路径修改为 `/usr/local/bin/python` [原来在 `/usr/bin/python`]，`pip install <package>`命令会将模块安装到`/usr/local/lib/python2.7/site-packages`中。`pip list`命令查看已经安装的Python模块。

```
hujiawei-MacBook-Pro:~ hujiawei$ brew install python
Warning: A newer Command Line Tools release is available
Update them from Software Update in the App Store.
==> Installing dependencies for python: readline, sqlite, gdbm
==> Installing python dependency: readline
==> Downloading https://downloads.sf.net/project/machomebrew/Bottles/readline-6.
==> Pouring readline-6.2.4.mavericks.bottle.2.tar.gz
==> Caveats
...
```

如果把`/usr/local/share/python`（参考网站提示用来存放Python脚本）也添加到`$PATH`中的话，`brew doctor`会给出一个警告，暂时不添加。

```
Warning: /usr/local/share/python is not needed in PATH.
Formerly homebrew put Python scripts you installed via `pip` or `pip3`
(or `easy_install`) into that directory above but now it can be removed
from your PATH variable.
Python scripts will now install into /usr/local/bin.
You can delete anything, except 'Extras', from the /usr/local/share/python
(and /usr/local/share/python3) dir and install affected Python packages
anew with `pip install --upgrade`.
```

安装好了python之后，按照网址上的内容继续安装pip，然后安装`virtualenv, virtualenvwrapper, numpy, gfortran, scipy, matplotlib`等模块。[注，一般软件包使用brew安装和管理，对于python的模块使用pip安装和管理]

5.配置Ruby环境 ［为了正常使用原有的Octopress］

网址：[/blog/2013/11/17/hello-octopress/](/blog/2013/11/17/hello-octopress/)
网址：[http://blog.zerosharp.com/clone-your-octopress-to-blog-from-two-places/](http://blog.zerosharp.com/clone-your-octopress-to-blog-from-two-places/)
网址：[http://octopress.org/docs/setup/](http://octopress.org/docs/setup/) [http://octopress.org/docs/deploying/github/](http://octopress.org/docs/deploying/github/)

执行`rbenv install 1.9.3-p0` 时需要`apple-gcc42`，执行 `brew tap homebrew/dupes ; brew install apple-gcc42`

```
hujiawei-MacBook-Pro:eclipse_cp hujiawei$ brew install rbenv
Warning: A newer Command Line Tools release is available
Update them from Software Update in the App Store.
==> Downloading https://github.com/sstephenson/rbenv/archive/v0.4.0.tar.gz
==> Caveats
To use Homebrew's directories rather than ~/.rbenv add to your profile:
  export RBENV_ROOT=/usr/local/var/rbenv
...
```

rbenv是一个管理ruby环境的工具，gem相当于管理ruby模块的工具。(`gem list`查看已安装的模块)

如果想要使用以前的Octopress的话，执行下面的命令，之后就可以像以前一样使用Octopress了

```
brew update
brew install rbenv
brew install ruby-build
rbenv install 1.9.3-p0
rbenv rehash
rbenv global 1.9.3-p0  #建议增加这句修改系统全局的ruby版本
ruby --version  #查看系统ruby版本
cd <path-to-octopress>
gem install bundler
rbenv rehash    # If you use rbenv, rehash to be able to run the bundle command
bundle install
```

**更新内容 2015-10-10**
最近又升级了系统到Mac OS X El Capitan，没想到Octopress环境出现了问题，generate命令执行不了，经过一番折腾，发现原来升级系统之后系统默认的ruby版本是2.0以上的了（执行`ruby --version`），我之前安装的是`1.9.3-p0`（执行`rbenv versions`），两者不统一；而且貌似以前安装好的一些依赖也不能正常工作了，所以就执行了下面一些操作。

1.在文件`.bash_profile`末尾添加，之后在终端执行`ruby --version`将看到`1.9.3-p0`    
参考[http://stackoverflow.com/questions/10940736/rbenv-not-changing-ruby-version](http://stackoverflow.com/questions/10940736/rbenv-not-changing-ruby-version)

`export PATH="$HOME/.rbenv/bin:$PATH"`
`eval "$(rbenv init -)"`    

2.接着在Octopress的目录下重新执行下面的命令即可      
参考[http://octopress.org/docs/setup/](http://octopress.org/docs/setup/)

```
gem install bundler
rbenv rehash    # If you use rbenv, rehash to be able to run the bundle command
bundle install
```

其他可能有帮助的网址：
（1）[https://github.com/sstephenson/ruby-build/wiki](https://github.com/sstephenson/ruby-build/wiki)
（2）[https://ruby-china.org/wiki/rbenv-guide](https://ruby-china.org/wiki/rbenv-guide)


6.配置OpenCV环境

网址：[/blog/2014/03/13/develop-with-opencv-on-mac-os-x/](/blog/2014/03/13/develop-with-opencv-on-mac-os-x/)

**注意！如果是进行OpenCV源码编译的话，因为会产生很多的文件保存到`/usr/local`下的各个子目录中，这会导致`brew doctor`报出很多错误，例如`/usr/local/lib`下很多OpenCV的库Homebrew不能识别，甚至涉及到了权限问题，所以建议不要再前面进行OpenCV环境的配置！**

正常情况下的OpenCV配置：安装CMake，编译OpenCV源码，花的时间比较长

```
sudo brew install cmake //homebrew
cd <path-to-opencv-source>
mkdir release
cd release
cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local ..
make
sudo make install
```

如果导致前面出现Python环境配置出现问题，可以尝试卸载OpenCV，还要手动删除一些`/usr/local`下的OpenCV目录。

```
hujiawei-MacBook-Pro:hujiawei hujiawei$ cd Android/opencv-2.4.6.1/
hujiawei-MacBook-Pro:opencv-2.4.6.1 hujiawei$ cd release
hujiawei-MacBook-Pro:release hujiawei$ sudo make uninstall
Password:
Scanning dependencies of target uninstall
-- Uninstalling "/usr/local/include/opencv2/opencv_modules.hpp"
-- Uninstalling "/usr/local/lib/pkgconfig/opencv.pc"
-- Uninstalling "/usr/local/share/OpenCV/OpenCVConfig.cmake"
-- Uninstalling "/usr/local/share/OpenCV/OpenCVConfig-version.cmake"
-- Uninstalling "/usr/local/include/opencv/cv.h"
-- Uninstalling "/usr/local/include/opencv/cv.hpp"
...
-- Uninstalling "/usr/local/share/OpenCV/haarcascades/haarcascade_smile.xml"
-- Uninstalling "/usr/local/share/OpenCV/haarcascades/haarcascade_upperbody.xml"
-- Uninstalling "/usr/local/share/OpenCV/lbpcascades/lbpcascade_frontalface.xml"
-- Uninstalling "/usr/local/share/OpenCV/lbpcascades/lbpcascade_profileface.xml"
-- Uninstalling "/usr/local/share/OpenCV/lbpcascades/lbpcascade_silverware.xml"
-- Uninstalling "/usr/local/bin/opencv_haartraining"
-- Uninstalling "/usr/local/bin/opencv_createsamples"
-- Uninstalling "/usr/local/bin/opencv_performance"
-- Uninstalling "/usr/local/bin/opencv_traincascade"
Built target uninstall
```
如果可以的话，使用Homebrew安装OpenCV

参考网址：[http://www.jeffreythompson.org/blog/2013/08/22/update-installing-opencv-on-mac-mountain-lion/](http://www.jeffreythompson.org/blog/2013/08/22/update-installing-opencv-on-mac-mountain-lion/)  支持Mavericks

其他关于搭建OpenCV环境的文章 [http://blog.sciencenet.cn/blog-702148-657754.html](http://blog.sciencenet.cn/blog-702148-657754.html)

我的系统在执行`brew install jasper`时不知何原因不能继续，一直停留在`make install`状态，所以`brew install opencv`不能成功，即使我修改japser或者opencv的Formula文件也无济于事，最终尝试还是进行OpenCV源码编译，但是不安装到`/usr/local/`目录中，方法是修改下面的`CMAKE_INSTALL_PREFIX`

```
cd <path-to-opencv-source>
mkdir release
cd release
cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/opencv ..
make
sudo make install
```
但是，还有一个问题，无论在Xcode还是Eclipse中创建OpenCV项目都一样会报一个错，如下：

```
dyld: Library not loaded: lib/libopencv_core.2.4.dylib
  Referenced from: /Users/hujiawei/Library/Developer/Xcode/DerivedData/PRWorks-gmeabxnfaunwiqbrvvjpxjlfkymu/Build/Products/Debug/PRWorks
  Reason: image not found
```

即使你的路径都没错也还是不能加载到，不知道何原因，但是如果你直接将编译之后的所有dylib复制到`/usr/local/lib`中即可，不能是该目录下的某个文件夹！复制了之后，自然`brew doctor`会对此进行警告，无视吧。
一个常用来测试OpenCV环境的项目代码如下，需要opencv_core和opencv_highgui两个库

```
#include <opencv2/opencv.hpp>
using namespace cv;
int main(int argc, char** argv) {
	Mat image;
	image = imread(
			"/Users/hujiawei/Pictures/webimages/clone-your-octopress-001.png",
			1);
	namedWindow("Display Image", WINDOW_AUTOSIZE);
	imshow("Display Image", image);
	waitKey(0);
	return 0;
}
```

7.最后执行`brew linkapps`会将brew安装的python中的app链接到Applications中

```
hujiawei-MacBook-Pro:~ hujiawei$ brew linkapps
Linking /usr/local/Cellar/python/2.7.6/IDLE.app
Linking /usr/local/Cellar/python/2.7.6/Python Launcher.app
Finished linking. Find the links under /Applications.
```

使用`brew doctor`检查，修复问题。

```
hujiawei-MacBook-Pro:~ hujiawei$ brew doctor
Warning: You have unlinked kegs in your Cellar
Leaving kegs unlinked can lead to build-trouble and cause brews that depend on
those kegs to fail to run properly once built. Run `brew link` on these:
    cloog
    isl
Warning: A newer Command Line Tools release is available
Update them from Software Update in the App Store.
^C
hujiawei-MacBook-Pro:~ hujiawei$ brew link cloog
Linking /usr/local/Cellar/cloog/0.18.1... 8 symlinks created
hujiawei-MacBook-Pro:~ hujiawei$ brew link isl
Linking /usr/local/Cellar/isl/0.12.1... 6 symlinks created
```

**更新内容 2016-5-10**

1.之前将Ruby版本设置为1.9，现在需要使用2.0以上版本的Ruby，所有又将Ruby版本改了回来，正好现在博客不再使用Octopress，改为Hexo了。
