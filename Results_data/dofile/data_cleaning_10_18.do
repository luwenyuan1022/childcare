****************
Program:CFPS data cleaning 


**********************************
***Guideline of CFPS cleaning*****

**(1) clean up the variables required in the adult questionnaire year by year, and keep the personal identification code pid, family identification code fid, and the cleaned variables;
**(2) longitudinally combining the cleaned adult questionnaires from 2010 to 2018 to obtain individual-level panel data;
**(3) clean up the variables required in the household questionnaire year by year, keep the household code fid and get the variables after cleaning;
**(4) vertically merge the household questionnaires cleaned up from 2010 to 2018 to obtain household-level panel data;
**(5) horizontally append the household-level panel data and individual-level panel data according to the year and the household identification code fid to obtain the household-individual-level panel data from 2010 to 2018 required for the study.




************************ The cleaning of audit questionire **********************

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

log using "$logfiles/logfile12_18.log",text replace




************* create the variables in the crossyear adult questionire  ****** 

use  "$cfps2018/ecfps2018crossyearid_202104.dta", clear

des, replace
keep position name type varlab
list, noobs clean compress



*sreshape long后面添加需要转置的变量
*如果年份信息在变量最后，如fid10，则可以直接写fid
*如果年份信息在变量名中间，如co_a10_p，则用@代替年份信息
use  "$cfps2018/ecfps2018crossyearid_202104.dta", clear
reshape long fid inroster indsurvey selfrpt  co_a@_p         ///
        tb6_a@_p marriage_ cfps20@edu cfps20@sch cfps20@eduy ///
         cfps20@eduy_im urban hk employ  genetype@r           ///
         coremember  alive, i(pid) j(year)


*整理年份信息，新生成的年份是从变量中识别出来的
*变量中仅有10\12\14\16\18,
*因此需要以下步骤转换为2010\2012\2014\2016\2018
replace year=2000+year 


*Rename the variable (after reshape, the variable name become very strange)
rename * (pid year birthy gender ethnicity     ///
       entrayear fidbaseline psu            ///
	   subsample subpopulation fid          ///
       deceased death_year death_month      ///
       deathcause_code inroster indsurvey   ///
       selfrpt coeco_pid colive_pid         ///
       marriage edulevel sch eduyear        ///
       eduyear_im urban hk genetype14       ///
       genetype16 genetype18 releaseversion ///          
       employ genetype coremember alive)

***add label*************

label var   pid                "[personal ID]"
label var   year               "[year of survey]"
label var   birthy             "[year of birth]"
label var   gender             "[gender：male=1]"
label var   ethnicity          "[ethnic]"
label var   entrayear          "[the year first enter the CFPS survey]"
label var   deceased           "[whether die]"
label var   death_year         "[the year of death]"
label var   death_month        "[the month of death]"
label var   deathcause_code    "[the cause of death(code)]"
label var   fid                "[CFPS family id]"
label var   inroster           "[whether in the CFPS family relationship]"
label var   indsurvey          "[the type of personal data]"
label var   selfrpt            "[whether have self-report questionire]"
label var   coeco_pid          "[whether is the family member of pid economically ]"
label var   colive_pid         "[whether lives with pid]"
label var   marriage           "[marital status]"
label var   edulevel           "[person highest education level ]"
label var   sch                "[still in school/leave]"
label var   eduyear            "[year of education]"
label var   eduyear_im         "[year of education - adding information]"
label var   hk                 "[hukou]"
label var   employ             "[employment]"
label var   genetype           "[gentic member type]"
label var   coremember         "[whether core member]"
label var   alive              "[whether is alive]"
label var   fidbaseline        "[family_id baseline]"
label var   psu                "[family_id matching psu code]"
label var   subsample          "[whether baseline family id is in the subsample]"
label var   subpopulation      "[whether baseline family matching the subpopulation]"
label var   releaseversion     "[release version]"

save "$temp_data/ind2010-2018.dta", replace
tab  selfrpt


********* 此处完成跨年核心解释变量的清理 将作为后续append多年 using匹配家庭成员库的信息 *******



*** taking the variable from Childproxy （从少儿代答库提取变量，仅测试2018年的情况）

*use "$cfps2018/ecfps2018childproxy_202012.dta"
*keep fid10 fid12 fid14 fid16 fid18 pid countyid18 cid18 urban18 wb201 wb501 wb601 wb701 wb801 wc8015   ///
*wd4 wd402 wd501b wd503r wd5total_m wz301 wf602 wg301 wg302 wg303 wg304 wg305 wg306 wg308

*sum

*save "$temp_data/child2018.dta", replace

*************************************************************************************

**少儿家长代答库和个人库来匹配少儿代答与成人数据。具体思路如下：

*（1）将家庭成员库作为 master data，少儿代答库和个人库作为 using data；
*（2）用家庭成员库中每个孩子的样本编码与少儿代答库中的 pid 进行匹配（最关键）。若孩子 i 的样本编码能够与少儿代答库中的 pid 配对，则说明孩子 i 存在代答信息；
*（3）因为家庭成员库中设有 10 个孩子的样本编码，故需循环匹配 10 次。需要说明的是，在每次匹配后要删除 _merge=2 的样本，这主要是为了保证每次匹配时 master data 的样本量相同；
*（4）使用 pid 作为匹配变量，对个人库进行匹配（匹配第二次）
*（5）删除年龄小于 18 岁的个体，即得到成人与少儿代答相匹配的数据。


cd /Users/wenyuanlu/Desktop/stata/CFPS

use "$cfps2018/ecfps2018famconf_202008.dta", clear

des pid*

**** 首先，我们了解家庭关系库的结构： 一系列的pid* 是表示家庭关系的变量，需要与个人库，少儿代答库进行匹配

** 生成10个少儿代答库子集

forvalues i = 1(1)10{
  use "$cfps2018/ecfps2018childproxy_202012.dta", clear //导入少儿代答数据库
  keep fid* pid countyid18 cid18 urban18 wb201 wb501 wb601 wb701 wb801 wc8015   ///
wd4 wd402 wd501b wd503r wd5total_m wz301 wz302 wf602 wg301 wg302 wg303 wg304 wg305 wg306 wg308  //提取需要的变量      
  renvars _all, postfix(_`i')  //给所有的变量加后缀
  rename pid_`i' pid_a_c`i'    //变量重命名, 以保证匹配变量在 master 和 using 中一致（都是pid_a_c前缀)
 
  save child`i', replace        
   }


** 获得所有child信息的变量，做好第二轮匹配的准备

**然后，将家庭成员库作为 master data，少儿代答库作为 using data 进行匹配    

use "$cfps2018/ecfps2018famconf_202008.dta", clear ///导入家庭成员数据库

 forvalues i= 1(1)10{
   merge m:1 pid_a_c`i' using child`i' //因家庭成员库有父亲和母亲, 对应孩子编码有重复, 故使用多对一匹配
   drop if _merge == 2
   drop _merge
  }

merge 1:1 pid using $cfps2018/ecfps2018person_202012, force  //匹配个人库

***删除年龄小于18的个体，即得成人与少儿代答相匹配的数据
drop if age <18


**** 计算每个家庭的子女数量***
**子女数量：家庭成员库提供了个体对应的每个子女 (如果有子女) 的样本编码，如变量 pid_a_c1 表示第 1 个子女的样本编码。若该变量有对应的编码，则表示个体有第 1 个孩子，若该变量取值 -8 (不适用) 或 77，则表示个体没有第 1 个孩子。据此，可通过如下代码计算每个受访者的子女数量。

 
forvalues i = 1(1)10{   
gen xx`i' = 0 if pid_a_c`i' == -8 | pid_a_c`i' == 77      //若不存在, 则 x`i' = 0
replace xx`i' = 1 if pid_a_c`i' != -8 & pid_a_c`i' != 77  //若存在, 则 x`i' = 1
 }
egen childnumber = rowtotal(xx*)  //子女数量, childnumber = 0 表示没有子女
tab childnumber urban18 if childnumber < 7 & urban18 != -9 /// 查看子女数量的城乡差距



***********************2010年数据处理****************************************
clear 

forvalues i = 1(1)10{
  use "$cfps2010/ecfps2010child_201906.dta", clear //导入少儿代答数据库
  keep fid pid countyid cid urban wa105 wb201 wb501 wb601 wb701 wb801 wc2 wc201 wc4 wc801  ///
      wd4 wd501 wd503 wd5total wd501 wz301 wz302 wf602 wg301 wg302 wg303 wg304 wg305 wg306 wg308  
  renvars _all, postfix(_`i')  //给所有的变量加后缀
  rename pid_`i' pid_a_c`i'    //变量重命名, 以保证匹配变量在 master 和 using 中一致（都是pid_a_c前缀)
  save "$cfps2010/child`i'.dta", replace  
}

use "$cfps2010/ecfps2010famconf_202008.dta", clear //导入家庭成员数据库
forvalues i= 1(1)10{
  rename pid_c`i' pid_a_c`i' 	
  merge m:1 pid_a_c`i' using "$cfps2010/child`i'.dta" //因家庭成员库有父亲和母亲, 对应孩子编码有重复, 故使用多对一匹配
  drop if _merge == 2
  drop _merge
}

save "$cfps2010/merge1.dta", replace 

merge 1:1 pid using "$cfps2010/ecfps2010adult_202008.dta", force  //匹配个人库
drop if _merge == 2
drop _merge

save "$cfps2010/merge2_2010.dta", replace


***删除年龄小于18的个体，即得成人与少儿代答相匹配的数据
drop if  qa1age <18

save "$cfps2010/merge3_2010.dta", replace 


*** 匹配家庭经济问卷
use "$cfps2010/merge3_2010.dta", clear 
merge m:1 fid using "$cfps2010/ecfps2010famecon_202008.dta", force
drop if _merge == 2
drop _merge

save "$temp_data/family_2010_1.dta" , replace


*** 提取所需要的变量 *** 

keep faminc_net meduc qa5code feduc tb2_a_c* familysize urban fid* pid* urban wa105* wb201* wb501* wb601* wb701* wb801* wc2* wc201* wc4* ///
wc801* wd4* wd501* wd503* wd5total* wd501* wz301* wz302* wf602* wg301* wg302* wg303* wg304* wg305* wg306* wg308* tb1y_a_c* 

for var _all: replace X =. if inlist(X, -10, -9, -8, -2, -1)  ///去掉没有回答或者不适用的情况

save "$temp_data/family_2010_final.dta" , replace




*************************2012年处理 ******************************************************************************************

clear

forvalues i = 1(1)10{
  use "$cfps2012/ecfps2012child_201906.dta", clear //导入少儿代答数据库
  keep fid12 pid countyid cid urban12 wa105b wb201 wb501 wb601 wb701 wb801 wc2 wc201 wc4 wc801  ///
      wd4 wd501 wd503 wd5total wd501 wz301 wz302 wf602 wg301 wg302 wg303 wg304 wg305 wg306 wg308      
  renvars _all, postfix(_`i')  //给所有的变量加后缀
  rename pid_`i' pid_a_c`i'    //变量重命名, 以保证匹配变量在 master 和 using 中一致（都是pid_a_c前缀)
  save "$cfps2012/child`i'.dta", replace  
}

use "$cfps2012/ecfps2012famconf_092015.dta", clear //导入家庭成员数据库
forvalues i= 1(1)10{
  rename pid_c`i' pid_a_c`i' 	
  merge m:1 pid_a_c`i' using "$cfps2012/child`i'.dta" //因家庭成员库有父亲和母亲, 对应孩子编码有重复, 故使用多对一匹配
  drop if _merge == 2
  drop _merge
}

save "$cfps2012/merge1.dta", replace

gen year = 2012
duplicates tag pid year, gen(num)
tab num 

keep if num == 0
merge 1:1 pid using "$cfps2012/ecfps2012adult_201906.dta", force  //匹配个人库
drop if _merge == 2
drop _merge

save "$cfps2012/merge2.dta", replace


***删除年龄小于18的个体，即得成人与少儿代答相匹配的数据
drop if  tb1b_a_p <18

save "$cfps2012/merge3_2012.dta", replace


*** 匹配家庭经济问卷

merge m:1 fid12 using "$cfps2012/ecfps2012famecon_201906.dta", force
keep if _merge == 3
drop _merge

save "$temp_data/family_2012_1.dta" , replace


*** 提取所需要的变量 *** 
use "$temp_data/family_2012_1.dta"

keep fincome1  familysize tb4_a12_m tb4_a12_f tb1y_a_c* tb2_a_c* fid* pid* urban12 wa105* wb201* wb501* wb601* wb701* wb801* ///
wc2* wc201* wc4* wc801* wd4* wd501* wd503* wd5total* wd501* wz301* wz302* wf602* wg301* wg302* wg303* wg304* wg305* wg306* wg308* 

for var _all: replace X =. if inlist(X, -10, -9, -8, -2, -1)  ///去掉没有回答或者不适用的情况

save "$temp_data/family_2012_final.dta" , replace


******************************* 2014 ********************************************************

clear
forvalues i = 1(1)10{
  use "$cfps2014/ecfps2014child_201906.dta", clear //导入少儿代答数据库
  keep fid12 pid countyid cid urban14 wa105b wb201 wb501 wb601 wb701 wb801 wc4 wc801  ///
       wd4 wd501 wd503 wd5total wd501 wz301 wz302 wf602 wg301 wg302 wg303 wg304 wg305 wg306 wg308      
  renvars _all, postfix(_`i')  //给所有的变量加后缀
  rename pid_`i' pid_a_c`i'    //变量重命名, 以保证匹配变量在 master 和 using 中一致（都是pid_a_c前缀)
  save "$cfps2014/child`i'.dta", replace  
  }

use "$cfps2014/ecfps2014famconf_170630.dta", clear //导入家庭成员数据库
forvalues i= 1(1)10{
  rename pid_c`i' pid_a_c`i'    
  merge m:1 pid_a_c`i' using "$cfps2014/child`i'.dta" //因家庭成员库有父亲和母亲, 对应孩子编码有重复, 故使用多对一匹配
  drop if _merge == 2
  drop _merge
  }
save "$cfps2014/merge1.dta",replace


duplicates tag pid, gen(num)
keep if num == 0
merge 1:1 pid using "$cfps2014/ecfps2014adult_201906.dta", force  //匹配个人库
drop if _merge == 2
drop _merge


save "$cfps2014/merge2_2014.dta", replace

drop if  cfps2014_age <18 ///去掉非成年人的受访者

save "$cfps2014/merge3_2014.dta", replace

*********匹配家庭经济问卷***************************

merge m:1 fid14 using "$cfps2014/ecfps2014famecon_201906.dta", force
drop if _merge == 2
drop _merge
save "$temp_data/family_2014_1.dta" , replace

*****take the variables you need*********

keep fincome1 qa502ccode tb1y_a_c* tb4_a14_f tb4_a14_m familysize14 tb2_a_c* fid* pid* urban14 wa105* wb501* wb601* wb701* wb801* ///
      wc4* wc801* wd4* wd501* wd503* wd5total* wd501* wz301* wz302* wf602* wg301* wg302* wg303* wg304* wg305* wg306* wg308* tb2_a_c* 

for var _all: replace X =. if inlist(X, -10, -9, -8, -2, -1)  ///去掉没有回答或者不适用的情况

save "$temp_data/family_2014_final.dta" , replace



******************************** 2016 *************************************
clear 

forvalues i = 1(1)10{
  use "$cfps2016/ecfps2016child_201906.dta", clear //导入少儿代答数据库
  keep fid12 pid countyid cid urban16 wa105b wb201 wb501 wb601 wb701 wb801 wc4 wc801  ///
      wd4 wz301 wz302 wf602 wg301 wg302 wg303 wg304 wg305 wg306 wg308      
  renvars _all, postfix(_`i')  //给所有的变量加后缀
  rename pid_`i' pid_a_c`i'    //变量重命名, 以保证匹配变量在 master 和using 中一致（都是pid_a_c前缀)
  save "$cfps2016/child`i'.dta", replace  
  }

use "$cfps2016/ecfps2016famconf_201804.dta", clear //导入家庭成员数据库

forvalues i= 1(1)10{
  rename pid_c`i' pid_a_c`i'    
  merge m:1 pid_a_c`i' using "$cfps2016/child`i'.dta" //因家庭成员库有父亲和母亲, 对应孩子编码有重复, 故使用多对一匹配
  drop if _merge == 2
  drop _merge
 }
 
save "$cfps2016/merge1.dta", replace 

duplicates tag pid, gen(num)
keep if num == 0
merge 1:1 pid using "$cfps2016/ecfps2016adult_201906.dta", force  //匹配个人库
drop if _merge == 2
drop _merge

save "$cfps2016/merge2.dta", replace 

drop if  cfps_age <18 ///去掉非成年人的受访者

save "$cfps2016/merge3.dta", replace 

*****匹配家庭经济问卷2016***************************

merge m:1 fid16 using "$cfps2016/ecfps2016famecon_201807.dta", force
drop if _merge == 2
drop _merge
save "$temp_data/family_2016_1.dta" , replace



***********taking the variables you want *********************

keep fincome1 pa701code tb1y_a_c* tb4_a16_f tb4_a16_m familysize16 urban16 fid* pid* wa105* wb501* wb601* wb701* wb801*  wc4* ///
wc801* wd4*  wz301* wz302* wf602* wg301* wg302* wg303* wg304* wg305* wg306* wg308* qf704_a_1 tb2_a_c*

for var _all: replace X =. if inlist(X, -10, -9, -8, -2, -1)  ///去掉没有回答或者不适用的情况

save "$temp_data/family_2016_final.dta" , replace


*********************************2018 ***********************************************
clear
forvalues i = 1(1)10{
  use "$cfps2018/ecfps2018childproxy_202012.dta", clear //导入少儿代答数据库
  keep fid* pid countyid18 cid18 urban18 wa105b wb201 wb501 wb601 wb701 wb801 wc8015   ///
  wd4 wd402 wd501b wd503r wd5total_m wz301 wz302 wf602 wg301 wg302 wg303 wg304 wg305 wg306 wg308  //提取需要的变量      
  renvars _all, postfix(_`i')  //给所有的变量加后缀
  rename pid_`i' pid_a_c`i'    //变量重命名, 以保证匹配变量在 master 和 using 中一致（都是pid_a_c前缀)
  save "$cfps2018/child`i'.dta", replace        
 }

 
use "$cfps2018/ecfps2018famconf_202008.dta", clear ///导入家庭成员数据库 

forvalues i= 1(1)10{
  merge m:1 pid_a_c`i' using "$cfps2018/child`i'.dta" //因家庭成员库有父亲和母亲, 对应孩子编码有重复, 故使用多对一匹配
  drop if _merge == 2
  drop _merge
 }

save "$cfps2018/merge1.dta",replace

*duplicates tag pid, gen(num)
*keep if num == 0
merge 1:1 pid using "$cfps2018/ecfps2018person_202012.dta", force  //匹配个人库
drop if _merge == 2
drop _merge
save "$cfps2018/merge2.dta",replace


drop if age <18 ///去掉非成年人的受访者

save "$cfps2018/merge3.dta", replace 



**************匹配家庭经济问卷***************************


merge m:1 fid18 using "$cfps2018/ecfps2018famecon_202101.dta", force
drop if _merge == 2 
drop _merge
 
save "$temp_data/family_2018_1.dta" , replace

******提取所需要的变量 *** **********************************
use "$temp_data/family_2018_1.dta"

keep fincome1 tb1y_a_c* tb2_a_c* qa701code tb4_a18_f tb4_a18_m familysize18 urban18 fid* pid* wa105* wb201* wb501* wb601* wb701* ///
wb801* wc8015* wd4* wd402* wd501b* wd503r* wd5total_m* wz301* wz302* wf602* wg301* wg302* wg303* wg304* wg305* wg306* wg308* qf704_a_1

for var _all: replace X =. if inlist(X, -10, -9, -8, -2, -1)  ///去掉没有回答或者不适用的情况


save "$temp_data/family_2018_final.dta" , replace

******************adding year variable  and cleaning ***********************************************************************

use "$temp_data/family_2018_final.dta" 
gen year= 2018
rename (tb4_a18_f tb4_a18_m familysize18 urban18 qa701code) (father_edu mother_edu familysize urban ethnicity)


**** clean the duplicated first child and second child ********* 
/*duplicates tag pid_a_c1 year, gen(num1801)
keep if num1801 == 0

duplicates tag pid_a_c2 year, gen(num1802)
keep if num1801== 0 */

save "$temp_data/family_2018_final.dta" , replace 
clear

*********. 子女数量 number of children ********
forvalues i = 1(1)10{   
   gen xx`i' = 0     //若不存在, 则 x`i' = 0
   replace xx`i' = 1 if pid_a_c`i' != .  //若存在, 则 x`i' = 1
  }

egen childnumber = rowtotal(xx*)  //子女数量, childnumber = 0 表示没有子女
tab childnumber


**子女中男孩和女孩数量：家庭成员库提供了每个子女的性别，如变量 tb2_a_c1 表示个体的第 1 个孩子的性别，取值 1 表示第 1 个孩子是男孩，取值 0 表示第 1 个孩子是女孩。据此，我们可以根据该变量来计算男孩和女孩的数量

** 分性别计算子女数量
egen malechildnumber = anycount(tb2_a_c*), v(1)    //男孩数量
egen femalechildnumber = anycount(tb2_a_c*), v(0)  //女孩数量

tab malechildnumber 
tab femalechildnumber 

** 0-3 岁子女数量：主要根据出生年份和性别计算

forvalues i = 1(1)10{
replace tb1y_a_c`i' = . if tb1y_a_c`i' < 0                   //将出生年份小于 0 的值处理成缺失值
gen child0_3`i' = 1 if tb1y_a_c`i' >= 2015 & tb1y_a_c`i' !=.  //adult`i'=1 表示第 i 个子女的年龄大于 3 岁(晚于等于2015出生)
replace child0_3`i' = 0 if tb1y_a_c`i' < 2015 & tb1y_a_c`i' !=.  //adult`i'=0 表示第 i 个子女的年龄小于4岁（早于2015年出生）
}
egen childnumber_0_3 = anycount(child0_3*),v(0)  //0-3岁子女数量
tab childnumber_0_3
label var childnumber_0_3 "Number of children at age 0-3"


save "$temp_data/family_2018_final.dta", replace 

***************************
** 对2010-2016 每一年进行检查与合并

*** 16***

use "$temp_data/family_2016_final.dta" 
gen year= 2016
rename (tb4_a16_f tb4_a16_m familysize16 urban16 pa701code) (father_edu mother_edu familysize urban ethnicity)


save "$temp_data/family_2016_final.dta", replace
clear 

****14****
use "$temp_data/family_2014_final.dta" 
gen year= 2014
rename (tb4_a14_f tb4_a14_m familysize14 urban14) (father_edu mother_edu familysize urban)
save "$temp_data/family_2014_final.dta", replace 
clear 

****12****
use "$temp_data/family_2012_final.dta" 
gen year= 2012
rename (tb4_a12_f tb4_a12_m urban12) (father_edu mother_edu urban)
save "$temp_data/family_2012_final.dta", replace 
clear 


****10*****
use "$temp_data/family_2010_final.dta" 
gen year= 2010
rename (feduc meduc qa5code faminc_net) (father_edu mother_edu ethnicity fincome1)
save "$temp_data/family_2010_final.dta", replace
clear 


********** final append*****

use "$temp_data/family_2010_final.dta", clear 
append using "$temp_data/family_2012_final.dta"
append using "$temp_data/family_2014_final.dta"
append using "$temp_data/family_2016_final.dta"
append using "$temp_data/family_2018_final.dta"
order pid year

save "$temp_data/family_child_final_10_18.dta", replace 


tab year





