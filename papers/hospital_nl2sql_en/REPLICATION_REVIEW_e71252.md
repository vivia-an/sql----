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
| 参考文献 | 51 条，Vancouver + [doi:] [Medline:] | **24 条**，样式已对齐，按首次引用排序 | ⚠️ 缺量 |
| 补充材料 DOCX ×3 | 实体文件 | 仅列条目 | ⚠️ 未产出 |

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

## 四、下一轮要做的（按优先级）

1. **参考文献 24 → ~50**：文末已列出待补清单（MIMICSQL/TREQS、MedTS、BIRD、DAIL-SQL、
   MAC-SQL、Criteria2Query、Trial Pathfinder、LeafAI、Presto、BM25、Sentence-BERT、
   8 个模型卡、Landis&Koch、McNemar、Tukey、scipy、statsmodels）。补时必须按首次引用序插入。
2. **补充材料 3 份**（Supplementary methods / Prompt templates / SQL evaluation metrics）。
3. 5 处 overfull（≤17.6pt）微调断行。
4. 若拿到真实数据：整组替换第三节所有数值，并重算 Fig 2/3/4 的内嵌数据表。

## 五、当前评分（自评）

结构/版式/图表形制/统计手法/尾部件：**≈99**。
整篇完成度受两项拖累：参考文献 24/51、补充材料 0/3 —— 这两项不是复刻精度问题，是产出量问题，
补齐即可。
