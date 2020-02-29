capture program drop table_lasso
program define table_lasso, eclass
	syntax varlist ,  path_file_tex(string) name_tex(string) treatment(varname) ////
			[ caption(string) col_labels(string)  indep(varlist)  ////
			lasso_control(varlist) fix_effect(varlist) ////
			notes(string)  absorbvar(varlist) notesw(string) indep_toshow(varlist) ////
			table_float(string) show_nr_nonzero_obs(string) cluster(varlist) ///
			extravar1(varname) extravar1_name(string) //// 
			extravar2(varname) extravar2_name(string) //// 
			extravar3(varname) extravar3_name(string) //// 
			extravar4(varname) extravar4_name(string) //// 
			extravar5(varname) extravar5_name(string) //// 
			extravar6(varname) extravar6_name(string) //// 
			extravar7(varname) extravar7_name(string) ////
			extravars_num(integer 0) fmt_digits(string)]

	
	local nb_col 1 
	local cols "l"
	if "`notesw'" == ""{
		local notesw "13cm"
		} 
	if "`fmt_digits'" == ""{
		local fmt_digits 2 
	}
	if "`table_float'" == ""{
		local table_float "H"
	}
	
	local name_tex_label = subinstr("`name_tex'","_",".",.)

	foreach v of varlist `varlist'{
		local nb_col = `nb_col' + 1
		sum `v'
			if `r(mean)' > 1000{
				local cols "`cols' C{1.9cm}"
			}
			else{
				local cols "`cols' C{1.7cm}"
			}
		}
		
	local end_postfoot "\bottomrule \end{tabular} \footnotesize \begin{tabular}{p{13cm}}{\textbf{Note:} `notes' } \end{tabular} \end{table}"
	local postfoot_panelB "`end_postfoot'"

	* Create summary stats of extra variables to add to the table
	local extravars_list
	local extravars_list_names 
	local extravars_format
	
	if `extravars_num' >0 {
		forvalues i = 1/`extravars_num' {
			local extravars_list "`extravars_list' meanC`i'"
			local extravars_list_names `" `extravars_list_names' "`extravar`i'_name'" "'
			local extravars_format "`extravars_format' `fmt_digits'"
		}
		di `extravars_list_names'
	}
		
	local stats_panel_obs_only `"stats(Nobs, fmt(0) labels("\textit{N}"))"'
	
	* Set up contents of final statistics panel
	if "`show_nr_nonzero_obs'"=="yes" { // display nr of non-zero observations
		local stats_panel `"stats(meanC `extravars_list' nonzero Nobs, fmt(`fmt_digits' `extravars_format' 0 0) labels("Control Dep Var Mean" `extravars_list_names' "Nr of Non-Zero Obs" "\textit{N}"))"'
	}
	else { // do not display number of non-zero observations
		local stats_panel `"stats(meanC `extravars_list' Nobs, fmt(`fmt_digits' `extravars_format' 0) labels("Control Dep Var Mean" `extravars_list_names' "\textit{N}"))"'
	}
		
	local stats_panelC `"stats(meanC `extravars_list' Nobs, fmt(`fmt_digits' `extravars_format' 0) labels("BL Control Dep Var Mean" `bl_extravars_list_names' "\textit{N}"))"'

	
******* Panel A: Without Control
eststo clear
foreach var of varlist `varlist' {
		eststo: reghdfe `var' `treatment', absorb(`absorbvar') vce(cluster `cluster')
		estadd scalar Nobs = `e(N)'
		sum `var' if `treatment' == 0
		estadd scalar meanC = round(`r(mean)', 0.01)
		count if `var' > 0 & !missing(`var')
		estadd scalar nonzero = `r(N)'

		* Create summary stats of extra variables to add to the table
		if `extravars_num' > 0 {
			forvalues i = 1/`extravars_num' {
				sum `extravar`i'' if `treatment'==0
				estadd scalar meanC`i' = round(`r(mean)', 0.01)
			}
		}
	}
	esttab using "`path_file_tex'/regtab_pA_`name_tex'.tex", replace frag style(tex) ///
		booktabs star(* .1 ** .05 *** .01) nonotes nomtitles se parentheses collabels(none)  ///
		cells(b(fmt(`fmt_digits')) se(fmt(`fmt_digits') star par)) keep(`treatment') ///
		`stats_panel' label  ///
		prehead(\begin{table}[`table_float'] \centering \caption{`caption'} \label{"`name_tex_label'"} \small \begin{tabular}{`cols'}  \cmidrule{2-`nb_col'} \\ `col_labels' \\ \midrule ///
				\multicolumn{`nb_col'}{l}{\textit{\textbf{Panel A: Without Controls}}}\\ \midrule) ///


******* Panel B: With Lasso Selected Controls
eststo clear   
foreach var of varlist `varlist' {
		eststo: pdslasso `var' `treatment' (`lasso_control' `fix_effect'), partial(`fix_effect') cluster(`cluster')
		estadd local Nobs = `e(N)'
		sum `var' if `treatment' == 0
		estadd scalar meanC = round(`r(mean)', 0.01)
		count if `var' > 0 & !missing(`var')
		estadd scalar nonzero = `r(N)'

		* Create summary stats of extra variables to add to the table
		if `extravars_num' > 0 {
			forvalues i = 1/`extravars_num' {
				sum `extravar`i'' if `treatment'==0
				estadd scalar meanC`i' = round(`r(mean)', 0.01)
			}
		}
	}
	esttab using "`path_file_tex'/regtab_pB_`name_tex'.tex", replace frag style(tex) ///
		booktabs star(* .1 ** .05 *** .01) nonotes nomtitles se parentheses mlabels(none) collabels(none)  ///
		cells(b(fmt(`fmt_digits')) se(fmt(`fmt_digits') star par)) eqlabels(none) keep(`treatment') ///
		`stats_panel'  label ///
		prehead( \\ \midrule \multicolumn{`nb_col'}{l}{\textit{\textbf{Panel B: With Control}}} \\ \midrule ) ///
		postfoot( \bottomrule \end{tabular} \footnotesize \begin{tabular}{p{`notesw'}}{\textbf{Note:} `notes' } \end{tabular} \end{table})

end
