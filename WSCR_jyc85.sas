%LET job=WSCR;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

*proc printto log="&outdir/Logs/&job._&onyen..log" new; *run; 

*********************************************************************
*  Assignment:    WSCR              
*                                                                    
*  Description:   Web scraping using SAS or R
*
*  Name:          Joyce Choe
*
*  Date:          3/22/2024                                  
*------------------------------------------------------------------- 
*  Job name:      WSCR_jyc85.sas   
*
*  Purpose:       Parse info from a web page http source
*				  and make a data set with this info using SAS or R
*                                         
*  Language:      SAS, VERSION 9.4  
*
*
*  Output:        PDF file, data sets
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;

* 1 - Webscraping movie cast using SAS;


* Save http page source file as .txt file in data folder;
%let fileloc=/home/u63543840/BIOS669/Data;
filename src "&fileloc/moviecast.txt";

proc http 
    method="GET"
    url="https://www.imdb.com/title/tt15398776/fullcredits"
    out=src;
run;

* Write each record as a line to a dataset;
data from_src;
    infile src length=len lrecl=32767;
    input line $varying32767. len;
    line = strip(line); 			/*remove trailing 0s and blanks in line variable*/
    if len>0; 						/*include only those with chr length */
   
run;


* Find position of chr string in line, later use to subset;
data parse_positions;
    set from_src;
    name_begin  = find(line,'alt='); 
    line_end  = find(line,' </td>'); 
    if name_begin > 0 and line_end > 0; 
    
run;

* Print data set for cast names only; 
data cast;
    set parse_positions;
    length name $100;
    
    name = scan(line, 6, '"'); 
    keep name;
    
run;
   
title  'Cast names from Oppenheimer movie';
proc print data=cast label;
	label name = 'Cast member name';
run;


* 1 extension; 

data subsetcast;
	set from_src;
	
	name_begin  = find(line,'alt='); 
	line_end  = find(line,' </td>'); 
	if (name_begin = 30 and line_end > 0) or scan(line,1) = 'uncredited';
	num = _N_;
	
run;

data creditedcast;
	set subsetcast;
	length name $20;
	
	where num <= 1924;
	name = scan(line, 6, '"');
	
run;

title  'Credited cast names';
proc print data=creditedcast (keep=name) label;
	label name = 'Cast member name';
run;


* 2 - Webscraping sunrise/sunset using R code and SAS;

libname r "/home/u63543840/BIOS669/Data/R";

* Import data from txt file R;

proc import out=r.rdata
    datafile="/home/u63543840/BIOS669/Data/R/rdata.txt"
    dbms=dlm
    replace;
    getnames=yes;
run;


* Print sunrise times for first day of months in 2019;
data sunrise;
	set r.rdata;
	length Month $20;
	where substr(Day, 10) = '1';
	
	if scan(Day, 2, " ") = 'Jan' then Month = 'January';
		else if scan(Day, 2, " ") = 'Feb' then Month = 'February';
		else if scan(Day, 2, " ") = 'Mar' then Month = 'March';
		else if scan(Day, 2, " ") = 'Apr' then Month = 'April';
		else if scan(Day, 2, " ") = 'May' then Month = 'May';
		else if scan(Day, 2, " ") = 'Jun' then Month = 'June';
		else if scan(Day, 2, " ") = 'Jul' then Month = 'July';
		else if scan(Day, 2, " ") = 'Aug' then Month = 'August';
		else if scan(Day, 2, " ") = 'Sep' then Month = 'September';
		else if scan(Day, 2, " ") = 'Oct' then Month = 'October';
		else if scan(Day, 2, " ") = 'Nov' then Month = 'November';																							
	else Month = 'December';
			
	Sunrise = substr(Sunrise, 1, 7);
	
run;

title 'First day of the month sunrise times, Carrboro, 2019';
proc print data=sunrise(keep= Month Sunrise) noobs label;
	var Month Sunrise; 	/*order month to sunrise*/
	*label Sunrise = Sunrise time (EST);
	
run;


ODS PDF CLOSE;


*proc printto; *run; 