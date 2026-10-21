# 安卓个人安装与更新

应用包名固定为 `dev.dayflow.personal`，支持 Android 7.0（API 24）及以上。
客户端 SQLite 保存在应用私有目录，使用记录功能无需联网或启动 Go 服务。

## 当前电脑工具路径

- Flutter：`C:\Users\lenovo\flutter-sdk`
- Java：`C:\Users\lenovo\java\jdk-21.0.12.1+1`
- Android SDK：`C:\Users\lenovo\AppData\Local\Android\Sdk`

## 正式签名

个人签名密钥及密码配置保存在 `C:\Users\lenovo\.dayflow\signing`。
项目的 `android/key.properties` 是本地签名配置，已被 Git 忽略。
请将整个签名目录备份到安全位置：丢失原密钥后，无法为已安装的应用生成同签名更新。
签名文件和密码不要提交到代码仓库，也不要和 APK 一起分享。

## 构建

在项目根目录运行：

```powershell
.\scripts\build-android.ps1 -BuildNumber 3
```

后续更新递增 BuildNumber，始终保留原包名和原密钥。
产物为 `build/app/outputs/flutter-apk/app-release.apk`。

## 安装

把 APK 传到安卓手机并打开，允许文件管理器安装该应用即可。
也可以连接 USB、开启开发者选项和 USB 调试，在手机确认电脑的调试授权后运行：

```powershell
& 'C:\Users\lenovo\AppData\Local\Android\Sdk\platform-tools\adb.exe' devices
& 'C:\Users\lenovo\AppData\Local\Android\Sdk\platform-tools\adb.exe' install -r .\build\app\outputs\flutter-apk\app-release.apk
```

更新应覆盖安装。不要通过卸载解决安装冲突，卸载或清除应用数据会删除本地记录。
电脑浏览器记录与手机数据库彼此独立；备份及迁移尚未实现。

## 真机验收

1. 断网启动，新增学习和心情记录，检查统计更新。
2. 小屏幕及大字体下打开表单，确认键盘弹出后仍可滚动、保存。
3. 保存过程中按钮不可重复点击，失败后保留输入并允许重试。
4. 从最近任务关闭应用再重开，检查记录保留。
5. 切到其他应用再返回，检查首页刷新。
6. 同签名覆盖安装新版，检查原记录保留。

数据库启动重试、保存失败恢复和防重复提交已经有自动化测试；
实际安装、原生 SQLite、系统键盘及覆盖安装的数据保留须以真机结果为准。

## 本次构建验证

2026-10-12 已生成正式签名 APK：版本 `0.2.0`，versionCode `2`，
包名 `dev.dayflow.personal`，最低 API `24`，目标 API `36`。
Android toolchain、静态检查与 11 项自动化测试通过。
APK SHA256：`3F3844C5D8856C62AC928A3F37E9282BECA58DB164626AD1504174C03DFFDAF4`。
当前未连接手机，真机步骤待验收。

2026-10-13 已生成更新包：版本 `0.3.0`，versionCode `3`，包名不变。
新增本地搜索、五套可保存的颜色主题，并通过 SQLite v1 到 v2 的设置表迁移保留已有记录。
静态检查、13 项自动化测试和正式签名验证通过；本次 APK 仍需按上面的真机步骤覆盖安装验收。
