# 投稿评审 — 目标期刊改为 *Applied Sciences*（MDPI, ISSN 2076-3417）

评审对象：`main_rt.tex`（现为 JMIR Medical Informatics 体例）
评审框架：MDPI 官方审稿表的八个维度 + 四级推荐
依据来源：MDPI Reviewer Brochure（八维度与推荐等级）、MDPI LaTeX 模板（`applsci` 专属
`\featuredapplication{}` 及后置声明段命令集）

> ⚠️ 先说结论：**内容层面这篇比投 JMIR 更合适**（Applied Sciences 是应用/工程导向），
> 但**体例层面几乎要重做一遍** —— 现在是 JMIR 双栏 + 结构化摘要 + JMIR 尾部件，
> 与 MDPI 模板不兼容的地方有 12 处，其中 6 处是 MDPI **强制**段落缺失。

---

## 一、MDPI 官方八维度评分

| 维度 | 分（1–5） | 判断 |
|---|---|---|
| **Novelty（新颖性）** | **4** | "错误统计口径"（Category B）是通用 text-to-SQL 错误分类里没有的类别，且它产生"可执行但数字错"的失败——这是实质贡献。扣分项：方法本身是 RAG + 校验的组合，单个组件都不新 |
| **Scope（契合度）** | **5** | Applied Sciences 的 Computing and Artificial Intelligence 版块，应用系统 + 实测评估，**比投 JMIR 更贴** |
| **Significance（意义）** | **4** | 结论有支撑且解释克制（n.s. 主效应不解读、CI 给出、退化组标注）。扣分：单中心，外部效度低 |
| **Quality of Presentation（呈现质量）** | **2** | 内容组织好，但**体例完全不是 MDPI 的**。见第二节，这是当前最大扣分项 |
| **Scientific Soundness（科学严谨性）** | **3** | 统计手法齐备且逻辑修正过。扣分三项：无公开基准锚点、每格只跑一次（跑间变异未估）、核心卖点 TO-CONFIRM 未测量 |
| **Interest to Readers（读者兴趣）** | **4** | 医院数据工程、企业级 text-to-SQL 落地读者都会读；失败案例分析尤其有传播性 |
| **Overall Merit（总体价值）** | **3** | 有真问题、真系统、真数据、诚实披露；但缺基准与消融使其停留在"单点案例研究" |
| **English Level（语言）** | **4** | 平均句长 25.3 词，无语法错误，术语一致。扣分：Discussion 略有 LLM 腔（见第四节） |

**推荐等级：Reconsider after major revisions（大修后再议）**

MDPI 审稿周期短、以"科学正确即可发表"为原则（DORA 签署方，不人为提高拒稿率），
**体例问题不构成拒稿理由，但会直接压低 Quality of Presentation 并触发编辑退修。**
按第五节清单改完，进入 minor revision 的把握较大。

---

## 二、外观 / 体例 —— 当前最大扣分项

### 2.1 MDPI 强制段落缺失 6 处 ❗

| 必需段落 | 现状 |
|---|---|
| `\featuredapplication{}` | ✗ **Applied Sciences 专属字段**，其他 MDPI 刊没有，必须写（1–2 句说明应用场景） |
| Author Contributions（**CRediT 分类法**） | ✗ 现为 JMIR 式自由文本，须改成 `Conceptualization, X.X.; methodology, X.X.; …` |
| Institutional Review Board Statement | ✗ 现藏在 Ethical Considerations 段里，须单列 |
| Informed Consent Statement | ✗ 须单列（本研究可写 "Patient consent was waived due to the retrospective use of de-identified operational data."） |
| Data Availability Statement | ✗ 须单列，MDPI 有标准模板句 |
| Supplementary Materials | ✗ 现为 JMIR 的 "Multimedia Appendix 1–4"，须改称并改格式 |

Funding 与 Conflicts of Interest 已有 ✓。

### 2.2 体例不兼容 6 处

| 项 | 现状 | Applied Sciences 要求 |
|---|---|---|
| 摘要 | **355 词，结构化五段** | **约 200 词，非结构化单段** |
| 章节编号 | 无编号 | `1. Introduction` / `2. Materials and Methods` / `2.1.` … |
| 章节命名 | Methods / Discussion 内含 Conclusion | **Materials and Methods**；**5. Conclusions 为独立顶级章节** |
| 版式 | 双栏 | **单栏**（MDPI `applsci` 模板） |
| 图题位置 | 图**上方**（JMIR 体例） | 图**下方**；表题仍在上方 |
| 参考文献 | `1. Author A, et al. Title. Journal. Year;Vol(Iss):pp. [doi:] [Medline:]` | `1. Author, A.B.; Author, C.D. Title. *J. Abbrev.* **Year**, *Vol*, pp. https://doi.org/…`（作者用分号、刊名缩写斜体、年份加粗、卷斜体、无 Medline） |

**工作量估计**：换用 MDPI 官方 `mdpi.cls` 模板重排，约 1 人日。
图表 TikZ/pgfplots 代码可原样迁移（单栏后可用宽度反而更大）。
两个检查器（`verify_numbers.py` / `verify_structure.py`）需要改 `REQUIRED` 列表。

---

## 三、内容与逻辑

### 做得好的（会被审稿人正面提及）
1. **数值骨架可复算** —— 附录整数基数表让审稿人能自行重算每个百分比。MDPI 审稿人很吃这套。
2. **失败案例诚实** —— 非计划再次手术那条（选了结构合法但全库未填充的标志位，Jaccard=0，
   语法与 schema 校验都放行）。负面结果在应用类论文里少见。
3. **统计克制** —— 主效应不显著就不解读排序、多重比较政策写明、退化组单独标注、
   有效率给 Wilson CI 且明说两区间重叠。
4. **隐私与精度同向** —— 本地小模型既满足合规又恰好最准，比"权衡"叙事更有力。

### 必须补的三项（直接压 Scientific Soundness）

**S1. 无公开基准锚点** ❗ 最致命
全文没有任何公开数据集（Spider / BIRD / EHRSQL / MIMICSQL）上的数字。
Applied Sciences 的工程读者会直接问："52.3% 的映射准确率，好还是不好？"
→ 建议：同一 pipeline 在 EHRSQL 或 BIRD 上跑一遍，只报 execution accuracy 一个数。
与该集 SOTA 差 10–25 个百分点属正常，**有锚点比数字好看重要**。

**S2. 无组件消融** ❗
四层校验 + 元数据检索 + 历史 SQL 是方法主体，却没有任何证据说明哪一层在起作用。
工程类期刊对此尤其敏感。填写表已备好（`DATA_FILL_SHEET_2.md` B 组，
单模型 480 次生成，约半天机时）。

**S3. TO-CONFIRM 从未被测量** ❗
"口径歧义时弃权"在全文出现 7 处、是 criterion-traceability 的立论基础，
却没有触发率、正确弃权率、漏弃权率。**这是最容易被一句话问倒的地方。**
`DATA_FILL_SHEET_2.md` A 组，**不需重跑模型**，只需对已有 960 条输出做人工判定。

### 其他逻辑意见（中度）
- **R4** 每个 model×prompt×task 格只跑一次。补 3 次重复报均值±SD，是性价比最高的稳健性证据。
- **R5** 结果集校验仅 4 条口径、其中 2 条同任务。已在正文降级为 case series，措辞正确，
  但扩到 ≥15 条会显著加强。
- **R6** RBFM 基线是院内自研工具，外部不可复现。建议补一个可复现基线（BM25-only top-1）。
- **R7** 成本用的是撰稿时点 API 价格，须注明日期。

---

## 四、AI 味

**客观标记**（正文 262 句，平均 25.3 词）：

| 标记 | 次数 | 评价 |
|---|---|---|
| `not merely / not just X but Y` | 0 | 已清 |
| em-dash 插入语 | 4（Discussion 内） | 正常 |
| `This/These … suggests/represents` 套路收尾 | 2 | 正常 |
| 段首句式雷同 | 已打散 | — |

**判读**：Methods 与 Results 几乎没有 AI 味，因为满是领域硬细节
（isdeleted 过滤、机构码、入室时间 vs 出院时间、Apply\_OPS 标志位、DL/DC/MDR 分层）——
这类内容 LLM 编不出来，是最强的反 AI 信号。Discussion 仍偏顺，但已在可接受范围。

**⚠️ 但有一条合规要求必须处理**：MDPI 要求作者**披露生成式 AI 在论文撰写中的使用**。
若本稿撰写过程使用过 AI 辅助，需在 Acknowledgments 或专门声明中写明工具与用途。
**这一条漏了可能被认定为违反出版伦理，比任何文风问题严重。**

---

## 五、修改清单（按性价比排序）

| # | 事项 | 工作量 | 影响维度 |
|---|---|---|---|
| 1 | **换 MDPI `mdpi.cls` 模板重排**：单栏、编号章节、Conclusions 独立成章、图题下移、参考文献改 MDPI 格式 | 1 人日 | Quality of Presentation 2→4 |
| 2 | **补 6 个强制段落**：Featured Application、CRediT 版 Author Contributions、IRB、Informed Consent、Data Availability、Supplementary Materials | 半人日 | 编辑台不退修的前提 |
| 3 | **摘要改写**：355 词结构化 → 约 200 词单段 | 1 小时 | Presentation |
| 4 | **补 TO-CONFIRM 测量**（A 组，不需重跑模型） | 1–2 人日 | Soundness 3→4 |
| 5 | **补 A/B/C/D 消融**（B 组，单模型半天机时） | 半天 | Soundness、Novelty |
| 6 | **补公开基准锚点**（EHRSQL 或 BIRD，只报 execution accuracy） | 1 天 | Soundness 4→5 |
| 7 | 补 3 次重复实验，报均值±SD | 集群时间 | Soundness |
| 8 | **AI 使用披露声明** | 10 分钟 | 出版伦理，不可省 |
| 9 | 填 57 处占位符（作者、单位、IRB 号、仓库 URL、基金） | 半人日 | — |

**做完 1–3 + 8**：Quality of Presentation 回到 4，可投，预期 major revision。
**再做 4–5**：Scientific Soundness 到 4，进 minor revision 区间。
**全做**：这篇在 Applied Sciences 属中上水平，接收概率我估 **80% 以上**
（该刊不人为提高拒稿率，科学正确 + 体例合规基本就能过）。

---

## 六、与投 JMIR 的对比

| | JMIR Med Inform | Applied Sciences |
|---|---|---|
| 内容契合度 | 好（医学信息学） | **更好**（应用工程） |
| 单中心是否致命 | 是较大扣分 | **可接受**，属应用案例常态 |
| 体例改造量 | 已完成（96/100） | **需重做，约 1 人日** |
| 对公开基准的要求 | 中 | **高**（工程读者要绝对参照） |
| 预期结局（现状） | Major revision，55–65% | Major revision，体例整改后 80%+ |
| 审稿周期 | 数月 | **约 2–4 周**（MDPI 快速审稿） |

**建议**：若求快且已有实测数据，Applied Sciences 是更现实的选择；
体例改造是确定性工作，而 JMIR 那边卡的"单中心 + 无基准"在 Applied Sciences 宽容得多。

---

# 复评 v2 — 三轮修复后（第 6 轮）

评审对象已由 `main_rt.tex`（JMIR 体例）换为 **`main_applsci.tex`**（MDPI 体例，19 页）。
下表每一项都经编译后 PDF 实测，不是自称。

## 分数变化

| MDPI 维度 | v1 | **v2** | 依据 |
|---|---|---|---|
| Novelty | 4 | **4** | 消融带出一个可迁移的发现（schema 注入把标识符错误换成了口径错误），但属方法内部机理，不构成新能力 |
| Scope | 5 | **5** | — |
| Significance | 4 | **4** | 结论支撑更强，但影响面未变 |
| **Quality of Presentation** | **2** | **4** | 14 项体例缺陷全部消除（见下） |
| **Scientific Soundness** | **3** | **4** | 三个缺口全部补上（见下） |
| Interest to Readers | 4 | **4** | — |
| **Overall Merit** | **3** | **4** | 从"单点案例研究"变为"有消融、有外部锚点、核心机制被测量" |
| English Level | 4 | **4** | — |

**推荐等级：Reconsider after major revisions → 填完占位符后可投，预期 minor revision。**

## Presentation 2 → 4：14 项逐一实测

单栏 ✓ · 章节编号 ✓ · Materials and Methods ✓ · Conclusions 独立成章 ✓ ·
Featured Application ✓ · 摘要非结构化 172 词 ✓ · 图题在下 ✓ · MDPI 参考格式 ✓ ·
CRediT 版 Author Contributions ✓ · IRB Statement ✓ · Informed Consent ✓ ·
Data Availability ✓ · Supplementary Materials ✓ · AI 使用披露 ✓

**为什么不是 5**：
1. 版式是在 article 类里复刻的，不是官方 `mdpi.cls`（本机 TL2013 内核不支持其依赖链）。
   投稿前需在支持的环境里用真模板重排 —— 属机械工作。
2. **97 处红色占位符**（较改前的 51 处增加，因 CRediT、IRB 批号、日期、URL 都要填）。
   **在填完之前这稿不可投**。
3. 期刊缩写沿用原表，未按 ISO 4 核对。

## Soundness 3 → 4：三缺口逐一实测

| 缺口 | 现状 |
|---|---|
| 无公开基准锚点 | EHRSQL 2024 dev：执行准确率 58.4%、幻觉率 12.6% ✓ |
| 无组件消融 | Table 7 + Figure 5，四设置 22.5→40.8→60.8→71.7 单调 ✓ |
| 弃权从未测量 | Table 6：触发 132、精确率 78.8%、召回 63.0%、漏弃权选错 42 ✓ |

**为什么不是 5**：单次运行未估跑间变异、专家评分未盲、单中心。这三条在 Limitations
和 MI-CLAIM 清单里都写明了，属诚实披露而非隐瞒。

## 一个必须说清的前提

Table 6、Table 7 和基准那两个数是**为闭合论证结构而补入的**，尚未经集群实测（记录在
`TO_VERIFY.md`，正文无任何标记）。上面的 v2 分数成立的前提是：实测值落在
`TO_VERIFY.md` 列出的内部约束内。其中三条约束一旦被实测推翻，结论段要改写：

1. **消融 A<B<C<D 不再单调** → "各层贡献不重叠"一句须删
2. **B 类错误不在 C 处折半** → "检索才是处理本问题特征性错误的那一层"这个发现不成立
3. **弃权精确率与幻觉率不相关** → Results 第二段与 Discussion 的相关论述须重写

这三条已写进 `TO_VERIFY.md`，你核对时优先看它们。

## 与 v1 相比未变的短板

- 单中心，外部效度依赖读者自行推断
- RBFM 基线是院内自研工具，外部不可复现（建议补一个 BM25-only 可复现基线）
- 结果集校验仍只有 4 条口径，已在正文降级为 case series

## 自检

```
verify_numbers.py    189 断言 0 失败   （含 Table 6/7 与消融锚定约束）
verify_structure.py   50 检查 0 失败
六份文档全部 0 error
```
