* 4/4/2022
* ZiwenSun, ZhuolinXiang
* coverage analysis

version 17.0
clear all
set more off
set scheme s1color
capture log close

prog drop _all

**Central config program
prog config
  **Setup directory:
  dropbox  
  global dir "`r(db)'Amenity"

  **generate log.file:
  cd "$dir"
  cap mkdir "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles"
  log using "./output/analysis/veraset_gravy_gps_sample_analysis/logfiles/coverage_analysis.log", replace

  **Setup the number of cores that will be used.
  *set processors 10

  **Setup parameter:

end

* ------------------------------------------------------------------------------
prog main

//data_append

use "./data/derived/veraset_gravy_gps_sample/veraset/device_coverage.dta", clear

data_prep 

//reg_dofw

plots

end


prog plots

* 1. active devices across all 35 days, and across day of week
//
graph bar (count) device_id, over(date, label(angle(60))) ytitle("Number of Active Devices") scale(0.8)
graph export "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/active_device_date.pdf", replace
//
graph bar (count) device_id, over(dofw, label(angle(60))) ytitle("Number of Active Devices")
graph export "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/active_device_dofw.pdf", replace

* 2. binscatter plot
//binscatter coverage_10 dofw, discrete
//
//binscatter coverage_10 date, discrete
//
//reghdfe coverage_1 i.device_id, noabsorb
//predict res_coverage_1, residuals

* 3. mean coverage 

//graph bar (mean) coverage_1, over(dofw, label(angle(60)))
//graph export "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/mean_coverage_1_dofw.pdf", replace

//graph bar (mean) coverage_3, over(dofw, label(angle(60)))
//graph export "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/mean_coverage_3_dofw.pdf", replace
//
//graph bar (mean) coverage_5, over(dofw, label(angle(60)))
//graph export "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/mean_coverage_5_dofw.pdf", replace
//
//graph bar (mean) coverage_10, over(dofw, label(angle(60)))
//graph export "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/mean_coverage_10_dofw.pdf", replace


* 4. histograms for coverage on each day of week
//label var dofw "day of week"
//gen coverage_1_log = log(coverage_1)
//gen coverage_3_log = log(coverage_3)
//gen coverage_5_log = log(coverage_5)
//gen coverage_10_log = log(coverage_10)
//forv i = 1/7 {
	//hist_plot, var(coverage_1) day_of_week(`i')
 	//hist_plot, var(coverage_3) day_of_week(`i')
 	//hist_plot, var(coverage_5) day_of_week(`i')
 	//hist_plot, var(coverage_10) day_of_week(`i')
//}

end


prog hist_plot

syntax, var(str) day_of_week(integer)

sum `var' if dofw == `day_of_week', detail
local mcover = `r(mean)'
local sdcover = `r(sd)'
local maxcover = `r(max)'
local mincover = `r(min)'
local number = `r(N)'
local p25 = `r(p25)'
local p75 = `r(p75)'
local p50 = `r(p50)'

hist `var' if dofw == `day_of_week', bcolor(navy*0.5) note(`"SampleSize = `=string(`number',"%10.0f")'"'  ///
				`"Mean = `=string(`mcover',"%4.2f")'"' ///
                `"S.D. = `=string(`sdcover',"%4.2f")'"' ///
                 `"Max = `=string(`maxcover',"%4.2f")'"'  ///
                 `"Min = `=string(`mincover',"%4.2f")'"'  ///
                 `"p25 = `=string(`p25',"%4.3f")'"'  ///
                 `"p50 = `=string(`p50',"%4.3f")'"'  ///
                 `"p75 = `=string(`p75',"%4.3f")'"', ///
                 size(medium) position(2) ring(0) linegap(1.5))

graph export "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/hist_`var'_day_`day_of_week'.pdf", replace

end


program reg_dofw

local i = 1
foreach coverage in coverage_1 coverage_3 coverage_5 coverage_10 {
	
	reghdfe `coverage' ib4.dofw, absorb(device_id) cluster(dofw)
	
	if `i' == 1 {
		outreg2 using "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/reg_coverage_dofw.tex", replace dec(5) label tex(frag) nocons nonotes nor2 addstat(R-squared, `e(r2)') addtext(Device FE, Yes) 
	} 
	else {
		outreg2 using "./output/analysis/veraset_gravy_gps_sample_analysis/coverage_analysis/reg_coverage_dofw.tex", append dec(5) label tex(frag) nocons nonotes nor2 addstat(R-squared, `e(r2)') addtext(Device FE, Yes) 		
	}

	local i = `i' + 1
}

end


prog data_prep

*** replace str id with num id
egen device_id = group(caid)
drop caid

*** duplicates caused by id_type, keep higher monthly coverage one
egen unique_id = group(device_id id_type)

bys device_id id_type: egen num_days_type = count(device_id)
bys device_id: egen num_days_device = count(device_id)

gen dup = (num_days_device != num_days_type)

bys device_id id_type: egen monthly_coverage = sum(coverage_1) if dup==1
replace monthly_coverage = monthly_coverage/62

**** now take the max coverage one
bys device_id: egen max_coverage = max(monthly_coverage) if dup==1
drop if dup==1 & monthly_coverage!=max_coverage

drop unique_id num_days_type num_days_device dup monthly_coverage max_coverage

** encode the day of week dummy to numerical form
rename dofw day_of_week
la define dofw 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" 7 "Sunday"
encode day_of_week, gen(dofw) label(dofw)

drop day_of_week

** a bit labeling
label var coverage_1 "1-min Block Coverage"
label var coverage_3 "3-min Block Coverage"
label var coverage_5 "5-min Block Coverage"
label var coverage_10 "10-min Block Coverage"

** substr of date
replace date = substr(date, 1, 6)

replace date = subinstr(date, "Apr", "04", .)
replace date = subinstr(date, "May", "05", .)
replace date = subinstr(date, "Jun", "06", .)

end


prog data_append

local index "00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21"
local j = 0
foreach i in "`index'" {
	import delimited "./data/derived/veraset_gravy_gps_sample/veraset/device_coverage_`i'.csv", clear 
	save "./data/derived/veraset_gravy_gps_sample/veraset/device_coverage_`j'.dta", replace
	local j = `j' + 1
}

use "./data/derived/veraset_gravy_gps_sample/veraset/device_coverage_0.dta", clear

forv i = 1/21 {
	append using "./data/derived/veraset_gravy_gps_sample/veraset/device_coverage_`i'.dta"
	erase "./data/derived/veraset_gravy_gps_sample/veraset/device_coverage_`i'.dta"
}

//save "./data/derived/veraset_gravy_gps_sample/veraset/device_coverage.dta", replace

//erase "./data/derived/veraset_gravy_gps_sample/veraset/device_coverage_0.dta"

end


prog dropbox , rclass
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


config 
main

log close
