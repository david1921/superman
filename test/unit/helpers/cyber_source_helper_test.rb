require File.dirname(__FILE__) + "/../../test_helper"

class CyberSourceHelperTest < ActionView::TestCase
  context "with a daily deal purchase and a failed order" do
    setup do
      publisher = Factory(:publisher, :support_email_address => "support@example.com", :support_phone_number => "(858) 555-1212")
      @daily_deal_purchase = Factory(:daily_deal_purchase, :daily_deal => Factory(:daily_deal, :publisher => publisher))

      @parameters = {
        "reasonCode" => "151"
      }
      @cyber_source_order = CyberSource::Order.new(@parameters)
      @response = ActionController::Response.new
    end
    
    should "return an error div from cyber_source_error_messages" do
      render :text => cyber_source_error_messages(@daily_deal_purchase, @cyber_source_order)

      assert_select "div.daily_deal_payment_errors", 1 do
        assert_select "h3.header", 1
        assert_select "h3.header", "Sorry, we were unable to process your payment:"
        
        assert_select "ul", 1 do
          assert_select "li", 1
          assert_select "li", "The payment server timed out"
        end
        assert_select "h3.footer", 1
        assert_select "h3.footer", "Please contact customer service at support@example.com or (858) 555-1212"
      end
    end
  end
end
