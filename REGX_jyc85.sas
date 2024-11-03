%LET job=REGX;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    REGX                                  
*                                                                    
*  Description:   An intro to regular expressions
*
*  Name:          Joyce Choe
*
*  Date:          2/15/2024                                      
*------------------------------------------------------------------- 
*  Job name:      REGX_jyc85.sas   
*
*  Purpose:       Output various regular expressions 
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         METS > OMRA_669 > OMRA1 variable 
*
*  Output:        PDF file    
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

LIBNAME mets "~/my_shared_file_links/klh52250/METS" access=readonly;

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;

* SAS RegEx macro program;

%MACRO find(q, regex);

data checkregex;
set mets.omra_669;
    retain testregex;
    if _N_=1 then do; 					  /*_N_ = number of iterations in data loop*/
        testregex = prxparse("/&regex/"); /*search for matching regex*/
        if missing(testregex)then do; 
            putlog 'ERROR: regex is malformed';
            stop;
        end;
    end;
if prxmatch(testRegEx, strip(omra1)); 	 /*otherwise output matching regex*/
run;

title "&q.. Medication matches &regex";
proc print data=checkregex;
    var omra1;
run;

%MEND find;

* Run macro input;
%find(q=1, regex = ASPIRIN);
%find(q=2, regex = ASP.*IN);
%find(q=3, regex = ASP.*IN\b..\d+(.MG|MG));
%find(q=3.5, regex=ASPI*RIN.*\d);
%find(q=4, regex = RO\w*REM);
%find(q=5, regex = ((L([^L])*L([^L])*L)(\B|\b)));
%find(q=6, regex = TRAZ[AIO]DONE);
%find(q=7, regex = PRIL(\W|$));
%find(q=8, regex = %);
%find(q=9, regex = (\d|\s)MG);
%find(q=10, regex = \d+$);
%find(q=11, regex = (.PRO|PRO$|\wPRO));
%find(q=12, regex = (^.{1,3}$)); 
%find(q=13, regex = ([AEIOU]{3,}));
%find(q=14, regex = \b.+\b\s\b.+\b\s\b.+\b\s\b.+\b);
%find(q=14.5, regex=\S+?\s\S+?\s\S+?\s\S+?);
%find(q=15, regex = (^VITA).+[A-E]);
%find(q=15.5, regex=. .+. .+. .);

ODS PDF CLOSE;

proc printto; run; 