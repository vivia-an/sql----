---
name: single-sql-metric-probe
description: >-
  Generates one Presto SQL with UNION ALL ladder to probe hospital metric
  denominators/numerators (volume mismatch, filter impact, caliber selection).
  Use when the user mentions 探测, 排查, 分母虚高/虚低, 数据量对不上, 口径选择,
  全放开, 量探测, or asks which filter condition fits a target count.
---

# 单条 SQL 指标量探测（UNION ALL 阶梯）

## 何时触发

- 指标结果与业务预期数量不符（如「少了」「25万对不上」）
- 需要对比多种过滤口径，选国考/业务分母
- 用户要求「一个 SQL 搞定」「不要多个 SQL」
- 修改主指标 SQL 之前，先定位哪一层过滤丢/多了数据

## 执行前

1. 读 `sql----/.trace` 找主指标 SQL 与血缘
2. 读主指标 SQL，提取：主表、主键、时间字段、院区、JOIN、分子/分母条件
3. 确认时间窗口（两区间 / 自然年 / 用户指定）

## 输出物

**只生成一个可执行 SQL 文件**，命名：

`{目录}/{指标名}_量探测.sql` 或 `{指标名}_分母排查.sql`

禁止拆成多个独立 `SELECT`（DBeaver 一次执行出全表）。

## 标准结果列

| 列 | 含义 |
|----|------|
| 时间窗口 | 如 `A_2025-07~2026-06`、`B_2025自然年` |
| 口径 | 编号+简述，如 `06_主SQL分母(起止合法+住院)` |
| 数据源 | 主表或对照表名 |
| 行数 | `count(*)` |
| distinct_计数 | `count(distinct 主键)` |

外层统一：

```sql
SELECT "时间窗口", "口径", "数据源", "行数", "distinct_计数"
FROM ( ... UNION ALL ... ) t
ORDER BY "时间窗口", "口径";
```

## 口径阶梯（按序 UNION ALL）

从松到紧，编号两位前缀保证排序：

| 编号段 | 口径 | 目的 |
|--------|------|------|
| 01 | 全表无过滤（同主表） | 数仓总量上限 |
| 02 | 仅时间落窗（主时间字段） | 窗口内全量 |
| 03 | 换备用时间字段落窗 | 时间字段选错排查 |
| 04 | +MedOrgCode | 院区影响 |
| 05 | +IsDeleted=0 | 删除标记影响 |
| 06 | **主指标分母完整条件** | 与主 SQL 对齐的基准 |
| 07~08 | 全放开对照（无院区/住院） | 业务「全量」参照 |
| 09~11 | 自然年或其他窗口 | 用户口头预期年 |
| 12~13 | 关联表同窗口（Apply_OPS/MR_FPOPS 等） | 跨表口径对比 |

每档只比上一档**多一个**关键条件，便于看「哪一步掉量最大」。

## Presto 约定

- 库表：`datacenter_db."TableName"`，字段双引号
- 删除：`coalesce(cast(x AS varchar), '0') = '0'`
- 时间 VARCHAR：半开区间 `>= 起点 AND < 终点`
- 主键去重：`count(DISTINCT "主键字段")`
- 中文列名加双引号

## 跑完后的分析模板

回复用户时包含：

1. **阶梯表**：各口径 distinct_计数，标出与预期的差距
2. **掉量最大的一步**：哪条过滤剔最多
3. **推荐口径**：国考用 06；业务对账用哪一档
4. **是否改主 SQL**：仅在有明确确认后改

## 参考实现

本仓库范例：

- `sql----/HIS/麻醉医师手术时间重合率_一年全放开量探测.sql`
- 模板见 [template.sql](template.sql)

## 与 .trace 联动

探测完成后在 `sql----/.trace` 追加一行：

```
- **探测**：`路径/xxx_量探测.sql` — 结论一句话（如窗口A主口径167045）
```
