define(["../../../public/javascripts/app/daily_deals/deal_ticker.js"], function(ticker) {
	
	var tickerNotificationExpectedValue = {
			
			day: 	"00",
			hour: "10",
			min: 	"31",
			sec: 	"03",
			toString: function() {
				return this.hour + ":" + this.min + ":" + this.sec;
			}
							
		},
		
		tickerNotificationWithDayExpectedValue = {
			
			day: "01",
			hour: "10",
			min: "31",
			sec: "03",
			toString: function() {
				return this.day + " day " + this.hour + ":" + this.min + ":" + this.sec;
			}
			
		},
		
		tickerNotificationWithHoursOver24Hours = {
			day: 	"00",
			hour: "58",
			min: 	"31",
			sec: 	"03",
			toString: function() {
				return this.hour + ":" + this.min + ":" + this.sec;
			}			
		};
	
	return {
		runTests: function() {
			
			module("deal_ticker.js with defaults", {
					setup: function() {
						jQuery('#qunit-fixture').append("<div id='time_left_to_buy'>00:00:00</div>");
					},
					teardown: function() {
						jQuery('#time_left_to_buy').remove();
					}										
				} 
			);
			
			test("should default to #time_left_to_buy selector", function() {
				equal("#time_left_to_buy", ticker.build({}).settings.selector );
			});
			
			test("should not update the ticker on configuration", function() {
				ticker.build({});
				equal( jQuery('#time_left_to_buy').text(), '00:00:00' );
			});
			
			test("should update ticker when notified", function() {
				var Deal = function() {},
						t = ticker.build({});
				
				Deal.prototype.timeRemainingPadded = function(includeDay) { return tickerNotificationExpectedValue; };
							
				t.observe(new Deal(), "deal:receivedTick");  
				equal( jQuery('#time_left_to_buy').text(), tickerNotificationExpectedValue.toString() );						
			});
			
			test("should update ticker when notified with hour over 24 hours", function() {
				var Deal = function() {},
						t = ticker.build({});
				
				Deal.prototype.timeRemainingPadded = function(includeDay) { return tickerNotificationWithHoursOver24Hours; };
				t.observe( new Deal(), "deal:receivedTick" );
				equal( jQuery("#time_left_to_buy").text(), tickerNotificationWithHoursOver24Hours.toString() );
			});
			
			module("deal_ticker.js with a different selector", {
				
				setup: function() {
					jQuery('#qunit-fixture').append("<div class='ticker'>00:00:00</div>");
				},
				
				teardown: function() {
					jQuery('#qunit-fixture .ticker').remove();
				}
				
			});
			
			test("should set the selector setting to the supplied selector", function() {
				equal(".ticker", ticker.build({selector: ".ticker"}).settings.selector );
			});
			
			test("should not update the ticker on configuration", function() {
				ticker.build({selector: '.ticker'});
				equal( jQuery('.ticker').text(), '00:00:00' );
			});
			
			test("should update ticker when notified", function() {
				var Deal = function() {},
						t = ticker.build({selector: '.ticker'});
				
				Deal.prototype.timeRemainingPadded = function(includeDay) { return tickerNotificationExpectedValue; };
				
				t.observe( new Deal(), "deal:receivedTick" );  
				equal( jQuery('.ticker').text(), tickerNotificationExpectedValue.toString() );						
			});	
			
			module("deal_ticker.js with default formatTimeRemaining", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div id='time_left_to_buy'>10:30:10</div>");
				},
				teardown: function() {
					jQuery('#time_left_to_buy').remove();
				}										
			});
			
			test("initial the ticker should be 10:30:10", function() {
				equal( jQuery('#time_left_to_buy').text(), "10:30:10" );
			});
			
			test("after timer receives a deal:isOver notification should set ticker to 00:00:00", function() {
				var Deal = function() {},
						t = ticker.build({});
				
				t.observe( new Deal(), "deal:isOver" );
				equal( jQuery("#time_left_to_buy").text(), "00:00:00" );
			});		
					
			module("deal_ticker.js with custom formatTimeRemainng with day", {
				setup: function() {
					jQuery('#qunit-fixture').append("<div id='time_left_to_buy'>00:00:00</div>");
				},
				teardown: function() {
					jQuery('#time_left_to_buy').remove();
				}								
			});
			
			test("before tick notification happens ticker should still be 00:00:00", function() {
				ticker.build({formatTimeRemaining: function(day, hour, min, sec) {
					return day + " day " + hour + ":" + min + ":" + sec;  
				}});
				
				equal( jQuery("#time_left_to_buy").text(), "00:00:00" );				
			});
			
			test("after tick notification happens ticker should still be 1 day ", function() {
				var Deal = function() {},
						t = ticker.build({formatTimeRemaining: function(day, hour, min, sec) {
								return day + " day " + hour + ":" + min + ":" + sec;  
						}});
				
				Deal.prototype.timeRemainingPadded = function(includeDay) { return tickerNotificationWithDayExpectedValue; }
				
				t.observe( new Deal(), "deal:receivedTick" );										
				equal( jQuery("#time_left_to_buy").text(), tickerNotificationWithDayExpectedValue.toString() );				
			});
			
			}
		}
	
});