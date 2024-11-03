%LET job=SQLD3;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    SQLD Problem 3                         
*                                                                    
*  Description:   MIMIC patients who went to more than one different ICU care unit
*
*  Name:          Joyce Choe
*
*  Date:          2/1/2024                                      
*------------------------------------------------------------------- 
*  Job name:      SQLD3_jyc85.sas   
*
*  Purpose:       PROC SQL query/subquery
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         MIMIC > icustays data set
*
*  Output:        PDF file     
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";
LIBNAME mimic "~/my_shared_file_links/klh52250/MIMIC" access=readonly;

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;


* Care unit formats; 

PROC FORMAT;
value $cunit
	'MICU' = 'Medical intensive care unit'
	'CSRU' = 'Cardiac surgery recovery unit'
	'SICU' = 'Surgical intensive care unit'
	'CCU' = 'Coronary care unit'
	'TSICU' = 'Trauma/surgical intensive care unit';
RUN;


* Query;

PROC SQL number;
TITLE "MIMIC patients who went to more than one different ICU care unit";
	SELECT DISTINCT FIRST_CAREUNIT format=$cunit., SUBJECT_ID
	FROM mimic.icustays
		GROUP BY SUBJECT_ID
		HAVING COUNT(DISTINCT(FIRST_CAREUNIT))> 1
			ORDER BY SUBJECT_ID;
QUIT;
	
	
ODS PDF CLOSE;

proc printto; run; 