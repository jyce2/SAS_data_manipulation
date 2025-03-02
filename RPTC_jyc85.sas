%LET job=RPTC;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    RPTC                          
*                                                                    
*  Description:   PROC REPORT 
*
*  Name:          Joyce Choe
*
*  Date:          4/5/2024                                     
*------------------------------------------------------------------- 
*  Job name:      RPTC_jyc85.sas   
*
*  Purpose:       PROC REPORT macro table (a) and customizing (b); 
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         'Customize comparison tables for clinical studies' macro (Polina), 
*				   RPTC data set
*
*  Output:        2 RTF files 
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;

libname ref "/home/u63543840/my_shared_file_links/klh52250/RPTC" access=readonly;
libname lib '/home/u63543840/BIOS669/Data/Macro';

* Part A;
%include '/home/u63543840/my_shared_file_links/klh52250/macros/Compare_baseline_669.sas';

%Compare_baseline_669 
(_DATA_IN=ref.rptc, 
_DATA_OUT=lib.rptc_macro, 
_NUMBER=1,
_group=trt, 
_predictors=race1 gender BMI cholesterol age heartrate,
_categorical=race1 gender,
_countable=Age HeartRate, 
_title1=Compare_baseline_characteristics macro,
_ID=BID);


* Part B; 
ods escapechar='#'; /*for indent space- see RPTC*/

proc format; 
value pvalue2_best 0-<0.001='<0.001' 0.001-<0.005=[5.3] 
0.005-<0.045= [5.2] 0.045-<0.055=[5.3] other=[5.2]; 
run;

* edit data set from macro;
data custom_rptc; 
	set lib.rptc_macro; 
	length characteristic $200; 
	if variable="RACE1" and label=" " then do; 
	characteristic="{\i \ul Baseline Characteristics\line \line \ul0 \i0 Race}"; 
	order=1;  
	pvalue=' ';
	end; 
	if variable="RACE1" and label="- Black" then do; 
	characteristic="#{nbspace 6}" ||"Black";
	order=2;
	end; 
	if variable="RACE1" and label="- Other" then do; 
	characteristic="#{nbspace 6}" ||"Other";
	order=3;
	end; 
	if variable="RACE1" and label="- White" then do; 
	characteristic="#{nbspace 6}" ||"White";
	order=4;
	end; 
	if variable="GENDER" and label="- F" then do; 
	characteristic="Female"; 
	order=5; 
	end;
	if variable="GENDER" and label="- M" then do; 
	characteristic="Male"; 
	order=6; 
	end;
	if variable="BMI" and label="Computed BMI (wt/ht2)" then do; 
	characteristic="{BMI (wt/ht\super 2}{)}"; 
	order=7; 
	end;
	if variable="AGE" and label="Age" then do; 
	characteristic="Age"; 
	order=9; 
	end;
	if variable="CHOLESTEROL" and label="Cholesterol(mg/dL)" then do; 
	characteristic="{Cholesterol(mg/dL)}"; 
	order=8; 
	end;
	if variable="HEARTRATE" and label="Heart Rate (beats/min)" then do; 
	characteristic="{Heart Rate (beats/min)}"; 
	order=10; 
	end;
	if missing(order) then delete;
run;

ods rtf file="/home/u63543840/BIOS669/Output/customised_table.RTF" style=journal bodytitle; 
ods listing; title; footnote; ods listing close;

title1 J=center height=12pt font='ARIAL' bold "Final Results Publication"; 
title2 J=center height=11pt bold font='ARIAL' "{Table 1. Characteristics of the Participants by Treatment Group}"; 

footnote1 J=left height=8.5pt font='ARIAL' "{Note: Values expressed as N(%), mean ± standard deviation or median (25\super th}{, 75\super th }{percentiles)}" ;
footnote2 J=left height=8.5pt font='ARIAL' "P-value comparisons across treatment groups for categorical variables are based on chi-square test of homogeneity; 
p-values for continuous variables are based on ANOVA or Kruskal-Wallis test for median" ; 
footnote3 J=left height=8.5pt font='ARIAL'" "; 
footnote4 J=right height=7pt font='ARIAL' "&sysdate, &systime -- Baseline Characteristics Macro"; 

%let st=style(column)=[just=center cellwidth=2.8 cm vjust=bottom font_size=8.5 pt] style(header)=[just=center font_size=8.5 pt];


* print custom table in proc report;
proc report data=custom_rptc nowd style=[cellpadding=6 font_size=8.5 pt rules=none]; 
	column order characteristic('Treatment Group' column_overall column_2 column_1 pvalue); 
	define order / order noprint; 
	define characteristic / display " " style=[just=left cellwidth=9.0 cm font_weight=bold font_size=8.5 pt asis=on]; 
	define column_2 / display "{Drug A\line (N=&count_2)}" &st ; 
	define column_1 / display "{Drug B\line (N=&count_1)}" &st ; 
	define column_overall / display "{Overall\line (N=&count_overall)}" &st; 
	define pvalue / display "{p-value}" format=pvalue2_best. style(column)=[just=right cellwidth=2 cm vjust=bottom font_size=8.5 pt] style(header)=[just=right cellwidth=2 cm font_size=8.5 pt] ;
run;


ods rtf close; ods listing;


proc printto; run; 
