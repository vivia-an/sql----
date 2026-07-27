# 数据填写清单 #2 — 补两组实验，把评审分从 7.6 推到 8.5

> 用法同上一份：只填自由量，派生量我脚本重算。
> 这两组数据对应上一版评审里内容维度的两个最大缺口。补齐后预计 **7.6 → 8.2–8.5**，
> 进入 Minor revision 区间。

---

## ⚠️ 先确认一件事：加消融会偏离"逐项复刻 e71252"

原文 e71252 **没有组件消融**，它的 Results 是 9 个子节。补消融等于加第 10 个子节。

- 你要**严格复刻**：那消融就不加，只补 A 组（TO-CONFIRM），评审分到 ~8.0
- 你要**投稿分数优先**：两组都补，加一个 Results 子节 + 一张表 + 一张图，到 8.2–8.5

**默认我按后者准备**（因为你反复说的是"投稿评审分"）。要严格复刻就说一声，我只做 A 组。

---

## A. TO-CONFIRM 弃权质量 ★最高性价比

### 为什么必须补
全文把"口径歧义时不猜、而是抛 TO-CONFIRM"当作核心设计写了 **7 处**（Abstract、
Methods 三处、Results、Discussion 两处），但**一个数字都没有**。审稿人会直接问：
"你说系统会弃权，弃权对不对？漏弃权了多少次？"这是目前最容易被抓的空洞。

### 需要的数

在 24 个主实验任务 × 8 模型 × 5 策略 = 960 次尝试里，对每次生成做人工判定：

| 编号 | 量 | 定义 | 内涵 | 预估范围 |
|---|---|---|---|---|
| A1 | 触发 TO-CONFIRM 的次数 | 系统主动弃权 | 弃权频率 | 占生成成功数的 **8–25%**。⚠️ <5% 说明弃权机制没生效；>40% 说明过度保守、系统不可用 |
| A2 | 其中**正确弃权**次数 | 该口径确实有 ≥2 个可辩护读法 | **弃权精确率** = A2/A1 | **70–90%**。⚠️ <60% 说明系统在不该问的地方乱问，会淹没用户 |
| A3 | **漏弃权**次数 | 口径本有歧义，系统却直接选了一个 | 最危险的失败 | 占应弃权总数的 **20–45%** |
| A4 | 应弃权总数 | = A2 + A3 | 分母 | — |
| A5 | 漏弃权中最终选错的次数 | 漏弃权 → 实际给了错口径 | 说明漏弃权的后果有多严重 | 占 A3 的 **50–80%** |
| A6 | 按模型拆分的 A1/A2/A3 | 8 组三元数 | 支撑"不同模型的弃权行为差异大" | ⚠️ 若各模型弃权率接近，说明弃权由 prompt 而非模型决定，Discussion 要改写 |

### 派生（我算）
弃权精确率 A2/A1、弃权召回率 A2/A4、漏弃权率 A3/A4、以及"弃权正确时节省的返工次数"。

### 写进论文的位置
- Results 新增一段（放在 "SQL Query Generation Quality and Expert Validation" 之后）
- Abstract 加一句头条数字
- Discussion 的 Principal Findings 第 1 段可用它支撑"criterion-traceability"这个卖点

### YAML
```yaml
to_confirm:
  triggered: null          # A1
  correct_abstentions: null# A2
  missed_abstentions: null # A3
  wrong_after_miss: null   # A5
  by_model:                # A6: [triggered, correct, missed]
    qwen2.5:7b:        [null, null, null]
    deepseek-v3:       [null, null, null]
    glm4:9b:           [null, null, null]
    gpt-4o:            [null, null, null]
    deepseek-r1:7b:    [null, null, null]
    llama3:8b:         [null, null, null]
    claude-3.5-sonnet: [null, null, null]
    phi3:              [null, null, null]
```

---

## B. A/B/C/D 组件消融

### 为什么要补
四层校验 + 元数据检索 + 历史 SQL 是本文的方法主体，但**没有任何证据说明哪一层在起作用**。
系统类论文缺消融是硬伤。你原来的 `main.tex` 里本来就有这套设置，复刻时丢了。

### 四个设置（沿用你原稿的定义）

| 设置 | 含义 |
|---|---|
| A | 裸 LLM，只给自然语言请求 |
| B | A + 数仓 schema |
| C | B + RAG（元数据 + 口径字典 + 历史 SQL） |
| D | C + 四层执行反馈校验（= 完整系统） |

**建议只跑最优模型 qwen2.5:7b**，24 个任务 × 5 策略 = 120 次/设置，共 480 次。
跑全部 8 模型会好但成本高 4 倍，边际收益不大。

### 需要的数（每设置两个整数，与主实验同构）

| 设置 | 尝试 | 生成成功 | 幻觉 | 预估有效率 |
|---|---|---|---|---|
| A 裸 LLM | 120 | ___ | ___ | **15–35%**。⚠️ >50% 说明任务太简单，整套方法的必要性存疑 |
| B +schema | 120 | ___ | ___ | 30–50% |
| C +RAG | 120 | ___ | ___ | 55–70% |
| D 完整 | 120 | 108 | 22 | 71.7%（已有，即主实验的 qwen 行） |

**关键检查**：A < B < C < D 必须单调。⚠️ 若 C ≈ D，说明四层校验没带来增量，
Discussion 里"execution feedback 是关键"的说法要改写；若 B ≈ A，说明 schema 注入无效。

### 另需：按错误类别拆分（说明每一层修掉了哪类错）

| 设置 | A 不存在字段 | B 错误口径 | C 自然语言残留 | D 占位符 | E 方言/schema |
|---|---|---|---|---|---|
| A | ___ | ___ | ___ | ___ | ___ |
| B | ___ | ___ | ___ | ___ | ___ |
| C | ___ | ___ | ___ | ___ | ___ |
| D | 3 | 8 | 2 | 5 | 4 |

**内涵**：这张表是消融的真正价值所在 —— 它能说明
"schema 注入主要消掉 A 类，RAG 主要消掉 B 类，执行反馈主要消掉 D/E 类"。
⚠️ 若各设置的错误构成没有明显移动，说明各组件作用重叠，方法叙事要调整。

### 我会产出
- Results 新增子节 "Component Ablation"
- 新增 Table 6（四设置 × 生成率/幻觉率/有效率）
- 新增 Figure 5（堆叠柱：四设置 × 五类错误绝对数，直接可视化"哪一层修掉哪类错"）
- Discussion 增补一段

### YAML
```yaml
ablation:
  model: qwen2.5:7b
  attempts_per_setting: 120
  settings:
    A_bare:      {generated: null, hallucinating: null, hall_types: [null,null,null,null,null]}
    B_schema:    {generated: null, hallucinating: null, hall_types: [null,null,null,null,null]}
    C_rag:       {generated: null, hallucinating: null, hall_types: [null,null,null,null,null]}
    D_full:      {generated: 108,  hallucinating: 22,   hall_types: [3,8,2,5,4]}
```

---

## C. 可选：公开基准锚点（评审第三个缺口）

不填也能到 8.2–8.5，填了到 8.5+。最省力的做法：拿现成的 **EHRSQL** 或 **MIMICSQL**
公开集，用同一套 pipeline 跑一遍，只报 execution accuracy 一个数。

| 量 | 内涵 | 预估 |
|---|---|---|
| 公开集名称与版本 | 让审稿人有绝对参照 | EHRSQL 2024 / MIMICSQL |
| 你的 pipeline 在其上的执行准确率 | "我们的方法本身合格" | 与该集已发表 SOTA 差 **10–25 个百分点**属正常（你的 pipeline 是为医院数仓调的） |
| 同一模型在公开集上的幻觉率 | 说明幻觉率不是数仓特有 | — |

```yaml
public_benchmark:
  dataset: null
  execution_accuracy: null
  hallucination_rate: null
```

---

## D. 优先级

| 顺序 | 事项 | 集群成本 | 分数增益 |
|---|---|---|---|
| 1 | **A 组 TO-CONFIRM**（纯人工判定，不用重跑模型） | 1–2 人日 | +0.4 |
| 2 | **B 组消融**（480 次生成，单模型） | 半天机时 | +0.4 |
| 3 | C 组公开基准 | 1 天 | +0.3 |

A 组最划算 —— **不需要重跑任何模型**，只要对已有的 960 条输出做人工判定。
