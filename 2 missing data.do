**********missing data table*********************************

misstable summ cost_prolife cost_*_healthcare cost_*_tbtest cost_tbmeds cost_*_art, gen(mistab_)

misstable summ  a_reported_age a_sex, gen(mistab_)

misstable summ *_utility *_vas, gen(mistab_)

*************by group missing data**********************************
by group: tab1 mistab_*

*********association between baseline covariates and missingness****
local name "cost_bl_healthcare cost_m3_healthcare cost_m6_healthcare cost_bl_tbtest cost_trial_tbtest cost_tbmeds cost_m3_art cost_m6_art m3_utility m6_utility"
foreach n of local name {
	xi: logistic mistab_`n' group
	xi: logistic mistab_`n' a_reported_age
	xi: logistic mistab_`n' a_sex
}

************association between missingness and observed outcomes********************************
xi: logistic mistab_cost_m3_healthcare cost_bl_healthcare
xi: logistic mistab_cost_m6_healthcare cost_bl_healthcare
xi: logistic mistab_cost_m6_healthcare cost_m3_healthcare

**xi: logistic mistab_cost_trial_tbtest cost_bl_tbtest
**outcomes do not vary
xi: logistic mistab_cost_m6_art cost_m3_art

local name "utility vas"
foreach n of local name {
	xi: logistic mistab_m3_`n' bl_`n'
	xi: logistic mistab_m6_`n' bl_`n'
	xi: logistic mistab_m6_`n' m3_`n'
}

***********missingness association with death status*******************
local name "cost_bl_healthcare cost_m3_healthcare cost_m6_healthcare cost_bl_tbtest cost_trial_tbtest cost_tbmeds cost_m3_art cost_m6_art m3_utility m6_utility"
foreach n of local name {
	xi: logistic mistab_`n' death
}
