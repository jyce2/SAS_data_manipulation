%LET job=MTDC;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

*proc printto log="&outdir/Logs/&job._&onyen..log" new;* run; 

*********************************************************************
*  Assignment:    MTDC                            
*                                                                    
*  Description:   Metadata C
*
*  Name:          Joyce Choe
*
*  Date:          4/26/2024                                     
*------------------------------------------------------------------- 
*  Job name:      MTDC_jyc85.sas   
*
*  Purpose:       Create a beginner-level codebook using metadata-based techniques
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         METS > DEMA_669 data set
*
*  Output:        PDF file and log
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer mprint;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

libname mets "~/my_shared_file_links/klh52250/METS" access=readonly;

ods pdf file="&outdir/Output/&job._&onyen..PDF" style=JOURNAL startpage=no;
ods noproctitle;

* codebook loop of variables; 
%macro codebookloop;

	*macro var variable;
	proc sql noprint;
	    select name into :var separated by ','
	        from dictionary.columns
	        where upcase(libname)='METS' and upcase(memname)='DEMA_669'
	        order by name;
		%let totalvar= &sqlobs;
	    reset noprint;
	    
	* macro date variable;
		select name into :datevar separated by ','
			from dictionary.columns
        	where upcase(libname)='METS' and upcase(memname)='DEMA_669'
        	and (index(format,'DATE')>0 or index(format,'MMDDYY')>0)
        	order by name;
		%let totaldate= &sqlobs;
       	reset noprint;
   	
   	* macro label variable;
		select label into :varlabel separated by ','
			from dictionary.columns
        	where upcase(libname)='METS' and upcase(memname)='DEMA_669'
        	order by name;
       	reset noprint;

		quit;
	%put &var are &totalvar total variables;
	%put &datevar are &totaldate total date variables;
	
	* begin loop here to separate vars for using in functions;
	%do i=1 %to &totalvar;
		
		* scan through total var;
		%let each= %scan(%bquote(&var), &i, %str(,));
		%put &each;
		
		%let lab= %scan(%bquote(&varlabel), &i, %str(,));
		%put &lab;
		
	* macro variable count N;
	proc sql noprint; 
	select count(distinct &each) into :noobs separated by ', '
		from mets.dema_669;
	quit;
	
	%put &each has &noobs unique values; 
	%put &each=&datevar is a date variable;
	
	* macro variable type (note: vtype is numeric);
	data _null_;
		set mets.dema_669;
		type = vtype(%nrbquote(&each));
		call symputx("vartype", type);
		stop;
	run;
	
	%put &each &vartype &lab;
	
	%do j=1 %to &totaldate;
		
		* scan through total date var;
		%let dv= %scan(%bquote(&datevar), &j, %str(,));
		%put &dv;
	
	
	%if &vartype=N and &each=&dv %then %do;
		ods startpage=now;
	title "&datevar (&vartype) &lab n=&noobs";
		proc tabulate data=mets.dema_669;
		var &each;
		table &each,
		n nmiss (min max median)*f=date9. range;
		run;
	title;
	%end;
	
	%else %if &vartype=N and &noobs > 6 %then %do; 
		ods startpage=now;
		title "&each (&vartype) &lab N=&noobs";
		ods noproctitle;
		proc means data=mets.dema_669 n nmiss mean min max;
			var &each;
		run;
		title;
	%end;
	
	%else %if &vartype=N and &noobs <=6 %then %do; 
		ods startpage=now;
		title "&each (&vartype) &lab N=&noobs";
		ods noproctitle;
		proc freq data=mets.dema_669;
			table &each / missing;
		run;
		title;
	%end;
	
	%else %if &vartype=C and &noobs <=6 %then %do; 
		ods startpage=now;
		title "&each (&vartype) &lab N=&noobs";
		ods noproctitle;
		proc freq data=mets.dema_669;
			table &each / missing;
		run;
		title;
	%end;

	%else %if &vartype=C and &noobs >6 %then %do; 
	ods startpage=now;
    proc odstext; 
        p "Variable &each not tabulated; all or most values unique" / style=[fontsize=11pt fontweight=bold fontfamily=Arial]; 
    run;
    %end;
    
    %else %put Check variable &each;
	%end;
	%end;

%mend codebookloop;

%codebookloop;



ods pdf close;

*proc printto;* run; 



