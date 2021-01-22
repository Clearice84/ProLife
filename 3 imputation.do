****run on ProLife_CRF_randomised_unblind MI 2020-10-16.dta, following preparation.do and missing data.do**********************
****save to new file: ProLife_imputation.dta

**baseline covariates (group, sex, age) are complete so no mean imputation*********

mi set flong

mi register regular a_reported_age a_sex death cost_prolife bl_utility bl_utility_M bl_utility_B bl_vas cost_trial_healthcare

mi register passive ref_cost totalcost cost_usualcare qaly qaly_M qaly_B

mi register imputed cost_bl_healthcare cost_m3_healthcare cost_m6_healthcare ///
			cost_bl_tbtest cost_trial_tbtest cost_tbmeds cost_m3_art cost_m6_art ///
			m3_utility m6_utility m3_utility_M m6_utility_M m3_utility_B m6_utility_B ///
			m3_vas m6_vas

mi describe

mi impute chained ///
		(pmm, knn(10)) cost_bl_healthcare cost_m3_healthcare cost_m6_healthcare ///
			cost_bl_tbtest cost_trial_tbtest cost_tbmeds cost_m3_art cost_m6_art ///
			m3_utility m6_utility m3_utility_M m6_utility_M m3_utility_B m6_utility_B ///
			m3_vas m6_vas ///
		= a_reported_age a_sex death cost_prolife bl_utility bl_utility_M bl_utility_B ///
		bl_vas, add(41) rseed(999) by(group)

mi passive: replace ref_cost = cost_bl_healthcare + cost_bl_tbtest
mi passive: replace cost_trial_healthcare = cost_m3_healthcare + cost_m6_healthcare
mi passive: replace cost_usualcare = cost_tbmeds + cost_m3_art + cost_m6_art + cost_trial_tbtest
mi passive: replace totalcost = cost_prolife + cost_usualcare + cost_trial_healthcare

mi passive: replace qaly = ((bl_utility + m3_utility) * 3/12) / 2 + ((m3_utility + m6_utility) * 3/12) / 2

mi passive: replace qaly_M = ((bl_utility_M + m3_utility_M) * 3/12) / 2 + ((m3_utility_M + m6_utility_M) * 3/12) / 2

mi passive: replace qaly_B = ((bl_utility_B + m3_utility_B) * 3/12) / 2 + ((m3_utility_B + m6_utility_B) * 3/12) / 2

mi estimate: mean cost_prolife, over(group)
mi estimate: mean cost_usualcare, over(group)
mi estimate: mean cost_trial_healthcare, over(group)
mi estimate: mean totalcost, over(group)
mi estimate: mean bl_utility, over(group)
mi estimate: mean m3_utility, over(group)
mi estimate: mean m6_utility, over(group)
mi estimate: mean qaly, over(group)

mi estimate: glm totalcost i.group ref_cost i.a_sex a_reported_age, fam(gam) l(i)
mi estimate: reg qaly i.group bl_utility i.a_sex a_reported_age

dis 2373/0.006
***395500
**point estimate of ICER

****for TB treatment outcome, to match with statistical analysis, it was not imputed**************************
tab new_treatment_outcome_2Cat group if _mi_m == 0, col
mi estimate: mean totalcost if !mi(new_treatment_outcome_2Cat), over(group)

dis 1957/.71
dis 3701/.69
***total cost per TB treatment success case
mi estimate: glm totalcost i.group ref_cost i.a_sex a_reported_age if !mi(new_treatment_outcome_2Cat), fam(gam) l(i)

***cost of accommodation/travel/refreshments in training accounted for 80% of ProLife*********************
***reduce cost of ProLife by 20%, 40%, 60%**************************************

forvalues i = 20(20)60 {
	gen Cprolifeminus`i' = cost_prolife * (100-`i')/100
	
	mi passive: gen TCprolifeminus`i' = Cprolifeminus`i' + cost_usualcare + cost_trial_healthcare
	
	mi estimate: glm TCprolifeminus`i' i.group ref_cost i.a_sex a_reported_age, fam(gam) l(i)
}
