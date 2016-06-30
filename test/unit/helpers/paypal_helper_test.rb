require File.dirname(__FILE__) + "/../../test_helper"

class PaypalHelperTest < ActionView::TestCase
	test "paypal_cancel_return_url with no value" do
	  daily_deal = Factory(:daily_deal, :value_proposition => "the best deal ever")
	  ddp = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
	  publisher = daily_deal.publisher
	  publisher.label = 'couponcity'
	  publisher.production_host = 'deals.couponcity.com'
	  assert_equal "http://#{publisher.production_host}/publishers/#{publisher.label}/deal-of-the-day", paypal_cancel_return_url(ddp)
	end
	test "paypal_cancel_return_url with value" do
	  daily_deal = Factory(:daily_deal, :value_proposition => "the best deal ever")
	  ddp = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
	  publisher = daily_deal.publisher
	  publisher.label = 'couponcity'
	  publisher.production_host = 'deals.couponcity.com'
	  publisher.custom_paypal_cancel_return_url = 'http://google.com'
	  assert_equal 'http://google.com', paypal_cancel_return_url(ddp)
	end
end