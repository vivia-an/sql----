#!/usr/bin/env python3
"""Sync figures and tables from the English manuscript into main_cn.tex.

The Chinese companion shows the same artwork and the same tables as
main_applsci_mdpicls.tex, with Chinese captions. Copying that code by hand would
guarantee the two drift apart, so it is copied by this script instead: every float
body comes from the English source verbatim, and only the caption is replaced.

main_cn.tex marks each float position with a fence:

    %%CNFLOAT-BEGIN:tab:domains%%
    %%CNFLOAT-END:tab:domains%%

Everything between a matching pair is regenerated on every run, so an edit to a
figure in the English manuscript reaches the Chinese one with a single command and
cannot be forgotten. Labels absent from CAPTIONS below are left alone; verify_cn.py
lists which floats have not been brought over yet.

    python3 cn_floats.py            # report what would change
    python3 cn_floats.py --write    # rewrite main_cn.tex
"""
import re
import sys

EN = "main_applsci_mdpicls.tex"
CN = "main_cn.tex"

# Chinese captions. The figure artwork itself is not translated - that was the
# instruction - so in-figure text stays English and the caption carries the
# explanation. Abbreviation glosses are kept because the figures print them.
CAPTIONS = {
    "fig:arch":
        "转换流水线的结构。一条自由文本的医院统计需求依次经过三阶段预处理、"
        "信息抽取、字段与口径映射、SQL 生成，最终在三层临床数据仓库（CDW）上"
        "产出与 Presto 兼容的结构化查询语言（SQL），同时给出字段血缘记录与"
        "全部 TO-CONFIRM 条目。实线箭头表示模块间的数据流；虚线箭头表示各模块"
        "读取元数据知识库的哪一部分。DC：数据中心；DL：数据湖；"
        "JSON：JavaScript 对象表示法；LLM：大语言模型；MDR：主数据仓库。",

    "fig:preproc":
        "预处理各阶段中 token 数与口径条数的递减。(\\textbf{a}) 七项验证任务在切分、"
        "过滤、简化三个阶段的 token 数变化。(\\textbf{b}) 相应的口径条数变化。"
        "所示任务为：RPT-001（各科室月度择期手术量）、RPT-002（非计划再次手术率）、"
        "RPT-003（麻醉后监护室通过量与延迟离室率）、RPT-004（月度输血量与输血反应率）、"
        "RPT-005（检验危急值通报及时率）、RPT-006（手术部位感染监测分母）、"
        "RPT-007（日间手术占手术总量比例）。黑色虚线为各任务的均值。",

    "tab:domains":
        "抽取出的业务术语按临床数据仓库（CDW）\\tnote{1}主题域的分布。",

    "tab:terms":
        "全部任务中出现频次最高的十个业务术语。",

    "tab:retrieval":
        "系统生成查询与已校验参考 SQL\\tnote{1} 的结果集检索对比。",

    "fig:models":
        "八个大语言模型在临床数据仓库（CDW）结构化查询语言（SQL）生成上的表现。"
        "(\\textbf{a}) 各模型的幻觉率与有效 SQL 率，每个模型 120 次尝试。"
        "(\\textbf{b}) 每次查询成本对有效 SQL 率；云端模型画为蓝色方块，"
        "本地模型画为橙色圆点。本地模型没有按次 API 费用，图中按摊薄成本作图，"
        "即推理时间 $\\times$ 每 GPU 小时 0.28 美元（按本院 3 年硬件摊销计）。",

    "tab:modelperf":
        "模型表现汇总。",

    "fig:halluc":
        "各模型的幻觉类型分布，基于 274 条含幻觉的查询。"
        "(\\textbf{a}) 各模型每类幻觉的绝对计数，堆叠显示，柱上方为该模型合计。"
        "类型为 A，不存在的字段标识；B，错误的口径指派；C，标识位置上的自然语言；"
        "D，占位符插入；E，结构与方言错误。"
        "(\\textbf{b}) 同一批计数按各模型自身合计的百分比显示，"
        "以便在不受错误总量影响的情况下比较错误构成；颜色越深表示占该模型合计的比例越小。"
        "两个面板中模型顺序相同。",

    "tab:halluctypes":
        "各模型幻觉类型的详细分布。",

    "tab:abstain":
        "各模型的弃权行为。触发率为 TO-CONFIRM 条目占该模型生成查询数的比例；"
        "精确率为应当弃权者占所提出弃权的比例；漏弃权指模型未加询问即自行决定的"
        "有歧义口径。",

    "tab:ablation":
        "qwen2.5:7b 上的组件消融。每个设置都在同样的 24 项任务与 5 种提示策略下运行，"
        "每设置 120 次尝试。设置 D 即主实验中的 qwen2.5:7b 条件。"
        "错误类别为 A，不存在的字段标识；B，错误的统计口径；C，标识位置上的自然语言；"
        "D，占位符插入；E，结构与方言错误。",

    "fig:ablation":
        "qwen2.5:7b 上的组件消融。设置 A 为裸模型，B 加上仓库结构，"
        "C 加上在元数据知识库上的检索，D 加上四层执行反馈校验。"
        "(\\textbf{a}) 按类别的绝对错误计数，柱上方为合计；"
        "错误类别为 A，不存在的字段标识；B，错误的统计口径；C，标识位置上的自然语言；"
        "D，占位符插入；E，结构与方言错误。注入仓库结构消除了 A 类错误，"
        "却使 B 类错误增加，而只有检索能把 B 类降下来。"
        "(\\textbf{b}) 有效 SQL 率，并标出每一层各自贡献的增量。",
}


def floats_of(text):
    """label -> the full float environment, as written in the source."""
    out = {}
    for m in re.finditer(r"\\begin\{(figure|table)\}(\*?)(.*?)\\end\{\1\2\}",
                         text, re.S):
        lab = re.search(r"\\label\{([^}]*)\}", m.group(3))
        if lab:
            out[lab.group(1)] = m.group(0)
    return out


def swap_caption(block, zh):
    """Replace the caption text, leaving everything else byte-identical."""
    m = re.search(r"\\caption\{", block)
    if not m:
        sys.exit("float has no \\caption: %r" % block[:60])
    i = m.end()
    depth, j = 1, i
    while j < len(block) and depth:
        if block[j] == "{" and block[j - 1] != "\\":
            depth += 1
        elif block[j] == "}" and block[j - 1] != "\\":
            depth -= 1
        j += 1
    return block[:i] + zh + block[j - 1:]


def main():
    en = floats_of(open(EN, encoding="utf-8").read())
    cn = open(CN, encoding="utf-8").read()

    missing = [k for k in CAPTIONS if k not in en]
    if missing:
        sys.exit("captions given for floats not in %s: %s" % (EN, missing))

    changed, absent = [], []
    for lab, zh in CAPTIONS.items():
        b = "%%%%CNFLOAT-BEGIN:%s%%%%" % lab
        e = "%%%%CNFLOAT-END:%s%%%%" % lab
        if b not in cn or e not in cn:
            absent.append(lab)
            continue
        i, j = cn.index(b) + len(b), cn.index(e)
        new = "\n" + swap_caption(en[lab], zh).strip() + "\n"
        if cn[i:j] != new:
            cn = cn[:i] + new + cn[j:]
            changed.append(lab)

    for lab in changed:
        print("  synced   %s" % lab)
    for lab in absent:
        print("  no fence %s  (add %%%%CNFLOAT-BEGIN/END:%s%%%% in %s)"
              % (lab, lab, CN))
    if not changed and not absent:
        print("  nothing to do; all fenced floats already match the source")

    have = set(CAPTIONS)
    todo = sorted(set(en) - have)
    if todo:
        print("\n  %d float(s) still without a Chinese caption: %s"
              % (len(todo), ", ".join(todo)))

    if "--write" in sys.argv:
        open(CN, "w", encoding="utf-8").write(cn)
        print("\nwrote %s" % CN)
    else:
        print("\n(report only; pass --write to update %s)" % CN)


if __name__ == "__main__":
    main()
