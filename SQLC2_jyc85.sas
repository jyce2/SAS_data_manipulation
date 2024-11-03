%LET job=SQLC2;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    SQLC Problem 2                            
*                                                                    
*  Description:   Create MIMIC data set for RN caregiver schedule on 2/6/2107 
*
*  Name:          Joyce Choe
*
*  Date:          1/30/2024                                      
*------------------------------------------------------------------- 
*  Job name:      SQLC2_jyc85.sas   
*
*  Purpose:       Merge data sets with PROC SQL & PROC SORT/DATA STEPs
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         MIMIC > patients, admissions, chartevents, caregivers, d_items
*
*  Output:        PDF file     
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";
LIBNAME mimic "~/my_shared_file_links/klh52250/MIMIC" access=readonly;

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;

*2a) Merge data sets: PROC SQL;

PROC SQL number;
CREATE TABLE CSCHEDULE AS 
	SELECT A.SUBJECT_ID, B.ADMISSION_TYPE, A.GENDER, D.CGID, D.LABEL AS CAREGIVER, E.LABEL AS TASK, C.CHARTTIME
		FROM mimic.patients AS A, mimic.admissions AS B, mimic.chartevents AS C, mimic.caregivers AS D, mimic.d_items as E
		WHERE A.SUBJECT_ID = B.SUBJECT_ID = C.SUBJECT_ID AND 
			  C.CGID = D.CGID AND  
			  D.LABEL = 'RN' AND 
			  C.ITEMID = E.ITEMID AND 
			  DATEPART(C.CHARTTIME)='06FEB2107'd
		ORDER BY C.CHARTTIME, D.CGID, TASK;
QUIT;

* Print care giver schedule;
PROC PRINT data=cschedule (obs=10);
	title 'Caregiver schedule: 1st 10 observations';
RUN;

*2b) Merge same data sets: PROC SORT and DATA steps;

* Sort variables;
%MACRO sort(ds= , var= );
	PROC SORT data = mimic.&ds. out=s_&ds.;
	by &var ;
	RUN;
%MEND sort;

%sort(ds=patients, var= SUBJECT_ID);
%sort(ds=admissions, var= SUBJECT_ID);
%sort(ds=caregivers, var= CGID);
%sort(ds=chartevents, var= SUBJECT_ID CGID ITEMID);
%sort(ds=d_items, var= ITEMID);

* Merge data;
DATA dt1;
	MERGE s_patients(in=a)
		  s_admissions(in=b);
	BY SUBJECT_ID;
	IF (a=1 and b=1);
	
PROC SORT data= dt1 out=s_dt1;
	BY SUBJECT_ID;
RUN;

DATA dt2;
	MERGE dt1 (in=s_dt1)
		  s_chartevents(where=(DATEPART(CHARTTIME)='06FEB2107'd) in=c);
	BY SUBJECT_ID;
	IF (s_dt1=1 and c=1);

PROC SORT data=dt2 out=s_dt2;
	BY CGID;
RUN;

DATA dt3;
	MERGE s_dt2(in=s_dt2) s_caregivers(rename=(LABEL=CAREGIVER) in=d);
	BY CGID;
	IF CAREGIVER = 'RN';
	IF (s_dt2=1) and (d=1);

PROC SORT data=dt3 out=s_dt3;
	BY ITEMID;
RUN;

DATA dt4;
	MERGE s_dt3(in=s_dt3) s_d_items(rename=(LABEL=TASK) in=e);
	BY ITEMID;
	IF (s_dt3=1) and (e=1);
RUN;

PROC SORT data=dt4(keep=SUBJECT_ID ADMISSION_TYPE GENDER CGID CAREGIVER TASK CHARTTIME) out=cschedule2;
	BY CHARTTIME CGID TASK;
RUN;

* Print caregiver schedule;
PROC PRINT data=cschedule2 (obs=10);
	title 'Caregiver schedule: 1st 10 observations';
RUN;

*2c) Compare data sets: PROC COMPARE;

PROC COMPARE BASE=cschedule COMPARE=cschedule2 LISTALL;
	title 'Comparing caregiver schedules';
RUN;


ODS PDF CLOSE;

proc printto; run; 