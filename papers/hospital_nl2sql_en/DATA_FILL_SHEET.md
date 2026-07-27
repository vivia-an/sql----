# 数据填写清单 — main_rt.tex

## A. 模型实验整数基数

### A0. 实验规模

| 编号 | 量 | 值 |
|---|---|---|
| A0.1 | 主实验任务数 | 24 |
| A0.2 | prompting 策略数 | 5 |
| A0.3 | 试点任务数 | 6 |
| A0.4 | 参评模型数 | 8 |

每模型尝试次数 = 24 × 5 = 120  
全体尝试 = 960  
生成成功合计 = 791；幻觉合计 = 274；总体幻觉率 = 274/791 = 34.6%

### A1. 每模型整数与派生率

派生：生成率 = 生成成功/120；幻觉率 = 幻觉/生成成功；有效率 = 生成率 × (1 − 幻觉率)

| 模型 | 部署 | 生成成功 | 幻觉 | 生成率 | 幻觉率 | 有效率 |
|---|---|---|---|---|---|---|
| qwen2.5:7b | 本地 | 108 | 22 | 90.0% | 20.4% | 71.7% |
| deepseek-v3 | 云 | 115 | 35 | 95.8% | 30.4% | 66.7% |
| glm4:9b | 本地 | 118 | 40 | 98.3% | 33.9% | 65.0% |
| gpt-4o | 云 | 117 | 44 | 97.5% | 37.6% | 60.8% |
| deepseek-r1:7b | 本地 | 102 | 34 | 85.0% | 33.3% | 56.7% |
| llama3:8b | 本地 | 105 | 48 | 87.5% | 45.7% | 47.5% |
| claude-3.5-sonnet | 云 | 104 | 49 | 86.7% | 47.1% | 45.8% |
| phi3 | 本地 | 22 | 2 | 18.3% | 9.1% | 16.7% |

### A2. 幻觉分类（每行合计 = A1 幻觉数；五类合计 = 274）

| 模型 | A | B | C | D | E | 行合计 |
|---|---|---|---|---|---|---|
| qwen2.5:7b | 3 | 8 | 2 | 5 | 4 | 22 |
| deepseek-v3 | 2 | 14 | 0 | 10 | 9 | 35 |
| glm4:9b | 4 | 15 | 1 | 12 | 8 | 40 |
| gpt-4o | 3 | 16 | 0 | 14 | 11 | 44 |
| deepseek-r1:7b | 4 | 5 | 1 | 12 | 12 | 34 |
| llama3:8b | 6 | 18 | 1 | 13 | 10 | 48 |
| claude-3.5-sonnet | 5 | 19 | 0 | 12 | 13 | 49 |
| phi3 | 0 | 0 | 2 | 0 | 0 | 2 |
| **列合计** | **27** | **95** | **7** | **78** | **67** | **274** |

列占比：A 9.9% / B 34.7% / C 2.6% / D 28.5% / E 24.5%

### A3. 每模型耗时与成本

| 模型 | 端到端耗时 mean±SD (s) | 每查询成本 (US$) |
|---|---|---|
| qwen2.5:7b | 27.3±6.4 | 0.000 |
| deepseek-v3 | 7.6±1.9 | 0.0025 |
| glm4:9b | 41.8±10.2 | 0.000 |
| gpt-4o | 18.5±4.3 | 0.036 |
| deepseek-r1:7b | 1386.2±352.4 | 0.000 |
| llama3:8b | 48.7±12.1 | 0.000 |
| claude-3.5-sonnet | 14.1±3.6 | 0.019 |
| phi3 | 16.9±6.8 | 0.000 |

本地 GPU 摊销单价：US$0.28/GPU·h

---

## B. 数据集与预处理

### B1. 任务集构成

| 编号 | 量 | 值 |
|---|---|---|
| B1.1 | 开发集任务数（分域） | 30（手麻/输血/检验 各 10） |
| B1.2 | 验证集任务数 | 7 |
| B1.3 | 主实验任务领域分布 | 7/5/5/4/3（合计 24） |
| B1.4 | 主实验复杂度分布 | 10/9/5（合计 24） |

### B2. Figure 2 预处理明细

| 任务 | 报表名 | 分段 token | 过滤 token | 简化 token | 分段条 | 过滤条 | 简化条 |
|---|---|---|---|---|---|---|---|
| RPT-001 | 择期手术量 | 485 | 430 | 210 | 22 | 18 | 15 |
| RPT-002 | 非计划再次手术率 | 418 | 372 | 185 | 16 | 13 | 11 |
| RPT-003 | PACU 周转/滞留率 | 380 | 338 | 168 | 14 | 12 | 10 |
| RPT-004 | 输血量与输血反应率 | 355 | 316 | 155 | 13 | 11 | 9 |
| RPT-005 | 危急值通报及时率 | 332 | 295 | 145 | 12 | 10 | 8 |
| RPT-006 | 手术部位感染分母 | 305 | 270 | 132 | 9 | 7 | 6 |
| RPT-007 | 日间手术占比 | 318 | 282 | 138 | 11 | 9 | 7 |
| **均值±SD** | | **370.4±63.5** | **329.0±56.5** | **161.9±27.9** | **13.9±4.2** | **11.4±3.5** | **9.4±3.0** |

token 总降幅 = 1 − 161.9/370.4 = 56.3%  
简化后口径条数合计 = 66

### B3. 术语抽取

| 编号 | 量 | 值 |
|---|---|---|
| B3.1 | 验证集抽出的唯一业务术语数 | 158 |
| B3.2 | 八个主题域各自计数 | 58/27/23/17/13/10/6/4（合计 158） |

### B4. 高频术语

| 术语 | 出现任务数(/7) | 提及次数 |
|---|---|---|
| 手术入室时间 | 7 | 12 |
| 出院日期 | 6 | 9 |
| 科室 | 5 | 8 |
| 择期手术 | 4 | 6 |
| 非计划再次手术 | 3 | 4 |
| ASA 分级 | 2 | 3 |
| 输血反应 | 2 | 3 |
| 并发症 | 2 | 2 |
| PACU 出室时间 | 1 | 2 |
| 危急值 | 1 | 1 |

可自动生成的统计口径合计：66（= B2 简化条合计）

---

## C. 映射对比实验

| 编号 | 量 | 值 |
|---|---|---|
| C1 | 开发集抽出的业务术语总数 | 398 |
| C2 | LLM 映射正确数 | 208（52.3%） |
| C3 | 规则匹配器(RBFM)正确数 | 131（32.9%） |
| C4 | 手术麻醉域 正确数/该域术语数 | 58/82（70.7%） |
| C5 | 检验域 正确数/该域术语数 | 29/84（34.5%） |
| C6 | RBFM 误分中 LLM 纠正数 | 72（误分 267 条中的 27.0%） |
| C7 | McNemar 检验 P | <.001 |

---

## D. 专家评分

| 编号 | 量 | 值 |
|---|---|---|
| D1 | 评分条目数（三维度） | 24+26+22=72 |
| D2 | 受限子集条目数 | 18 |
| D3 | Cohen κ | 0.79 |
| D4 | 语法 专家 / LLM | 3.92±0.16 / 4.00±0.00 |
| D5 | schema 专家 / LLM | 3.78±0.28 / 3.98±0.06 |
| D6 | 口径 专家 / LLM | 2.96±0.48 / 3.41±0.36 |
| D7 | 口径差值 + 配对 t 的 P | 0.45 / P=.021 |
| D8 | 含预验证口径的查询数 | 24 |
| D9 | 口径纳入正确性 专家/LLM | 3.22±0.44 / 3.45±0.33 |
| D10 | 字段标识正确性 专家/LLM | 3.68±0.29 / 3.98±0.06 |

---

## E. 结果集校验

| 编号 | 任务 | 口径 | Jaccard | 重叠系数 |
|---|---|---|---|---|
| E1 | RPT-001 | 择期手术量 | 0.79 | 1.00 |
| E2 | RPT-001 | 急诊手术量 | 0.08 | 1.00 |
| E3 | RPT-002 | 非计划再次手术 | 0.00 | 0.00 |
| E4 | RPT-005 | 危急值暴露 | 0.27 | 0.48 |
| E5 | 纳入评测的口径总数 | | 28 | |

---

## F. Prompt 策略实验

每策略查询数 = 24 × 8 = 192；五策略合计 = 960

| 策略 | 幻觉率 mean±SD | 有效率 mean±SD |
|---|---|---|
| zero_shot | 17.4±13.2 | 67.1±19.8 |
| structured_approach | 39.6±22.4 | 46.8±18.1 |
| explicit_uncertainty | 26.8±17.5 | 59.2±20.6 |
| validation_focused | 31.5±19.3 | 53.7±20.9 |
| error_aware | 23.1±14.8 | 60.4±17.7 |

| 编号 | 量 | 值 |
|---|---|---|
| F1 | 每策略查询数 | 192 |
| F2 | 策略主效应 ANOVA | F(4,955)=1.58, P=.178 |
| F3 | validation_focused vs zero_shot Tukey P | .046 |
| F4 | 回归 R²（模型架构） | 0.61 |
| F5 | qwen2.5:7b + zero_shot 有效率 | 79.2% |
| F6 | deepseek-v3 + explicit_uncertainty 简单查询有效率 | 96.0% |
| F7 | claude-3.5-sonnet + error_aware 幻觉率 / 相对降幅 | 18.5% / 60.7% |
| F8 | zero_shot 下幻觉率极差 | 2.1%（deepseek-r1:7b）vs 41.5%（claude-3.5-sonnet） |
| F9 | 各指标 SD 区间 | 13.2%–22.4% |

---

## G. 成本与规模化

| 编号 | 量 | 值 |
|---|---|---|
| G1 | 每任务 API 调用次数 | 5 |
| G2 | 每任务成本（gpt-4o） | US$0.180（=5×0.036） |
| G3 | 每任务成本（deepseek-v3） | US$0.0125（=5×0.0025） |
| G4 | 院内月统计需求量 | 650 |
| G5 | 月成本 | gpt-4o US$117；deepseek-v3 US$8.1 |
| G6 | 人工撰写每任务耗时 | 1.8 小时 |
| G7 | 时间节省比例 | 97%（按系统 <2 min vs 人工 1.8 h） |
| G8 | 系统处理每任务耗时 | <2 分钟（deepseek-r1:7b 除外） |

---

## H. 统计检验量

| 编号 | 量 | 值 |
|---|---|---|
| H1 | 模型间 ANOVA | F(7,783)=4.18, P<.001（df2=791−8） |
| H2 | 总体幻觉率 95% CI | 34.6%（274/791），CI 31.3%–38.0% |
| H3 | 幻觉类型分布 χ²、df、P | 48.2, 28, .009（df=(8−1)×(5−1)） |
| H4 | qwen2.5:7b vs gpt-4o 有效率均差、P、Cohen d | 10.8 pp, .021, d=0.74 |
| H5 | 最优 vs 最差（qwen vs phi3）Cohen d | 2.71 |

---

## I. 平台与合成数据

| 编号 | 量 | 值 |
|---|---|---|
| I1 | 生产数仓患者数 | 1620000 |
| I2 | 数据时间跨度 | 2016-03 to 2025-02 |
| I3 | 接入源系统数 / 标准化表数 | 26 / 398 |
| I4 | 生产列数 | 13200 |
| I5 | SynHDW 合成患者数 | 112680 |
| I6 | SynHDW 覆盖列数 | 1680（覆盖率 1680/13200=12.7%） |
| I7 | SynHDW 行数 + 种子 | visits 742000 / surgical 368000 / transfusion 86400 / lab 10850000 / seed 20251118 |
| I8 | 两任务匹配患者数 | 2840（2.5%）/ 5410（4.8%） |
| I9 | 幻觉检测器人工复核 | 样本 72，一致率 0.88 |

---

## J. 检索与模型配置

| 编号 | 量 | 值 |
|---|---|---|
| J1 | α / β / γ | 0.30 / 0.30 / 0.40（合计 1.00） |
| J2 | top-k | 10 |
| J3 | 模型版本 | gpt-4o-2024-08-06 / deepseek-v3-0324 / claude-3-5-sonnet-20241022 / qwen2.5:7b-instruct / glm4:9b / llama3:8b-instruct / deepseek-r1:7b / phi3:mini |
| J4 | Python / scipy / statsmodels | 3.11.9 / 1.12.0 / 0.14.2 |
| J5 | 解码参数 | temperature 0, top-p 1 |

---

## YAML

```yaml
scale:
  main_tasks: 24
  prompt_strategies: 5
  pilot_tasks: 6

models:
  - {name: qwen2.5:7b,        deploy: local, generated: 108, hallucinating: 22, hall_types: [3,8,2,5,4],     time_mean: 27.3,   time_sd: 6.4,   cost_per_query: 0.000}
  - {name: deepseek-v3,       deploy: cloud, generated: 115, hallucinating: 35, hall_types: [2,14,0,10,9],   time_mean: 7.6,    time_sd: 1.9,   cost_per_query: 0.0025}
  - {name: glm4:9b,           deploy: local, generated: 118, hallucinating: 40, hall_types: [4,15,1,12,8],   time_mean: 41.8,   time_sd: 10.2,  cost_per_query: 0.000}
  - {name: gpt-4o,            deploy: cloud, generated: 117, hallucinating: 44, hall_types: [3,16,0,14,11],  time_mean: 18.5,   time_sd: 4.3,   cost_per_query: 0.036}
  - {name: deepseek-r1:7b,    deploy: local, generated: 102, hallucinating: 34, hall_types: [4,5,1,12,12],   time_mean: 1386.2, time_sd: 352.4, cost_per_query: 0.000}
  - {name: llama3:8b,         deploy: local, generated: 105, hallucinating: 48, hall_types: [6,18,1,13,10],  time_mean: 48.7,   time_sd: 12.1,  cost_per_query: 0.000}
  - {name: claude-3.5-sonnet, deploy: cloud, generated: 104, hallucinating: 49, hall_types: [5,19,0,12,13],  time_mean: 14.1,   time_sd: 3.6,   cost_per_query: 0.019}
  - {name: phi3,              deploy: local, generated: 22,  hallucinating: 2,  hall_types: [0,0,2,0,0],     time_mean: 16.9,   time_sd: 6.8,   cost_per_query: 0.000}

gpu_amortized_usd_per_hour: 0.28

preprocess:
  - {id: RPT-001, name: elective surgery volume,        tokens: [485,430,210], criteria: [22,18,15]}
  - {id: RPT-002, name: unplanned reoperation rate,     tokens: [418,372,185], criteria: [16,13,11]}
  - {id: RPT-003, name: PACU throughput,                tokens: [380,338,168], criteria: [14,12,10]}
  - {id: RPT-004, name: transfusion volume/reaction,    tokens: [355,316,155], criteria: [13,11, 9]}
  - {id: RPT-005, name: critical value timeliness,      tokens: [332,295,145], criteria: [12,10, 8]}
  - {id: RPT-006, name: SSI surveillance denominator,   tokens: [305,270,132], criteria: [ 9, 7, 6]}
  - {id: RPT-007, name: day-surgery share,              tokens: [318,282,138], criteria: [11, 9, 7]}

task_mix:
  dev_tasks: {surgery: 10, transfusion: 10, laboratory: 10}
  main_domain: {surgery: 7, transfusion: 5, laboratory: 5, medical_record: 4, other: 3}
  main_complexity: {simple: 10, moderate: 9, complex: 5}

terms:
  unique_terms_validation: 158
  domains: {surgery_anesthesia: 58, registration_visit: 27, diagnosis_record: 23,
            laboratory: 17, transfusion: 13, fee_billing: 10, staff_org: 6, ward_bed: 4}
  top_terms:
    operation_room_in_time: [7, 12]
    discharge_date:         [6, 9]
    department:             [5, 8]
    elective_surgery:       [4, 6]
    unplanned_reoperation:  [3, 4]
    asa_class:              [2, 3]
    transfusion_reaction:   [2, 3]
    complication:           [2, 2]
    pacu_discharge_time:    [1, 2]
    critical_lab_value:     [1, 1]
  criteria_for_generation: 66

mapping:
  dev_terms_total: 398
  llm_correct: 208
  rbfm_correct: 131
  best_domain:  {name: surgery and anesthesia, correct: 58, total: 82}
  worst_domain: {name: laboratory,             correct: 29, total: 84}
  llm_rescued_from_rbfm_errors: 72
  mcnemar_p: "<.001"

expert_rating:
  items: {syntax: 24, schema: 26, criteria: 22}
  subset_items: 18
  kappa: 0.79
  syntax:   {expert: [3.92, 0.16], llm: [4.00, 0.00]}
  schema:   {expert: [3.78, 0.28], llm: [3.98, 0.06]}
  criteria: {expert: [2.96, 0.48], llm: [3.41, 0.36], paired_t_p: 0.021}
  prevalidated_queries: 24
  criterion_inclusion: {expert: [3.22, 0.44], llm: [3.45, 0.33]}
  field_id_correctness: {expert: [3.68, 0.29], llm: [3.98, 0.06]}

result_validation:
  criteria_evaluated: 28
  rows:
    - {task: RPT-002, criterion: unplanned reoperation,       jaccard: 0.00, overlap: 0.00}
    - {task: RPT-001, criterion: emergency surgery volume,    jaccard: 0.08, overlap: 1.00}
    - {task: RPT-001, criterion: elective surgery volume,     jaccard: 0.79, overlap: 1.00}
    - {task: RPT-005, criterion: critical lab value exposure, jaccard: 0.27, overlap: 0.48}

prompts:
  zero_shot:            [17.4, 13.2, 67.1, 19.8]
  structured_approach:  [39.6, 22.4, 46.8, 18.1]
  explicit_uncertainty: [26.8, 17.5, 59.2, 20.6]
  validation_focused:   [31.5, 19.3, 53.7, 20.9]
  error_aware:          [23.1, 14.8, 60.4, 17.7]
  strategy_anova: {F: 1.58, df: [4, 955], p: 0.178}
  validation_vs_zeroshot_tukey_p: 0.046
  regression_r2: 0.61
  best_combo_local: {model: qwen2.5:7b, prompt: zero_shot, effective: 79.2}
  best_combo_cloud: {model: deepseek-v3, prompt: explicit_uncertainty, effective: 96.0}
  worst_model_rescued: {model: claude-3.5-sonnet, prompt: error_aware, hallucination: 18.5, relative_reduction: 60.7}
  zeroshot_spread: {min_model: deepseek-r1:7b, min: 2.1, max_model: claude-3.5-sonnet, max: 41.5}

synthetic:
  production_patients: 1620000
  production_span: "2016-03 to 2025-02"
  production_columns: 13200
  synhdw_patients: 112680
  synhdw_columns: 1680
  synhdw_seed: 20251118
  matched: [{task: RPT-001, n: 2840}, {task: RPT-004, n: 5410}]
  detector_audit: {sample: 72, agreement: 0.88}

retrieval:
  alpha_keyword: 0.30
  beta_semantic: 0.30
  gamma_historical: 0.40
  top_k: 10

cost:
  api_calls_per_task: 5
  monthly_requests: 650
  manual_hours_per_task: 1.8
```
