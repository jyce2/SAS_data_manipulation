%LET job=MTDA;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

*proc printto log="&outdir/Logs/&job._&onyen..log" new; *run; 

*********************************************************************
*  Assignment:    MTDA                             
*                                                                    
*  Description:   Metadata A 
*
*  Name:          Joyce Choe
*
*  Date:          4/17/2024                                     
*------------------------------------------------------------------- 
*  Job name:      MTDA_jyc85.sas   
*
*  Purpose:       1. Macro (ds) if/else ds exists to log
				  2. Macro (numeric var) if/else GT/LE 6 unique values to log
				  3. Macro (var) type and label to log
				  4. Macro (var) type and label to print file output
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         BIOS511 > CARS2011 data set
*
*  Output:        PDF file and log
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer mprint;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

libname bios511 "~/my_shared_file_links/klh52250/BIOS511" access=readonly;
libname lib "/home/u63543840/BIOS669/Data";

* I plan to present my final project. Thanks!; 

ods pdf file="&outdir/Output/&job._&onyen..PDF" style=JOURNAL;

* 1;
%macro exist(ds=);
	data _null_;
		dsid = open("&ds");
		nobs = attrn(dsid, 'nobs');
		call symputx("numobs", nobs);
		rc = close(dsid);
	run;
	
	%if %sysfunc(exist(&ds))=1 %then %do;
	
	%put "data set &ds. exists and has &numobs observations";
	%end;
	 	
	%else %do; 
	 	
	%put "data set &ds. does not exist";
	%end;
%mend;

%exist(ds=sashelp.class);	
%exist(ds=sashelp.cllas);	


*2; 
%let cars=bios511.cars2011;

ods noproctitle;
%macro numeric(var=);
	* macro variable noobs to count unique values in &var;
	proc sql noprint;
		select count(distinct &var) into :noobs
		from &cars;
	quit;
	* macro variable type, note- vtype is numeric;
	data _null_;
		set &cars;
		type = vtype(&var);
		call symputx("numtype", type);
		stop;
	run;

	%if &noobs <= 6 and &numtype=N %then %do;
		title "&var freq output";
		proc freq data=&cars;
			table &var / missing;
		run;
	%end;
	
	%else %if &noobs > 6 and &numtype=N %then %do;
		title "&var means output";
		proc means data=&cars;
			var &var;
		run;
	%end;
	
	%else %put 'character variable-not numeric';
%mend;

%numeric(var=hwyMPG);
%numeric(var=satisfaction);
%numeric(var=make);
	
	
*3;
proc format;
	value $typing C='Character'
				  N='Numeric';
run;

%macro varlog(var=);
	data _null_;
	
		* open ds;
		dsid=open("&cars");
		
		* macro variable type with format;
		vtype = vartype(dsid, varnum(dsid, "&var"));
		
		call symputx("showtype",put(vtype, $typing.));
		
		* macro variable label;
		vlabel = varlabel(dsid, varnum(dsid, "&var"));
		call symputx("showlabel", vlabel);
		
		* close ds;
		rc= close(dsid);	
	run;
	
	%put "&showtype variable &var is labeled &showlabel";
%mend;

%varlog(var=baseMSRP);
%varlog(var=Model);


*4;
%macro varfile(var=);
	data _null_;
	file print;
		* open ds;
		dsid=open("&cars");
		
		* macro variable type with format;
		vtype = vartype(dsid, varnum(dsid, "&var"));
		
		call symputx("showtype", put(vtype, $typing.));
		
		* macro variable label;
		vlabel = varlabel(dsid, varnum(dsid, "&var"));
		call symputx("showlabel", vlabel);
		
		* close ds;
		rc= close(dsid);	
	run;
	
	proc odstext;
  		p "&showtype variable &var is labeled &showlabel";
	run;
%mend;


%varfile(var=seating);
%varfile(var=type);



*ods pdf close;

*proc printto; *run; 
