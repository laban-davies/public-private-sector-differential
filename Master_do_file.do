* SET THE GLOBAL ROOT TO THE PATHWAY TO YOUR FOLDER CONTAINING THE LFS DATA (Download from UK Data Service) *

global root "path/to/your/folder"

capture log close _all // closes any open logs so code runs
log using "$root/results.log", text replace // main log 
log using "$root/key_results.log", text replace name(key) // log for relevant results

log off key 

global controls "c.AGE##c.AGE c.EXPERIENCE##c.EXPERIENCE##i.EDUC3 i.QDATE i.EDUC7 i.GOVTOF2" /* creates a shortcut for our controls for conditional differential. A few decisions worth noting:


1. c.variable is used for continuous variables, preventing stata from treating it as categorical in regressions. E.g., using Age otherwise would give you a coefficient for every age, treating it as a large set of dummy variables.

2. Age is interacted with itself to allow for a potential non-linear relationship between age and wages. The same is done for experience due to potential non-linearity. (e.g., there may be diminishing marginal returns to experience --> the first two years in an industry are likely more formative than your 11th and 12th) 

3. Experience is interacted with EDUC3 to allow the coefficient on experience to vary between the three education categories as returns to experience tend to vary by education level. (I used EDUC3 instead of EDUC7 to limit the number of parameters)

4. i.variable is used so stata treats it as a set of dummy variables in the regression 

5. i.QDATE ensures that the regression is quarterly adjusted. If the (public-private) composition of the sample changes between quarters and wages for all change between quarters this would bias the public-private wage differential. Controlling for QDATE adjusts data using quarterly trends to avoid this problem 

6. Use of EDUC7 instead of HIQUL15D since it distinguishes between undergrads and postgrads, relevant when investigating the public-private wage differential 

7. Every control is interacted with sex to allow for the fact that relationships between age, experience, education, quarters, and region may vary between sexes */


* Establish macros using root so that someone recreating the study can just change the root *

global lfs "$root/raw datasets"
global code "$root/Do-files"
global quarters aj21 js21 od21 jm22 aj22 js22 od22 jm23 // establishes quarter list, primarily for the cleaning and data preparation loops

* Run the cleaning do file *

do "$code/Cleaning_loop_IFS"
do "$code/Data_preparation"
do "$code/Analysis_do_file" 2021
do "$code/Analysis_do_file" 2022

log close _all
