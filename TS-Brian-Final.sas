libname data 'Z:\Documents\MSA 2019\024 Visualization\visuals';

proc import datafile = 'Z:\Documents\MSA 2019\024 Visualization\outdir\G-2147_T-well.csv'
 out = work.well
 dbms = CSV
 ;
run;

proc import datafile = 'Z:\Documents\MSA 2019\024 Visualization\outdir\G-2147_T-tide.csv'
 out = work.tide
 dbms = CSV
 ;
run;

proc import datafile = 'Z:\Documents\MSA 2019\024 Visualization\outdir\G-2147_T-rain.csv'
 out = work.rain
 dbms = CSV
 ;
run;


/*TIME SERIES FINAL PROJECT*/
/*IMPORT THREE CSV'S NAMED WELL, TIDE, AND RAIN*/
/* Visualize the data!!!!  */
/*combined into one dataset with 3 variables: well ,tide, rain*/
proc Sql;
create table final as
select a.date_time,a.corrected as well,b.corrected as tide
from work.well as a left join work.tide as b 
on a.date_time = b.date_time;
/*work.tide as b inner join work.rain as c*/
/*on b.date_time = c.date_time;*/
quit;
proc sql;
create table combo as
select a.date_time,a.well, a.tide, b.corrected as rain
from work.final as a left join work.rain as b 
on a.date_time = b.date_time;
quit;

/*visualize*/
data well_f;
set work.combo;
time=_n_;
run;
proc sgplot data=well_f ;
series x=time y=well;
series x=time y=tide;
series x=time y=rain;
run;
quit;

/* Creating lag variables */
data well_f;
set well_f;
tide1=lag1(tide);
tide2=lag2(tide);
tide3=lag3(tide);
tide4=lag4(tide);
tide5=lag5(tide);
tide6=lag6(tide);
rain1=lag1(rain);
rain2=lag2(rain);
rain3=lag3(rain);
rain4=lag4(rain);
rain5=lag5(rain);
rain6=lag6(rain);
rain7=lag7(rain);
rain8=lag8(rain);
rain9=lag9(rain);
well1=lag1(well);
well2=lag2(well);
run;

data well_train;
set well_f;
if _n_>3000;
run;
/* Step 1: Need to see if residuals are stationary */
proc arima data=well_train;
identify var=well crosscorr=(tide tide1 tide2 tide3 tide4 tide5 tide6 rain rain1 rain2 rain3 rain4 rain5 rain6 rain7 rain8 rain9);
estimate input=(tide tide1 tide2 tide3 tide4 tide5 tide6 rain rain1 rain2 rain3 rain4 rain5 rain6 rain7 rain8 rain9) p=2 method=ML;
forecast out=well_out;
run;
quit;


proc arima data=well_out;
identify var=residual stationarity=(adf=2);
run;
quit;
/*if you need to log or take a difference of variables you do this first*/


/* Here is the AICC one */
proc glmselect data=well_train;
model well=well1 well2 tide tide1 tide2 tide3 tide4 tide5 tide6 rain rain1 rain2 rain3 rain4 rain5 rain6 rain7 rain8 rain9/selection=backward select=aicc;
run;
quit;
/* Here is the AIC one */
proc glmselect data=well_train;
model well=well1 well2 tide tide1 tide2 tide3 tide4 tide5 tide6 rain rain1 rain2 rain3 rain4 rain5 rain6 rain7 rain8 rain9/selection=backward select=aic;
run;
quit;

/*This is the model I could got */
/*ods output FitStatistics=Fit1;*/
/*proc arima data=well_f;*/
/*identify var=well(1) crosscorr=(tide rain) nlag=100;*/
/*estimate input=(6 $/(3) rain (5) tide) p=6 q=24 method=ML;*/
/*forecast out=model1 back=168 lead = 168;*/
/*run;*/
/*quit;*/

/* This is an alternate model */
/*ods output FitStatistics=Fit1;*/
/*proc arima data=well_train;*/
/*identify var=well(1) crosscorr=(tide rain) nlag=100;*/
/*estimate input=((5) tide 6 $/(3) rain) p=6 q=24 method=ML;*/
/*forecast out=model1 back=168 lead = 168;*/
/*run;*/
/*quit;*/


/* Try a number of different models */
ods output FitStatistics=Fit1;
proc arima data=well_train;
identify var=well(1) crosscorr=(tide rain) nlag=100;
estimate input=((5) tide (1,3,4,5,6,7,8,9) rain) p=6 q=24 method=ML;
forecast out=model1 back=168 lead = 168;
run;
quit;


data fitstats;
set fit1 (keep=label1 nvalue1);
if label1 = 'AIC' or label1='SBC';
run;

proc transpose data=fitstats out=fitstats2;
id label1;
run;


data test;
merge model1 (rename=(residual=mod1));
if _n_>3000;
run;

data test;
set test;
absmod1=abs(mod1);
mapemod1=absmod1/abs(well);
run;

proc means data=test;
var absmod1 mapemod1;
run;

data New1;
set Well_f (keep=date_time);
run;

data New;
merge New1 Model1;
run;

/*proc sgplot data=New;*/
/*  series X=Time Y= Well;*/
/*  series X=Time Y=Forecast;*/
/*  YAXIS LABEL = 'Well Depth(In)';*/
/*  XAXIS LABEL = 'Time(Day)';*/
/*  REFLINE 0 / TRANSPARENCY = 0.5;*/
/*  title"Actual Vs Predicted for Well G2147";*/
/*run;*/



