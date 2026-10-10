args fy // receives the financial year passed from the master (e.g. do Analysis_do-file 2021), so the same analysis runs separately for each year

use "$lfs/analysis.dta", clear 
keep if FYEAR == `fy' // keep only the observations from the financial year in question

log on key 

display "===== Financial year `fy' ====="

log off key 

* Quarterly adjusted wage differential *

regress LNWAGE public i.QDATE [pw=PIWT22], robust /* runs the regression of log wages over the public dummy variable. 

Quarterly adjusted for the same reason outlined in the master do-file

Each observation is adjusted using the PIWT22 income weights. Only waves 1 and 5 are asked to record their wages. PIWT22 uses only data from waves 1 and 5 to ensure characteristics of the population are reflected within the sample with incomes recorded --> since we are looking at the wage differential throughout, we only use PIWT22 weights. 

Don't use PWT24 as these take data from all five phases to calculate the weights 

We use log wages in order to ensure the coefficient can be converted into percentage changes using the transformation e^b - 1

Robust allows for heteroskedasticity within the sample, which tends to give more accurate (mostly larger) standard errors. I included it in this first regression to make it visible that we allow for heteroskedasticity. However, it is not necessary since stata automatically reports robust standard errors when the regression uses weights. Thus I have dropped robust from all future regressions. */

log on key
display (exp(_b[public])-1) * 100 // the raw public-private sector wage differential 
nlcom (exp(_b[public])-1) * 100 // CI for raw public-private sector wage differential
display "N = " e(N) // sample size 
log off key

* Conditional differential *

regress LNWAGE public i.SEX##($controls) [pw=PIWT22] // controlled regression 

log on key
display (exp(_b[public])-1) * 100 // the conditional public-private sector wage differential
nlcom (exp(_b[public])-1) * 100 // CI for conditional wage differential
display "N = " e(N) // sample size
log off key

log on key
tab public if e(sample) // gives the sample size for each year
log off key

* Education variable choice, sensitivity test 

regress LNWAGE public i.SEX##(c.AGE##c.AGE c.EXPERIENCE##c.EXPERIENCE##i.EDUC3 i.QDATE i.HIQUL15D i.GOVTOF2) [pw=PIWT22] // controlled regression using HIQUL15D instead of EDUC7 --> they differ only in how they categorise higher education. HIQUL15D combines postgraduate and undergraduate degrees into one category, whereas EDUC7 distinguishes between undergrads and postgrads

log on key
display (exp(_b[public])-1) * 100 // the conditional public-private sector wage differential using HIQUL15D
nlcom (exp(_b[public])-1) * 100 // CI for conditional wage differential using HIQUL15D
display "N = " e(N) // sample size 
log off key

* By sex *

regress LNWAGE i.SEX##(i.public $controls) [pw=PIWT22] // controlled regression by sex. Putting i.public into the interaction term allows for different coefficients on the public sector dummy

log on key
display (exp(_b[1.public])-1) * 100 // male public-private sector wage differential
nlcom (exp(_b[1.public])-1) * 100 // CI for male public-private sector wage differential
display "N = " e(N) // sample size 
count if e(sample) & SEX == 1
count if e(sample) & SEX == 2

display (exp(_b[1.public]+_b[2.SEX#1.public])-1) * 100 // female public-private sector wage differential
nlcom (exp(_b[1.public]+_b[2.SEX#1.public])-1) * 100 // CI for female public-private sector wage differential
log off key

* By region *

regress LNWAGE i.public##i.GOVTOF2 i.SEX##($controls) [pw=PIWT22] // controlled regression by region. Interact the public sector dummy with region to allow for the coefficient on the public sector dummy to vary between regions. Same controls apply.

	* Loop to report the differential and CI for each region *

levelsof GOVTOF2, local(regions) // this finds every value GOVTOF2 can take, and stores it in a local list, named regions
local base : word 1 of `regions' // this takes the lowest code (1 for North East) and stores it as 'base'

log on key
display "N = " e(N) // sample size
log off key

foreach r of local regions { // begins the loop 
local name : label (GOVTOF2) `r' // converts the numerical code to the region its associated with
log on key
display "`name'" 
if `r' == `base' display (exp(_b[1.public]) - 1) * 100 // for the base region, the differential simply uses the coefficient on the public sector dummy variable
else display (exp(_b[1.public] + _b[`r'.GOVTOF2#1.public]) - 1) * 100 // for all other regions, there is a further coefficient reflecting the interaction between the public sector dummy and each regional dummy (the difference between the base differential and each regional differential). Thus the sum of the base coefficient and the interaction coefficient gives the total differential 
if `r' == `base' nlcom (exp(_b[1.public]) - 1) * 100
else nlcom (exp(_b[1.public] + _b[`r'.GOVTOF2#1.public]) - 1) * 100
count if e(sample) & GOVTOF2 == `r'
display "N = " r(N) // regional counts
log off key
}

* By education level *

regress LNWAGE i.public##i.EDUC7 i.SEX##($controls) [pw=PIWT22] // controlled regression by education level

log on key
display "N = " e(N) // sample size 
log off key

levelsof EDUC7, local(qualifications) // adapts the regional analysis methodology to the EDUC7 variable, otherwise the above comments apply
local base : word 1 of `qualifications'

foreach e of local qualifications {
local name : label (EDUC7) `e'
log on key
display "`name'"
if `e' == `base' display (exp(_b[1.public]) - 1) * 100
else display (exp(_b[1.public] + _b[`e'.EDUC7#1.public]) - 1) * 100
if `e' == `base' nlcom (exp(_b[1.public]) - 1) * 100
else nlcom (exp(_b[1.public] + _b[`e'.EDUC7#1.public]) - 1) * 100
count if e(sample) & EDUC7 == `e'
display "N = " r(N) // sample size breakdown --> qualification counts 
log off key
}

* Furlough check --> did furlough impact the conditional differential? *

/* this is a crude check, comparing Q2-3 to Q1 and Q4. I do this in 2021-22 FY to investigate whether furlough coincided with a noticeable change in the differential. (For example, perhaps furlough impacted a greater percentage of private sector employees, which may subdue private sector pay whilst public sector pay held up, thus biasing the wage differential upwards)

I then repeat this for FY 2022-23 to give us an indicator of whether the change in wage differential that coincided with furlough merely reflected some regular seasonal variation in the differential. 

This is an exploratory check and cannot identify a causal effect

With more time I would compare difference in differences formally to account for seasonal variation. I would create a Q2/3 dummy variable and investigate whether the interaction with the public sector was statistically different in 2021-22 compared to other years tested. For it to robustly account for seasonal variation we would need to extend our research beyond these two years which would be time consuming. */

if `fy' == 2021 { // only concerns data on 2021-22

regress LNWAGE public i.SEX##($controls) [pw=PIWT22] if inlist(QDATE, tq(2021q4), tq(2022q1)) // controlled regression for non furlough quarters 

log on key
display "Non-furlough quarters: 2021q4 and 2022q1"
display (exp(_b[public])-1) * 100 // the conditional public-private sector wage differential for non-furlough quarters
nlcom (exp(_b[public])-1) * 100 // CI for conditional wage differential in non-furlough quarters
display "N = " e(N) // sample size
log off key

regress LNWAGE public i.SEX##($controls) [pw=PIWT22] if inlist(QDATE, tq(2021q2), tq(2021q3)) // controlled regression for furlough quarters

log on key
display "Furlough quarters: 2021q2 and 2021q3"
display (exp(_b[public])-1) * 100 // the conditional public-private sector wage differential for furlough quarters
nlcom (exp(_b[public])-1) * 100 // CI for conditional wage differential for furlough quarters
display "N = " e(N) // sample size
log off key 
}

if `fy' == 2022 { // compare to seasonal trend during 2022-23 to see if changes in differential reflected regular seasonal trends, rather than potentially reflecting the impact of furlough

regress LNWAGE public i.SEX##($controls) [pw=PIWT22] if inlist(QDATE, tq(2022q4), tq(2023q1)) // controlled regression for non furlough quarters

log on key
display "Placebo: 2022q4 and 2023q1"
display (exp(_b[public])-1) * 100 // the conditional public-private sector wage differential
nlcom (exp(_b[public])-1) * 100 // CI for conditional wage differential
display "N = " e(N) // sample size
log off key

regress LNWAGE public i.SEX##($controls) [pw=PIWT22] if inlist(QDATE, tq(2022q2), tq(2022q3)) // controlled regression for furlough quarters

log on key
display "Placebo: 2022q2 and 2022q3"
display (exp(_b[public])-1) * 100 // the conditional public-private sector wage differential
nlcom (exp(_b[public])-1) * 100 // CI for conditional wage differential
display "N = " e(N) // sample size
log off key 
}

