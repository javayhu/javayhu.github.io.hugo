---
title: "Android Development Code Snippets"
date: "2015-05-31"
tags: ["android"]
---
Android开发代码片段 <!--more-->

1.获取应用的版本信息

通过`PackageInfo`类来得到版本信息

```
PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
String versionName = pInfo.versionName;
int versionCode = pInfo.versionCode;
```

2.进入应用市场给应用评分

构造应用程序在应用市场中对应的网址，打开即可

```
Uri uri = Uri.parse("market://details?id=" + getPackageName());
Intent intent = new Intent(Intent.ACTION_VIEW, uri);
intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
startActivity(intent);
```

3.安装/卸载应用

打开查看某个APK文件就是安装应用操作

```
File apkfile = "/path/to/your/apk/file";
if (!apkfile.exists()) {
    return;
}

Intent intent = new Intent(Intent.ACTION_VIEW);
intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
intent.setDataAndType(Uri.parse("file://" + apkfile.toString()), "application/vnd.android.package-archive");
startActivity(intent);
```

卸载应用

```
private void uninstall(String packageName) {
    Uri uri = Uri.parse("package:" + packageName);
    Intent intent = new Intent(Intent.ACTION_UNINSTALL_PACKAGE, uri);
    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    startActivity(intent);
}
```

4.在屏幕的中间显示Toast信息

设置`setGravity`即可

```
private static void showMiddleToast(Context context, String msg) {
    Toast toast = Toast.makeText(context, msg, Toast.LENGTH_SHORT);
    toast.setGravity(Gravity.CENTER, 0, 0);
    toast.show();
}
```

5.复制文本到剪贴板

使用`ClipboardManager`类

```
public static void copy(Context context, String content) {
    ClipboardManager clipboardManager = (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
    clipboardManager.setText(content);
}
```

6.用户按两次返回键退出应用

记录上一次按返回键的时间`exitTime`，并给定一个时间范围(2 秒钟)

```
public void onBackPressed() {
    exitApp();
}

private long exitTime = 0;

private void exitApp() {
    if ((System.currentTimeMillis() - exitTime) > 2000) {
        showButtomToast("再按一次退出");
        exitTime = System.currentTimeMillis();
    } else {
        finish();
    }
}
```

7.创建桌面快捷方式

创建桌面快捷方式实际上就是构造一个Intent然后将其广播出去

```
@Click
void shortcut() {
    new AsyncTask<String, Void, Boolean>() {
        @Override
        protected void onPreExecute() {
            Toast.makeText(ShortcutActivity.this, "正在创建快捷方式...", Toast.LENGTH_SHORT).show();
            super.onPreExecute();
        }

        @Override
        protected Boolean doInBackground(String... params) {
            try {
                Intent shortcutIntent = new Intent("com.android.launcher.action.INSTALL_SHORTCUT");
                shortcutIntent.putExtra("duplicate", false);//不重复创建
                shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_NAME, params[0]);

                Parcelable icon = Intent.ShortcutIconResource.fromContext(ShortcutActivity.this, R.drawable.polaris);
                shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, icon);

                Intent intent = new Intent(Intent.ACTION_MAIN);
                //指定class的名称是为了在卸载应用程序时，同时删除桌面快捷键的图标
                ComponentName componentName = new ComponentName(ShortcutActivity.this, ShortcutActivity.class);
                intent.setComponent(componentName);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                intent.addCategory(Intent.CATEGORY_BROWSABLE);
                intent.addCategory(Intent.CATEGORY_DEFAULT);

                shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, intent);
                ShortcutActivity.this.sendBroadcast(shortcutIntent);
                return true;
            } catch (Exception e) {
                e.printStackTrace();
                return false;
            }
        }

        @Override
        protected void onPostExecute(Boolean result) {
            if (null != result && result) {
                Toast.makeText(ShortcutActivity.this, "创建快捷方式成功", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(ShortcutActivity.this, "创建快捷方式失败", Toast.LENGTH_SHORT).show();
            }
            super.onPostExecute(result);
        }
    }.execute("Polaris");
}
```
