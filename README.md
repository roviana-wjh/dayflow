# DayFlow MVP

个人学习与心情记录 App 的最小可用版本。

## Flutter 客户端

运行 `flutter pub get` 后执行 `flutter run`。

在当前电脑上预览浏览器版本：

```powershell
& 'C:\Users\lenovo\flutter-sdk\bin\flutter.bat' run -d chrome --web-port 7357
```

浏览器版本使用 SQLite Web，数据保存在当前浏览器的 IndexedDB 中。
请固定使用 `http://localhost:7357` 和同一浏览器，清除站点数据会删除本地记录。
`web/sqlite3.wasm` 和 `web/sqflite_sw.js` 是必需的数据库运行文件；
更新 SQLite 依赖后可用 `dart run sqflite_common_ffi_web:setup --force` 重新生成。

客户端使用 SQLite 本地保存学习和心情记录，核心功能不依赖网络。

## Go/Gin 后端

进入 `backend` 目录后执行 `go mod download` 和 `go run .`。

服务默认监听 `http://localhost:8080`，提供健康检查、学习记录和心情记录 API。

## 安卓个人安装

正式包名：`dev.dayflow.personal`；版本：`0.3.0+3`；最低 Android 7.0。
正式签名配置、构建脚本和真机验收步骤见 [安卓安装与更新](docs/android-release.md)。
使用 `scripts/build-android.ps1` 检查、测试并构建 APK。

## 当前包含

- 首页概览
- 学习与心情记录新增、编辑、删除确认及补记日期
- 按真实记录计算今日学习、今日心情与本周趋势（周一至周日）
- 连续记录：学习或心情任一有效记录计为一天；今天未记时延续截至昨天的连续天数
- 学习主题必填、时长限制为 1–1440 整数分钟
- 按记录日期排序的混合最近记录、分日期的学习及心情历史
- 全局搜索学习与心情记录，可按关键词、类型、近 7/30 天或自定义日期范围筛选
- 五套浅色主题，可从顶部颜色按钮切换，并保存在本机
- 简约浅色界面、可滚动表单及中文日期选择
- 本地 SQLite 持久化
- Go/Gin 基础 API
- 学习、心情、我的四项底部导航

客户端直接使用本地数据库，当前未接入 Go API。每日学习目标暂定 60 分钟。
备份、设备同步及学习计时尚未提供。

## 验证

`flutter analyze` 检查代码；`flutter test` 验证统计、记录筛选、主题切换、表单校验、编辑删除与小屏键盘布局。
