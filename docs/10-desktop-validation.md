# 10 Windows Desktop 快速验证与验收流程

## 1. 为什么把 Windows 纳入 MVP

本项目既要最终在手机上使用，也需要在开发阶段快速验证功能。

因此 Windows Desktop 不是临时调试页面，而是正式 MVP target：

- 大部分开发与 UI 调整先在电脑上直接运行验证
- Windows 与 Android 复用同一套 Flutter 业务代码
- Windows 版本本身也应可以正常独立记账
- 最终再用 Android 真机/模拟器检查移动端交互和安装包

MVP 不做同步，因此 Windows 和 Android 各有自己的本地 SQLite 数据库。不要为了让两端数据一致而擅自增加服务器。

## 2. 开发环境验收

Codex 开始实现前先检查：

```bash
flutter doctor
flutter devices
```

预期至少能看到 Windows target。

如果 Flutter 工程尚未包含 Windows target，应使用 Flutter 官方方式补齐 Windows 平台工程文件，不得另外新建一个桌面项目。

## 3. 日常最快验证方式

每完成一个小功能，优先：

```bash
flutter run -d windows
```

使用正在运行的 Windows App 手工验证，再结合 Flutter hot reload / hot restart 快速迭代 UI。

推荐开发节奏：

```text
Implement Agent 修改代码
        ↓
flutter analyze / 相关 test
        ↓
flutter run -d windows
        ↓
手工点一遍本阶段核心链路
        ↓
Review/Test Agent 检查 diff
        ↓
通过后再进入下一里程碑
```

## 4. Windows 每阶段 smoke test

### M1 工程/数据库
- Windows App 能启动
- 首次启动自动创建数据库
- 默认分类正确写入
- 关闭再打开后数据仍存在

### M2 分类管理
- 新增一级/二级分类
- 全局重名被拒绝
- 停用/恢复立即生效
- 移动二级分类正常

### M3 记一笔
- 金额整数/一位小数均可
- 两位小数被拒绝
- 默认当前时间
- 选择分类后成功保存

### M4 支出列表
- 新支出立即出现
- 时间倒序正确
- 修改后刷新
- 删除有二次确认

### M5 周期/预算
- 25 日周期边界正确
- 默认预算生成周期预算
- 修改本期预算不影响历史

### M6 统计
- 总支出正确
- 环形图金额与列表一致
- 二级分类汇总正确
- 每日趋势金额正确
- 自定义范围不显示预算

### M7 CSV
- Windows 能生成 CSV
- 文件可以在电脑上正常打开
- 中文、日期、金额列内容正确

## 5. 响应式 UI 检查

Windows 手工验收至少检查 3 类窗口宽度：

1. 较窄窗口：确认不 overflow，页面仍可操作
2. 普通桌面窗口：作为主要桌面体验
3. 最大化窗口：确认内容没有被不合理拉伸

要求：
- 业务组件复用，不为桌面复制一套页面
- 表单设置合理最大宽度
- 统计区可以在宽屏下合理并排
- 窄窗口自动回落为纵向布局

## 6. Android 仍然必须单独验收

Windows 验收不能替代 Android 验收。Windows 主要提高开发速度，Android 仍要检查：

- 底部导航/移动端布局
- 数字键盘与金额输入
- 日期时间选择器
- 返回手势/返回按钮
- CSV 导出/分享
- SQLite 持久化
- APK 构建和安装

## 7. 最终完成门槛

Codex 不得只因为 Windows 运行正常就宣布完成。最终至少完成：

```bash
flutter analyze
flutter test
flutter build windows
flutter build apk
```

并分别完成 Windows 全功能手工回归和 Android 核心链路回归。

## 8. 平台独立数据的说明

MVP 中：

```text
Windows 数据 ≠ Android 数据
```

两端数据库结构和业务规则相同，但文件位于各自设备。

CSV 当前只用于导出查看，不作为同步或恢复手段。未来如果需要“电脑记一笔，手机立即看到”，那将是独立的 V2 同步需求，需要重新设计数据同步方案。
