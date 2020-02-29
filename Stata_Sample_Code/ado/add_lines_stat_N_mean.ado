cap drop prog add_lines_stat_N_mean
prog define add_lines_stat_N_mean
	args file_path label_list var_list nb_col col_varlist
	cap file close file_to_fill
	file open file_to_fill using "`file_path'", write append
	file write file_to_fill _newline "\multicolumn{`nb_col'}{l}{\textbf{`label_list'}}\\" 
	set more off
	foreach var in `var_list'{
		local varname `:var lab `var''
		no di "`varname'"
		if "`varname'" == ""{
			local varname "`var'"
			}
		local varname = subinstr("`varname'","_","\_",.)
		local varname = subinstr("`varname'","%","\%",.)
		local varname = subinstr("`varname'","'","",.)
		noi di "`varname'"
		
		qui count if `var' == 1
		file write file_to_fill _newline  "\hspace{0.4cm} `varname' & " %8.0f (`r(N)')
		local i 1
		foreach col in `col_varlist'{
		qui sum `col' if `var' == 1
			local mean_`i' `r(mean)'
			local i = `i' + 1
			file write file_to_fill _newline   " & " %8.2f (`r(mean)') 
		}
		qui count if `var' == 1
		
		file write file_to_fill _newline  " \\" 
		noi di "`varname'"
		}
	file write file_to_fill _newline "\multicolumn{`nb_col'}{l}{}\\" 
	file close file_to_fill
	set more on
end
