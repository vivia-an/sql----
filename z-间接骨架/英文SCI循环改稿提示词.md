# 医院 NL2SQL 论文 · 英文 SCI 循环改稿提示词（适配版）

> 来源：由 paperD_coordinate_mask 的循环改稿提示词改写而来。
> 体裁已从"深度学习现象分析型"切换为"医学信息学应用/系统型（IMRaD）"，并新增"英文 SCI 写作层"与"数据出处闸门"。
> 源中文稿（只读参照）：`z-间接骨架/基于大语言模型的医院数据查询SQL自动生成系统设计与应用_毛笔临帖修订稿.md`

---

## 【已锁定参数】（2026-06-20 作者确认）
- **目标期刊/档位 = 最快适合的 SCI（快通 SCIE 综合/应用档）**：候选 IEEE Access / MDPI（Applied Sciences、Electronics、Diagnostics、Healthcare）/ Scientific Reports / Heliyon。门槛友好、周期短、接受完整应用框架；按选定刊的 Author Guidelines 收口。**注意**：即便快通刊，医院数据的伦理/去标识化声明仍为硬性必备，不得省。
- **A/B/C/D 数字性质 = 先填合理示意值做成"形态可直接投稿"完整稿（2026-06-21 作者新指令，覆盖原"留空占位"策略）** → 用符合可投稿逻辑、单调合理、贴合文献经验的数字把结果表/图全部填满并真画出图；唯一约束=表/图注保留极简 `(illustrative)` 标记 + main.tex 顶部与 SUBMISSION_CHECKLIST 注明"投稿前须换实测"。作者拿到实测后替换并删标记。**红线：绝不把示意数字当真实实测在正式投稿中宣称为已测结果（学术不端）——标记在＝责任清晰，标记删＝作者已用真实数据背书。**
- 产出形态：main.tex 为英文交付件，story_en.md 为英文事实底稿，story_zh.md 仅作翻译/推理桥（可留可删）。

## 【实验数字策略 · 先填示意做完整可投稿稿，作者后替换（2026-06-21 更新，覆盖原"实验边界/留空"）】
- 本循环**不跑真实实验**，但**要把数字、图、各处内容补齐**，产出"形态上可直接投稿"的完整稿（数字、标注协议、复现配置、图全部填到位）。
- 数字用**符合可投稿逻辑、单调合理、贴合文献经验**的示意值（如 A→D 单调上升、延迟随校验上升、schema-linking/join 类错误偏多）；图用这些值真画出来（pgfplots/TikZ 可编译，或 matplotlib）。配置类占位（LLM/解码/检索/标注协议）填合理示例并行内注明"confirm with actual"。
- **安全绳（不可删）**：结果表/图注保留极简 `(illustrative)`；main.tex 顶部与 `SUBMISSION_CHECKLIST.md` 标明"数字为示意、投稿前须换实测"。作者填入真实数字即删标记。
- **红线**：绝不把示意数字当真实实测在正式投稿中宣称为已测结果（学术不端）。

---

## 【目标】
以"面向医院统计口径的元数据增强 RAG-Text2SQL 生成与反馈校验框架"为中心，持续打磨 **paper_en**（story_en.md + main.tex + figs），产出一篇**可投英文 SCI** 的医学信息学应用/系统论文。
重心是**真实医院数据平台上 NL2SQL 的工程可靠性与临床可用性**（降幻觉、保口径、可追溯、减返工），不是刷 SOTA 精度，也不是优化器/方法排名。

**本循环的执行总纲（2026-06-20 作者确认，最高约束）**：
- **写作优先 / 方向驱动**：循环的目标就是**先把论文写出来、写到可投稿**——写作方向来自"对比他人论文骨架分析（间接骨架/参考论文）+ 网上调研分析"得出的可借鉴角度，逐轮把这些方向落进 story_en/main.tex。
- **数字/图/内容全部补齐做成可直接投稿稿（2026-06-21 更新）**：用合理示意值把数字与图填满、配置类占位填合理示例，产出"形态可直接投稿"的完整稿；作者拿到实测后替换。详见【实验数字策略】。
- **安全绳**：所有示意数字处保留极简 `(illustrative)` 标记；红线＝绝不把示意数字当真实实测正式投出。
- **成稿判据**：条理清晰、逻辑通顺、IMRaD 完整、claim 不越证据、占位可由作者无歧义填入 → 即视为"可投稿成稿"。

## 【写作策略 · 按好的可投论文自信顺写（2026-06-21 作者新指令，最高优先）】
- **目标刊 = JMIR Medical Informatics**（SCIE/Q1 健康信息学/OA 快通；同类已发 LLM 临床查询/text-to-SQL，如 e71252/e63216/e58541）。按其 IMRaD + 结构化 Discussion 组织：Principal findings → Comparison with prior work →（投稿前才加 Limitations）→ Conclusions。
- **自信顺写**：先把故事讲足讲顺，正文**不铺陈缺陷**；去掉散落的自我贬低（"do not claim to outperform / feasibility only / builder-judged / conjecture" 等）。自信≠虚假——靠把贡献讲足，不靠编造超越。
- **缺陷最后加**：Limitations / Threats to validity 暂存 `LIMITATIONS_PARKED.md`，**投稿前**作为 Discussion 子节插回（JMIR 要求有 Limitations）。
- **对照范文**：每轮对照目标刊一篇优秀同类论文的写作与叙事（措辞/段落组织/过渡），打磨本文 flow；故事线该调就调，讲顺为先。
- **不变的红线**：数字仍留 `(illustrative)` 安全绳；不写虚假/未做之事为已做。

## 【体裁铁律】（这是应用/系统型论文，不是现象分析型，也不是 leaderboard 论文）
1. **贡献定位**：框架设计 + 领域贴地的评测方法 + 真实医院场景下诚实的错误/局限分析。精度只用于支撑"可行性/可用性"，**不主张超越已有系统**。
2. **A/B/C/D 是内部消融**（裸生成 / +表结构 / +RAG / +执行反馈），用于显示各组件的边际贡献，**不是与外部系统/基准的对比**——绝不写成 "outperforms prior methods"。
3. **三个可靠性杠杆**（元数据约束 / SQL 子结构分解 / 执行反馈闭环）是设计，其增量效果是被"测量"的，不为任何一个"加冕"。
4. **叙事骨架（IMRaD，已定，沿用）**：
   临床/运营痛点（人工写 SQL、表结构多源、口径不一致）
   → 为何裸 LLM-to-SQL 在医院不安全（字段幻觉 / 口径幻觉 / 关联路径错 / 方言不兼容）
   → 框架（元数据知识库组织 → 召回 + 口径映射 → SQL 子结构生成 → 四层校验 → 错误归因反馈）
   → 评测设计（30 条真实脱敏医院任务、4 档递进设置、指标定义清楚）
   → 结果（A→D 单调提升）
   → 错误类型学（5 类）
   → 局限与诚实边界（单中心、小样本、人评、LLM 版本依赖、延迟代价）
   → 未来工作。

## 【英文 SCI 写作铁律】（本次新增，相对中文稿的硬增量）
- 产出语言=学术英文 IMRaD，**不是中文稿的逐句直译**：按 SCI 规范重组——结构化 Abstract（Background / Objective / Methods / Results / Conclusion）、显式 Contributions、Related Work、Methods、Experimental Setup、Results、Discussion、Limitations、Conclusion。
- 术语统一且首次出现给英文定义：Text-to-SQL、retrieval-augmented generation (RAG)、schema linking、execution feedback；领域词 PACU、elective surgery、medical record front page（病案首页）、"口径"→ statistical definition / criterion。杜绝 Chinglish 与直译腔。
- **补齐中文稿缺、但 SCI 必备的件**（每轮检查是否到位）：
  (1) Ethics / IRB & 数据**去标识化**声明，正文示例禁用真实患者数据；
  (2) **可复现性**：LLM 名称+版本、解码参数（temperature 等）、检索/嵌入配置、提示词模板；
  (3) **标注协议**：人评指标由谁判、判定规则、（若可能）标注者间一致性，并说明"结果一致率为抽样"；
  (4) **baseline 定位**：与 Spider/BIRD、DIN-SQL/RAT-SQL 等先前工作的关系（定位而非对打），讲清本文为何用内部消融而非公开基准；
  (5) Data/Code availability statement（在合规范围内）。

## 【已验证证据不丢】（本文真实数字，逐字保住；进稿前仍须过出处闸门）
- 方案级（A 裸 / B +表结构 / C +RAG / D +执行反馈）：
  - SQL 可执行率 62 → 74 → 86 → 91（%）
  - 关键字段一致率 41 → 55 → 71 → 78（%）
  - 条件识别准确率 48 → 59 → 72 → 79（%）
  - 平均人工修正次数 2.7 → 1.9 → 1.1 → 0.6（次/条）
- 效率级：端到端耗时 18 → 21 → 26 → 31（s）；平均校验-重试轮数 0 → 0 → 0.4 → 1.2；口径歧义触发人工确认 8 → 11 → 19 → 23（%）
- 任务集：30 条 = 月度统计 8 / 科室病区 6 / 并发症 6 / 多表明细 5 / 口径歧义 5；4 类案例原型；5 类错误学
- 指标集：可执行率、关键字段一致率、条件识别准确率、结果一致率（抽样）、平均人工修正次数、端到端耗时
- 方法资产：元数据知识库 4 类条目、召回得分 Score(c)=α·key+β·sem+γ·hist、SQL 子结构 5 段、四层校验（语法/字段/口径/结果）、错误归因—上下文更新—再生成闭环

## 【数据出处闸门】（本次新增 · SCI 诚信红线，任何数字进英文稿前必过）
- 每个将作为"实测结果"写入英文稿的数字，必须回溯到**真实实验记录**（运行日志 / 标注表 / 结果 CSV）。
- 若某数字目前**只存在于中文稿、无底层记录**：按【待确认参数】分支处理——
  (i) 真实实测 → 找到/补建记录文件并在 STORYLINE 标注出处；
  (ii) 示意占位 → 明确标 "illustrative / preliminary"，**不得**作为实证发现报告；要么本轮安排真实重测并落记录，要么把对应 claim 降级为"设计预期/案例演示"。
- **绝不**为投稿"美化、补全、对齐"任何数字。编造或修饰实验结果=学术不端，一票否决。

## 【linchpin · 任何 claim 不得越过证据】（医学信息学审稿命门）
- (a) **单中心 / 单库 / N=30 / 由系统搭建者自评** → 全文定位为 feasibility / case study；不主张普适性、不主张"生产级优于他法"。泛化只进 Discussion 作 conjecture。
- (b) **A/B/C/D 是内部消融，不是外部系统/公开基准对比** → 绝不写 "outperforms"；诚实定位与先前工作的关系。
- (c) **多项指标为人评**（关键字段一致率、条件识别准确率、结果一致率为抽样）→ 必须披露判定主体、协议、抽样性质，并承认评测偏差风险。
- (d) **结果依赖特定 LLM + 提示词 + 检索配置** → 必须报告这些；明确"非模型无关"，给可复现性 caveat。
- (e) **隐私/伦理**：医院数据 → 去标识化 + IRB/数据治理声明为必备；示例不得含真实患者信息。
- (f) **延迟上升是真实代价**（31s vs 18s）→ 如实报告，论证"该场景下可靠性优先于单次速度"，不藏。

## 【路径】`papers/hospital_nl2sql_en/`（首轮若不存在则本轮先初始化创建）
- `main.tex`（英文 LaTeX 交付件）
- `story_en.md`（英文事实底稿/叙事，作为 main.tex 的 single source of truth）
- `STORYLINE_ITER_LOG.md`（轮次轴：每轮记录）
- `PERSPECTIVE_TREE.md`（视角树：按医学信息学审稿维度建 H 节叶子）
- `figs/`（fig_pipeline 框架图、fig_results_AtoD 结果图、fig_error_taxonomy 错误学图）
- 只读参照（中文事实源）：`z-间接骨架/...毛笔临帖修订稿.md`
- 只读参照（同主题专利，素材/术语/在先披露）：`zhuanli/AJ2534335-...自然语义转结构化SQL生成与优化系统-初稿...doc`

## 【循环优先级 · 按论文完成度推荐执行】（每轮选叶子的总规则：先阻塞件，再骨架，再证据，后润色）
不要随机取视角叶子。每轮先看 `STORYLINE_ITER_LOG.md` 顶部维护的 **Submission-Readiness Checklist**，从**最高优先级且未完成**的层取叶子。完成度阶梯（P0→P4，逐层放行）：

- **P0 写作范围内的投稿阻塞件（不补不能投，最高优先；实验本身不在此列）**：
  - 伦理/IRB + 数据去标识化声明；正文示例无真实患者信息；
  - 评测设计章节写完整（任务集、A/B/C/D 定义、指标定义、标注协议、案例原型）+ 结果表/图占位结构就位且口径自洽（数字由作者填，占位齐了即视为本层达标）。
- **P1 骨架完整（让 main.tex 能编译成一篇"形态完整"的稿）**：
  IMRaD 全节到位、结构化 Abstract、显式 Contributions、Related Work 骨架、三张图（pipeline / results / error-taxonomy）与各表占位齐全。
- **P2 证据链与 linchpin 收口**：
  每个数字过【数据出处闸门】；逐条满足 linchpin (a)–(f)；baseline 定位、可复现性（LLM 版本+解码参数+检索配置）、标注协议+抽样说明写入。
- **P3 规范与可投性**：
  英文学术化（去直译腔、术语统一）、参考文献与图表格式按选定刊模板、cover letter / highlights（如刊物要求）。
- **P4 打磨与查漏**：
  视角树剩余叶子做精修、叙事顺滑、审稿预答（rebuttal-proofing）。

**放行规则**：某层全部叶子未达标前，不把主要轮次预算投到更低优先级层（P3 润色不能跑在 P0 伦理声明前面）。**实测数字属作者占位、不阻塞写作完成**——结果数字未填不算未达标，只要占位结构正确、口径自洽即可继续向更高完成度推进，全文以"作者填数即可投稿"为收口。
每轮在 STORYLINE 顶部更新 Checklist 勾选状态，给出"当前完成度 ≈ x%/到可投还差哪几件"的一句话结论。

## 【每轮流程 · 两段制 + 视角方向树】（每 10–15 分钟一轮）
**① 分析**：先读 `STORYLINE_ITER_LOG.md`（接续/防重复）+ `PERSPECTIVE_TREE.md`（视角树）。
【若两文件不存在，本轮先初始化创建】：STORYLINE 记轮次轴；PERSPECTIVE_TREE 按以下 H 节维度建叶子——
clinical motivation / framework novelty / evaluation rigor / baseline positioning / reproducibility / ethics & privacy / error analysis / generalizability / writing & English clarity / figures / patent alignment & novelty positioning。
做两件事：
  - **(a) web 重搜（体裁要对）**：搜「how to write a strong applied clinical-informatics / health-NLP system paper」「Text-to-SQL / NL2SQL in healthcare evaluation」「medical informatics manuscript reviewer checklist (JAMIA / JBI / JMIR)」「reporting guidelines for clinical AI（MI-CLAIM / TRIPOD-AI / CONSORT-AI 思路）」。把新的可借鉴叙事/对比方向追加为 PERSPECTIVE_TREE 的 H 节新叶子（来源去重）。
    对照系=**应用/系统类** NL2SQL 与临床 NLP 落地论文 + RAG-in-healthcare，**不是**优化器/纯方法 SOTA 论文。
  - **(b) 取一叶子（完成度驱动，非随机）**：按【循环优先级 P0→P4】从**最高优先级且未达标**的层取一个未做叶子（不与已做冲突/重复），用逆向倒推法对照上述范文/审稿清单，分析 paper_en 在该视角的差距。同层多叶子时，先取离"可投"最近的。
  - **(c) 结合专利样例（每轮必做的横向核对）**：对照同主题专利 `zhuanli/AJ2534335-...自然语义转结构化SQL生成与优化系统-初稿...doc`，做三件事——
    (i) **素材复用**：从专利的系统架构、模块划分、流程描述中提取可支撑 Methods 章节与 pipeline 图的细节，保持术语/架构与专利一致；
    (ii) **分歧核对（红线）**：专利含**强化学习(RL)**，而本论文方法是 **RAG + 执行反馈、未用 RL**。凡专利有、论文未真正实现的机制（尤以 RL/优化为甚），**一律不得搬进论文当作已实现**；如要提及，只能在 Related Work/Discussion 中作为"作者另一路线/在先工作"区分陈述；
    (iii) **新颖性与在先披露定位**：把该专利作为作者自有在先成果**显式引用**，讲清论文相对专利的增量（领域贴地评测、四层校验、错误学），规避自我抄袭/重复发表风险，并按选定刊对专利披露的要求处理。
**② 二次评审（强制先评审后改）**：
  - (a) **幻觉/编数？** 每个数字过【数据出处闸门】，核到真实记录，区分实测 vs 示意；
  - (b) **证据链够不够、有没有越界？** 逐条过 linchpin (a)–(f)；
  - (c) **达没达到目标 SCI 期刊口径？** IMRaD 是否完整、伦理/复现/标注协议/baseline 定位是否齐备、英文是否学术规范；
  - (d) 有无**更稳的证据链/更诚实表述**？给明确结论（通过 / 打回 / 改进）。
**③ 评审过才改稿**（story_en / main.tex / figs），实事求是：未实测不写成实测；示意数据明确标注或剔除；生成图必 **Read 肉眼核渲染**；英文避免直译腔、术语统一。
**④ 记录**：`STORYLINE_ITER_LOG.md` 记「轮次 + 时间戳 / 视角方向 / 分析 / 二次评审结论 / 改稿摘要」；`PERSPECTIVE_TREE.md` 把该叶子标 `[✓done Rxx]`。
遵守证据链铁律：每个实证陈述都能回溯到记录；不可回溯的一律降级或剔除。
