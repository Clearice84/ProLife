***to run on ProLife_CRF_randomised_unblind MI 2020-10-16.dta***********

**********theorectically correct approach, but tooooooo slow*******

capture program drop myboot
program define myboot, rclass
	mi impute chained ///
		(pmm, knn(10)) cost_bl_healthcare cost_m3_healthcare cost_m6_healthcare ///
			cost_bl_tbtest cost_trial_tbtest cost_tbmeds cost_m3_art cost_m6_art ///
			m3_utility m6_utility m3_utility_M m6_utility_M m3_utility_B m6_utility_B ///
			m3_vas m6_vas ///
		= a_reported_age a_sex death cost_prolife bl_utility bl_utility_M bl_utility_B ///
		bl_vas, add(5) rseed(999) by(group)

	mi passive: replace ref_cost = cost_bl_healthcare + cost_bl_tbtest
	mi passive: replace totalcost = cost_prolife + cost_tbmeds + cost_m3_art + cost_m6_art + cost_trial_tbtest + cost_m3_healthcare + cost_m6_healthcare

	mi passive: replace qaly = ((bl_utility + m3_utility) * 3/12) / 2 + ((m3_utility + m6_utility) * 3/12) / 2
	
	mi passive: replace qaly_M = ((bl_utility_M + m3_utility_M) * 3/12) / 2 + ((m3_utility_M + m6_utility_M) * 3/12) / 2
	
	mi passive: replace qaly_B = ((bl_utility_B + m3_utility_B) * 3/12) / 2 + ((m3_utility_B + m6_utility_B) * 3/12) / 2
	
	mi estimate: glm totalcost i.group ref_cost i.a_sex a_reported_age, fam(gam) l(i)
	scalar CD = e(b_mi)[1,2]
	
	mi estimate: reg qaly i.group bl_utility i.a_sex a_reported_age
	scalar QD = e(b_mi)[1,2]
	
	mi estimate: reg qaly_M i.group bl_utility_M i.a_sex a_reported_age
	scalar QDm = e(b_mi)[1,2]
	
	mi estimate: reg qaly_B i.group bl_utility_B i.a_sex a_reported_age
	scalar QDb = e(b_mi)[1,2]
	
end

mi set wide
***this has to be wide, otherwise insufficient observations

mi register regular a_reported_age a_sex death cost_prolife bl_utility bl_utility_M bl_utility_B bl_vas cost_trial_healthcare

mi register passive ref_cost totalcost qaly qaly_M qaly_B

mi register imputed cost_bl_healthcare cost_m3_healthcare cost_m6_healthcare ///
			cost_bl_tbtest cost_trial_tbtest cost_tbmeds cost_m3_art cost_m6_art ///
			m3_utility m6_utility m3_utility_M m6_utility_M m3_utility_B m6_utility_B ///
			m3_vas m6_vas

myboot

set seed 12345

bootstrap bootsCD=CD bootsQD=QD bootsQDm=QDm bootsQDb=QDb, reps(3) strata(group) saving (P:\\Documents\PROLIFE\data\analysis\bootstrap MI.dta, replace): myboot

***open bootstrap MI.dta*****************
gen bootsICER = bootsCD/bootsQD
local name "CD QD ICER"
foreach n of local name {
	dis "boots`n'"
	sort boots`n'
	list boots`n' in 125
	list boots`n' in 4875
}

count if bootsQD > 0
***incremental QALYs > 0: 4705
dis 4705/5000
**0.941

********CEP*************
**check axis range
sum bootsCD bootsQD

twoway (scatter bootsCD bootsQD,msize(Small)), ///
	ytitle(Incremental Costs) yscale(range(-200 3000))yline(0) ylabel(-200(800)3000) ///
	xtitle(Incremental QALY) xscale(range(-0.01 0.02)) xline(0) xlabel(-0.01(0.005)0.02) ///
	title(Cost-effectiveness plane) 

****CEAC***
matrix CEAC = J(100000/600,2,0)
local ind = 0
local lambda = 0
while `lambda'<= 100000 {
 local ind=`ind'+1  
 local lambda= `lambda'+600  
*INDI represents a cost-effectiveness realisation*

qui gen INDI=(bootsICER<`lambda') if bootsQD>0
qui replace INDI=(bootsICER>`lambda') if bootsQD<0
qui sum INDI if bootsICER<.
matrix CEAC [`ind',1]=`lambda'  
matrix CEAC [`ind',2]= `r(mean)'  
drop INDI 
}
svmat CEAC  

twoway (line CEAC2 CEAC1), ytitle(Probability cost-effective) yscale(range(0 1)) ///
yline(0.5, lpattern(dash) lcolor(black)) ylabel(0  (0.2) 1, labsize(medsmall) ///
format(%02.1f)) xtitle(Willingness to pay) xscale(range(0 100000)) ///
xlabel(0 (10000) 100000, labsize(medsmall) angle(forty_five) format(%9.0fc)) ///
 xline(18567, lpattern(dash))  xline(74490, lpattern(dash)) title(Cost-effectiveness acceptability curve)  

graph box bootsQD bootsQDm bootsQDb, ytitle(Adjusted difference in mean QALYs between arms)

