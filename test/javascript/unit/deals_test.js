define(["../../../public/javascripts/app/daily_deals/deals.js"], function(dealz) {
	
	return {
		runTests: function() {
			
			module("deals.js build");
			
			test("should set the dealsUrl to http://localhost/daily_deals/1/deals.json", function() {
				var deals = dealz.build("http://localhost/daily_deals/1/deals.json");
				equal(deals.dealsUrl, "http://localhost/daily_deals/1/deals.json");
			});
			
			test("should initially have 0 observers", function() {
				equal(dealz.build().observers.length, 0);
			});
			
			module("deals.js add observer");
			
			test("should add a new observer", function() {
				var deals = dealz.build(),
						Observer = function() {},
						anObserver = new Observer();
						
				deals.addObserver(anObserver);
				
				equal(deals.observers.length, 1, "should have one observer");
				equal(deals.observers[0], anObserver);
			});
			
			module("deals.js add observers");
			
			test("should be able to add multiple observers", function() {
				var deals = dealz.build(),
						Observer = function() {},
						anObserver = new Observer(),
						anotherObserver = new Observer();
						
				deals.addObservers([anObserver, anotherObserver]);
				
				equal(deals.observers.length, 2, "should have two observers");
				equal(deals.observers[0], anObserver);
				equal(deals.observers[1], anotherObserver);
				
			});
			
			module("deals.js update with null data");
			
			test("should not update the internal deal information", function() {
				var deals = dealz.build("http://localhost/daily_deals/1/deals.json");
				deals.update(null);
				
				ok(!deals.data, "should not have data");
			});
			
			module("deals.js update with valid data");
			
			test("should update the internal deal information", function() {
				var deals = dealz.build("http://localhost/daily_deals/1/deals.json"),						
						data = {
							id: 2,
							utc_start_time_in_milliseconds: 1305604800000,
							utc_end_time_in_milliseconds: 1306253886000,
							number_sold: "2",
							is_sold_out: false
						};
				deals.update(data);
				
				equal(deals.deals, data);
			});
			
			module("deals.js events");
			
			test("should notify observers when tick received", function() {
				var deals = dealz.build("http://localhost/daily_deals/1/deals.json"),                                           
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
					if (message == 'deals:receivedTick' )
					observerCalled = true;
				}
				
				deals.addObserver( new Observer() );
				deals.update(data);
				deals.handleTick();
				ok( observerCalled, 'observer should have been notified about deals:receivedTick');
			});
			
			test("should NOT notify observers of tick before deal is updated", function() {
				var deals = dealz.build("http://localhost/daily_deals/1/deals.json"),                                           
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
					if (message == 'deals:receivedTick' )
					observerCalled = true;
				}
				
				deals.addObserver( new Observer() );
				deals.handleTick();
				equal( false, observerCalled, 'observer should NOT have been notified about deal:receivedTick');
			});
		}
	}
});