---
title: "Matlab Image Segmentation"
date: "2014-03-30"
tags: ["dev"]
---
本文主要介绍Matlab实现的两种自动阈值图像分割方法<!--more-->

1.基于迭代的自动阈值图像分割方法

参考文献: [基于迭代(自动阈值)算法的医学图像增强方法](/files/image_segmentation.pdf)
该文献实现了全局和局部的图像分割代码，使用的都是迭代算法，对比下面的结果可以看出，在灰度差异特别大的图像中，局部阈值分割要比全局阈值分割表现更好。[注:我对源码略有修改]

1.1 全局阈值分割程序

```matlab
original_image=imread('test1.png');
gray_image=rgb2gray(original_image);
gray_image=double(gray_image);
t=mean(gray_image(:));
is_done=false;
count=0;%迭代次数
block=gray_image(1:end,1:end);%不分块
while ~is_done
    r1=find(gray_image<=t);
    r2=find(gray_image>t);
    temp1=mean(block(r1));
    if isnan(temp1);
        temp1=0;
    end
    temp2=mean(block(r2));
    if isnan(temp2)
        temp2=0;
    end
    t_new=(temp1+temp2)/2;
    is_done=abs(t_new-t)<1;%差异阈值是1
    t=t_new;
    count=count+1;
    if count>=1000
        Error='Error:Cannot find the ideal threshold.'
        return
    end
end
[m,n]=size(gray_image);
result=zeros(m,n)+255;
result(r1)=0;
% resule(r2)=255;
result=uint8(result);
figure
imshow(result);
```

1.2 局部阈值分割程序

```
original_image=imread('test1.png');
gray_image=rgb2gray(original_image);
gray_image=double(gray_image);
[m,n]=size(gray_image);
result=zeros(m,n);
block_size=70;%分块大小
for i=1:block_size:m
    for j=1:block_size:n
        if ((i+block_size)>m)&&((j+block_size)>n)
            block=gray_image(i:end,j:end);
        elseif ((i+block_size)>m)&&((j+block_size)<=n)
            block=gray_image(i:end,j:j+block_size-1);
        elseif ((i+block_size)<=m)&&((j+block_size)>n)
            block=gray_image(i:i+block_size-1,j:end);
        else
            block=gray_image(i:i+block_size-1,j:j+block_size-1);
        end
        t=mean(block(:)); t_org=t; is_done=false; count=0;
        while ~is_done
            r1=find(block<=t); r2=find(block>t); temp1=mean(block(r1));
            if isnan(temp1);
                temp1=0;
            end
            temp2=mean(block(r2));
            if isnan(temp2)
                temp2=0;
            end
            t_new=(temp1+temp2)/2; is_done=abs(t_new-t)<1; t=t_new;
            count=count+1;
            if count>=1000
                Error='Error:Cannot find the ideal threshold.'
                return
            end
        end
        block(r1)=0;
        block(r2)=255;
        if ((i+block_size)>m)&&((j+block_size)>n)
            result(i:end,j:end)=block;
        elseif ((i+block_size)>m)&&((j+block_size)<=n)
            result(i:end,j:j+block_size-1)=block;
        elseif ((i+block_size)<=m)&&((j+block_size)>n)
            result(i:i+block_size-1,j:end)=block;
        else
            result(i:i+block_size-1,j:j+block_size-1)=block;
        end
    end
end
resule=uint8(result);
figure
imshow(result);
```

对比结果：
{% img /images/whole.png 320 210 %} {% img /images/partial.png 320 210 %}

2.基于OSTU算法的自动阈值图像分割

[这块我还没有细究...To be continued......]
Matlab内置的`graythresh`使用的便是OSTU算法，使得白色像素和黑色像素的类间方差最大。
因为上面测试图像的亮度存在明显的水平差异，所以我写了一个将图像沿水平方向分成几部分分别进行OSTU算法，效果明显又比上面两种方式要好些。

{% img /images/postu.png %}

```
function [ result ] = partialostu( image,part,isrgb )
%PARTIALOSTU partial image ostu
if isrgb
    image=rgb2gray(image);
end
cols=size(image,2);
result=zeros(size(image));
for i=1:part
    fstart=floor((i-1)*cols/part)+1;
    fend=floor(i*cols/part);
    f=image(:,fstart:fend);
    t=graythresh(f);
    f=im2bw(f,t);
    result(:,fstart:fend)=f;
end
end
```
