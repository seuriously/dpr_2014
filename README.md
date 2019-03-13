# dpr_2014
Crawled data of 2014 Legislative Election's result.

all_dpr_2014.csv is the crawling result.
kpu_script.R is the main code to run.
install both phantomjs and casperjs before running kpu_script.R
casper_kpu.js is the js script that will open and load the page.
kpu_dpr_readAll.R combine the all result into 1 dataframe.


Hitting the url directly will resulted in blank page since the web is using javascript to populate the data.
Since I have little to no knowledge in js, all looping and data extraction was done using rvest.

