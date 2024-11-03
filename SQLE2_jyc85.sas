%LET job=SQLE2;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    SQLE Problem 2                            
*                                                                    
*  Description:   List of care units with mean length of stay 
*				  greater than overall mean length of stay in MIMIC
*
*  Name:          Joyce Choe
*
*  Date:          2/6/2024                                      
*------------------------------------------------------------------- 
*  Job name:      SQLE2_jyc85.sas   
*
*  Purpose:       PROC SQL Macro Variable
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         MIMIC > ICUSTAYS
*
*  Output:        PDF file     
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";
LIBNAME mimic "~/my_shared_file_links/klh52250/MIMIC" access=readonly;

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;

PROC SQL NOPRINT; 

* Macro variable for select overall mean;
	SELECT MEAN(LOS) AS MEAN_LOS format=8.1 INTO :mean_los 
		FROM MIMIC.ICUSTAYS;
	RESET PRINT;
	
* Reset sql to rerun with macro variable within same proc sql step; 
	TITLE "Care units with average length of stay greater than &mean_los. days";
	SELECT FIRST_CAREUNIT, MEAN(LOS) format=8.1 label 'Mean length of stay (days)' 
   	 	FROM MIMIC.ICUSTAYS
        GROUP BY FIRST_CAREUNIT
        HAVING MEAN(LOS) > &mean_los;
        
QUIT;

ODS PDF CLOSE;

proc printto; run; 
