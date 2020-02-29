********************************************************************************
/* 	
*	Filename: 		01_data_cleaning.do

*	Purpose:		Clean the raw before runing analysis

*	Created by: Hongdi Zhao
*	Created on: Feb 2020
*	Last updated on: Feb 2020

* 	Input data: "$data/0_raw/data_raw.dta"
* 	Output data: "$data/1_clean/data_analysis.dta"


	Sections:
		1: Error Corrections
		2: Re-labeling, Recoding Missing
		3: Generate Variables
		4: Top Code Variables

*/
********************************************************************************


//	Setup

	clear
	capture log close
	set more off
	set mem 100m
	version 14
	

* 	Copy this .dofile to archive
	local doname "01_data_cleaning"
	copy "$do/`doname'.do" "$do/_archive/`doname'_$date.do", replace
	
	
* 	Use log file
	log using "$logs/`doname'_$date", replace
	
	
	
*===============================================================================*
*		SECTION 1: Error Corrections
*===============================================================================*
	
	use "$data/0_raw/data_raw.dta", clear
	
	
* 	Duplicates and Stop Midway Cleaning
	/* Instead of manually correcting variables, here used readreplace command.
	   All the variables that need to correct, and the keys are in the excel 
	   file. */ 

	readreplace using "$docs/manual_corrections.xlsx", 		///
		id(key) var(variable) value(newvalue) excel 		///
		import(sheet(census) firstrow)	
		
		
		
*===============================================================================*
*		SECTION 2: Re-labeling, Recoding Missing
*===============================================================================*	


* 	Recoding Missing Values

	ds, has(type numeric)
	foreach var in `r(varlist)'{
		di "`var'"
		local newlabel: value label `var'
		di "`newlabel'"
			replace `var' = .d if `var' == -998
				cap lab def `newlabel' .d "-998 Don't Know (.d)", add
			replace `var' = .r if `var' == -999
				cap lab def `newlabel' .r "-999 Refused to Answer (.r)", add
			replace `var' = .o if `var' == -997
				cap lab def `newlabel' .o "-997 Other (.o)", add
			replace `var' = .n if `var' == -996
				cap lab def `newlabel' .n "-996 None (.n)", add	
			replace `var' = .c if `var' == -90
				cap lab def `newlabel' .c "-90 Can't Say (.c)", add
	}
	
	
	
			
*===============================================================================*
*		SECTION 3: Generate Additional Variables
*===============================================================================*	
	
	* Household Consumption
	
		* Essential goods over 7 days:
			#delimit;
				egen conso_ess7d = rowtotal(	conso_dryfruits7d
												conso_groundnuts7d
												conso_onions7d
												conso_tomatoes7d
												conso_otherveg7d
												conso_cooldrinks7d
												conso_tea7d
												conso_coffee7d
												conso_dairy7d														
												conso_otherprocfood7d   ) , m 
				;
				#delimit cr
				
		* Essential goods over 30 days:	
				gen conso_ess30d = conso_ess7d*4
	
		* Total consumptio over 30 days:
			#delimit;
				egen totalcon_exp30d = rowtotal(conso_ess30d conso_staple30d 
												conso_meatfish30d conso_outmeal30d 
												conso_tobpdt30d conso_sweetpdt30d 
												conso_liquor30d religionexp30d 
												educ_exp30d), m
				;
				#delimit cr

		
	* Aggregated Income
	
		bys hhid: egen hhinc_bus30d = total(inc_bus30d)
		bys hhid: egen hhinc_bus12m = total(inc_bus12m)
		bys hhid: egen hhexp_bus30d = total(exp_bus30d)
		bys hhid: egen hhexp_bus12m = total(exp_bus12m)
		bys hhid: egen hhw_bus = total(w_bus)
	
	
	* Self-emp types 
	
		local selfemptype selfemptype4021 selfemptype4022 selfemptype4023 selfemptype4024
		forvalues i = 1/4 {
			replace selfemptype402`i' = -888 if selfemptype402`i'==.f
		}
		egen selfemptype_1_retailshop = 	anymatch(`selfemptype'), values(1)
		egen selfemptype_2_wholesale = 	anymatch(`selfemptype'), values(2)
		egen selfemptype_3_mill = 	anymatch(`selfemptype'), values(3)
		egen selfemptype_4_pawn = 	anymatch(`selfemptype'), values(4)
		egen selfemptype_5_agriinput = 	anymatch(`selfemptype'), values(5)
		egen selfemptype_6_repairshop = 	anymatch(`selfemptype'), values(6)
		egen selfemptype_888_other = 	anymatch(`selfemptype'), values(-888)

	
	* label 
		lab var hhinc_bus30d 	"Business income (30days)"
		lab var hhinc_bus12m 	"Business income (12mo, derived)"
		lab var hhexp_bus30d	"Business expenditure (30days)"
		lab var hhexp_bus12m 	"Business expenditure (12mo, derived)"
		lab var conso_ess7d 	"Total Consumptions (7days)"
		lab var conso_ess30d 	"Total Consumptions (30days)"
		lab var selfemptype_1_retailshop "HH self-emp or owns business: retail shop"
		lab var selfemptype_2_wholesale  "HH self-emp or owns business: wholesale shop"
		lab var selfemptype_3_mill 	 	 "HH self-emp or owns business: mill owner"
		lab var selfemptype_4_pawn 	 	 "HH self-emp or owns business: pawnshop "
		lab var selfemptype_5_agriinput  "HH self-emp or owns business: agri input shop"
		lab var selfemptype_6_repairshop "HH self-emp or owns business: cycle/auto repair shop"
		lab var selfemptype_7_fruit 	 "HH self-emp or owns business: fruit vendor"
		lab var selfemptype_8_veg 		 "HH self-emp or owns business: veg vendor"
		lab var selfemptype_9_meat 	 	 "HH self-emp or owns business: meat seller"		
		lab var selfemptype_888_other 	 "HH self-emp or owns business: other"

		

			
*===============================================================================*
*		SECTION 4: Top Code Variables
*===============================================================================*
	
	* For variables that are both surveyed in BL and EL
	qui foreach var of varlist hhinc_* totalcon_exp30d /// self reported
							totformalborrow_24 totinformalborrow_24 totvalcrop338 ///
							s_* p_* hhexp_* male_* female_* {
							
		no di "... Topcoding: `var' "
		
		* Top-coding based on unconditional mean
		* Top-coding is seperated from BL and EL

		************************* Baseline **************************
		* Post is 0
		sum `var' if post ==0, det			
		
		* Create top-coded & trimmed variables
		gen `var'_99 = `var'
			replace `var'_99 = `r(p99)' if (`var' > `r(p99)') & !missing(`var') & post ==0
		gen `var'_sd = `var'
			replace `var'_sd = `r(mean)' + 3 * `r(sd)' if (`var' > `r(mean)' + 3 * `r(sd)') & !missing(`var') & post ==0
		gen `var'_99t = `var'
			replace `var'_99t = .t if (`var' > `r(p99)') & !missing(`var') & post ==0
		gen `var'_sdt = `var'
			replace `var'_sdt = .t if (`var' > `r(mean)' + 3 * `r(sd)') & !missing(`var') & post ==0
		
		
		************************* Endline **************************
		* Post is 1
		sum `var' if post == 1, det			
		
		* Create top-coded & trimmed variables
			replace `var'_99 = `r(p99)' if (`var' > `r(p99)') & !missing(`var') & post == 1
			replace `var'_sd = `r(mean)' + 3 * `r(sd)' if (`var' > `r(mean)' + 3 * `r(sd)') & !missing(`var') & post == 1
			replace `var'_99t = .t if (`var' > `r(p99)') & !missing(`var') & post == 1
			replace `var'_sdt = .t if (`var' > `r(mean)' + 3 * `r(sd)') & !missing(`var') & post == 1

		* Label
		local labvar: var label `var'
		lab var `var'_99 "`labvar' - topcoded (pct99)"
		lab var `var'_99t "`labvar' - trimmed (pct99)"
		lab var `var'_sd "`labvar' - topcoded (3sd)"
		lab var `var'_sdt "`labvar' - trimmed (3sd)"
	}
	


//	Save the data for analysis
	save "$data/1_clean/data_analysis.dta", replace

	
	log close
	
