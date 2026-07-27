# Overleaf：Applied Sciences（官方 mdpi.cls）

## 主文件
- 设为 `main_applsci_mdpicls.tex`（不要用 `main.tex` / `main_rt.tex`）
- 编译器：pdfLaTeX

## 官方依赖（已入库）
目录 `Definitions/` 来自 MDPI 官方包  
https://www.mdpi.com/authors/latex → `MDPI_template.zip`

至少需要：
- `Definitions/mdpi.cls`
- `Definitions/journalnames.tex`
- `Definitions/logo-mdpi.eps`（`submit` 模式页眉）
- `Definitions/logo-orcid.pdf`、`Definitions/logo-updates.eps`
- `Definitions/mdpi.bst`（及 apa/chicago 变体，按需）

`documentclass` 必须是：
```tex
\documentclass[applsci,article,submit,pdftex,moreauthors]{Definitions/mdpi}
```
写成 `{mdpi}` 且项目根没有 `mdpi.cls` 时，会报 `File mdpi.cls not found`。

## 模拟版（无需官方类）
若只想先看内容排版，可改主文件为 `main_applsci.tex`（`article` 模拟，不依赖 `Definitions/`）。

## 同步后若仍无 PDF
1. Menu → Main document → `main_applsci_mdpicls.tex`
2. 确认左侧有 `Definitions/` 文件夹
3. 若存在根目录 `output.pdf`，先改名或删除
4. Recompile
