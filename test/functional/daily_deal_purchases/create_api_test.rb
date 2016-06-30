require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::CreateApiTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper
  include BraintreeHelper

  context "daily deal API" do

    setup do
      @controller.stubs(:verified_request?).returns(false)
    end

    context "POST to :create" do

      should "reset session when the format is not json" do
        daily_deal = Factory(:daily_deal)
        assert_no_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {
                  :name => "Joseph Blow",
                  :email => "joe@blow.com",
                  :password => "mypassword"
              },
              :daily_deal_purchase => {:quantity => "1", :gift => "0"}
        end

        assert session["user_id"].nil?, "Should have no user in session"
      end

      should "return 406 Not Acceptable with api version 1.0.0 with missing api header" do
        daily_deal = Factory(:daily_deal)
        assert_no_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {
                  :name => "Joseph Blow",
                  :email => "joe@blow.com",
                  :password => "mypassword"
              },
              :daily_deal_purchase => {:quantity => "1", :gift => "0"},
              :format => "json"
        end

        assert_response :not_acceptable
      end

      should "return 406 Not Acceptable with api version 1.0.0 and invalid api header" do
        @request.env['API-Version'] = "9.9.9"
        daily_deal = Factory(:daily_deal)
        assert_no_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {
                  :name => "Joseph Blow",
                  :email => "joe@blow.com",
                  :password => "mypassword"
              },
              :daily_deal_purchase => {:quantity => "1", :gift => "0"},
              :format => "json"
        end

        assert_response :not_acceptable
      end

      should "return 409 Conflict with api version 1.0.0 and new invalid consumer" do
        @request.env['API-Version'] = "1.0.0"
        daily_deal = Factory(:daily_deal)
        assert_no_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {
                  :name => "Joseph Blow",
                  :email => "joe@blow.com",
                  :password => "",
                  :agree_to_terms => "1"
              },
              :daily_deal_purchase => {:quantity => "1", :gift => "0"},
              :format => "json"
        end

        assert_response :conflict
        json = JSON.parse(@response.body)
        assert_equal ["Password can't be blank", "Password is too short (minimum is 6 characters)", "Confirm Password can't be blank"], json["errors"]
      end

      should "return JSON that includes payment_gateway info with api version 1.0.0 with new valid consumer" do
        @request.env['API-Version'] = "1.0.0"
        daily_deal = Factory(:daily_deal)
        assert_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {
                  :name => "Joseph Blow",
                  :email => "joe@blow.com",
                  :password => "mypassword",
                  :agree_to_terms => "1"
              },
              :daily_deal_purchase => {:quantity => "1", :gift => "0"},
              :format => "json"
        end

        assert_response :success
        daily_deal_purchase = assigns(:daily_deal_purchase)
        assert_not_nil daily_deal_purchase

        json = JSON.parse(@response.body)
        assert_equal Braintree::TransparentRedirect.url, json["payment_gateway"]
        assert_equal Braintree::TransparentRedirect.transaction_data(
                         :redirect_url => braintree_redirect_daily_deal_purchase_url(daily_deal_purchase, :host => AppConfig.api_host, :format => "json"),
                         :transaction => {
                             :type => "sale",
                             :amount => "%.2f" % daily_deal_purchase.total_price,
                             :order_id => daily_deal_purchase.analog_purchase_id,
                             :options => {:submit_for_settlement => true}
                         }.merge(braintree_merchant_account_attrs(daily_deal_purchase.publisher)).merge(braintree_custom_field_attrs(daily_deal_purchase.daily_deal.item_code, daily_deal_purchase.publisher))), json["tr_data"]
      end
      
      should "persist the purchase device, when provided, and default the made_via_qr_code to false" do
        @request.env['API-Version'] = "1.0.0"
        daily_deal = Factory(:daily_deal)
        assert_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {
                  :name => "Joseph Blow",
                  :email => "joe@blow.com",
                  :password => "mypassword",
                  :agree_to_terms => "1"
              },
              :daily_deal_purchase => { :quantity => "1", :gift => "0", :device => "iphone-1.2.3"},
              :format => "json"
        end

        assert_response :success
        assert !assigns(:daily_deal_purchase).made_via_qr_code?
        assert_equal "iphone-1.2.3", assigns(:daily_deal_purchase).device
      end
      
      should "allow setting made_via_qr_code when a purchase was initiated by scanning a QR code" do
        @request.env['API-Version'] = "1.0.0"
        daily_deal = Factory(:daily_deal)
        assert_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {
                  :name => "Joseph Blow",
                  :email => "joe@blow.com",
                  :password => "mypassword",
                  :agree_to_terms => "1"
              },
              :daily_deal_purchase => { :made_via_qr_code => "1", :quantity => "1", :gift => "0", :device => "iphone-1.2.3"},
              :format => "json"
        end

        assert_response :success
        assert assigns(:daily_deal_purchase).made_via_qr_code?
      end

      should "return 409 Conflict with api version 1.0.0 and invalid session" do
        @request.env['API-Version'] = "1.0.0"
        daily_deal = Factory(:daily_deal)
        assert_no_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {:session => @controller.send(:verifier).generate({:user_id => 9999})},
              :daily_deal_purchase => {:quantity => "1", :gift => "0"},
              :format => "json"
        end
        assert_response :conflict
        json = JSON.parse(@response.body)
        assert json["errors"].present?
      end

      should "return JSON that includes payment_gateway info with api version 1.0.0 and valid session" do
        Timecop.freeze(Time.zone.now) do
          @request.env['API-Version'] = "1.0.0"
          daily_deal = Factory(:daily_deal)
          publisher = daily_deal.publisher
          consumer = Factory(:consumer, :publisher => publisher)

          assert_difference "DailyDealPurchase.count" do
            xhr :post, :create,
                :daily_deal_id => daily_deal.to_param,
                :consumer => {:session => @controller.send(:verifier).generate({:user_id => consumer.id})},
                :daily_deal_purchase => {:quantity => "1", :gift => "0"},
                :format => "json"
          end

          assert_response :success
          daily_deal_purchase = assigns(:daily_deal_purchase)
          assert_not_nil daily_deal_purchase
          assert_not_nil daily_deal_purchase.publisher

          json = JSON.parse(@response.body)
          assert_equal Braintree::TransparentRedirect.url, json["payment_gateway"]
          assert_equal Braintree::TransparentRedirect.transaction_data(
                           :redirect_url => braintree_redirect_daily_deal_purchase_url(daily_deal_purchase, :host => AppConfig.api_host, :format => "json"),
                           :transaction => {
                               :type => "sale",
                               :amount => "%.2f" % daily_deal_purchase.total_price,
                               :order_id => daily_deal_purchase.analog_purchase_id,
                               :options => {:submit_for_settlement => true}
                           }.merge(braintree_merchant_account_attrs(daily_deal_purchase.publisher)).merge(braintree_custom_field_attrs(daily_deal_purchase.daily_deal.item_code, daily_deal_purchase.publisher))), json["tr_data"]
        end
      end

      should "succeed with api version 1.0.0 and valid session if the deal is inactive but has qr_code_active set" do
        Timecop.freeze(Time.zone.now) do
          @request.env['API-Version'] = "1.0.0"
          daily_deal = Factory(:daily_deal, :start_at => 2.days.ago, :hide_at => 1.days.ago, :qr_code_active => true)
          publisher = daily_deal.publisher
          consumer = Factory(:consumer, :publisher => publisher)

          assert_difference "DailyDealPurchase.count" do
            xhr :post, :create,
                :daily_deal_id => daily_deal.to_param,
                :consumer => {:session => @controller.send(:verifier).generate({:user_id => consumer.id})},
                :daily_deal_purchase => {:quantity => "1", :gift => "0"},
                :format => "json"
          end
          assert_response :success
        end
      end

      should "raise with api version 1.0.0 and valid session if the deal is inactive and does not have qr_code_active set" do
        Timecop.freeze(Time.zone.now) do
          @request.env['API-Version'] = "1.0.0"
          daily_deal = Factory(:daily_deal, :start_at => 2.days.ago, :hide_at => 1.days.ago, :qr_code_active => false)
          publisher = daily_deal.publisher
          consumer = Factory(:consumer, :publisher => publisher)

          assert_raise ActiveRecord::RecordNotFound do
            xhr :post, :create,
                :daily_deal_id => daily_deal.to_param,
                :consumer => {:session => @controller.send(:verifier).generate({:user_id => consumer.id})},
                :daily_deal_purchase => {:quantity => "1", :gift => "0"},
                :format => "json"
          end
          assert_response :success
        end
      end

      should "return 409 Conflict with api version 1.0.0 with session and recipient_names that do not match quantity" do
        @request.env['API-Version'] = "1.0.0"
        daily_deal = Factory(:daily_deal)
        publisher = daily_deal.publisher
        consumer = Factory(:consumer, :publisher => publisher)

        assert_no_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {:session => @controller.send(:verifier).generate({:user_id => consumer.id})},
              :daily_deal_purchase => {:quantity => "2", :gift => "1", :recipient_names => ["John Smith"]},
              :format => "json"
        end

        assert_response :conflict
        json = JSON.parse(@response.body)
        assert_equal ["There should be 2 recipient names"], json["errors"]
      end
      
      should "return 409 Conflict with api version 2.0.0 with session and recipient_names that do not match quantity " +
             "(example with multi-voucher deal)" do
        @request.env['API-Version'] = "2.0.0"
        daily_deal = Factory :daily_deal, :quantity => 20, :certificates_to_generate_per_unit_quantity => 2
        consumer = Factory :consumer, :publisher => daily_deal.publisher
        
        assert_no_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => { :session => @controller.send(:verifier).generate({ :user_id => consumer.id }) },
              :daily_deal_purchase => { :quantity => 3, :gift => "1", :recipient_names => %w(Bob Alice Tim) },
              :format => "json"
        end
        
        assert_response :conflict
        json = JSON.parse(@response.body)
        assert_equal ["There should be 6 recipient names"], json["errors"]
      end
      
      should "successfully create the purchase with the required recipient names on a multi-voucher deal" do
        @request.env['API-Version'] = "2.0.0"
        daily_deal = Factory :daily_deal, :quantity => 20, :certificates_to_generate_per_unit_quantity => 2
        consumer = Factory :consumer, :publisher => daily_deal.publisher

        DailyDealPurchase.destroy_all
        assert_difference "DailyDealPurchase.count", 1 do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => { :session => @controller.send(:verifier).generate({ :user_id => consumer.id }) },
              :daily_deal_purchase => { :quantity => 3, :gift => "1", :recipient_names => %w(Bob Alice Tim Sherry Jane Dylan) },
              :format => "json"
        end
        assert_response :success
        assert_equal %w(Alice Bob Dylan Jane Sherry Tim), DailyDealPurchase.last.recipient_names.sort
      end

      should "return 406 Not Acceptable with api version 1.0.0 with session and consumer" do
        @request.env['API-Version'] = "1.0.0"
        daily_deal = Factory(:daily_deal)
        publisher = daily_deal.publisher
        consumer = Factory(:consumer, :publisher => publisher)

        assert_no_difference "DailyDealPurchase.count" do
          xhr :post, :create,
              :daily_deal_id => daily_deal.to_param,
              :consumer => {
                  :name => "Joseph Blow",
                  :email => "joe@blow.com",
                  :password => "mypassword",
                  :session => @controller.send(:verifier).generate({:user_id => consumer.id})
              },
              :daily_deal_purchase => {:quantity => "1", :gift => "0"},
              :format => "json"
        end

        assert_response :not_acceptable
      end

    end

  end
end
