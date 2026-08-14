# 给 Codex 的启动提示词

请把这个项目当成一个真实的小型产品来开发，而不是一次性 Demo。

第一步不要写代码。请先完整阅读：

- `AGENTS.md`
- `README.md`
- `docs/00-decision-summary.md`
- `docs/01-product-requirements.md`
- `docs/02-mvp-scope.md`
- `docs/03-business-rules.md`
- `docs/04-architecture.md`
- `docs/05-data-model.md`
- `docs/06-ui-spec.md`
- `docs/07-testing-plan.md`
- `docs/08-agent-workflow.md`
- `docs/09-deferred-features.md`
- `docs/10-desktop-validation.md`
- `docs/assets/ui-reference.png`

然后：

1. 检查需求是否存在内部冲突；只报告真正阻塞开发的问题，不要重新发明需求。
2. 输出项目实施计划和目录树。
3. 明确准备使用的 Flutter 包以及用途，但不要为了“架构完整”引入多余依赖。
4. 按里程碑开发，每次只推进一个阶段。
5. 每个阶段由实现 Agent 完成后，让 Review/Test Agent 检查 diff、业务规则和测试结果。
6. 发现问题先修复再进入下一阶段。
7. 不得擅自实现 `docs/09-deferred-features.md` 中的功能。
8. 金额、分类历史归属、软停用、生活费周期这些规则必须严格按照文档实现。
9. Windows Desktop 和 Android 都是 MVP target：开发过程中优先在 Windows 上快速运行验收，最终同时完成 Windows release build 与 Android build；Flutter 代码保持 iOS 兼容。
10. Windows 与手机在 MVP 中各自保存本地 SQLite 数据，不要擅自增加跨设备同步、账号或服务器。
11. 响应式 UI 必须复用同一套 feature/business logic，不要做两套独立应用。

先给我实施计划，不要直接开始大规模编码。
