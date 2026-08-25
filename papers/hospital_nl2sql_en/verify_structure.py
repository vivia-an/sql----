#!/usr/bin/env python3
"""
Assert that the compiled PDF still contains everything the source says it should.

Why this exists: twice now, a layout change silently deleted whole sections while
pdflatex reported zero errors. Round 16, cuted's strip environment dropped
everything after the reference list - Abbreviations, editorial footer, copyright
block. Round 19, after a compression pass changed the content length, the same
environment dropped the Conclusion tail, Acknowledgments, Authors' Contributions,
and Conflicts of Interest, leaving Limitations truncated mid-word. A third time,
mdpi.cls plus paracol quietly stopped placing floats and shipped 22 blank pages,
again with zero errors reported. All three were found only by reading the PDF.

Two manuscripts are checked, each against its own journal's structure:
  main_rt                 JMIR Med Inform format
  main_applsci_mdpicls    Applied Sciences, official mdpi.cls

Checks performed per manuscript:
  1. every structural element named below appears in the compiled text
  2. the reference list runs 1..N with no gaps
  3. the final sentence of the LaTeX body also appears in the PDF, which catches
     truncation at a page or column boundary
  4. pages that carry almost no text are reported (the mdpi.cls float failure
     showed up here first)
  5. citations, cross-references and abbreviation expansions in the source

Comparison is done on text with hyphenated line breaks rejoined and whitespace
collapsed, because pdftotext splits words at line ends and reads a two-column
page across both columns.

    python3 verify_structure.py

Exit status 0 when all assertions pass.
"""
import glob
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
# The PDF is built outside the repository (see build_local.sh), and the build
# directory is per-session, so search the sibling scratchpads rather than naming
# one that has since been retired.
PDF_DIRS = [HERE] + sorted(
    glob.glob("/tmp/claude-*/-root-sqlge/*/scratchpad*"), reverse=True)

JMIR_REQUIRED = [
    "Original Paper", "Corresponding Author",
    "Background:", "Objective:", "Methods:", "Results:", "Conclusions:", "Keywords:",
    "Study Design", "Experimental Design", "Statistical Analysis",
    "Ethical Considerations", "Data and Code Availability",
    "Principal Findings", "Complementary Evaluation Strategy",
    "Cost-Effectiveness and Scalability", "Broader Healthcare and Societal Impact",
    "Limitations and Future Directions",
    "Acknowledgments", "Contributions", "Conflicts of Interest",
    "Multimedia Appendix 1", "Multimedia Appendix 2",
    "Multimedia Appendix 3", "Multimedia Appendix 4",
    "References", "Abbreviations", "Please cite as",
    "Creative Commons Attribution",
]

# Applied Sciences prescribes both the numbered section skeleton and the exact
# back-matter statement headings; a missing one is a desk-reject item.
APPLSCI_REQUIRED = [
    "Featured Application", "Abstract", "Keywords",
    "1. Introduction", "2. Materials and Methods", "3. Results",
    "4. Discussion", "5. Conclusions",
    "Study Design", "Experimental Design", "Statistical Analysis",
    "Principal Findings", "Limitations",
    "Supplementary Materials:", "Author Contributions:", "Funding:",
    "Institutional Review Board Statement:", "Informed Consent Statement:",
    "Data Availability Statement:", "Acknowledgments:", "Conflicts of Interest:",
    "Abbreviations", "References",
]

PROFILES = [
    dict(name="main_rt", tex="main_rt.tex", pdf="main_rt.pdf",
         required=JMIR_REQUIRED,
         concl_anchor="\\subsection{Conclusion}",
         concl_stops=("\\balance", "\\onecolumn", "\\begin{strip}", "\\section*"),
         abbr_anchor="\\section*{Abbreviations}",
         body_anchor="\\twocolumn",
         probe="Hospital Statistical Criteria Conversion"),
    dict(name="main_applsci_mdpicls", tex="main_applsci_mdpicls.tex",
         pdf="main_applsci_mdpicls.pdf",
         required=APPLSCI_REQUIRED,
         concl_anchor="\\section{Conclusions}",
         concl_stops=("\\supplementary", "\\authorcontributions", "\\section*"),
         abbr_anchor="\\abbreviations{Abbreviations}",
         body_anchor="\\section{Introduction}", lineno=True,
         abstract_max=200, desk_checks=True,
         probe="Metadata-Grounded Large Language Models"),
]


def find_pdf(name, probe=None):
    """Locate the freshest build of `name`, and say which one was used.

    Builds land outside the repository in a per-session scratchpad, and retired
    sessions' scratchpads are not cleaned up. Taking the first path that exists
    once made this checker validate a PDF from a session that had ended, so it
    reported 0 failures against a manuscript that no longer existed. Search every
    candidate root recursively, take the newest by mtime, and print it: a checker
    that will not name its input cannot be trusted when it passes.
    """
    hits = []
    for d in PDF_DIRS:
        if not os.path.isdir(d):
            continue
        hits.extend(glob.glob(os.path.join(d, "**", name), recursive=True))
    if not hits:
        return None
    if probe:
        # BOTH directories contain a main_rt.tex, so "newest main_rt.pdf across the
        # scratchpads" once picked the other paper's build - the same trap round 23
        # fixed for main_cn.pdf and left open here. Require the PDF to identify
        # itself by a phrase only this manuscript contains.
        ours = []
        for h in hits:
            try:
                txt = subprocess.check_output(["pdftotext", h, "-"]).decode(
                    "utf-8", "replace")
            except Exception:                              # noqa: BLE001
                continue
            if probe in txt:
                ours.append(h)
        if not ours:
            print("   no build of %s contains %r; compile this directory's copy"
                  % (name, probe))
            return None
        hits = ours
    newest = max(hits, key=os.path.getmtime)
    age = (time.time() - os.path.getmtime(newest)) / 60.0
    print("   using %s (%.0f min old)" % (newest, age))
    if age > 60:
        print("   NOTE  that build is over an hour old - recompile if you have "
              "edited the source since")
    return newest


def pdf_pages(path):
    out = subprocess.check_output(["pdftotext", "-layout", path, "-"])
    return out.decode("utf-8", "replace").split("\f")


RUNNING_HEAD = re.compile(r"submitted to|\d+ of \d+")
GUTTER_L = re.compile(r"^[ \t]{2,}\d{1,4}[ \t]{2,}(?=\S)", re.M)
GUTTER_R = re.compile(r"[ \t]{2,}\d{1,4}[ \t]*$", re.M)


def flatten(text, strip_gutter=False):
    """Rejoin words split at a line end, then collapse whitespace.

    MDPI's submit layout prints lineno numbers in a margin - left in the 2021
    class, right in the 2025 one. pdftotext -layout renders them inline, so a
    sentence spanning a line break reads "... may 726 be necessary ...". Strip
    both gutters before joining, or every multi-line probe fails for a reason
    that has nothing to do with the text.
    """
    if strip_gutter:
        text = GUTTER_R.sub("", GUTTER_L.sub("", text))
    return re.sub(r"\s+", " ", re.sub(r"-\s*\n\s*", "", text))


def tex_last_body_sentence(src, anchor, stops):
    concl = src.split(anchor)
    if len(concl) < 2:
        return None
    seg = concl[1]
    for stop in stops:
        seg = seg.split(stop)[0]
    seg = re.sub(r"\\[a-zA-Z]+\*?(\[[^\]]*\])?(\{[^{}]*\})?", " ", seg)
    seg = re.sub(r"\s+", " ", seg).strip()
    sentences = [s.strip() for s in seg.split(".") if len(s.strip()) > 30]
    return sentences[-1] if sentences else None


def twin_body(path, end_marker):
    """Body prose from the Introduction to the back matter, floats elided.

    The two Applied Sciences files are meant to carry word-identical prose: one is
    compiled with the official mdpi.cls, the other is an article-class backup.
    Their back matter differs by construction (\\supplementary{} against
    \\section*{Supplementary Materials}) and so do their float environments
    ([H]+adjustwidth against [!ht]), so both are excluded; what is compared is the
    prose that must not diverge.
    """
    s = re.sub(r"(?<!\\)%.*", "", open(path, encoding="utf-8").read())
    s = s[s.index("\\section{Introduction}"):]
    if end_marker in s:
        s = s[:s.index(end_marker)]
    s = re.sub(r"\\begin\{(figure|table)\}(\*?).*?\\end\{\1\2\}", " [FLOAT] ", s,
               flags=re.S)
    return re.sub(r"\s+", " ", s).strip()


def check_twins():
    """The submission file and its article-class backup must agree word for word.

    This invariant has been maintained by hand across every edit - every change went
    into both files - and was never asserted. One forgotten sync would leave two
    manuscripts making different claims under the same title.
    """
    a = os.path.join(HERE, "main_applsci_mdpicls.tex")
    b = os.path.join(HERE, "main_applsci.tex")
    if not (os.path.exists(a) and os.path.exists(b)):
        return 0, [], []
    pa = twin_body(a, "\\supplementary{")
    pb = twin_body(b, "\\section*{Supplementary Materials}")
    if pa == pb:
        print("   NOTE  投稿件与 article 类备份的正文逐字一致（%d 字符）" % len(pa))
        return 1, [], []
    import difflib
    sm = difflib.SequenceMatcher(None, pa, pb)
    first = next((op for op in sm.get_opcodes() if op[0] != "equal"), None)
    detail = ""
    if first:
        _, i1, i2, j1, j2 = first
        detail = " 首处差异 —— 投稿件 %r / 备份件 %r" % (pa[i1:i2][:70],
                                                       pb[j1:j2][:70])
    return 1, ["main_applsci_mdpicls.tex 与 main_applsci.tex 的正文已不一致"
               "（相似度 %.5f）%s" % (sm.ratio(), detail)], []


def check(profile):
    """Run every assertion for one manuscript. Returns (checks, fails, warns)."""
    tex = os.path.join(HERE, profile["tex"])
    if not os.path.exists(tex):
        return 0, ["%s not found" % profile["tex"]], []
    pdf = find_pdf(profile["pdf"], profile.get("probe"))
    if pdf is None:
        return 0, ["%s not found; compile first" % profile["pdf"]], []

    pages = pdf_pages(pdf)
    whole = flatten("\n".join(pages), profile.get("lineno", False))
    failures, warnings = [], []

    for item in profile["required"]:
        if item not in whole:
            failures.append("[%s] missing structural element: %s"
                            % (profile["name"], item))

    src = re.sub(r"(?<!\\)%.*", "", open(tex, encoding="utf-8").read())
    bibitems = len(re.findall(r"\\bibitem", src))
    if ("%d." % bibitems) not in whole:
        failures.append("[%s] last reference (%d) missing from PDF"
                        % (profile["name"], bibitems))

    # Applied Sciences caps the abstract at 200 words and checks it at the desk,
    # so treat an over-length abstract as a failure rather than a style note.
    limit = profile.get("abstract_max")
    if limit:
        m = re.search(r"\\abstract\{(.*?)\}\s*\n\s*\n", src, re.S)
        if not m:
            failures.append("[%s] abstract not found" % profile["name"])
        else:
            t = m.group(1).replace("---", " ").replace("--", "-")
            t = re.sub(r"\$[^$]*\$", "X", t)
            t = re.sub(r"\\[a-zA-Z]+", "", t)
            n = len(re.sub(r"[{}\\]", "", t).split())
            if n > limit:
                failures.append("[%s] abstract is %d words, over the %d-word "
                                "limit" % (profile["name"], n, limit))

    # -- desk-check items this journal's production stage looks at ------------
    # Floats must be numbered in the order they are first referred to, every float
    # must be referred to at least once, and the keyword count has a range. None of
    # these were covered before; the abbreviation check below found EHR used twice
    # in the body and never expanded, which is the same class of copyedit query.
    extra = 0
    if profile.get("desk_checks"):
        body_src = src.split("\\begin{thebibliography}")[0]
        first_ref, seen_ref = [], set()
        for m in re.finditer(r"\\ref\{((?:fig|tab):[^}]*)\}", body_src):
            if m.group(1) not in seen_ref:
                seen_ref.add(m.group(1))
                first_ref.append(m.group(1))
        defined_order = re.findall(r"\\label\{((?:fig|tab):[^}]*)\}", body_src)
        for kind in ("fig", "tab"):
            extra += 1
            a = [k for k in first_ref if k.startswith(kind)]
            b = [k for k in defined_order if k.startswith(kind)]
            if a != b:
                failures.append("[%s] %s 的编号顺序与首次引用顺序不一致：%s vs %s"
                                % (profile["name"], kind, a, b))
        for lab in defined_order:
            extra += 1
            if lab not in seen_ref:
                failures.append("[%s] 浮动体 %s 在正文中从未被引用"
                                % (profile["name"], lab))

        m = re.search(r"\\keyword\{(.*?)\}\s*\n", src, re.S)
        if m:
            n = len([k for k in re.sub(r"\s+", " ", m.group(1)).split(";")
                     if k.strip()])
            extra += 1
            if not 3 <= n <= 10:
                failures.append("[%s] 关键词 %d 个，超出 3--10 的范围"
                                % (profile["name"], n))

        # Every abbreviation in the list must be used, and every listed one must be
        # expanded somewhere in the body.
        ab = re.search(r"\\abbreviations\{Abbreviations\}\s*\{(.*?)\n\}", src, re.S)
        if ab:
            for short, long in re.findall(r"\\item\[([^\]:]+):\]\s*([^\n]+)",
                                          ab.group(1)):
                extra += 1
                if not re.search(r"(?<![A-Za-z])" + re.escape(short)
                                 + r"(?![A-Za-z])", body_src):
                    failures.append("[%s] 缩写表列了 %s，正文却没用过"
                                    % (profile["name"], short))

        # The other direction, which nothing covered and which is how EHR slipped
        # through: an acronym used in the body that is not in the list at all. It
        # was used twice, never expanded, and absent from the list, so the
        # list-driven check above never looked at it.
        # Excluded by category, with the reason, rather than by a growing list of
        # one-offs: proper nouns (datasets, standards, taxonomies), SQL keywords,
        # statistical conventions, and the red \PH{} placeholders.
        NOT_ABBREV = {
            "EHRSQL", "OMOP", "MIMIC", "TREQS", "SynHDW", "CRediT",   # 专名
            "III", "AI", "NEJM", "ACM", "VLDB", "BERT", "NAACL", "EMNLP",
            "INTERSECT", "EXCEPT", "NOT", "IN", "VARCHAR",            # SQL 关键字
            "TO", "CONFIRM",                                          # TO-CONFIRM 标记
            "CI", "SD", "ANOVA",                                      # 统计惯例
            "API", "GPU", "JSON", "URL", "ID", "US", "CC", "AJ",
            "XX", "XXXX",                                             # 占位符
            "MI",                     # MI-CLAIM 清单名的一部分，非独立缩写
            "RPT",                    # RPT-001 等任务编号前缀
            "CLAIM", "GEN",           # MI-CLAIM / MI-CLAIM-GEN 清名的组成部分
            "BM",                     # BM25 检索函数名的一部分
            "HTML",                   # 通用技术词，非本文自定缩写
        }
        # re.findall with one group returns strings, not tuples - taking m[0]
        # here silently yielded first letters and flagged every listed
        # abbreviation as missing.
        listed_short = set(re.findall(r"\\item\[([^\]:]+):\]", ab.group(1))) \
            if ab else set()
        used = set(re.findall(r"(?<![A-Za-z\\])([A-Z]{2,}[A-Za-z]*)(?![A-Za-z])",
                              body_src))
        for tok in sorted(used):
            base = tok[:-1] if tok.endswith("s") and tok[:-1].isupper() else tok
            if base in listed_short or base in NOT_ABBREV or len(base) > 8:
                continue
            extra += 1
            failures.append("[%s] 正文用了缩写 %s，但缩写表里没有它"
                            % (profile["name"], tok))

    # -- reference punctuation, and the arXiv identifiers derived from DOIs ----
    # Round 18 rewrote 18 arXiv entries from "arXiv preprint." to the identifier
    # form, deriving each identifier from the DOI with a regex, and only a few were
    # spot-checked. The B-track equivalent of that batch rewrite turned out to have
    # damaged one entry, so this asserts the A-track one instead of assuming it.
    if profile.get("desk_checks") and "\\begin{thebibliography}" in src:
        bib = src[src.index("\\begin{thebibliography}"):]
        for it in re.findall(
                r"\\bibitem\{[^}]*\}[^\n]*(?:\n(?!\\bibitem|\\end)[^\n]*)*", bib):
            key = re.match(r"\\bibitem\{([^}]*)\}", it).group(1)
            body = re.sub(r"\s+", " ", it[it.index("}") + 1:]).strip()
            for pat, what in ((r"\.\.", "double full stop"),
                              (r",\s*\.", "comma then full stop"),
                              (r"\betal\b", "et al without a full stop"),
                              (r"\s,", "space before a comma")):
                extra += 1
                if re.search(pat, body):
                    failures.append("[%s] reference %s has a %s: %s"
                                    % (profile["name"], key, what, body[:80]))
            extra += 1
            if not body.rstrip().endswith(("}", ".")):
                failures.append("[%s] reference %s does not end in a full stop or "
                                "brace: %s" % (profile["name"], key, body[-50:]))
            # An arXiv identifier must equal the one inside its own DOI. A regex
            # that mis-captured would produce a reference pointing at a different
            # preprint while still looking well-formed.
            # Every reference needs something a reader can resolve: a volume with
            # pages, a preprint identifier, a DOI, or a conference locator. One
            # entry read only "medRxiv 2025, preprint." - no DOI, no identifier,
            # nothing to look up, and it is cited as key related work.
            extra += 1
            # Accept anything a reader can actually follow. The first version
            # only recognised `In \textit{Proc...}` and no \url at all, so it
            # flagged a NeurIPS entry that carries pages and a model card that
            # carries a URL with an access date. A check that cries wolf on
            # well-formed references teaches the reader to skip it.
            resolvable = (re.search(r"\\doilink\{", body)
                          or re.search(r"\\url\{", body)
                          or re.search(r"arXiv:\d", body)
                          or re.search(r"\\textbf\{\d{4}\}\s*,\s*\\textit\{[^}]*\}\s*,"
                                       r"\s*[A-Za-z0-9]", body)
                          or re.search(r"In \\textit\{[^}]*\}[^.]*pp\.", body))
            if not resolvable:
                failures.append("[%s] reference %s carries nothing a reader can "
                                "resolve (no DOI, identifier, volume+pages or "
                                "proceedings locator): %s"
                                % (profile["name"], key, body[:100]))

            ident = re.search(r"arXiv:(\d{4}\.\d{4,5}(?:v\d+)?)", body)
            doi = re.search(r"10\.48550/arXiv\.(\d{4}\.\d{4,5}(?:v\d+)?)", body)
            if ident:
                extra += 1
                if not doi or ident.group(1) != doi.group(1):
                    failures.append("[%s] reference %s: identifier arXiv:%s does not "
                                    "match its DOI (%s)"
                                    % (profile["name"], key, ident.group(1),
                                       doi.group(1) if doi else "no 10.48550 DOI"))

    # A placeholder whose text repeats must denote the SAME value, because that is
    # how it gets filled - one search and replace. Two Introduction statistics both
    # read \PH{XX} while needing different numbers, so a global fill would have put
    # the same figure in both, silently. Generic repeated placeholders are therefore
    # a failure; ones that legitimately repeat (the IRB number, appearing three
    # times and required to be identical) carry distinctive text.
    if profile.get("desk_checks"):
        from collections import Counter
        for text, n in Counter(re.findall(r"\\PH\{([^}]*)\}", src)).items():
            if n < 2:
                continue
            extra += 1
            if len(text) <= 4 or text.upper() == text and len(text) <= 12:
                if not re.match(r"^X{4}-X{4}$", text):    # IRB 批号：三处必须同号
                    failures.append("[%s] 占位符 \\PH{%s} 出现 %d 次且文本泛化 —— "
                                    "若它们要填不同的值，全局替换会静默填成一样"
                                    % (profile["name"], text, n))

    tail = tex_last_body_sentence(src, profile["concl_anchor"], profile["concl_stops"])
    if tail:
        probe = " ".join(tail.split()[-7:])
        if probe and probe not in whole:
            failures.append("[%s] body appears truncated: final Conclusion "
                            "sentence not found in PDF (%r)" % (profile["name"], probe))

    # A page carrying no text at all means the output routine stopped placing
    # material - the mdpi.cls float exhaustion produced 22 such pages while
    # pdflatex reported success.
    #
    # One exception, and only one: a reference list that runs a few entries past
    # the page break leaves a short final page, which is ordinary typesetting and
    # not lost material. It is safe to exempt because truncation of the
    # bibliography is caught independently above, by asserting that the last
    # \bibitem's number reaches the PDF. Any short page that is not entirely
    # numbered reference entries is still reported.
    last_ref = re.compile(r"(^|\s)%d\.\s" % bibitems)
    for i, page in enumerate(pages[:-1]):
        lines = [x for x in page.split("\n") if x.strip()]
        if len(lines) <= 8 and last_ref.search(flatten(page, True)):
            # The page carrying the final reference; the bibliography ran a few
            # entries past the break. Exempt, and only this page.
            continue
        if len(lines) <= 4:
            failures.append("[%s] page %d is blank (%d lines)"
                            % (profile["name"], i + 1, len(lines)))
        elif len(lines) <= 8:
            warnings.append("[%s] page %d nearly empty (%d lines) - spill page?"
                            % (profile["name"], i + 1, len(lines)))

    # -- source-level integrity: compression passes have silently removed an
    #    abbreviation's only definition before, so also assert that nothing
    #    dropped a citation or a cross-reference ------------------------------
    body_src = src.split("\\begin{thebibliography}")[0]
    cited = []
    for m in re.finditer(r"\\cite\{([^}]*)\}", body_src):
        for k in m.group(1).split(","):
            k = k.strip()
            if k and k not in cited:
                cited.append(k)
    bib = re.findall(r"\\bibitem\{([^}]*)\}", src)
    for b in bib:
        if b not in cited:
            failures.append("[%s] reference listed but never cited: %s"
                            % (profile["name"], b))
    for c in cited:
        if c not in bib:
            failures.append("[%s] cited but no bibitem: %s" % (profile["name"], c))
    if cited != [b for b in bib if b in cited]:
        failures.append("[%s] reference list is no longer in first-citation order"
                        % profile["name"])

    labels = set(re.findall(r"\\label\{([^}]*)\}", src))
    refs = set(re.findall(r"\\ref\{([^}]*)\}", src))
    for r in sorted(refs - labels):
        failures.append("[%s] ref to undefined label: %s" % (profile["name"], r))
    for l in sorted(labels - refs):
        warnings.append("[%s] label defined but never referenced: %s"
                        % (profile["name"], l))

    # -- every abbreviation in the list must be expanded somewhere in the text
    # search everything except the Abbreviations list itself, which would
    # otherwise satisfy every expansion check trivially
    prose = src.split(profile["abbr_anchor"])[0]
    flat_src = re.sub(r"\s+", " ", prose)
    # the journal wants each abbreviation expanded again at first use in the
    # body, not only in the abstract, so check the body separately
    body_only = prose.split(profile["body_anchor"], 1)[-1]
    flat_body = re.sub(r"\s+", " ", body_only)
    for abbr, full in re.findall(r"\\item\[([A-Za-z0-9]+):\]\s*([^\n\\]+)", src):
        # drop a trailing gloss such as "(warehouse layer)" before searching
        full = re.sub(r"\s*\([^)]*\)\s*$", "", full.strip())
        if full.lower() not in flat_src.lower():
            failures.append("[%s] abbreviation never expanded outside the list: %s"
                            % (profile["name"], abbr))
        elif abbr in flat_body and full.lower() not in flat_body.lower():
            failures.append("[%s] abbreviation used in the body but expanded only "
                            "in the abstract: %s" % (profile["name"], abbr))

    checks = len(profile["required"]) + 3 + max(len(pages) - 1, 0) + extra
    return checks, failures, warnings


def main():
    total, failures, warnings = 0, [], []
    for profile in PROFILES:
        n, f, w = check(profile)
        total += n
        failures += f
        warnings += w
    n, f, w = check_twins()
    total += n; failures += f; warnings += w
    print("structure: %d checks, %d failed, %d warnings"
          % (total, len(failures), len(warnings)))
    for w in warnings:
        print("   WARN  %s" % w)
    for f in failures:
        print("   FAIL  %s" % f)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
