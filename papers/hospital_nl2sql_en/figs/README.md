# figs — figure specs (to be rendered; J2 in PERSPECTIVE_TREE)

## fig_pipeline (Fig. 1) — Overall framework
Flow: NL query → intent recognition → metadata/knowledge retrieval → field recall & criterion
mapping → SQL sub-structure generation (SELECT/FROM-JOIN/WHERE/GROUP BY/ORDER BY) → candidate
synthesis → 4-layer verification (syntax/field/criterion/result) → {pass: output SQL + field
provenance} / {fail: error attribution → context update → regenerate}.
Source: §3 of main.tex; mirror patent AJ2534335 architecture for terminology consistency (no RL).

## fig_results_AtoD (Fig. 2) — Setting-level results A→D
Grouped bar or line: x = settings A/B/C/D; series = exec. rate / key-field consistency /
condition accuracy (%) + secondary axis manual corrections.
**Numbers are author-supplied placeholders — do not render real-looking values until measured.**

## fig_error_taxonomy (Fig. 3) — Error taxonomy
5 classes (non-existent field / time-criterion confusion / condition-value mismatch / wrong join
path / dialect-type) with counts and handling strategy. Counts = PLACEHOLDER.

> Render with matplotlib/draw.io; after rendering, Read the image and eyeball before committing
> (per loop rule: 生成图必 Read 肉眼核渲染).
