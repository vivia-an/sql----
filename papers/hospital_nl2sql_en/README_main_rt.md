# main_rt.tex — 交接说明

对标复刻 JMIR Med Inform 2025;13:e71252，内容为本院 NL2SQL 工作。
26 轮迭代，`main.tex` 是早先的单栏草稿，**投稿走 `main_rt.tex`**。

---

## 编译

本机 TeX Live 2013 缺 pgfplots，已装到 `/root/texmf`（pgf 3.1.5b + pgfplots 1.16，
取自 TL2019；最新版 pgf 与 TL2013 内核不兼容）。换机器需重装。

```bash
pdflatex main_rt.tex && pdflatex main_rt.tex     # 跑两遍解引用
for f in appendix1_methods appendix2_prompts appendix3_sqlmetrics appendix4_miclaim; do
    pdflatex $f.tex
done
```

当前：main_rt 18 页 / 附录 3·3·2·3 页 / 全部 0 error / 0 overfull。

## 改完必跑的两个检查器

```bash
python3 verify_numbers.py     # 117 断言：论文与附录的每个数 vs DATA_FILL_SHEET.md
python3 verify_structure.py   #  50 检查：结构件、截断、空白页、引用、交叉引用、缩写
```

两者都做过负向测试（注入缺陷确认能抓到）。**不要只看 pdflatex 的 0 error** ——
本项目里有两次整节内容被静默删除，编译日志全程干净。

---

## 文件

| 文件 | 是什么 |
|---|---|
| `main_rt.tex` | 投稿正文 |
| `appendix1_methods.tex` | 补充材料 1：Figure S1 详细架构、处理流程、任务集表 S1、**整数基数表 S2**、幻觉检测算法 |
| `appendix2_prompts.tex` | 补充材料 2：六个管线 prompt 全文 + 五种策略指令体 |
| `appendix3_sqlmetrics.tex` | 补充材料 3：72 条专家评分条目全表 |
| `appendix4_miclaim.tex` | 补充材料 4：MI-CLAIM / MI-CLAIM-GEN 完成版清单 |
| `DATA_FILL_SHEET.md` | **数值唯一真值源**。改数据改这里，然后跑 verify_numbers |
| `DATA_FILL_SHEET_2.md` | 待补两组实验的填写表（TO-CONFIRM 弃权质量、A/B/C/D 消融） |
| `verify_numbers.py` / `verify_structure.py` | 两个检查器 |
| `REPLICATION_SCORECARD.md` | 复刻记分卡 96/100，逐项依据与扣分理由 |
| `FIGURE_SCORECARD.md` | 配图评分 9.7/10，八项标准 + 历轮改动动因 |
| `SUBMISSION_REVIEW.md` | 模拟审稿：加权 7.6/10，Major revision，接收概率 55–65% |
| `REVIEW_READINESS.md` | 投稿就绪度分维度评估 + 审稿人最可能提的意见 |
| `REPLICATION_REVIEW_e71252.md` | 逐轮复刻评审日志 |
| `main.tex` 及其余 md | 早先单栏草稿与前期分析，保留备查 |

---

## 数值骨架（改数据前必读）

模型侧所有百分比都从**八对整数**推导，不要手改派生值：

```
每模型 120 次尝试（24 任务 × 5 策略）
生成率 = 生成成功 / 120
幻觉率 = 幻觉数 / 生成成功
有效率 = 生成率 × (1 − 幻觉率) = (生成成功 − 幻觉数) / 120   ← 二项比例，可给 Wilson CI
```

改 `DATA_FILL_SHEET.md` 的 YAML 后，Table 4、Table 5、Figure 3、Figure 4、
附录表 S2 以及正文里的合并率/自由度/类别占比全部需要同步 —— `verify_numbers.py`
会逐项指出哪里没跟上。

---

## 投稿前待办

1. **两组实验数据** — 见 `DATA_FILL_SHEET_2.md`。补齐后评审分 7.6 → 8.2–8.5。
   A 组（TO-CONFIRM 弃权质量）**不需重跑模型**，只需对已有 960 条输出做人工判定。
2. **57 处红色占位符** — 作者、单位、IRB 号、仓库 URL、基金、期刊字段、
   两个 intake 统计、补充材料文件体积。搜 `\PH{` 定位。
3. **附录转 DOCX** — 本机无 pandoc/libreoffice。JMIR 也接受 PDF 附录。
4. **Criteria2Query 3.0 作者名单** — 期刊页 403 未能核到，未编造，当前未收录。

## 已知取舍（不建议改）

- **18 页 vs 原文 17 页**：尾部件另起一页。`cuted` 的 `strip` 能做到同页转通栏，
  但在本文档上会**静默吞掉整节内容**（试过两次，两次都吞）。宁可差一页。
- **Fig 1 / Fig S1 节点内 5pt**：低于印刷下限，但放大会撑破流程图版面。
  期刊若明确要求 ≥6pt，需重新设计节点尺寸。
- **正文比原文长 5–9%**：多出来的主要是 Limitations 里披露的四条 MI-CLAIM 缺口，
  删掉能换复刻分但会丢投稿分。
