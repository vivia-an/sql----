#!/usr/bin/env python3
"""
Assert that the compiled PDF still contains everything the source says it should.

Why this exists: twice now, a layout change silently deleted whole sections while
pdflatex reported zero errors. Round 16, cuted's strip environment dropped
everything after the reference list - Abbreviations, editorial footer, copyright
block. Round 19, after a compression pass changed the content length, the same
environment dropped the Conclusion tail, Acknowledgments, Authors' Contributions,
and Conflicts of Interest, leaving Limitations truncated mid-word. Both were
found only by reading the PDF page by page.

Checks performed:
  1. every structural element named below appears in the compiled text
  2. the reference list runs 1..N with no gaps
  3. the final sentence of the LaTeX body also appears in the PDF, which catches
     truncation at a page or column boundary
  4. near-empty pages are reported as warnings (a spill page is legitimate; a
     blank one usually is not)

Comparison is done on text with hyphenated line breaks rejoined and whitespace
collapsed, because pdftotext splits words at line ends and reads a two-column
page across both columns.

    python3 verify_structure.py

Exit status 0 when all assertions pass.
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, "main_rt.tex")
PDF_DIRS = [HERE, "/tmp/claude-0/-root-sqlge/3e42dd89-1e2f-4616-b67a-a3ac6ec61a6c/scratchpad"]

REQUIRED = [
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


def find_pdf():
    for d in PDF_DIRS:
        p = os.path.join(d, "main_rt.pdf")
        if os.path.exists(p):
            return p
    return None


def pdf_pages(path):
    out = subprocess.check_output(["pdftotext", "-layout", path, "-"])
    return out.decode("utf-8", "replace").split("\f")


def flatten(text):
    """Rejoin words split at a line end, then collapse whitespace."""
    return re.sub(r"\s+", " ", re.sub(r"-\s*\n\s*", "", text))


def tex_last_body_sentence(path):
    src = re.sub(r"(?<!\\)%.*", "", open(path, encoding="utf-8").read())
    concl = src.split("\\subsection{Conclusion}")
    if len(concl) < 2:
        return None
    for stop in ("\\balance", "\\onecolumn", "\\begin{strip}", "\\section*"):
        concl[1] = concl[1].split(stop)[0]
    seg = concl[1]
    seg = re.sub(r"\\[a-zA-Z]+\*?(\[[^\]]*\])?(\{[^{}]*\})?", " ", seg)
    seg = re.sub(r"\s+", " ", seg).strip()
    sentences = [s.strip() for s in seg.split(".") if len(s.strip()) > 30]
    return sentences[-1] if sentences else None


def main():
    pdf = find_pdf()
    if pdf is None:
        print("main_rt.pdf not found; compile first")
        return 1
    pages = pdf_pages(pdf)
    whole = flatten("\n".join(pages))
    failures, warnings = [], []

    for item in REQUIRED:
        if item not in whole:
            failures.append("missing structural element: %s" % item)

    nums = sorted(int(m) for m in re.findall(r"(?:^|\s)(\d{1,2})\.\s+[A-Z]", whole))
    refs = [n for n in nums if 1 <= n <= 60]
    if refs:
        top = max(refs)
        gaps = [n for n in range(1, top + 1) if n not in refs]
        if gaps:
            warnings.append("reference numbers not all detected: %s (regex is "
                            "approximate for entries starting with an acronym)" % gaps[:8])
    bibitems = len(re.findall(r"\\bibitem", open(TEX, encoding="utf-8").read()))
    if ("%d." % bibitems) not in whole:
        failures.append("last reference (%d) missing from PDF" % bibitems)

    tail = tex_last_body_sentence(TEX)
    if tail:
        probe = " ".join(tail.split()[-7:])
        if probe and probe not in whole:
            failures.append("body appears truncated: final Conclusion sentence "
                            "not found in PDF (%r)" % probe)

    for i, page in enumerate(pages[:-1]):
        lines = [x for x in page.split("\n") if x.strip()]
        if len(lines) <= 4:
            failures.append("page %d is blank (%d lines)" % (i + 1, len(lines)))
        elif len(lines) <= 8:
            warnings.append("page %d nearly empty (%d lines) - spill page?"
                            % (i + 1, len(lines)))

    # -- source-level integrity: compression passes have silently removed an
    #    abbreviation's only definition before, so also assert that nothing
    #    dropped a citation or a cross-reference ------------------------------
    src = re.sub(r"(?<!\\)%.*", "", open(TEX, encoding="utf-8").read())
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
            failures.append("reference listed but never cited: %s" % b)
    for c in cited:
        if c not in bib:
            failures.append("cited but no bibitem: %s" % c)
    if cited != [b for b in bib if b in cited]:
        failures.append("reference list is no longer in first-citation order")

    labels = set(re.findall(r"\\label\{([^}]*)\}", src))
    refs = set(re.findall(r"\\ref\{([^}]*)\}", src))
    for r in sorted(refs - labels):
        failures.append("ref to undefined label: %s" % r)
    for l in sorted(labels - refs):
        warnings.append("label defined but never referenced: %s" % l)

    # -- every abbreviation in the list must be expanded somewhere in the text
    # search everything except the Abbreviations list itself, which would
    # otherwise satisfy every expansion check trivially
    prose = src.split("\\section*{Abbreviations}")[0]
    flat_src = re.sub(r"\s+", " ", prose)
    # the journal wants each abbreviation expanded again at first use in the
    # body, not only in the abstract, so check the body separately
    body_only = prose.split("\\twocolumn", 1)[-1]
    flat_body = re.sub(r"\s+", " ", body_only)
    for abbr, full in re.findall(r"\\item\[([A-Za-z0-9]+):\]\s*([^\n\\]+)", src):
        # drop a trailing gloss such as "(warehouse layer)" before searching
        full = re.sub(r"\s*\([^)]*\)\s*$", "", full.strip())
        if full.lower() not in flat_src.lower():
            failures.append("abbreviation never expanded outside the list: %s" % abbr)
        elif abbr in flat_body and full.lower() not in flat_body.lower():
            failures.append("abbreviation used in the body but expanded only in "
                            "the abstract: %s" % abbr)

    print("structure: %d checks, %d failed, %d warnings"
          % (len(REQUIRED) + 3 + len(pages) - 1, len(failures), len(warnings)))
    for w in warnings:
        print("   WARN  %s" % w)
    for f in failures:
        print("   FAIL  %s" % f)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
