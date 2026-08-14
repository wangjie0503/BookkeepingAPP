# 05 数据模型

以下为逻辑模型，Codex 可根据 Drift 语法落地，但不得改变业务语义。

## 1. categories

建议一级/二级分类共用一张表。

| 字段 | 类型 | 说明 |
|---|---|---|
| id | INTEGER PK | 分类 ID |
| name | TEXT UNIQUE | 全局唯一名称 |
| parent_id | INTEGER NULL | NULL=一级分类；非空=二级分类父级 |
| is_active | BOOLEAN | 是否启用 |
| sort_order | INTEGER | 固定排序 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 修改时间 |

规则：
- 一级分类 `parent_id = NULL`
- 二级分类必须有父级
- 不支持第三级
- 停用不删除记录
- `name` 全局唯一，包括停用分类

## 2. expenses

| 字段 | 类型 | 说明 |
|---|---|---|
| id | INTEGER PK | 支出 ID |
| amount_jiao | INTEGER | 金额，单位角，必须 > 0 |
| secondary_category_id | INTEGER FK | 二级分类 ID |
| spent_at | DATETIME | 消费时间 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 修改时间 |

刻意**不保存 primary_category_id**。

原因：一级分类通过二级分类当前父级推导，从而满足“二级分类移动后历史统计跟随新父级”的需求。

## 3. budget_periods

| 字段 | 类型 | 说明 |
|---|---|---|
| id | INTEGER PK | 周期 ID |
| label_year | INTEGER | 周期命名年份 |
| label_month | INTEGER | 周期命名月份 |
| start_at | DATETIME | 周期开始 |
| end_at | DATETIME | 周期结束 |
| budget_jiao | INTEGER | 该周期预算快照 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 修改时间 |

建议：
- `(label_year, label_month)` 唯一
- `start_at < end_at`
- 历史周期不依据当前设置动态重算

## 4. app_settings

可以使用单例表或 key-value 表。MVP 需要至少保存：

| 配置 | 说明 |
|---|---|
| default_budget_jiao | 默认月预算 |
| funding_day | 当前生活费周期起始日，当前值 25 |

如果使用 key-value，必须在 Repository 中做类型封装，不允许 UI 到处手工解析字符串。

## 5. 默认分类初始化

初始化时建议写入以下默认分类；用户以后可以全部改名、移动、停用。

```text
餐饮
├── 早餐
├── 午餐
├── 晚餐
├── 饮品
├── 水果
└── 零食

交通
├── 公交
├── 地铁
├── 打车
└── 骑行

生活
├── 日用品
├── 洗护
├── 衣物
└── 医疗

学习
├── 书籍
├── 学习用品
└── 软件服务

娱乐
├── 游戏
├── 影音
└── 聚会

数码
├── 数码产品
└── 配件

其他支出
└── 杂项
```

注意：由于名称全局唯一，初始化数据中不得出现任何重复名称。

## 6. 关键查询

至少需要清晰封装：

- 当前可用一级分类
- 指定一级分类下当前可用二级分类
- 指定时间范围支出列表
- 指定时间范围总支出
- 指定时间范围一级分类聚合
- 指定时间范围二级分类聚合
- 指定时间范围每日聚合
- 查找某日期属于哪个生活费周期
- 创建尚不存在的当前周期

## 7. 索引建议

至少考虑：
- `expenses.spent_at`
- `expenses.secondary_category_id`
- `categories.parent_id`
- `budget_periods.start_at/end_at`

数据量不大，但这些索引能让查询语义更明确。
