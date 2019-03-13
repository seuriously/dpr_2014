#!/usr/bin/env node

'use strict';


// Dependencies
var fs = require('fs');
var casperjs = require('casper');

var casper = casperjs.create({
    verbose: !true,
    // logLevel: 'debug',
    logLevel: 'info',
    waitTimeout: 60000,
    resourceTimeout: 10000,
    viewportSize: {
        width: 1280,
        height: 960
    },
    pageSettings: {
        javascriptEnabled: true,
        loadImages: !true,
        loadPlugins: true,
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:57.0) Gecko/20100101 Firefox/57.0'
    }
});


casper.start('https://pemilu2014.kpu.go.id/db1_dpr.php');

var dapilSel = '#contentcolumn_left > div > div.formcontainer > div.form > span.field > select[name="wilayah_id"]';

casper.waitForSelector(dapilSel, function () {
    var selectedDapil, selectedKab, selectedDapil_nm, selectedKab_nm;

    var dapilOptions = this.evaluate(function () {
        var result = [];
        var opts = document.querySelectorAll('select[name="wilayah_id"] option');
        for (var i = 0; i < opts.length; i++) {
            if (opts[i].value.length > 0) {
                result.push(opts[i].value);
            }
        }
		
        return result;
    });
	//this.echo(dapilOptions);
	
	var dapilName = this.evaluate(function () {
        var result = [];
        var opts = document.querySelectorAll('select[name="wilayah_id"] option');
        for (var i = 0; i < opts.length; i++) {
            if (opts[i].text != 'pilih') {
                result.push(opts[i].text);
            }
        }
		
        return result;
    });
	//this.echo(dapilName);
	
	selectedDapil = dapilOptions[76];
	selectedDapil_nm = dapilName[76];
	this.fillSelectors('#contentcolumn_left > div > div.formcontainer > div.form', {
		'select[name="wilayah_id"]': selectedDapil
	}, false);
	this.echo(selectedDapil_nm);
	this.waitForText('Kabupaten/Kota ', function () {
		var kabOptions = this.evaluate(function () {
			var result = [];
			var opts = document.querySelectorAll('#subcat_0 > div.form > span.field > select > option');
			for (var i = 0; i < opts.length; i++) {
				if (opts[i].value.length > 0) {
					result.push(opts[i].value);
				}
			}
			return result;
		});
		
		var kabName = this.evaluate(function () {
			var result = [];
			var opts = document.querySelectorAll('#subcat_0 > div.form > span.field > select > option');
			for (var i = 0; i < opts.length; i++) {
				if (opts[i].text != 'pilih') {
					result.push(opts[i].text);
				}
			}
			return result;
		});
		
		
		selectedKab = kabOptions[10];
		selectedKab_nm = kabName[10];
		this.echo(selectedKab_nm);
		
		this.fillSelectors('#subcat_0 > div.form', {
			'select[name="wilayah_id"]': selectedKab
		}, false);
		
		var selector = "#daftartps > table";
		var filename = [selectedDapil, selectedKab, selectedDapil_nm, selectedKab_nm, 'dpr.html'].join('_');
		this.waitForSelector(selector, function () {
			console.log(filename);
			fs.write(filename, this.getPageContent(), 'w');
		});			
	
		
	});

});

casper.run(function () {
    this.exit();
});

