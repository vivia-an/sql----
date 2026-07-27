#!/usr/bin/env python3
"""
Cross-check every number in main_rt.tex against the canonical data in
DATA_FILL_SHEET.md.

Why this exists: several editing passes were applied by scripts that aborted
part-way on a failed anchor match and wrote nothing, while the run was reported
as successful. Ad-hoc checking against flattened PDF text produced both false
negatives (values split across a line break) and false positives (adjacent
numbers concatenating once whitespace was stripped, e.g. "d=0.74" followed by
"2.71" appearing to contain "74.2"). This script reads the LaTeX source, strips
only unescaped comments, and matches whitespace-insensitively.

Run after any change to the data or to the tables and figures:

    python3 verify_numbers.py

Exit status is 0 when every check passes, 1 otherwise.
"""
import re
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, "main_rt.tex")
APPLSCI = os.path.join(HERE, "main_applsci.tex")
TOVERIFY = os.path.join(HERE, "TO_VERIFY.md")
SHEET = os.path.join(HERE, "DATA_FILL_SHEET.md")
ATTEMPTS = 120  # 24 tasks x 5 prompting strategies


def load_models(path):
    """Pull the eight (name, generated, hallucinating, [A..E], time, sd, cost)
    tuples out of the YAML block in the fill sheet."""
    src = open(path, encoding="utf-8").read()
    block = src.split("models:", 1)[1].split("gpu_amortized", 1)[0]
    pat = re.compile(
        r"name:\s*([^,]+),\s*deploy:\s*(\w+),\s*generated:\s*(\d+),\s*"
        r"hallucinating:\s*(\d+),\s*hall_types:\s*\[([^\]]+)\],\s*"
        r"time_mean:\s*([\d.]+),\s*time_sd:\s*([\d.]+),\s*cost_per_query:\s*([\d.]+)")
    out = []
    for m in pat.finditer(block):
        out.append((m.group(1).strip(), m.group(2),
                    int(m.group(3)), int(m.group(4)),
                    [int(x) for x in m.group(5).split(",")],
                    float(m.group(6)), float(m.group(7)), float(m.group(8))))
    return out


def load_tex(path):
    raw = open(path, encoding="utf-8").read()
    body = re.sub(r"(?<!\\)%.*", "", raw)      # strip only unescaped comments
    return re.sub(r"\s+", " ", body)


class Checker:
    def __init__(self):
        self.passed = 0
        self.failed = []

    def __call__(self, label, cond, detail=""):
        if cond:
            self.passed += 1
        else:
            self.failed.append((label, detail))

    def report(self):
        print("passed %d, failed %d" % (self.passed, len(self.failed)))
        for label, detail in self.failed:
            print("   FAIL  %-34s %s" % (label, detail))
        return 0 if not self.failed else 1


def main():
    models = load_models(SHEET)
    if len(models) != 8:
        print("could not parse eight models from %s" % SHEET)
        return 1
    flat = load_tex(TEX)
    chk = Checker()

    generated = sum(m[2] for m in models)
    hallucinating = sum(m[3] for m in models)
    categories = [sum(m[4][i] for m in models) for i in range(5)]

    # -- per model: row sums, and the three rates Table 4 publishes ------------
    for name, deploy, g, h, types, tmean, tsd, cost in models:
        chk("%s row sum" % name, sum(types) == h, "%d vs %d" % (sum(types), h))

        gen_rate, hall_rate, eff_rate = g / ATTEMPTS * 100, h / g * 100, (g - h) / ATTEMPTS * 100
        row = re.search(
            re.escape(name) + r"\s*&\s*(On-premises|Cloud)\s*&\s*([\d.]+)\s*&\s*([\d.]+)"
            r"[^&]*&\s*([\d.]+)\s*&\s*([\d.]+)\$\\pm\$([\d.]+)\s*&\s*([\d.]+)", flat)
        if row is None:
            chk("Table 4 row %s" % name, False, "row not found")
            continue
        chk("T4 %s generation" % name, abs(float(row.group(2)) - round(gen_rate, 1)) < 0.051,
            "%s vs %.1f" % (row.group(2), gen_rate))
        chk("T4 %s hallucination" % name, abs(float(row.group(3)) - round(hall_rate, 1)) < 0.051,
            "%s vs %.1f" % (row.group(3), hall_rate))
        chk("T4 %s effective" % name, abs(float(row.group(4)) - round(eff_rate, 1)) < 0.051,
            "%s vs %.1f" % (row.group(4), eff_rate))
        chk("T4 %s time" % name,
            abs(float(row.group(5)) - tmean) < 0.051 and abs(float(row.group(6)) - tsd) < 0.051, "")

        # -- Table 5: cells must equal hall_types and percentages must recompute
        cells = re.search(
            re.escape(name) + r"\s*&\s*(\d+)" + r"\s*&\s*(\d+)\s*\(([\d.]+)\)" * 5, flat)
        if cells is None:
            chk("Table 5 row %s" % name, False, "row not found")
            continue
        chk("T5 %s total" % name, int(cells.group(1)) == h, "%s vs %d" % (cells.group(1), h))
        got = [int(cells.group(2 + 2 * i)) for i in range(5)]
        pct = [float(cells.group(3 + 2 * i)) for i in range(5)]
        chk("T5 %s cells" % name, got == types, "%s vs %s" % (got, types))
        chk("T5 %s percentages" % name,
            all(abs(p - c / h * 100) < 0.06 for p, c in zip(pct, got)), str(pct))

    # -- pooled figures quoted in the prose -----------------------------------
    chk("pooled n=%d/%d" % (hallucinating, generated),
        "n=%d/%d generated queries" % (hallucinating, generated) in flat, "")
    chk("pooled rate", "%.1f\\%%" % (hallucinating / generated * 100) in flat, "")
    chk("ANOVA df2 = generated - 8", "F_{7,%d}" % (generated - 8) in flat, "")
    chk("category totals sum to hallucinating", sum(categories) == hallucinating, str(categories))
    for letter, total in zip("ABCDE", categories):
        chk("category %s n=%d in prose" % (letter, total), "n=%d" % total in flat, "")

    # -- restricted pool (models generating on >80% of attempts) --------------
    kept = [m for m in models if m[2] / ATTEMPTS * 100 > 80]
    rg, rh = sum(m[2] for m in kept), sum(m[3] for m in kept)
    chk("restricted pool n=%d/%d" % (rh, rg), "n=%d/%d" % (rh, rg) in flat, "")

    # -- effective rate is a binomial proportion, so the identity must hold ---
    for name, deploy, g, h, types, tmean, tsd, cost in models:
        chk("%s eff identity" % name,
            abs((g / ATTEMPTS) * (1 - h / g) - (g - h) / ATTEMPTS) < 1e-12, "")

    # -- Appendix 1 Table S2 restates the same integers; they must not drift ---
    app = os.path.join(HERE, "appendix1_methods.tex")
    if os.path.exists(app):
        aflat = load_tex(app)
        for name, deploy, g, h, types, tmean, tsd, cost in models:
            row = re.search(re.escape(name) + r"\s*&\s*%d\s*&\s*(\d+)\s*&\s*(\d+)\s*&\s*([\d.]+)\s*&\s*([\d.]+)"
                            % ATTEMPTS, aflat)
            if row is None:
                chk("S2 row %s" % name, False, "row not found in appendix 1")
                continue
            chk("S2 %s generated" % name, int(row.group(1)) == g, "%s vs %d" % (row.group(1), g))
            chk("S2 %s hallucinating" % name, int(row.group(2)) == h, "%s vs %d" % (row.group(2), h))
            chk("S2 %s generation rate" % name,
                abs(float(row.group(3)) - round(g / ATTEMPTS * 100, 1)) < 0.051, row.group(3))
            chk("S2 %s effective rate" % name,
                abs(float(row.group(4)) - round((g - h) / ATTEMPTS * 100, 1)) < 0.051, row.group(4))
        chk("S2 totals row", re.search(r"Total\s*&\s*%d\s*&\s*%d\s*&\s*%d"
            % (8 * ATTEMPTS, generated, hallucinating), aflat) is not None,
            "expected 960 / %d / %d" % (generated, hallucinating))
        chk("S2 pooled rate sentence",
            "$%d/%d=%.1f\\%%$" % (hallucinating, generated, hallucinating / generated * 100) in aflat,
            "")
        chk("S2 ANOVA df", "df=(7,%d)" % (generated - 8) in aflat, "")

    # -- Applied Sciences variant: Tables 6 and 7 against TO_VERIFY.md --------
    if os.path.exists(APPLSCI) and os.path.exists(TOVERIFY):
        aflat = load_tex(APPLSCI)
        tv = open(TOVERIFY, encoding="utf-8").read()

        rows = re.findall(r"^\s{2}([\w.:\-]+):\s*\[(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\]", tv, re.M)
        tg = wa = ms = 0
        for name, g, t, w, m in rows:
            g, t, w, m = int(g), int(t), int(w), int(m)
            tg += t; wa += w; ms += m
            row = re.search(re.escape(name) + r"\s*&\s*(\d+)\s*&\s*(\d+)\s*\(([\d.]+)\)\s*&\s*"
                            r"(\d+)\s*\(([\d.]+)\)\s*&\s*(\d+)\s*&\s*([\d.]+)", aflat)
            if row is None:
                chk("T6 row %s" % name, False, "row not found"); continue
            chk("T6 %s generated" % name, int(row.group(1)) == g, "%s vs %d" % (row.group(1), g))
            chk("T6 %s triggered" % name, int(row.group(2)) == t, "%s vs %d" % (row.group(2), t))
            chk("T6 %s trigger rate" % name,
                abs(float(row.group(3)) - round(t / g * 100, 1)) < 0.051, row.group(3))
            chk("T6 %s warranted" % name, int(row.group(4)) == w, "%s vs %d" % (row.group(4), w))
            chk("T6 %s precision" % name,
                abs(float(row.group(5)) - round(w / t * 100, 1)) < 0.051, row.group(5))
            chk("T6 %s missed" % name, int(row.group(6)) == m, "%s vs %d" % (row.group(6), m))
            chk("T6 %s recall" % name,
                abs(float(row.group(7)) - round(w / (w + m) * 100, 1)) < 0.051, row.group(7))
        if rows:
            chk("T6 totals", re.search(r"Total\s*&\s*%d\s*&\s*%d\s*\(%.1f\)\s*&\s*%d\s*\(%.1f\)\s*&\s*%d"
                % (generated, tg, tg / generated * 100, wa, wa / tg * 100, ms), aflat) is not None,
                "expected %d/%d/%d" % (tg, wa, ms))
            wam = re.search(r"wrong_after_miss:\s*(\d+)", tv)
            if wam:
                n = int(wam.group(1))
                chk("wrong-after-miss <= category B", n <= categories[1],
                    "%d vs %d" % (n, categories[1]))
                chk("wrong-after-miss share of B in text",
                    "%.1f\\%% of the 95" % (n / categories[1] * 100) in aflat
                    or "%.1f" % (n / categories[1] * 100) in aflat, "")

        abl = re.findall(r"^\s{2}([ABCD]_\w+):\s*\[(\d+),\s*(\d+),\s*\[([\d,\s]+)\]\]", tv, re.M)
        prev = -1
        for tag, g, h, cls in abl:
            g, h = int(g), int(h)
            types = [int(x) for x in cls.split(",")]
            chk("T7 %s class sum" % tag, sum(types) == h, "%d vs %d" % (sum(types), h))
            eff = (g - h) / 120 * 100
            chk("T7 %s monotone" % tag, eff > prev, "%.1f after %.1f" % (eff, prev))
            prev = eff
            chk("T7 %s row" % tag,
                re.search(r"%d\s*&\s*%d\s*&\s*[\d.]+\s*&\s*[\d.]+\s*&\s*%.1f" % (g, h, eff), aflat)
                is not None, "row not found for %s" % tag)
        if abl:
            dg, dh, dcls = abl[-1][1], abl[-1][2], [int(x) for x in abl[-1][3].split(",")]
            qw = [m for m in models if m[0] == "qwen2.5:7b"][0]
            chk("T7 setting D equals main-experiment qwen row",
                int(dg) == qw[2] and int(dh) == qw[3] and dcls == qw[4],
                "%s/%s/%s vs %d/%d/%s" % (dg, dh, dcls, qw[2], qw[3], qw[4]))

    return chk.report()


if __name__ == "__main__":
    sys.exit(main())
