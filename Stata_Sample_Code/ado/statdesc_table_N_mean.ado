capture program drop statdesc_table_N_mean
program define statdesc_table_N_mean, eclass
		
	syntax varlist [if/] [in],  path_file_tex(string) ///
			[LABvar caption(string) col_varlist(varlist) ////
			varlist1_lab(string) varlist2(varlist) varlist2_lab(string) ////
			varlist3(varlist) varlist3_lab(string) varlist4(varlist) varlist4_lab(string) ////
			varlist5(varlist) varlist5_lab(string) ////
			varlist6(varlist) varlist6_lab(string) ////
			varlist7(varlist) varlist7_lab(string) ////
			varlist8(varlist) varlist8_lab(string) ////
			varlist9(varlist) varlist9_lab(string) ////
			varlist10(varlist) varlist10_lab(string) ////
			varlist11(varlist) varlist11_lab(string) ////
			varlist12(varlist) varlist12_lab(string) ////
			varlist13(varlist) varlist13_lab(string) ////
			notes(string) fmt_digits(string) notesw(string)]
	local nb_col cols add_col add_numcol
	
	* A - Preambule of the Latex table
	***********************************
	* (a) Define characteristics of the table
	/* You may need to add on your general document Latex code:
	_newline "\usepackage{supertabular}" ///
	_newline "\usepackage{array}" ///
	*/
	local nb_col = 5
	local cols = "l ccccc"
	if "`notesw'" == ""{
		local notesw "17cm"
		} 
	if "`fmt_digits'"!="2" {
		local mean_fmt "0.001"
	}
	no di "`nb_col'"
	cap file close _all
	file open myfile using "`path_file_tex'", write replace 
	file write myfile "" ///
		_newline "\begin{center} " ///
		_newline "\tablefirsthead{\cmidrule{2-`nb_col'} \\ & \textbf{N} & \textbf{Female} & \textbf{Age} & \textbf{Caset SC ST} & \textbf{Hindu}\\ & [1] & [2] & [3] & [4] & [5] \\ \midrule \\} " /// 
		_newline "\tablehead{ \multicolumn{`nb_col'}{r}{\small\sl \ldots continued from previous page}\\ \cmidrule{2-`nb_col'}  \\ & \textbf{N} & \textbf{Female} & \textbf{Age} & \textbf{Caset SC ST} & \textbf{Hindu} \\& [1] & [2] & [3] & [4] & [5]  \\ \midrule \\}" ///
		_newline "\tabletail{\midrule \multicolumn{`nb_col'}{r}{\small\sl continued to next page\ldots}\\} \tablelasttail{\bottomrule} " ///
		_newline "\topcaption{`caption'}" ///
		_newline "\renewcommand{\arraystretch}{0.85}" ///
		_newline "\begin{supertabular}{`cols'}" 
	file close myfile
	

	* B - Add lines
	***************
	local varlist1 `varlist'
	set more off
	forvalues i=1/13{
		if "`varlist`i''" != ""{
			add_lines_stat_N_mean "`path_file_tex'" "`varlist`i'_lab'" "`varlist`i''" `nb_col' "`col_varlist'"
			}
		}
	set more on
	
	* C - Declare end of the table
	******************************
	file open myfile using "`path_file_tex'", write append
	file write myfile  " \end{supertabular}" ///
		_newline "\footnotesize \begin{tabular}{p{`notesw'}} " ///
		_newline "\textbf{Note :} `notes'" ///
		_newline "\end{tabular}" ///
		_newline " \end{center}" 
	file close myfile

end
