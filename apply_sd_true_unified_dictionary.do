clear all
set more off
set varabbrev off

local root      "/Users/renhangdong/Desktop/Research/Commercial_Bank"
local cleanroot "`root'/2007～2016年税收调查数据（含 sdid）/税调2007-2016_cleaned"
local docs      "`root'/2007～2016年税收调查数据（含 sdid）/税调变量说明07-16"
local outroot   "`cleanroot'/sd_cleaned_true_unified"
local dict      "`docs'/sd_2007_2016_真统一字典.dta"

capture mkdir "`outroot'"

log using "`root'/apply_sd_true_unified_dictionary.log", replace text

capture confirm file "`dict'"
if _rc {
    display as error "Unified SD dictionary not found. Run build_sd_2007_2016_true_unified_dictionary.do first."
    exit 601
}

forvalues y = 2007/2016 {
    display "Applying unified dictionary to SD cleaned year `y'..."

    tempfile dict_y
    use "`dict'", clear
    keep if year == `y'
    keep original_varname canonical_varname canonical_label_zh
    sort original_varname
    by original_varname: keep if _n == 1
    save `dict_y', replace

    use "`cleanroot'/`y'sd_cleaned.dta", clear

    preserve
        use `dict_y', clear
        quietly count
        local n = r(N)
        forvalues i = 1/`n' {
            local ov_`i' = original_varname[`i']
            local cv_`i' = canonical_varname[`i']
            local lb_`i' = canonical_label_zh[`i']
        }
    restore

    forvalues i = 1/`n' {
        capture confirm variable `ov_`i''
        if !_rc {
            if "`ov_`i''" != "`cv_`i''" {
                capture confirm variable `cv_`i''
                if _rc {
                    rename `ov_`i'' `cv_`i''
                }
            }
        }

        capture confirm variable `cv_`i''
        if !_rc capture label variable `cv_`i'' `"`lb_`i''"'
    }

    save "`outroot'/`y'sd_cleaned_true_unified.dta", replace
}

log close
exit
