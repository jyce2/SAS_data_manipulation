%LET job=ADSA2;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    ADSA                        
*                                                                    
*  Description:   Analysis Data Sets, Problem 4 (Program 2 of 2)
*
*  Name:          Joyce Choe
*
*  Date:          2/23/2024                                     
*------------------------------------------------------------------- 
*  Job name:      ADSA2_jyc85.sas   
*
*  Purpose:       Use a shared macro program and test with a data set 
*			      to report results about excluding conditions  
*			      
*  Language:      SAS, VERSION 9.4  
*
*  Input:         1. Exclude_data_using_conditions_for_669.sas (macro)
*			  	  2. lib.chd_record (data set from step 2)
*
*  Output:        RTF file    
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

libname chd "~/my_shared_file_links/klh52250/CHD" access=readonly;
libname lib "/home/u63543840/BIOS669/Data";

%include "/home/u63543840/my_shared_file_links/klh52250/macros/Exclude_data_using_conditions_for_669.sas";
%exclude_data_using_conditions(_DATA_IN= lib.chd_record,
							   _USE_PRIMARY_EXCLUSIONS = Yes,
							   _PRIMARY_EXCLUSIONS = race ^in ('B','W') ~ ^((Gender='M' and 600<TotCal<4200) | (Gender='F' and 500<TotCal<3600)),
 							   _SECONDARY_EXCLUSIONS = missing(BMI) ~ missing(DietMg) ~ missing(SerumMg),
							   _PREDICTORS = race gender age BMI prevalentCHD,
							   _CATEGORICAL = race gender prevalentCHD,
 							   _ID = ID,
							   _TITLE1 = lib.chd_record>);


proc printto; run; 