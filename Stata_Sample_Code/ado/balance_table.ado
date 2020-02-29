capture program drop balance_table
program define balance_table, eclass

	syntax varlist [if/] [in],  path_file_tex(string) treatment(varname) ////
			[LABvar caption(string) controls1(string) controls2(string) collabels(string) ////
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
			varlist14(varlist) varlist14_lab(string) ////
			varlist15(varlist) varlist15_lab(string) ////
			varlist16(varlist) varlist16_lab(string) ////
			varlist17(varlist) varlist17_lab(string) ////
			panelA(string) panelA_loc(string) ////
			panelB(string) panelB_loc(string) ////
			panelC(string) panelC_loc(string) ////
			notes(string) ////
			base_group(string) comparison_group(string)]
	
	local nb_col cols add_col add_numcol
	
	* A - Preambule of the Latex table
	***********************************
	* (a) Define characteristics of the table
	/* You may need to add on your general document Latex code:
	_newline "\usepackage{supertabular}" ///
	_newline "\usepackage{array}" ///
	*/
	
	local nb_col = 4
	if "`base_group'"=="" {
		local base_group "Control"
	}
	if "`comparison_group'"==""{
		local comparison_group "Treatment"
	}
	local cols = "l C{2.5cm} C{2.5cm} C{2.5cm}"
	if "`collabels'" == ""{
		local collabels "\parbox[c]{2.5cm}{ \centering \textbf{`comparison_group'} \\ \vspace{2mm} Mean diff. (SE)}  & \parbox[c]{2.5cm}{ \centering Nr. Obs}"
		}
	local numbering "[2] & [3]"
	if "`controls2'" != ""{
		local nb_col = 5
		local cols = "l C{1.7cm} C{2.2cm} C{2.2cm} C{2.2cm}"
		local cols = "l cccc"
		if "`collabels'" == ""{
			local collabels "\parbox[c]{2.5cm}{ \centering \textbf{`comparison_group'} \\ \vspace{2mm} Mean diff. (SE)} &  \parbox[c]{2.5cm}{ \centering \textbf{`comparison_group'} \\ Mean diff. (SE)}"
		}
		local numbering "[2] & [3] & [4]"
		}
	no di "`nb_col'"
	cap file close _all
	file open myfile using "`path_file_tex'", write replace 
	

	file write myfile "" ///
		_newline "\begin{center} \footnotesize  " ///
		_newline "\tablefirsthead{ \cmidrule{2-`nb_col'} \\  & \parbox[c]{2.5cm}{ \centering \textbf{`base_group'} \\ \vspace{2mm} Mean [SD] } & `collabels' \\ \\ & [1] & `numbering' \\ \midrule } " ///
		_newline "\tablehead{  \multicolumn{`nb_col'}{r}{\small\sl \ldots continued from previous page}\\ \cmidrule{2-`nb_col'}  \\  & \parbox[c]{2.5cm}{ \centering \textbf{`base_group'} \\ \vspace{2mm} Mean [SD] } &  `collabels' \\ \\ & [1] & `numbering'  \\ \midrule }" ///
		_newline "\tabletail{\midrule \multicolumn{`nb_col'}{r}{\small\sl continued to next page\ldots}\\} \tablelasttail{\midrule \midrule} " ///
		_newline "\topcaption{`caption'}" ///
		_newline "\renewcommand{\arraystretch}{0.85}" ///
		_newline "\begin{supertabular}{`cols'}" 
	file close myfile

	
	* B - Add Lines
	***************
	* If table too long, will continue to next page
	
	local varlist1 `varlist'
	set more off
	forvalues i=1/10{
		if "`varlist`i''" != ""{
			foreach l in "A" "B" "C"{
				if "`panel`l'_loc'" == "`i'"{
					file open myfile using "`path_file_tex'", write append
					file write myfile "" ///
						_newline " \midrule \multicolumn{`nb_col'}{l}{ \textbf{Panel `l': `panel`l''}} \\ \midrule \midrule "
					file close myfile
					}
				}
			add_lines_balance_table "`path_file_tex'" "`varlist`i'_lab'" "`varlist`i''" `nb_col' `treatment' "`controls1'" "`controls2'"
			}
		}
	set more on
	
	
	* C - Declare End of The Table
	******************************
	file open myfile using "`path_file_tex'", write append
	file write myfile  " \end{supertabular}" ///
		_newline "\footnotesize \begin{tabular}{p{17cm}} " ///
		_newline "\textbf{Note :} `notes' "  ///
		_newline " \end{tabular} \end{center}" 
	file close myfile
end
