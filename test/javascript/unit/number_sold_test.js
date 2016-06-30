define(["../../../public/javascripts/app/daily_deals/number_sold.js"], function(numberSold) {


	return {
		runTests: function() {
			
			module("number_sold.js with default values", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div class='number-sold-container'><span id='deals_sold'>0</span> Sold</div>");
				},
				teardown: function() {
					jQuery('#qunit-fixture .number-sold-container').remove();
				}
			});
			
			test("should have #deals_sold for the selector", function() {
				equal( numberSold.build({}).settings.selector, "#deals_sold" );
			});
			
			test("should not update the #deals_sold container on configuration", function() {
				numberSold.build({});
				equal( jQuery("#deals_sold").text(), "0" );
			});
			
			test("with a deal:numberSoldUpdated notification", function() {
				var Deal 								= function() {},
						numberSoldInstance 	= numberSold.build({});
						
				Deal.prototype.getNumberOfDealsSold = function() { return 10; };
				
				numberSoldInstance.observe( new Deal(), "deal:numberSoldUpdated" );
				equal( jQuery("#deals_sold").text(), "10" );
			});
			
			module("number_sold.js with custom selector", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div class='number-sold-container'><span class='number-sold'>0</span> Sold</div>");
				},
				teardown: function() {
					jQuery('#qunit-fixture .number-sold-container').remove();
				}
			});
			
			test("should have #deals_sold for the selector", function() {
				equal( numberSold.build({selector: ".number-sold"}).settings.selector, ".number-sold" );
			});
			
			test("should not update the #deals_sold container on configuration", function() {
				numberSold.build({selector: '.number-sold'});
				equal( jQuery(".number-sold").text(), "0" );
			});
			
			test("with a deal:numberSoldUpdated notification", function() {
				var Deal 								= function() {},
						numberSoldInstance 	= numberSold.build({selector: '.number-sold'});
						
				Deal.prototype.getNumberOfDealsSold = function() { return 10; };
				
				numberSoldInstance.observe( new Deal(), "deal:numberSoldUpdated" );
				equal( jQuery(".number-sold").text(), "10" );
			});			
			
		}
	}
		
});