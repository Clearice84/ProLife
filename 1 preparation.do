***Analysis file generation************************************************

*****to run on ProLife_CRF_2020-08-27.dta
count
**include unrandomised objects
keep if group != .
***n=574
tab group, m
label define group 1 "Usual care", modify
label define group 2 "ProLife", modify
****save to ProLife_CRF_randomised_unblind 2020-10-16.dta

***to run on ProLife_CRF_randomised_unblind 2020-10-16.dta
**2b.FinalDataGenerationCode_MK JL.do

***********************************************************************
****to run on ProLife_MI_2020-08-27***********
sort study_number
***save
sort study_number
merge 1:1 study_number using "\\hscifs6\usershomedir$\jl1405\Documents\PROLIFE\data\ProLife_MI_2020-08-27.dta"
***all participants in intervention matched
drop _merge
****save to ProLife_CRF_randomised_unblind MI 2020-10-16.dta

****to run on ProLife_CRF_randomised_unblind MI 2020-10-16.dta
foreach n of numlist 1/3 {
	tab participant_arrived_mi_`n' mi_`n'_full if group == 2, m
}
****all those who have not arrived did not have completion level, but some of those arrived missing completion level or state not at all completed the session
****as we do not have exact minutes, we use participant_arrived_mi_`n' to indicate session attendance. all those who did not arrive or missing are considered not attending
***Note it is a limitation in estimating cost of intervention delivery

foreach n of numlist 1/3 {
	gen mi_sess`n' = participant_arrived_mi_`n'
	recode mi_sess`n' .=1 if group == 2
	label val mi_sess`n' participant_arrived_mi_`n'
	tab mi_sess`n' if group == 2, m
}

gen uc_mises1 = 5.31
gen uc_mises2 = 5
gen uc_mises3 = 5.31

foreach n of numlist 1/3 {
    gen c_mises`n' = uc_mises`n' if mi_sess`n' == 2
	replace c_mises`n' = 0 if mi_sess`n' == 1
}
egen cost_mises = rowtotal(c_mises1-c_mises3)
bysort group: sum cost_mises

gen cost_misystem = 4.59 if group == 2
gen cost_training = 2429 if group == 2
gen cost_supervision = 157 if group == 2

gen cost_prolife = cost_mises + cost_misystem + cost_training + cost_supervision
replace cost_prolife = 0 if group == 1
sum cost_prolife if group == 2

******TB biochemical investigations******************************
*****if n of investigations were "missing/not recorded", they are considered 0
*****if n of investigations missing, they are considered missing
gen bl_smear = a_nr_pre_treat_results
gen bl_xpert = a_number_xpert_results
gen bl_culture = a_number_culture_results
local name "smear xpert culture"
foreach n of local name {
    replace bl_`n' = 0 if bl_`n' == .a
}

gen m2_smear = b_nr_results_month2
gen m3_smear = b_nr_results_month3
gen m6_smear = c_nr_results_month6

bysort group: sum bl_smear-m6_smear

local name "smear xpert culture"
foreach n of local name {
    tab bl_`n' group, col
}

foreach n of numlist 2 3 6 {
    tab m`n'_smear group, col
}

gen uc_smear = 28.37
gen uc_culture = 79.22
gen uc_xpert = 201.56

local name "smear xpert culture"
foreach n of local name {
    gen c_bl_`n' = bl_`n' * uc_`n'
	by group: sum c_bl_`n'
}

local name "smear xpert culture"
foreach n of local name {
    egen temp`n'1 = total(c_bl_`n') if group == 1 & bl_`n' == 1
	egen temp`n'2 = total(c_bl_`n') if group == 1 & bl_`n' == 2
	egen temp`n'3 = total(c_bl_`n') if group == 2 & bl_`n' == 1
	egen temp`n'4 = total(c_bl_`n') if group == 2 & bl_`n' == 2
	by group: sum temp*
	drop temp*
}

foreach n of numlist 2 3 6 {
    gen c_m`n'_smear = m`n'_smear * uc_smear
	by group: sum c_m`n'_smear
}

foreach n of numlist 2 3 6 {
    egen temp`n'1 = total(c_m`n'_smear) if group == 1 & m`n'_smear == 1
	egen temp`n'2 = total(c_m`n'_smear) if group == 1 & m`n'_smear == 2
	egen temp`n'3 = total(c_m`n'_smear) if group == 2 & m`n'_smear == 1
	egen temp`n'4 = total(c_m`n'_smear) if group == 2 & m`n'_smear == 2
	by group: sum temp*
	drop temp*
}

by group: sum c_bl_smear-c_m6_smear

egen cost_bl_tbtest = rowtotal(c_bl_smear-c_bl_culture), m
egen cost_m3_tbtest = rowtotal(c_m2_smear c_m3_smear), m
gen cost_m6_tbtest = c_m6_smear
egen cost_trial_tbtest = rowtotal(cost_m3_tbtest cost_m6_tbtest), m

by group: sum cost_*_tbtest

**************TB drug*****************************************************
local med "rhze rh h z e s"
foreach m of local med {
	tab a_ip_`m'_1 treatment_regimen, m
}

tab treatment_outcome group, m 

gen tbmed_course = 1 if treatment_outcome == 1 | treatment_outcome == 0
replace tbmed_course = 2 if treatment_outcome == 2 | treatment_outcome == 3 | treatment_outcome == 4 | treatment_outcome == 6
replace tbmed_course = 3 if treatment_outcome == 5 | treatment_outcome == 7 | mi(treatment_outcome)
label define tbmed_course 1 "complete" 2 "incomplete" 3 "unknown"
label val tbmed_course tbmed_course
tab tbmed_course group, col

gen uc_IP = 65.8
gen uc_CP = 55.56

gen cost_tbmeds = uc_IP * 2 + uc_CP * 4 if tbmed_course == 1
replace cost_tbmeds = uc_IP * 2 + uc_CP if tbmed_course == 2

by group: sum cost_tbmeds

*************ART************************************************************
sum a_hiv_status a_art a_art_start_date *_taking_art *_taking_art_startdate
tab a_art b_taking_art, m
list a_art_start_date b_taking_art_startdate if a_art == 0 & b_taking_art == 1
list b_taking_art_startdate c_taking_art_startdate if b_taking_art == 0 & c_taking_art == 1
**dates are very messy and incorrect. Some answered not taking ART still provide a start date. Baseline only has y/n to ART, no detailed schedule
rename *_zidomat_100_300 *_zidomat

egen b_artmed = rowtotal(b_atroiza b_dumiva b_tenemine b_zovilam b_kavimun b_ricovir b_zidomat b_lazena b_efrin b_efamat b_acriptaz), m
replace b_artmed = 0 if b_taking_art == 0

egen c_artmed = rowtotal(c_atroiza c_dumiva c_tenemine c_zovilam c_kavimun c_ricovir c_zidomat c_lazena c_efrin c_efamat c_acriptaz), m
replace c_artmed = 0 if c_taking_art == 0

tab b_artmed b_taking_art, m
tab c_artmed c_taking_art, m

tab a_hiv_status b_taking_art, m
tab a_hiv_status c_taking_art, m
**there are people who taking ART but HIV status is negative, not much use

local med "atroiza dumiva tenemine zovilam kavimun ricovir zidomat lazena efrin efamat acriptaz"
foreach m of local med {
	tab b_`m'_prescribed b_`m' if b_`m' == 1, m
	tab c_`m'_prescribed c_`m' if c_`m' == 1, m
}
******some participants reported they were supposed to take 0 dose per day. possibly interval longer than one day

tab b_taking_art group, m col
tab c_taking_art group, m col

tab b_artmed group if b_taking_art == 1, m col
tab c_artmed group if c_taking_art == 1, m col

local med "atroiza dumiva tenemine zovilam kavimun ricovir zidomat lazena efrin efamat acriptaz"
foreach m of local med {
	dis "month 3 `m'"
	tab group if b_`m' == 1
	dis "month 6 `m'"
	tab group if c_`m' == 1
}

local med "atroiza dumiva tenemine zovilam kavimun ricovir zidomat lazena efrin efamat acriptaz"
foreach m of local med {
	dis "month 3 `m'"
	tab b_`m'_prescribed group if b_`m' == 1, m
	dis "month 6 `m'"
	tab c_`m'_prescribed group if c_`m' == 1, m
}

local med "atroiza dumiva tenemine zovilam kavimun ricovir zidomat lazena efrin efamat acriptaz"
foreach m of local med {
	dis "month 3 `m'"
	tab b_`m'_prescribed b_artmed if b_`m' == 1, m
	dis "month 6 `m'"
	tab c_`m'_prescribed c_artmed if c_`m' == 1, m
}

local med "atroiza dumiva tenemine zovilam kavimun ricovir zidomat lazena efrin efamat acriptaz"
foreach m of local med {
	replace b_`m'_prescribed = . if b_`m' == 1 & b_`m'_prescribed > 5
	replace c_`m'_prescribed = . if c_`m' == 1 & c_`m'_prescribed > 5
}

tab month_3_completed b_taking_art, m
tab month_6_completed c_taking_art, m
****all missing taking_art are lost-to-follow-up at that follow-up

gen uc_atroiza = 3.78
gen uc_dumiva = 5.55
gen uc_tenemine = 2.34
gen uc_zovilam = 1.72
gen uc_kavimun = 1.89
gen uc_ricovir = 1.36
gen uc_zidomat = 1.38
gen uc_lazena = 0.55
gen uc_efrin = 0.63
gen uc_efamat = 0.63
gen uc_acriptaz = 0.61

local med "atroiza dumiva tenemine zovilam kavimun ricovir zidomat lazena efrin efamat acriptaz"
foreach m of local med {
	gen c_m3_`m' = b_`m'_prescribed * uc_`m' * 90
	replace c_m3_`m' = uc_`m' * 90/2 if b_`m'_prescribed == 0
	replace c_m3_`m' = 0 if b_`m' == 0
	replace c_m3_`m' = 0 if b_taking_art == 0
	gen c_m6_`m' = c_`m'_prescribed * uc_`m' * 90
	replace c_m6_`m' = uc_`m' * 90/2 if c_`m'_prescribed == 0
	replace c_m6_`m' = 0 if c_`m' == 0
	replace c_m6_`m' = 0 if c_taking_art == 0
}

gen cost_m3_art = c_m3_atroiza + c_m3_dumiva + c_m3_tenemine + c_m3_zovilam + c_m3_kavimun + c_m3_ricovir + c_m3_zidomat + c_m3_lazena + c_m3_efrin + c_m3_efamat + c_m3_acriptaz

gen cost_m6_art = c_m6_atroiza + c_m6_dumiva + c_m6_tenemine + c_m6_zovilam + c_m6_kavimun + c_m6_ricovir + c_m6_zidomat + c_m6_lazena + c_m6_efrin + c_m6_efamat + c_m6_acriptaz

by group: sum cost_m3_art cost_m6_art

********************************************************************
gen death = 1 if treatment_outcome == 5
tab death group
list new_bl_date new_m3_date new_m6_date treatment_outcome_date if death == 1
****death was extracted from treatment_outcome but treatment_outcome_date is not complete.
***we can't determine when death occurred. Problme with imputation as we can't compare with date of 3m and 6m follow-up
tab month_3_completed month_6_completed if death == 1, m
***19 missing both (considering the question, missing should be not completed)
***1 death completed both 3m and 6m, 1 completed 6m but not 3m, 5 completed 3m but not 6m
***this doesn't solve the problem with imputation as we couldn't determine if lost-to-follow-up at 3m and 6m is missing or due to death.
replace death = 0 if treatment_outcome < 5
***With concrete outcome, they are considered not dead
replace death = 2 if treatment_outcome > 5
***transferred out or unknown, or missing, death stauts unknown
label define death 0 "Alive" 1 "Dead" 2 "Unknown"
label values death death
tab death group, col

rename a_visited_facility_tb a_visited_facility_for_tb
local time "a b c"
foreach t of local time {
	tab group `t'_visited_facility_for_tb, m
}

local time "a b c"
foreach t of local time {
	tab `t'_visit_public_clinic `t'_visit_public_hospital if `t'_visited_facility_for_tb ==1 , m
}
***some participants answered yes to visited facility for tb but no to both public clinic and hospital. However, they could have gone to private facility, therefore not unreasonable

sum *_visit_public_clinic_times *_visit_public_hospital_times
***baseline extreme values
histogram a_visit_public_clinic_times
**1 50
histogram a_visit_public_hospital_times
**1 200

gen bl_pubclinic = a_visit_public_clinic_times
replace bl_pubclinic = . if bl_pubclinic == 50

gen bl_pubhos = a_visit_public_hospital_times
replace bl_pubhos = . if bl_pubhos == 200

gen m3_pubclinic = b_visit_public_clinic_times
gen m6_pubclinic = c_visit_public_clinic_times

gen m3_pubhos = b_visit_public_hospital_times
gen m6_pubhos = c_visit_public_hospital_times

replace bl_pubclinic = 0 if a_visited_facility_for_tb == 0
replace bl_pubhos = 0 if a_visited_facility_for_tb == 0
replace bl_pubclinic = 0 if a_visit_public_clinic == 0
replace bl_pubhos = 0 if a_visit_public_hospital == 0

replace m3_pubclinic = 0 if b_visited_facility_for_tb == 0
replace m3_pubhos = 0 if b_visited_facility_for_tb == 0
replace m3_pubclinic = 0 if b_visit_public_clinic == 0
replace m3_pubhos = 0 if b_visit_public_hospital == 0

replace m6_pubclinic = 0 if c_visited_facility_for_tb == 0
replace m6_pubhos = 0 if c_visited_facility_for_tb == 0
replace m6_pubclinic = 0 if c_visit_public_clinic == 0
replace m6_pubhos = 0 if c_visit_public_hospital == 0

local time "bl m3 m6"
foreach t of local time {
	by group: sum `t'_pubclinic if `t'_pubclinic != 0
	by group: sum `t'_pubhos if `t'_pubhos != 0
}

sum *_hospital_overnight_nr
***one participant stayed 90 days at month 3, which means they were in hospital for 3 months
***one participant at baseline answered yes to overnight stay but number of nights was 0
***both keep as they are

gen bl_hosstay = a_hospital_overnight_nr
replace bl_hosstay = 0 if a_hospital_overnight == 0
replace bl_hosstay = 0 if a_visit_public_hospital == 0
replace bl_hosstay = 0 if a_visited_facility_for_tb == 0

gen m3_hosstay = b_hospital_overnight_nr
replace m3_hosstay = 0 if b_hospital_overnight == 0
replace m3_hosstay = 0 if b_visit_public_hospital == 0
replace m3_hosstay = 0 if b_visited_facility_for_tb == 0

gen m6_hosstay = c_hospital_overnight_nr
replace m6_hosstay = 0 if c_hospital_overnight == 0
replace m6_hosstay = 0 if c_visit_public_hospital == 0
replace m6_hosstay = 0 if c_visited_facility_for_tb == 0

sum *_hosstay

gen uc_inp_bedday = 2198.26
gen uc_opt_clinic = 152.04
gen uc_opt_hos = 213.4

local time "bl m3 m6"
foreach t of local time {
	gen c_`t'_pubclinic = `t'_pubclinic * uc_opt_clinic
	gen c_`t'_pubhos = `t'_pubhos * uc_opt_hos
	gen c_`t'_hosstay = `t'_hosstay * uc_inp_bedday
	label var c_`t'_hosstay "cost per visit, count as one as we don't know n of stays"
}

sum c_bl_* c_m3_* c_m6_*

local time "bl m3 m6"
foreach t of local time {
	gen cost_`t'_healthcare = c_`t'_pubclinic + c_`t'_pubhos + c_`t'_hosstay
}

by group: sum cost_bl_healthcare cost_m3_healthcare cost_m6_healthcare

gen cost_trial_healthcare = cost_m3_healthcare + cost_m6_healthcare
by group: sum cost_trial_healthcare

gen cost_usualcare = cost_tbmeds + cost_m3_art + cost_m6_art + cost_trial_tbtest
gen totalcost = cost_prolife + cost_usualcare + cost_trial_healthcare
by group: sum cost_prolife cost_usualcare cost_trial_healthcare totalcost

gen ref_cost = cost_bl_healthcare + cost_bl_tbtest

sysdir set PLUS "P:\\Documents\STATA\"

************EQ5D********************
gen bl_eq1 = a_mobility
gen bl_eq2 = a_self_care
gen bl_eq3 = a_usual_activities
gen bl_eq4 = a_pain_discomfort
gen bl_eq5 = a_anxiety_depression
gen bl_vas = a_state_of_health

gen m3_eq1 = b_mobility
gen m3_eq2 = b_self_care
gen m3_eq3 = b_usual_activities
gen m3_eq4 = b_pain_discomfort
gen m3_eq5 = b_anxiety_depression
gen m3_vas = b_state_of_health

gen m6_eq1 = c_mobility
gen m6_eq2 = c_self_care
gen m6_eq3 = c_usual_activities
gen m6_eq4 = c_pain_discomfort
gen m6_eq5 = c_anxiety_depression
gen m6_vas = c_state_of_health

local time "bl m3 m6"
foreach t of local time {
	foreach n of numlist 1/5 {
		recode `t'_eq`n' 2=3
		recode `t'_eq`n' 1=2
		recode `t'_eq`n' 0=1
	}
}

local time "bl m3 m6"
foreach t of local time {
	egen `t'_profile = concat(`t'_eq1 `t'_eq2 `t'_eq3 `t'_eq4 `t'_eq5)
}
sort bl_profile
destring bl_profile, replace
rename bl_profile profile
merge m:1 profile using "\\hscifs6\usershomedir$\jl1405\Documents\PROLIFE\data\Argentina EQ 5D VAS.dta", keepusing(Mean) gen(_bleq3l) keep(1 3)
rename Mean bl_utility
rename profile bl_profile

sort m3_profile
replace m3_profile = "" if m3_profile == "....."
destring m3_profile, replace
rename m3_profile profile
merge m:1 profile using "\\hscifs6\usershomedir$\jl1405\Documents\PROLIFE\data\Argentina EQ 5D VAS.dta", keepusing(Mean) gen(_m3eq3l) keep(1 3)
rename Mean m3_utility
rename profile m3_profile

sort m6_profile
replace m6_profile = "" if m6_profile == "....."
destring m6_profile, replace
rename m6_profile profile
merge m:1 profile using "\\hscifs6\usershomedir$\jl1405\Documents\PROLIFE\data\Argentina EQ 5D VAS.dta", keepusing(Mean) gen(_m6eq3l) keep(1 3)
rename Mean m6_utility
rename profile m6_profile

bysort group: sum *_utility *_vas

gen qaly = ((bl_utility + m3_utility) * 3/12) / 2 + ((m3_utility + m6_utility) * 3/12) / 2

by group: sum qaly

eq5dds bl_eq1 bl_eq2 bl_eq3 bl_eq4 bl_eq5 if qaly != ., v(3L) by(group)
eq5dds m3_eq1 m3_eq2 m3_eq3 m3_eq4 m3_eq5 if qaly != ., v(3L) by(group)
eq5dds m6_eq1 m6_eq2 m6_eq3 m6_eq4 m6_eq5 if qaly != ., v(3L) by(group)


**********model test******************************************
reg totalcost i.group ref_cost i.a_sex a_reported_age
estat ic

glm totalcost i.group ref_cost i.a_sex a_reported_age, fam(gam) l(i)
estat ic
***lowest AIC and BIC

glm totalcost i.group ref_cost i.a_sex a_reported_age, fam(gam) l(log)
estat ic

reg qaly i.group bl_utility i.a_sex a_reported_age
estat ic

glm qaly i.group bl_utility i.a_sex a_reported_age, fam(gau)
estat ic
****reg and glm,fam(gau) are the same, identical results, lowest AIC and BIC

glm qaly i.group bl_utility i.a_sex a_reported_age, fam(gam) l(i)
estat ic

glm qaly i.group bl_utility i.a_sex a_reported_age, fam(gam) l(log)
estat ic

***alternative calculate utility of EQ-5D-3L for sensitivity analysis*******
****Malaysia*************************************
matrix EQ3L_M=(0, -0.084, -0.191\/*
*/0, -0.097, -0.16\/*
*/0, -0.053, -0.122\/*
*/0, -0.054, -0.127\/*
*/0, -0.081, -0.086)
gen cons_M = -0.067
gen n3_M = -0.116 
****Belgium**************************************
matrix EQ3L_B=(0, -0.074, -0.148\/*
*/0, -0.083, -0.166\/*
*/0, -0.031, -0.062\/*
*/0, -0.084, -0.168\/*
*/0, -0.103, -0.206)
gen cons_B = -0.152
gen n3_B = -0.256

local name "bl m3 m6"
local country "M B"
foreach c of local country {
	foreach n of local name {
		gen mobility_`n' = EQ3L_`c'[1, `n'_eq1[_n]]
		gen selfcare_`n' = EQ3L_`c'[2, `n'_eq2[_n]]
		gen usualact_`n' = EQ3L_`c'[3, `n'_eq3[_n]]
		gen paindiscom_`n' = EQ3L_`c'[4, `n'_eq4[_n]]
		gen antdepres_`n' = EQ3L_`c'[5, `n'_eq5[_n]]
		egen temp = rowtotal(`n'_eq1-`n'_eq5)
		gen cons_`n' = cons_`c' if temp > 5 & temp <=15
		replace cons_`n' = 0 if temp == 5
		gen n3_`n' = -0.116 if `n'_eq1 == 3 | `n'_eq2 == 3 | `n'_eq3 == 3 | `n'_eq4 == 3 | `n'_eq5 == 3
		replace n3_`n' = 0 if `n'_eq1 != 3 & `n'_eq2 != 3 & `n'_eq3 != 3 & `n'_eq4 != 3 & `n'_eq5 != 3 & temp <= 15
		gen `n'_utility_`c' = 1 + mobility_`n' + selfcare_`n' + usualact_`n' + paindiscom_`n' + antdepres_`n' + cons_`n' + n3_`n'
		drop temp mobility_`n' selfcare_`n' usualact_`n' paindiscom_`n' antdepres_`n' cons_`n' n3_`n'
	}
	drop cons_`c' n3_`c'
}

by group: sum bl_utility_M-m6_utility_B

local country "M B"
foreach c of local country {
	gen qaly_`c' = ((bl_utility_`c' + m3_utility_`c') * 3/12) / 2 + ((m3_utility_`c' + m6_utility_`c') * 3/12) / 2
}

by group: sum qaly_*

*****************************************************************************
**********secondary outcomes*************************************************

******Payments to TB-related healthcare services*****************************
sum *_visit_public_clinic_rands *_visit_public_hospital_rands

local time "bl m3 m6"
local name "pubclinic pubhos"
foreach t of local time {
	foreach n of local name {
		gen `t'_yn`n' = 1 if `t'_`n' > 0 & !mi(`t'_`n')
		replace `t'_yn`n' = 0 if `t'_`n' == 0
		tab `t'_yn`n' group, m
	}
}

gen bl_oop_pubclinic = a_visit_public_clinic_rands
gen bl_oop_pubhos = a_visit_public_hospital_rands

gen m3_oop_pubclinic = b_visit_public_clinic_rands
gen m3_oop_pubhos = b_visit_public_hospital_rands

gen m6_oop_pubclinic = c_visit_public_clinic_rands
gen m6_oop_pubhos = c_visit_public_hospital_rands

local time "bl m3 m6"
local name "pubclinic pubhos"
foreach t of local time {
	foreach n of local name {
		by group: sum `t'_oop_`n' if `t'_yn`n' == 1
	}
}

local time "bl m3 m6"
local name "pubclinic pubhos"
foreach t of local time {
	foreach n of local name {
		gen p_`t'_`n' = `t'_`n' * `t'_oop_`n'
		replace p_`t'_`n' = 0 if `t'_`n' == 0
	}
	gen pay_`t'_healthcare = p_`t'_pubclinic + p_`t'_pubhos
}

by group: sum p_bl_pubclinic-pay_m6_healthcare

gen pay_trial_healthcare = pay_m3_healthcare + pay_m6_healthcare
by group: sum pay_trial_healthcare

***********Payments to stop smoking, purchase cigarettes & alcohol**************
sum *_methods_stop_smoking_r *_week_cigarettes_r *_spent_on_alcohol

***a_methods_stop_smoking 0/1 n/y; b/c_methods_stop_smoking 1/2 n/y
gen pay_bl_stopsmoke = a_methods_stop_smoking_r
tab group if pay_bl_stopsmoke == 0 & a_methods_stop_smoking == 1
tab group if pay_bl_stopsmoke == . & a_methods_stop_smoking == 1
by group: sum pay_bl_stopsmoke if pay_bl_stopsmoke != 0

gen pay_m3_stopsmoke = b_methods_stop_smoking_r
tab group if pay_m3_stopsmoke == 0 & b_methods_stop_smoking == 2
tab group if pay_m3_stopsmoke == . & b_methods_stop_smoking == 2
by group: sum pay_m3_stopsmoke if pay_m3_stopsmoke != 0

gen pay_m6_stopsmoke = c_methods_stop_smoking_r
tab group if pay_m6_stopsmoke == 0 & c_methods_stop_smoking == 2
tab group if pay_m6_stopsmoke == . & c_methods_stop_smoking == 2
by group: sum pay_m6_stopsmoke if pay_m6_stopsmoke != 0

tab a_methods_stop_smoking group
tab b_methods_stop_smoking group
tab c_methods_stop_smoking group

by group: sum *_week_cigarettes_r *_spent_on_alcohol

tab new_smoking_drinking group if !mi(baseline_completed)
tab new_smoking_drinking group if !mi(month_3_completed)
tab new_smoking_drinking group if !mi(month_6_completed)


**********TB outcome*********************
tab new_treatment_outcome_2Cat group, col

**********6m CO-quit*********************
gen m6_coquit = new_bc_abstinence_2Cat
replace m6_coquit = 0 if c_breath_carbon_monoxide > 6 & !mi(m6_coquit)
replace m6_coquit = 0 if (b_tried_quitting_smoking !=2 | c_tried_quitting_smoking != 2) & !mi(m6_coquit)
replace m6_coquit = 0 if mi(m6_coquit) & a_manufactured_cigarettes == 1
replace m6_coquit = . if a_manufactured_cigarettes != 1
***Mona used manufatured cigarettes smokers only to calculate quit rate, not all smokers were inlcuded

tab m6_coquit group, col

**********harmful/hazardous drinking*************
sum new_a_audit new_b_audit new_c_audit
****harmful/hazardous drinking AUDIT < 20, male >= 8, female >= 7********
**month 3 and 6, AUDIT score has higher than 20
gen bl_harmdrink = 1 if new_a_audit > 7 & !mi(new_a_audit) & a_sex == 0
replace bl_harmdrink = 1 if new_a_audit > 6 & !mi(new_a_audit) & a_sex == 1
replace bl_harmdrink = 0 if mi(bl_harmdrink) & !mi(new_a_audit) & new_smoking_drinking != 10

gen m3_harmdrink = 1 if new_b_audit > 7 & !mi(new_b_audit) & a_sex == 0
replace m3_harmdrink = 1 if new_b_audit > 6 & !mi(new_b_audit) & a_sex == 1
replace m3_harmdrink = 2 if new_b_audit > 19 & !mi(new_b_audit)
replace m3_harmdrink = 0 if mi(m3_harmdrink) & !mi(new_b_audit) & new_smoking_drinking != 10

gen m6_harmdrink = 1 if new_c_audit > 7 & !mi(new_c_audit) & a_sex == 0
replace m6_harmdrink = 1 if new_c_audit > 6 & !mi(new_c_audit) & a_sex == 1
replace m6_harmdrink = 2 if new_c_audit > 19 & !mi(new_c_audit)
replace m6_harmdrink = 0 if mi(m6_harmdrink) & !mi(new_c_audit) & new_smoking_drinking != 10

label define drinking 0 "not harmful/hazardous" 1 "harmful/hazardous" 2 " alcohol dependence"
label values *_harmdrink drinking

local time "bl m3 m6"
foreach t of local time {
    tab `t'_harmdrink group if new_smoking_drinking != 10, col
}

egen harmdrink = rowmiss(bl_harmdrink m3_harmdrink m6_harmdrink)
local time "bl m3 m6"
foreach t of local time {
    tab `t'_harmdrink group if harmdrink == 0, col
}

