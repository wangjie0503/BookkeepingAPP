# AGENTS.md

## 1. 项目目标

开发一个**个人自用、离线优先的生活费支出去向分析 App**。核心问题只有一个：

> 我这一期生活费花了多少钱，主要花到哪里了？

第一版只记录**支出**，不做收入、账户、转账、资产、负债、信用卡、退款、多人协作、登录、后端服务器或云同步。

目标平台：
- **Windows Desktop：MVP 必须可运行，作为开发和快速功能验收平台，也可直接日常使用**
- **Android：MVP 必须可构建并安装使用**
- **iOS：保持 Flutter 代码和依赖兼容，不要求在当前开发阶段完成 iOS 真机构建**

重要：MVP 不做多端同步。Windows、Android、iOS 各自使用本机 SQLite 数据；不要因为增加 Windows 支持而擅自实现账号、服务器或同步功能。

## 2. 开发前必读

开始编码前，必须按顺序阅读：

1. `README.md`
2. `docs/00-decision-summary.md`
3. `docs/01-product-requirements.md`
4. `docs/02-mvp-scope.md`
5. `docs/03-business-rules.md`
6. `docs/04-architecture.md`
7. `docs/05-data-model.md`
8. `docs/06-ui-spec.md`
9. `docs/07-testing-plan.md`
10. `docs/08-agent-workflow.md`
11. `docs/09-deferred-features.md`
12. `docs/10-desktop-validation.md`
13. `docs/assets/ui-reference.png`

如果代码实现与文档冲突，以 `03-business-rules.md` 和 `02-mvp-scope.md` 为最高优先级；不要擅自扩大范围。

## 3. 技术原则

- Flutter + Dart。
- 本地 SQLite，使用 Drift 作为数据库访问层。
- 使用 Riverpod 做状态管理和依赖注入。
- 使用 `fl_chart` 绘制统计图。
- Material 3，界面简洁，同时支持移动端和桌面端自适应。
- Windows 与 Android 必须复用同一套 domain/repository/database 业务逻辑，不允许复制两套实现。
- 平台差异应限制在 UI 自适应、文件导出和必要的平台适配层。
- 不引入后端，不依赖网络才能完成核心记账功能。
- 金额禁止使用浮点数持久化，统一使用“角”为整数单位保存。
- 数据库变更必须使用 migration，禁止破坏已有数据。
- 业务规则放在 service/repository 层，不要只靠 UI 校验。

## 4. 代码组织原则

采用**适度分层 + 按功能组织**，不要为了“架构完整”引入过多样板代码，也不要把所有逻辑堆进页面。

推荐结构见 `docs/04-architecture.md`。

必须保证：
- UI 不直接写 SQL。
- 统计计算可单元测试。
- 周期计算可单元测试。
- 分类停用、改名、移动等规则集中管理。
- 页面只负责展示和交互，不承担复杂业务计算。

## 5. 工作方式

### 编码前

先输出一份简洁实施计划，至少包含：
- 本阶段目标
- 涉及文件
- 数据结构变化
- 测试方案
- 风险点

未经计划不要直接大规模生成代码。

### 分阶段开发

按以下里程碑推进：

1. Flutter 工程骨架 + 数据库
2. 分类管理
3. 记一笔
4. 支出列表 + 编辑/删除
5. 生活费周期 + 预算
6. 概述统计 + 图表
7. CSV 导出
8. 全量回归测试 + Windows 运行/构建 + Android 构建

每个里程碑完成后：
- 运行格式化
- 运行静态检查
- 运行相关测试
- 由 Review Agent 检查 diff
- 修复问题后再进入下一里程碑

## 6. 禁止事项

未经用户明确批准，不要实现：
- 收入
- 多账户
- 转账
- 退款
- 云备份
- 备份恢复
- 登录注册
- 后端服务器
- 多币种
- 系统通知
- 分类拖拽排序
- AI 分析
- OCR/小票识别
- 商家、地点、备注、图片
- CSV 导入

## 7. 完成标准

不要只以“能运行”为完成标准。每项功能必须同时满足：
- 业务规则正确
- UI 可操作
- 数据落库正确
- 重启 App 后数据仍然存在
- 相关测试通过
- 不破坏其他已完成功能

最终至少提供：
- 可运行源码
- Windows 本地运行说明
- Windows 构建验证结果
- Android 构建说明
- APK 构建验证结果
- 测试结果摘要
- 已知限制列表

开发过程中优先使用 Windows Desktop 快速验收：每个 UI/业务里程碑完成后应先执行 `flutter run -d windows` 做手工 smoke test，再进行自动化测试和 Android 构建检查。详细流程见 `docs/10-desktop-validation.md`。
