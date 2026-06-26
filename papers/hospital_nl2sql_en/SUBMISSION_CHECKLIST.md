# 投稿前待办清单（作者侧一次补齐）· hospital_nl2sql_en

> 循环已把"除实测数字与作者私有信息外"的稿件写到可投形态。以下是**只有你能补**的缺口。
> 全部 `\PH{...}` 红色占位编译后会醒目显示，逐项替换即可。

## A. 状态（2026-06-21：循环已把数字/图/配置补成"形态可直接投稿"，均为示意值，投稿前须替换）
**已填（示意值；表/图注保留 `(illustrative)` 标记作安全绳，换上真实数据后删标记）**
- [x] Table 1 / Table 2 全部数字（A→D 单调合理、延迟随校验上升）
- [x] Fig.2 趋势图 + Fig.3 错误分布图（pgfplots，可直接编译）
- [x] §4.3 标注协议（两名工程师独立标注、第三人仲裁、Cohen's κ≈0.81）—— 示意
- [x] §4.4 复现配置（GPT-4-class、temperature 0、hybrid 检索 top-k=8）—— 示意
- [x] §Ethics 伦理/数据可得性声明（标准表述）

**仍需你做（红色安全绳处）**
- [ ] 用真实实测数字替换 Table 1/2 与 Fig.2/3，并删去对应 `(illustrative)` 标记
- [ ] 核对 §4.3 标注协议、§4.4 LLM/检索配置、§Ethics 批件 与实际一致（main.tex 行内已留 `% confirm ...` 注释）
- [ ] 参考文献 13 条 `\PH{authors}` 作者名补全（arXiv 号已给；可让循环下一轮代查，绝不杜撰）
- [ ] 中文稿原 5 条领域文献（纪相存2024 / 帖军 RNSQL / 丁咚 / 贺梓然 / 白培发）按目标刊语言决定是否保留

## B. 作者决策项
- [ ] **选刊**：候选 JMIR Medical Informatics（SCIE/IF3.8/Q1/OA 快通）、IEEE Access、MDPI(Applied Sciences/Electronics/Diagnostics/Healthcare)、Scientific Reports、Heliyon。定刊后套该刊模板（P3）
- [ ] 作者/单位/通讯作者+ORCID+邮箱（main.tex \author）
- [ ] 标题最终定稿（现题：A Metadata-Augmented Retrieval-to-SQL ... for Hospital Statistical Queries）

## C. 图（J2，全部已就位，均可编译）
- [x] Fig.1 pipeline：TikZ 流程图（编译后请肉眼核渲染）
- [x] Fig.2 results A→D：pgfplots 趋势图（示意数字）
- [x] Fig.3 error taxonomy：pgfplots 柱状图（示意数字）
- [ ] 拿到实测后更新 Fig.2/3 的坐标数字并删 `(illustrative)`

## D. 专利对齐（K，受阻）
- [ ] 把 `zhuanli/AJ2534335-...v2.doc` 另存为 **.docx 或 .txt** → 循环即可解锁：从专利提取架构细节喂 Methods/图、写好在先披露引用、确认"论文无 RL"与专利 RL 路线的区分

## E. 投稿附件（按选定刊要求）
- [ ] Cover letter（讲清贡献/创新点/无重复发表/利益冲突；可提及同主题专利为在先披露）
- [ ] Highlights / 三句话要点（部分刊要求）
- [ ] Graphical abstract（部分刊要求；可基于 Fig.1 改）
- [ ] 作者贡献声明 / 利益冲突声明 / 基金声明

---
_循环负责 A 的文字骨架与 C 的 Fig.1、E 的结构提示；带"依赖实测/作者私有/受阻"的项必须你来补。_
