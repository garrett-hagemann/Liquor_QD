capture log close 
clear
set more off

log using "data_explore.txt", text replace

/* Calculating panelists per year */
append using ny_panelists_2008
gen year = 2008
append using ny_panelists_2009
replace year = 2009 if year == .
append using ny_panelists_2010
replace year = 2010 if year == .
append using ny_panelists_2011
replace year = 2011 if year == .
append using ny_panelists_2012
replace year = 2012 if year == .
append using ny_panelists_2013
replace year = 2013 if year == .
append using ny_panelists_2014
replace year = 2014 if year == .

gen NYC = (fips_county_descr == "BRONX" | fips_county_descr == "NEW YORK" | fips_county_descr == "KINGS" | fips_county_descr == "QUEENS" | fips_county_descr == "RICHMOND")
keep if NYC == 1

tab year

clear

/* Working with purchases now */

use prod_chars_individual
keep if product > 0 // dropping outside options

gen purchase_month = month(date_d)
gen purchase_year = year(date_d)

egen group = group(purchase_month purchase_year upc)
egen uniq_prices = nvals(price), by(group) // needs egenmore
egen purch_freq = count(product), by(group)

hist uniq_prices if product <= 250 & purch_freq > 1, disc percent ///
	title("") ///
	xtitle("Unique Prices") graphregion(color(white)) ///
	fcolor(edkblue) lcolor(black) ylabel(,nogrid)
graph export "uniq_prices.pdf", replace

drop group uniq_prices purch_freq

sum price proof imported d_s_* [weight = projection_factor]
sum price proof imported d_s_* [weight = projection_factor] if product <= 250

preserve
	bys product: keep if _n == 1
	drop if product > 250
	tab1 d_g_*
restore

/* Purchases by month and Year */
tab purchase_year purchase_month

gen date_q = qofd(date_d) // quarterly date. Useful for time graphs
format date_q %tq

gen inc = .
replace inc = 2500 if household_income == 3
replace inc = 6500 if household_income == 4
replace inc = 9000 if household_income == 6
replace inc = 11000 if household_income == 8
replace inc = 13000 if household_income == 10
replace inc = 17500 if household_income == 11
replace inc = 22500 if household_income == 13
replace inc = 27500 if household_income == 15
replace inc = 32500 if household_income == 16
replace inc = 37500 if household_income == 17
replace inc = 42500 if household_income == 18
replace inc = 47500 if household_income == 19
replace inc = 55000 if household_income == 21
replace inc = 65000 if household_income == 23
replace inc = 85000 if household_income == 26
replace inc = 150000 if household_income >= 27

tab inc [weight = projection_factor]
tab inc [weight = projection_factor] if NYC

label define income 3 "0-5" ///
					4 "5-8" ///
					6 "8-10" ///
					8 "10-12" ///
					10 "12-15" ///
					11 "15-20" ///
					13 "20-25" ///
					15 "25-30" ///
					16 "30-35" ///
					17 "35-40" ///
					18 "40-45" ///
					19 "45-50" ///
					21 "50-60" ///
					23 "60-70" ///
					26 "70-100" ///
					27 "100+" //

gen hh_inc_2 = household_income
replace hh_inc_2 = 27 if hh_inc_2 > 27
label values hh_inc_2 income

graph hbar (percent) household_code [weight=projection_factor], over(hh_inc_2 ) ///
	l1title("Income Range ($000)") /// undocumented option
	ytitle("Percent") title("Income Distribution") ///
	graphregion(color(white)) bar(1,fcolor(edkblue) lcolor(black)) ylabel(,nogrid)
graph export "consumer_income_dist.pdf",replace
	
	
/* Distribution of household purchases. I.e. distribution of number of times
a household appears in the data */

preserve
	contract household_code
	disp "Number of Households = " _N
	replace _freq = 200 if _freq > 200 // making 200+ bin
	hist _freq, discrete freq
	graph export "hh_freq.pdf", replace
restore


/* Calculating number of retailers */

preserve
	contract retailer_code store_code_uc
	disp "Number of Retailers + Stores = " _N
	replace _freq = 400 if _freq > 400 // making 400+ bin
	hist _freq, discrete freq
	graph export "retailer_freq.pdf", replace
restore

/*
preserve
	// contracting down to frequencies
	contract upc_descr fips_county_descr fips_county_code purchase_month purchase_year date_q
	// generating total purchases overall, annyally, and by month-year combo
	egen upc_total = total(_freq), by(upc_descr fips_county_descr)
	egen ann_total = total(_freq), by(purchase_year upc_descr fips_county_descr)
	egen qtr_total = total(_freq), by(date_q upc_descr fips_county_descr)
	egen mth_total = total(_freq), by(purchase_month purchase_year upc_descr fips_county_descr)
	// makes graphs spaced evenly as fips_county_code varies from 5 to 80+
	egen cty = group(fips_county_descr)
	
	// working with overall rank first
	bys upc_descr fips_county_descr : gen unique = (_n == 1) // flag 1 obs per upc
	// generating overall ranking
	egen upc_total_rank = rank(-upc_total) if unique == 1, by(fips_county_descr) unique
	
	egen bronx_rank = max((fips_county_descr == "BRONX")*upc_total_rank), by(upc_descr)
	egen kings_rank = max((fips_county_descr == "KINGS")*upc_total_rank), by(upc_descr)
	egen ny_rank = max((fips_county_descr == "NEW YORK")*upc_total_rank), by(upc_descr)
	egen queens_rank = max((fips_county_descr == "QUEENS")*upc_total_rank), by(upc_descr)
	egen richmond_rank = max((fips_county_descr == "RICHMOND")*upc_total_rank), by(upc_descr)
	
	foreach rankvar of varlist bronx_rank kings_rank ny_rank queens_rank richmond_rank {
		twoway (connect upc_total_rank cty if `rankvar' == 1 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 2 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 3 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 4 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 5 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 6 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 7 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 8 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 9 & unique == 1) ///
		(connect upc_total_rank cty if `rankvar' == 10 & unique == 1), ///
		yscale(reverse) legend(off)
		graph export "`rankvar'_graph.pdf", replace

	}
	
	/* Originally planned to do this monthly, but data is too thin. Not
	enough purchases per month */
	
	// working with annual rank
	drop unique
	bys upc_descr fips_county_descr purchase_year: gen unique = (_n == 1) // flag 1 obs per upc
	egen year_rank = rank(-ann_total) if unique == 1, by(fips_county_descr purchase_year) unique
	egen first_rank = max((purchase_year == 2008)*year_rank), by(upc_descr fips_county_descr) // rank in 2008
	foreach cty in "BRONX" "KINGS" "NEW YORK" "QUEENS" "RICHMOND"{
		twoway (connected year_rank purchase_year if first_rank == 1 & fips_county_descr == "`cty'" & unique == 1) ///
		 (connected year_rank purchase_year  if first_rank == 2 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected year_rank purchase_year  if first_rank == 3 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected year_rank purchase_year  if first_rank == 4 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected year_rank purchase_year  if first_rank == 5 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected year_rank purchase_year  if first_rank == 6 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected year_rank purchase_year  if first_rank == 7 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected year_rank purchase_year  if first_rank == 8 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected year_rank purchase_year  if first_rank == 9 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected year_rank purchase_year  if first_rank == 10 & fips_county_descr == "`cty'" & unique == 1), ///
		  yscale(reverse) legend(off) title("`cty'")
		  graph export "annual_`cty'_rank.pdf", replace
	}
	
	// Working with quarterly rank
	drop unique
	bys upc_descr fips_county_descr date_q: gen unique = (_n == 1) // flag 1 obs per upc
	egen qtr_rank = rank(-qtr_total) if unique == 1, by(fips_county_descr date_q) unique
	egen first_qtr_rank = max((date_q == tq(2008q1))*qtr_rank), by(upc_descr fips_county_descr) // rank in 2008q1
	foreach cty in "BRONX" "KINGS" "NEW YORK" "QUEENS" "RICHMOND"{
		twoway (connected qtr_rank date_q if first_qtr_rank == 1 & fips_county_descr == "`cty'" & unique == 1) ///
		 (connected qtr_rank date_q  if first_qtr_rank == 2 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected qtr_rank date_q  if first_qtr_rank == 3 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected qtr_rank date_q  if first_qtr_rank == 4 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected qtr_rank date_q  if first_qtr_rank == 5 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected qtr_rank date_q  if first_qtr_rank == 6 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected qtr_rank date_q  if first_qtr_rank == 7 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected qtr_rank date_q  if first_qtr_rank == 8 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected qtr_rank date_q  if first_qtr_rank == 9 & fips_county_descr == "`cty'" & unique == 1) ///
		  (connected qtr_rank date_q  if first_qtr_rank == 10 & fips_county_descr == "`cty'" & unique == 1), ///
		  yscale(reverse) legend(off) title("`cty'")
		  graph export "qtr_`cty'_rank.pdf", replace
	}	  
	  
restore
*/


log close
