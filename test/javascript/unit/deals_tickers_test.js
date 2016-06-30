define(["../../../public/javascripts/app/daily_deals/deals_tickers.js"], function(dealsTickers) {
	
	return {
		runTests: function() {
			
			module("deals_tickers.js build");
			
			test("should default to #time_left_to_buy_ selectorPrefix", function() {
				equal("#time_left_to_buy_", dealsTickers.build({}).settings.selectorPrefix );
			});
			
			module("deals_tickers.js events");
			
			test("should observe deals:receivedTick", function() {
				var Deals = function() {},
						tickers = dealsTickers.build({});
				var observed = false;
				tickers.handleTick = function() { observed = true };
				tickers.observe(new Deals(), "deals:receivedTick");  
				ok(observed, "should call handleTick when deals:receivedTick observed")
			});
			
			module("deals_tickers.js time remaining");
			
			test("should be display 1 day", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(1, 47, 4, 37);
				equal(timeRemaining, "1 day");
			});
			
			test("should be display days", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(3, 73, 4, 37);
				equal(timeRemaining, "3 days");
			});
			
			test("should be display 1 hour", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(0, 1, 4, 37);
				equal(timeRemaining, "1 hour");
			});
			
			test("should be display hours", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(0, 7, 4, 37);
				equal(timeRemaining, "7 hours");
			});
			
			test("should be display 1 minute", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(0, 0, 1, 37);
				equal(timeRemaining, "1 min");
			});
			
			test("should be display minutes", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(0, 0, 4, 37);
				equal(timeRemaining, "4 mins");
			});
			
			test("should be display 0 minutes when seconds remaining", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(0, 0, 0, 37);
				equal(timeRemaining, "0 mins");
			});
			
			test("should display deal over when time remaining equal to zero", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(0, 0, 0, 0);
				equal(timeRemaining, "Deal Over");
			});
			
			test("should display deal over when minute remaining less than zero", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(0, 0, -1, 0);
				equal(timeRemaining, "Deal Over");
			});
			
			test("should display deal over when hour remaining less than zero", function() {
				var tickers = dealsTickers.build({});
				var timeRemaining = tickers.formatTimeRemaining(0, -1, 0, 0);
				equal(timeRemaining, "Deal Over");
			});
			
		}
	}
});