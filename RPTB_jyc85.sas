%LET job=RPTB;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

*proc printto log="&outdir/Logs/&job._&onyen..log" new; *run; 

*********************************************************************
*  Assignment:    RPTB                           
*                                                                    
*  Description:   PROC REPORT Produce METS Table 2.2 
*
*  Name:          Joyce Choe
*
*  Date:          4/2/2024                                     
*------------------------------------------------------------------- 
*  Job name:      RPTB_jyc85.sas   
*
*  Purpose:       PROC REPORT 
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         METS > mhxa_669, dr_669 data
*
*  Output:        RTF file    
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer mprint;

libname mets "~/my_shared_file_links/klh52250/METS" access=readonly;

* Subset data set for needed variables;
data merge_trt_mhxa;
	merge mets.dr_669 mets.mhxa_669;
	by BID;
	keep BID mhxa25-mhxa32 trt; *keep needed variables;
run;

* Freq tables for counts and percentages;
%macro mhxa(d);
proc freq data=merge_trt_mhxa noprint;
	table trt*mhxa&d / totpct nocol outpct missprint out=trtm&d;
	table trt / out=trtfreq;
run;

data trtmm&d;
	set trtm&d;
	where ^missing(mhxa&d);
run;

title "trt*mhxa&d";
proc print data=trtmm&d;
run;

%mend mhxa;

%mhxa(d=25); 
%mhxa(d=26); 
%mhxa(d=27); 
%mhxa(d=28);
%mhxa(d=29); 
%mhxa(d=30); 
%mhxa(d=31); 
%mhxa(d=32);

title "trt";
proc print data=trtfreq;
run;

* add variable for total n=;
proc sql;
	create table trtfreqsum as
	select *, SUM(COUNT) as Total
	from trtfreq;
quit;

* store N= counts in macro;
data _null_;
	set trtfreqsum;
	if trt='A' then call symput('m',strip(put(COUNT,3.)));
	if trt='B' then call symput('p',strip(put(COUNT,3.)));
	call symput('t',strip(put(Total,3.)));
run;
%put m=&m p=&p t=&t;


* create npct values for table; 
%macro table(d);

data mhxa_np&d;
	set trtmm&d(keep=trt mhxa&d count pct_row);
	length npct $10;
    npct=STRIP(PUT(count,3.)) || ' (' || STRIP(PUT(pct_row,5.1)) || ')'; *concatenate n (%);
	if MHXA&d='A';
run;

proc sql;
	create table mhxa_sum&d as
	select *, SUM(COUNT) as counta, (CALCULATED counta)*100/&t as perca
	from mhxa_np&d;
quit;

data mhxa_sumc&d(keep=trt MHXA&d npct totnpct counta);
	set mhxa_sum&d;
	length totnpct $10;
    totnpct=STRIP(PUT(counta,3.)) || ' (' || STRIP(PUT(perca,5.1)) || ')'; *concatenate n (%);
run;

proc sort data=mhxa_sumc&d;
	by MHXA&d;
run;
proc transpose data=mhxa_sumc&d out=mhxa_t&d prefix=trt;
	by MHXA&d;
	id trt;
	var npct totnpct counta;
run;

data mhxa_edit&d;
	set mhxa_t&d;
	if missing(mhxa&d) then delete;
	
	if mhxa&d = 'A' then do;
		mhxa = "&d" ;
	end;
	rename _NAME_ = calc;
run;

%mend table;

%table(d=25); 
%table(d=26); 
%table(d=27); 
%table(d=28);
%table(d=29); 
%table(d=30); 
%table(d=31); 
%table(d=32);

* combine all 8 mhxa cols;
data mhxa_all;
	set mhxa_edit25-mhxa_edit32;
	by mhxa;
run;

* subset total column;
proc transpose data=mhxa_all out=mhxa_total(keep=mhxa totnpct);
	by mhxa;
	id calc;
	var trtA trtB;
run;

proc sort data=mhxa_total nodupkey;
	by mhxa;
run;

* subset counta (order) column;
proc transpose data=mhxa_all out=mhxa_order(keep=mhxa counta);
	by mhxa;
	id calc;
	var trtA trtB;
run;

proc sort data=mhxa_order nodupkey;
	by mhxa;
run;

* merge for proc report data set;
data mhxa_report (keep=mhxa totnpct counta trtA trtB);
	merge mhxa_all(where=(calc='npct')) mhxa_total mhxa_order;
	by mhxa;
run;

* sort order descending;
proc sort data=mhxa_report out=mhxa_reports;
	by descending counta;
run;

* make table labels;
proc format;
   value $label
      '25' = 'Abnormal General Appearance/Skin'
      '26' = 'Abnormal HEENT'
      '27' = 'Abnormal Cardiovascular'
      '28' = 'Abnormal Chest'
      '29' = 'Abnormal Abdominal'
      '30' = 'Abnormal Extremities/Joints'
      '31' = 'Abnormal Neurological'
      '32' = 'Abnormal Physical Exam Other';
run; 

* table proc report;
ODS RTF FILE="&outdir/Output/&job._&onyen..RTF" style=journal bodytitle;

title1 'Table 2.2: METS Baseline Physical Exam - Systematic Inquiry';
title2 ' ';
proc report
	data=mhxa_reports nowd split = "|";
	columns mhxa totnpct trtA trtB;
	define mhxa / display "|N (%)" format=$label. style(header)=[just=right];
	define totnpct / display center "Total|N=&t" style=[backgroundcolor=cxDDDDDD];
	define trtA / display center "Metformin|N=&m";
	define trtB / display center "Placebo|N=&p";
footnote1 "Participants could have experienced more than one medical disorder.";
footnote2 "Job &job._&onyen run on &sysdate at &systime";

run;

* stuck on last two row order
realize that last two rows should be reversed, think it has to do with mhxa32 missing values....;



ODS RTF CLOSE;

*proc printto; *run; 