*********model*******

clear 
clear matrix 
set more off

global root         = "/Users/wenyuanlu/Desktop/stata/CFPS" // Mac 
*global root         "D:\research\LU_Wenyuan\CFPS" 			//帮你调代码时候的临时路径，之后重新用前面注释掉的 


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


use "$temp_data/family_child_final_10_18.dta"
log using "$logfiles/model.log",text replace


**********only consider 1-3rd child*** 
***two version of data (3 child or no limitation)
***手动清除 4-10号的所有指标******* 

save "$temp_data/family_top3child_10_18.dta", replace

use "$temp_data/family_top3child_10_18.dta"

*************************************************take the variables we need to make a firstborn secondborn **** 
clear

use "$temp_data/family_child_final_10_18.dta"

keep year pid_a_c1  fincome1 tb1y_a_c1 tb2_a_c1 father_edu mother_edu ethnicity familysize urban ///
     fid10 fid12 fid18 fid16 fid14 wa105_1 wb201_1 wb501_1 wb601_1 wb701_1 wb801_1 wc8015_1 wz301_1 wz302_1 wf602_1 wg301_1 ///
     wg302_1 wg303_1 wg304_1 wg305_1 wg306_1 wg308_1 qf704_a_1 pid_a_c2 tb1y_a_c2 tb2_a_c2 wa105_2 wb201_2 wb501_2 ///
	 wb601_2 wb701_2 wb801_2 wc8015_2 wz301_2 wz302_2 wf602_2 wg301_2 wg302_2 wg303_2 wg304_2 wg305_2 wg306_2 wg308_2 

save "$working_data/first_secondborn.dta", replace 

********create birth order dummy ****************** 
gen birthorder = 0 
replace birthorder = 1 if pid_a_c1 != . 
replace birthorder = 2 if pid_a_c2 != . 

gen firstborn = 0  
replace firstborn = 1 if birthorder == 1 & birthorder != .
gen secondborn = 0
replace secondborn= 1 if birthorder == 2 & birthorder != .

drop if pid_a_c1 == 77|pid_a_c1 == 79  /// 没有第一个孩子

drop if pid_a_c2 == 77|pid_a_c1 == 79 /// 没有第二个孩子

save "$working_data/first_secondborn_v2.dta", replace

**** log income ************
gen logincome = log(fincome1)

sort pid_a_c1 pid_a_c2 year  
  
save "$working_data/first_secondborn_v3.dta", replace
  
*******Let's regress!~~~~******  

/*    这一组是你写的，下面的是我写的


use  "$working_data/first_secondborn_v3.dta"
drop if tb1y_a_c1 < 2008
drop if tb1y_a_c2 < 2008

keep if pid_a_c1 !=. & pid_a_c2 !=.

save "$working_data/first_secondborn_v4.dta", replace



***** var************
global X1  "i.wg301_1 i.wg302_1 i.wg303_1 i.wg304_1 i.wg308_1"
global X2  "i.wg302_2 i.wg303_2 i.wg304_2 i.wg305_2 i.wg306_2 i.wg308_2"

global control "wz301_1 wz302_1 logincome i.father_edu i.mother_edu familysize urban"


reg wb501_1 i.wg301_1 i.wg302_1 i.wg303_1 i.wg304_1 i.wg308_1 

reg wb501_1 f(1) s i.wg301_1 i.wg302_1 i.wg303_1 i.wg304_1 i.wg308_1 

reg wb501_2 f s(1) wg301_2 i.wg302_2 i.wg303_2 i.wg304_2 i.wg308_2  
*/




use  $root/first_secondborn_v3.dta, clear

*构造能够跑交乘项的数据
	//分别提取老大和老二的变量，且变量名统一
preserve

	keep year pid_a_c1  fincome1 tb1y_a_c1 tb2_a_c1 father_edu mother_edu ethnicity familysize urban ///
         fid10 fid12 fid18 fid16 fid14 wa105_1 wb201_1 wb501_1 wb601_1 wb701_1 wb801_1 wc201_1 wc2_1 wc8015_1 wz301_1 wz302_1 wf602_1 wg301_1 ///
         wg302_1 wg303_1 wg304_1 wg305_1 wg306_1 wg308_1 qf704_a_1 
	
	gen first=1
		label  var first "child order first=1 second=0"
		
	//统一变量名     可能需要安装命令  renvarlab
	
	renvarlab w????_1  , postdrop(2)
	renvarlab ?????_c1  , postdrop(3)
	rename tb1y_a_c1  
	tb1y_a
	
	save $working_data/temp_first.dta , replace
	
restore   
	//然后是第二个孩子

		keep year pid_a_c1  fincome1 tb1y_a_c1 tb2_a_c1 father_edu mother_edu ethnicity familysize urban ///
             fid10 fid12 fid18 fid16 fid14 wa105_1 wc2_2 wc201_2 wb201_2 wb501_2 wb601_1 wb701_1 wb801_1 ///
			 wc8015_1 wz301_1 wz302_1 wf602_1 wg301_1 wg302_1 wg303_1 wg304_1 wg305_1 wg306_1 wg308_1 qf704_a_1 
	
	gen first=0
		label  var first "child order first=1 second=0"
		
	//统一变量名     可能需要安装命令  renvarlab
	
	renvarlab w????_2  , postdrop(2)
	renvarlab ?????_c2  , postdrop(3)
	rename tb1y_a_c2   tb1y_a
	
	save $root/temp_second.dta , replace
	
	
	append using $root/temp_first.dta   //纵向合并
	
	tab first
	
	save $root/first_second, replace
	
//跑回归
	global Y  "wb501"   //这个变量之后可能要分段处理一下
	global X  "i.wg301 i.wg302 i.wg303 i.wg304 i.wg308"

	global control "i.first logincome i.father_edu i.mother_edu familysize urban"

	
	eststo r1: reg $Y i.wg301 $control
	eststo r2: reg $Y i.wg302 $control	
	eststo r3: reg $Y i.wg303 $control
	eststo r4: reg $Y i.wg304 $control
	 
	eststo r5: reg $Y i.wg301##i.first $control     
			//这个是交乘项，随便跑的，实际设定根据你研究的问题
	
	
	//结果导出
	
	
esttab r* using $root/result_example.csv ,b(3) se(3)  r2 scalars(F) ///
    title("Table 1. Baseline Regression: XXXXX ") /// 
	nomtitles collabels("walk age") modelwidth(7) nogaps nobaselevels ///
	order(?.wg30*) ///
	sfmt(0 0 0 3)  /// 
    interaction(" * ") addnote("Source: CFPS ") ///
    starlevels(* 0.1 ** 0.05 *** 0.01) ///
    replace
	
eststo clear



*******balanced panel******************
bys pid_a_c1: egen num = count(pid_a_c1)
tab num
keep if num == 5


****testing ***** 
gen xxx = 0     //若不存在, 则 x`i' = 0
replace xxx = 1 if pid_a_c1 != .  //若存在, 则 x`i' = 1
egen num1 = rowtotal(xxx)  //子女数量, childnumber = 0 表示没有子女
tab num1 year
******
gen xxy = 0     //若不存在, 则 x`i' = 0
replace xxy = 1 if pid_a_c2 != .  //若存在, 则 x`i' = 1
egen num2 = rowtotal(xxy)  //子女数量, childnumber = 0 表示没有子女
tab num2 year



