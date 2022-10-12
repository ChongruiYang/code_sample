/*coverage and acs data merged results
date: 2022/4/12
chongrui */

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
  log using "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles/home_start_end.log", replace

  **Setup the number of cores that will be used.
  *set processors 10

  **Setup parameter:

end


use "C:\Users\Justin\Dropbox\Amenity\data\analysis\veraset_gravy_gps_sample\our_home_final_sample.dta"

/*merge with coverage data*/
merge 1:1 caid using "C:\Users\Justin\Dropbox\Amenity\data\analysis\veraset_gravy_gps_sample\total_coverage.dta"
keep if _merge == 3
drop _merge

/*spatial join the coverage and the ACS, ALAND is square meters*/



/*cbg 2010 data merge routine*/
drop oid_ join_count target_fid statefp10 countyfp10 tractce10 blkgrpce10 namelsad10 mtfcc10 funcstat10 awater10 intptlat10 intptlon10 gisjoin
rename geoid10 our_cbg
rename aland10 our_cbg_land
tostring our_cbg, gen(cbg_id_str) format(%14.0g) force
*rename our_cbg cbg_id_str 

merge 1:1 caid using "C:\Users\Justin\Desktop\2.dta"
keep if _merge == 3
drop _merge
format our_cbg_id %13.0f
tostring our_cbg, gen(cbg_id_str) format(%14.0g) force
gen cbg_id_str = substr(cbg_id,2,11)

/*use our lat and lon to gen a cbg id, then merge it with ACS data*/
merge 1:m cbg_id_str using "C:\Users\Justin\Desktop\2.dta"
keep if _merge == 3
drop _merge

/*get the dataset merged with acs grp and zcta*/


winsor2 coverage_10, replace cut(5,95)
gen mark = 1
bys zcta: egen coverage_10_zcta = mean(coverage_10)
bys zcta: egen coverage_10_zcta_med = median(coverage_10)
bys zcta: egen device_zcta = sum(mark)

*sum coverage_10, d
*keep if coverage_10 >= .0604839
*drop coverage_10_zcta coverage_10_zcta_med
*drop device_zcta
*bys zcta: egen coverage_10_zcta = mean(coverage_10)
*bys zcta: egen coverage_10_zcta_med = median(coverage_10)
*bys zcta: egen device_zcta = sum(mark)

*gen zip5 = real(zcta)
*duplicates drop zip5, force
*keep if zip5 >90001 & zip5<96163  

/* 
maptile device_zcta, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\veraset_home_work_locations\zcta_device_p75.pdf",replace
maptile coverage_10_zcta, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\veraset_home_work_locations\coverage_10_zcta_p75.pdf",replace
maptile coverage_10_zcta_med, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\veraset_home_work_locations\coverage_10_zcta_med_p75.pdf",replace
*/


preserve 
bys zcta : gen tag = 1 if _n == 1  
keep if tag == 1

qui sum coverage_10_zcta, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_10_zcta, ///
          xtitle("coverage distribution zcta") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs12) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_zcta_dis.pdf", replace
  
qui sum coverage_10_zcta_med, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_10_zcta_med, ///
          xtitle("coverage distribution zcta med") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs12) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_zcta_med_dis.pdf", replace

*note some abnormal results will show the data is not stable,
gen zip5 = real(zcta)
keep if zip5 >90001 & zip5<96163  
  
maptile device_zcta, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\veraset_home_work_locations\zcta_device.pdf",replace
maptile coverage_10_zcta, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\veraset_home_work_locations\coverage_10_zcta.pdf",replace
maptile coverage_10_zcta_med, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\veraset_home_work_locations\coverage_10_zcta_med.pdf",replace
restore

bys zcta: egen num_mean = mean(num_records_overnight)
bys zcta: egen num_median = median(num_records_overnight)
bys zcta: gen mark = _n
duplicates drop zip5, force
maptile num_mean, geo(zip5) nq(6) mapif(mark==1) fcolor(ltblue*0.4  eltblue*0.6 eltblue ebblue*0.8 edkblue*0.9 edkblue*1.5) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\veraset_home_work_locations\num_mean.pdf",replace
maptile num_median, geo(zip5) nq(6) mapif(mark==1) fcolor(ltblue*0.4  eltblue*0.6 eltblue ebblue*0.8 edkblue*0.9 edkblue*1.5) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\veraset_home_work_locations\num_median.pdf",replace

/*deal with the binscatter*/
drop _merge
merge 1:m cbg_id_str using "C:\Users\Justin\Desktop\2.dta"
keep if _merge == 3
drop _merge

gen ln_population = log(population)
gen ln_median_hhinc = log(median_hhinc)
gen ln_per_capita_inc = log(per_capita_inc)
gen ln_median_house_value = log(median_house_value)
unique our_cbg
*gen a average or median for each census block group
bys our_cbg: egen coverage_10_mean = mean(coverage_10)
bys our_cbg: egen coverage_10_median = median(coverage_10)
bys our_cbg: egen home_device_num = count(caid)
bys our_cbg: gen tag_blcgrp = 1 if _n == 1 
gen pop_density = population/(our_cbg_land/1000000)
gen share_over_hs = 1 -share_less_hs
keep if tag_blcgrp == 1 


*winsor all the data indicators
winsor2 ln_population ln_median_hhinc ln_per_capita_inc ln_median_house_value pop_density share_unemploy share_white share_over_hs median_age coverage_10_mean coverage_10_median

sum ln_population ln_median_hhinc ln_per_capita_inc ln_median_house_value pop_density share_unemploy share_white share_over_hs median_age,d
outreg2 using x.tex, replace sum(detail) keep (ln_population ln_median_hhinc ln_per_capita_inc ln_median_house_value pop_density share_unemploy share_white share_over_hs median_age) eqkeep(N mean sd min max p25 p50 p75)

*deal with the coverage in cbg level as we aggregate

preserve
qui sum coverage_10_mean, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_10_mean, ///
          xtitle("coverage mean in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean.pdf", replace 
  
qui sum coverage_10_median, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_10_median, ///
          xtitle("coverage median in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median.pdf", replace  
  
qui sum ln_population, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram ln_population, ///
          xtitle("ln_population in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/ln_population.pdf", replace 
  
 qui sum ln_median_hhinc, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram ln_median_hhinc, ///
          xtitle("ln_median_hhinc in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/ln_median_hhinc.pdf", replace  
  
  
qui sum ln_per_capita_inc, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram ln_per_capita_inc, ///
          xtitle("ln_per_capita_inc in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/ln_per_capita_inc.pdf", replace   
  
  
qui sum ln_median_house_value, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram ln_median_house_value, ///
          xtitle("ln_median_house_value in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/ln_median_house_value.pdf", replace 
  
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
          xtitle("pop_density(person per KM2) in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/pop_density.pdf", replace 
  
 qui sum share_unemploy, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram share_unemploy, ///
          xtitle("share_unemploy in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/share_unemploy.pdf", replace  
  
 qui sum share_white, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram share_white, ///
          xtitle("share_white in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(10) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/share_white.pdf", replace   
  
  
qui sum share_over_hs, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram share_over_hs, ///
          xtitle("share_over_hs in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(10) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/share_over_hs.pdf", replace 
  
  
qui sum median_age, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram median_age, ///
          xtitle("median_age in cbg level") ///
          note(`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"Observation = `=string(`number',"%10.0f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(small) position(2) ring(0) linegap(1.5)) ///
         bin(40) bcolor(gs18) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/median_age.pdf", replace 
  
restore

*plot a series of binscatters for home devices
qui reg coverage_10_mean pop_density [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_pop_density.pdf", replace 
  
qui reg coverage_10_median pop_density [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[pop_density]
  local se = _se[pop_density]
  local t = _b[pop_density]/_se[pop_density]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median pop_density [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_pop_density.pdf", replace  
  
  
qui reg coverage_10_mean ln_population [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[ln_population]
  local se = _se[ln_population]
  local t = _b[ln_population]/_se[ln_population]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean ln_population [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_ln_population.pdf", replace 
  
qui reg coverage_10_median ln_population [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[ln_population]
  local se = _se[ln_population]
  local t = _b[ln_population]/_se[ln_population]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median ln_population [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_ln_population.pdf", replace 
  
qui reg coverage_10_mean ln_median_hhinc [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[ln_median_hhinc]
  local se = _se[ln_median_hhinc]
  local t = _b[ln_median_hhinc]/_se[ln_median_hhinc]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean ln_median_hhinc [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_ln_median_hhinc.pdf", replace 
  
qui reg coverage_10_median ln_median_hhinc [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[ln_median_hhinc]
  local se = _se[ln_median_hhinc]
  local t = _b[ln_median_hhinc]/_se[ln_median_hhinc]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median ln_median_hhinc [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_ln_median_hhinc.pdf", replace 
  
qui reg coverage_10_mean ln_per_capita_inc [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[ln_per_capita_inc]
  local se = _se[ln_per_capita_inc]
  local t = _b[ln_per_capita_inc]/_se[ln_per_capita_inc]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean ln_per_capita_inc [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_ln_per_capita_inc.pdf", replace 
  
qui reg coverage_10_median ln_per_capita_inc [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[ln_per_capita_inc]
  local se = _se[ln_per_capita_inc]
  local t = _b[ln_per_capita_inc]/_se[ln_per_capita_inc]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median ln_per_capita_inc [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_ln_per_capita_inc.pdf", replace 
  
 qui reg coverage_10_mean ln_median_house_value [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[ln_median_house_value]
  local se = _se[ln_median_house_value]
  local t = _b[ln_median_house_value]/_se[ln_median_house_value]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean ln_median_house_value [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_ln_median_house_value.pdf", replace 
  
qui reg coverage_10_median ln_median_house_value [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[ln_median_house_value]
  local se = _se[ln_median_house_value]
  local t = _b[ln_median_house_value]/_se[ln_median_house_value]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median ln_median_house_value [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_ln_median_house_value.pdf", replace 
  
qui reg coverage_10_mean share_unemploy [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[share_unemploy]
  local se = _se[share_unemploy]
  local t = _b[share_unemploy]/_se[share_unemploy]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean share_unemploy [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_share_unemploy.pdf", replace 
  
qui reg coverage_10_median share_unemploy [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[share_unemploy]
  local se = _se[share_unemploy]
  local t = _b[share_unemploy]/_se[share_unemploy]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median share_unemploy [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_share_unemploy.pdf", replace
  
  
qui reg coverage_10_mean share_white [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[share_white]
  local se = _se[share_white]
  local t = _b[share_white]/_se[share_white]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean share_white [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_share_white.pdf", replace 
  
qui reg coverage_10_median share_white [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[share_white]
  local se = _se[share_white]
  local t = _b[share_white]/_se[share_white]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median share_white [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_share_white.pdf", replace 
  
  
qui reg coverage_10_mean share_over_hs [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[share_over_hs]
  local se = _se[share_over_hs]
  local t = _b[share_over_hs]/_se[share_over_hs]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean share_over_hs [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_share_over_hs.pdf", replace 
  
qui reg coverage_10_median share_over_hs [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[share_over_hs]
  local se = _se[share_over_hs]
  local t = _b[share_over_hs]/_se[share_over_hs]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median share_over_hs [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_share_over_hs.pdf", replace 

  
qui reg coverage_10_mean median_age [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[median_age]
  local se = _se[median_age]
  local t = _b[median_age]/_se[median_age]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_mean median_age [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_mean_median_age.pdf", replace 
  
qui reg coverage_10_median median_age [aw = home_device_num], r
  local r2 = `e(r2)'
  local r2_a = `e(r2_a)'
  local beta = _b[median_age]
  local se = _se[median_age]
  local t = _b[median_age]/_se[median_age]
  local p =  2*ttail(e(df_r),abs(`t'))
  local N = `e(N)'

binscatter coverage_10_median median_age [aw = home_device_num], n(20) ///
  ///
    note(`"r2 = `=string(`r2',"%8.4fc")'"'  ///
        `"r2_adjust = `=string(`r2_a',"%8.4fc")'"'  ///
			     `"N = `=string(`N',"%8.0fc")'"'  ///
        `"beta = `=string(`beta',"%8.4fc")'"' `"se = `=string(`se',"%8.4fc")'"'  ///
        `"t = `=string(`t',"%8.4fc")'"' `"p = `=string(`p',"%8.4fc")'"',   ///
      size(small) position(1) ring(0) linegap(1.5)) 
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/veraset_home_work_locations/coverage_10_median_median_age.pdf", replace 
  
/*run the reg for all the indicators for the original data*/
gen h_coverage_10_mean = 100*coverage_10_mean
gen h_coverage_10_median = 100*coverage_10_median

*ln_population ln_median_hhinc ln_per_capita_inc ln_median_house_value pop_density share_unemploy share_white share_over_hs median_age

reg h_coverage_10_mean median_age ln_population share_white share_over_hs urban,r
est sto base1
reg h_coverage_10_median median_age ln_population share_white share_over_hs urban,r
est sto basem1

reg h_coverage_10_mean median_age ln_population share_white share_over_hs urban ln_median_hhinc,r
est sto base2
reg h_coverage_10_median median_age ln_population share_white share_over_hs urban ln_median_hhinc,r
est sto basem2

reg h_coverage_10_mean median_age ln_population share_white share_over_hs urban ln_per_capita_inc,r
est sto base3
reg h_coverage_10_median median_age ln_population share_white share_over_hs urban ln_per_capita_inc,r
est sto basem3

reg h_coverage_10_mean median_age ln_population share_white share_over_hs urban ln_median_house_value,r
est sto base4
reg h_coverage_10_median median_age ln_population share_white share_over_hs urban ln_median_house_value,r
est sto basem4

esttab base1 base2 base3 base4 using regression_robust_mean.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)
esttab basem1 basem2 basem3 basem4 using regression_robust_median.tex, compress nogap r2 ar2 aic bic p star(* 0.1 ** 0.05 *** 0.01)

