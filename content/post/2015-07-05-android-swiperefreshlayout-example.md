---
title: "Head First Android SwipeRefreshLayout"
date: "2015-07-05"
tags: ["android"]
---
本文内容和代码参考自[Implementing Swipe to Refresh, an Android Material Design UI Pattern](https://www.bignerdranch.com/blog/implementing-swipe-to-refresh/)，原博客内容中略有错误。 <!--more-->

[SwipeRefreshLayout](https://developer.android.com/reference/android/support/v4/widget/SwipeRefreshLayout.html)组件是Support Library中的，用途是使用户在某个组件中下拉即可刷新页面中的内容。

This layout should be made the parent of the view that will be refreshed as a result of the gesture and can only support one direct child. This view will also be made the target of the gesture and will be forced to match both the width and the height supplied in this layout. The SwipeRefreshLayout does not provide accessibility events; instead, a menu item must be provided to allow refresh of the content wherever this gesture is used.

SwipeRefreshLayout只能有一个直接子组件，子组件也将作为手势识别的目标区域。SwipeRefreshLayout的显示效果如下，在组件上显示一个进度圈表示正在刷新。

![image](/images/swiperefreshlayout.png)

下面我们来做个案例使用SwipeRefreshLayout。

(1)新建布局文件，在SwipeRefreshLayout中插入一个RecyclerView。

```
<RelativeLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context="hujiawei.xiaojian.ui.SwipeRefreshLayoutActivity">


    <android.support.v4.widget.SwipeRefreshLayout
        android:id="@+id/mSwipeRefreshLayout"
        android:layout_width="match_parent"
        android:layout_height="wrap_content">

        <android.support.v7.widget.RecyclerView
            android:id="@+id/mRecyclerView"
            android:layout_width="match_parent"
            android:layout_height="match_parent" />

    </android.support.v4.widget.SwipeRefreshLayout>


</RelativeLayout>
```

(2)在`res/values/strings.xml`中添加一个字符串数组，内容是一些猫的种类的名称。

```
<!--swipe refresh layout-->
<string-array name="cat_names">
    <item>George</item>
    <item>Zubin</item>
    <item>Carlos</item>
    <item>Frank</item>
    <item>Charles</item>
    <item>Simon</item>
    <item>Fezra</item>
    <item>Henry</item>
    <item>Schuster</item>
</string-array>
```

(3)创建RecyclerView的Adapter类`CatNamesRecyclerViewAdapter`，其中方法`refreshContent`是用来混淆mCatNames的，当做是内容刷新之后的结果。

```
import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import hujiawei.xiaojian.R;

public class CatNamesRecyclerViewAdapter extends RecyclerView.Adapter<CatNamesRecyclerViewAdapter.CatNamesViewHolder> {

    private Context mContext;
    List<String> mCatNames;

    public CatNamesRecyclerViewAdapter(Context context) {
        mContext = context;
        randomizeCatNames();
    }

    public void randomizeCatNames() {
        mCatNames = Arrays.asList(getCatNamesResource());
        Collections.shuffle(mCatNames);
    }

    private String[] getCatNamesResource() {
        return mContext.getResources().getStringArray(R.array.cat_names);
    }

    public class CatNamesViewHolder extends RecyclerView.ViewHolder {
        TextView mCatNameTextView;

        public CatNamesViewHolder(View itemView) {
            super(itemView);
            mCatNameTextView = (TextView) itemView.findViewById(R.id.cat_name_textview);
        }
    }

    public void refreshContent(){
        Collections.shuffle(mCatNames);
    }

    @Override
    public CatNamesViewHolder onCreateViewHolder(ViewGroup viewGroup, int i) {
        View inflatedView = LayoutInflater.from(mContext).inflate(R.layout.item_listview_catname, viewGroup, false);
        return new CatNamesViewHolder(inflatedView);
    }

    @Override
    public void onBindViewHolder(CatNamesViewHolder viewHolder, int i) {
        String catName = getItem(i);
        viewHolder.mCatNameTextView.setText(catName);
    }

    public String getItem(int position) {
        return mCatNames.get(position);
    }

    @Override
    public int getItemCount() {
        return mCatNames.size();
    }

}
```

(4)在Activity中添加主要的测试代码

实例的代码使用了Android Annotations，但是代码读起来应该是没有障碍的，如果不太了解AA的话，可以参考下[此文](/blog/2015/05/31/android-annotations/)。

```
import android.os.Handler;
import android.support.v4.widget.SwipeRefreshLayout;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;

import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.ViewById;

import hujiawei.xiaojian.R;
import hujiawei.xiaojian.adapter.CatNamesRecyclerViewAdapter;

@EActivity(resName = "activity_swipe_refresh_layout2")
public class SwipeRefreshLayoutActivity2 extends AppCompatActivity {

    @ViewById
    SwipeRefreshLayout mSwipeRefreshLayout;

    @ViewById
    RecyclerView mRecyclerView;

    CatNamesRecyclerViewAdapter mAdapter;

    @AfterViews
    void init() {
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        mRecyclerView.setLayoutManager(linearLayoutManager);

        mAdapter = new CatNamesRecyclerViewAdapter(this);
        mRecyclerView.setAdapter(mAdapter);

        mSwipeRefreshLayout.setColorSchemeResources(R.color.orange, R.color.green, R.color.blue);
        mSwipeRefreshLayout.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                refreshContent();
            }
        });
    }

    private void refreshContent() {
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                mAdapter.refreshContent();
                mAdapter.notifyDataSetChanged();
                mSwipeRefreshLayout.setRefreshing(false);
            }
        }, 5000);
    }

}
```

其中方法`setColorSchemeResources`是用来改变进度圈的颜色的，`setOnRefreshListener`是用来添加我们下拉刷新的具体操作的监听器的，这里是虚拟地去加载了新数据。

OK，Enjoy! :-)
