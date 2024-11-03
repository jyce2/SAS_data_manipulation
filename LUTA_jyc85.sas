%LET job=LUTA;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    LUTA                              
*                                                                    
*  Description:   Look-up table techniques 
*
*  Name:          Joyce Choe
*
*  Date:          2/20/2024                                     
*------------------------------------------------------------------- 
*  Job name:      LUTA_jyc85.sas   
*
*  Purpose:       1. Subset data set to METS medication to be classified (n=186).
*				  2. Copy in look up table as data set.
*				  3. Create 3 identical data sets with select METS medication
*				  classified as 'HIGH', 'LOW', or blank using look up table.
*				  4. Examine results.
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         1. METS > OMRA data set 
*				  2. Look-up table (Weight-liability medication)
*
*  Output:        1. Data set files (.sas7bdat)
*				  2. PDF file    
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

libname mets "~/my_shared_file_links/klh52250/METS" access=readonly;
libname lib "/home/u63543840/BIOS669/Data";

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;

* 1 - Subset data;
data classifymeds; 
	set mets.omra_669;
	where OMRA5A='Y' and OMRA4='06';
	WtLiabMed = scan(OMRA1,1, " -"); /*Make a new variable containing 1st word from OMRA1 variable*/
	keep BID WtLiabMed;
run;

* Remove duplicates to get a unique combination of BID*meds;
proc sort data=classifymeds out=lib.selectmeds nodupkey;
	by BID WtLiabMed;
run;

* 2 - Input/copy data from look-up table to make a new data set;
data lookup;
	length med $25 class $4;
	input med class;
	cards;
CLOZAPINE HIGH 
ZYPREXA HIGH 
RISPERIDONE HIGH 
SEROQUEL HIGH
INVEGA HIGH
CLOZARIL HIGH
OLANZAPINE HIGH
RISPERDAL HIGH 
ZIPREXA HIGH 
LARI HIGH
QUETIAPINE HIGH
RISPERDONE HIGH
RISPERIDAL HIGH
RISPERIDOL HIGH
SERAQUEL HIGH
ABILIFY LOW 
GEODON LOW
ARIPIPRAZOLE LOW 
HALOPERIDOL LOW 
PROLIXIN LOW 
ZIPRASIDONE LOW 
GEODONE LOW 
HALDOL LOW
PERPHENAZINE LOW
FLUPHENAZINE LOW 
THIOTRIXENE LOW
TRILAFON LOW
TRILOFAN LOW 
;
run;

* Sort by med to merge; 
proc sort data=lookup out=lib.lookup;
	by med;
run;


* 3 - Table look-ups: 
* Method 1 - DATA step MERGE;
* Rename variable to same name variable as in the look up table,
also sort to merge by this variable;
proc sort data=lib.selectmeds(rename=(WtLiabMed=med)) out=selectmeds;
	by med;
run;

* Merge presorted datasets by the same variable, 
then include only values that were in the first(main) data set;
data lib.mergecodes1;
	merge selectmeds(in=infirst) lib.lookup(keep=med class);
	by med;
	if infirst;
run;

* Reverse variable name to original variable name, 
then sort merged data set;
proc sort data=lib.mergecodes1(rename=(med=WtLiabMed)rename=(class=class1));
	by BID WtLiabMed;
run;


* Method 2 - PROC SQL JOIN;
PROC SQL;

	create table lib.mergecodes2(rename=(class=class2)) as 		  
		select BID, first.WtLiabMed, lookup.class /*select variables for merged data set*/
		from lib.selectmeds as first		  	  /*join two data sets*/
	left join lib.lookup as lookup 		  
		on first.WtLiabMed = lookup.med 	      /*join by matching value*/
	order by BID, WtLiabMed; 					  /*sort*/

QUIT;							  

* Method 3 - DATA step hash object;
DATA lib.mergecodes3;
	if _N_=1 then do;
	length med $1000 class $100; 			  /*initialize value and code variables from lookup data set*/
	declare HASH obj(dataset:'lib.lookup');   /*hash object from lookup data set*/
		obj.DEFINEKEY('med');  		  	  	  /*define code variable, matching first data set*/
		obj.DEFINEDATA('class'); 			  /*define value variable*/
		obj.DEFINEDONE(); 
	call missing(med, class); 				  /*stop running by setting variables to missing*/
	end;
	set lib.selectmeds;						  
	rc=obj.FIND(KEY:WtLiabMed);				  /*match hash object with first data set variable*/
	drop rc med;						  	  /*drop unneeded variables*/
RUN;

proc sort data=lib.mergecodes3(rename=(class=class3));
	by BID WtLiabMed;
run;

* 4 - Examine results;
* a;
title 'Crosstab of class*med';
proc freq data=lib.mergecodes3; 
	table class3*WtLiabMed / list missing;
run;

*b;
data mergecodes_all;
	merge lib.mergecodes1 lib.mergecodes2 lib.mergecodes3;
	by BID WtLiabMed;
run;

title 'Crosstab of all classes*med';
proc freq data=mergecodes_all;
	tables class1*class2*class3 / list missing;
run;

*c;
title 'Not classfied as HIGH or LOW';
PROC SQL;
	select BID, WtLiabMed
	from lib.mergecodes1
	where class1 ^in('HIGH', 'LOW');
QUIT;


ODS PDF CLOSE;

proc printto; run; 