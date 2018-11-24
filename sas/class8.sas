* class8.sas
  written by Steve Simon
  November 18, 2018;

** preliminaries **;

%let path=/folders/myfolders;
%let xpath=c:/Users/simons/Documents/SASUniversityEdition/myfolders;

ods pdf file="&path/survival-lecture8/sas/class8.pdf";

libname survival
  "&path/data";
  
proc import
    datafile="&path/data/leader1.csv"
    dbms=dlm
    out=survival.leader;
  delimiter=",";
  getnames=yes;
run;

data survival.leader;
  set survival.leader;
  if age ^= .;
  cens=(lost ^= "still in power");
run;

proc print
    data=survival.leader(obs=10);
  title1 "Leader data set";
  title2 "Partial listing";
run;

proc means
    data=survival.leader;
  var years start age loginc growth pop land literacy;
  title2 "Descriptive statistics";
run;

proc freq
    data=survival.leader;
  tables lost manner military conflict region;
run;

* First, let's look at this model in a binary
  fashion, with lost = "still in power" as
  censored observations and "constitutional
  exit" and "natural death" and 
  "non-constitutional exit" as events.
;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata manner;
  title2 "Simple KM curves";
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata military;
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata conflict;
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata region;
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata start(1969, 1979);
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata age(39, 59);
run;

* log(200) is approximately 5.3, 
  log(500) is approximately 6.2
;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata loginc(5.3, 6.2);
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata growth(0, 3.9);
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata pop(1, 10);
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata land(100, 1000);
run;

proc lifetest
    notable
    plots=survival
    data=survival.leader;
  time years*cens(0);
  strata literacy(50, 75);
run;

proc phreg
    data=survival.leader;
  class manner military;
  model years*cens(0)=
    manner military age;
  output
    out=martingale_residuals
    resmart=r_martingale;
  title2 "Model with three independent variables";
run;

* The plot of the Martingale residuals versus
  age (which is already in the model) provides
  an informal assessment as to whether there is
  a nonlinear effect of age above and beyond the
  linear effect already in the model.
  
  You do not need to plot the Martingale residuals
  versus the other two variables in the model,
  military and age, because categorical variables
  cannot have a nonlinear component.
;

proc sgplot
    data=martingale_residuals;
  loess x=age y=r_martingale / clm smooth=0.5;
  title3 "Plot of Martingale residuals";
run;

* When you plot the Martingale residuals versus
  variables not yet in the model, you get an
  informal assessment of whether these variables
  should be added to the model. For those
  variables which are continuous, you also get
  a hint as to whether the relationship is linear
  or nonlinear.
  
  Use boxplots, of course, for categorical variables.
;

proc sgplot
    data=martingale_residuals;
  vbox r_martingale / category=region;
run;  
  
proc sgplot
    data=martingale_residuals; 
  loess x=loginc y=r_martingale / clm smooth=0.5;
run;
  
proc sgplot
    data=martingale_residuals; 
  loess x=growth y=r_martingale / clm smooth=0.5;
run;
  
proc sgplot
    data=martingale_residuals; 
  loess x=pop y=r_martingale / clm smooth=0.5;
run;
  
proc sgplot
    data=martingale_residuals; 
  loess x=land y=r_martingale / clm smooth=0.5;
run;
  
proc sgplot
    data=martingale_residuals; 
  loess x=literacy y=r_martingale / clm smooth=0.5;
run;
  
* Update your multivariate model;

proc phreg
    data=survival.leader;
  class manner military region;
  model years*cens(0)=
    manner military age loginc region;
  output
    out=schoenfeld_residuals
    ressch=r_manner r_military r_age r_loginc r_region1 r_region2 r_region3;
  title2 "Model with five independent variables";
run;

* The Schoenfeld residuals help you assess whether
  a variable in the model meets the assumptions
  of proportional hazards.
  
  You plot the Schoenfeld residuals versus time
  (or possibly log(time)).  Anything other than a
  flat trend indicates a possible problem.
;

proc sgplot
    data=schoenfeld_residuals; 
  loess x=years y=r_manner / clm smooth=0.5;
  title3 "Plot of Schoenfeld residuals";
run;
  
proc sgplot
    data=schoenfeld_residuals; 
  loess x=years y=r_military / clm smooth=0.5;
run;
  
proc sgplot
    data=schoenfeld_residuals; 
  loess x=years y=r_age / clm smooth=0.5;
run;
  
proc sgplot
    data=schoenfeld_residuals; 
  loess x=years y=r_loginc / clm smooth=0.5;
run;
  
proc sgplot
    data=schoenfeld_residuals; 
  loess x=years y=r_region / clm smooth=0.5;
run;
  
* Competing risks analysis;

data survival.leader;
  set survival.leader;
  outcome=
    1*(lost="constitutional exit") +
    2*(lost="natural death") +
    3*(lost="nonconstitutional exit");
run;

proc freq
    data=survival.leader;
  tables lost*outcome /
    norow nocol nopercent;
  title2 "Competing risk analysis";
  title3 "All observations";
run;
  
* You could analyze the Kaplan Meier curve for
  each event separately and then consider
  alternative events as censored. But this
  produces an overestimate of the probability
  of individual causes. In fact, if you sum
  up the cumulative probabilities for each
  individual event, you could end up with a
  total probability larger than 1.
  
  You can partition the probabilities up
  properly using the cumulative incidence
  function.
;

proc phreg
    data=survival.leader;
  model years*outcome(0)= / eventcode=1;
  output out=cif1 cif=p1;
run;

proc sort
    nodupkey
    data=cif1
    out=cif1a(keep=years p1);  
  by years;

proc phreg
    data=survival.leader;
  model years*outcome(0)= / eventcode=2;
  output out=cif2 cif=p2;
run;

proc sort
    nodupkey
    data=cif2
    out=cif2a(keep=years p2);  
  by years;

proc phreg
    data=survival.leader;
  model years*outcome(0)= / eventcode=3;
  output out=cif3 cif=p3;
run;

proc sort
    nodupkey
    data=cif3
    out=cif3a(keep=years p3);  
  by years;

data cif;
  merge
    cif1a
    cif2a
    cif3a;
  by years;
  constitutional_means=p1;
  natural_death=p1+p2;
  nonconstitutional_means=p1+p2+p3;
run;

proc sgplot
    data=cif;
  step x=years y=constitutional_means;
  step x=years y=natural_death;
  step x=years y=nonconstitutional_means;
  yaxis min=0 max=1;
run;

* Repeat these steps, but on the subgroup where
  manner=nonconstitutional ascent
;

proc phreg
    data=survival.leader;
  model years*outcome(0)= / eventcode=1;
  output out=cif1 cif=p1;
  where manner="nonconstitutional ascent";
  title3 "Subgroup manner=nonconstitutional ascent";
run;

proc sort
    nodupkey
    data=cif1
    out=cif1a(keep=years p1);  
  by years;

proc phreg
    data=survival.leader;
  model years*outcome(0)= / eventcode=2;
  output out=cif2 cif=p2;
  where manner="nonconstitutional ascent";
run;

proc sort
    nodupkey
    data=cif2
    out=cif2a(keep=years p2);  
  by years;

proc phreg
    data=survival.leader;
  model years*outcome(0)= / eventcode=3;
  output out=cif3 cif=p3;
  where manner="nonconstitutional ascent";
run;

proc sort
    nodupkey
    data=cif3
    out=cif3a(keep=years p3);  
  by years;

data cif;
  merge
    cif1a
    cif2a
    cif3a;
  by years;
  constitutional_means=p1;
  natural_death=p1+p2;
  nonconstitutional_means=p1+p2+p3;
run;

proc sgplot
    data=cif;
  step x=years y=constitutional_means;
  step x=years y=natural_death;
  step x=years y=nonconstitutional_means;
  yaxis min=0 max=1;
run;

ods pdf close;
