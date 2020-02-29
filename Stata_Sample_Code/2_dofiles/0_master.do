********************************************************************************
/*       
*       Filename: 	0_master.do

*       Purpose:	This is the Master .do file 
					
					The .do should be run at the start of any Stata session
					to set up relative directories and flag issues that can
					prevent code from running in the files (e.g. ensuring that
					boxcryptor is set up and the encrypted PII data is 
					accessible). 
					
* 		About the study: These do files are used to analysis a RCT study in
					Southern India.
							

*       Created by: Hongdi Zhao (alisa.hdzhao@gmail.com)
*       Created on: 20 Feb 2020
*       Last updated on: 20 Feb 2020
*/
********************************************************************************

//	Setup

	clear
	capture log close
	set more off
	set mem 100m
	version 14
	macro drop _all
	
	
*===============================================================================*
*	SECTION 1: Set up directories and macros                                 
*===============================================================================*
	
 
* Local Macros for this .do File
	local  doname "0_master"
    local  packages "estout dataout sxpose labmask orth_out labvalch3 texify renvars"    // Insert all known ssc packages that are used (not vital, but helps avoid errors)                 
 
 
* Change directory to current folder (add your username and path)
        if "`c(username)'" == "hz394"  {
			global main "C:/Users/hz394/Dropbox/Hongdi Zhao/projectfolder"
			global encrypted "X:/Dropbox/Hongdi Zhao/projectfolder"	// Boxcryptor directory
		}
		
	   else {
			global main ""      
			global encrypted ""	
		}

 
* Trip error if no directory specified
	if "$main" == "" {
		di 	as error 	"No directory specified. See above."
		error 198
	}
	
	if "$encrypted" == "" {
		di 	as error 	"No Boxcryptor directory specified. See above."
		* No error needed: You may not need to have Boxcryptor installed.
	}
	

		
* Set global paths to main directories
		global	data			"$encrypted/1_data"	// Use boxcryptor by default

		
* Set global paths to main directories
        cd "$main"               	
 
		global	do				"2_dofiles"
		global	tables 			"3_tables"
		global 	figures			"4_figures"
		global	logs			"2_dofiles/logs"
		global 	docx			"5_documents"
		global 	ado				"ado"
		
		
* Global date for archiving
        global date=strofreal(date(c(current_date), "DMY"),"%td_CCYYNNDD")

		
* Check that packages used in this .do file are installed. Install if not.
	 foreach package in `packages' {
			 cap which `package'
			 if _rc cap ssc install `package'  // 111 is the return code for a missing package
			 if _rc {
				di as error "You must install `package'"
				search `package'
			 }
		}

		
* Ensure all users are using the plotplainblind scheme
	 cap set scheme plotplainblind
	 if _rc {
		di as error "You need to install the plotplainblind scheme, available from package gr0070"
		ssc install blindschemes
		set scheme plotplainblind
	 }
	 
	 
*===============================================================================*
*	SECTION 2: Point Stata to the ado folder and copy latest program versions                          
*===============================================================================*

* Add ado directory
	adopath + "$ado"
		
 
	exit
*===============================================================================*
*	SECTION 3: Execute data cleaning workflow                               
*===============================================================================*


*	Run .do files
	qui do "$do/01_data_cleaning.do"
	qui do "$do/02_data_analysis.do"



*	Run LaTeX files for reports
	texify "$docx/summary_report.tex"
	
	