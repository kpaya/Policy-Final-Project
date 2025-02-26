/// This do file creates the tables from the conflict paper ///
*Author: Nicolas Gatti
*Stata Version 16
*Date: 02/05/2020
*E-mail: gatti3@illinois.edu
clear all
set more off
cap log close
set matsize 1500
/// Download the Conley Standard error ado files ///
*1) Download ols_spatial_HAC.ado from:
*https://www.dropbox.com/s/pf2vtvgqhjk7rc8/spatial_HAC.zip?dl=0&file_subpath=%2Fspatial_HAC%2Fols_spatial_HAC.ado
*2) Download reg2hdfespatial-id1id2.ado from: 
*http://www.trfetzer.com/wp-content/uploads/reg2hdfespatial-id1id2.ado
*3) Run the programs
run ols_spatial_HAC.ado, nostop
run reg2hdfespatial-id1id2.ado

*Open dataset
use data.dta, clear

*Create directory for results
mkdir conflict_paper
cd "conflict_paper"

*Start log file
log using conflict_paper.log, replace

*---------------------------------------------------------------Locals------------------------------------------------------------------------*
local rain1 z_rgrowing_season_cm
local temp1 z_tgrowing_season
local rain_o z_roff_season_cm
local temp_o z_toff_season
local irrigation c.z_ground_dams_ha#c.z_rgrowing_season_cm c.z_ground_dams_ha#c.z_tgrowing_season
local current c.z_irrigation_cont#c.z_rgrowing_season_cm c.z_irrigation_cont#c.z_tgrowing_season
local irrigation_off c.z_ground_dams_ha#c.z_roff_season_cm c.z_ground_dams_ha#c.z_toff_season
local inter_o c.z_irri_ha#c.z_roff_season_cm c.z_irri_ha#c.z_toff_season
local intere1 c.z_sum_elec_1997#c.z_rgrowing_season_cm c.z_sum_elec_1997#c.z_tgrowing_season

*controls by growing-season rainfall 
local controls1 c.z_rgrowing_season_cm#c.z_urban_avg c.z_rgrowing_season_cm#c.z_relig_herfindahl c.z_rgrowing_season_cm#c.z_lang_herfindahl  ///
c.z_rgrowing_season_cm#c.z_skilled_ag_avg c.z_rgrowing_season_cm#c.z_ag_labor_avg c.z_rgrowing_season_cm#c.z_ed_level_avg 					 ///
c.z_rgrowing_season_cm#c.z_literacy_avg c.z_rgrowing_season_cm#c.z_pop_density c.z_rgrowing_season_cm#c.z_floor1_avg 						 ///
c.z_rgrowing_season_cm#c.z_wall1_avg c.z_rgrowing_season_cm#c.z_roof1_avg c.z_slope1#c.z_rgrowing_season_cm 								 ///
c.z_slope2#c.z_rgrowing_season_cm c.z_slope3#c.z_rgrowing_season_cm c.z_slope4#c.z_rgrowing_season_cm c.z_slope5#c.z_rgrowing_season_cm	
	
*controls by year FE
local controls2 i.year#c.z_urban_avg i.year#c.z_relig_herfindahl i.year#c.z_lang_herfindahl i.year#c.z_skilled_ag_avg 						 ///
i.year#c.z_ag_labor_avg i.year#c.z_ed_level_avg i.year#c.z_literacy_avg i.year#c.z_pop_density i.year#c.z_floor1_avg i.year#c.z_wall1_avg 	 ///
i.year#c.z_roof1_avg c.z_slope1#i.year c.z_slope2#i.year c.z_slope3#i.year c.z_slope4#i.year c.z_slope5#i.year

*controls by off-season rainfall
local controls_off c.z_roff_season_cm#c.z_urban_avg c.z_roff_season_cm#c.z_relig_herfindahl c.z_roff_season_cm#c.z_lang_herfindahl  		 ///
c.z_roff_season_cm#c.z_skilled_ag_avg c.z_roff_season_cm#c.z_ag_labor_avg c.z_roff_season_cm#c.z_ed_level_avg 								 ///
c.z_roff_season_cm#c.z_literacy_avg c.z_roff_season_cm#c.z_pop_density c.z_roff_season_cm#c.z_floor1_avg c.z_roff_season_cm#c.z_wall1_avg 	 ///
c.z_roff_season_cm#c.z_roof1_avg c.z_slope1#c.z_roff_season_cm c.z_slope2#c.z_roff_season_cm c.z_slope3#c.z_roff_season_cm 					 ///
c.z_slope4#c.z_roff_season_cm c.z_slope5#c.z_roff_season_cm 

*------------------------------------------------------------TABLES--------------------------------------------------------------------------*

*Set Panel Data
sort district_code year
xtset district_code year

*TABLE 1: Summary Statistics
tabstat total_rainfall rgrowing_season_cm roff_season_cm total_area total_prod  					///
ground_dams_ha conflict resource pop_justice law_enf gov_prog separatist identity 				    ///
urban_avg relig_herfindahl lang_herfindahl skilled_ag_avg 									  	    ///
ag_labor_avg ed_level_avg literacy_avg pop_density floor1_avg wall1_avg 						    ///
roof1_avg, col(stat) stat(mean sd)

matrix table1 = J(23,2,.)

local j = 0 
foreach var1 in total_rainfall rgrowing_season_cm roff_season_cm total_area total_prod  							///
				ground_dams_ha conflict resource pop_justice law_enf gov_prog separatist identity 				    ///
				urban_avg relig_herfindahl lang_herfindahl ag_labor_avg skilled_ag_avg 						  	    ///
				ed_level_avg literacy_avg floor1_avg wall1_avg roof1_avg 	{
					local ++j
					sum `var1'
					scalar `var1'_mean = r(mean)
					scalar `var1'_sd = r(sd)
					matrix table1[`j',1] = scalar(`var1'_mean)
					matrix table1[`j',2] = scalar(`var1'_sd)
					}

matrix rownames table1 = total_rainfall rgrowing_season_cm roff_season_cm total_area total_prod  					///
				ground_dams_ha conflict resource pop_justice law_enf gov_prog separatist identity 				    ///
				urban_avg relig_herfindahl lang_herfindahl skilled_ag_avg 									  	    ///
				ag_labor_avg ed_level_avg literacy_avg floor1_avg wall1_avg roof1_avg
matrix colnames table1 = Mean Sd

matrix list table1
putexcel set "table1.xlsx",  sheet("table1") replace
putexcel A1=(" ") A2=("Annual rainfall (100 mm)") A3=("Growing-season rainfall (100 mm)") A4=("Off-season rainfall (100 mm)") 		   ///
A5=("Rice area (hectares)") A6=("Rice production (tons)") A7=("Irrigation capacity in 1997 (% of total district ha)") 				   ///
A8=("Total incidents") A9=("Resource incidents") A10=("Popular justice incidents") A11=("Law Enforcement incidents")				   ///
A12=("Government policy incidents") A13=("Separatist incidents") A14=("Group identity incidents")								   	   ///
A15=("Urban Households (% of total in the district)") A16=("Religion HHI (0 to 10,000)")   										       ///
A17=("Language HHI (0 to 10,000)") A18=("Agricultural Labor Force (% of total in the district)") 									   ///
A19=("Skilled Agriculture (% of agricultural in the district)") A20=("Average education level (by HH in the district)") 			   ///
A21=("UIlliterate Households (% of total in the district)") A22=("Cane/wood wall (% of total in the district)")   					   ///
A23=("No floor (% of total in the district)") A24=("Wood/grass roof (% of total in the district)") 
putexcel B1=("Mean") C1=("Standard deviation")
putexcel B2=matrix(table1), sheet("table1")
putexcel (B2:C24)=shrinkfit("on") (B2:C24)=nformat("number_d2") (A2:A24)=nformat("text") (A1:C1)=border("bottom", "thin") 			   ///
(A24:C24)=border("bottom", "thin") (B1:C24)=halign("center")
putexcel A7=nformat("percent_d2") (A18:A19)=nformat("percent_d2") (A21:A24)=nformat("percent_d2")

*TABLE 2: The effect of growing-season rainfall and irrigation capacity on rice production
xtreg ihs_total_prod `rain1' `temp1' `irrigation' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table2, word excel replace keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg ihs_total_prod `rain1' `temp1' `irrigation' i.year i.district_code#c.year, fe vce(cluster district_code)
outreg2 using table2, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg ihs_total_prod `rain1' `temp1' `current' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table2, word excel append keep(z_rgrowing_season_cm c.z_irrigation_cont#c.z_rgrowing_season_cm) nocons

*TABLE 3: The effect of growing-season rainfall and irrigation capacity on conflict
xtreg conflict `rain1' `temp1' `irrigation' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table3, word excel replace keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' i.year i.district_code#c.year, fe vce(cluster district_code)
outreg2 using table3, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `current' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table3, word excel append keep(z_rgrowing_season_cm c.z_irrigation_cont#c.z_rgrowing_season_cm) nocons
xtreg conflict ihs_total_prod i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table3, word excel append keep(ihs_total_prod) nocons

*TABLE 4. Impact of growing-season rainfall by subcategories of conflict.
foreach var in resource pop_justice law_enf gov_prog separatist identity {
xtreg `var' `rain1' `temp1' `irrigation' i.year c.year#i.prov i.prov#c.year, fe vce(cluster district_code)
outreg2 using table4, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
} 

*Table 5. Positive versus negative growing-season rainfall shocks on rice production and conflict
xtreg ihs_total_prod posrain negrain c.posrain#c.z_ground_dams_ha c.negrain#c.z_ground_dams_ha 			///
	   tgrowing_season c.tgrowing_season#c.z_ground_dams_ha i.year i.prov#c.year i.island_code#i.year  	///
			   , fe vce(cluster district_code)
outreg2 using table5, word excel replace keep(posrain negrain c.posrain#c.z_ground_dams_ha c.negrain#c.z_ground_dams_ha) nocons
			   
xtreg conflict posrain negrain c.posrain#c.z_ground_dams_ha c.negrain#c.z_ground_dams_ha 				///
	   tgrowing_season c.tgrowing_season#c.z_ground_dams_ha i.year i.prov#c.year i.island_code#i.year   ///
			   , fe vce(cluster district_code)
outreg2 using table5, word excel append keep(posrain negrain c.posrain#c.z_ground_dams_ha c.negrain#c.z_ground_dams_ha) nocons


*TABLE 6. Controls and rainfall interactions
xtreg conflict `rain1' `temp1' `irrigation' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table6, word excel replace keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `controls1'  i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table6, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `controls1'  i.year i.island_2#c.z_rgrowing_season_cm i.prov#c.year, fe vce(cluster district_code)
outreg2 using table6, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `controls1'  i.year i.island_code#c.z_rgrowing_season_cm i.prov#c.year, fe vce(cluster district_code)
outreg2 using table6, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons


*TABLE 7. Controls and year FE interactions
xtreg conflict `rain1' `temp1' `irrigation' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table7, word excel replace keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `controls2' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table7, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `controls2' i.year i.island_2#i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table7, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `controls2' i.year i.island_code#i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table7, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons

*Table 8. Impact of growing-season rainfall on conflict in rural versus urban areas
xtreg conflict `rain1' `temp1' i.year i.prov#c.year if agric_per_capita >=  4.691448, fe vce(cluster district_code)
outreg2 using table8, word excel replace keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' i.year i.prov#c.year if agric_per_capita <  4.691448, fe vce(cluster district_code)
outreg2 using table8, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' i.year i.prov#c.year if agric_per_capita >=  4.691448, fe vce(cluster district_code)
outreg2 using table8, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' i.year i.prov#c.year if agric_per_capita <  4.691448, fe vce(cluster district_code)
outreg2 using table8, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons

*TABLE 9. growing season/out of season - dam irrigation/ dam electricity on conflict
xtreg conflict `rain1' `temp1' `rain_o' `temp_o' `irrigation' `irrigation_off' `controls1' `controls_off' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table9, word excel replace keep(z_rgrowing_season_cm z_roff_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm c.z_ground_dams_ha#c.z_roff_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `intere1' `controls1' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using table9, word excel append keep(z_rgrowing_season_cm z_roff_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm c.z_sum_elec_1997#c.z_rgrowing_season_cm) nocons

*TABLE 10. Property rights tests
xtreg conflict `rain1' `temp1' `irrigation' `controls1'  c.z_owner_avg#c.z_rgrowing_season_cm i.prov#c.year i.year, fe vce(cluster district_code)
outreg2 using table10, word excel replace keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm c.z_owner_avg#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `controls1' i.prov#c.year i.year if owner_avg < .8958687, fe vce(cluster district_code)
outreg2 using table10, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg conflict `rain1' `temp1' `irrigation' `controls1' i.prov#c.year i.year if owner_avg >= .8958687, fe vce(cluster district_code)
outreg2 using table10, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons

*--------------------------------------------------APPENDIX TABLES----------------------------------------------------------*

*TABLE A1. Total irrigation hectares, per rice area and rice+corn area 
xtreg conflict z_rgrowing_season_cm z_tgrowing_season c.z_irri_capita#c.z_rgrowing_season_cm c.z_irri_capita#c.z_tgrowing_season i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using a2, word excel replace keep(z_rgrowing_season_cm c.z_irri_capita#c.z_rgrowing_season_cm) nocons
xtreg conflict z_rgrowing_season_cm z_tgrowing_season c.z_irri_rice#c.z_rgrowing_season_cm c.z_irri_rice#c.z_tgrowing_season i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using a2, word excel append keep(z_rgrowing_season_cm c.z_irri_rice#c.z_rgrowing_season_cm) nocons
xtreg conflict z_rgrowing_season_cm z_tgrowing_season c.z_irri_corn_rice#c.z_rgrowing_season_cm c.z_irri_corn_rice#c.z_tgrowing_season i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using a2, word excel append keep(z_rgrowing_season_cm c.z_irri_corn_rice#c.z_rgrowing_season_cm) nocons

*TABLE A2. Regressions of irrigation capacity on surface irrigation
xtreg lirrigation lground_dams, vce(cluster district_code)
outreg2 using a1, word excel replace
xtreg ln_irrigation ln_ground_dams, vce(cluster district_code)
outreg2 using a1, word excel append


*TABLE A3. Conflict factor analysis
factor resource pop_justice law_enf gov_prog identity separatist
matrix loadings = e(L)
matrix eigen1 = e(Ev)
matrix eigen3 = eigen1[1,1..3]
matrix chi2 = e(chi2_i)
matrix chi_p = e(p_i)

putexcel set "a3.xlsx",  sheet("a3") replace
putexcel A1=("Conflict type") A2=("Resource incidents") A3=("Popular justice incidents") A4=("Law Enforcement incidents")			   ///
A5=("Government policy incidents") A6=("Group identity incidents") A7=("Separatist incidents") 									   	   ///
A8=("Eigenvalues") A9=("Lr Test:")   										       ///
A10=("Chi-squared") A11=("Prob>chi2") 									   
putexcel B1=("1") C1=("2") D1=("3")
putexcel B2=matrix(loadings) B8=matrix(eigen3) C9=("Independent vs. Saturated") C10=matrix(chi2) C11=matrix(chi_p), sheet("a3")
putexcel (B2:D11)=nformat("number_d2") (A1:D1)=border("bottom", "thin") ///
(A11:D11)=border("bottom", "thin") (B1:D11)=halign("center")


*TABLE A4. Heterogeneity in factors
foreach var in f1 f2 {
xtreg `var' `rain1' `temp1' `irrigation' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using a4, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
} 

*TABLE A5. Rainfall shocks by terciles on rice production and conflict 
xtreg ihs_total_prod tercile1 tercile3 c.tercile1#c.z_ground_dams_ha c.tercile3#c.z_ground_dams_ha 										///
z_tgrowing_season c.z_tgrowing_season#c.z_ground_dams_ha i.year c.year#i.prov i.island_code#i.year   									///
, fe vce(cluster district_code)
outreg2 using terciles, word excel replace keep(tercile1 tercile3 c.tercile1#c.z_ground_dams_ha c.tercile3#c.z_ground_dams_ha) nocons
			   
xtreg conflict tercile1 tercile3 c.tercile1#c.z_ground_dams_ha c.tercile3#c.z_ground_dams_ha     										///
z_tgrowing_season c.z_tgrowing_season#c.z_ground_dams_ha i.year c.year#i.prov i.island_code#i.year   									///
, fe vce(cluster district_code)
outreg2 using terciles, word excel append keep(tercile1 tercile3 c.tercile1#c.z_ground_dams_ha c.tercile3#c.z_ground_dams_ha) nocons


*TABLE A6. Growing-season rainfall and irrigation capacity on rice production: Conley Standard Errors
reg2hdfespatial ihs_total_prod z_rgrowing_season_cm z_tgrowing_season z_rain_ground_dams_ha z_temp_ground_dams_ha    					///
prov_code1_year prov_code2_year prov_code3_year prov_code4_year prov_code5_year prov_code6_year prov_code7_year 						///
prov_code8_year prov_code9_year prov_code10_year prov_code11_year prov_code12_year prov_code13_year prov_code14_year 					///
prov_code15_year prov_code16_year prov_code17_year prov_code18_year prov_code19_year prov_code20_year prov_code21_year 					///
prov_code22_year prov_code23_year prov_code24_year ///
, timevar(year) panelvar(district_code) lat(y_stub) lon(x_stub) distcutoff(50) lagcutoff(200)
outreg2 using a5, word excel replace keep(z_rgrowing_season_cm z_rain_ground_dams_ha) nocons

reg2hdfespatial ihs_total_prod z_rgrowing_season_cm z_tgrowing_season z_rain_ground_dams_ha z_temp_ground_dams_ha    					///
prov_code1_year prov_code2_year prov_code3_year prov_code4_year prov_code5_year prov_code6_year prov_code7_year 						///
prov_code8_year prov_code9_year prov_code10_year prov_code11_year prov_code12_year prov_code13_year prov_code14_year				  	///
prov_code15_year prov_code16_year prov_code17_year prov_code18_year prov_code19_year prov_code20_year prov_code21_year 					///
prov_code22_year prov_code23_year  ///
, timevar(year) panelvar(district_code) lat(y_stub) lon(x_stub) distcutoff(100) lagcutoff(200)
outreg2 using a5, word excel append keep(z_rgrowing_season_cm z_rain_ground_dams_ha) nocons

reg2hdfespatial ihs_total_prod z_rgrowing_season_cm z_tgrowing_season z_rain_ground_dams_ha z_temp_ground_dams_ha   					///
prov_code1_year prov_code2_year prov_code3_year prov_code4_year prov_code5_year prov_code6_year prov_code7_year 						///
prov_code8_year prov_code9_year prov_code10_year prov_code11_year prov_code12_year prov_code13_year prov_code14_year 					///
prov_code15_year prov_code16_year prov_code17_year prov_code18_year prov_code19_year prov_code20_year prov_code21_year 					///
prov_code22_year prov_code23_year prov_code24_year ///
, timevar(year) panelvar(district_code) lat(y_stub) lon(x_stub) distcutoff(100) lagcutoff(300)
outreg2 using a5, word excel append keep(z_rgrowing_season_cm z_rain_ground_dams_ha) nocons

*Cluster by province
xtreg ihs_total_prod `rain1' `temp1' `irrigation' i.year i.prov#c.year, fe vce(cluster prov)
outreg2 using a5, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons

*TABLE A7. Growing-season rainfall and Irrigation capacity on conflict: Conley Standard Errors
reg2hdfespatial conflict z_rgrowing_season_cm z_tgrowing_season z_rain_ground_dams_ha z_temp_ground_dams_ha    							///
prov_code1_year prov_code2_year prov_code3_year prov_code4_year prov_code5_year prov_code6_year prov_code7_year 						///
prov_code8_year prov_code9_year prov_code10_year prov_code11_year prov_code12_year prov_code13_year prov_code14_year 					///
prov_code15_year prov_code16_year prov_code17_year prov_code18_year prov_code19_year prov_code20_year prov_code21_year 					///
prov_code22_year prov_code23_year prov_code24_year ///
, timevar(year) panelvar(district_code) lat(y_stub) lon(x_stub) distcutoff(50) lagcutoff(200) 
outreg2 using a6, word excel replace keep(z_rgrowing_season_cm z_rain_ground_dams_ha) nocons

reg2hdfespatial conflict z_rgrowing_season_cm z_tgrowing_season z_rain_ground_dams_ha z_temp_ground_dams_ha    							///
prov_code1_year prov_code2_year prov_code3_year prov_code4_year prov_code5_year prov_code6_year prov_code7_year 						///
prov_code8_year prov_code9_year prov_code10_year prov_code11_year prov_code12_year prov_code13_year prov_code14_year 					///
prov_code15_year prov_code16_year prov_code17_year prov_code18_year prov_code19_year prov_code20_year prov_code21_year 					///
prov_code22_year prov_code23_year prov_code24_year ///
, timevar(year) panelvar(district_code) lat(y_stub) lon(x_stub) distcutoff(100) lagcutoff(200)
outreg2 using a6, word excel append keep(z_rgrowing_season_cm z_rain_ground_dams_ha) nocons

reg2hdfespatial conflict z_rgrowing_season_cm z_tgrowing_season z_rain_ground_dams_ha z_temp_ground_dams_ha    							///
prov_code1_year prov_code2_year prov_code3_year prov_code4_year prov_code5_year prov_code6_year prov_code7_year 						///
prov_code8_year prov_code9_year prov_code10_year prov_code11_year prov_code12_year prov_code13_year prov_code14_year 					///
prov_code15_year prov_code16_year prov_code17_year prov_code18_year prov_code19_year prov_code20_year prov_code21_year 					///
prov_code22_year prov_code23_year prov_code24_year ///
, timevar(year) panelvar(district_code) lat(y_stub) lon(x_stub) distcutoff(100) lagcutoff(300)
outreg2 using a6, word excel append keep(z_rgrowing_season_cm z_rain_ground_dams_ha) nocons

*Cluster by province
xtreg conflict `rain1' `temp1' `irrigation' i.year i.prov#c.year, fe vce(cluster prov)
outreg2 using a6, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons


*TABLE A8. Regressions between baseline irrigation and baseline characteristics
foreach var in ground_dams sum_1997 ground_1997 sum_elec_1997 {
reg `var'  conflict_mean urban_avg relig_herfindahl lang_herfindahl 			 							///
		   skilled_ag_avg ag_labor_avg ed_level_avg literacy_avg pop_density 								///
		   floor1_avg wall1_avg roof1_avg slope1 slope2 slope3 slope4 slope5								///
		   , vce(cluster district_code)
outreg2 using a7, word excel append
}

*TABLE A9: The effect of growing-season rainfall and irrigation capacity on ln(rice production)
xtreg lprod `rain1' `temp1' `irrigation' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using a8, word excel replace keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg lprod `rain1' `temp1' `irrigation' i.year i.district_code#c.year, fe vce(cluster district_code)
outreg2 using a8, word excel append keep(z_rgrowing_season_cm c.z_ground_dams_ha#c.z_rgrowing_season_cm) nocons
xtreg lprod `rain1' `temp1' `current' i.year i.prov#c.year, fe vce(cluster district_code)
outreg2 using a8, word excel append keep(z_rgrowing_season_cm c.z_irrigation_cont#c.z_rgrowing_season_cm) nocons


*Table A10. IV regressions
ivregress 2sls ihs_total_prod `rain1' `temp1' (z_rain_irrigation_cont = z_rain_ground_dams_ha z_temp_ground_dams_ha) z_temp_irrigation_cont i.year i.district_code i.prov#c.year, vce(cluster district_code)
outreg2 using a9, word excel replace keep(z_rgrowing_season_cm z_rain_irrigation_cont) nocons
ivregress 2sls conflict `rain1' `temp1' (z_rain_irrigation_cont = z_rain_ground_dams_ha z_temp_ground_dams_ha) z_temp_irrigation_cont i.year i.district_code i.prov#c.year, vce(cluster district_code)
outreg2 using a9, word excel append keep(z_rgrowing_season_cm z_rain_irrigation_cont) nocons
reg z_rain_irrigation_cont z_rain_ground_dams_ha z_temp_ground_dams_ha i.year i.district_code i.prov#c.year, vce(cluster district_code)
outreg2 using a9, word excel append keep(z_rgrowing_season_cm z_rain_ground_dams_ha) nocons


log close 
exit
