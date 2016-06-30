/*
	We need to be able to attach to multiple deals....
*/
define(["../../../public/javascripts/app/daily_deals/variations.js"], function(variations) {
	
	return {
		runTests: function() {

			module("variations.js with one deal and with default values", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div id=\"daily_deal_content_box\"><a id=\"buy_now_button\" class=\"dd_button dd_variations_button\" href=\"#\">Buy</a><a id=\"dd_variations_button\" class=\"buy_now\" href=\"#\">&gt;</a><div id=\"dd_variations\" class=\"dd_variations_menu\" style=\"display: none; \">Hello I am A Variation</div></div>");
				},
				teardown: function() {
					jQuery('#qunit-fixture #buy_now').remove();
				}
			});

			test("should only have one variation", function() {
				equal( variations.build({}).length, 1 );
			});

			test("should not display the variation menu on initial build", function() {
				equal( jQuery(".dd_variations_menu:hidden").length, 1 );
			});

			module("variations.js with one deal and click events", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div id=\"daily_deal_content_box\"><a id=\"buy_now_button\" class=\"dd_button dd_variations_button\" href=\"#\">Buy</a><a id=\"dd_variations_button\" class=\"buy_now\" href=\"#\">&gt;</a><div id=\"dd_variations\" class=\"dd_variations_menu\" style=\"display: none; \">Hello I am A Variation</div></div>");
				},
				teardown: function() {
					jQuery('#qunit-fixture #buy_now').remove();
				}
			});

			test("click on body should not open variation menu", function() {
				variations.build({});
				QUnit.triggerEvent( document.body, "click" );
				equal( jQuery('#daily_deal_content_box .dd_variations_menu:visible').length, 0 );
				equal( jQuery('#daily_deal_content_box .dd_variations_menu:hidden').length, 1 );
			});

			test("click on buttonElement and then proceed to click on body should open and close variation menu", function() {
				variations.build({});
				QUnit.triggerEvent( jQuery("#daily_deal_content_box a:first")[0], "click" );
				equal( jQuery('#daily_deal_content_box .dd_variations_menu:visible').length, 1 );
				QUnit.triggerEvent( document.body, "click" );
				equal( jQuery('#daily_deal_content_box .dd_variations_menu:hidden').length, 1 );
			});

			module("variations.js with more than one deal", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div id=\"daily_deal_content_box\"><div class=\"daily_deal_content\"><a id=\"buy_now_button\" class=\"dd_button dd_variations_button\" href=\"#\">Buy</a><a id=\"dd_variations_button\" class=\"buy_now\" href=\"#\">&gt;</a><div id=\"dd_variations\" class=\"dd_variations_menu\" style=\"display: none; \">Hello I am A Variation</div></div><div class=\"daily_deal_content\"><a id=\"buy_now_button\" class=\"dd_button dd_variations_button\" href=\"#\">Buy</a><a id=\"dd_variations_button\" class=\"buy_now\" href=\"#\">&gt;</a><div id=\"dd_variations\" class=\"dd_variations_menu\" style=\"display: none; \">Hello I am A Variation</div></div></div>");
				},
				teardown: function() {
					jQuery('#qunit-fixture #buy_now').remove();
				}
			});

			test("should only have one variation", function() {
				equal( variations.build({deal_selectors:".daily_deal_content"}).length, 2 );
			});

			test("should not display the variation menu first deal", function() {				
				variations.build({deal_selectors:".daily_deal_content"});
				equal( jQuery("#daily_deal_content_box .daily_deal_content:nth-child(1) .dd_variations_menu:hidden").length, 1 );
			});			

			test("should not display the variation menu second deal", function() {
				variations.build({deal_selectors:".daily_deal_content"});
				equal( jQuery("#daily_deal_content_box .daily_deal_content:nth-child(2) .dd_variations_menu:hidden").length, 1 );
			});						

			module("variations.js clicks with more than one deal", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div id=\"daily_deal_content_box\"><div class=\"daily_deal_content\"><a id=\"buy_now_button\" class=\"dd_button dd_variations_button\" href=\"#\">Buy</a><a id=\"dd_variations_button\" class=\"buy_now\" href=\"#\">&gt;</a><div id=\"dd_variations\" class=\"dd_variations_menu\" style=\"display: none; \">Hello I am A Variation</div></div><div class=\"daily_deal_content\"><a id=\"buy_now_button\" class=\"dd_button dd_variations_button\" href=\"#\">Buy</a><a id=\"dd_variations_button\" class=\"buy_now\" href=\"#\">&gt;</a><div id=\"dd_variations\" class=\"dd_variations_menu\" style=\"display: none; \">Hello I am A Variation</div></div></div>");
				},
				teardown: function() {
					jQuery('#qunit-fixture #buy_now').remove();
				}
			});

			test("click on body should not open variation menu on either deal", function() {
				variations.build({});
				QUnit.triggerEvent( document.body, "click" );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(1) .dd_variations_menu:visible').length, 0 );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(2) .dd_variations_menu:hidden').length, 1 );
			});		

			test("click on buttonElement on the first daily deal content button should just show that variation menu", function() {
				variations.build({deal_selectors:".daily_deal_content"});
				QUnit.triggerEvent( jQuery("#daily_deal_content_box .daily_deal_content:nth-child(1) a:first")[0], "click" );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(1) .dd_variations_menu:visible').length, 1 );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(2) .dd_variations_menu:hidden').length, 1);
				QUnit.triggerEvent( document.body, "click" );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(1) .dd_variations_menu:hidden').length, 1 );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(2) .dd_variations_menu:hidden').length, 1 );
			});

			test("click on buttonElement on the second daily deal content button should just show that variation menu", function() {
				variations.build({deal_selectors:".daily_deal_content"});
				QUnit.triggerEvent( jQuery("#daily_deal_content_box .daily_deal_content:nth-child(2) a:first")[0], "click" );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(1) .dd_variations_menu:hidden').length, 1 );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(2) .dd_variations_menu:visible').length, 1);
				QUnit.triggerEvent( document.body, "click" );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(1) .dd_variations_menu:hidden').length, 1 );
				equal( jQuery('#daily_deal_content_box .daily_deal_content:nth-child(2) .dd_variations_menu:hidden').length, 1 );
			});					
			
		}
	}
	
});
