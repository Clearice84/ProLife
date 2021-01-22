****to run on ProLife_CRF_randomised_unblind MI 2020-10-16.dta****
**save to new file: ProLife_CCA.dta*****

keep if !mi(totalcost) & !mi(qaly)

by group: sum totalcost qaly

glm totalcost i.group ref_cost i.a_sex a_reported_age, fam(gam) l(i)
reg qaly i.group bl_utility i.a_sex a_reported_age

dis 2488/0.007
***355428.57
**point estimate of ICER

capture program drop myboot
program define myboot, rclass
	glm totalcost i.group ref_cost i.a_sex a_reported_age, fam(gam) l(i)
	sca CD = e(b)[1,2]
	
	reg qaly i.group bl_utility i.a_sex a_reported_age
	sca QD = e(b)[1,2]
	
	sca ICER = CD/QD

end

set seed 12345

bootstrap bootsCD=CD bootsQD=QD bootsICER=ICER, reps(5000) strata(group) saving (P:\\Documents\PROLIFE\data\analysis\bootstrap CCA.dta, replace): myboot

***open bootstrap CCA.dta*****************
local name "CD QD ICER"
foreach n of local name {
	dis "boots`n'"
	sort boots`n'
	list boots`n' in 125
	list boots`n' in 4875
}

********CEP*************
**check axis range
sum bootsCD bootsQD

twoway (scatter bootsCD bootsQD,msize(Small)), ///
	ytitle(Incremental Costs) yscale(range(-200 3800))yline(0) ylabel(-200(800)3800) ///
	xtitle(Incremental QALY) xscale(range(-0.02 0.03)) xline(0) xlabel(-0.02(0.01)0.03) ///
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

