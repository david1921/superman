define(["../../../public/javascripts/app/daily_deals/deal_notifier.js"], function(notifier) {
		
		
	return {
		runTests: function() {
			
			module("deal_notifier.js build");
			
			test("should initially have 0 observers", function() {
				equal(notifier.build().observers.length, 0);
			});
			
			test("should set stopCountdown to false", function() {
				equal(notifier.build().stopCountdown, false);
			});
			
			test("should set stopPolling to false", function() {
				equal(notifier.build().stopPolling, false);
			});
			
			module("deal_notifier.js add observer");
			
			test("should add a new observer", function() {
				var n = notifier.build(),
						Observer = function() {},
						anObserver = new Observer();
						
				n.addObserver(anObserver);
				
				equal(n.observers.length, 1, "should have one observer");
				equal(n.observers[0], anObserver);
			});
			
			module("deal_notifier.js add observers");
			
			test("should be able to add multiple observers", function() {
				var n = notifier.build(),
						Observer	 			= function() {},
						anObserver			= new Observer(),
						anotherObserver = new Observer();
						
				n.addObservers([anObserver, anotherObserver]);
				
				equal(n.observers.length, 2, "should have two observers");
				equal(n.observers[0], anObserver);
				equal(n.observers[1], anotherObserver);
				
			});
			
			module("deal_notifier.js tick when countdown is still active");
			
			test("should call observe with tick on observers", function() {
				var n = notifier.build(),
						observerCalled = false,
						Observer = function() {};
				
				Observer.prototype.observe = function(deal, message) {
					if (message == 'event:tick')
						observerCalled = true;
				}
										
				n.addObserver( new Observer() );
				n.tick();
				ok( observerCalled, "observer shoud have been notified about tick");
			});
			
			module("deal_notifier.js tick when countdown is stopped");
			
			test("should not call observe with tick on observers", function() {
				var n = notifier.build(),
						observerCalled = false,
						Observer = function() {};

				Observer.prototype.observe = function(deal, message) {
					if (message == 'event:tick')
						observerCalled = true;
				}		
				
				n.addObserver( new Observer() );
				n.stopCountdown = true;
				n.tick();
				ok( !observerCalled, "observer should not be called with tick");
			});
			
			module("deal_notifier.js poll when polling is still active");
			
			test("should call observe with poll on observers", function() {
				var n = notifier.build(),
						observerCalled 	= false,
						Observer				= function() {};
				
				Observer.prototype.observe = function(deal, message) {
					if (message == 'event:poll')
						observerCalled = true;
				}
										
				n.addObserver( new Observer() );
				n.poll();
				ok( observerCalled, "observer shoud have been notified about poll");
			});
			
			module("deal_notifier.js poll when polling is stopped");
			
			test("should not call observe with poll on observers", function() {
				var n  = notifier.build(),
						observerCalled = false,
						Observer = function() {};

				Observer.prototype.observe = function(deal, message) {
					if (message == 'event:poll')
						observerCalled = true;
				}		
				
				n.addObserver( new Observer() );
				n.stopPolling = true;
				n.poll();
				ok( !observerCalled, "observer should not be called with poll");
			});
			
		}
	}
	
});