********************************************************************************
/* 	
*	Filename: 		02_data_analysis.do

*	Purpose:		Using cleaned data for analysis

*	Created by: Hongdi Zhao
*	Created on: Feb 2020
*	Last updated on: Feb 2020


	Sections:
		1: Overall Summary
		2: Balance Check
		3: Regression Analysis
		4: Figures

*/
********************************************************************************

//	Setup

	clear
	capture log close
	set more off
	set maxvar 10000
	version 14
	

* 	Copy this .dofile to archive
	local doname "02_data_analysis"
	copy "$do/`doname'.do" "$do/_archive/`doname'_$date.do", replace
	
	
	
* 	Use log file
	log using "$logs/`doname'_$date", replace

	
	
*===============================================================================*
*		SECTION 1:  Overall Summary
*===============================================================================*
	
	use "data/cleaned/data_analsyis.dta", clear

*	Village Summary	
	gen total = 1
	tab survey_status, gen(survey_status_)
	
	lab var survey_status_1 "Complete"
	lab var survey_status_2 "Ineligible"
	lab var survey_status_3 "Eligible for Revisit"
	lab var survey_status_4 "Not Consent/Revoke Consent Midway"
	lab var total "Total"
	

	estpost tabstat survey_status_* total, by(village) stat(sum)
	matrix A = e(survey_status_1)', e(survey_status_2)', e(survey_status_3)', e(survey_status_4)', e(total)'
	esttab matrix(A) using "$tables/tab1-sum-byvillage.tex", replace ///
		booktab title("Completed Survey Status by Village\label{tab1-sum-byvillage}") label nomtitles ///
		collabels("Complete" "Ineligible" "Eligible for Revisit" "Not Consent/Revoke Consent Midway" "Total")

	
*	Consent survey
	tab consent, gen(consent_)
	
	gen survey_status_1_c = (survey_status_1 & consent == 1)
	gen survey_status_2_c = (survey_status_2 & consent == 1)
	gen survey_status_3_c = (survey_status_3 & consent == 1)
	gen survey_status_4_c = (survey_status_4 & consent == 1)

	estpost tabstat consent_1 consent_2 ///
		survey_status_1_c survey_status_2_c survey_status_3_c survey_status_4_c ///
		, by(calc_dt) stat(sum)
	
	matrix A = e(consent_1)', e(consent_2)', e(survey_status_1_c)', ///
		e(survey_status_2_c)', e(survey_status_3_c)', e(survey_status_4_c)'
	
	esttab matrix(A) using "$tables/tab1-consent.tex", replace ///
		booktab title("Consent to Survey\label{tab1-consent}") label nomtitles ///
		collabels("Not Consent" "Consented" "[Complete" "Ineligible" "Eligible for Revisit" "Revoke Consent Midway]")
			
		

*===============================================================================*
*		SECTION 2: Balance Check
*===============================================================================*	


	local balancetable 1
	if `balancetable' {
	
	preserve 

		* Only Baseline 
		keep if post == 0
			
		* HOUSEHOLD LEVEL
		
		* Panel A: Predetermined Demographic Characteristics
		local varlist_demo gender_hoh educyears_hoh hhnomembers ///
					  hhcaste_mbc hhcaste_sc_st hhownland ///
					femalerespage yrsedufemaleresp 
				
		local labvarlist_demo "Demographics"
		
		lab var gender_hoh "Household Head is Male"
		lab var educyears_hoh "Years of Education of Household Head"
		lab var hhnomembers "Number of Household Members"
		lab var	hhcaste_mbc "Most Backward Caste"
		lab var hhcaste_sc_st "Scheduled Caste and Tribe"
		lab var hhownland "Household Own Land"
		lab var femalerespage "Female Respondent Age"
		lab var yrsedufemaleresp "Female Respondent Years of Education"

					
		* Panel B: Income & Consumption Table
		local varlist_income total_consoexp30d_sd hhinc_sr_sdt ///
							bplwb_conso_r_sdt bplwb_r_sdt 
		
		local labvarlist_income "Income \& Consumption Outcomes"
		lab var total_consoexp30d_sd "Tot HH Consumption (30-day), top-coded"
		lab var hhinc_sr_sdt "Tot HH Income (30-day), top-coded"
		lab var bplwb_conso_r_sdt "Below Poverty Line (using Consumption)"
		lab var bplwb_r_sdt "Below Poverty Line (using Income)"

			
		* Panel C: Borrowing \& Saving \& Insurance Table
		local varlist_loans formalloan_hh informalloan_hh ///
				 activeinsurance saveacctamt_sd ///
				informal_outstnd_ratio
				
		local labvarlist_loans "Borrowing \& Saving \& Insurance Outcomes"
		
		lab var formalloan_hh "Household has Outstanding Formal Loan(s)"
		lab var informalloan_hh "Household has Outstanding Informal Loan(s)"
		lab var saveacctamt_sd "Tot. Savings Amt (Rs)"
		lab var activeinsurance "Household Has Active Insurance"
		lab var informal_outstnd_ratio "Informal Share of Tot. Outstnd Ratio"
		lab var formal_outstnd_ratio "Formal Share of Tot. Outstnd Ratio"
		
		
		* Balance Table (used the ado program written previosly)
		balance_table `varlist_demo',  path_file_tex("$tables/tab2-balancetable.tex") treatment(treated) ///
				caption("Baseline Balance Checks") ///
				varlist1_lab("Panel A: `labvarlist_demo'")  ///
				varlist2(`varlist_income') varlist2_lab("Panel B: `labvarlist_income'")  ///
				varlist3(`varlist_loans') varlist3_lab("Panel C: `labvarlist_loans'")  ///
				notes( ***(**)(*) indicates significance at the 1\%(5\%)(10\%) level. ///
				Column [1] reports control group means, with standard deviations in  ///
				parentheses. Column [2] reports the OLS coefficient estimates   ///
				associated with regressing each outcome on a dummy indicating 	///
				treatment. Pair fixed effects are included. Standard errors are ///
				clustered at the service area level. Column [3] reports the number ///
				of observations. All Rs. values are top-coded three standard ///
				deviations from the mean, unless otherwise specified.)
					
	restore
}


		
*===============================================================================*
*		SECTION 3: Regression Analyis
*===============================================================================*	


	* Fix effect
	tab pair_id, gen(PAIRID_)
	tab survey2, gen(SURVEY2_)
	local strata PAIRID_* SURVEY2_*
	
	* Control variables
	local varcontrols ///
		age_hoh_c missing_age_hoh /// head of household age
		educyears_hoh_c missing_educyears_hoh /// head of household years of education
		hhcaste_mbc_c missing_hhcaste_mbc /// most backward caste
		hhcaste_sc_st_c missing_hhcaste_sc_st /// scheduled caste and tribe
		hhownland_c2 missing_hhownland /// household land ownership
		hhnomembers_c missing_hhnomembers 
		
	* Table Notes
	#delimit ;
	local notes_incpove "***, **, * indicates significance at the 1\%, 5\%, 
				and 10\% level respectively. OLS estimates (standard errors) 
				are reported from regressing each dependent variable on a 
				dummy indicating whether the household resides in a treated 
				service area.";
	#delimit cr
	
	
	* Household Income, Consumption and Borrowing
	local inc_conso_lasso 1
	if `inc_conso_lasso' {

	preserve 
	
		* Only use endline data for analysis, control variables are all from baseline
		keep if post == 1 
		
		* Generate variables for table
			* Log income - top-coded
			gen loghhinc_sr_sd = log(hhinc_sr_sd + 1)
			replace loghhinc_sr_sd = . if hhinc_sr_sd == .

			* Log household consumption - top-coded
			gen logtotconsoexp30d_sd = log(totalcon_exp30d_sd + 1)
			replace logtotconsoexp30d_sd = . if totalcon_exp30d_sd == .
			
	
		* Outcome Variable list for table
			local varlist loghhinc_sr_sd logtotconsoexp30d_sd totformalborrow_24_sd totinformalborrow_24_sd
		
		* Declare column labels
		#delimit ;
			local collabel " & Log Tot HH Income (Last 30 days) & Log Tot HH 
						Consumption (Last 30 days) & Total Formal Borrowed Loan 
						(24 month) & Total Informal Borrowed Loan (24 month)";
		#delimit cr
		
			* Generate table (used the ado program prepared previously)
			
			/* table_lasso: flexible ado files that can used to prepare two 
			   pabel tables (Panel A: without control variable, Panel B: with
			   control varaible). The number of columns will change accroding 
			   to the total number of outcome varairables. */
			   
			table_lasso `varlist', col_labels("`collabel'") ///
				path_file_tex("$tables") name_tex("incpov") ///
				treatment(treated) lasso_control(`varcontrols') fix_effect(`strata') ///
				caption("Impact on Income and Borrowing") ///
				notes("`notes_incpove'") notesw("13cm") ///
				fmt_digits(2) cluster(group_id) absorbvar(pair_id)
	
	
	restore
}
	
	
	
*===============================================================================*
*		SECTION 4: Figures
*===============================================================================*	
		
	
*	Geo-location graph of households
	
	* Change lat to XY
	geo2xy a_gpslatitude a_gpslongitude, gen(y x) proj(mercator)
	sum y
	replace y = (y - `r(min)')/1000
	sum x
	replace x = (x - `r(min)')/1000

	cap set scheme pih

	twoway (scatter y x if calc_dt == "23-02-2020") ///
			(scatter y x if calc_dt == "24-02-2020") ///
			(scatter y x if calc_dt == "25-02-2020") ///
			(scatter y x if calc_dt == "26-02-2020") ///
		, ytitle(Latitude (KMs)) xtitle(Longitude (KMs)) ///
		legend(order(- "Survey Days" 1 "Day 1" 2 "Day 2" 3 "Day 3" 4 "Day 4")) ///
		title("GPD Coordinates Check") ///
		note("This figure is used to check the GPS Coordinates." ///
			"If the coordinates are too far way from most of other coordinates, then it might not correct." ///
			"There are `num_miss' out of `total' households that surveyor did not record location coordinates.")
	
	
	graph export "$figures/gps_check_pilot.png", replace
	graph export "$figures/gps_check.png", replace
	
	log close
	
	
	*******************
	***	 By Village ***
	*******************
	
	* Village: Gehri Bara Singh
	preserve 
	
		keep if village == 1
		
		count if missing(y)
		local num_miss = "`r(N)'"
		count
		local total = "`r(N)'"
		
		twoway  (scatter y x if calc_dt == "23-02-2020") ///
			(scatter y x if calc_dt == "24-02-2020") ///
			(scatter y x if calc_dt == "25-02-2020") ///
			(scatter y x if calc_dt == "26-02-2020") ///
		, ytitle(Latitude (KMs)) xtitle(Longitude (KMs)) ///
		legend(order(- "Survey Days" 1 "Day 1" 2 "Day 2" 3 "Day 3" 4 "Day 4")) ///
			title("GPD Coordinates Check - Gehri Bara Singh") ///
			note("This figure is used to check the GPS Coordinates." ///
			"If the coordinates are too far way from most of other coordinates, then it might not correct." ///
			"There are `num_miss' out of `total' households that surveyor did not record location coordinates.")
			
		graph export "$figures/gps_check_pilot_1.png", replace
		
	restore
	
	* Village:  Gurusar 
	preserve 
	
		keep if village == 2
		
		count if missing(y)
		local num_miss = "`r(N)'"
		count
		local total = "`r(N)'"
		
		twoway (scatter y x if calc_dt == "23-02-2020") ///
			(scatter y x if calc_dt == "24-02-2020") ///
			(scatter y x if calc_dt == "25-02-2020") ///
			(scatter y x if calc_dt == "26-02-2020") ///
		, ytitle(Latitude (KMs)) xtitle(Longitude (KMs)) ///
		legend(order(- "Survey Days" 1 "Day 1" 2 "Day 2" 3 "Day 3" 4 "Day 4")) ///
			title("GPD Coordinates Check -  Gurusar") ///
			note("This figure is used to check the GPS Coordinates." ///
			"If the coordinates are too far way from most of other coordinates, then it might not correct." ///
			"There are `num_miss' out of `total' households that surveyor did not record location coordinates.")
			
		graph export "$figures/gps_check_pilot_2.png", replace
		
	restore		

	
	log close
	