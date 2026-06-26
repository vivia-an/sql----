# 图表/各部分 vs 范文 差距分析（2026-06-22）

## 对标范文（JMIR Medical Informatics）
- **e71252**（临床试验标准→OMOP SQL，严谨评测范式·主对标）：4 图（多 A/B 双面板）+ 5 表 + Discussion 现有系统对比表 + 统计检验（McNemar/ANOVA/Tukey/χ²）+ 补充材料含 prompt 模板。
- **e63216**（ICU-GPT 临床大数据抽取，系统演示范式）：8 图（工作流 + 4 UI 截图 + agent 流程 + 收益图）、0 表、定性结果、无对比表。

## 量对比
| | 改前 | 改后 | e71252 |
|---|---|---|---|
| 图 | 3 | **5** | 4 |
| 表 | 3 | **7** | 5 |

## 本轮已补（不依赖真实数字，均标 illustrative/示意）
1. ✅ Discussion 现有系统**特征对比表** `tab:compare`（Rule/templating · DIN-SQL · EHRSQL track · metadata+decomp · 本文 × Meta/Decomp/Hybrid/Exec-fb/Abstain/Criterion）。
2. ✅ 方法侧 3 表：`tab:kb`(知识库四类条目)、`tab:substruct`(SQL 五子结构×校验focus)、`tab:verify`(四层校验×典型错×反馈)。
3. ✅ 端到端 `fig:example` worked-example（NL→召回口径→子结构→校验抓错→to-confirm，脱敏示意）。
4. ✅ `fig:complexity` 复杂度分层柱状（A vs D，示意），与 `tab:complexity` 互补。

## 各部分薄弱点 & 状态
- Abstract：缺头条数字（示意所致，投稿前补）。
- Introduction：已补 hook+gap+objective（R18）。✓
- Related Work：原纯文字 → 现有 `tab:compare` 对比表。✓
- Methods：原文字过密 → 现 3 表 + worked-example，密度/可扫读改善。✓ 仍可：α/β/γ 给值（作者侧）。
- Experimental Setup：⚠️ 数据集未具名（作者侧）；指标无形式化公式（**下轮可补 EX/一致率定义**）；无统计检验设计（作者侧，数字真测后加）。
- Results：现 3 图（results 线 / 复杂度柱 / 错误柱）；⚠️ 无统计显著性、无"修好的错误"定性例（worked-example 已部分覆盖）。
- Discussion：JMIR 式 + 对比表。✓
- 总量：5图7表，达标。

## 仍属作者侧（无法自动做）
- 真实实测数字替换示意值 + 统计检验（McNemar/ANOVA 等）。
- 数据集具名/可得性细化。
- 系统 UI 截图（如走 e63216 演示风格）。
- 多模型对比（8 模型那种，需多模型实测）。
