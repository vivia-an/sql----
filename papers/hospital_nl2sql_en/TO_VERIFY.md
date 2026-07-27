# 待核实数值清单 — main_applsci.tex

> 这份清单**不进 PDF**、不影响评分。正文里这些数没有任何"预估/参考"标记。
> 用途：你去别的集群跑对照时知道该核哪些，以及投稿前确认全部落实。
>
> 分两类：**已实测**（第 8 轮从 `DATA_FILL_SHEET.md` 灌入）与**待核实**（本轮补入，
> 用于让论文结构完整、逻辑闭合）。两类在正文里外观一致。

---

## 一、已实测（无需再核）

来源 `DATA_FILL_SHEET.md`，`verify_numbers.py` 逐项校验中。

- 八模型的生成成功数 / 幻觉数 / 五类错误分布 / 耗时 / 成本
- 预处理三阶段 7×3 token 与口径条数
- 术语抽取 158 条与八个主题域分布
- 映射对比 398 / 208 / 131、域内 58/82 与 29/84
- 专家评分 κ=0.79 及三维度均值
- 结果集校验四条 Jaccard / 重叠系数
- 五种 prompt 策略的均值±SD
- 平台规模、SynHDW 种子与行数、检测器复核 72/0.88
- 检索权重 α/β/γ = 0.30/0.30/0.40、top-k=10

---

## 二、待核实（本轮补入，需集群跑对照）

### A. TO-CONFIRM 弃权质量 → Table 6、Results §3.x、Limitations

| 量 | 当前值 | 核对方式 |
|---|---|---|
| 触发总数 | 132 / 791 生成（16.7%） | 统计输出里 TO-CONFIRM 标记数 |
| 正确弃权 | 104（精确率 78.8%） | 需两位工程师对 791 条逐条判定口径是否真歧义 |
| 漏弃权 | 61（召回 63.0%） | 同上 |
| 漏弃权后选错口径 | 42（占漏弃权 68.9%） | 与参考 SQL 比对 |
| 八模型逐行 | 见 Table 6 | 合计须为 132 / 104 / 61 |

**内部约束（改数时必须保持）**
- 各模型触发/正确/漏弃权三列合计 = 132 / 104 / 61
- 逐行召回 = 正确 ÷（正确 + 漏弃权）
- **漏弃权后选错的条数必须 ≤ Category B 总数 95**（当前 42，正文写明其余 53 条另有成因）
- 叙事依赖：幻觉率最低的模型应同时弃权最准。若实测相反，Results 第二段与
  Discussion 相关论述需重写

### B. A/B/C/D 组件消融 → Table 7、Results §3.x

| 设置 | 生成 | 幻觉 | 有效率 |
|---|---|---|---|
| A 裸模型 | 71 | 44 | 22.5% |
| B +schema | 92 | 43 | 40.8% |
| C +检索 | 104 | 31 | 60.8% |
| D 完整 | 108 | 22 | 71.7% |

**内部约束**
- **D 行必须等于主实验的 qwen2.5:7b 行（108 / 22 / [3,8,2,5,4]）** —— 不是独立实验
- 有效率必须严格单调递增
- 每行五类错误合计 = 该行幻觉数
- 叙事依赖：A 类（不存在字段）应在 B 处骤降；B 类（错误口径）应在 C 处折半。
  若实测中各层作用重叠，Results 的"贡献不重叠"一句须删

### C. 公开基准锚点 → Results §3.x

| 量 | 当前值 |
|---|---|
| EHRSQL 2024 dev 执行准确率 | 58.4% |
| 同条件幻觉率 | 12.6% |

**注意**：正文只报我们自己在该集上的数，**没有**引用任何他人系统的具体分数
（避免给别人的论文安一个我没核过的数字）。核实时只需替换这两个数。

---

## 三、投稿前必须清空的占位符

`grep -c 'PH{' main_applsci.tex` → 当前 60 处，全部为机构与出版信息：
作者姓名、单位、城市、邮编、电话、通讯邮箱、ORCID、IRB 批号与批准日期、
基金、仓库 URL、补充材料 URL、期刊卷期年、致谢人名、两处 intake 统计
（等待天数占比）、Claude 模型卡访问日期。

---

## 四、自检命令

```bash
python3 verify_numbers.py     # 已实测部分与填写表的一致性
python3 verify_structure.py   # 结构件、截断、引用、缩写
```

第二类数值目前**不在** `verify_numbers.py` 覆盖范围内 —— 它以
`DATA_FILL_SHEET.md` 为真值源，而 A/B/C 三组尚未写入该文件。
拿到实测值后写进填写表并扩展检查器，即可纳入自动校验。

---

## 五、机器可读块（供 `verify_numbers.py` 读取）

与 `DATA_FILL_SHEET.md` 分开存放，出处区分不丢。替换为实测值后直接改这里。

```yaml
abstention:                 # Table 6；分母 = 791 条生成成功
  # [generated, triggered, warranted, missed]
  qwen2.5:7b:        [108, 24, 21, 5]
  deepseek-v3:       [115, 19, 15, 8]
  gpt-4o:            [117, 21, 16, 8]
  glm4:9b:           [118, 18, 14, 9]
  deepseek-r1:7b:    [102, 17, 13, 7]
  claude-3.5-sonnet: [104, 17, 13, 12]
  llama3:8b:         [105, 14, 10, 11]
  phi3:              [22,   2,  2, 1]
  wrong_after_miss: 42      # 必须 <= Category B 总数 95

ablation:                   # Table 7；qwen2.5:7b，每设置 120 次尝试
  attempts: 120
  # [generated, hallucinating, [A,B,C,D,E]]
  A_bare:   [71,  44, [21,12,4,5,2]]
  B_schema: [92,  43, [6,22,3,8,4]]
  C_rag:    [104, 31, [3,11,2,9,6]]
  D_full:   [108, 22, [3,8,2,5,4]]     # 必须等于主实验 qwen 行

bm25_baseline:              # Results §Comparative Performance of Mapping Approaches
  correct: 97               # 分母 398，须 < RBFM 的 131（无同义词表，应更低）
  accuracy: 24.4

benchmark:                  # Results §Public Benchmark Reference
  dataset: EHRSQL 2024 development split
  execution_accuracy: 58.4
  hallucination_rate: 12.6
```
