# Python scripts: tables and figures

These scripts turn the Stata output (`key_results.log`) into the tables and figures used in the write-up.
They were written with AI assistance (Claude, Anthropic); the Stata analysis is the author's own.

Run order (from this folder):

```
pip install -r requirements.txt
python parse_log.py path/to/key_results.log   # -> results.csv, sample.csv
python make_outputs.py                        # -> outputs/ (PNG figures, results_tables.docx)
python make_word_charts.py                    # -> outputs/figures_editable.docx (native Word charts)
```

`results.csv` and `sample.csv` are included so the figures can be rebuilt without access to the LFS microdata.
They contain only aggregate estimates and sample counts.
