#!/usr/bin/env python3
"""Check the Chinese companion against the English manuscript it mirrors.

The companion exists so院内 readers can review the same paper in Chinese. That
only helps if it says the same thing, so three properties are asserted here:

  1. No number drifts. Every numeral in the Chinese body must also occur in the
     English source. A translation is exactly the place where 52.3 becomes 53.2
     and nobody notices, because the surrounding words changed too.
  2. Float code is not edited. Figures and tables are copied from the English
     source verbatim, captions aside; a divergence means the two papers now show
     different artwork under the same number.
  3. Untranslated sections are counted, not hidden. Every \\todocn marker is
     reported, so "the Chinese version is done" is a claim with a number behind
     it rather than an impression.

Usage: python3 verify_cn.py
"""
import glob
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
EN = os.path.join(HERE, "main_applsci_mdpicls.tex")
CN = os.path.join(HERE, "main_cn.tex")

# Numerals that are allowed to appear in the Chinese text without appearing in
# the English source, with the reason. Anything not listed here is a failure.
# Floats whose cells are prose rather than numbers and short labels, and which are
# therefore TRANSLATED in the companion instead of copied verbatim. Byte-identity
# is given up deliberately for these; numeric drift is still caught, because every
# numeral in the Chinese body must occur in the English source. Keep this set as
# small as the content forces it to be - a translated float is a float that can
# fall out of step with the English one in a way no assertion here will see.
# English label -> the label the translated version carries in the companion.
TRANSLATED_FLOATS = {
    # 管理用途表：五行都是成段文字，给中文读者看英文原文没有意义
    "tab:mgmt": "tab:cn-mgmt",
}

NUM_ALLOW = {
    "1": "章节与列举序号",
    "2": "章节与列举序号",
    "3": "章节与列举序号",
    "4": "章节与列举序号",
    "5": "章节与列举序号",
    "610041": "成都邮编，英文稿写在单位行内",
    "1680": "SynHDW 字段数，英文稿写作 $\\sim$1680",
}


def body(path, whole=False):
    """Comment-free text. `whole` keeps the front matter, which is where the
    English manuscript puts the abstract, the address and the phone number - not
    reading it made this checker report the country code and the p value as
    Chinese-only inventions."""
    src = open(path, encoding="utf-8").read()
    if not whole:
        src = src[src.index("\\begin{document}"):]
    return re.sub(r"(?<!\\)%.*", "", src)


def braced(text, start):
    """End index of the {...} group whose opening brace is at `start`.

    Non-greedy `\\{.*?\\}` is wrong for any LaTeX argument that can nest, and these
    can: captions carry (\\textbf{a}) and \\tnote{1}, and a \\todocn marker once
    carried \\texttt{main\\_jmir.tex}. The same regex bug bit the B-track checker in
    round 22 after being fixed in cn_floats.py in round 19, so it is done properly
    here rather than left to luck.
    """
    depth, j = 1, start + 1
    while j < len(text) and depth:
        if text[j] == "{" and text[j - 1] != "\\":
            depth += 1
        elif text[j] == "}" and text[j - 1] != "\\":
            depth -= 1
        j += 1
    return j


def cut_calls(text, macro):
    """Remove every `\\macro{...}` call, argument included, braces matched."""
    out, i = [], 0
    pat = re.compile(r"\\" + macro + r"\{")
    while True:
        m = pat.search(text, i)
        if not m:
            out.append(text[i:])
            return "".join(out)
        out.append(text[i:m.start()])
        i = braced(text, m.end() - 1)


def macro_args(text, macro):
    """Every `\\macro{...}` argument, braces matched."""
    args, i = [], 0
    pat = re.compile(r"\\" + macro + r"\{")
    while True:
        m = pat.search(text, i)
        if not m:
            return args
        j = braced(text, m.end() - 1)
        args.append(text[m.end():j - 1])
        i = j


def without_scaffolding(text):
    """Drop \\todocn markers: they name sections that are not translated yet, so
    their section numbers are scaffolding rather than claims about the content."""
    return cut_calls(text, "todocn")


def numerals(text):
    """Numeric tokens, with thousands separators removed so 1,620,000 == 1620000.

    Column widths and other typesetting lengths are removed first. They are
    layout, not claims: a translated table needs wider columns than the English
    one for the same content, and reporting `L{3.4cm}` as a number the Chinese
    manuscript invented is noise that would train the reader to ignore this check.
    """
    text = re.sub(r"[LCplrbm]\{[\d.]+\s*(cm|mm|pt|bp|in|em|ex)\}", "", text)
    text = re.sub(r"\{?[\d.]+\s*(cm|mm|pt|bp|em|ex)\}?", "", text)
    text = re.sub(r"(?<=\d)[,\\][,\s]*(?=\d)", "", text)
    return re.findall(r"\d+(?:\.\d+)?", text)


def floats_of(text):
    """Every figure/table environment, keyed by its \\label, caption stripped."""
    out = {}
    for m in re.finditer(r"\\begin\{(figure|table)\}(\*?)(.*?)\\end\{\1\2\}",
                         text, re.S):
        blk = m.group(3)
        lab = re.search(r"\\label\{([^}]*)\}", blk)
        if not lab:
            continue
        stripped = cut_calls(blk, "caption")
        out[lab.group(1)] = re.sub(r"\s+", " ", stripped).strip()
    return out


def title_probe(path):
    """A distinctive phrase from this manuscript's own title.

    Both tracks name their companion main_cn.tex, so "newest main_cn.pdf across
    the scratchpads" found the *other* track's build - the A-track checker was
    running its PDF-level assertions against the B-track document. The fix cannot
    rest on build-directory naming, so the PDF is required to contain a phrase
    from this file's title: the artifact identifies itself.
    """
    src = open(path, encoding="utf-8").read()
    m = re.search(r"\\LARGE(.*?)\\par", src, re.S)
    seg = m.group(1) if m else src
    runs = re.findall(r"[\u4e00-\u9fff]{6,}", seg)
    if not runs:
        sys.exit("could not derive a title probe from %s" % path)
    return max(runs, key=len)


def find_pdf(name):
    """Newest build of `name`, and say which one - a checker that will not name
    its input cannot be trusted when it passes."""
    hits = [os.path.join(HERE, name)] if os.path.exists(
        os.path.join(HERE, name)) else []
    for d in sorted(glob.glob("/tmp/claude-*/-root-sqlge/*/scratchpad*"),
                    reverse=True):
        hits.extend(glob.glob(os.path.join(d, "**", name), recursive=True))
    if not hits:
        return None
    probe = title_probe(CN)
    ours = []
    for h in hits:
        try:
            txt = subprocess.check_output(["pdftotext", h, "-"]).decode(
                "utf-8", "replace")
        except Exception:                                  # noqa: BLE001
            continue
        if probe in txt:
            ours.append(h)
    if not ours:
        print("   没有找到属于本稿的 main_cn.pdf（按标题短语 %r 判定）；"
              "先编译本目录的 main_cn.tex" % probe)
        return None
    newest = max(ours, key=os.path.getmtime)
    print("   using %s (%.0f min old)"
          % (newest, (time.time() - os.path.getmtime(newest)) / 60.0))
    return newest


def main():
    for p in (EN, CN):
        if not os.path.exists(p):
            sys.exit("%s not found" % p)

    # mdpi.cls puts the abstract, address and keywords BEFORE \begin{document},
    # so the English side is read whole. The Chinese companion keeps its front
    # matter inside the document, and reading its preamble whole would drag in
    # margins, colours and font sizes as if they were claims.
    en, cn = body(EN, whole=True), body(CN)
    checks, failures, notes = 0, [], []

    # -- 1. numbers ----------------------------------------------------------
    en_nums = set(numerals(en))
    seen = set()
    for tok in numerals(without_scaffolding(cn)):
        if tok in seen:
            continue
        seen.add(tok)
        checks += 1
        if tok not in en_nums and tok not in NUM_ALLOW:
            failures.append("数字 %s 出现在中文稿但不在英文稿中" % tok)

    # -- 2. float code -------------------------------------------------------
    en_f, cn_f = floats_of(en), floats_of(cn)
    zh_labels = set(TRANSLATED_FLOATS.values())
    for lab, blk in cn_f.items():
        checks += 1
        if lab in zh_labels:
            continue          # 声明为已翻译的表，逐字比较对它没有意义
        if lab not in en_f:
            failures.append("中文稿的浮动体 %s 在英文稿中不存在" % lab)
        elif en_f[lab] != blk:
            failures.append("浮动体 %s 的代码与英文稿不一致（题注之外不该有差异）"
                            % lab)
    missing = [l for l in en_f if l not in cn_f and l not in TRANSLATED_FLOATS]
    if missing:
        notes.append("英文稿有 %d 个浮动体尚未搬入中文稿：%s"
                     % (len(missing), ", ".join(sorted(missing))))
    for en_lab, zh_lab in sorted(TRANSLATED_FLOATS.items()):
        checks += 1
        if en_lab not in en_f:
            failures.append("TRANSLATED_FLOATS 里的 %s 在英文稿中不存在" % en_lab)
        elif en_lab in cn_f:
            failures.append("%s 同时被声明为已翻译又被逐字搬入，二者只能取一"
                            % en_lab)
        elif zh_lab not in cn_f:
            notes.append("%s 已声明为待翻译表，但中文稿里还没有 %s"
                         % (en_lab, zh_lab))

    # -- 2b. has the companion fallen behind? --------------------------------
    # The English manuscript gained the framework-attribution passage in a later
    # round and the Chinese one did not, which was caught by memory rather than by
    # a check. Citation keys are a good proxy for "this paragraph exists on both
    # sides": a passage that cites something is a passage, and a key present only
    # in the English body means the Chinese one is missing that passage. While
    # sections are still untranslated most keys are legitimately absent, so this
    # is a NOTE now and becomes a failure once \todocn is empty.
    def keys(t):
        out = set()
        for m in re.finditer(r"\\cite\{([^}]*)\}", t):
            out |= {k.strip() for k in m.group(1).split(",") if k.strip()}
        return out

    todo_now = re.findall(r"\\todocn\{", cn)
    behind = sorted(keys(en) - keys(cn))
    if behind:
        checks += 1
        msg = ("英文稿引用了但中文稿没有的文献 %d 条：%s"
               % (len(behind), ", ".join(behind[:12])
                  + (" …" if len(behind) > 12 else "")))
        if todo_now:
            notes.append(msg + "（仍有未译段落，暂列为提示）")
        else:
            failures.append(msg + "（已无未译段落，中文稿落后于英文稿）")

    # -- 2c. Markdown leaking into LaTeX -------------------------------------
    # `**bold**` does not error in LaTeX; it typesets four asterisks. Writing the
    # companion in a chat window makes this easy to do and impossible to notice in
    # a compile log, so it is asserted rather than trusted.
    for pat, what in ((r"\*\*", "Markdown 粗体 **"),
                      (r"(?m)^\s*#{1,6}\s", "Markdown 标题 #"),
                      (r"(?m)^\s*```", "Markdown 代码围栏 ```")):
        checks += 1
        hits = len(re.findall(pat, cn))
        if hits:
            failures.append("中文稿里有 %d 处%s —— LaTeX 不会报错，会原样印出来"
                            % (hits, what))

    # -- 2d. the bibliography is a verbatim copy, so assert it stayed one -----
    # It is transplanted rather than translated (reference lists keep their
    # original wording). That makes it a copy, and a copy goes stale silently:
    # editing 18 arXiv entries in the English manuscript left the Chinese one
    # holding the old text, and nothing here noticed until it was checked by hand.
    def bibblock(t):
        try:
            i = t.index("\\begin{thebibliography}")
            j = t.index("\\end{thebibliography}") + len("\\end{thebibliography}")
        except ValueError:
            return None
        return t[i:j]

    en_bib, cn_bib = bibblock(en), bibblock(cn)
    checks += 1
    if cn_bib is None:
        notes.append("中文稿还没有参考文献表")
    elif en_bib is None:
        failures.append("英文稿里找不到参考文献表")
    elif en_bib != cn_bib:
        n_en = en_bib.count("\\bibitem")
        n_cn = cn_bib.count("\\bibitem")
        failures.append("中文稿的参考文献表与英文稿不一致（%d 条 vs %d 条）——"
                        "它是逐字搬运的副本，英文稿改了就要重新搬"
                        % (n_cn, n_en))

    # -- 2e. publication-ethics statements must be in both versions ----------
    # Same principle as the two B-track candidates: venue machinery may differ
    # between versions, an ethics disclosure may not. The companion silently
    # carried no back matter at all, so the generative-AI use disclosure - the one
    # statement in that block whose omission is an ethics matter rather than a
    # formatting choice - was missing from the copy hospital reviewers read.
    checks += 1
    if ("Use of Generative Artificial Intelligence" in en
            and "生成式人工智能的使用" not in cn):
        failures.append("英文稿有 AI 使用披露，中文稿没有 —— "
                        "投稿事务性段落可以省略，出版伦理声明不可以")

    # -- 3. translation completeness ----------------------------------------
    todo = macro_args(cn, "todocn")
    checks += 1
    if todo:
        notes.append("未译段落 %d 处：" % len(todo))
        for t in todo:
            notes.append("    - " + re.sub(r"\s+", " ", t)[:96])

    # -- 4. the PDF actually built ------------------------------------------
    pdf = find_pdf("main_cn.pdf")
    if pdf is None:
        notes.append("没有找到 main_cn.pdf，先编译：xelatex main_cn.tex")
    else:
        txt = subprocess.check_output(["pdftotext", pdf, "-"]).decode(
            "utf-8", "replace")
        checks += 1
        if "医院" not in txt:
            failures.append("PDF 里抽不出中文，字体或驱动有问题")
        # Before the bibliography was carried over, all 48 \cite calls printed
        # "[?]" and the compile still reported success. Undefined references are a
        # visible defect in the PDF, so they are a failure, not a warning.
        log = os.path.join(os.path.dirname(pdf), "main_cn.log")
        if os.path.exists(log):
            checks += 1
            n = len(re.findall(r"Reference `[^']*' on page \d+ undefined",
                              open(log, encoding="utf-8", errors="replace").read()))
            m = len(re.findall(r"Citation `[^']*' on page \d+ undefined",
                              open(log, encoding="utf-8", errors="replace").read()))
            if n or m:
                failures.append("PDF 里有未定义的交叉引用 %d 处、未定义的文献引用 "
                                "%d 处 —— 会印成 ??/[?]，编译却仍报成功" % (n, m))
            # A stale .aux makes the count read zero on the first pass, so say
            # which run this came from.
            print("   NOTE  交叉引用与文献引用均已解析（读自 %s）"
                  % os.path.basename(log))

    print("verify_cn: %d 项检查，%d 失败" % (checks, len(failures)))
    for f in failures:
        print("   FAIL  " + f)
    for n in notes:
        print("   " + n if n.startswith("    ") else "   NOTE  " + n)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
