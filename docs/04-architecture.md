# 04 技术架构

## 1. 总体方案

```text
                 ┌─ Windows Desktop UI
Flutter UI ──────┤
                 └─ Android / iOS Mobile UI
                         ↓
              Riverpod State / Controller
                         ↓
              Repository / Domain Service
                         ↓
                     Drift DAO
                         ↓
                       SQLite
```

这是一个本地单机 App，不需要后端。Windows 与移动端必须共享同一套 domain、repository、DAO 和统计逻辑，仅在布局、文件导出等确有平台差异的地方做适配。

MVP 没有账号和同步服务，因此每台设备都有自己的本地数据库：

```text
Windows App → Windows 本机 SQLite
Android App → Android 本机 SQLite
iOS App     → iOS 本机 SQLite
```

电脑端的核心价值之一是开发阶段可以快速启动并验证功能，不需要每改一次 UI 都先等待手机安装。

## 2. 推荐依赖

只使用当前 Flutter stable 兼容版本，不在文档中写死版本号。

- `flutter_riverpod`：状态管理、依赖注入
- `drift` + SQLite 运行依赖：数据库和 migration
- `fl_chart`：环形图、趋势图
- `intl`：日期格式化
- `csv`：CSV 生成
- `path_provider`：导出文件路径
- `share_plus`：把 CSV 分享/保存到用户选择的位置

除非实现确实需要，不要额外引入大型框架。

## 3. 推荐目录

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── theme.dart
│   └── navigation.dart
├── data/
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   ├── daos/
│   │   └── migrations/
│   └── repositories/
├── domain/
│   ├── models/
│   └── services/
│       ├── period_service.dart
│       ├── category_service.dart
│       └── statistics_service.dart
├── features/
│   ├── expense_entry/
│   ├── expense_list/
│   ├── category_management/
│   ├── overview/
│   └── settings/
└── shared/
    ├── money.dart
    ├── date_utils.dart
    └── widgets/
```

## 4. 页面导航与响应式布局

四个主入口在所有平台保持一致：

- 记一笔
- 支出列表
- 分类管理
- 概述统计

移动端优先使用底部导航栏。

Windows Desktop 使用适合宽屏的导航方式，优先参考用户提供的桌面截图：顶部导航或 NavigationRail/侧边导航均可，但不要另造一套页面和业务逻辑。窗口缩窄时应自然退化为更紧凑的布局。

设置页不是第五个主 Tab，可通过 AppBar/标题栏区域的设置入口进入。

设置页负责：
- 默认月预算
- 当前生活费周期起始日/初始化设置
- CSV 导出

## 5. 状态刷新

所有读写都通过 Repository/Provider 暴露。

写操作成功后必须使相关 provider 失效或更新，保证：
- 新记一笔后列表立即出现
- 分类变化后记一笔立即更新
- 支出变化后统计立即更新
- 预算变化后概述页立即更新

## 6. 数据库策略

- 使用 schema version。
- 所有后续字段/表变化必须写 migration。
- 不允许“开发时方便”直接删除用户数据库。
- 统计应尽量通过明确查询或可测试的 service 完成。

## 7. 金额设计

不使用 `double` 作为数据库金额真值。

使用：

```text
amountJiao: int
```

显示层统一通过 money formatter 转成字符串。

## 8. 时间设计

- 使用设备本地时间。
- 数据库保存明确可排序的时间值。
- 周期边界统一由 `PeriodService` 生成。
- 页面不要自行拼日期范围。

## 9. 桌面端约束

- Windows Desktop 是正式 MVP target，不是临时 mock。
- 同一个 Flutter feature/widget 尽量通过 `LayoutBuilder`、`MediaQuery` 或可复用 adaptive widget 适配宽度，不复制 `mobile_xxx_page.dart` / `windows_xxx_page.dart` 两套完整业务页面。
- 数据库打开方式必须选择同时支持 Windows 与 Android/iOS 的 Drift 方案。
- CSV 导出能力必须在 Windows 和 Android 至少都能正常工作；平台文件选择/分享逻辑可封装在 adapter/service 中。
- 不以 Flutter Web 作为主要验收环境，因为本项目的主要持久化目标是原生 SQLite 桌面/移动应用。Web 可后续单独评估。

## 10. 架构刻意不做的事情

MVP 不使用：
- Clean Architecture 的完整多层模板
- 微服务
- 后端 API
- 网络缓存
- 事件总线
- Redux/BLoC 多套状态方案并存

目标是清楚、可测、可维护，而不是文件数量多。
