SAS-L Sort, summarize, transpose and honor FORMATs all in one datastep

A take on Soren's excellent macro.
I added code to get the list of variables.
Soren discovered that summary statistics maintain the associated formats.
It appears to me adjusting data structute and meta data at compile time
greatly simplifies mainline code.
Also we need a macro 'do' in open code;

HAVE
====

WORK.HAVE_1 total obs=3
                          BALANCE_
 ACCT_NUM    AGE       DUE

   111        72       5009
   222        24      10001
   333        19       6150


WANT
===+

WORK.WANT total obs=2

  VARIABLE_
  NAME            MIN        MAX       MEAN

  age                19         72        38
  balance_due    $5,009    $10,001    $7,053


WORKING CODE

   COMPILE TIME

      proc transpose data=have_1(obs=1) out=havxpo(keep=_name_);

      select _name_ into :vars separated by " " from havxpo  *dictionaries are slow;

      %array(ary,values=&vars);

      proc summary data=have_1;
      var %do_over(ary,phrase=?);
      output out=temp
        %do_over(ary,phrase=min(?)=min_? max(?)=max_? mean(?)=mean_?);

       /* summary output                                                   MEAN_
                                         MIN_BALANCE_    MAX_BALANCE_    BALANCE_
       MIN_AGE    MAX_AGE    MEAN_AGE         DUE             DUE           DUE

          19         72       38.3333        5009            10001        7053.33

       Note statistics are formatted

       3    MIN_AGE             Num       8    12.
       4    MAX_AGE             Num       8    12.
       5    MEAN_AGE            Num       8    12.
       6    MIN_BALANCE_DUE     Num       8    DOLLAR12.
       7    MAX_BALANCE_DUE     Num       8    DOLLAR12.
       8    MEAN_BALANCE_DUE    Num       8    DOLLAR12.

      */


   MAINLINE

      %do_over(ary,phrase=%nrstr(
         variable_name="?";
         min=vvalue(min_?);   * uses the formatted value - char var;
         max=vvalue(max_?);   * uses the formatted value - char var;
         mean=vvalue(mean_?); * uses the formatted value - char var;
         output;
     ));

see
https://listserv.uga.edu/cgi-bin/wa?A2=SAS-L;1e81dc14.1710d

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

* only needed for development;
proc datasets lib=work kill;
run;quit;
%symdel ary1 ary2 / nowarn;

data have_1;
input acct_num$ age balance_due;
format age 12.0 balance_due dollar12.;
cards;
111 72 5009
222 24 10001
333 19 6150
;
run;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

data want;

  if _n_=0 then do;
    %let rc=%sysfunc(dosubl('
      proc transpose data=have_1 out=havxpo(keep=_name_);
         var _numeric_;
      run;quit;
      proc sql;
         select _name_ into :vars separated by " " from havxpo
      ;quit;
      %array(ary,values=&vars.);
      proc summary data=have_1;
        var %do_over(ary,phrase=?);
        output out=temp
          %do_over(ary,phrase=min(?)=min_? max(?)=max_? mean(?)=mean_?);
      run;quit;
    '));
  end;

  length variable_name min max mean $25;

  set temp;

  %do_over(ary,phrase=%nrstr(
     variable_name="?";
     min=vvalue(min_?);
     max=vvalue(max_?);
     mean=vvalue(mean_?);
     output;));

  keep variable_name min max mean;

run;quit;


