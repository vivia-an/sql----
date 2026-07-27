# 复刻评审 — main_rt.tex vs JMIR Med Inform 2025;13:e71252

对标原文：Lee KH, et al. *Large Language Models for Automating Clinical Trial Criteria
Conversion to OMOP CDM Queries: Validation and Evaluation Study.* doi:10.2196/71252
（PDF 全文已解析，17 页，4 图 5 表 51 引用）

产出：`main_rt.tex` → 编译通过（0 error，5 处 overfull ≤17.6pt），**17 页**，与原文同页数。

工具链：本机原无 LaTeX。已装 TeX Live 2013 + poppler；pgf 3.1.5b / pgfplots 1.16
装在 `/root/texmf`（TL2019 版本，TL2013 内核兼容）。编译命令：
`pdflatex -output-directory=<tmp> main_rt.tex`（跑两遍解引用）。

---

## 一、逐项对齐核对

| 维度 | 原文 | main_rt.tex | 状态 |
|---|---|---|---|
| 篇首 “Original Paper” 标签 | ✓ | ✓ | ✅ |
| 标题式样 `…: Validation and Evaluation Study` | ✓ | ✓ | ✅ |
| 作者行（学位+上标）/ 单位块 / 通讯作者块（Phone/Fax/Email） | 8 作者 / 5 单位 | 8 / 5 | ✅ |
| 结构化摘要 Background/Objective/Methods/Results/Conclusions | ✓ | ✓ | ✅ |
| 引用行 + Keywords 行 | ✓ | ✓ | ✅ |
| Introduction 段数 | 5 | 5 | ✅ |
| Methods 子节 | 11 个（含 3 个三级） | 同名同序 11 个 | ✅ |
| Results 子节 | 9 | 同序 9 | ✅ |
| Discussion 子节 | 6 | 同序 6 | ✅ |
| 图 | 4（Fig2/3/4 为 A/B 双面板） | 4，同样 A/B 双面板 | ✅ |
| 表 | 5（含 a–e 脚注字母） | 5，同结构同脚注字母 | ✅ |
| 统计手法 | McNemar / ANOVA F / Tukey HSD / Cohen d / χ² / 多元回归 R² / 配对 t / κ / 95%CI | 全部出现 | ✅ |
| 尾部 Acknowledgments → Authors' Contributions → Conflicts → MA1-3 → References → Abbreviations → 编辑页脚+版权 | ✓ | ✓ | ✅ |
| 页眉页脚（刊名/作者、URL、`(page number not for citation purposes)`） | ✓ | ✓ | ✅ |
| 参考文献 | 51 条，Vancouver + [doi:] [Medline:] | **50 条**，样式一致，按首次引用重排，无悬空无缺引 | ✅ |
| 补充材料 ×3 | Supplementary methods / Prompt templates / SQL evaluation metrics | 三份独立 .tex 全部产出并编译通过 | ✅ |

### 图的对应关系
| | 原文 | 本稿 |
|---|---|---|
| Fig 1 | 三阶段预处理+概念映射架构图（单幅） | 同构：三阶段预处理 + 信息抽取/字段口径映射/SQL 生成 + 元数据知识库三层 |
| Fig 2 | (A) token 数跨阶段折线×7 试验 (B) criteria 数 | (A)(B) 同构，7 个报表任务 RPT-001…007 + 均值虚线 |
| Fig 3 | (A) 8 模型幻觉率 vs 有效 SQL 率柱 (B) 成本-性能气泡图（对数 x，云/本地分色） | 同构；本地模型按摊销 GPU 成本定位（原文本地成本为 0 无法上对数轴，此处已注明算法） |
| Fig 4 | (A) 幻觉类型堆叠柱+总数标注 (B) 行归一化热力图+色条 | 同构，5 类 A–E，viridis 色阶 |

---

## 二、内容替换映射（“内容我们自己的”）

| 原文 | 本稿 |
|---|---|
| 临床试验入组标准 | 医院统计需求（报表工单） |
| OMOP CDM | 三层数仓 DL/DC/MDR + Presto |
| USAGI（字符串相似度映射工具） | RBFM 院内元数据门户规则字段匹配器 |
| SynPUF 合成数据 | SynHDW 数仓脱敏合成镜像 |
| N3C 参考概念集 | 工程师核定的历史参考 SQL |
| 概念域（condition/drug/…） | 主题域（手麻/登记就诊/诊断病案/检验/输血/收费/人员/病区） |
| 幻觉 B 类=错误域归属 | **B 类=错误统计口径**（如按出院时间而非入室时间计数）——本文的领域特化 |
| 8 LLM（3 云 5 本地） | 8 LLM（云：gpt-4o / deepseek-v3 / claude-3.5-sonnet；本地：qwen2.5:7b / glm4:9b / llama3:8b / deepseek-r1:7b / phi3） |
| 结论：小模型 llama3:8b 胜 GPT-4 | 结论：本地 qwen2.5:7b 73.8% 胜 gpt-4o 63.3%——并额外收口“隐私约束与精度最优点重合” |

---

## 三、待你修正的数据（全部为**内部自洽**的暂填值）

所有派生量都能从表里重算，替换时请整组替换，否则会自相矛盾。

- **预处理**：348.6±61.7 → 302.9±53.6 → 134.6±23.6 tokens；12.9±4.2 → 10.4±3.5 → 9.6±3.3 条；
  降幅 61.4%。Fig 2 的 7×3 明细与均值/SD 完全一致，末阶段条数合计 = 67（正文引用值）。
- **术语抽取**：163 条，8 个主题域计数合计=163，百分比逐条核过。
- **映射对比**：LLM 53.9%(222/412) vs RBFM 34.5%(142/412)；域内 71.8%(61/85) / 36.7%(33/90)；
  RBFM 误分 270 条中 LLM 纠正 79 条(29.3%)。
- **专家评分**：κ=0.87；语法 3.96±0.14、schema 3.85±0.23、口径 3.08±0.51（差 0.41，P=.017）。
- **结果集校验**（Table 3）：0/0、0.05/1.0、0.86/1.0、0.22/0.51。
- **模型表**（Table 4）：8 行，Effective = Generation×(1−Hallucination) 逐行验算通过。
- **幻觉分类**（Table 5）：各行合计 = 42/29/50/21/41/33/1/46，总计 **263**；
  五类合计 24/91/6/78/64 = 263，占比 9.1/34.6/2.3/29.7/24.3 = 100.0。正文与图 4 同源。
- **总体幻觉率 32.6% (n=263)**：由 8 模型 ×120 次生成、按各自生成率加权推出（生成成功 807 次）。
- **红色 `[...]` 占位**：作者/单位/IRB 号/仓库 URL/月请求量/成本区间/真实数仓规模。

---

---

## 四、第 2 轮已补（2026-07-25）

### 4.1 参考文献 24 → 50（全部真实、全部已核）
按首次引用顺序重排完毕；脚本校验 **无悬空条目、无缺引用**。新增 26 条，重点核实过著录：

- Yuan C, et al. Criteria2Query. *JAMIA* 2019;26(4):294-305. doi:10.1093/jamia/ocy178（Medline 30753493）
- Liu R, et al. Trial Pathfinder. *Nature* 2021;592(7855):629-633. doi:10.1038/s41586-021-03430-5（Medline 33828294）
- Dobbins NJ, et al. LeafAI. *JAMIA* 2023;30(12):1954-1964. doi:10.1093/jamia/ocad149（Medline 37550244）
- Pan Y, et al. MedTS. *JMIR Med Inform* 2021;9(12):e32698. doi:10.2196/32698（Medline 34889749）
- 另加 TREQS、BIRD、DAIL-SQL、MAC-SQL、Presto(ICDE'19)、BM25、Sentence-BERT、BERT、
  OHDSI、8 个模型技术报告、Landis&Koch、McNemar、Tukey、SciPy、statsmodels

> ⚠️ Criteria2Query **3.0**（J Biomed Inform 2024;154:104649）作者名单未能核到，**未收录**，
> 没有编造。若要引用需自行补作者。

正文同步补了引用点：Intro¶2（Presto/OMOP）、Intro¶3（三组：benchmark / EHR / 试验入组查询）、
Methods 管线（BM25+SBERT+BERT）、Experimental Design（8 个模型逐一引）、Statistical Analysis
（McNemar/Tukey/κ/SciPy/statsmodels）。

### 4.2 三份补充材料已产出（均独立编译通过）
| 文件 | 内容 | 页数 |
|---|---|---|
| `appendix1_methods.tex` | **Figure S1** 详细管线架构（4 泳道：预处理/抽取生成/四层校验/知识库）+ 处理流程细节 + 任务集构成表 S1 + SynHDW 构建 + 幻觉检测算法 7 步 | 3 |
| `appendix2_prompts.tex` | P1–P6 六个管线 prompt 全文 + 5 种 prompting strategy 指令体对照表 + 复现说明 | 3 |
| `appendix3_sqlmetrics.tex` | **72 条专家评分条目全表**（语法 24 / schema 26 / 口径 22），含 18 条受限子集标记 + 评分公式 | 2 |

72 条已按 24+26+22 拆分核对；18 条子集 = C1–C3、C22–C24（字段标识正确性 6 条）+
X1–X3、X6、X7、X12–X14、X16–X19（口径纳入正确性 12 条），与正文 Methods 描述一致。

### 4.3 补充材料里顺带修掉一处正文隐患
Appendix 1 §S5 明确了**计数口径**：每条幻觉查询按严重度 A>B>C>D>E 只归一类。
这保证 Table 5 行合计 = 该模型幻觉查询数、总计 263 = 幻觉查询总数、32.6% = 263/807 三者自洽，
不会被审稿人抓「defect 数 vs query 数」的矛盾。

### 4.4 配图再优化
- Fig 1：分组框标签外移、行距加大、`Field and criterion mapping` 断字修掉 —— 无遮挡
- Fig 3B：气泡尺寸区间拉开（1.4–6.6pt）、8 个标签重新定位、x 轴上限放宽，无裁切无互压
- Fig S1：知识库连线原本横穿泳道，改为泳道级连接器（retrieve / lookup）+ 反馈路径绕左下走线，
  现在**零穿框**

### 4.5 编译状态
| 文件 | errors | overfull | pages |
|---|---|---|---|
| main_rt.tex | 0 | 5（≤17.6pt） | **18**（原文 17，参考文献从 24 涨到 50 后 +1） |
| appendix1_methods.tex | 0 | 1 | 3 |
| appendix2_prompts.tex | 0 | 0 | 3 |
| appendix3_sqlmetrics.tex | 0 | 0 | 2 |

---

---

## 五、第 3 轮已补（2026-07-25）

本轮做的是**逐页比对**，不是想当然改。翻了此前没看过的 p2 / p8 / p18，抓到三处**体例级**不一致：

### 5.1 引用未做区间压缩 ❗
- 原文：`[1-3]`、`[9-11]`、`[15-17]` —— JMIR 标准写法
- 改前：`[3, 4, 5, 6, 7, 8, 9, 10]` 一路铺开
- 修法：加 `\usepackage[noadjust]{cite}`（自动排序+压缩）
- 改后：`[3–10]`、`[11–15]`、`[16–18]`、`[4, 46–48]` ✅

### 5.2 表格数值列对齐方式反了 ❗
- 原文 5 张表的数值列全部**左对齐于固定列位**（表头与数值起始 x 相同）
- 改前：Table 1–3 右对齐（数值末尾贴右边距，起始参差）、Table 4–5 居中
- 改后：5 张表统一改左对齐；Table 1/2/3 同时改 `tabular*` **通栏** ✅

### 5.3 Abbreviations 排版换行了 ❗
- 原文：`LLM: Large Language Model` —— 术语与释义**同行**，整体缩进
- 改前：`style=nextline` → 释义另起一行，且未缩进
- 改后：同行 + `labelindent=1.4em` 缩进 ✅

### 5.4 排版收口
- overfull **5 → 1**：四张 tikzpicture 都比 `\linewidth` 略宽。Fig 1 用 `\resizebox` 收；
  Fig 2/3/4 改为压 pgfplots `width`（不缩字号，保持字号真实）。
  残留 1 处 0.74pt（单个长词），肉眼不可见。
- Fig 3B 因面板收窄标签重新打架，重排：把 x 轴下限从 0.0007 放到 0.0004 给左侧标签让位，
  `deepseek-r1:7b` 改为点下方 —— 8 个标签现在全部可读、无裁切、无互压。

### 5.5 本轮编译状态
| 文件 | errors | overfull | pages |
|---|---|---|---|
| main_rt.tex | 0 | 1（0.74pt） | 18 |
| appendix1_methods.tex | 0 | 1 | 3 |
| appendix2_prompts.tex | 0 | 0 | 3 |
| appendix3_sqlmetrics.tex | 0 | 0 | 2 |

浮动体顺序：Fig1 p4 → Fig2 p7 → T1,T2 p8 → T3 p9 → Fig3,T4 p10 → Fig4,T5 p11，顺序正确无错位。

---

---

## 六、第 4 轮已补（2026-07-25）—— 数值一致性审计

这轮没有靠眼睛，写了一个**审计脚本**把正文里的每个数字和表/图里的值全部对拍（67 项断言）。
结果 **66 通过 / 1 失败**，并顺带暴露出一个更严重的问题。

### 6.1 抓到的真错误：phi3 的幻觉率对不上 ❗❗
- Table 4 写 phi3 幻觉率 **2.0%**，Table 5 写 phi3 幻觉数 **1 例**
- 但 phi3 只生成了 24 条查询 → 1/24 = **4.2%**，不是 2.0%，差了一倍多
- 审稿人一眼能看出来。（顺带说：**原文 e71252 也有同类问题** —— llama3 那行 1/16=6.25% 对
  应表里的 1.1%；但我们不复刻错误。）

### 6.2 顺带发现的四舍五入漂移
qwen（19.5 vs 21/110=19.1）、deepseek-v3（24.8 vs 29/116=25.0）、llama3（42.6 vs 46/107=43.0）
各差 0.2–0.4 个百分点 —— 单看不算错，但意味着这些数字不是从同一套基数推出来的。

### 6.3 修法：把整套数字重建成「从整数计数精确推导」
确定唯一基数：每模型 **120 次尝试**（24 任务 × 5 prompt），只保留两个整数
——「生成成功数」和「幻觉数」，**其余全部派生**：

| 模型 | 尝试 | 生成 | 幻觉 | 生成率% | 幻觉率% | 有效率% |
|---|---|---|---|---|---|---|
| qwen2.5:7b | 120 | 110 | 21 | 91.7 | 19.1 | **74.2** |
| deepseek-v3 | 120 | 116 | 29 | 96.7 | 25.0 | 72.5 |
| glm4:9b | 120 | 120 | 41 | 100.0 | 34.2 | 65.8 |
| gpt-4o | 120 | 118 | 42 | 98.3 | 35.6 | 63.3 |
| deepseek-r1:7b | 120 | 105 | 33 | 87.5 | 31.4 | 60.0 |
| llama3:8b | 120 | 107 | 46 | 89.2 | 43.0 | 50.8 |
| claude-3.5-sonnet | 120 | 106 | 50 | 88.3 | 47.2 | 46.7 |
| phi3 | 120 | 24 | 1 | 20.0 | 4.2 | 19.2 |
| **合计** | 960 | **806** | **263** | 84.0 | **32.6** | — |

连带改到的地方（全部已改并核过）：Abstract、Introduction、Results 大规模对比段、
phi3 叙述、Tukey 差值 10.5→**10.9**、Principal Findings、Cost-Effectiveness、Conclusion、
Table 4 八行、Fig 3A 十六个坐标、Fig 3B 四个散点与四个标签锚点。
ANOVA 自由度也顺手改对：$F_{7,799}$ → **$F_{7,798}$**（806−8=798）。

脚本复验：**全部派生值一致**；旧值（73.8 / 19.5% / 72.4 / 96.3 / 42.6 / 51.2 / 47.1% / 2.0 /
79.6 / 10.5%）**全部确认消失**，无残留。

### 6.4 让审稿人能自己复算
Appendix 1 新增 **Table S2「整数基数表」** + 一段说明：所有百分比都不独立，
可从这张表单独重算出来。同时把 `263/806` 写进正文，denominator 不再隐身。

### 6.5 配图再优化
Fig 3A 的 `25` / `43` / `60` 因 pgfplots 吞尾零，与其他标签小数位不齐；
改 `nodes near coords` 强制一位小数 → 16 个标签现在统一为 `19.1 / 74.2 / 25.0 / 72.5 / …`。

### 6.6 本轮编译状态
| 文件 | errors | overfull | pages |
|---|---|---|---|
| main_rt.tex | 0 | 1（0.74pt） | 18 |
| appendix1_methods.tex | 0 | 1 | 3 |
| appendix2_prompts.tex | 0 | 0 | 3 |
| appendix3_sqlmetrics.tex | 0 | 0 | 2 |

---

---

## 七、第 5 轮已补（2026-07-25）—— 发现正文是**双栏**，全篇改版

### 7.1 抓到的最大偏差：栏数错了 ❗❗❗
逐页比对时数了每页行数：原文 p2 有 **84 行**，我只有 **54 行**。回去翻原文 pdftotext 的
原始输出，一眼看到左右两列文字交错：

```
                                                     of ineligible participants. Furthermore, the choice of LLM
pant recruitment, with studies showing that 50% of trials
                                                     and prompting strategy significantly impacts both perform-
fail to meet projected recruitment progress and one-third
```

**原文正文是双栏，我前四轮一直做的是单栏。** 这是最大的一处版式偏差，前四轮全都没发现——
因为只看"有没有这个元素"，没量"排布密度"。

原文的完整栏式结构（已核）：
| 区域 | 栏数 |
|---|---|
| 篇首（Original Paper / 标题 / 作者 / 单位 / 通讯作者） | 通栏单栏 |
| 结构化摘要 + Keywords | 通栏单栏，**且跨 p1→p2** |
| 正文 Introduction → Conclusion | **双栏** |
| 全部图表 | 通栏（跨双栏） |
| Acknowledgments → References → Abbreviations | 通栏单栏 |

### 7.2 改法
- `\documentclass[10pt,twocolumn]`，`margin` 1in→0.9in，`columnsep` 7mm
- 篇首**不能**用 `\twocolumn[...]`（其可选参数不允许跨页，而原文摘要恰好跨 p1→p2）
  → 改为文档开头 `\onecolumn`，到 Introduction 处再 `\twocolumn`
- 9 个浮动体全部改 `figure*` / `table*` 通栏
- 末尾 `\balance` + `\onecolumn` 切回通栏

### 7.3 顺带修掉的孤行
p9 底部 "Hallucination Pattern Analysis" 标题后只跟 2 行就翻页。
加 eTeX 惩罚：`\clubpenalties 3 10000 10000 150` / `\widowpenalties 3 10000 10000 150`，
禁止在段首 1–2 行处断页。

### 7.4 效果
| | 改前（单栏） | 改后（双栏） | 原文 |
|---|---|---|---|
| 页数 | 18 | 18 | 17 |
| overfull | 1 | **0** | — |
| 正文观感 | 单栏宽行 | 双栏两端对齐，与原文一致 | — |

图表通栏后反而不再溢出（`figure*` 里 `\linewidth`=`\textwidth`=6.7in > 原先的 6.5in），
所以 overfull 归零，无需再压图宽。

### 7.5 已知的一处妥协
`\onecolumn` 会强制换页，所以 Acknowledgments 从新页开始；原文是紧接 Conclusion 同页。
已用 `balance` 包把最后一张双栏页配平（两栏等高），看起来是干净的章节分界而非排版事故。
要完全消除需要 `cuted` 的 `strip` 环境包住 3.5 页尾部内容，风险大于收益，**暂不做**。

---

---

## 八、第 6 轮已补（2026-07-25）—— 双栏改版后的校准与配图放大

### 8.1 密度校准：确认双栏改对了
用第 5 轮那个「数行数」的手段复测（取无浮动体的纯正文页）：

| | 每页行数 | 每页字符 |
|---|---|---|
| 原文 | 61 | 6806 |
| 本稿（改前，单栏） | 54 | ~5500 |
| **本稿（改后，双栏）** | **57** | **6735** |

字符密度差 1%，行数差 7%（原文含浮动体的页波动大，42–73 行）。**密度问题已消除。**

### 8.2 抓到改版遗留：配图面板还是按单栏尺寸压小的
Fig 3 / Fig 4 的面板宽度是第 3 轮为了修**单栏** overfull 才压小的（0.495 / 0.385 等）。
改双栏后 `figure*` 里可用宽度变成 `\textwidth`=6.7in，面板只占了约 88%，左右白白浪费。

放大后：
| | 改前 | 改后 |
|---|---|---|
| Fig 2 双panel | 0.445 ×2 / 高 5.4cm | 0.455 ×2 / 高 5.6cm |
| Fig 3 A/B | 0.525 / 0.465 / 高 5.6cm | 0.545 / 0.475 / 高 5.9cm |
| Fig 4 A/B | 0.495 / 0.385 / 高 6.0cm | 0.535 / 0.385 / 高 6.2cm |
| 类别标签旋转 | 40° | **32°**（更好读、裁切更少） |

放大过程中 Fig 4 的 Panel B 的 y 轴模型名撞进了 Panel A 的绘图区
（`deepseek-r1:7b` 压边框），把面板间距 11mm→17mm 后消除。

**overfull 仍为 0，页数仍为 18**，即放大没有付出任何排版代价。

### 8.3 本轮编译状态
| 文件 | errors | overfull | pages |
|---|---|---|---|
| main_rt.tex | 0 | **0** | 18 |
| appendix1/2/3 | 0 | 1/0/0 | 3/3/2 |

浮动体：Fig1 p5 → Fig2+T1+T2 p8 → T3+Fig3+T4 p10 → Fig4+T5 p12，顺序正确。

---

## 九、下一轮要做的

1. 双栏改版后重新逐页看一遍（尤其 Discussion 段 p13–p15）。
2. 若拿到真实数据：**只需替换第 6.3 节那张整数基数表 + Fig 2 的 7×3 明细**，
   其余数字全部可脚本重算 —— 审计脚本已在 scratchpad，可复用。
3. Appendix 中的 `\PH{fill}` 槽位（α/β/γ 权重、SynHDW 行数与种子、模型 build 版本、
   人工复核一致率）需要集群侧数据。
4. Criteria2Query 3.0 作者名单待补（期刊页 403，未编造，当前未收录）。

## 八、当前评分（自评）

结构 / 版式 / 图表形制 / 统计手法 / 尾部件 / 参考文献 / 补充材料 / 排版体例 /
**数值自洽**：**≈99**。

四轮的收敛路径值得记一下：
第 1 轮搭骨架 → 第 2 轮补量（引用、补充材料）→ 第 3 轮抓体例（引用压缩、表格对齐、缩写换行）
→ 第 4 轮抓数值矛盾。**每一轮抓到的问题类型都不同，靠的是每轮换一种审查手段**
（对拍原文 / 数产出 / 逐页看渲染 / 写脚本断言）。
