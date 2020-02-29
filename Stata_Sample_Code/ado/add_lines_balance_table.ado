cap prog drop add_lines_balance_table
prog add_lines_balance_table
	args file_path label_list var_list nb_col treatment controls1 controls2
	cap file close file_to_fill
	file open file_to_fill using "`file_path'", write append
	file write file_to_fill _newline "\multicolumn{`nb_col'}{l}{\textbf{`label_list'}}\\" 
	set more off
	local stars 
	local n_control_varlist 1
	if "controls2" != "" {
		local n_control_varlist 2
		}
	qui foreach var in `var_list'{
		local varname `:var lab `var''
		no di "`varname'"
		if "`varname'" == ""{
			local varname "`var'"
			}
		local varname = subinstr("`varname'","_","\_",.)
		local varname = subinstr("`varname'","%","\%",.)
		no sum `var'
		sca Ntot = `r(N)'
		sum `var' if `treatment' == 0
		sca NC = `r(N)'
		sca mean_varC = `r(mean)'
		sca sd_varC = `r(sd)'
		sum `var' if `treatment' == 1
		sca NT = `r(N)'
		qui forval i = 1/`n_control_varlist'{
			reg `var' `treatment' `controls`i'', vce(cluster group_id) 
			mat est_b = e(b)
			mat est_V = e(V)
			sca t_effect`i' = est_b[1,1]
			sca se_coeff`i' = sqrt(est_V[1,1])
			test `treatment'  == 0	
			if `r(p)'> 0.1 {
				sca stars`i' =""
				}
			if `r(p)'<=0.1 {
				sca stars`i'="$^{\star}$"
				}
			if `r(p)'<=0.05 {
				sca stars`i' = "$^{\star \star}$"
				}
			if `r(p)'<=0.01 {
				sca stars`i' = "$^{\star \star \star}$"
				}
			}

		file write file_to_fill _newline  "\hspace{0.4cm} `varname' & " %7.2f (mean_varC) "& " %7.2f (t_effect1) (stars1) "& " %7.0f (Ntot) "\\" 
		file write file_to_fill	_newline  " &[" %7.2f (sd_varC) " ]& (" %7.2f (se_coeff1) " ) & \\" 

		}
	file write file_to_fill _newline "\multicolumn{`nb_col'}{l}{}\\" 
	file close file_to_fill
	set more on
end
