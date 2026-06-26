# 最佳对照分析 · 本文 vs Liu W 等 (medRxiv 2025)

**对照论文**：Liu W, Qu B, Mallya P, et al. *Optimizing an LLM-Based Clinical Data Querying System
Using Metadata Enrichment and Task Decomposition.* medRxiv 2025（本文引为 `metaclin2025`）。
选它的理由：同为"临床数据 + LLM text-to-SQL + 元数据 + 任务分解 + 检索 + 自纠"的应用型系统论文，几乎逐项对应，是最干净的 1:1 对照。

## 对照论文实查要点（来源：medRxiv 题录/摘要级检索；正文 PDF 403 未取全）
- 场景：自托管开源 LLM，严格隐私/安全约束下查真实临床注册库 **GWTG-HF（心衰）**。
- 方法：metadata enrichment + query decomposition + **hybrid retrieval** + **SQL self-correction**。
- 评测：**600 条查询**，按 **1/2/3 字段复杂度分层**，**execution-based** 验证。
- 结果（真实测得）：1 字段 88.0%→94.5%；3 字段 10.0%→82.0%。
- 真实用户层：数据科学家试用，质性发现（编码变量 / 临床歧义 / 多步推理）。

## 叙事对比
- 共同：临床自然语言取数痛点；元数据 + 分解 + 检索 + 自纠四件套。
- 对照独特：**隐私驱动（自托管开源 LLM）**、复杂度分层、真实用户试用。
- 本文独特：**口径可追溯**、四层校验错误归因、错误类型学（映射文献）、四类效度 Threats to validity。

## 实验对比（本文吃亏处）
| 维度 | 对照(metaclin2025) | 本文 |
|---|---|---|
| 数据规模 | 600 条 | 30 条 |
| 数据来源 | 具名真实库 GWTG-HF | 脱敏医院任务（未具名） |
| 复杂度分层 | 1/2/3 字段 | （R-restart 已补：Simple/Moderate/Complex） |
| 验证 | execution-based(EX) | 可执行率 + 人评（部分自评） |
| 数字 | 真实测得 | 示意（未实测） |
| LLM | 自托管开源（隐私） | （R-restart 已改：本地开源、数据不出院） |
| 真实用户测试 | 有 | 无 |

## 本文不足（按严重度 + 改法）
1. **数字未实测（P0，作者侧）**——根本项，投稿前必补。
2. **隐私叙事 vs 云端 LLM 矛盾**——✅ R-restart 已修（§4.4 改自托管开源 + §Ethics 数据不出院）。
3. **缺复杂度分层**——✅ R-restart 已补 Table（Simple/Moderate/Complex，示意值）。
4. **缺真实用户/落地测试层**——TODO：加小规模真实用户试用 + 质性反馈小节。
5. **关键指标偏主观（人评/自评）**——TODO：提 EX 为主指标、扩大抽样、引入盲评。
6. **数据集未具名/不可获取**——TODO：补任务集可得性声明/示例集。
7. **样本量 30 太小（对照 600）**——TODO：扩到 ~100+、报置信区间（已在 Threats to validity 提到，需落实）。

## 可直接落到 main.tex 的后续（不依赖作者真实数字）
- 加 "Real-world user testing"（质性）小节（#4）
- 把 EX/结果一致率提为主指标的措辞（#5）
- 任务集可得性声明（#6）
