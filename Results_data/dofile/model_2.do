*********model*******

clear 
clear matrix 
set more off

global root         = "/Users/wenyuanlu/Desktop/stata/CFPS" // Mac 



global cfps2020     = "$root/CFPS2020"
global cfps2018     = "$root/CFPS2018/English_version"
global cfps2016     = "$root/CFPS2016/English_version"
global cfps2014     = "$root/CFPS2014/English_version "
global cfps2012     = "$root/CFPS2012/English_version "
global cfps2011     = "$root/CFPS2011/English_version"
global cfps2010     = "$root/CFPS2010/English_version"

global dofiles      = "$root/Results_data/dofile"
global logfiles     = "$root/Results_data/logfile"
global temp_data    = "$root/Results_data/Temp_data"
global working_data = "$root/Results_data/Working_data"

log using "$logfiles/model_2.log",text replace

*************************************************take the variables we need to make a firstborn secondborn **** 
clear

use "$temp_data/family_child_final_10_18.dta"


********************************************

keep pid fid year pid_a_c1  fincome1 tb1y_a_c1 tb2_a_c1 father_edu mother_edu ethnicity familysize urban ///
     fid10 fid12 fid18 fid16 fid14 wa105_1 wb201_1 wb501_1 wb601_1 wb701_1 wb801_1 wc2_1 wc201_1 wc8015_1 ///
	 wz301_1 wz302_1 wf602_1 wg301_1 wg302_1 wg303_1 wg304_1 wg305_1 wg306_1 wg308_1 qf704_a_1 pid_a_c2 ///
	 tb1y_a_c2 tb2_a_c2 wa105_2 wb201_2 wb501_2 wb601_2 wb701_2 wb801_2 wc2_2 wc201_2 wc8015_2 ///
	 wz301_2 wz302_2 wf602_2 wg301_2 wg302_2 wg303_2 wg304_2 wg305_2 wg306_2 wg308_2 

	 	 
	 
save "$working_data/first_secondborn.dta", replace 

********create birth order dummy ************************************ 

use "$working_data/first_secondborn.dta"



*****number of firstborn child ****** 
 
gen xx1 = 0     //若不存在, 则 x`i' = 0
replace xx1 = 1 if pid_a_c1 != .  

tab xx1

*****number of secondborn child ****** 
gen xx2 = 0     //若不存在, 则 x`i' = 0
replace xx2 = 1 if pid_a_c2 != .  //若存在, 则 x`i' = 1
 
tab xx1 xx2

drop xx1 xx2 

**********************************************************
gen birthorder_1 = 0 
replace birthorder_1 = 1 if pid_a_c1 != .

gen birthorder_2 = 0 
replace birthorder_2 = 1 if pid_a_c2 !=.


drop if pid_a_c1 == 77|pid_a_c1 == 79 
drop if pid_a_c2 == 77|pid_a_c1 == 79  


// 去掉没有孩子的人
drop if pid_a_c2 ==. & pid_a_c1 ==.   


// 查看 
order pid year pid_a_c1 pid_a_c2 birthorder_1 birthorder_2 firstborn 
br 


save "$working_data/first_secondborn_v2.dta", replace

*************** log income and age setting  **********************

use  "$working_data/first_secondborn_v2.dta"

gen logincome = log(fincome1)        

*** 确定年龄/去掉非少儿的人(10岁以上） **************
 
gen age_1 = year - tb1y_a_c1 + 1     
gen age_2 = year - tb1y_a_c2 + 1 


drop if age_1 > 10 | age_2 >10


*** 年龄差变量 *********************************

gen age_gap = age_1 - age_2 
	        
drop if age_gap <= 0 | age_gap > 10


save "$working_data/first_secondborn_v3.dta", replace
 
*******Let's regress!~~~~****** *********************************************** 


*构造能够跑交乘项的数据
	//分别提取老大和老二的变量，且变量名统一（类似构建panel data的处理方法)
	
*preserve

use "$working_data/first_secondborn_v3.dta"
keep pid fid fid10 fid12 fid18 fid16 fid14 year pid_a_c1 age_1 age_gap logincome tb1y_a_c1 tb2_a_c1 ///
     father_edu mother_edu ethnicity familysize urban ///
     wa105_1 wb201_1 wb501_1 wb601_1 wb701_1 wb801_1 wc201_1 wc2_1 wc8015_1 ///
     wz301_1 wz302_1 wf602_1 wg301_1 wg302_1 wg303_1 wg304_1 wg305_1 wg306_1 wg308_1 qf704_a_1 

gen first=1
label  var first "child order first=1 second=0"
		

		
//统一变量名     可能需要安装命令  renvarlab


***** drop all the _1 ***************************	
renvarlab  age_1 wb501_1 wb601_1 wb701_1 wb801_1 wc201_1 wc2_1 wc8015_1 wz301_1 wz302_1 wf602_1 wg301_1 ///
           wg302_1 wg303_1 wg304_1 wg305_1 wg306_1 wg308_1, postdrop(2)
		   
***** drop all the 1 ****************************		   
renvarlab pid_a_c1, postdrop(1)	
		   
***** rename the variable hard to figure out **** 			   		 
rename (tb1y_a_c1 tb2_a_c1 qf704_a_1)(date_of_birth gender father_help_housework)


	
save "$working_data/temp_first.dta", replace
	
*restore   

//然后是第二个孩子
	
clear 
use  $working_data/first_secondborn_v3.dta, clear	
keep pid fid fid10 fid12 fid18 fid16 fid14 year pid pid_a_c2 age_2 age_gap logincome ///
     tb1y_a_c2 tb2_a_c2 father_edu mother_edu ethnicity familysize urban   ///
     wa105_1 wc2_2 wc201_2 wb201_2 wb501_2 wb601_2 wb701_2 wb801_2 ///
	 wc8015_2 wz301_2 wz302_2 wf602_2 wg301_2 wg302_2 wg303_2 wg304_2 wg305_2 wg306_2 wg308_2 qf704_a_1 
	
gen first=0
label var first "child order first=1 second=0"  //统一变量名     可能需要安装命令  renvarlab


**** 去掉所有的_2	****************
renvarlab age_2 wc2_2 wc201_2 wb201_2 wb501_2 wb601_2 wb701_2 wb801_2 wc8015_2 wz301_2 ///
	wz302_2 wf602_2 wg301_2 wg302_2 wg303_2 wg304_2 wg305_2 wg306_2 wg308_2, postdrop(2)
	
*** 去掉所有的2*******************
renvarlab pid_a_c2, postdrop(1)	
		
*** rename the variable hard to figure out *****	
rename (tb1y_a_c2 tb2_a_c2 qf704_a_1) (date_of_birth gender father_help_housework)
		
save "$working_data/temp_second.dta" , replace


**************** Append firstborn and secondborn *************************
clear
use  "$working_data/temp_second.dta"	
append using "$working_data/temp_first.dta"   //纵向合并

tab first

**** look at the data structure******************************************* 
sort pid year pid_a_c fid 

order pid year fid pid_a_c first

br 

save "$working_data/first_second.dta", replace
	

*****use CEM (test)******************************************************

imb logincome father_edu mother_edu familysize urban, treatment(first)
	
cem logincome father_edu mother_edu familysize urban, treatment(first)

*** perfactly balance ***** 

save "$working_data/first_second_2.dta"	, replace

************************Regression ******************************************************************


use "$working_data/first_second_2.dta"

**********label***************
label var wg304          "Frequency using toys & games to teach child to count"
label var wg305          "Frequency using toys & games to teach child to differentiate colors"
label var wg306          "Frequency using toys & games to teach child to differentiate shapes"
label var wg308          "Frequency use toys & games to teach child to read"
label var first          "First child"
label var father_edu     "Father's education"
label var mother_edu     "Mother's education"
label var familysize     "Family size"
label var urban          "Urban"
label var gender         "Boy"
label var logincome      "Log household income"
label var date_of_birth  "Date of birth"
label var year           "Survey year"
label var age_gap        "The age gap between firstborn and secondborn"



save "$working_data/final_data.dta", replace 


***********************Descriptive statistics ****************************************

use "$working_data/final_data.dta"

drop wc8015 wc201 wc2 father_help_housework wz302 wz301
	 
outreg2 using descriptive_summary.doc,label replace sum(log)  ///
        keep(first date_of_birth gender father_edu mother_edu logincome familysize urban age_gap  ///
        wg301 wg302 wg303 wg304 wg305 wg306 wg308 wb501 wb601 wb701 wb801) ///
	    eqkeep(N mean min max) title(Descriptive Statistics)	 
	 
***dependant variable, independent variable and controls ********

*** birth order and gender effect on the family care distribution (X birth order- M family care)*********************

global control "age_gap age logincome father_edu mother_edu urban familysize"  
  
eststo r1: reg wg301 first##gender $control
eststo r2: reg wg302 first##gender $control
eststo r3: reg wg303 first##gender $control
eststo r4: reg wg304 first##gender $control
eststo r5: reg wg305 first##gender $control
eststo r6: reg wg306 first##gender $control
eststo r7: reg wg308 first##gender $control
 		
	   
esttab r* using "$working_data/first_gender_effect.rtf",label b(3) se(3) r2 scalars(F) ///
       title("Table 1: The effect of birth order and gender on child's family care") /// 
	   modelwidth(7) nogaps nobaselevels nonumbers ///
	   sfmt(0 0 0 3)  /// 
       interaction(" * ") addnote("Source: CFPS ") ///
       starlevels(* 0.1 ** 0.05 *** 0.01) replace
	   

*******	X(birth order)---Y(outcome: age of walking; age of speaking; age of counting;age of urinate by self) 	   
eststo s1: reg wb501 first##gender $control 
eststo s2: reg wb601 first##gender $control	
eststo s3: reg wb701 first##gender $control
eststo s4: reg wb801 first##gender $control	 

    
esttab s* using "$working_data/first_gender_outcome1.rtf",label b(3) se(3)  r2 scalars(F) ///
       title("Table 2: The effect of birth order and gender on children's mental development") /// 
	   nonumbers modelwidth(7) nogaps nobaselevels ///
	   sfmt(0 0 0 3) interaction(" * ") addnote("Source: CFPS ") ///
       starlevels(* 0.1 ** 0.05 *** 0.01) ///
       replace	   
	   
***************Mechanism : wb501 - age of walking *******************************************

global Y  "wb501"   //这个变量之后可能要分段处理一下? because catgorical variable or not? 

eststo n1: reg $Y  wg301 first##gender $control 
eststo n2: reg $Y  wg302 first##gender $control	
eststo n3: reg $Y  wg303 first##gender $control 
eststo n4: reg $Y  wg304 first##gender $control	
eststo n5: reg $Y  wg305 first##gender $control	
eststo n6: reg $Y  wg306 first##gender $control	 
eststo n7: reg $Y  wg308 first##gender $control  
	

esttab n* using "$working_data/result_walk.rtf",label b(3) se(3)  r2 scalars(F) ///
       title("Table 3: The effect of family education on child's age of walking") /// 
	   nonumbers modelwidth(7) nogaps nobaselevels ///
       order(wg30*) sfmt(0 0 0 3)  /// 
       interaction(" * ") addnote("Source: CFPS ") ///
       starlevels(* 0.1 ** 0.05 *** 0.01) ///
       replace
	
eststo clear

***practice for wb601 ***************************************************************************
global Y2  "wb601" 

eststo o1: reg $Y2  wg301 first##gender $control
eststo o2: reg $Y2  wg302 first##gender $control	
eststo o3: reg $Y2  wg303 first##gender $control
eststo o4: reg $Y2  wg304 first##gender $control	 
eststo o5: reg $Y2  wg305 first##gender $control	
eststo o6: reg $Y2  wg306 first##gender $control	
eststo o7: reg $Y2  wg308 first##gender $control
	
 
esttab o* using "$working_data/result_speak.rtf",label b(3) se(3)  r2 scalars(F) ///
       title("Table 4:  The effect of family education on child's age of speaking") /// 
	   nonumbers modelwidth(7) nogaps nobaselevels ///
       order(wg30* ？) sfmt(0 0 0 3) interaction(" * ") addnote("Source: CFPS ") ///
       starlevels(* 0.1 ** 0.05 *** 0.01) replace
	
eststo clear

*************wb701********************************************************************************
global Y3  "wb701" 

eststo p1: reg $Y3  wg301 first##gender $control
eststo p2: reg $Y3  wg302 first##gender $control	
eststo p3: reg $Y3  wg303 first##gender $control
eststo p4: reg $Y3  wg304 first##gender $control	 
eststo p5: reg $Y3  wg305 first##gender $control	
eststo p6: reg $Y3  wg306 first##gender $control	
eststo p7: reg $Y3  wg308 first##gender $control
	


esttab p* using "$working_data/result_count.rtf",label b(a3) se(3)  r2 scalars(F) ///
       title("Table 5 : The effect of family education on child's age of counting") /// 
	   nonumbers modelwidth(7) nogaps nobaselevels ///
       order(wg30*) sfmt(0 0 0 3) interaction(" * ") addnote("Source: CFPS ") ///
       starlevels(* 0.1 ** 0.05 *** 0.01) ///
       replace
	
eststo clear


*************wb801******************************************************************************************************
global Y4  "wb801" 

eststo q1: reg $Y4  wg301 first##gender $control
eststo q2: reg $Y4  wg302 first##gender $control	
eststo q3: reg $Y4  wg303 first##gender $control
eststo q4: reg $Y4  wg304 first##gender $control	 
eststo q5: reg $Y4  wg305 first##gender $control	
eststo q6: reg $Y4  wg306 first##gender $control	
eststo q7: reg $Y4  wg308 first##gender $control
	


esttab q* using "$working_data/result_urinate.rtf",label b(3) se(3)  r2 scalars(F) ///
       title("Table 6: The effect of family education on child's age of urinate by self") /// 
	   nonumbers modelwidth(7) nogaps nobaselevels ///
       order(wg30* ) sfmt(0 0 0 3) interaction(" * ") addnote("Source: CFPS ") ///
       starlevels(* 0.1 ** 0.05 *** 0.01) ///
       replace
	
eststo clear



************************* Panel datacleaning and fixed effect *******************************************************
 

use "$working_data/final_data.dta", replace


**** 查看数据结构： 是pid层面的观察结果 ******  
sort pid year fid 
order pid year fid pid_a_c first 

***** 一年有两个pid obs, 所以分组 *********************************************************
egen newid = group(pid first)

xtset newid year

save "$working_data/finalpanel_data.dta", replace 



****Descriptive Statistics 2************************************************************

use "$working_data/finalpanel_data.dta"

label var age "Age"
outreg2 using "$working_data/descriptive_summary2.doc",label replace sum(log)  ///
        keep(first date_of_birth gender father_edu mother_edu logincome familysize urban age age_gap  ///
        wg301 wg302 wg303 wg304 wg305 wg306 wg308 wb501 wb601 wb701 wb801) ///
	    eqkeep(N mean min max) title(Descriptive Statistics)	 


	
*** the effect of birth order，gender,age_gap on the family care distribution (X birth order- M family care)**	

 forvalues i= 1(1)6{
   reghdfe wg30`i' first##gender age_gap, absorb(year pid) vce(cluster pid)
   estadd local Year      "Yes"	
   estadd local Household "Yes"
   est store m`i'
  }
    
reghdfe wg308 first##gender age_gap, absorb(year pid) vce(cluster pid) 
estadd local Year      "Yes"	
estadd local Household "Yes"
est store m8 

local m "m*"	   
esttab `m' using "$working_data/first_gender_effect_panel_2.rtf",  ///
       label b(a3) se(3) ar2 scalars(N Year Household) compress nonumbers ///
       title("Table 7 : The effect of birth order gender and age gap on child's family care (control year and family)") /// 
	   modelwidth(7) nogaps nobaselevels sfmt(0 0 0 3) interaction(" * ") addnote("Source: CFPS") star(* 0.1 ** 0.05 *** 0.01) replace


*** the effect of family care on the children's cognative development ***** 	   
	   
*******	X(birth order)---Y(outcome: age of walking; age of speaking; age of counting;age of urinate by self) 	
   
 forvalues i= 5(1)8{
   reghdfe wb`i'01 first##gender age_gap, absorb(year pid) vce(cluster pid)
   estadd local Year      "Yes"	
   estadd local Household "Yes"
   est store r`i'
  }

local r "r*"	    
esttab `r' using "$working_data/first_gender_panel_22.rtf",label b(a3) se(3) nonumbers  ar2 scalars(Year Household N) ///
	   title("Table 8: The effect of birth order gender and age gap on children's mental development (control year and family)") /// 
	   modelwidth(7)  nogaps nobaselevels compress ///
	   sfmt(0 0 0 3) interaction(" * ") addnote("Source: CFPS ") ///
       star(* 0.1 ** 0.05 *** 0.01) replace	   
	   
	   
***************Mechanism : wb501 - age of walking *******************************************
global Y  "wb501"   

 forvalues i= 1(1)6{
   reghdfe $Y wg30`i' first##gender age_gap, absorb(year pid) vce(cluster pid)
   estadd local Year      "Yes"	
   estadd local Household "Yes"
   est store a`i'
  }

reghdfe $Y wg308 first##gender age_gap, absorb(year pid) vce(cluster pid)
estadd local Year      "Yes"	
estadd local Household "Yes"
est store a8

local a "a*"

esttab `a' using "$working_data/result_walk_panel.rtf",label b(a3) se(3) scalars(Year Household N) ///
       title("Table 9: The effect of family care on child's age of walking(control year and family)") /// 
	   modelwidth(7) nogaps nobaselevels compress ///
       sfmt(0 0 0 3) interaction(" * ") addnote("Source: CFPS ") order(wg30*) ///
       star(* 0.1 ** 0.05 *** 0.01) replace
	
eststo clear   
	   
	   
***practice for wb601 ***************************************************************************
global Y2  "wb601" 

 forvalues i= 1(1)6{
   reghdfe $Y2 wg30`i' first##gender age_gap, absorb(year pid) vce(cluster pid)
   estadd local Year      "Yes"	
   estadd local Household "Yes"
   est store b`i'
  }
	
 reghdfe $Y2 wg308 first##gender age_gap, absorb(year pid) vce(cluster pid)
 estadd local Year      "Yes"	
 estadd local Household "Yes"
 est store b8	
	
	
local b "b*"


esttab `b' using "$working_data/result_speak_panel.rtf",label b(a3) se(3) ar2 scalars(Year Household N) ///
       title("Table 10:  The effect of family education on child's age of speaking(control year and family)") /// 
	   modelwidth(7) nogaps nobaselevels order(wg30*) ///
       nonumbers mtitles (`mt1') compress sfmt(0 0 0 3)  /// 
       interaction(" * ") addnote("Source: CFPS ") ///
       starlevels(* 0.1 ** 0.05 *** 0.01) ///
       replace	
	
eststo clear	   
	   
******* Practice for wb701 *******************************************************************	   
global Y3  "wb701" 
	
 forvalues i= 1(1)6{
   reghdfe $Y3 wg30`i' first##gender age_gap, absorb(year pid) vce(cluster pid)
   estadd local Year      "Yes"	
   estadd local Household "Yes"
   est store c`i'
  }
	
 reghdfe $Y3 wg308 first##gender age_gap, absorb(year pid) vce(cluster pid)
 estadd local Year      "Yes"	
 estadd local Household "Yes"
 est store c8
	
local c "c*"

esttab c* using "$working_data/result_count_panel.rtf",label b(a3) se(3)  ar2 scalars(Year Household N)  ///
       title("Table 11 : The effect of family education on child's age of counting(control year and family)") /// 
	   modelwidth(7) nogaps nobaselevels order(wg30*) ///
       nonumbers mtitles (`mt1') compress sfmt(0 0 0 3)  /// 
       interaction(" * ") addnote("Source: CFPS ") ///
       starlevels(* 0.1 ** 0.05 *** 0.01) replace	
	
	
eststo clear	   

*************wb801******************************************************************************************************
global Y4  "wb801" 
	
 forvalues i= 1(1)6{
   reghdfe $Y4 wg30`i' first##gender age_gap, absorb(year pid) vce(cluster pid)
   estadd local Year      "Yes"	
   estadd local Household "Yes"
   est store d`i'
  }
	
reghdfe $Y4 wg308 first##gender age_gap, absorb(year pid) vce(cluster pid)
estadd local Year      "Yes"	
estadd local Household "Yes"
est store d8
	
local d "d*"

esttab d* using "$working_data/result_urinate_panel.rtf",label b(3) se(3) ar2 scalars(Year Household N) ///
       title("Table 12: The effect of family education on child's age of urinate by self(control year and family)") /// 
       modelwidth(7) nogaps nobaselevels order(wg30*) ///
       nonumbers compress sfmt(0 0 0 3)  /// 
       interaction(" * ") addnote("Source: CFPS ") ///
       star(* 0.1 ** 0.05 *** 0.01) replace	
	
	
eststo clear   
	   
	   
	   