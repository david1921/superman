require File.dirname(__FILE__) + "/../test_helper"

class ThirdPartyEventsControllerTest < ActionController::TestCase
  def setup
    @deal = Factory(:daily_deal)
    @visitor = Factory(:subscriber)
    @params_landing_min = {:session_id => "teacanbebetter", :event => {:action => "landing"}, :third_party => {:id => @deal.advertiser.id}}
    @params_single_purchase_min = {:session_id => "teacanbebetter", :event => {:action => "purchase"}, :purchases => {
      "0" => {:transaction_id => "5b5cd0da3121fc53b4",
        :quantity => 1,
        :product_id => 371289,
        :price => "29.0"} }
      }
    @params_double_purchase_min = {:session_id => "teacanbebetter", :event => {:action => "purchase"}, :purchases => {
        "0" => {:transaction_id => "5b5cd0da3121fc53b4",
          :quantity => 1,
          :product_id => 371289,
          :price => "29.0"},
        "1" => {:transaction_id => "5b5cd0da3121fc53b4",
          :quantity => 2,
          :product_id => 371111,
          :price => "15.0"} }
        }
  end

  test "routing" do
    assert_routing '/tpe/tracker.js', {:controller => 'third_party_events', :action => 'tracker', :format => 'js'}
    assert_routing '/tpe/create_as_get', {:controller => 'third_party_events', :action => 'create_as_get'}
    assert_routing '/tpe/example', {:controller => 'third_party_events', :action => 'example'}
  end

  context "minimum params" do
    context "Action 'redirect'" do
      should "create an event" do
        assert_difference "ThirdPartyEvent.count" do
          get :create_as_get, {:session_id => "coffeeisgood", :event => {:action => "redirect"}, :third_party => {:id => @deal.advertiser.id}, :target => {:id => @deal.id, :type => "DailyDeal"}, :visitor => {:email => @visitor.email, :zip_code => @visitor.zip_code }}
          assert :success
          assert_not_nil assigns(:event)
        end
      end
    end

    context "Action 'landing'" do
      should "create an event" do
        assert_difference "ThirdPartyEvent.count" do
          get :create_as_get, @params_landing_min
          assert :success
          assert_not_nil assigns(:event)
        end
      end
    end
    context "Action 'purchase'" do
      should "create an event" do
        assert_difference "ThirdPartyEvent.count" do
          get :create_as_get, @params_single_purchase_min
          assert :success
          assert_not_nil assigns(:event)
        end
      end
    end
    context "Action 'multi-purchase'" do
      should "create an event" do
        assert_difference "ThirdPartyEvent.count" do
          get :create_as_get, @params_double_purchase_min
          assert :success
          assert_not_nil assigns(:event)
        end
      end
    end
  end
  should "record additional purchase data for purchases" do
    assert_difference "ThirdPartyEventPurchase.count" do
      get :create_as_get, @params_single_purchase_min 
      assert_response :success
    end
    assert_difference "ThirdPartyEventPurchase.count", 2 do
      get :create_as_get, @params_double_purchase_min 
      assert_response :success
    end
  end
  
  
  should "work with 'new' subscribers" do
    assert_difference "Subscriber.count" do
      get :create_as_get, @params_landing_min.merge({:visitor => {:email => "non_existant_subscriber@example.com"}})    
      assert_response :success
      assert_not_nil @visitor
      assert @visitor.email, "non_existant_subscriber@example.com"
    end
  end
  
end