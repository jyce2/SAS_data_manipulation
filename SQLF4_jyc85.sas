%LET job=SQLF4;
%LET onyen=jyc85;
%LET outdir=/home/u63543840/BIOS669;

proc printto log="&outdir/Logs/&job._&onyen..log" new; run; 

*********************************************************************
*  Assignment:    SQLF Problem 4                                   
*                                                                    
*  Description:   REFB3 redo with inexact date matching (SQL)
*
*  Name:          Joyce Choe
*
*  Date:          2/8/2024                                      
*------------------------------------------------------------------- 
*  Job name:      SQLF4_jyc85.sas   
*
*  Purpose:       PROC SQL create table, inexact matching, skeleton join
*                                         
*  Language:      SAS, VERSION 9.4  
*
*  Input:         METS > UVFA_669, CGIA_669, AESA_669, SAEA_669, VSFA_669, 
*				  		 AUQA_669, LABA_669, BSFA_669, SMFA_669 data sets 
*
*  Output:        PDF file    
*                                                                    
********************************************************************;
OPTIONS nodate mergenoby=warn varinitchk=warn nofullstimer orientation=landscape;
FOOTNOTE "Job &job._&onyen run on &sysdate at &systime";

LIBNAME mets "~/my_shared_file_links/klh52250/METS" access=readonly;

ODS PDF FILE="&outdir/Output/&job._&onyen..PDF" STYLE=JOURNAL;


* SQLF Problem 4; 

PROC SQL number;
TITLE 'Exact and inexact dates for when unscheduled visit forms were filled out';

	CREATE TABLE mergedates AS
	SELECT A.BID,
		   A.VISIT, 			/*Visit Number*/
		   A.UVFA1A as Reason1, /*'Change in psychiatric symptoms'*/
		   A.UVFA1B as Reason2, /*'Drug tolerability adverse event'*/
		   A.UVFA1C as Reason3, /*'Change in medical status'*/
		   A.UVFA1D as Reason4, /*'Medication changes or adjustment'*/ 
		   Z.UVFA0B				/*(In)exact_Visit_Dates*/
		FROM METS.UVFA_669 as A,
			 METS.UVFA_669 as Z
		WHERE A.BID = Z.BID and 
			  A.VISIT = Z.VISIT and 
			  A.UVFA0B = Z.UVFA0B or
			  A.UVFA0B+1 = Z.UVFA0B or
			  A.UVFA0B-1 = Z.UVFA0B;  
	* print output below; 
	RESET PRINT; 
	SELECT M.BID, 
		   M.VISIT,
		   M.UVFA0B label 'UVFA date',
		   B.CGIA0B label 'CGIA date', 
		   C.AESA0B label 'AESA date', 
		   D.VSFA0B label 'VSFA date',
		   E.AUQA0B label 'AUQA date',
		   F.LABA0B label 'LABA date',
		   G.BSFA0B label 'BSFA date',
		   H.SMFA0B label 'SMFA date'
		FROM mergedates as M
		LEFT JOIN
			 METS.CGIA_669 as B
			 ON M.BID = B.BID and M.VISIT = B.VISIT and M.UVFA0B = B.CGIA0B 
		LEFT JOIN
			 METS.AESA_669 as C
			 ON M.BID = C.BID and M.VISIT = C.VISIT and M.UVFA0B = C.AESA0B
		LEFT JOIN
			 METS.VSFA_669 as D
			 ON M.BID = D.BID and M.VISIT = D.VISIT and M.UVFA0B = D.VSFA0B
		LEFT JOIN
			 METS.AUQA_669 as E
			 ON M.BID = E.BID and M.VISIT = E.VISIT and M.UVFA0B = E.AUQA0B
		LEFT JOIN
			 METS.LABA_669 as F 
			 ON M.BID = F.BID and M.VISIT = F.VISIT and M.UVFA0B = F.LABA0B
		LEFT JOIN
			 METS.BSFA_669 as G
			 ON M.BID = G.BID and M.VISIT = G.VISIT and M.UVFA0B = G.BSFA0B
		LEFT JOIN
			 METS.SMFA_669 as H
			 ON M.BID = H.BID and M.VISIT = H.VISIT and M.UVFA0B = H.SMFA0B;
QUIT;  

* Solution Key;

proc sql;

    title1 'Other forms filled out at each unscheduled visit';
    title2 'Matching on visit date plus or minus one day';
    
    select u.bid, u.visit, u.uvfa0b, 
           c.cgia0b label='CGI date',
           a.aesa0b label='AES date',
           s.saea0b label='SAE date',
           v.vsfa0b label='VSF date',
           q.auqa0b label='AUQ date',
           l.laba0b label='LAB date',
           b.bsfa0b label='BSF date',
           m.smfa0b label='SMF date'
           
        from    mets.uvfa_669 as U
        
            left join
                mets.cgia_669 as C
                on u.bid=c.bid and u.visit=c.visit and abs(c.cgia0b-u.uvfa0b)<=1
                
            left join            
                mets.aesa_669 as A
                on u.bid=a.bid and u.visit=a.visit and -1 <= a.aesa0b-u.uvfa0b <= 1
                
            left join
                mets.saea_669 as S
                on u.bid=s.bid and u.visit=s.visit and -1 <= s.saea0b-u.uvfa0b <= 1
            
            left join
                mets.vsfa_669 as V
                on u.bid=v.bid and u.visit=v.visit and -1 <= v.vsfa0b-u.uvfa0b <= 1
                
            left join
                mets.auqa_669 as Q
                on u.bid=q.bid and u.visit=q.visit and -1 <= q.auqa0b-u.uvfa0b <= 1
                
            left join
                mets.laba_669 as L
                on u.bid=l.bid and u.visit=l.visit and -1 <= l.laba0b-u.uvfa0b <= 1
                
            left join
                mets.bsfa_669 as B
                on u.bid=b.bid and u.visit=b.visit and -1 <= b.bsfa0b-u.uvfa0b <= 1
                
            left join
                mets.smfa_669 as M
                on u.bid=m.bid and u.visit=m.visit and -1 <= m.smfa0b-u.uvfa0b <= 1;
            
    title;
quit;



ODS PDF CLOSE;

proc printto; run; 