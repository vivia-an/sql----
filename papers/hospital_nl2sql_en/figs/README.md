# figs — 投稿用的独立矢量图文件

> 这份说明在 2026-07-30 重写过。此前它描述的是一套早期的图规划
> （`fig_pipeline` / `fig_results_AtoD` / `fig_error_taxonomy`，"用 matplotlib 或
> draw.io 渲染"），那套东西早已不存在 —— 现在的 5 张图都是稿件里的 TikZ 与
> pgfplots 代码。旧说明留着只会误导。

**这些 PDF 与 `.tex` 都是生成物，不要手改。** 图的唯一真值源是
`main_applsci_mdpicls.tex` 里的绘制代码；改完图跑：

```bash
python3 ../make_figs.py --write
```

它把每个 `figure` 环境里的绘制代码逐字取出（与 `cn_floats.py` 同一条纪律：
**导出的图若与论文里的不一致，那还不如不提供独立文件**），配上该图所需的
preamble 片段，用 `preview` 裁到内容边界编译成单页 PDF。

## 当前 5 张（2026-07-30 实测）

| 文件 | 论文中 | 尺寸 (pt) | 绘制方式 |
|---|---|---|---|
| `fig-arch.pdf` | 图 1 转换流水线结构 | 377 × 273 | TikZ |
| `fig-preproc.pdf` | 图 2 预处理递减 (a)(b) | 377 × 157 | pgfplots groupplots |
| `fig-models.pdf` | 图 3 八模型表现 (a)(b) | 496 × 201 | pgfplots，通栏 |
| `fig-halluc.pdf` | 图 4 幻觉类型分布 (a)(b) | 502 × 205 | pgfplots，通栏 |
| `fig-ablation.pdf` | 图 5 组件消融 (a)(b) | 453 × 184 | pgfplots，通栏 |

## 为什么"通栏"要单独设一个测度

`mdpi.cls` 把宽图包在 `adjustwidth{-\extralength}{0cm}` 里，向页边扩展 4.61cm。
导出时**剥掉这个包装器、改由页面测度承载**（13.4cm 或 18.01cm）：
包装器的 `\end` 出现在题注*之后*，按题注截断会让环境不闭合；
而直接丢掉扩展，则会导出一张比读者实际看到的更窄的图。

## 本机注意事项

- 没有 `standalone.cls`（TeX Live 2013）。用 `tex-preview` 包的
  `[active,tightpage]` 达到同样的裁边效果，且不需要 ghostscript。
- 剥注释时**只含注释的整行必须整行删除**，不能只清成空行 ——
  groupplot 环境里一个空行会让 pgfplots 报
  `Paragraph ended before \pgfplots@@environment@groupplot was complete`。

## 交付前请肉眼核一遍

生成后逐张看过再提交（本仓库的循环规则：生成图必肉眼核渲染）。
`fig-preproc.pdf` 已于 2026-07-30 核过：两面板、7 条任务曲线 + 虚线均值、
Okabe-Ito 配色、面板号为 MDPI 的小写加粗 (**a**)/(**b**)，与论文一致。
