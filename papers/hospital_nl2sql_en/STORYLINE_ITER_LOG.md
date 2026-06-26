# STORYLINE_ITER_LOG · 医院 NL2SQL 英文 SCI 改稿循环

## 锁定参数（2026-06-20 作者确认）
- 目标期刊：最快适合的 SCI（快通 SCIE 综合/应用档：IEEE Access / MDPI Applied Sciences·Electronics·Diagnostics·Healthcare / Sci Rep / Heliyon）。
- 执行总纲：**写作优先 / 方向驱动 / 实验不在本循环内（作者自办）/ 结果留作者占位 / 成稿判据=条理清晰逻辑通顺+占位可无歧义填入**。
- 数字性质：占位（illustrative），循环绝不替作者编/美化实测数字。

## Submission-Readiness Checklist（每轮更新勾选）
- [P0] 伦理/IRB + 数据去标识化声明 ………………………… ✅ R1 已起草（main.tex §Ethics）
- [P0] 评测设计章节完整 + 结果表/图占位口径自洽 ……… ✅ R1 已搭（§4 Setup + §5 Results 占位表）
- [P1] IMRaD 全节就位、结构化 Abstract、显式 Contributions、Related Work 骨架、三图占位 … ✅ R1 已搭
- [P2] 数字过出处闸门 / linchpin (a)–(f) / baseline 定位 / 可复现性 / 标注协议 …… 🟡 推进中（R2：baseline 定位+EHR Text2SQL 相关工作+指标可操作化已收口；可复现性/标注协议仍占位）
- [P3] 英文学术化 / 参考文献与图表格式按选定刊模板 / cover letter ……… ⬜ 未开始
- [P4] 打磨、叙事顺滑、审稿预答 ……………………………………… ⬜ 未开始

**当前完成度 ≈ 92%（形态可直接投稿，纯写作天花板已达）**：正文**零 `\PH` 占位**；数字/3 图/标注协议/复现配置/伦理声明/24 条参考文献全部补齐（数字为示意，留 `(illustrative)` 安全绳）。剩余**全为作者侧**（见 `SUBMISSION_CHECKLIST.md`）：①真实实测替换示意数字并删标记②核对配置/批件③选刊套模板④专利 .doc 解锁做 K⑤cover letter 等附件。→ 循环转**低频维持**，主要轮询专利解锁，等作者输入。
> 注：纯写作型加固已接近天花板；剩余 P0/P1 缺口多为作者侧（实测数字、选刊、专利解锁）。后续轮次将转入"诚实边界打磨 / 审稿预答 / 全文一致性复核"等细粒度收尾。

---

## R1 · 2026-06-21 · 视角方向：bootstrap + P0/P1（骨架与评测设计占位）
- **分析**：
  - web 重搜得到方向种子——STARE-HI（健康信息学评测报告 35 项）、Downs & Black 方法学清单、Applied Clinical Informatics 偏好的 "lessons learned" / case-report 框架。已加入 PERSPECTIVE_TREE 的 H-web 节。
  - 取叶子（完成度驱动，P0/P1 最高优先且全空）：先把 paper_en 目录、两份跟踪文件、story_en、main.tex 英文 IMRaD 骨架、结果表/图占位、伦理声明 bootstrap 出来。
- **二次评审**：
  - (a) 编数？结果表数字沿用中文稿示意值，但已用 `\textit{(illustrative — to be replaced by measured results)}` 标注，Abstract/Conclusion 不写硬百分比当成果 → 通过。
  - (b) linchpin？已在 §Limitations 写入单中心/小样本/人评/LLM 版本依赖/延迟代价；A/B/C/D 定位为内部消融非外部 baseline → 通过（待逐句收紧措辞）。
  - (c) 期刊口径？IMRaD 完整、含 Ethics/复现/标注协议骨架 → 形态达标；具体刊模板待 P3。
  - 结论：**通过**，可作为首轮成稿骨架。
- **改稿**：新建 `main.tex` / `story_en.md` / `figs/README.md`，初始化 `STORYLINE_ITER_LOG.md` / `PERSPECTIVE_TREE.md`。
- **下一轮建议方向**：P2 — 用 STARE-HI 35 项逐条核 §4/§5 缺项；细化 Related Work（healthcare Text2SQL / RAG-in-healthcare）；专利对齐（区分 RL 路线、写入在先披露引用）。

## R2 · 2026-06-21 · 视角方向：P2 baseline 定位 + EHR Text2SQL 相关工作 + 指标可操作化（D1/D2/C3）
- **分析**：
  - web 重搜命中核心相关工作：EHRSQL-2024 shared task（Reliability Score：可答则对/不可答则弃答 abstention）、EM/EX 标准指标、MIMIC-IV demo 公开基准、两步 RAG/epi-RAG over EHR、medRxiv《用元数据优化 LLM 临床数据查询系统》（最贴近在先工作）。新叶子 W4–W8 入树。
  - 取叶子（P2 最高优先、离可投近）：D1/D2 baseline 定位 + C3 指标可操作化。
- **二次评审**：
  - (a) 出处闸门：本轮不加结果数字 → 无编数；新引文按搜索来源，作者未知处用 `\PH{authors}` 不杜撰 → 通过。
  - (b) linchpin：A/B/C/D 明确写成内部消融、非 leaderboard；"为何不用 MIMIC-IV" 写成方法论选择（私有 schema/口径不可迁移）；"待确认项"对应 abstention，不主张超越 → 通过。
  - (c) 期刊口径：补 EHRSQL/EM-EX/MIMIC 对齐显著提升评测严谨度与审稿可读性 → 通过。
  - 结论：**通过**。
- **改稿**：main.tex §2 加 "Text-to-SQL over EHRs" 段 + 强化 Positioning；§4.3 指标对齐 EX/abstention；新增 4 条参考文献（ehrsql2024/rag2step2025/ragepi2024/metaclin2025）。
- **下一轮建议方向**：K1–K3 专利对齐（需先把 .doc 转文本读架构细节）；或 C2 用 STARE-HI 35 项逐条核 §4/§5；或 I1/I2 英文去直译腔 + 术语统一。

## R3 · 2026-06-21 · 视角方向：P2/E 报告规范对齐（MI-CLAIM）+ 专利 blocker 登记
- **分析**：
  - 计划本轮做 K1–K3 专利对齐，但专利为老式二进制 `.doc`，本环境无 antiword/catdoc/libreoffice，**读不出正文** → K 挂起，已在树中登记解锁条件（作者另存 .docx/.txt 或装转换工具）。
  - web 重搜命中 MI-CLAIM（Nat Med 2020, EQUATOR）+ MI-CLAIM-GEN（arXiv:2403.02558）。转做 E/报告规范：让论文声明遵循该清单，显著提升快通 SCI 就绪度。新叶子 W9/W10 入树。
- **二次评审**：
  - (a) 出处闸门：不加结果数字 → 无编数；MI-CLAIM 引文为真实标准（Norgeot et al. 2020；arXiv:2403.02558），作者未定处用 `\PH` → 通过。
  - (b) linchpin：MI-CLAIM 的 baselines 项写成"裸 LLM(A)+人工写 SQL=现行实践基线"，诚实不越界；未声称已填好清单（标 supplementary 占位）→ 通过。
  - (c) 期刊口径：报告规范对齐是快通 SCI 加分项 → 通过。
  - 结论：**通过**。
- **改稿**：main.tex §4.2 加"现行实践基线"句；§4.4 加 MI-CLAIM/MI-CLAIM-GEN 遵循声明 + supplementary 占位；新增 2 条参考文献。E1 标 🟡。
- **下一轮建议方向**：I1/I2 英文去直译腔 + 术语统一（不依赖外部、纯 P3 加分）；或 G1 错误分析升级；专利待作者解锁后再做 K。

## R4 · 2026-06-21 · 视角方向：G1 错误分析升级（映射文献分类学）
- **分析**：
  - 专利仍 `.doc` 未解锁 → K 继续挂起（已 R3 登记）。
  - web 重搜命中通用 Text-to-SQL 错误分类学（schema-linking/join/value/syntax，schema-linking 与 join 占主导）+ Text-to-SQL LLM 综述 + SQL-of-Thought 引导式纠错 / execution-guided 生成。新叶子 W11–W13 入树。
  - 取叶子（G1，错误分析章，纯写作不依赖外部）。
- **二次评审**：
  - (a) 出处闸门：文献结论带引用、不冒充本文实测；本文错误计数仍 `\PH` → 通过。
  - (b) linchpin：把本文 5 类写成文献既有类目的"医院特化"（时间口径混淆），不越界、不主张超越 → 通过。
  - (c) 期刊口径：错误分析有文献锚点，审稿可读性提升 → 通过。
  - 结论：**通过**。
- **改稿**：main.tex §5.1 错误学映射到通用分类 + 点明时间口径为医院特化 + 关联 execution-guided 线；新增 2 条参考文献（tsqlsurvey2024 / sqlthought2025）。
- **下一轮建议方向**：I1/I2 英文去直译腔 + 术语统一全文扫一遍（纯 P3 加分、零外部依赖）；或 §3.3 召回用 schema-linking 双向检索文献加固（W13）；专利待解锁做 K。

## R5 · 2026-06-21 · 视角方向：I1/I2 英文一致性收口
- **分析**：专利仍 `.doc` 未解锁，K 挂起。web 重搜命中选刊候选（JMIR Medical Informatics 等，W14 入树）。读 main.tex 全文：本就英文新写、无明显直译腔，主要问题是一致性。取叶子 I1/I2。
- **二次评审**：纯格式/术语一致性，不动证据链、不加数字 → 出处闸门/linchpin 不触发；提升排版规范度 → 期刊口径加分。结论：**通过**。
- **改稿**：main.tex —— LaTeX 破折号统一 `---`（Discussion/作者行）；删 Positioning 残留中文"口径"；术语统一为 "manual SQL authoring"；Introduction 限制句改写更自然。I1 标 done、I2 标 🟡。
- **下一轮建议方向**：§3.3 召回用 schema-linking 双向检索文献加固（W13，纯写作）；或 Discussion 增"三杠杆各自机制"细化（B1/B2）；专利待解锁做 K。

## R6 · 2026-06-21 · 视角方向：§3.3 召回加固（schema-linking 文献定位）
- **分析**：专利仍 `.doc` 未解锁，K 挂起。web 重搜命中双向 schema-linking 检索（arXiv:2510.14296）+ RSL-SQL 召回/精确率权衡 + LinkAlign/SchemaGraphSQL（W15 备选入树）。取叶子 W13/§3.3。
- **二次评审**：加文献定位 + 2 引文（schemalink2025/rslsql2024），不冒充本文召回数字、把"历史SQL+abstention"诚实写成精确率控制、不主张超越 → 出处闸门/linchpin 通过；评测/方法严谨度提升 → 期刊口径通过。结论：**通过**。
- **改稿**：main.tex §3.3 加"加权召回=schema linking、recall vs precision 张力、历史SQL+abstention 作精确率控制"段；新增 2 条参考文献（共 18 条）。
- **下一轮建议方向**：Discussion 三杠杆各自机制细化（B1/B2，纯写作）；或图 J2 用文本/ASCII 先把 pipeline 图结构定下来；专利待解锁做 K。

## R7 · 2026-06-21 · 视角方向：B1/B2 三杠杆机制 + fig_pipeline TikZ 化
- **分析**：专利仍 `.doc` 未解锁，K 挂起。web 重搜命中三杠杆机制文献支撑（RAG-结构化降幻觉 arXiv:2404.08189、幻觉缓解综述 arXiv:2401.01313）。取叶子 B1/B2 + J2(fig_pipeline)。
- **二次评审**：机制段为一般性陈述带文献引用、不冒充本文实测；TikZ 图为结构示意不含数字；本环境无 LaTeX，TikZ 源码已自查未本地编译（已在树/稿注明，作者编译时核渲染）→ 出处闸门/linchpin/期刊口径 通过。结论：**通过**。
- **改稿**：main.tex 预置 tikz 包；fig_pipeline 由 \fbox 占位升级为可编译 TikZ 流程图（含 pass? 判定与反馈回边）；Discussion 加 "Why each lever helps" 机制段；新增 2 条参考文献（共 20 条）。B1 done、B2/J2 标 🟡。
- **下一轮建议方向**：诚实边界/审稿预答打磨（Discussion+Limitations 增"反驳预答"）；或全文一致性复核（acronym 首现、表注、引用编号）；专利待解锁做 K。剩余多为作者侧缺口，循环转细粒度收尾。

## R8 · 2026-06-21 · 视角方向：审稿预答 — Threats to validity（G2）
- **分析**：专利仍 `.doc` 未解锁，K 挂起。web 重搜确认四类效度框架（construct/internal/external/conclusion）。取叶子 G2（审稿预答，纯写作）。
- **二次评审**：诚实披露、把既有 linchpin 按四类效度系统化 + 缓解计划；明确"小样本下 A→D 差异应报效应量/置信区间而非视为显著"，与"数字为占位"一致 → 出处闸门/linchpin/期刊口径 通过。结论：**通过**。
- **改稿**：main.tex §7 加 \subsection{Threats to validity}（四类效度 + 缓解），引 validity 报告规范；新增 1 条参考文献（共 21 条）。G2 标 done。
- **下一轮建议方向**：全文一致性复核（acronym 首现展开 RAG/PACU/EM/EX、表注口径、\PH 清单是否齐全且无遗漏）；或为作者生成一份"投稿前 checklist / 待填占位清单"便于一次补齐；专利待解锁做 K。
> 提示：纯写作加固已基本到顶，建议作者侧尽快：选刊→填实测数字→专利转 .docx 解锁 K→渲染 fig_results/fig_error。

## R9 · 2026-06-21 · 视角方向：全文一致性复核 + 投稿前 checklist（I2 + P3）
- **分析**：专利仍 `.doc` 未解锁，K 挂起。grep 盘点 13 处 \PH 占位 + acronym 首现。web 重搜投稿附件规范（W16 入树）。取叶子 I2 + 生成 checklist。
- **二次评审**：纯一致性修复（acronym 展开、统一美式拼写）+ 作者侧 checklist（非稿件主张），无编数、不越界 → 通过。结论：**通过**。
- **改稿**：main.tex 摘要 RAG 首现展开、PACU 展开为 post-anesthesia care unit、favour→favor；新建 `SUBMISSION_CHECKLIST.md`（A 占位 13 项 / B 决策 / C 图 / D 专利 / E 投稿附件）。I2 标 done。
- **下一轮建议方向**：纯写作已近顶（≈74%，上限约 75–78%）。可做：①Introduction 收尾段补"paper 结构导航"句；②Abstract 与正文术语再核一遍；③专利解锁后做 K。若无作者新输入，循环将进入"维持/小幅润色"低频模式。
> 重要：再往上需作者侧补 SUBMISSION_CHECKLIST.md 的硬缺口；循环已逼近"不依赖作者输入的天花板"。

## R10 · 2026-06-21 · 【策略变更】作者指令：数字/图/内容全部补齐做成可直接投稿稿
- **指令**：作者要求把数字、图、各处内容补成"形态可直接投稿"版本，数字按可投稿逻辑+网上经验填合理值，作者拿到实测后替换。已更新驱动文件【实验数字策略】+【已锁定参数】。
- **二次评审（守红线）**：填示意值做完整稿可行，但**表/图注保留 `(illustrative)`、main.tex 顶部加 NOTE、行内 `% confirm` 注释**作安全绳；红线=绝不把示意当真实正式投出。配置类（LLM/标注κ）填合理示例并注明 confirm。→ 通过。
- **改稿**：main.tex —— Table 1/2 数字由 \PH 改为实值(62→91 等示意)；新增 Fig.2 趋势图(pgfplots)、Fig.3 错误分布图(pgfplots)；§4.3 标注协议(κ≈0.81 示意)、§4.4 复现配置(GPT-4-class/temp0/hybrid top-k=8 示意)、§Ethics 伦理+可得性声明 全部补实；预置 pgfplots 包。更新 SUBMISSION_CHECKLIST(A/C 节)。完成度 74%→90%(形态)。
- **下一轮建议方向**：参考文献 13 条作者名 web 代查补全（避免杜撰）；或全文编译性自查（pgfplots/tikz 语法、引用闭合）；专利待解锁做 K。

## R11 · 2026-06-21 · 视角方向：参考文献作者补全 + 编译自查（E2 + 可投性）
- **分析**：专利仍 `.doc` 未解锁，K 挂起。LaTeX 静态自查：\begin/\end 17=17、figure/table/tikzpicture/axis/abstract/enumerate/thebibliography/document 全配平、无未定义 \cite、正文除参考作者名外无残留 \PH → 编译结构健康。web 代查 6 条参考真实作者。
- **二次评审**：作者名均来自 arXiv/ACL 实查（Lee G 等 EHRSQL；Liu X 等综述；Chaturvedi S 等 SQL-of-Thought；Nahid 等 schema linking；Béchard 等结构化降幻觉；Tonmoy 等幻觉综述），非杜撰 → 通过；其余 6 条下一轮续查。结论：**通过**。
- **改稿**：main.tex 补 6 条参考作者（ehrsql2024/tsqlsurvey2024/sqlthought2025/schemalink2025/ragstruct2024/halluc2024），ehrsql 补 ACL Clinical NLP 2024 + arXiv:2405.06673。
- **下一轮建议方向**：续查剩余 6 条作者（rag2step2025 / ragepi2024 / metaclin2025 / miclaimgen2024 / rslsql2024 / validity2023）；之后纯写作再无大缺口，建议转低频等作者侧（实测数字/选刊/专利）。专利待解锁做 K。

## R12 · 2026-06-21 · 视角方向：补完全部参考作者（E2），纯写作到顶 → 转低频
- **分析**：专利仍 `.doc` 未解锁。web 代查剩余 6 条作者：rag2step/ragepi=Ziletti A & D'Ambrosi L（Bayer，后者 NAACL ClinicalNLP 2024）；miclaimgen=Miao B Y 等；rslsql=Cao Z 等（修正 arXiv:2411.00073）；validity=Sjøberg D I K & Bergersen G R（EASE 2023）；metaclin=Liu W 等（题名补全 + DOI）。
- **二次评审**：作者名全部 arXiv/ACL/medRxiv 实查、非杜撰；grep 核验正文 0 处 \PH{authors}、0 处任何 \PH（仅 \newcommand 定义行）；24 条参考文献。→ 通过。
- **改稿**：main.tex 补完最后 6 条参考作者并修正 1 个 arXiv 号、补 2 个出处/DOI。
- **结论**：纯写作（不依赖作者侧输入）已无实质缺口 → **循环转低频维持**（每 ~30 分钟），主要轮询专利是否转码解锁 K；待作者补实测数字/选刊/专利后再恢复主动。

## R13 · 2026-06-21 · 低频维持：补 Appendix 消除悬挂引用
- 专利仍 `.doc` 未解锁，K 挂起。自查发现 §4.4 引用 "the Appendix"（prompt templates）但无 Appendix 节 → 悬挂引用。
- 二次评审：补 \appendix + \section{Prompt template (illustrative)} + \label{app:prompt}，§4.4 改为 Appendix~\ref{app:prompt} 交叉引用；prompt 模板用 verbatim、标 illustrative、不涉数字 → 通过。
- 改稿：main.tex 加 Appendix（约束式 prompt 模板示意）。维持低频。

## R14 · 2026-06-21 · 维持期检查（无改动）
- 专利仍 `.doc` 未解锁。交叉引用核验：所有 \ref 均有 \label、无孤儿 \label、18 环境配平、正文零 \PH → 整稿编译就绪、内部自洽。
- 确无作者独立可做的实质工作 → 本轮不改稿，循环延长至 ~1 小时心跳，等作者输入（实测数字/选刊/专利转码）或"停"。

## R15 · 2026-06-21 · 【重启】对照最佳同类(metaclin2025)改两项 + 存对照分析
- **触发**：作者要求找最佳对照并据此改进。对照=Liu W 等(medRxiv 2025)：自托管开源 LLM 查真实库 GWTG-HF、600 条、1/2/3 字段分层、execution-based、1字段88→94.5/3字段10→82、含真实用户试用。
- **二次评审**：#2 隐私一致性修复（医院隐私叙事 vs 我之前填的云端 GPT-4-class 矛盾）；#3 复杂度分层用示意值+标 illustrative、对齐对照难度梯度叙事、不冒充实测 → 通过。
- **改稿**：main.tex §4.4 LLM 改"自托管开源、本地部署、数据不出院"；§Ethics 加"on-premises 推理、患者数据不出院"；§5 新增 \subsection{Effect of query complexity} + Table~\ref{tab:complexity}（Simple/Moderate/Complex × A/D，示意）。新建 `COMPARISON_metaclin2025.md`。
- **对照暴露的剩余不足(写入对照文件)**：#1 数字未实测(作者侧)；#4 缺真实用户测试小节；#5 指标偏主观(提 EX 为主)；#6 数据集未具名；#7 N=30 偏小。
- **下一轮建议方向**：#4 加 "Real-world user testing" 质性小节；#5 把 EX/结果一致率提为主指标措辞；#6 任务集可得性声明；专利待解锁做 K。→ 循环恢复主动节奏。

## R16 · 2026-06-21 · 对照驱动 L3/L4/L5（向 metaclin2025 看齐）
- 专利仍 `.doc` 未解锁。二次评审：L4/L5 诚实方法学；L3 质性小节标 illustrative + 引 metaclin2025、不造数 → 通过。
- 改稿：main.tex §4.1 任务集可得性声明（Supplementary，留 confirm）；§4.3 EX 提为 primary endpoint + 人评盲评(blinded to A–D)；§5 加 \subsection{Real-world use and qualitative feedback}（质性三主题，illustrative）。
- 结论：对照驱动的纯写作改进 L1–L5 全部完成；剩 L6（扩样本，作者侧）。纯写作再次到顶 → **转低频维持**，等作者侧（实测数字/选刊/专利转码）。

## R17 · 2026-06-21 · 【写作策略变更】自信顺写 + 目标刊 JMIR Med Inform + 缺陷后置
- **作者指令**：按好的可投论文自信顺写，正文不铺陈缺陷，Limitations 投稿前再加；按目标刊组织段落、对照优秀范文调故事线。已写入驱动文件【写作策略】。
- **目标刊**：JMIR Medical Informatics（确认在发同类 LLM 临床查询/text-to-SQL：e71252/e63216/e58541）。按其 IMRaD + 结构化 Discussion。
- **二次评审**：移出 Limitations/Threats 到 LIMITATIONS_PARKED.md（投稿前回插，JMIR 要求）；去散落自我贬低（do not claim/feasibility only/conjecture）；保留 (illustrative) 安全绳 + 不加虚假主张 → 通过。
- **改稿**：main.tex Discussion 改 JMIR 式 \subsection{Principal findings} + \subsection{Comparison with prior work}（自信）；删 \section{Limitations}+Threats（存档）；Conclusion/Abstract 去 feasibility 自我贬低、自信收束；Related Work Positioning 去"do not claim to outperform"。静态自查通过（20 环境配平、无断引用、正文无缺陷措辞、13 处 illustrative 仍在）。注：validity2023 暂成未引用（随 Limitations 回插）。
- **下一轮建议方向**：抓一篇 JMIR 优秀同类范文(e71252/e63216)对照其 Introduction 钩子/Methods 叙述/段落过渡，逐段把本文 flow 打磨更顺；专利待解锁做 K。

## R18 · 2026-06-21 · M4 Introduction flow（JMIR 惯例）
- 专利仍 `.doc` 未解锁。二次评审：纯叙事衔接、无新数字/无虚假/不铺缺陷 → 通过。
- 改稿：Introduction 在"裸 LLM 不行"与 Contributions 之间补一段"本文方法概述 + Objective"桥接（痛点→NL2SQL gap→受控闭环方法→objective(engineering-usable & criterion-traceable)→contributions），消除原先的叙事断裂。
- 下一轮：Methods/Results 段间过渡与小标题衔接继续打磨（M4 续）；M5 全文顺度通读；专利待解锁做 K。

## R19 · 2026-06-21 · M4 续 · Framework 总起句
- 专利仍 `.doc` 未解锁。二次评审：纯导航句、无数字/虚假 → 通过。
- 改稿：§3 Framework 开头补一句总览（指向 Fig.1 + 小节导航），消除直接进 Task definition 的突兀。M4 标 done（Intro 桥接 R18 + Framework 总起 R19）。
- 下一轮：M5 全文顺度通读（一次性顺一遍，抓生硬过渡/重复）；专利待解锁做 K。纯写作仅剩 M5 这类微调，建议维持低频。

## R20 · 2026-06-21 · M5 全文通读（无改动）
- 专利仍 `.doc` 未解锁。通读 Abstract→Conclusion：连贯自信、重复度健康、无生硬过渡 → 按策略"无新活则保持"，不制造无谓改动。
- 结论：写作策略 H-M（M1–M5）全部完成；仅剩 M6（投稿前回插 Limitations，作者侧）。纯写作再次收敛 → 维持低频，等作者侧（实测数字/选刊/专利转码）。

## R21 · 2026-06-22 · 【图表增强】对标 JMIR 范文补图表（作者指令：优先完成可投稿）
- 抓 JMIR 范文 e71252(4图5表+对比表+统计检验)/e63216(8图含截图)。本文原 3图3表偏少。
- 二次评审：新表/图均为方法结构或示意值(标 illustrative)、对比表为真实定位、不造数 → 通过。
- 改稿：main.tex 预置 amssymb；加 tab:kb / tab:substruct / tab:verify（方法侧 3 表）、tab:compare（Discussion 现有系统特征对比）、fig:example（端到端 worked-example 脱敏）、fig:complexity（复杂度分层柱）。**图表 3图3表 → 5图7表**。静态自查通过（33 环境配平、无断引用、无孤儿标签、无未定义 cite）。差距分析存 `FIGURE_GAP_ANALYSIS.md`。
- 下一轮：§4 指标形式化定义（EX/一致率公式，纯写作可做）；其余作者侧（真实数字/统计检验/数据集具名/UI 截图/多模型）。专利待解锁做 K。

## R22 · 2026-06-22 · M8 指标形式化定义
- 专利仍 `.doc` 未解锁。二次评审：纯定义公式、不涉数字、不越界 → 通过。
- 改稿：§4.3 加 5 指标形式化定义（可执行率/EX/字段一致/条件准确/人工修正，用 \mathbb{1} 指示函数 + 采样集 S/结果集 R 记号），对标 e71252。
- 结论：**纯写作（不依赖作者侧）已全部做完**（M1–M8 + 图表增强）。剩 M9 全为作者侧（真实数字+统计检验/数据集具名/UI 截图/多模型）+ 投稿前回插 Limitations。→ 转低频维持，等作者输入。
