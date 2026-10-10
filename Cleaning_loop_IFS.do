* Creating a loop that cleans each quarterly file *

foreach q of global quarters { // so that the changes apply to every quarter without repeating code 
use "$lfs/lfsp_`q'_eul_pwt24.dta", clear // the global quarterly loop is used here, using UK data service code so this works on the raw datasets

* Harmonising variables *

capture confirm variable HIQUL22D // this labels _rc = 0 if HIQUL22D exists, allowing the code to rename it for harmonisation 
if _rc == 0 rename HIQUL22D HIQUL15D // To ensure relevant variables are under the same name (this is sufficient for harmonisation because both use the same 1 to 7 classification) 

* the 2014 study's education metric splits the degree level into Higher degree and degree, otherwise the categories align. In order to get a metric identical to this we need to create a dummy variable for higher degrees, and then use the dummy and HIQUL15D to create EDUC7, which classifies observations based on the 2014 measure of education. In the regressions I start by control for education using EDUC7 since distinguishing between degree and higher degrees is highly relevant to the question, given the higher concentration of post graduate degree holders in the public sector. I will later use HIQUL15D as a sensitivity test to investigate whether this influenced the results * 


* HIQUAL15 and HIQUAL22 both code 1 as 'Higher degree' (LFS User Guide Vol. 3), so the dummy is consistent across the JM22 questionnaire change *

capture confirm variable HIQUAL22 
if _rc == 0 rename HIQUAL22 HIQUAL15 // same strategy as above to harmonise variables that allow us to create a higher education dummy
gen HIGHERDEG = .
replace HIGHERDEG = 1 if HIQUAL15 == 1 // creating the higher degree dummy variable

recode HIQUL15D (7 = -9) // recodes don't know to missing value
drop if inlist(HIQUL15D, -8, -9) // drops observations where realisations of the education variable is missing and does not apply
gen EDUC7 = HIQUL15D + 1 
replace EDUC7 = 1 if HIQUL15D == 1 & HIGHERDEG == 1
label define educ7_lbl 1 "Higher degree" 2 "Degree" 3 "Non-degree higher education qualification" 4 "A level (or equivalent)" 5 "GCSE (or equivalent)" 6 "Any other qualification" 7 "No qualification", replace // define label list for EDUC7
label values EDUC7 educ7_lbl // assigns said labels to EDUC7


keep THISWV INECAC05 GRSSWK EDAGE AGE SEX FTPT CASENOP PIWT22 PWT24 HOURPAY HIQUL15D PUBLICR BUSHR POTHR TTUSHR GOVTOF2 EDUC7 HIGHERDEG // Keeping only the relevant variables

* Creating a numerical quarter variable for cross-quarter comparison *

local yr = 2000 + real(substr("`q'", 3, 2)) // creates a local year macro to construct numerical quarterly data (instead of string) to allow for pooled regressions later // real makes sure that the string becomes a number
local mo = substr("`q'", 1, 2) // no real needed as converted into a number in next steps
assert inlist("`mo'", "jm", "aj", "js", "od") // checks that all month values are correct with no typos --> code returns error if typos are present
local qn = cond("`mo'"=="jm", 1, cond("`mo'"=="aj", 2, cond("`mo'"=="js", 3, 4))) // converts month code into a quarter number (achieved using an if/else-if chain)
generate QDATE = yq(`yr', `qn') // combines local macros to give a quarterly variable
format QDATE %tq // to ensure quarters are displayed in a comprehensible format (instead of stata's default - quarters since 1960 q1)

* Save cleaned data * 

save "$lfs/clean_`q'.dta", replace
}
