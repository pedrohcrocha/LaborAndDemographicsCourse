clear all
timer clear 1
timer on 1
set more off
capture log close

global path "C:/Users/pedro/Desktop/EPGE/ThirdYear/Labor_Demographics_Economics/ProblemSet"
cd $path

*********************************************************
* Question 1.a
*********************************************************

* Read it
use usa_00002.dta

* Select the sample
keep if sex == 2
keep if age >= 15 & age <= 65

* Merge the CPI Index in order to deflate nominal variables
merge m:1 year using cpi_index
drop _merge
gen rincwage = incwage/cpi_index

* Since weeks of work are in ranges, we take the average of the range
gen wkswork = 0 if wkswork2 == 0
replace wkswork = 7 if wkswork2 == 1
replace wkswork = 20 if wkswork2 == 2
replace wkswork = 33 if wkswork2 == 3
replace wkswork = 43 if wkswork2 == 4
replace wkswork = 48 if wkswork2 == 5
replace wkswork = 51 if wkswork2 == 6

* Now we can get total hours work in the year and, finally, the hourly wage
gen total_hours_worked = wkswork * uhrswork 

* Now generate labor force participation 
gen employed = (empstat == 1)
gen unemployed = (empstat == 2)
gen not_in_lf = (empstat == 3)

*********************************************************
* Calculate the variables
*********************************************************
bysort year: egen mean_wage = mean(incwage)
bysort year: egen mean_rwage = mean(rincwage)
bysort year: egen uncond_mean_hours_worked = mean(total_hours_worked) 
bysort year: egen cond_mean_hours_worked = mean(total_hours_worked) if employed == 1
bysort year: egen mean_employment_rate = mean(employed)

keep year mean_wage mean_rwage uncond_mean_hours_worked cond_mean_hours_worked mean_employment_rate
keep if cond_mean_hours_worked != .

*********************************************************
* Figures Section
*********************************************************
twoway line mean_wage year
graph export mean_wage.png

twoway line mean_rwage year
graph export mean_rwage.png

twoway line uncond_mean_hours_worked year
graph export uncond_mean_hours_worked.png

twoway line cond_mean_hours_worked year
graph export cond_mean_hours_worked.png

twoway line mean_employment_rate year
graph export mean_employment_rate.png
