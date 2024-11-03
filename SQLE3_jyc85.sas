%LET job=SQLE3;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

*proc printto log="&outdir/Logs/&job._&onyen..log" new; *run; 

*********************************************************************
*  Assignment:    SQLE Problem 3                           
*                                                                    
*  Description:   List all admitted patients with mean chart measurement 
*			  	  above overall mean in MIMIC
*
*  Name:          Joyce Choe
*
*  Date:          2/6/2024                                      
*------------------------------------------------------------------- 
*  Job name:      SQLE3_jyc85.sas   
*
*  Purpose:       PROC SQL Macro variable, Merge, Matching
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         MIMIC > CHARTEVENTS, ADMISSIONS, D_ITEMS
*
*  Output:        PDF file     
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";
LIBNAME mimic "~/my_shared_file_links/klh52250/MIMIC" access=readonly;

*ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;

%macro mean_value(itemID=);

PROC SQL NOPRINT NUMBER;
* Macro variable for overall average measurement;
	SELECT MEAN(A.VALUENUM) INTO :meanoverall
	FROM mimic.chartevents AS A,
		 mimic.d_items AS B
	WHERE A.ITEMID = B.ITEMID = &itemID;

* Macro variable for item label;
	SELECT B.LABEL INTO :itemlabel
	FROM mimic.chartevents AS A, 
	     mimic.d_items AS B 
	WHERE A.ITEMID = B.ITEMID = &itemID;
	RESET PRINT;
	
* From this point on, print SQL output;	
	TITLE "Patients with mean value above overall mean: &meanoverall. for ID# &itemID. (&itemlabel.)";
	SELECT A.SUBJECT_ID,
		   A.HADM_ID,
		   C.DIAGNOSIS,
		   MEAN(A.VALUENUM) label "Mean Value of &itemlabel."
	FROM mimic.chartevents AS A, 
		     mimic.d_items AS B, 
		     mimic.admissions AS C
	WHERE A.ITEMID = B.ITEMID = &itemID AND 
		  A.SUBJECT_ID = C.SUBJECT_ID AND 
		  A.HADM_ID = C.HADM_ID
	GROUP BY A.HADM_ID,
		     A.SUBJECT_ID,
		     C.DIAGNOSIS 
/*stuck on special note 1, can't wait to fix it!*/
	HAVING MEAN(A.VALUENUM) > &meanoverall
	ORDER BY SUBJECT_ID, HADM_ID; 

QUIT;

%mend;

* Run macro input;
PROC SQL;

	%mean_value(itemID=220045);
	%mean_value(itemID=220179);

QUIT;


/* Solution Key

%MACRO aboveAverageMeasure(itemID=);

    RESET NOPRINT;

    SELECT MEAN(VALUENUM) INTO :avgmeasure TRIMMED
        FROM MIMIC.CHARTEVENTS
        WHERE ITEMID = &itemID;
        
    SELECT LABEL INTO :measurelabel TRIMMED
        FROM MIMIC.D_ITEMS
        WHERE ITEMID = &itemID;
        
    RESET PRINT NUMBER;

    TITLE "Patients with recorded &measurelabel (&itemID) greater than the average recorded measurement over all patients: %SYSFUNC(PUTN(&avgmeasure, 7.2))";
    
    SELECT C.SUBJECT_ID, 
           a.hadm_id,
           A.DIAGNOSIS, 
           MEAN(C.VALUENUM) AS meanValue "Average recorded measurement"
           
        FROM MIMIC.CHARTEVENTS C, 
             MIMIC.ADMISSIONS A
        
            WHERE C.ITEMID = &itemID AND
                  C.SUBJECT_ID = A.SUBJECT_ID AND
                  C.HADM_ID = A.HADM_ID
                
            GROUP BY C.SUBJECT_ID, a.hadm_id, A.DIAGNOSIS
            
            HAVING meanValue > &avgmeasure
            
            ORDER BY C.SUBJECT_ID, a.hadm_id;
        

%MEND;


ODS PDF FILE="&outdir\&job._&onyen..PDF" STYLE=JOURNAL;

PROC SQL;
	%aboveAverageMeasure(itemID=220045);
	%aboveAverageMeasure(itemID=220179);
QUIT;

*/


*ODS PDF CLOSE;

*proc printto; *run; 
