# 08 Codex 多 Agent 工作流

目标：让 Agent 分工，但避免多人同时改同一批文件造成混乱。

## 1. 推荐角色

### Lead Agent
负责：
- 读需求
- 划分里程碑
- 指定每阶段修改范围
- 汇总 Review 结果
- 决定是否进入下一阶段

Lead 不应该一次性让多个 Agent 同时改核心数据库文件。

### Implement Agent
负责当前里程碑的实现。

要求：
- 只改本阶段相关文件
- 同步补测试
- 完成后给出改动摘要和测试结果

### Review/Test Agent
在实现 Agent 完成后介入。

负责：
- 阅读需求文档和 diff
- 检查业务规则是否实现正确
- 运行测试
- 专门找边界条件和回归问题
- 不为了“代码更像自己的风格”大面积重写

### Fix Agent
根据 Review 清单修复问题。

小项目里可以由原 Implement Agent 承担 Fix 角色。

## 2. 最佳节奏

```text
Lead 定义里程碑
      ↓
Implement 开发 + 测试
      ↓
Review/Test 独立检查
      ↓
发现问题？
  ├─ 是 → Fix → 再 Review
  └─ 否 → 进入下一里程碑
```

不要使用：

```text
Agent A 改数据库
Agent B 同时改数据库
Agent C 同时改同一页面
```

## 3. 里程碑建议

### M1 工程骨架与数据库
- Flutter 工程，同时启用 Windows + Android target
- Windows 可以 `flutter run -d windows` 启动
- Drift
- 表结构
- migration
- 默认分类 seed
- repository 基础

### M2 分类管理
- 新增
- 改名
- 停用/恢复
- 移动二级分类
- 唯一性

### M3 记一笔
- 4 字段
- 金额规则
- 默认时间
- 保存

### M4 支出列表
- 周期/日期范围查询
- 编辑
- 删除

### M5 预算与周期
- 默认预算
- 周期生成
- 周期预算修改
- 周期选择

### M6 统计
- 总支出
- 环形图
- 二级分类展开
- 每日趋势

### M7 CSV
- 选择范围
- 生成 CSV
- 分享/保存

### M8 最终验收
- 全量测试
- analyze
- Windows Desktop 全功能手工回归
- Windows release build
- Android build
- Android 真机/模拟器核心链路回归

## 4. 每阶段交付模板

Implement Agent 完成后必须报告：

```text
本阶段完成：
- ...

修改文件：
- ...

新增/修改测试：
- ...

已运行：
- flutter analyze
- flutter test ...

结果：
- ...

已知风险：
- ...
```

Review Agent 必须报告：

```text
阻塞问题：
- ...

非阻塞建议：
- ...

业务规则核对：
- 通过 / 不通过

测试结果：
- ...
```
