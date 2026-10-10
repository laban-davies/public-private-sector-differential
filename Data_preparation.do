clear

* Append *

foreach q of global quarters {
append using "$lfs/clean_`q'.dta"
}

save "$lfs/clean.dta", replace

* Run checks before continuing *

assert !missing(QDATE) // to check if every observation was assigned a value for the quarter variable (code returns error if not)
tab QDATE // to check if number of observations in each quarter matches the numbers in the raw data
describe 

* Preparing the data for analysis *

	* Generating new variables *

gen LNWAGE = ln(HOURPAY) // so we can work in terms of a percentage pay gap
gen public = (PUBLICR == 2) if inlist(PUBLICR, 1, 2) // creating the public sector dummy variable (1 is private and 2 is public. This code ensures the dummy variable equals 1 when PUBLICR equals 2)

// Other variables such as SEX, QDATE and GOVTOF2 all become dummy variables by using i.variable notation) //
// Use age and age squared to find coefficients that allows for the fact that every extra year doesn't add the same percentage to pay,    do the same for EXPERIENCE //

	* Decoding and removing missing values *
	
drop if missing(CASENOP) // this accounts for the 5 observations in jm_22 which only have PWT24 and no realisations of any other variables
mvdecode _all, mv(-9, -8) // to convert codes for N/A and missing values into '.' so they will be dropped from regressions
keep if INECAC05 == 1 // keeps employees only (self-employed are dropped along with unemployed since hourly pay is missing)
keep if inlist(PUBLICR, 1, 2) // drops all 'does not apply' observations
keep if inrange(AGE, 20, 59) // drops all outside this age range, taken from the 2014 study, I've assumed this assumption was carried over to the 2022 study 
keep if PIWT22 > 0 & !missing(PIWT22) // drops all missing values (keep waves 1 and 5 for the regression) 
keep if HOURPAY > 0 & !missing(HOURPAY) // drops all missing HOURPAY observations
drop if missing(GOVTOF2) // drops missing values for regions
drop if EDAGE == 97 | missing(EDAGE) // drops missing values, N/A and never in education (only 13 observations thus easier to drop from sample than recode data)

	* Variable generation that must occur after decoding *

gen EXPERIENCE = AGE - EDAGE // must occur after decoding to remove possibility of double negative (e.g. age = 40, edage = -9, experience = 49)
replace EXPERIENCE = 0 if EDAGE == 96 // accounts for the 231 still in education surveyed (96 is the code for still in education)

* one note for the experience variable is that it is potential experience and assumes students began work immediately after leaving education with no career breaks. It is worth noting that this will skew the results slightly given that career breaks will likely vary between regions, sexes and ages *
* Creation of three tiered education variable, mimicking 2014 methodology for the experience interaction *

gen EDUC3 = .
replace EDUC3 = 1 if inlist(HIQUL15D, 1, 2)
replace EDUC3 = 2 if inlist(HIQUL15D, 3, 4)
replace EDUC3 = 3 if inlist(HIQUL15D, 5, 6)
label define educ3_lbl 1 "Higher education" 2 "Secondary education" 3 "Other/none", replace // defines labels for EDUC3
label values EDUC3 educ3_lbl // assigns said labels to EDUC3

		* Creation of a financial year variable *

generate FYEAR = year(dofq(QDATE)) - (quarter(dofq(QDATE)) == 1) // the '(quarter(dofq(QDATE)) == 1)' takes the value 1 if the statement is true (if the quarter in question is jan-march) and 0 otherwise. This helps us convert QDATE into a variable which takes the value of the year in which the associated financial year begins. 
label define fyear_lbl 2021 "2021-22" 2022 "2022-23", replace // converts starting year to financial year
label values FYEAR fyear_lbl // assigns new list to FYEAR

gen HOURS = TTUSHR // new variable in order to trim top percentile wages in cases where weekly hours are less than 10 (trimming)

	* Trimming loop (by financial year) *
	
* Here, we trim the bottom percentile regardless of hours reported, whereas the top percentile is only trimmed if hours are less than 10. This is due to the way HOURPAY is constructed --> HOURPAY = Gross pay / Hours (GRSSWK/HOURS). This means that for the bottom percentile the likelihood is that GRSSWK was underreported, especially given national minimum wage legislation and the fact that weekly hours can only be overreported by a limited amount (due to 24x7 being an absolute upper bound). However, in the top percentile underreporting hours can lead to overstating hourpay and so it is concluded that hourpay in the top percentile with hours less than 10 is likely to be an error and thus trimmed *

* Trim within each financial year, using weighted percentiles, because nominal pay rose between years. Pooled cut-offs would trim disproportionately from the lower-paid year at the bottom and the higher-paid year at the top *

levelsof FYEAR, local(fyears)

foreach y of local fyears {

_pctile HOURPAY if FYEAR == `y' [pw=PIWT22], p(1 99) // computes percentiles for weighted hourly pay
local p1 = r(r1) // this and the next line ensures the desired results of the above calculation are stored (otherwise would have to print from results of running the code)

local p99 = r(r2)

log on key
display "FY `y': 1st percentile = £" %5.2f `p1' ", 99th percentile = £" %5.2f `p99'
count if HOURPAY < `p1' & FYEAR == `y'
display "Dropped at bottom: " r(N)
count if HOURPAY > `p99' & HOURS < 10 & !missing(HOURPAY) & FYEAR == `y'
display "Dropped at top (hours < 10): " r(N)
log off key

drop if HOURPAY < `p1' & FYEAR == `y'  // likely to be a reporting error

drop if HOURPAY > `p99' & HOURS < 10 & !missing(HOURPAY) & FYEAR == `y' // drops all observations in the top percentile in which hours are less than ten (and hourpay is reported/not missing) as this is highly likely to be a reporting error. 

}


save "$lfs/analysis.dta", replace // save data set ready for analysis
