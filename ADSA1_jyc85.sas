%LET job=ADSA1;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    ADSA                       
*                                                                    
*  Description:   Analysis Data Sets, Problems 1-3, 5 (Program 1 of 2)
*
*  Name:          Joyce Choe
*
*  Date:          2/23/2024                                     
*------------------------------------------------------------------- 
*  Job name:      ADSA1_jyc85.sas   
*
*  Purpose:       1/5. Create two (indicator) variables to add to a data set
*			         and edit data set to keep information on
*			         ID, diuretic use, and lipid lowering medications
*			 	  2. Combine core, nutrition, measurements, 
*					 and new (meds) data sets
*				  3. Subset data set
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         CHD > medications_wide, core, nutrition, measurements
*
*  Output:        PDF file    
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

libname chd "~/my_shared_file_links/klh52250/CHD" access=readonly;
libname lib "/home/u63543840/BIOS669/Data";

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;


* 1 - Create two indicator variables (0 or 1) to add to a wide data set;

data lib.var_medications;
	set chd.medications_wide; 
	Diuretic=0;
	LipidLowerMed=0;
		array d num_drugcode1-num_drugcode17; 
		array drugcode drugcode1-drugcode17;
		do i=1 to 17;
		d{i} = input(drugcode{i}, comma9.); *Change from character variables and add numeric variable to use temporarily;
		if 380000 >= d{i} >= 370000 then Diuretic = 1;
		if d{i} = 390000 or d{i} = 391000 or d{i} = 240600 then LipidLowerMed = 1; 
		end;
	keep ID Diuretic LipidLowerMed;
run;

* one-way frequency tables;
title '1. lib.var_medications';
proc freq data=lib.var_medications;
	table Diuretic / missing;
	table LipidLowerMed / missing;
run;


* 2 - Combine data sets to form one record per person;

PROC SQL;
create table lib.chd_record (drop=ID1 ID2 ID3) as 		  
	select *
	from chd.core as a
		left join chd.nutrition(rename=(ID=ID1 Magnesium=DietMg))
		on a.ID = ID1 
		left join chd.measurements(rename=(ID=ID2 Magnesium=SerumMg))
		on a.ID = ID2 
		left join lib.var_medications(rename=(ID=ID3))
		on a.ID = ID3;
	reset; 
	update lib.chd_record				
		set Diuretic =  0, LipidLowerMed = 0		 /*update missing values to 0*/
		where Diuretic = . and LipidLowerMed = . ;
QUIT;

* check contents;
title '2. lib.chd_record';
proc contents data=lib.chd_record;
run;

* one-way frequency tables;
title '2. lib.chd_record';
proc freq data=lib.chd_record;
	table Diuretic / missing;
	table LipidLowerMed / missing;
run;


* 3 - Subset data set;

Data lib.chd_subset;
	set lib.chd_record;
	where ^missing(BMI) and ^missing(SerumMg) and ^missing(DietMg);
	if (Gender = 'F' and 500 < TotCal < 3600) or (Gender = 'M' and 600 < TotCal < 4200);
	if Race = 'B' or Race = 'W';
run;

* check contents;
title '3. lib.chd_subset';
proc contents data=lib.chd_subset;
run;

* one-way frequency tables;
title '3. lib.chd_subset';
proc freq data=lib.chd_subset;
	table Race / missing;
	table Gender / missing;
run;

* means;
title '3. lib.chd_subset';
proc means n nmiss mean min max;
	var TotCal BMI DietMg SerumMg;
run;

* 5 - Create two indicator variables (0 or 1) to add to a long data set;

proc transpose data=chd.medications_long out=transpose;
	by ID;
	var drugcode;
run;

data lib.var_medications2;
	set transpose; 
	Diuretic=0;
	LipidLowerMed=0;
		array d num_drugcode1-num_drugcode17;
		array c col1-col17;
		do i=1 to 17;
		d{i} = input(c{i}, comma9.); *Change from character variables and add numeric variable to use temporarily;
		if 380000 >= d{i} >= 370000 then Diuretic = 1;
		if d{i} = 390000 or d{i} = 391000 or d{i} = 240600 then LipidLowerMed = 1; 
		end;
	keep ID Diuretic LipidLowerMed;
run;

* one-way frequency tables;
title '5. lib.var_medications2';
proc freq data=lib.var_medications2;
	table Diuretic / missing;
	table LipidLowerMed / missing;
run;


title '5. Compare data sets';
proc compare base=lib.var_medications compare=lib.var_medications2;
run;


ODS PDF CLOSE;

proc printto; run; 