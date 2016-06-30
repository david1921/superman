define(["../../../public/javascripts/app/daily_deals/deal.js"], function(deal) {
	
	return {
		runTests: function() {
			
			module("deal.js build");
			
			test("should set the dealUrl to http://localhost/daily_deals/1.json", function() {
				var d = deal.build("http://localhost/daily_deals/1.json");
				equal(d.dealUrl, "http://localhost/daily_deals/1.json");
			});
			
			test("should initially have 0 observers", function() {
				equal(deal.build().observers.length, 0);
			});
			
			module("deal.js add observer");
			
			test("should add a new observer", function() {
				var d = deal.build(),
						Observer = function() {},
						anObserver = new Observer();
						
				d.addObserver(anObserver);
				
				equal(d.observers.length, 1, "should have one observer");
				equal(d.observers[0], anObserver);
			});
			
			module("deal.js add observers");
			
			test("should be able to add multiple observers", function() {
				var d = deal.build(),
						Observer = function() {},
						anObserver = new Observer(),
						anotherObserver = new Observer();
						
				d.addObservers([anObserver, anotherObserver]);
				
				equal(d.observers.length, 2, "should have two observers");
				equal(d.observers[0], anObserver);
				equal(d.observers[1], anotherObserver);
				
			});
			
			module("deal.js update with null data");
			
			test("should not update the internal deal information", function() {
				var d = deal.build("http://localhost/daily_deals/1.json");
				d.update(null);
				
				ok(!d.dealId, "should not have dealId");
				ok(!d.utcStartTimeInMilliseconds, "should not have utcStartTimeInMilliseconds");
				ok(!d.utcEndTimeInMilliseconds, "should not have utcEndTimeInMilliseconds");
				ok(!d.numberSold, "should not have numberSold");
				ok(!d.soldOut, "shoudl not have soldOut");
			});
			
			module("deal.js update with valid data");
			
			test("should update the internal deal information", function() {
				var d = deal.build("http://localhost/daily_deals/1.json"),						
						data = {
							id: 2,
							utc_start_time_in_milliseconds: 1305604800000,
							utc_end_time_in_milliseconds: 1306253886000,
							number_sold: "2",
							is_sold_out: false
						};
				d.update(data);
				
				equal(d.dealId, data.id);
				equal(d.utcStartTimeInMilliseconds, data.utc_start_time_in_milliseconds);
				equal(d.utcEndTimeInMilliseconds, data.utc_end_time_in_milliseconds);
				equal(d.numberSold, data.number_sold);
				equal(d.soldOut, data.is_sold_out);
			});
			
			module("deal.js events");
			
			test("should notify observers of number sold update", function() {
				var d = deal.build("http://localhost/daily_deals/1.json"),                                           
				data = {
					id: 2,
					utc_start_time_in_milliseconds: 1305604800000,
					utc_end_time_in_milliseconds: 1306253886000,
					number_sold: "2",
					is_sold_out: false
				};
				
				var observerCalled = false,
				Observer = function() {};
				
				Observer.prototype.observe = function(deal, message) {
					if (message == 'deal:numberSoldUpdated' )
					observerCalled = true
				}
				
				var anObserver = new Observer(),
						anotherObserver = new Observer();
				d.addObservers([anObserver, anotherObserver]);
				d.update(data);
				
				ok(observerCalled, 'observer should have been notified about deal:numberSoldUpdated');
				equal(d.observers.length, 2, "should have two observers");
				equal(d.observers[0], anObserver);
				equal(d.observers[1], anotherObserver);
			});
			
			test("should notify observers when tick received", function() {
				var d = deal.build("http://localhost/daily_deals/1.json"),                                           
				data = {
					id: 2,
					utc_start_time_in_milliseconds: 1305604800000,
					utc_end_time_in_milliseconds: 1306253886000,
					number_sold: "2",
					is_sold_out: false
				};
				
				// mock the time remaining so test runs consistently.
				d.timeRemainingInMilliseconds = function() {
					return 1308583941450;
				}
				
				var observerCalled = false,
				Observer = function() {};
				
				Observer.prototype.observe = function(deal, message) {
					if (message == 'deal:receivedTick' )
					observerCalled = true;
				}
				
				var anObserver = new Observer(),
						anotherObserver = new Observer();
				d.addObservers([anObserver, anotherObserver]);
				d.update(data);
				d.handleTick();
				ok(observerCalled, 'observer should have been notified about deal:receivedTick');
				equal(d.observers.length, 2, "should have two observers");
				equal(d.observers[0], anObserver);
				equal(d.observers[1], anotherObserver);
			});
			
			test("should NOT notify observers of tick before deal is updated", function() {
				var d = deal.build("http://localhost/daily_deals/1.json"),                                           
				data = {
					id: 2,
					utc_start_time_in_milliseconds: 1305604800000,
					utc_end_time_in_milliseconds: 1306253886000,
					number_sold: "2",
					is_sold_out: true
				};
				
				// mock the time remaining so test runs consistently.
				d.timeRemainingInMilliseconds = function() {
					return 1308583941450;
				}
				
				var observerCalled = false,
				Observer = function() {};
				
				Observer.prototype.observe = function(deal, message) {
					if (message == 'deal:receivedTick' )
					observerCalled = true
				}
				
				d.addObserver( new Observer() );
				d.handleTick();
				equal( false, observerCalled, 'observer should NOT have been notified about deal:receivedTick');
			});
			
			test("should notify observers when deal is over at time of update", function() {
				var d = deal.build("http://localhost/daily_deals/1.json"),                                           
				data = {
					id: 2,
					utc_start_time_in_milliseconds: 1305604800000,
					utc_end_time_in_milliseconds: 1306253886000,
					number_sold: "2",
					is_sold_out: true
				};
				
				var observerCalled = false,
				Observer = function() {};
				
				Observer.prototype.observe = function(deal, message) {
					if (message == 'deal:isOver' )
					observerCalled = true
				}
				
				d.addObserver( new Observer() );
				d.update(data);
				ok( observerCalled, 'observer should have been notified about deal:isOver');
			});
			
			test("should notify observers when deal is over when tick received", function() {
				var d = deal.build("http://localhost/daily_deals/1.json"),                                           
				data = {
					id: 2,
					utc_start_time_in_milliseconds: 1305604800000,
					utc_end_time_in_milliseconds: 1306253886000,
					number_sold: "2",
					is_sold_out: true
				};
				
				var observerCalled = false,
				Observer = function() {};
				
				Observer.prototype.observe = function(deal, message) {
					if (message == 'deal:isOver' )
					observerCalled = true
				}
				
				d.addObserver( new Observer() );
				d.update(data);
				d.handleTick();
				ok( observerCalled, 'observer should have been notified about deal:isOver');
			});
			
			module("timeRemainingPadded is under 24 hours and day is not included");
			
			test("should return the correctly padded time", function() {
				var timeRemaining = null,
						d 	= deal.build("http://localhost/daily_deals/1.json"),
						data = {
							id: 1,
							utc_start_time_in_milliseconds: 1308294540000,
							utc_end_time_in_milliseconds: 1308634205000,
							number_sold: "2",
							is_sold_out: false
						};
				
				// mock the current time so test runs consistently.
				d.currentTime = function() {
					return 1308583941450;
				}		
				
				d.update(data);
				timeRemaining = d.timeRemainingPadded(false);
				equal(timeRemaining.day,  "00", "for day");
				equal(timeRemaining.hour, "13", "for hour");
				equal(timeRemaining.min,  "57", "for min");
				equal(timeRemaining.sec,  "43", "for sec");
			});
			
			module("timeRemainingPadded is under 24 hours and day is included");
			
			test("should return the correctly padded time", function() {
				var timeRemaining = null,
						d 	= deal.build("http://localhost/daily_deals/1.json"),
						data = {
							id: 1,
							utc_start_time_in_milliseconds: 1308294540000,
							utc_end_time_in_milliseconds: 1308634205000,
							number_sold: "2",
							is_sold_out: false
						};
				
				// mock the current time so test runs consistently.
				d.currentTime = function() {
					return 1308583941450;
				}		
				
				d.update(data);
				timeRemaining = d.timeRemainingPadded(true);
				equal(timeRemaining.day,  "00", "for day");
				equal(timeRemaining.hour, "13", "for hour");
				equal(timeRemaining.min,  "57", "for min");
				equal(timeRemaining.sec,  "43", "for sec");
			});
			
			module("timeRemainingPadded is over 24 hours and day is not included");
			
			test("should return the correct time padding", function(){
				var timeRemaining = null,
						d 	= deal.build("http://localhost/daily_deals/1.json"),
						data = {
							id: 1,
							utc_start_time_in_milliseconds: 1308294540000,
							utc_end_time_in_milliseconds: 1308756938000,
							number_sold: "2",
							is_sold_out: false
						};
				
				// mock the current time so test runs consistently.
				d.currentTime = function() {
					return 1308583941450;
				}				
				
				d.update(data);
				timeRemaining = d.timeRemainingPadded(false);
				equal(timeRemaining.day,  "00", "for day");
				equal(timeRemaining.hour, "48", "for hour");
				equal(timeRemaining.min,  "03", "for min");
				equal(timeRemaining.sec,  "16", "for sec");				
			});
			
			module("timeRemainingPadded is over 24 hours and day is included");
			
			test("should return the correct time padding", function(){
				var timeRemaining = null,
						d 	= deal.build("http://localhost/daily_deals/1.json"),
						data = {
							id: 1,
							utc_start_time_in_milliseconds: 1308294540000,
							utc_end_time_in_milliseconds: 1308756938000,
							number_sold: "2",
							is_sold_out: false
						};
				
				// mock the current time so test runs consistently.
				d.currentTime = function() {
					return 1308583941450;
				}				
				
				d.update(data);
				timeRemaining = d.timeRemainingPadded(true);
				equal(timeRemaining.day,  "02", "for day");
				equal(timeRemaining.hour, "00", "for hour");
				equal(timeRemaining.min,  "03", "for min");
				equal(timeRemaining.sec,  "16", "for sec");				
			});
			
		}
	}
	
});