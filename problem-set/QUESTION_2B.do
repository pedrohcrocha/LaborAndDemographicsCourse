clear all
set more off
capture log close

global path "C:/Users/pedro/Desktop/EPGE/ThirdYear/Labor_Demographics_Economics/ProblemSet"
cd $path

*----------------------------
* Question 2.b
*----------------------------
use question2_sample

* We can exclude all hourly wages above the 99 percentile and transform it into log
keep if hourly_rwage <= 170.6129
gen lnhourly_wage = log(hourly_rwage)
replace lnhourly_wage = 0 if lnhourly_wage == .

* And to reduce the size the non-labor income, we can:
gen ln_real_non_labor_income = log(real_non_labor_income)
replace ln_real_non_labor_income = 0 if ln_real_non_labor_income == . 

* To perform the non-parametric estimation (Kernel regression), we will use the `npregress kernel' command
* So I resort to using a 10% random sample of the year 2015 - because we will use 2015's data on the last question - to perform the estimations (If necessary)
keep if year == 2015
sample 10

* Non-parametric Kernel Estimation with Gaussian kernel function because of its statistical properties
npregress kernel employed ln_real_non_labor_income age nchild i.completed_college, kernel(gaussian)

* Save the predicted working probabilities  
outsheet using "data_new_predicted_employment.csv", comma replace

* With the predicted probabilities, we can estimate the full wage equation using LS to capture M and gamma 
* This is the not Robinson's partial regression model but the 2-step Heckman procedure. 
* We will estimate the Robinson's partial regression shortly
reg lnhourly_wage completed_college age _Mean_employed
 

*********************************
* Robinson's partial regression
*********************************

 