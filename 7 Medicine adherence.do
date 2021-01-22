***to run on ProLife_CRF_2020-08-27_adherence index.dta*****
keep if !mi(group)
keep id TB_Adherence_Index_3m TB_Adherence_Index_6m ART_Adherence_Index_3m ART_Adherence_Index_6m
sort id
**save to new file ProLife_CRF_2020-08-27_adherence index only.dta*****

***to run on ProLife_CRF_randomised_unblind MI 2020-10-16.dta*****
sort id
merge 1:1 id using "\\hscifs6\usershomedir$\jl1405\Documents\PROLIFE\data\ProLife_CRF_2020-08-27_adherence index only.dta", gen(_medadh)
***all match****
drop _medadh
**save to new file ProLife_CRF_randomised_unblind MI adherence 2020-10-25.dta***

***to run on ProLife_CRF_randomised_unblind MI adherence 2020-10-25.dta*****
sort group

local med "TB ART"
foreach m of local med {
	foreach n of numlist 3 6 {
		tab `m'_Adherence_Index_`n'm group, m
	}
}
***index >= 95% is optimal, there is no value between 100 and 75 in the dataset***
label define adherence 0 "suboptimal" 1 "optimal" 2 "unknown"
local med "TB ART"
foreach m of local med {
	foreach n of numlist 3 6 {
		gen m`n'_`m'adherence = 1 if `m'_Adherence_Index_`n'm == 100
		replace m`n'_`m'adherence = 0 if `m'_Adherence_Index_`n'm < 100
		replace m`n'_`m'adherence = 2 if `m'_Adherence_Index_`n'm > 100 & !mi(`m'_Adherence_Index_`n'm)
		label values m`n'_`m'adherence adherence
		tab m`n'_`m'adherence group, col
	}
}

label define adherence 3 "one point optimal", add
local med "TB ART"
foreach m of local med {
	gen temp = 1 if !mi(m3_`m'adherence) & !mi(m6_`m'adherence)
	gen trial_`m'adherence = 1 if m3_`m'adherence == 1 & m6_`m'adherence == 1
	replace trial_`m'adherence = 0 if m3_`m'adherence == 0 & m6_`m'adherence == 0
	replace trial_`m'adherence = 2 if m3_`m'adherence == 2 & m6_`m'adherence == 2
	replace trial_`m'adherence = 3 if (m3_`m'adherence == 1 | m6_`m'adherence == 1) & temp == 1 & trial_`m'adherence != 1
	replace trial_`m'adherence = 0 if temp == 1 & mi(trial_`m'adherence)
	drop temp
	label values trial_`m'adherence adherence
	tab trial_`m'adherence group, col
}




