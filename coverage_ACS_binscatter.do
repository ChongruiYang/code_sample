* 2/9/2022
* Chongrui, Ziwen
* to draw the coverage bin with the ACS data

clear all
set more off
set scheme s1color
capture log close

prog drop _all

prog config
  **Setup directory:
  dropbox  
  global dir "`r(db)'Amenity"

  **generate log.file:
  cd "$dir"
  cap mkdir "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles"
  log using "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles/coverage_bin.log", replace

  **Setup the number of cores that will be used.
  *set processors 10

  **Setup parameter:

end
config



import delimited ".\data\analysis\veraset_gravy_gps_sample\veraset_home_acs_2015_2019.csv", clear 
drop if census_block_group == "nan"
*winsor2 coverage_1 coverage_3 coverage_5 coverage_10, cut(1 99) replace 
gen lnpop = log(population)
gen lninc_med = log(income_household_median)
gen lninc_per_cap = log(income_per_capita)
gen lnhous_med = log(house_value_median)

prog census_block_level_aggregate
* gen a group level coverage
bys census_block_group: egen coverage_1_cen = mean(coverage_1)
bys census_block_group: egen coverage_3_cen = mean(coverage_3)
bys census_block_group: egen coverage_5_cen = mean(coverage_5)
bys census_block_group: egen coverage_10_cen = mean(coverage_10)
unique census_block_group
bys census_block_group: egen home_device_num = count(caid)
*select the first one
bys census_block_group : gen tag_blcgrp = 1 if _n == 1 
*gen density of pop(person/KM^2)
gen pop_density = population/(aland10/1000000)
gen lndensity = log(pop_density)

bys census_block_group: egen coverage_1_cen_med = median(coverage_1)
bys census_block_group: egen coverage_3_cen_med = median(coverage_3)
bys census_block_group: egen coverage_5_cen_med = median(coverage_5)
bys census_block_group: egen coverage_10_cen_med = median(coverage_10)

end
census_block_level_aggregate

**# Bookmark #11
foreach i in 1 3 5 10{
    gen lncoverage_`i'_cen = log(coverage_`i'_cen)
}
foreach i in 1 3 5 10{
    gen lncoverage_`i'_cen_med = log(coverage_`i'_cen_med)
}


** do the winsor for all the indicators
winsor2 coverage_1_cen_med coverage_3_cen_med coverage_5_cen_med coverage_10_cen_med coverage_1_cen coverage_3_cen coverage_5_cen coverage_10_cen lncoverage_1_cen lncoverage_3_cen lncoverage_5_cen lncoverage_10_cen lncoverage_1_cen_med lncoverage_3_cen_med lncoverage_5_cen_med lncoverage_10_cen_med pop_density age_median income_household_median poverty_share_indivi house_value_median poverty_share_household income_per_capita bachelors_share white_share unemploy_rate lnpop lninc_med lninc_per_cap lnhous_med, trim cut(1 99) replace 

preserve
foreach i in 1 3 5 10{

keep if tag_blcgrp == 1
qui sum coverage_`i'_cen_med, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_`i'_cen_med, ///
          xtitle("coverage distribution med") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue%20) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_`i'_cen_med_dis.pdf", replace  

}
restore

preserve
foreach i in 1 3 5 10{

keep if tag_blcgrp == 1
qui sum lncoverage_`i'_cen_med, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram lncoverage_`i'_cen_med, ///
          xtitle("ln(coverage) distribution med") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_`i'_cen_med_dis.pdf", replace  

}
restore

prog dist
preserve
keep if tag_blcgrp == 1

qui sum pop_density, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram pop_density, ///
          xtitle("pop_density distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/pop_density_dis.pdf", replace 

qui sum age_median, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram age_median, ///
          xtitle("age_median distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/age_median_dis.pdf", replace   

qui sum income_household_median, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram income_household_median, ///
          xtitle("income_household_median distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/income_household_median_dis.pdf", replace  
  
qui sum poverty_share_indivi, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram poverty_share_indivi, ///
          xtitle("poverty_share_indivi distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/poverty_share_indivi_dis.pdf", replace 
  
qui sum house_value_median, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram house_value_median, ///
          xtitle("house_value_median distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/house_value_median_dis.pdf", replace
  
 qui sum poverty_share_household, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram poverty_share_household, ///
          xtitle("poverty_share_household distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/poverty_share_household_dis.pdf", replace 
  
 qui sum income_per_capita, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram income_per_capita, ///
          xtitle("income_per_capita distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/income_per_capita_dis.pdf", replace 
  
qui sum bachelors_share, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram bachelors_share, ///
          xtitle("bachelors_share distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/bachelors_share_dis.pdf", replace   


qui sum white_share, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram white_share, ///
          xtitle("white_share distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/white_share_dis.pdf", replace  
  
qui sum unemploy_rate, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram unemploy_rate, ///
          xtitle("unemploy_rate distribution") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(blue40%) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/unemploy_rate_dis.pdf", replace      
restore

end
dist




prog validation of device

preserve
 keep if tag_blcgrp == 1
  qui reg pop_density home_device_num, r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[home_device_num]
  local se = _se[home_device_num]
  local t = _b[home_device_num]/_se[home_device_num]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter pop_density home_device_num, n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/pop_density_to_home_device.pdf", replace  
restore



end
validation of device

prog pop_dens
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_pop_density.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_pop_density_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_lndensity.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_lndensity.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_lndensity.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_lndensity.pdf", replace  
restore
end
pop_dens

prog income_household_median
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_income_household_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_income_household_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_lninc_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_lninc_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_lninc_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_lninc_med.pdf", replace  
restore
end
income_household_median

prog income_per_capita
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_income_per_capita.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_income_per_capita_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_lninc_per_cap.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_lninc_per_cap.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_lninc_per_cap.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_lninc_per_cap.pdf", replace  
restore
end
income_per_capita

prog bachelors_share
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_bachelors_share.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_bachelors_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_bachelors_share_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_bachelors_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_bachelors_share_med.pdf", replace  
restore
end
bachelors_share

prog age_median
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_age_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_age_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_age_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_age_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_age_median_med.pdf", replace  
restore
end
age_median

prog house_value_median
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_house_value_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_house_value_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_lnhous_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_lnhous_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_lnhous_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_lnhous_med.pdf", replace  
restore
end
house_value_median

prog white_share
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_white_share.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_white_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_white_share_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_white_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_white_share_med.pdf", replace  
restore
end
white_share

prog unemploy_rate
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_unemploy_rate.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_unemploy_rate_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_unemploy_rate_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_unemploy_rate_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_unemploy_rate_med.pdf", replace  
restore
end
unemploy_rate

prog poverty_share_household
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_poverty_share_household.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_poverty_share_household_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_poverty_share_household_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_poverty_share_household_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_poverty_share_household_med.pdf", replace  
restore
end
poverty_share_household

prog poverty_share_indivi
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_poverty_share_indivi.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_poverty_share_indivi_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_poverty_share_indivi_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_poverty_share_indivi_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_poverty_share_indivi_med.pdf", replace  
restore
end
poverty_share_indivi


*** plot the coverage median in CBG level
prog pop_dens_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_pop_density.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_pop_density_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_lndensity.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_lndensity.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_lndensity.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_lndensity.pdf", replace  
restore
end
pop_dens_1

prog income_household_median_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_income_household_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_income_household_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_lninc_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_lninc_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_lninc_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_lninc_med.pdf", replace  
restore
end
income_household_median_1

prog income_per_capita_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_income_per_capita.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_income_per_capita_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_lninc_per_cap.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_lninc_per_cap.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_lninc_per_cap.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_lninc_per_cap.pdf", replace  
restore
end
income_per_capita_1

prog bachelors_share_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_bachelors_share.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_bachelors_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_bachelors_share_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_bachelors_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_bachelors_share_med.pdf", replace  
restore
end
bachelors_share_1

prog age_median_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_age_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_age_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_age_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_age_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_age_median_med.pdf", replace  
restore
end
age_median_1

prog house_value_median_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_house_value_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_house_value_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_lnhous_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_lnhous_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_lnhous_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_lnhous_med.pdf", replace  
restore
end
house_value_median_1

prog white_share_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_white_share.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_white_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_white_share_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_white_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_white_share_med.pdf", replace  
restore
end
white_share_1

prog unemploy_rate_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_unemploy_rate.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_unemploy_rate_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_unemploy_rate_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_unemploy_rate_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_unemploy_rate_med.pdf", replace  
restore
end
unemploy_rate_1

prog poverty_share_household_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_poverty_share_household.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_poverty_share_household_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_poverty_share_household_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_poverty_share_household_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_poverty_share_household_med.pdf", replace  
restore
end
poverty_share_household_1

prog poverty_share_indivi_1
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_poverty_share_indivi.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_1_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_1_cen_med poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_1_cen_med_poverty_share_indivi_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_3_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_3_cen_med poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_3_cen_med_poverty_share_indivi_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg coverage_5_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_5_cen_med poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_5_cen_med_poverty_share_indivi_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg coverage_10_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_cen_med poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_10_cen_med_poverty_share_indivi_med.pdf", replace  
restore
end
poverty_share_indivi_1

***plot the lncoverage med
prog pop_dens_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_pop_density.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_pop_density_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_lndensity.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_lndensity.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_lndensity.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_lndensity.pdf", replace  
restore
end
pop_dens_2

prog income_household_median_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_income_household_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_income_household_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_lninc_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_lninc_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_lninc_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_lninc_med.pdf", replace  
restore
end
income_household_median_2

prog income_per_capita_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_income_per_capita.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_income_per_capita_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_lninc_per_cap.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_lninc_per_cap.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_lninc_per_cap.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_lninc_per_cap.pdf", replace  
restore
end
income_per_capita_2

prog bachelors_share_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_bachelors_share.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_bachelors_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_bachelors_share_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_bachelors_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_bachelors_share_med.pdf", replace  
restore
end
bachelors_share_2

prog age_median_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_age_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_age_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_age_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_age_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_age_median_med.pdf", replace  
restore
end
age_median_2

prog house_value_median_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_house_value_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_house_value_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_lnhous_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_lnhous_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_lnhous_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_lnhous_med.pdf", replace  
restore
end
house_value_median_2

prog white_share_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_white_share.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_white_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_white_share_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_white_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_white_share_med.pdf", replace  
restore
end
white_share_2

prog unemploy_rate_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_unemploy_rate.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_unemploy_rate_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_unemploy_rate_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_unemploy_rate_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_unemploy_rate_med.pdf", replace  
restore
end
unemploy_rate_2

prog poverty_share_household_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_poverty_share_household.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_poverty_share_household_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_poverty_share_household_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_poverty_share_household_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_poverty_share_household_med.pdf", replace  
restore
end
poverty_share_household_2

prog poverty_share_indivi_2
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_poverty_share_indivi.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen_med poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_med_poverty_share_indivi_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen_med poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_med_poverty_share_indivi_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen_med poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_med_poverty_share_indivi_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen_med poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen_med poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_med_poverty_share_indivi_med.pdf", replace  
restore
end
poverty_share_indivi_2

***plot the lncoverage

prog pop_dens_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_pop_density.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_pop_density.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_pop_density_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen pop_density [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen pop_density [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_pop_density_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_lndensity.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_lndensity.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_lndensity.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen lndensity [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lndensity]
  local se = _se[lndensity]
  local t = _b[lndensity]/_se[lndensity]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen lndensity [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_lndensity.pdf", replace  
restore
end
pop_dens_3

prog income_household_median_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_income_household_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen income_household_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_income_household_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_income_household_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen income_household_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_household_median]
  local se = _se[income_household_median]
  local t = _b[income_household_median]/_se[income_household_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen income_household_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_income_household_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_lninc_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_lninc_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_lninc_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen lninc_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_med]
  local se = _se[lninc_med]
  local t = _b[lninc_med]/_se[lninc_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen lninc_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_lninc_med.pdf", replace  
restore
end
income_household_median_3

prog income_per_capita_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_income_per_capita.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen income_per_capita [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_income_per_capita.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_income_per_capita_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen income_per_capita [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[income_per_capita]
  local se = _se[income_per_capita]
  local t = _b[income_per_capita]/_se[income_per_capita]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen income_per_capita [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_income_per_capita_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_lninc_per_cap.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_lninc_per_cap.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_lninc_per_cap.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen lninc_per_cap [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lninc_per_cap]
  local se = _se[lninc_per_cap]
  local t = _b[lninc_per_cap]/_se[lninc_per_cap]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen lninc_per_cap [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_lninc_per_cap.pdf", replace  
restore
end
income_per_capita_3

prog bachelors_share_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_bachelors_share.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen bachelors_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_bachelors_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_bachelors_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_bachelors_share_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_bachelors_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen bachelors_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[bachelors_share]
  local se = _se[bachelors_share]
  local t = _b[bachelors_share]/_se[bachelors_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen bachelors_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_bachelors_share_med.pdf", replace  
restore
end
bachelors_share_3

prog age_median_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_age_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen age_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_age_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_age_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_age_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_age_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen age_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[age_median]
  local se = _se[age_median]
  local t = _b[age_median]/_se[age_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen age_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_age_median_med.pdf", replace  
restore
end
age_median_3

prog house_value_median_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_house_value_median.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen house_value_median [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_house_value_median.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_house_value_median_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen house_value_median [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[house_value_median]
  local se = _se[house_value_median]
  local t = _b[house_value_median]/_se[house_value_median]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen house_value_median [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_house_value_median_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_lnhous_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_lnhous_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_lnhous_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen lnhous_med [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[lnhous_med]
  local se = _se[lnhous_med]
  local t = _b[lnhous_med]/_se[lnhous_med]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen lnhous_med [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_lnhous_med.pdf", replace  
restore
end
house_value_median_3

prog white_share_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_white_share.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen white_share [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_white_share.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_white_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_white_share_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_white_share_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen white_share [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[white_share]
  local se = _se[white_share]
  local t = _b[white_share]/_se[white_share]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen white_share [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_white_share_med.pdf", replace  
restore
end
white_share_3

prog unemploy_rate_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_unemploy_rate.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen unemploy_rate [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_unemploy_rate.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_unemploy_rate_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_unemploy_rate_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_unemploy_rate_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen unemploy_rate [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[unemploy_rate]
  local se = _se[unemploy_rate]
  local t = _b[unemploy_rate]/_se[unemploy_rate]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen unemploy_rate [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_unemploy_rate_med.pdf", replace  
restore
end
unemploy_rate_3

prog poverty_share_household_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_poverty_share_household.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen poverty_share_household [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_poverty_share_household.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_poverty_share_household_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_poverty_share_household_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_poverty_share_household_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen poverty_share_household [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_household]
  local se = _se[poverty_share_household]
  local t = _b[poverty_share_household]/_se[poverty_share_household]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen poverty_share_household [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_poverty_share_household_med.pdf", replace  
restore
end
poverty_share_household_3

prog poverty_share_indivi_3
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_poverty_share_indivi.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen poverty_share_indivi [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_poverty_share_indivi.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_1_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_1_cen poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_1_cen_poverty_share_indivi_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_3_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_3_cen poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_3_cen_poverty_share_indivi_med.pdf", replace  
restore
  
preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_5_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_5_cen poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_5_cen_poverty_share_indivi_med.pdf", replace  
restore

preserve
 keep if tag_blcgrp == 1
  qui reg lncoverage_10_cen poverty_share_indivi [aw = home_device_num] , r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[poverty_share_indivi]
  local se = _se[poverty_share_indivi]
  local t = _b[poverty_share_indivi]/_se[poverty_share_indivi]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter lncoverage_10_cen poverty_share_indivi [aw = home_device_num], n(20) med ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_10_cen_poverty_share_indivi_med.pdf", replace  
restore
end
poverty_share_indivi_3

* do the spatial join with Urban and rural data from Census Gov

prog main_reg
*deal with the urban and rural variables. uatyp10 u means urbanized, c means cluster(more big and population over 25000)
gen urban = 0
replace urban = 1 if uatyp10 == "C"
replace urban = 2 if uatyp10 == "U"
reg coverage_1_cen age_median pop_densit bachelors_share white_share i.urban [aw = home_device_num],r
est sto base1
reg coverage_1_cen age_median pop_densit income_household_median bachelors_share house_value_median white_share unemploy_rate poverty_share_household i.urban [aw = home_device_num],r
est sto m1
reg coverage_1_cen age_median pop_densit income_per_capita bachelors_share house_value_median white_share unemploy_rate poverty_share_indivi i.urban [aw = home_device_num],r
est sto m2
*esttab base1 m1 m2 using regression_robust_se_1.tex, compress nogap r2 ar2 aic bic star(* 0.1 ** 0.05 *** 0.01)


reg coverage_3_cen age_median pop_densit bachelors_share white_share i.urban [aw = home_device_num],r
est sto base2
reg coverage_3_cen age_median pop_densit income_household_median bachelors_share house_value_median white_share unemploy_rate poverty_share_household i.urban [aw = home_device_num],r
est sto m3
reg coverage_3_cen age_median pop_densit income_per_capita bachelors_share house_value_median white_share unemploy_rate poverty_share_indivi i.urban [aw = home_device_num],r
est sto m4

reg coverage_5_cen age_median pop_densit bachelors_share white_share i.urban [aw = home_device_num],r
est sto base3
reg coverage_5_cen age_median pop_densit income_household_median bachelors_share house_value_median white_share unemploy_rate poverty_share_household i.urban [aw = home_device_num],r
est sto m5
reg coverage_5_cen age_median pop_densit income_per_capita bachelors_share house_value_median white_share unemploy_rate poverty_share_indivi i.urban [aw = home_device_num],r
est sto m6

reg coverage_10_cen age_median pop_densit bachelors_share white_share i.urban [aw = home_device_num],r
est sto base4
reg coverage_10_cen age_median pop_densit income_household_median bachelors_share house_value_median white_share unemploy_rate poverty_share_household i.urban [aw = home_device_num],r
est sto m7
reg coverage_10_cen age_median pop_densit income_per_capita bachelors_share house_value_median white_share unemploy_rate poverty_share_indivi i.urban [aw = home_device_num],r
est sto m8

esttab base1 m1 m2 base2 m3 m4  using regression_robust_se_21.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)
esttab base3 m5 m6 base4 m7 m8  using regression_robust_se_12.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)

end
main_reg


***weighted reg
gen lnpop_den = log(pop_densit)

prog main_reg1
*deal with the urban and rural variables. uatyp10 u means urbanized, c means cluster(more big and population over 25000)
reg lncoverage_1_cen age_median lnpop_den lnhous_med white_share  [aw = home_device_num],r
est sto base1
reg lncoverage_1_cen age_median lnpop_den lninc_med  white_share  [aw = home_device_num],r
est sto m1
reg lncoverage_1_cen age_median lnpop_den lninc_per_cap  white_share  [aw = home_device_num],r
est sto m2
reg lncoverage_1_cen age_median lnpop_den lnhous_med white_share  [aw = home_device_num],r
est sto m9
*esttab base1 m1 m2 using regression_robust_se_1.tex, compress nogap r2 ar2 aic bic star(* 0.1 ** 0.05 *** 0.01)


reg lncoverage_3_cen  age_median lnpop_den lnhous_med white_share   [aw = home_device_num],r
est sto base2
reg lncoverage_3_cen age_median lnpop_den lninc_med white_share  [aw = home_device_num],r
est sto m3
reg lncoverage_3_cen  age_median lnpop_den lninc_per_cap white_share  [aw = home_device_num],r
est sto m4

reg lncoverage_5_cen  age_median lnpop_den lnhous_med white_share   [aw = home_device_num],r
est sto base3
reg lncoverage_5_cen age_median lnpop_den lninc_med white_share  [aw = home_device_num],r
est sto m5
reg lncoverage_5_cen  age_median lnpop_den lninc_per_cap white_share  [aw = home_device_num],r
est sto m6

reg lncoverage_10_cen age_median lnpop_den lnhous_med white_share  [aw = home_device_num],r
est sto base4
reg lncoverage_10_cen age_median lnpop_den lninc_med white_share  [aw = home_device_num],r
est sto m7
reg lncoverage_10_cen  age_median lnpop_den lninc_per_cap white_share  [aw = home_device_num],r
est sto m8

esttab base1 m1 m2 base2 m3 m4  using regression_robust_se_mas.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)
esttab base3 m5 m6 base4 m7 m8  using regression_robust_se_dos.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)

end
main_reg1





prog main_reg12223
*deal with the urban and rural variables. uatyp10 u means urbanized, c means cluster(more big and population over 25000)
reg lncoverage_1_cen_med age_median lnpop_den lnhous_med white_share  [aw = home_device_num],r
est sto base1
reg coverage_1_cen_med age_median lnpop_den lninc_med white_share  [aw = home_device_num],r
est sto m1
reg coverage_1_cen_med  age_median lnpop_den lninc_per_cap white_share   [aw = home_device_num],r
est sto m2
*esttab base1 m1 m2 using regression_robust_se_1.tex, compress nogap r2 ar2 aic bic star(* 0.1 ** 0.05 *** 0.01)


reg lncoverage_3_cen_med  age_median lnpop_den lnhous_med white_share   [aw = home_device_num],r
est sto base2
reg lncoverage_3_cen_med age_median lnpop_den lninc_med white_share   [aw = home_device_num],r
est sto m3
reg lncoverage_3_cen_med  age_median lnpop_den lninc_per_cap white_share  [aw = home_device_num],r
est sto m4

reg lncoverage_5_cen_med  age_median lnpop_den lnhous_med white_share   [aw = home_device_num],r
est sto base3
reg lncoverage_5_cen_med age_median lnpop_den lninc_med white_share   [aw = home_device_num],r
est sto m5
reg lncoverage_5_cen_med  age_median lnpop_den lninc_per_cap white_share  [aw = home_device_num],r
est sto m6

reg lncoverage_10_cen_med age_median lnpop_den lnhous_med white_share  [aw = home_device_num],r
est sto base4
reg lncoverage_10_cen_med age_median lnpop_den lninc_med white_share  [aw = home_device_num],r
est sto m7
reg lncoverage_10_cen_med  age_median lnpop_den lninc_per_cap white_share  [aw = home_device_num],r
est sto m8

esttab base1 m1 m2 base2 m3 m4  using regression_robust_se_reg.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)
esttab base3 m5 m6 base4 m7 m8  using regression_robust_se_pants.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)

end
main_reg12223


***unweighted reg
prog main_reg129
*deal with the urban and rural variables. uatyp10 u means urbanized, c means cluster(more big and population over 25000)
reg lncoverage_1_cen  age_median lnpop_den lnhous_med white_share bachelors_share,r
est sto base1
reg lncoverage_1_cen age_median lnpop_den lninc_med lnhous_med white_share bachelors_share,r
est sto m1
reg lncoverage_1_cen age_median lnpop_den lninc_per_cap lnhous_med white_share bachelors_share,r
est sto m2
*esttab base1 m1 m2 using regression_robust_se_1.tex, compress nogap r2 ar2 aic bic star(* 0.1 ** 0.05 *** 0.01)


reg lncoverage_3_cen  age_median lnpop_den lnhous_med white_share bachelors_share ,r
est sto base2
reg lncoverage_3_cen age_median lnpop_den lninc_med lnhous_med white_share bachelors_share,r
est sto m3
reg lncoverage_3_cen age_median lnpop_den lninc_per_cap lnhous_med white_share bachelors_share,r
est sto m4

reg lncoverage_5_cen  age_median lnpop_den lnhous_med white_share bachelors_share ,r
est sto base3
reg lncoverage_5_cen age_median lnpop_den lninc_med lnhous_med white_share bachelors_share,r
est sto m5
reg lncoverage_5_cen age_median lnpop_den lninc_per_cap lnhous_med white_share bachelors_share,r
est sto m6

reg lncoverage_10_cen  age_median lnpop_den lnhous_med white_share bachelors_share,r
est sto base4
reg lncoverage_10_cen age_median lnpop_den lninc_med lnhous_med white_share bachelors_share,r
est sto m7
reg lncoverage_10_cen age_median lnpop_den lninc_per_cap lnhous_med white_share bachelors_share,r
est sto m8

esttab base1 m1 m2 base2 m3 m4  using regression_robust_se_ma.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)
esttab base3 m5 m6 base4 m7 m8  using regression_robust_se_pa.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)

end
main_reg129




prog main_reg122231
*deal with the urban and rural variables. uatyp10 u means urbanized, c means cluster(more big and population over 25000)
reg lncoverage_1_cen_med  age_median lnpop_den lnhous_med white_share bachelors_share,r
est sto base1
reg coverage_1_cen_med age_median lnpop_den lninc_med lnhous_med white_share bachelors_share,r
est sto m1
reg coverage_1_cen_med age_median lnpop_den lninc_per_cap lnhous_med white_share bachelors_share ,r
est sto m2
*esttab base1 m1 m2 using regression_robust_se_1.tex, compress nogap r2 ar2 aic bic star(* 0.1 ** 0.05 *** 0.01)


reg lncoverage_3_cen_med  age_median lnpop_den lnhous_med white_share bachelors_share ,r
est sto base2
reg lncoverage_3_cen_med age_median lnpop_den lninc_med lnhous_med white_share bachelors_share ,r
est sto m3
reg lncoverage_3_cen_med age_median lnpop_den lninc_per_cap lnhous_med white_share bachelors_share,r
est sto m4

reg lncoverage_5_cen_med  age_median lnpop_den lnhous_med white_share bachelors_share ,r
est sto base3
reg lncoverage_5_cen_med age_median lnpop_den lninc_med lnhous_med white_share bachelors_share ,r
est sto m5
reg lncoverage_5_cen_med age_median lnpop_den lninc_per_cap lnhous_med white_share bachelors_share,r
est sto m6

reg lncoverage_10_cen_med  age_median lnpop_den lnhous_med white_share bachelors_share,r
est sto base4
reg lncoverage_10_cen_med age_median lnpop_den lninc_med lnhous_med white_share bachelors_share,r
est sto m7
reg lncoverage_10_cen_med age_median lnpop_den lninc_per_cap lnhous_med white_share bachelors_share,r
est sto m8

esttab base1 m1 m2 base2 m3 m4  using regression_robust_se_ga.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)
esttab base3 m5 m6 base4 m7 m8  using regression_robust_se_va.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)

end
main_reg122231


























prog dropbox_global , rclass
syntax [, NOCD]

if "`c(os)'" == "Windows" {
	local _db "/users/`c(username)'"
}
if "`c(os)'"~= "Windows" {
	local _db "~"
}

capture local dropbox : dir "`_db'" dir "*Dropbox*" , respectcase
if _rc==0 & `"`dropbox'"'~="" {
	local dropbox : subinstr local dropbox `"""' "" , all
	local delete_dropbox : subinstr local dropbox "Dropbox" "", all count(local nb_of_dropbox)
	if `nb_of_dropbox' > 1{
		local dropbox : dir "`_db'" dir "*Personal*" , respectcase
		local dropbox : subinstr local dropbox `"""' "" , all
	}
	if "`nocd'"=="" {
		cd "`_db'/`dropbox'/"
	}
	return local db "`_db'/`dropbox'/"
	exit
}
if _rc~=0 & "`c(os)'" == "Windows" {
	capture cd c:/
	if _rc~=0 {
		nois di in red "Cannot find dropbox folder"
		exit
	}
	capture local dropbox : dir "`_db'" dir "*Dropbox*" , respectcase
	if _rc==0 & `"`dropbox'"'~="" {
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "`_db'/`dropbox'/"
		}
		return local db "`_db'/`dropbox'/"
		exit
	}
	capture local dropbox : dir "/documents and settings/`c(username)'/my documents/" dir "*dropbox*" , 
	if _rc==0 &  `"`dropbox'"'~=""{
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "c:/documents and settings/`c(username)'/my documents/`dropbox'"
		}
		return local db "c:/documents and settings/`c(username)'/my documents/`dropbox'"
		exit
	}

	capture local dropbox : dir "/documents and settings/`c(username)'/documents/" dir "*dropbox*" , 
	if _rc==0 &  `"`dropbox'"'~=""{
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "c:/documents and settings/`c(username)'/documents/`dropbox'"
		}
		return local db "c:/documents and settings/`c(username)'/documents/`dropbox'"
		exit
	}
}
if _rc~=0 & "`c(os)'" ~= "Windows" {
	nois di in red "Cannot find dropbox folder"
	exit
}
if _rc==0 & `"`dropbox'"'=="" {
	capture local dropbox : dir "`_db'/Documents" dir "*Dropbox*" , respectcase
	if _rc==0 {
		local doc "Documents"
	}
	if `"`dropbox'"'=="" {
		capture local dropbox : dir "`_db'/My Documents" dir "*Dropbox*" , respectcase
		if _rc==0 {
			local doc "My Documents"
		}
	}
	if `"`dropbox'"'~="" {
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "`_db'/`doc'/`dropbox'/"
		}
		return local db "`_db'/`doc'/`dropbox'/"
		exit
	}

	if `"`dropbox'"'=="" & "`c(os)'" == "Windows" {
		local dropbox : dir "C:/" dir "*Dropbox*" , respectcase
		local dropbox : subinstr local dropbox `"""' "" , all
		if "`nocd'"=="" {
			cd "/`dropbox'"
		}
		return local db "/`dropbox'"
		exit
	}
	if `"`dropbox'"'=="" & "`c(os)'" ~= "Windows" {
		nois di in red "Cannot find dropbox folder"
		exit
	}
}
end

dropbox global
