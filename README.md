# stata_sample_code

This folder has my Stata sample code (cleaning, and analysis do files) and ado files that written to prepare summary statistics and tables. This is usually how my project folder is organized. 
Based on the different project, the folder structure might change slightly. Additional folders (such as documentation folder to save all project documentation, survey instrument folder to save all 
surveyCTO excel files) might be created accordingly.


## Folder Structure

- `1_data`: has the "raw" data folder, and "cleaned" data folder (for security, no data uploaded yet).
- `2_dofiles`: folders to put all the dofiles
  - `0_master.do`: set up globals, loading packages. You can execute this do file directly without opening the data cleaning and analysis dofile. You can also compile the latex file here. 
  - `01_data_cleaning`: taking the raw data from 1_data/raw and cleaning the dataset, save the cleaned the dataset to 1_data/cleaned.
  - `02_data_analysis`: analysis of the cleaned dataset (summary statistics, balance table, regression, and figures).
  - `logs`: log file folder. All the saved log files can be put here.
  - `_archive`: any archived dofiles can be put here.
- `3_tables`: have the analysis output in latex format and save in this folder.
- `4_figures`: all output figures.
- `5_documents`: has related documents and latex files in this folder. The latex file is taking tables from table folder, and figures from figure folder and compile them together into a PDF file.
- `ado`: this folder has all the ado files that written to help prepare the tables
  - `table_lasso`: run lasso regression. Two panels: panel A - regression without controls; panel B - regression with lasso selected control varaibles. 
  - `balance_table & add_lines_balance_table`: used to prepare balance checks. 
  - `statdesc_table_N_mean & add_line_stat_N_mean`: summary statistics table. You can adit this file accordingly to prepare complicated statistics tables.
  
Thanks!
