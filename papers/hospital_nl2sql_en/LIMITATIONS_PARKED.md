# Limitations & Threats to validity — PARKED (re-insert before submission)

> 作者指令(2026-06-21):正文先按"好的可投论文"自信顺写，**不在正文铺陈缺陷**；以下内容从 main.tex 暂时移出，**投稿前作为 Discussion 的 Limitations 子节插回**（JMIR Medical Informatics 要求有 Limitations 子节）。内容与措辞保留，供直接粘回。

## 插回位置
Discussion 末尾、Conclusion 之前，作为 `\subsection{Limitations}`（可保留 Threats to validity 作其下一段或并列子节）。

## 待插回的 LaTeX（verbatim）
```latex
\subsection{Limitations}
(i) Single site, single database, and a small task set ($N{=}30$) evaluated partly by the system
builders; this is a feasibility study, not a generalizability claim. (ii) A/B/C/D is an internal
ablation, not a comparison against external systems or public benchmarks. (iii) Several metrics are
human-judged and result consistency is sampled, so annotation bias is possible. (iv) Results depend
on a specific LLM, prompt, and retrieval configuration and are not model-agnostic. (v) The full
pipeline increases end-to-end latency; we argue reliability and criterion consistency outweigh
single-shot speed for this use case.

\subsection{Threats to validity}
We organize these concerns using the standard categories~\cite{validity2023}.
\emph{Construct validity}: human-judged metrics (key-field consistency, condition-recognition
accuracy) and a sampled result-consistency check may imperfectly capture ``engineering usability'';
we mitigate this with operational metric definitions and a documented annotation protocol.
\emph{Internal validity}: tasks were drawn from historical reports and partly annotated by the
system builders, raising selection and instrumentation bias; we plan blinded, independent annotation
with inter-annotator agreement. \emph{External validity}: a single site, a single database,
$N{=}30$, and one LLM configuration limit generalization, so multi-site data, a larger task set, and
multiple LLMs are required. \emph{Conclusion validity}: with a small sample, A$\to$D differences
should be reported with effect sizes and confidence intervals rather than asserted as significant,
which we defer to a larger measured study.
```

> 注：`\cite{validity2023}` 对应的参考文献仍保留在 main.tex 的 thebibliography 中（移出正文不影响），插回即用。
