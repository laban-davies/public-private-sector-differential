# NOTE: this script was written with AI assistance (Claude, Anthropic). See README for details.
"""
Parse Stata's key_results.log into results.csv (one row per nlcom estimate, with its sample size).

Usage:  python parse_log.py key_results.log
Writes: results.csv  (fy, section, label, est, se, p, lb, ub, N)
        sample.csv   (fy, private, public, total) from the `tab public if e(sample)` output

The log is read in the order the analysis do-file produces it, so the label list below
must match that order. A count check stops the script if they ever drift apart.
"""
import csv
import re
import sys

REGIONS = ["North East", "North West", "Yorkshire and Humberside", "East Midlands", "West Midlands",
           "East of England", "London", "South East", "South West", "Wales", "Scotland", "Northern Ireland"]
EDUC = ["Higher degree", "Degree", "Non-degree higher education qualification", "A level (or equivalent)",
        "GCSE (or equivalent)", "Any other qualification", "No qualification"]
LABELS = ([("Headline", "Raw (quarter-adjusted)"), ("Headline", "Conditional"),
           ("Headline", "Conditional (HIQUL15D education controls)"),
           ("Sex", "Men"), ("Sex", "Women")]
          + [("Region", r) for r in REGIONS] + [("Education", e) for e in EDUC]
          + [("Furlough check", "Oct-Mar quarters"), ("Furlough check", "Apr-Sep quarters")])

NL = re.compile(r"_nl_1 \|\s+(-?[\d.]+)\s+([\d.]+)\s+(-?[\d.]+)\s+([\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)")
N_LINE = re.compile(r"^N = (\d+)", re.M)
SEXCOUNT = re.compile(r"count if e\(sample\) & SEX == (\d)\s*\n\s*([\d,]+)")
TAB = re.compile(r"^\s+0 \|\s+([\d,]+).*\n\s+1 \|\s+([\d,]+)", re.M)

text = open(sys.argv[1]).read()
text = re.sub(r"\n> ?", "", text)  # undo Stata's line wrapping of long output
blocks = re.split(r"===== Financial year (\d{4}) =====", text)

rows, sample = [], []
for year, body in zip(blocks[1::2], blocks[2::2]):
    fy = f"{year}-{str(int(year) + 1)[2:]}"
    ests = list(NL.finditer(body))
    assert len(ests) == len(LABELS), f"{fy}: found {len(ests)} estimates, expected {len(LABELS)}"
    sex_n = {int(k): int(v.replace(",", "")) for k, v in SEXCOUNT.findall(body)}
    for (section, label), m in zip(LABELS, ests):
        est, se, z, p, lb, ub = m.groups()
        if section == "Sex":
            n = sex_n[1 if label == "Men" else 2]
        else:  # first "N = " printed after this estimate belongs to it
            n = int(N_LINE.search(body, m.end()).group(1))
        rows.append(dict(fy=fy, section=section, label=label, est=float(est), se=float(se), p=float(p),
                         lb=float(lb), ub=float(ub), N=n))
    priv, pub = (int(x.replace(",", "")) for x in TAB.search(body).groups())
    sample.append(dict(fy=fy, private=priv, public=pub, total=priv + pub))

# sanity checks: region/education counts add up to the full sample; men + women likewise
for s in sample:
    yr = [r for r in rows if r["fy"] == s["fy"]]
    for sec in ("Region", "Education", "Sex"):
        total = sum(r["N"] for r in yr if r["section"] == sec)
        assert total == s["total"], (s["fy"], sec, total, s["total"])

with open("results.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0]))
    w.writeheader()
    w.writerows(rows)
with open("sample.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(sample[0]))
    w.writeheader()
    w.writerows(sample)
print(f"{len(rows)} estimates and {len(sample)} sample rows written; subgroup counts add up to totals")
