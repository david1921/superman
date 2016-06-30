require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealVariationsController::ApiTest < ActionController::TestCase
  tests DailyDealVariationsController
  include DailyDealVariationsHelper

  context "daily deal variation controllers api actions" do
    setup do
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.update_attributes! :enable_daily_deal_variations => true
      @daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
    end

    should "return failure for status.json if the API-Version request header is wrong" do
      @request.env['API-Version'] = "9.9.9"
      get :index, :id => @daily_deal_variation.to_param, :daily_deal_id => @daily_deal.to_param, :format => "json"
      assert_response :not_acceptable
      assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
      assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
    end

    should "have correct JSON response for index.json (v 3.0.0) and include daily deal variations" do
      @request.env['API-Version'] = "3.0.0"
      get :index, :id => @daily_deal_variation.to_param, :daily_deal_id => @daily_deal.to_param, :format => 'json'
      assert_response :success
      assert_equal "3.0.0", @response.headers["API-Version"]
      ddv = @daily_deal_variation
      expected =  [{'value_proposition' => ddv.value_proposition,
                    'value' => ddv.value.to_f,
                    'price' => ddv.price.to_f,
                    'minimum_purchase_quantity' => ddv.min_quantity,
                    'maximum_purchase_quantity' => ddv.max_quantity,
                    'total_quantity_available' => ddv.quantity,
                    'quantity_sold' => ddv.number_sold,
                    'daily_deal_variation_id' => ddv.id  ,
                    'terms' => ddv.terms
                   }]
      assert_equal expected, ActiveSupport::JSON.decode(@response.body)
    end
  end
end
