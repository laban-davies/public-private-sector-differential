# Premium or discount? Depends who's asking.

Replicating and extending the IFS study (Bee Boileau, Laurence O'Brien and Ben Zaranko, 2022) on the public-private sector wage differential across different groups in 2021-22 and 2022-23.

The full write-up is in [`Premium or discount?.pdf`](Premium%20or%20discount%3F.pdf).

## Key findings

In 2021-22, public sector employees earned 7.1% more per hour than those in the private sector, yet 1.3% less once controlling for sex, experience, region, age, quarterly changes and education. The IFS (2022) estimates of 7% and -0.7% both lie within the study's 95% confidence intervals, and this study's estimates both lie within the IFS's confidence intervals. In 2022-23, the raw differential fell to 3.8%, and the conditional fell to -3.4%.

- **By sex:** the conditional public-private sector wage differentials were 1.4% and -4.9% for females and males respectively in 2021-22. In 2022-23, the figures fell to -1% and -6.6% for females and males respectively.
- **By region:** the 2021-22 differential ranged from 8.3% in Scotland to -10.2% in the South East. In both years, only three of the twelve regions returned a differential statistically different from zero.
- **By qualification:** the differential varies by highest qualification, with degree holders facing the highest public sector discount.

## Questions

- Can the IFS (2022) estimates for 2021-22 be replicated?
- How did the differential change in 2022-23?
- How does it vary by sex, region and qualification?

## Data

The data used is Labour Force Survey data spanning 2021q2 to 2023q1. The data is recorded in waves, with only waves 1 and 5 answering the income questions, thus income weights (PIWT22) were used.

**No microdata is included in this repository.** The LFS End User Licence does not allow redistribution. The eight quarterly datasets can be downloaded from the UK Data Service after registering:

| Quarter | SN | DOI |
|---|---|---|
| Apr–Jun 2021 | 8826 | [10.5255/UKDA-SN-8826-5](http://doi.org/10.5255/UKDA-SN-8826-5) |
| Jul–Sep 2021 | 8872 | [10.5255/UKDA-SN-8872-7](http://doi.org/10.5255/UKDA-SN-8872-7) |
| Oct–Dec 2021 | 8915 | [10.5255/UKDA-SN-8915-6](http://doi.org/10.5255/UKDA-SN-8915-6) |
| Jan–Mar 2022 | 8957 | [10.5255/UKDA-SN-8957-6](http://doi.org/10.5255/UKDA-SN-8957-6) |
| Apr–Jun 2022 | 8999 | [10.5255/UKDA-SN-8999-5](http://doi.org/10.5255/UKDA-SN-8999-5) |
| Jul–Sep 2022 | 9027 | [10.5255/UKDA-SN-9027-6](http://doi.org/10.5255/UKDA-SN-9027-6) |
| Oct–Dec 2022 | 9052 | [10.5255/UKDA-SN-9052-4](http://doi.org/10.5255/UKDA-SN-9052-4) |
| Jan–Mar 2023 | 9097 | [10.5255/UKDA-SN-9097-4](http://doi.org/10.5255/UKDA-SN-9097-4) |

## Method

Equation 1: ln(hourly pay) = α + β·public + controls + error

Equation 2: (e^β − 1) × 100 (Halvorsen and Palmquist, 1980)

The set of controls for the conditional differential are age and age², experience and experience² interacted with three education groups, a seven-category education, region and quarter, all interacted with sex. All standard errors reported are robust, and all confidence intervals are calculated using the delta method.

## Repository contents

| File | What it does |
|---|---|
| `Master_do_file.do` | Sets paths, globals and logs, then runs the other do-files in order |
| `Cleaning_loop_IFS.do` | Cleans each quarterly LFS file |
| `Data_preparation.do` | Builds variables, appends quarters and trims hourly pay by financial year |
| `Analysis_do_file.do` | Runs the regressions for one financial year (called for 2021 and 2022) |
| `python/` | Scripts that turn `key_results.log` into the figures and tables in the write-up |

## Running the code

1. Download the eight datasets above (Stata format).
2. Create a project folder with this layout:
   ```
   your-folder/
   ├── raw datasets/   (the eight lfsp_<quarter>_eul_pwt24.dta files)
   └── Do-files/       (the four .do files from this repository)
   ```
3. In `Master_do_file.do`, set `global root` to the path of your folder.
4. Run `Master_do_file.do`. It writes `results.log` (full output) and `key_results.log` (the estimates reported in the write-up) to the root folder.
5. To rebuild the figures and tables, run the scripts in `python/` on `key_results.log` (see `python/README_python.md`).

## AI use

The project's purpose was to improve my understanding of econometrics and my competency in Stata. Thus, Claude by Anthropic was used to learn how to code steps of the preparation, cleaning and analysis. AI was often used to debug the code when it returned errors. Comments on the Stata code are mine, where I attempt to justify judgement calls, explain what lines of code do, and why they are necessary. AI was used in cases to help me understand the code and thus informed some of my comments. AI was also used to write the Python scripts to create the tables and figures in this report. AI also reviewed drafts of my write-up to catch errors. No raw data was uploaded to AI during this study.

## References

Boileau, B., O'Brien, L. and Zaranko, B. (2022) 'Public spending, pay and pensions', in *IFS Green Budget 2022*. IFS Report R219. London: Institute for Fiscal Studies. Available at: https://ifs.org.uk/sites/default/files/2022-10/Public-spending-pay-and-pensions-R219.pdf

Cribb, J., Emmerson, C. and Sibieta, L. (2014) *Public sector pay in the UK*. IFS Report R97. Available at: https://ifs.org.uk/sites/default/files/output_url_files/r97.pdf

Halvorsen, R. and Palmquist, R. (1980) 'The interpretation of dummy variables in semilogarithmic equations', *American Economic Review*, 70(3), pp. 474–475.
