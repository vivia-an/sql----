# PERSPECTIVE_TREE · 视角方向树（医学信息学应用/系统型 · 英文 SCI）

> 取叶子规则：按完成度阶梯 P0→P4，从最高优先级且未达标层取**未做**叶子；同层先取离"可投"最近的。做完标 `[✓done Rxx]`。

## H-A clinical motivation（临床/运营动机）
- [ ] A1 用"人工写 SQL 的响应慢/口径不一致/经验难复用"三痛点开场，给量化或案例支撑
- [ ] A2 "lessons-learned / 可行性研究"框架（web 种子：ACI case-report 偏好）

## H-B framework novelty（框架新颖性）
- [✓done R7] B1 Discussion 加"三杠杆为何有效"机制段（grounding 降幻觉 / 分解使错误可定位 / 执行反馈闭环），引 RAG-结构化降幻觉 + 幻觉缓解综述
- [🟡R7] B2 四层校验 + 错误归因 已在 §2/§3.4 区别于 DIN-SQL 自纠；可再补"工程化"对比一句

## H-C evaluation rigor（评测严谨性）
- [✓done R1] C1 评测设计章节占位就位（任务集、A/B/C/D、指标、案例原型）
- [ ] C2 用 **STARE-HI 35 项**逐条核评测报告缺项（web 种子）
- [✓done R2] C3 指标可操作化：executable rate↔运行、result consistency↔EX、criterion-confirm↔abstention（写入 §4.3）

## H-D baseline positioning（基线定位）
- [✓done R2] D1 A/B/C/D=内部消融、非外部对比；Related Work 加 EHRSQL/EM-EX/两步RAG/epi-RAG/元数据临床查询定位
- [✓done R2] D2 为何不用公开基准（MIMIC-IV demo 等私有 schema/口径不可迁移）—— 写成方法论选择（§2 Positioning）

## H-E reproducibility（可复现性）
- [🟡R3] E1 复现段已对齐 MI-CLAIM/MI-CLAIM-GEN 六部分（study design/measures/population/baselines/examination/reproducible pipeline）；具体 LLM 版本+解码参数+检索配置仍占位（作者侧填）
- [ ] E2 Data/Code availability statement（合规范围内）

## H-F ethics & privacy（伦理与隐私）
- [✓done R1] F1 Ethics/IRB + 去标识化声明骨架已写入 §Ethics
- [ ] F2 正文示例逐一核查无真实患者信息

## H-G error analysis（错误分析）
- [✓done R4] G1 5 类错误学映射到文献既有分类（schema-linking/join/value/syntax），点明"时间口径混淆"为医院特化错误；引 survey + SQL-of-Thought（§5.1）
- [✓done R8] G2 偏差/混杂自查 → §7 Threats to validity 子节（construct/internal/external/conclusion 四类 + 缓解计划），引 validity 报告规范

## H-H generalizability（泛化性）
- [ ] H1 单中心→多中心的迁移性只进 Discussion 作 conjecture，不在结论主张

## H-I writing & English clarity（英文写作）
- [✓done R5] I1 一致性收口：LaTeX 破折号统一 `---`、删正文残留中文"口径"、术语统一为 "manual SQL authoring"（全文扫一遍，本就英文新写非直译腔）
- [✓done R9] I2 acronym 首现展开：摘要 RAG 展开、PACU 展开为 post-anesthesia care unit、统一美式拼写（favour→favor）；EM/EX/LLM/NL2SQL 首现已定义

## H-J figures（图）
- [✓done R1] J1 三图占位与说明就位（fig_pipeline/fig_results_AtoD/fig_error_taxonomy）
- [✓done R10] J2 三图全部可编译：fig_pipeline(TikZ)、fig_results(pgfplots 趋势)、fig_error(pgfplots 柱状)；后两图用示意数字，标 (illustrative)，作者换实测后更新坐标

## H-K patent alignment & novelty positioning（专利对齐）
> ⚠️ BLOCKER（R3 发现）：专利为老式二进制 `.doc`，本环境无 antiword/catdoc/libreoffice，读不出正文。
> 解锁需其一：①作者把专利另存为 .docx 或 .txt；②环境装上 `catdoc`/`antiword`/`libreoffice`。解锁前 K1–K3 挂起。
- [ ] K1 从专利 AJ2534335 提取架构/模块细节喂 Methods 与 pipeline 图、统一术语 〔挂起·待解锁〕
- [ ] K2 **红线**：专利含 RL、本文无 RL；专利有而论文未实现的机制不得搬入；RL 仅在 Related Work/Discussion 作"作者另一路线"区分
- [ ] K3 专利作自有在先成果显式引用，讲清论文增量，规避自我抄袭/重复发表

## H-M 写作策略（R17 起 · 自信顺写 / 目标刊 JMIR Med Inform / 缺陷后置）
- [✓done R17] M1 目标刊定 JMIR Medical Informatics；按其 IMRaD + 结构化 Discussion 组织
- [✓done R17] M2 Limitations/Threats 移出正文存 LIMITATIONS_PARKED.md（投稿前回插）
- [✓done R17] M3 Discussion 改 Principal findings + Comparison with prior work（自信）；去散落自我贬低
- [✓done R19] M4 段间过渡：R18 Introduction 补方法+Objective 桥接段；R19 Framework 补总起句(指向 Fig.1 + 小节导航)。Intro/Method 衔接已顺
- [✓done R20] M5 全文顺度通读：摘要/引言/方法/结果/讨论/结语连贯自信，重复度健康（criterion-traceable 等为主题词），无生硬过渡 → 无需改动
- [✓done R21] M7 图表增强（对标 JMIR e71252）：+tab:kb/tab:substruct/tab:verify/tab:compare + fig:example/fig:complexity，3图3表→5图7表（见 FIGURE_GAP_ANALYSIS.md）
- [✓done R22] M8 §4 指标形式化定义：可执行率/EX/字段一致/条件准确/人工修正 给公式（用 \mathbb{1} 指示函数），对标 e71252 严谨度
- [ ] M9 作者侧：真实数字+统计检验、数据集具名、UI 截图、多模型对比
- [ ] M6 投稿前：从 LIMITATIONS_PARKED.md 回插 Limitations 子节（勿忘）

## H-web 网络方向种子（每轮 web 重搜追加，来源去重）
- [ ] W1 STARE-HI：健康信息学评测报告 35 项规范 → 用于 §4/§5 自查（src: STARE-HI statement）
- [ ] W2 Downs & Black 27 项方法学质量清单 → 偏差/外部效度自查（src: PMC systematic-review）
- [ ] W3 Applied Clinical Informatics 的 "lessons learned" / case-report 写法 → 动机与讨论框架（src: ACI author instructions）
- [✓done R2] W4 EHRSQL-2024 Reliability Score（可答则对/不可答则弃答）→ 对应本文"待确认项=abstention"（src: EHRSQL 2024 overview）
- [✓done R2] W5 EM / EX（execution accuracy）标准指标 → 对齐 executable rate / result consistency（src: EHRSQL/Spider 线）
- [✓done R2] W6 MIMIC-IV demo 公开 EHR 基准 → §2 回答"为何不用公开基准"（src: EHRSQL 2024）
- [✓done R2] W7 medRxiv《用元数据优化 LLM 临床数据查询系统》→ 最贴近在先工作，须引用并区分增量（src: medrxiv 2025.12）
- [ ] W8 SCARE: SQL 纠错与可答性分类基准 / 两步 RAG 生成 cohort → 备选，下一轮考查（src: arXiv 2511.17559 / 2502.21107）
- [✓done R3] W9 MI-CLAIM（Nature Medicine 2020, EQUATOR）临床AI建模最小报告清单 → §4.4 声明遵循（src: nature s41591-020-1041-y）
- [✓done R3] W10 MI-CLAIM-GEN（arXiv:2403.02558, 2024）生成式扩展 → §4.4 一并引用（src: arXiv 2403.02558）
- [✓done R4] W11 Text-to-SQL LLM 综述（arXiv:2408.05109）+ 通用错误分类学（schema-linking/join/value/syntax 主导）→ §5.1 映射（src: arXiv 2408.05109）
- [✓done R4] W12 SQL-of-Thought 引导式纠错 / execution-guided 生成 → 定位本文执行反馈闭环（src: arXiv 2509.00581）
- [✓done R6] W13 双向 schema-linking 检索（arXiv:2510.14296）+ RSL-SQL 召回/精确率权衡 → §3.3 定位本文加权召回，点明"历史SQL+abstention=精确率控制"（src: arXiv 2510.14296 / RSL-SQL）
- [ ] W15 LinkAlign（大规模多库 schema linking）/ SchemaGraphSQL / REaR 多表检索 → 备选，"未来工作:跨系统扩展"可引（src: arXiv 2503.18596 / 2505.18363 / 2511.00805）
- [✓done R5] W14 选刊候选：JMIR Medical Informatics（SCIE/IF 3.8/Q1 健康信息学/OA 快通）、JBHI "Trustworthy LLMs in Healthcare" 专刊 → 供作者定刊（src: medinform.jmir.org / embs.org jbhi）
- [✓done R9] W16 投稿附件规范（cover letter 讲贡献/无重复发表/利益冲突、graphical abstract、highlights、ORCID 通讯作者）→ 写入 SUBMISSION_CHECKLIST.md（src: JEM/ACS/AGU 投稿指南）
- [✓done R15] W17 最佳对照 metaclin2025 实查（自托管开源LLM/GWTG-HF/600条/1-2-3字段分层/EX/88→94.5·10→82/真实用户试用）→ 见 COMPARISON_metaclin2025.md（src: medRxiv 2025）

## H-L 对照驱动改进（R15 起，源自 metaclin2025 对比）
- [✓done R15] L1 隐私一致性：§4.4 改自托管开源 LLM、本地部署、数据不出院；§Ethics 加 on-premises 推理
- [✓done R15] L2 复杂度分层：§5 加 Table tab:complexity（Simple/Moderate/Complex × A/D，示意）
- [✓done R16] L3 §5 加 \subsection{Real-world use and qualitative feedback}（质性三主题，标 illustrative，引 metaclin2025）
- [✓done R16] L4 §4.3 EX/结果一致率提为 primary endpoint + 人评盲评(blinded to A–D)；"扩大抽样"属作者侧执行
- [✓done R16] L5 §4.1 任务集可得性声明（Supplementary Material，留 confirm）
- [ ] L6 样本量从 30 扩到 ~100+ 并报置信区间（作者侧执行，Threats to validity 已提）
