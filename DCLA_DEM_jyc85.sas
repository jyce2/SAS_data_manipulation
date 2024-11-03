%LET job=DCLA_DEM;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

*proc printto log="&outdir/Logs/&job._&onyen..log" new; *run; 

*********************************************************************
*  Assignment:    DCLA           
*                                                                    
*  Description:   Data cleaning "resp.dem2018"
*
*  Name:          Joyce Choe
*
*  Date:          3/1/2024                                   
*------------------------------------------------------------------- 
*  Job name:      DCLA_DEM_jyc85.sas   
*
*  Purpose:       Check data for cleaning
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         resp.dem2018 data set
*
*  Output:        PDF, RTF
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

libname resp "/home/u63543840/my_shared_file_links/klh52250/Resp";

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;
ODS RTF FILE="&outdir/Output/&job._&onyen..RTF" STYLE=JOURNAL;

proc format;
 	value m    	  . = 'Missing';
	value $m 	' ' = 'Missing';
run;

* A -  Check all chr variables by data collection form.;
title 'Character variables';
proc freq data=resp.dem2018(drop=fakeid);
	tables _character_ / missing nocum nopercent;
run;

title '"Invalid" observations from chr variables';
proc print data=resp.dem2018 n noobs;
	var _CHARACTER_;
    where notdigit(strip(FAKEID))>0 
    or length(FAKEID) NE 4
    or DEMA2 ^in('M','F')
    or verify(DEMA3,'YNUR')>0 
    or verify(DEMA5,'ACMOUR')>0 
    or verify(DEMA7,'YNUR')>0 
    or verify(DEMA8,'CTMRNDUO')>0 
    or verify(DEMA9,'ABCDEFGH')>0 
    or verify(DEMA11A,'YN')>0 
    or verify(DEMA11B,'YN')>0 
    or verify(DEMA11C,'YN')>0 
    or verify(DEMA4A,'YNUR')>0 
    or verify(DEMA4B,'YNUR')>0 
    or verify(DEMA4C,'YNUR')>0 
    or verify(DEMA4D,'YNUR')>0 
    or verify(DEMA4E,'YNUR')>0 
    or verify(DEMA4F,'YNUR')>0 
    or verify(DEMA6B,'KP')>0 
    or verify(DEMA6D,'CI')>0;
run; 

* B - Check numeric variables: AGE, DEMA6A, DEMA6C, FSEQNO, VISIT;
title 'Observations in num variables';
proc univariate data=resp.dem2018;
	ods select BasicMeasures Quantiles ExtremeObs;
	var _numeric_;
run;

title 'Age distribution';
proc sgplot data=resp.dem2018;
	histogram AGE/ scale=count;
run;

* Exlude missing values to plot with no warning;
data excludemissing;
	set resp.dem2018;
	where ^missing(DEMA6C) 
	and ^missing(DEMA6D) 
	and ^missing(DEMA6A)
	and ^missing(DEMA6B); 
run;

title 'Weight distribution by K(kg) or P(lb)';
proc sgplot data=excludemissing;
    vbox DEMA6A / group=DEMA6B;
	yaxis grid;
run;

title 'Height distribution by I(in) or C(cm)';
proc sgplot data=excludemissing;
     vbox DEMA6C / group=DEMA6D;
	yaxis grid;
run;

title '"Invalid" height obs';
proc freq data=excludemissing;
	table FAKEID*DEMA6C*DEMA6D / list nopercent;
	where (DEMA6C < 135 and DEMA6D = 'C') 
	or  (DEMA6C > 100 and DEMA6D = 'I');
run;

* C - Check for missing values where complete data is necessary;
* Gender, weight and height and their units of measure;

title '"Invalid/Missing" observations from num variables';
proc freq data=resp.dem2018;
	tables FAKEID*Age*DEMA6A*DEMA6B*DEMA6C*DEMA6D*FSEQNO*VISIT / missing list nopercent;
	where Age=0	
		or DEMA6B ^in('K','P')
		or DEMA6D ^in('C','I')
		or FSEQNO NE 0
		or VISIT NE 1
		or missing(DEMA2) 
		or missing(DEMA6A)
		or missing(DEMA6B)
		or missing(DEMA6C)
		or missing(DEMA6D);
	format DEMA2 $m.;
	format DEMA6B $m.;
	format DEMA6D $m.;
	format DEMA6A m.;
	format DEMA6C m.;
run;

* D - Check duplicate IDs; 
title 'Duplicate IDs by FAKEID, VISIT, and FSEQNO';
proc sort data=resp.dem2018 out=sorted dupout=dup nodupkey;
    by fakeid visit fseqno;
run;
proc print data=dup; *0 output - so no duplicates in data; 
run;

ODS PDF CLOSE;
ODS RTF CLOSE;

*proc printto;* run; 