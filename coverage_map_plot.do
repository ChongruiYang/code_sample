version 17.0
clear all
set more off
set scheme s1color
*set trace on
capture log close
*author: chongrui yang, focus on the coverage geographic distribution in CA

prog drop _all
prog config
  **Setup directory:
  dropbox  
  global dir "`r(db)'Amenity"

  **Setup in Linux:
  *set processors 4
  *set max_memory 100g, permanently

  **Generate log.file:
  cd "$dir"
  cap mkdir "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles"
  log using "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles/sankey_sample_plot.log", replace
end
config

prog main_maptile_combine
use ".\data\analysis\veraset_gravy_gps_sample\coverage_maptile_file.dta", clear

**afraid some outlier, just winsor(5,95)
winsor2 coverage_1 coverage_3 coverage_5 coverage_10, replace cut(5,95)

**get mean coverage by cz or by 5-digit zip in 2000
rename CommutingZoneID2000 cz
gen zip5 = real(zcta)
gen mark = 1
bys cz: egen coverage_1_cz = mean(coverage_1)
bys cz: egen coverage_3_cz = mean(coverage_3)
bys cz: egen coverage_5_cz = mean(coverage_5)
bys cz: egen coverage_10_cz = mean(coverage_10)
bys cz: egen coverage_1_cz_med = median(coverage_1)
bys cz: egen coverage_3_cz_med = median(coverage_3)
bys cz: egen coverage_5_cz_med = median(coverage_5)
bys cz: egen coverage_10_cz_med = median(coverage_10)
bys zcta: egen coverage_1_zcta = mean(coverage_1)
bys zcta: egen coverage_3_zcta = mean(coverage_3)
bys zcta: egen coverage_5_zcta = mean(coverage_5)
bys zcta: egen coverage_10_zcta = mean(coverage_10)
bys zcta: egen coverage_1_zcta_med = median(coverage_1)
bys zcta: egen coverage_3_zcta_med = median(coverage_3)
bys zcta: egen coverage_5_zcta_med = median(coverage_5)
bys zcta: egen coverage_10_zcta_med = median(coverage_10)

** gen the weighted coverage in cz or zip5
bys cz: egen device_cz = sum(mark)
bys zcta: egen device_zcta = sum(mark)
gen total = 3790784
gen share_cz = device_cz/total
gen share_zcta = device_zcta/total


** cut off all the outliers of veraset coverage**
foreach i in 1 3 5 10{
    gen lncoverage_`i'_cz = log(coverage_`i'_cz)
    gen lncoverage_`i'_cz_med = log(coverage_`i'_cz_med)
    gen lncoverage_`i'_zcta = log(coverage_`i'_zcta)
    gen lncoverage_`i'_zcta_med = log(coverage_`i'_zcta_med)
    winsor2 lncoverage_`i'_cz lncoverage_`i'_cz_med lncoverage_`i'_zcta lncoverage_`i'_zcta_med coverage_`i'_zcta_med coverage_`i'_zcta coverage_`i'_cz_med coverage_`i'_cz, trim cut(1 99) replace
}

prog plotall
foreach i in 1 3 5 10{
preserve
bys cz : gen tag = 1 if _n == 1 
keep if tag == 1

qui sum coverage_`i'_cz, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_`i'_cz, ///
          xtitle("coverage distribution cz") ///
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
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_`i'_cz_dis.pdf", replace
  
qui sum coverage_`i'_cz_med, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_`i'_cz_med, ///
          xtitle("coverage distribution cz med") ///
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
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_`i'_cz_med_dis.pdf", replace

qui sum lncoverage_`i'_cz, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram lncoverage_`i'_cz, ///
          xtitle("lncoverage distribution cz") ///
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
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_`i'_cz_dis.pdf", replace
  
 qui sum lncoverage_`i'_cz_med, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram lncoverage_`i'_cz_med, ///
          xtitle("lncoverage distribution cz med") ///
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
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_`i'_cz_med_dis.pdf", replace 
}
  
  
bys zcta : gen tag = 1 if _n == 1   
preserve
foreach i in 1 3 5 10 {


keep if tag == 1

qui sum coverage_`i'_zcta, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_`i'_zcta, ///
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
         bin(40) bcolor(blue%20) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_`i'_zcta_dis.pdf", replace
  
qui sum coverage_`i'_zcta_med, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram coverage_`i'_zcta_med, ///
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
         bin(40) bcolor(blue%20) gap(20) scheme(s1color)
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/coverage_`i'_zcta_med_dis.pdf", replace

qui sum lncoverage_`i'_zcta, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram lncoverage_`i'_zcta, ///
          xtitle("lncoverage distribution zcta") ///
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
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_`i'_zcta_dis.pdf", replace
  
 qui sum lncoverage_`i'_zcta_med, d
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

histogram lncoverage_`i'_zcta_med, ///
          xtitle("lncoverage distribution zcta med") ///
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
  graph export "./output/analysis/veraset_gravy_gps_sample_analysis/varaset_home_work_locations/lncoverage_`i'_zcta_med_dis.pdf", replace 
  }
  restore
end

plotall


  
  
  
  
**plot the device_number in cz or zip5
**please remember to use spmap command to support the maptile because maptile is builded by spmap

preserve
bys cz : gen tag = 1 if _n == 1 
keep if tag == 1
maptile device_cz, geo(cz2000) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\cz_device.pdf",replace
restore

** ensure all the zipcode 2000 are in CA, so zip5 must be regulated
keep if zip5 >90001 & zip5<96163

preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
maptile device_zcta, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\zcta_device.pdf",replace
restore

** plot coverage in cz2000 in CA
preserve
drop if cz == .
bys cz : gen tag = 1 if _n == 1 
keep if tag == 1
* maptile coverage_10_zcta_med, geo(zip5) nq(6) stateoutline (medthick) mapif(mark==1)
maptile coverage_1_cz, geo(cz2000) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_1_cz.pdf",replace
maptile coverage_3_cz, geo(cz2000) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_3_cz.pdf",replace
maptile coverage_5_cz, geo(cz2000) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_5_cz.pdf",replace
maptile coverage_10_cz, geo(cz2000) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_10_cz.pdf",replace
maptile coverage_1_cz_med, geo(cz2000) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_1_cz_med.pdf",replace
maptile coverage_3_cz_med, geo(cz2000) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_3_cz_med.pdf",replace
maptile coverage_5_cz_med, geo(cz2000) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_5_cz_med.pdf",replace
maptile coverage_10_cz_med, geo(cz2000) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_10_cz_med.pdf",replace




** plot coverage in zcta_2000 in CA
preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
* maptile coverage_10_zcta_med, geo(zip5) nq(6) stateoutline (medthick) mapif(mark==1)
maptile coverage_1_zcta, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_1_zcta.pdf",replace
maptile coverage_3_zcta, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_3_zcta.pdf",replace
maptile coverage_5_zcta, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_5_zcta.pdf",replace
maptile coverage_10_zcta, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_10_zcta.pdf",replace
maptile coverage_1_zcta_med, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_1_zcta_med.pdf",replace
maptile coverage_3_zcta_med, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_3_zcta_med.pdf",replace
maptile coverage_5_zcta_med, geo(zip5) nq(6) mapif(mark==1)   spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_5_zcta_med.pdf",replace
maptile coverage_10_zcta_med, geo(zip5) nq(6) mapif(mark==1)  spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_10_zcta_med.pdf",replace



preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
* maptile coverage_10_zcta_med, geo(zip5) nq(6) stateoutline (medthick) mapif(mark==1)
maptile coverage_1_zcta, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_1_zcta.pdf",replace
maptile coverage_3_zcta, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_3_zcta.pdf",replace
maptile coverage_5_zcta, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_5_zcta.pdf",replace
maptile coverage_10_zcta, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_10_zcta.pdf",replace
maptile coverage_1_zcta_med, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_1_zcta_med.pdf",replace
maptile coverage_3_zcta_med, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_3_zcta_med.pdf",replace
maptile coverage_5_zcta_med, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_5_zcta_med.pdf",replace
maptile coverage_10_zcta_med, geo(zip5) nq(6) mapif(mark==1) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\coverage_10_zcta_med.pdf",replace


preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
bys zip5: egen inc_per = mean(income_per_capita)
maptile inc_per, geo(zip5) nq(6) mapif(mark==1) fcolor(ltblue*0.7  eltblue*0.6 eltblue ebblue edkblue edkblue*1.5) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\inc_per.pdf",replace
restore

*some intuitive plot
preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
bys zip5: egen inc_hous = mean(income_household_median)
maptile inc_hous, geo(zip5) nq(6) mapif(mark==1) fcolor(ltblue*0.7  eltblue*0.6 eltblue ebblue  edkblue edkblue*1.5) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\inc_hous.pdf",replace
restore

preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
bys zip5: egen hous_val = mean(house_value_median)
maptile hous_val, geo(zip5) nq(6) mapif(mark==1) fcolor(ltblue*0.7  eltblue*0.6 eltblue ebblue  edkblue edkblue*1.5) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\hous_val.pdf",replace
restore

preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
bys zip5: egen age_m = mean(age_median)
maptile age_m, geo(zip5) nq(6) mapif(mark==1) fcolor(ltblue*0.7  eltblue*0.6 eltblue ebblue edkblue edkblue*1.5) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\age_m.pdf",replace
restore

preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
bys zip5: egen b_s = mean(bachelors_share)
maptile b_s, geo(zip5) nq(6) mapif(mark==1) fcolor(ltblue*0.7  eltblue*0.6 eltblue ebblue edkblue edkblue*1.5) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\b_s.pdf",replace
restore

preserve
bys zip5 : gen tag = 1 if _n == 1 
keep if tag == 1
bys zip5: egen em_po= mean(employ_to_population)
maptile em_po, geo(zip5) nq(6) mapif(mark==1) fcolor(ltblue*0.7  eltblue*0.6 eltblue ebblue edkblue edkblue*1.5) spopt(legend(pos(6) row(3) ring(1) size(*.75) symx(*.75) symy(*.75) forcesize )) 
graph export ".\output\analysis\veraset_gravy_gps_sample_analysis\varaset_home_work_locations\em_po.pdf",replace
restore
end
main_maptile_combine


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