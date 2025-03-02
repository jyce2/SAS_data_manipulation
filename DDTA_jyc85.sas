%LET job=DDTA;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

*proc printto log="&outdir/Logs/&job._&onyen..log" new; *run; 

*********************************************************************
*  Assignment:    DDTA              
*                                                                    
*  Description:   Data-Driven Programming 
*
*  Name:          Joyce Choe
*
*  Date:          4/12/2024                                  
*------------------------------------------------------------------- 
*  Job name:      DDTA_jyc85.sas   
*
*  Purpose:       macro, PROC SQL, call execute, 
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         SQLE3 code
*
*  Output:        PDF file 
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

LIBNAME mimic "~/my_shared_file_links/klh52250/MIMIC" access=readonly;

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;


* subset data set for call execute input;
proc sql noprint;
	create table restrict_items as
        select *
        from mimic.d_items
        where ITEMID > 220000 and LINKSTO="chartevents" and PARAM_TYPE="N";

* macro program;
%MACRO avgtest(itemID);
proc sql;

    RESET NOPRINT;
	*;
    SELECT MEAN(VALUENUM) INTO :avgmeasure TRIMMED
        FROM MIMIC.CHARTEVENTS
        WHERE ITEMID = &itemID ;
        
    SELECT LABEL INTO :measurelabel TRIMMED
        FROM MIMIC.D_ITEMS
        WHERE ITEMID = &itemID;
        
    SELECT STD(VALUENUM) INTO :stdev TRIMMED
        FROM MIMIC.CHARTEVENTS
        WHERE ITEMID = &itemID;

 	RESET NOPRINT;
 	*;
   	CREATE TABLE test&itemID as
    SELECT C.SUBJECT_ID, 
           A.HADM_ID,
           A.DIAGNOSIS, 
           MEAN(C.VALUENUM) AS meanValue format=7.2
        
        FROM MIMIC.CHARTEVENTS C, 
             MIMIC.ADMISSIONS A

            WHERE C.ITEMID = &itemID AND
                  C.SUBJECT_ID = A.SUBJECT_ID AND
                  C.HADM_ID = A.HADM_ID
                  
            GROUP BY C.SUBJECT_ID, A.HADM_ID, A.DIAGNOSIS
            
            HAVING meanValue > (&avgmeasure + 3*&stdev) OR meanValue < (&avgmeasure - 3*&stdev)
          
            ORDER BY C.SUBJECT_ID, a.hadm_id;
quit;     

* warning from title possible; 
title "Patients with &measurelabel (&itemID) having 
mean +/-3 sd than overall mean: %SYSFUNC(PUTN(&avgmeasure, 7.2)) +/- %SYSFUNC(PUTN(&stdev, 7.2))";

   
   proc print data=test&itemID;
	var SUBJECT_ID HADM_ID DIAGNOSIS meanValue;
	where ^missing(&avgmeasure) AND ^missing(&stdev);
	run;

%MEND;


* call execute;
data _null_;
    set restrict_items;
    call execute('%nrstr(%avgtest('||strip(itemID)||'))'); 
run;


* SOLUTION KEY;
%MACRO aboveAverageMeasure(itemID=);
    DATA OUT_OF_RANGE; SET _NULL_; RUN; /*Clear dataset from previous run*/

    PROC SQL NOPRINT; 
        /*include label in all outputs*/
        SELECT LABEL INTO :measurelabel trimmed from mimic.d_items where itemid=&itemid;

        /*Then, determine if ITEMID exists in current CHARTEVENTS data to avoid unnecessary steps*/
        SELECT COUNT(*) into :id_count trimmed from MIMIC.CHARTEVENTS where itemid= &itemid and ^missing(valuenum); 
            %put &id_count;

        %if &id_count in(0 1) %then %do; 
            %let row_count = NA; 
        %end; 
        %else %do; 
            SELECT MEAN(VALUENUM) INTO :average TRIMMED
                FROM MIMIC.CHARTEVENTS
                WHERE ITEMID = &itemID; 
            SELECT MEAN(VALUENUM)+(3*STD(VALUENUM)) INTO :three_sd_above TRIMMED
                FROM MIMIC.CHARTEVENTS
                WHERE ITEMID = &itemID;
            SELECT MEAN(VALUENUM)-(3*STD(VALUENUM)) INTO :three_sd_below TRIMMED
                FROM MIMIC.CHARTEVENTS
                WHERE ITEMID = &itemID;   

            CREATE TABLE out_of_range AS
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
                        
                        HAVING (.z < meanValue < &three_sd_below) or (meanValue > &three_sd_above > .z)
                        
                        ORDER BY C.SUBJECT_ID, a.hadm_id;


                SELECT COUNT(*) INTO :row_count trimmed FROM out_of_range; 

            %end; 
    QUIT; 

    /*Based on number of rows, write appropriate message to the log*/
    %if &row_count = 0  %then %put ++++++++++++ %superq(measurelabel) (&itemid) has no extreme values per the stated criteria. ++++++++++++; 
    %else %if &row_count = NA %then %put ++++++++++++ Not enough %superq(measurelabel) (&itemid) present in the current CHARTEVENTS data (run on &sysdate). ++++++++++++; 
    %else %do; 
        title "Patients with recorded %superq(measurelabel) (&itemID) greater than three standard deviations from the average recorded measurement over all patients:  %SYSFUNC(PUTN(&average, 7.2))";
        title2 "Acceptable range: %SYSFUNC(PUTN(&three_sd_below, 7.2)) - %SYSFUNC(PUTN(&three_sd_above, 7.2))";
            proc print data=out_of_range; 
            run; 
        title;
    %end;

%MEND;



ods pdf file="&outdir\&job._&onyen..pdf" style=journal;
data _null_;
    set mimic.d_items; 
    where param_type="N" and itemid > 220000 and linksto = "chartevents";

   call execute(  '%nrstr(%aboveAverageMeasure)(itemid='
                   ||strip(put(itemid,8.))||
                  ');'
                );

run;





ods pdf close;

*proc printto; *run; 
