clear all
timer clear 1
timer on 1
set more off
capture log close

global path "C:/Users/pedro/Desktop/EPGE/ThirdYear/Labor_Demographics_Economics/ProblemSet"
cd $path

*----------------------------
* Question 1.b
*----------------------------

* Read it
use usa_00002.dta

* Sample:
/*
"For the purpose of this study, the data were restricted to white husband-wife families, excluding units of which heads were self-employed or not gainfully occupied. The excluded population subgroupsare known to exhibit differential patterns of labor force behavior." (Mincer, 1962)
*/

* White only
keep if race == 1

* Create variable that identifies household with at least one child with less than 16 years of age
bysort year cbserial: gen child_w_less_16 = 1 if relate == 3 & age <= 16
replace child_w_less_16 = 0 if child_w_less_16 != 1
egen child_with_less_16 = total(child_w_less_16), by(year cbserial)
gen children_with_less_16 = 1 if child_with_less_16 > 0
replace children_with_less_16 = 0 if children_with_less_16 != 1

drop child_w_less_16 child_with_less_16

* Married only
keep if marst <= 2
* Household and spouse only
keep if relate <=2

* Table 2 from Mincer (1962) shows the sample sizes of husband-wife urban consumer units from the 1950 Bureau of Labor Statistics Data
* I have multiple years (2005-2019) so I am going to choose 2015 because question 4 estimates a model using data from 2015.
* It also specifies only information about the head, therefore, I select only the individuals who reported as head
keep if year == 2015
keep if relate == 1

* I can create a categorical variable describing the educational levels (Elementary, High School, College)
gen education_level = "Elementary" if educ <= 2
replace education_level = "High School" if educ >= 3 & educ <= 6
replace education_level = "College" if educ >= 7

* I also can recreate the categories using in the right-hand side of the table 2
gen right_hand_information = "Less than 35, child less than 16" if age < 35 & children_with_less_16 == 1
replace right_hand_information = "Less than 35, no small children" if age < 35 & nchlt5 == 0
replace right_hand_information = "35-54" if age >= 35 & age <= 54
replace right_hand_information = "55 and older" if age >= 55
 
* To get those who work a full time year-round, we need to take two steps:

* First, since weeks of work are in ranges, we take the average of the range
gen wkswork = 0 if wkswork2 == 0
replace wkswork = 7 if wkswork2 == 1
replace wkswork = 20 if wkswork2 == 2
replace wkswork = 33 if wkswork2 == 3
replace wkswork = 43 if wkswork2 == 4
replace wkswork = 48 if wkswork2 == 5
replace wkswork = 51 if wkswork2 == 6

* Second, we can get total hours work in the year
gen total_hours_worked = wkswork * uhrswork 
 
* Finally, we define a full time year-round as:
gen full_time = (total_hours_worked >= 52*30)


**********************************
* Tables section
**********************************

* The raw data table (without differentiating for heads working full time year-round) is:
tab right_hand_information education_level
 
* Full time 
tab right_hand_information education_level if full_time == 1

* Working less than full timer
tab right_hand_information education_level if full_time != 1
