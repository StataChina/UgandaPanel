/*-------------------------------------------------------------------------------
# Name:		05_shocks_2010
# Purpose:	Process shock module including coping strategies
# Author:	Tim Essam, Ph.D.
# Created:	01/12/2015
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/
capture log close
clear
log using "$pathlog/05_shocks_2010", replace
set more off

* Load in shock module to look at different shocks faced by hh
use "$wave2/GSEC16.dta", clear

* List the label for shocks and their cross-walk codes
label list df_SHOCK df_SHOCKRECOVERY

* Tabulate total shocks reported
tab h16q00 if h16q01 == 1

* Calculate total shocks per household
	g byte anyshock = (h16q01 ==1)
	g byte rptShock = (h16q01 ==1)

	egen totShock = total(anyshock), by(HHID)
	la var anyshock "household reported at least one shock"
	la var totShock "total shocks"

* Quickly get a sense of frequency of shocks at HH-level
	bys HHID: gen id = _n
	tab totShock if id==1, mi

	la var totShock "Total shocks"

* Create shock buckets
/* World Bank classifications
	Prices (inputs, outputs, food)
	Hazards (natural, droughts, floods)
	Employment (jobs, wages)
	Assets (house, land, livestock)
	Health (death, illness)
	Crime & Safety (theft, violence)	*/

* Create detailed shocks just in case they are needed
/*ag 		= other crop damage; input price increase; death of livestock
* aglow		= unusually low prices for ag output
* conflit 	= theft/robbery/violence
* disaster 	= drought, flood, heavy rains, landslides, fire
* drought	= drought/irregular rains
* financial	= loss of non-farm job
* pricedown = price fall of food items
* health	= death of hh member; illness of hh member
* other 	= loss of house; displacement; other
* theft		= theft of money/assets/output/etc.. */ 
	g byte ag 		= inlist(h16q00, 104, 105, 106) &  inlist(h16q01, 1) == 1
	g byte aglow	= inlist(h16q00, 107) &  inlist(h16q01, 1) == 1
	g byte conflict = inlist(h16q00, 116) &  inlist(h16q01, 1) == 1
	g byte drought	= inlist(h16q00, 101) &  inlist(h16q01, 1) == 1
	g byte disaster = inlist(h16q00, 102, 103, 117) &  inlist(h16q01, 1) == 1
	g byte financial= inlist(h16q00, 108, 109) &  inlist(h16q01, 1) == 1
	g byte health 	= inlist(h16q00, 110, 111, 112, 113) &  inlist(h16q01, 1) == 1
	g byte other 	= inlist(h16q00, 118, 116) &  inlist(h16q01, 1) == 1
	g byte theft	= inlist(h16q00, 114, 115) &  inlist(h16q01, 1) == 1

	g byte priceShk = inlist(h16q00, 106, 107) &  inlist(h16q01, 1) == 1
	g byte hazardShk = inlist(h16q00, 101, 102, 103, 117) &  inlist(h16q01, 1) == 1
	g byte employShk = inlist(h16q00, 108, 109) &  inlist(h16q01, 1) == 1
	g byte assetShk = inlist(h16q00, 104, 105) &  inlist(h16q01, 1) == 1
	g byte healthShk = inlist(h16q00, 110, 111, 112, 113) &  inlist(h16q01, 1) == 1
	g byte crimeShk = inlist(h16q00, 114, 115, 116) &  inlist(h16q01, 1) == 1

	la var ag "Agriculture"
	la var aglow "Low ag output prices"
	la var conflict "Conflict"
	la var disaster "Disaster"
	la var financial "Financial"
	la var health "Health"
	la var other "Other"
	la var theft "Theft"
	la var drought "lack of rainfall or drought"

	la var priceShk "price shocks  (inputs, outputs, food)"
	la var hazardShk "hazard schock (flood, fire, drought, landslide)"
	la var employShk "Employment (jobs, wages)"
	la var assetShk "Assets (house, land, livestock)"
	la var healthShk "Health (death, illness)"
	la var crimeShk "Crime & Safety (theft, violence)"

recode h16q02b (16 = 12)
* How long did each shock last (taking max value)
	egen priceLgth  = max(h16q02b) if inlist(h16q00, 106, 107)==1 &  inlist(h16q01, 1) == 1, by(HHID)
	egen hazardLgth = max(h16q02b) if inlist(h16q00, 101, 102, 103, 117) &  inlist(h16q01, 1) == 1, by(HHID)
	egen employLgth = max(h16q02b) if inlist(h16q00, 108, 109) &  inlist(h16q01, 1) == 1, by(HHID)
	egen assetLgth  = max(h16q02b) if inlist(h16q00, 104, 105) &  inlist(h16q01, 1) == 1, by(HHID)
	egen healthLgth = max(h16q02b) if inlist(h16q00, 110, 111, 112, 113) &  inlist(h16q01, 1) == 1, by(HHID)
	egen crimeLgth  = max(h16q02b) if inlist(h16q00, 114, 115, 116) &  inlist(h16q01, 1) == 1, by(HHID)

*label variables
	la var priceLgth "Length of price shocks  (inputs, outputs, food)"
	la var hazardLgth "Length of hazard schock (flood, fire, drought, landslide)"
	la var employLgth "Length of Employment (jobs, wages)"
	la var assetLgth "Length of Assets (house, land, livestock)"
	la var healthLgth "Length of Health (death, illness)"
	la var crimeLgth "Length of Crime & Safety (theft, violence)"

* How did households cope?
label list df_SHOCKRECOVERY

/* Coping Mechanisms - What are good v. bad coping strategies? From (Heltberg et al., 2013)
	http://siteresources.worldbank.org/EXTNWDR2013/Resources/8258024-1352909193861/
	8936935-1356011448215/8986901-1380568255405/WDR15_bp_What_are_the_Sources_of_Risk_Oviedo.pdf
	Good Coping: use of savings, credit, asset sales, additional employment, 
					migration, and assistance
	Bad Coping: increases vulnerabiliy* compromising health and edudcation 
				expenses, productive asset sales, conumsumption reductions 
				*/
				
	g byte goodcope = inlist(h16q4a, 1, 2, 4, 5, 6, 7, 8, 9, 10, 12) &  inlist(h16q01, 1) == 1
	g byte badcope 	= inlist(h16q4a, 3, 13, 14, 15, 11) &  inlist(h16q01, 1) == 1
	g byte incReduc = h16q3a == 1
	g byte assetReduc = h16q3b == 1
	g byte foodProdReduc = h16q3c == 1
	g byte foodPurchReduc = h16q3d == 1

* Label variables
	la var goodcope "Good primary coping strategy"
	la var badcope "Bad primary coping strategy"
	la var incReduc "Income reduction due to shock"
	la var assetReduc "Asset reduction due to shock"
	la var foodProdReduc "Food production reduction due to shock"
	la var foodPurchReduc "Food purchase reduction due to shock"

* Create bar graph of shocks ranked by severity
	graph hbar (count) if hazardShk == 1, /*
	*/ over(h16q4a, sort(1) descending label(labsize(vsmall))) /*
	*/ blabel(bar) scheme(s2mono) scale(.80) /*
	*/ by(rptShock, missing cols(2) iscale(*.80) /*
	*/ title(High food and agricultural input prices are the most common and the most severe shocks/*
	*/, size(small) color("100 100 100"))) 
	graph export "$pathgraph\HazCope2010.pdf", as(pdf) replace



* Collapse data to househld level and merge back with GIS info
ds (h16* id ), not
keep `r(varlist)'

* Collapse everything down to HH-level using max values for all vars
* Copy variable labels to reapply after collapse
include "$pathdo/copylabels.do"

#delimit ;
	collapse (max) ag aglow conflict drought disaster financial health other theft 
	priceShk hazardShk employShk healthShk crimeShk assetShk
	priceLgth hazardLgth employLgth assetLgth healthLgth crimeLgth
	goodcope badcope incReduc assetReduc foodProdReduc foodPurchReduc
	anyshock totShock, by(HHID) fast; 
#delimit cr

* Reapply variable lables & value labels
include "$pathdo/attachlabels.do"

g year = 2010

* Save shock data
save "$pathout/shocks_2010.dta", replace

sum *Shk
tab anyshock
tab totShock

* ---- Extra Code 
/*
* Save shock data and merge with geovars
compress
merge 1:1 HHID using "$pathout/Geovars.dta", gen(geo_merge)
drop geo_merge

* Merge in the data with sampling information
merge 1:1 HHID using "$pathraw/GSEC1.dta", gen(_merge)
keep if _merge==3
drop _merge

* Survey set the data to account for complex sampling design in variance calculations
* Export a cut for GIS work
export delimited "$pathexport/shocks.csv", replace

save "$pathout/shocks.dta", replace
log2html "$pathlog/04_shocks", replace
capture log close 
*/
