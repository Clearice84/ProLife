***to run on ProLife_imputation.dta*******************************

**********Scenario 1************************
***increase imputed costs by 10%-30% in both arms
forvalues i = 10(10)30 {
	gen Cplus`i'_bl_healthcare = cost_bl_healthcare
	replace Cplus`i'_bl_healthcare = cost_bl_healthcare*(100+`i')/100 if mistab_cost_bl_healthcare == 1
		
	gen Cplus`i'_m3_healthcare = cost_m3_healthcare
	replace Cplus`i'_m3_healthcare = cost_m3_healthcare*(100+`i')/100 if mistab_cost_m3_healthcare == 1
		
	gen Cplus`i'_m6_healthcare = cost_m6_healthcare
	replace Cplus`i'_m6_healthcare = cost_m6_healthcare*(100+`i')/100 if mistab_cost_m6_healthcare == 1
		
	gen Cplus`i'_bl_tbtest = cost_bl_tbtest
	replace Cplus`i'_bl_tbtest = cost_bl_tbtest*(100+`i')/100 if mistab_cost_bl_tbtest == 1
		
	gen Cplus`i'_trial_tbtest = cost_trial_tbtest
	replace Cplus`i'_trial_tbtest = cost_trial_tbtest*(100+`i')/100 if mistab_cost_trial_tbtest == 1
		
	gen Cplus`i'_tbmeds = cost_tbmeds
	replace Cplus`i'_tbmeds = cost_tbmeds*(100+`i')/100 if mistab_cost_tbmeds == 1
		
	gen Cplus`i'_m3_art = cost_m3_art
	replace Cplus`i'_m3_art = cost_m3_art*(100+`i')/100 if mistab_cost_m3_art == 1
		
	gen Cplus`i'_m6_art = cost_m6_art
	replace Cplus`i'_m6_art = cost_m6_art*(100+`i')/100 if mistab_cost_m6_art == 1
		
	mi passive: gen ref_Cplus`i' = Cplus`i'_bl_healthcare + Cplus`i'_bl_tbtest
	mi passive: gen TCplus`i' = cost_prolife + Cplus`i'_tbmeds + Cplus`i'_m3_art + Cplus`i'_m6_art + Cplus`i'_trial_tbtest + Cplus`i'_m3_healthcare + Cplus`i'_m6_healthcare
	
	mi estimate: glm TCplus`i' i.group ref_Cplus`i' i.a_sex a_reported_age, fam(gam) l(i)

}


*************Scenario 2**********************************
***reduce imputed utility by 10%-30% in both arms
forvalues i = 10(10)30 {
	gen m3_utilityminus`i' = m3_utility
	replace m3_utilityminus`i' = m3_utility*(100-`i')/100 if mistab_m3_utility == 1
	
	gen m6_utilityminus`i' = m6_utility
	replace m6_utilityminus`i' = m6_utility*(100-`i')/100 if mistab_m6_utility == 1
	
	mi passive: gen qalyminus`i' = ((bl_utility + m3_utilityminus`i') * 3/12) / 2 + ((m3_utilityminus`i' + m6_utilityminus`i') * 3/12) / 2
	
	mi estimate: reg qalyminus`i' i.group bl_utility i.a_sex a_reported_age
}




