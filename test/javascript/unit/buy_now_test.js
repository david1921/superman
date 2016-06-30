define(["../../../public/javascripts/app/daily_deals/buy_now.js"], function(buyNow) {

	return {
		runTests: function() {
			
			module("buy_now.js with default configurations", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div class='buy-now-container'><div id='buy_now_button'>Buy Now</div><div class='unavailable' style='display:none'>Soldout</div></div>");
				},
				teardown: function() {
					jQuery('#qunit-fixture .buy-now-container').remove();
				}
			});
			
			test("should have #buy_now_buttom for buyNowButtonSelector selector", function() {
				equal( buyNow.build({}).settings.buyNowButtonSelector, "#buy_now_button" );
			});
			
			test("should have for .unavailable for unavailableButtonSelector selector", function() {
				equal( buyNow.build({}).settings.unavailableButtonSelector, '.unavailable' );
			});
			
			test("should have correct initial state after configuration", function() {
				buyNow.build({});
				equal( jQuery('#buy_now_button:visible').length, 1, "#buy_now_button should be visible" );
				equal( jQuery('.unavailable:visible').length, 0, ".unavailable button should not be visible" );
			});
			
			test("receives notification of deal:isOver", function() {
				var Deal = function() {},
						buyNowInstance = buyNow.build({});
				
				buyNowInstance.observe( new Deal(), 'deal:isOver' );
				equal( jQuery('#buy_now_button:visible').length, 0, "#buy_now_button should not be visible" );
				equal( jQuery('.unavailable:visible').length, 1, ".unavailable button should be visible" );
			});
			
			module("buy_now.js with custom configurations", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div class='buy-now-container'><div class='buy-now'>Buy Now</div><div class='deal-is-over' style='display:none'>Soldout</div></div>");
				},
				teardown: function() {
					jQuery('#qunit-fixture .buy-now-container').remove();
				}
			});
			
			test("should have .buy-now for buyNowButtonSelector selector", function() {
				equal( buyNow.build({ buyNowButtonSelector: '.buy-now' }).settings.buyNowButtonSelector, ".buy-now" );
			});
			
			test("should have for .deal-is-over for unavailableButtonSelector selector", function() {
				equal( buyNow.build({ unavailableButtonSelector: '.deal-is-over'} ).settings.unavailableButtonSelector, '.deal-is-over' );
			});
			
			test("should have correct initial state after configuration", function() {
				buyNow.build({
					buyNowButtonSelector: '.buy-now',
					unavailableButtonSelector: '.deal-is-over'
				});
				equal( jQuery('.buy-now:visible').length, 1, ".buy-now should be visible" );
				equal( jQuery('.deal-is-over:visible').length, 0, ".deal-is-over button should not be visible" );
			});
			
			test("receives notification of deal:isOver", function() {
				var Deal = function() {},
						buyNowInstance = buyNow.build({
							buyNowButtonSelector: '.buy-now',
							unavailableButtonSelector: '.deal-is-over'
						});
				
				buyNowInstance.observe( new Deal(), 'deal:isOver' );
				equal( jQuery('.buy-now:visible').length, 0, ".buy-now should not be visible" );
				equal( jQuery('.deal-is-over:visible').length, 1, ".deal-is-over button should be visible" );
			});			
			
		}
	}
		
});