%LET job=SQLD2;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    SQLD Problem 2                           
*                                                                    
*  Description:   Max and mean length of ICU stay by 
*				  MIMIC patient/care unit compared to overall
*
*  Name:          Joyce Choe
*
*  Date:          2/1/2024                                      
*------------------------------------------------------------------- 
*  Job name:      SQLD2_jyc85.sas   
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

*Care unit formats; 

PROC FORMAT;
value $cunit
	'MICU' = 'Medical intensive care unit'
	'CSRU' = 'Cardiac surgery recovery unit'
	'SICU' = 'Surgical intensive care unit'
	'CCU' = 'Coronary care unit'
	'TSICU' = 'Trauma/surgical intensive care unit';
RUN;

*Queries on mimic.icustays;

*a;
PROC SQL number;
TITLE "Each patient's max length of stay";
	SELECT SUBJECT_ID, floor(MAX(LOS)) AS MAXLOS label 'Maximum length of stay (days)'
	FROM mimic.icustays
		GROUP BY SUBJECT_ID
		ORDER BY MAXLOS desc;

*b;
TITLE "Each care unit's max length of stay";
	SELECT FIRST_CAREUNIT format=$cunit., floor(MAX(LOS)) AS MAXLOS label 'Maximum length of stay (days)'
	FROM mimic.icustays
		GROUP BY FIRST_CAREUNIT
		ORDER BY MAXLOS desc;

*c;
TITLE "Each care unit's mean length of stay";
	SELECT FIRST_CAREUNIT format=$cunit., floor(MEAN(LOS)) AS MEANLOS label 'Average length of stay (days)'
	FROM mimic.icustays
		GROUP BY FIRST_CAREUNIT
		ORDER BY MEANLOS desc;
	
*d;
TITLE "Overall mean length of stay";
	SELECT floor(MEAN(LOS)) label 'Average length of stay (days)'
	FROM mimic.icustays;
	
*e;
TITLE "Care units where mean length of stay > overall mean";
	SELECT FIRST_CAREUNIT format=$cunit., floor(mean(LOS)) label 'Average length of stay (days)'
	FROM mimic.icustays
		GROUP BY FIRST_CAREUNIT
		HAVING MEAN(LOS) GT
			(SELECT MEAN(LOS)
			 FROM mimic.icustays);
QUIT;

ODS PDF CLOSE;

proc printto; run; 