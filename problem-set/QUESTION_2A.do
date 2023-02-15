clear all
timer clear 1
timer on 1
set more off
capture log close

global path "C:/Users/pedro/Desktop/EPGE/ThirdYear/Labor_Demographics_Economics/ProblemSet"
cd $path

*----------------------------
* Question 2.a
*----------------------------

* Read it
use usa_00002.dta

* Select the sample (married)
keep if marst <= 2

* In the rest of the question, we will require to use a measure of non-labor income (y) to estimate the participation decision (P)
* We saw in class that in some cases, the husband's earnings can be used as part of the wife's non-labor income, so we will need it
* First, let's recalculate the wage so we can get hourly wages

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

* First, we can deflate the nominal wage: Use the CPI index to get the real wage
merge m:1 year using cpi_index
drop _merge
gen rwage = incwage/cpi_index
gen hourly_rwage = rwage/total_hours_worked
replace hourly_rwage = 0 if rwage == 0

* Create male spouse variable and interact with the hourly_wage variable to capture his hourly wage
gen male_spouse = (sex == 1)
gen male_spouse_rwage = male_spouse * rwage

* Now, for each household, we have the male spouse wage
bysort year cbserial: egen husband_rwage = sum(male_spouse_rwage)

* To get a continous variable X that is not included in Z, we choose the husband non-labor income
gen male_spouse_non_labor_income = male_spouse * (incss + incwelfr)

* Now, for each household, we have the male non-labor income
bysort year cbserial: egen husband_non_labor_income = sum(male_spouse_non_labor_income)
gen husband_real_non_labor_income = husband_non_labor_income/cpi_index

* Finishing the sample selection
keep if sex == 2
keep if age >= 25 & age <= 55

* Now generate labor force participation decision
gen employed = (empstat == 1)
gen unemployed = (empstat == 2)
gen not_in_lf = (empstat == 3)

* To make the estimations more tractable, we can reduce the number of categories on the education variable 
* Using the `educd' variable, we can create the following categories:
* 1 - No schooling to uncompleted primary education
* 2 - Completed primary education to uncompleted secondary education/ HS
* 3 - Completed HS to uncompleted College
* 4 - Completed college and more
gen education = 1 if educd <= 21
replace education = 2 if educd > 21 & educd < 62
replace education = 3 if educd >= 62 & educd < 81
replace education = 4 if educd >= 81

* To make the estimations even easier, we can make a dummy for completed (college) education, which captures the college wage premium
gen completed_college = (education == 4) 

* Finally, we can calculate the non-labor income and deflate it
gen non_labor_income = husband_rwage + incss + incwelfr
gen real_non_labor_income = non_labor_income/cpi_index

* And to reduce the size the non-labor income, we can:
gen ln_real_non_labor_income = log(real_non_labor_income)
replace ln_real_non_labor_income = 0 if ln_real_non_labor_income == . 

* Finally, add a constant variable for later estimations
gen constant = 1

* Save it (just in case)
save question2_sample, replace

*****************************************
* Estimations Section
*****************************************

* First, let's have a look at the distribution of the hourly wages for those who work
summarize hourly_rwage if employed == 1 [aweight=perwt], detail

* It's highly skewed to the right with a very long tale.
* To make any useful use of the estimations, we can exclude all hourly wages above the 99 percentile
keep if hourly_rwage <= 170.6129

* Now it looks more sensible
hist hourly_rwage if employed == 1

* However there still zero hourly wages for employed women, which may be a measurement error. So we remove those
keep if (hourly_rwage > 0 & employed == 1) | (hourly_rwage == 0 & employed == 0)

* First, we can use the simplest estimation strategy possibly to estimate the first wage equation (w = z'gamma + year_fe + college_premia_trend + xi)
reg hourly_rwage age completed_college i.year completed_college#year

* It yields gamma' = [.195	, 14.53]

* But labor force participation is an endogenous decision and we need to make sure we account for that.

* To perform the non-parametric estimation (Kernel regression), we will use the `npregress kernel' command
* However, this command is painfully slow and with > 5 million observations, it might take a long time.
* So I resort to using a 10% random sample of the year 2015 - because we will use 2015's data on the last question - to perform the estimations (If necessary)
keep if year == 2015
sample 10

* Non-parametric Kernel Estimation. We use the Gaussian kernel function because of its statistical properties 
	* y = real (deflated) non labor income
	* x = constant, age, number of children
	* z = dummy for completed college education
npregress kernel employed ln_real_non_labor_income constant age nchild i.completed_college, kernel(gaussian) 

