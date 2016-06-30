require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::ApiTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  context "daily deals controllers api actions" do
    setup do
      Time.stubs(:now).returns(Time.parse("Jan 01, 2011 01:00:00 UTC"))
      @daily_deal = Factory(:daily_deal, {
        :start_at  => Time.parse("Jan 01, 2011 00:00:00 UTC"),
        :hide_at   => Time.parse("Jan 01, 2011 23:55:00 UTC"),
        :reviews => "A wonderful place"
      })
      @daily_deal.publisher.update_attribute :apple_app_store_url, "http://app.url"
    end

    subject { @daily_deal }
    
    context "#status" do

      should "return failure for status.json if the API-Version request header is wrong" do
        @request.env['API-Version'] = "9.9.9"
        get :status, :id => @daily_deal.to_param, :format => "json"
        assert_response :not_acceptable
        assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
        assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
      end

      should "have correct JSON response for status.json (v 1.0.0)" do
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal)

        @request.env['API-Version'] = "1.0.0"
        get :status, :id => @daily_deal.to_param, :format => 'json'
        assert_response :success
        assert_equal "1.0.0", @response.headers["API-Version"]

        expected = {
          "quantity_sold" => 1,
          "updated_at" => "2011-01-01T01:00:00Z"
        }
        assert_equal expected, ActiveSupport::JSON.decode(@response.body)
      end

      should "have correct JSON response for status.json (v 2.0.0)" do
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal)

        @request.env['API-Version'] = "2.0.0"
        get :status, :id => @daily_deal.to_param, :format => 'json'
        assert_response :success
        assert_equal "2.0.0", @response.headers["API-Version"]

        expected = {
          "quantity_sold" => 1,
          "updated_at" => "2011-01-01T01:00:00Z"
        }
        assert_equal expected, ActiveSupport::JSON.decode(@response.body)
      end

      should "return not_found for invalid deal id (v 1.0.0)" do
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal)
        @request.env['API-Version'] = "1.0.0"
        get :status, :id => 9999, :format => 'json'
        assert_response :not_found
      end

      should "return not_found for invalid deal id (v 2.0.0)" do
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal)

        @request.env['API-Version'] = "2.0.0"
        get :status, :id => 9999, :format => 'json'
        assert_response :not_found
      end
      
    end
    
    context "#active" do

      should "return failure for active.json if the API-version request header is wrong" do
        @request.env['API-Version'] = "9.9.9"
        get :active, :id => @daily_deal.to_param, :format => "json"
        assert_response :not_acceptable
        assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
        assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
      end

      should "have correct JSON response for active.json (v 1.0.0)" do
        @request.env['API-Version'] = "1.0.0"
        get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"
        assert_response :success
        assert_equal "1.0.0", @response.headers["API-Version"]

        expected = {
          @daily_deal.uuid => {
            "description" => "<p>this is my description</p>",
            "terms" => "<p>these are my terms</p>",
            "photo" => "#{@daily_deal.photo.url}",
            "highlights" => "<p>A wonderful place</p>",
            "maximum_purchase_quantity" => 10,
            "certificates_to_generate_per_unit_quantity" => 1,
            "value_proposition" => "$30.00 for only $15.00!",
            "featured" => true,
            "shopping_mall" => false,
            "updated_at" => "2011-01-01T01:00:00Z",
            "starts_at" => "2011-01-01T00:00:00Z",
            "ends_at" => "2011-01-01T23:55:00Z",
            "expires_on" => nil,
            "minimum_purchase_quantity" => 1,
            "total_quantity_available" => 20,
            "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
            "location_required" => false,
            "value" => 30.0,
            "price" => 15.0,
            "connections"=> {
              "publisher" => "http://#{AppConfig.api_host}/publishers/#{@daily_deal.publisher.label}.json",
              "advertiser" => "http://#{AppConfig.api_host}/advertisers/#{@daily_deal.advertiser.to_param}.json",
              "status" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/status.json"
            },
            "methods" => {
              "purchase" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/daily_deal_purchases.json"
            }
          }
        }
        assert_equal expected, ActiveSupport::JSON.decode(@response.body)
      end

      should "have correct JSON response for active.json (v 2.0.0)" do
        @request.env['API-Version'] = "2.0.0"
        get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"
        assert_response :success
        assert_equal "2.0.0", @response.headers["API-Version"]

        expected = {
          @daily_deal.uuid => {
            "description" => "<p>this is my description</p>",
            "terms" => "<p>these are my terms</p>",
            "photo" => "#{@daily_deal.photo.url}",
            "highlights" => "<p>A wonderful place</p>",
            "maximum_purchase_quantity" => 10,
            "value_proposition" => "$30.00 for only $15.00!",
            "featured" => true,
            "shopping_mall" => false,
            "updated_at" => "2011-01-01T01:00:00Z",
            "starts_at" => "2011-01-01T00:00:00Z",
            "ends_at" => "2011-01-01T23:55:00Z",
            "expires_on" => nil,
            "minimum_purchase_quantity" => 1,
            "certificates_to_generate_per_unit_quantity" => 1,
            "total_quantity_available" => 20,
            "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
            "location_required" => false,
            "value" => 30.0,
            "price" => 15.0,
            "connections"=> {
              "publisher" => "http://#{AppConfig.api_host}/publishers/#{@daily_deal.publisher.label}.json",
              "advertiser" => "http://#{AppConfig.api_host}/advertisers/#{@daily_deal.advertiser.to_param}.json",
              "status" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/status.json"
            },
            "methods" => {
              "purchase" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/daily_deal_purchases.json"
            }
          }
        }
        assert_equal expected, ActiveSupport::JSON.decode(@response.body)
      end

      should "have correct JSON response for active.json for deal with affiliate_url v1 & v2" do
        @daily_deal.affiliate_url = "http://www.notanaloganalytics.com"
        @daily_deal.save
        @request.env['API-Version'] = "2.0.0"
        get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"
        assert_response :success
        affiliate_url = ActiveSupport::JSON.decode(@response.body)[@daily_deal.uuid]["methods"]["affiliate_url"]
        assert_equal "http://www.notanaloganalytics.com", affiliate_url
      end

      should "return not_found for invalid publisher label (v 1.0.0)" do
        @request.env['API-Version'] = "1.0.0"
        get :active, :publisher_id => 'blahblah', :format => 'json'
        assert_response :not_found
      end

      should "return not_found for invalid publisher label (v 2.0.0)" do
        @request.env['API-Version'] = "2.0.0"
        get :active, :publisher_id => 'blahblah', :format => 'json'
        assert_response :not_found
      end
    
      should "respect shopping_mall setting" do
        @request.env['API-Version'] = "2.0.0"
        assert @daily_deal.update_attribute(:shopping_mall, true)
        get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"
        assert_response :success
        assert_equal "2.0.0", @response.headers["API-Version"]

        expected = {
          @daily_deal.uuid => {
            "description" => "<p>this is my description</p>",
            "terms" => "<p>these are my terms</p>",
            "photo" => "#{@daily_deal.photo.url}",
            "highlights" => "<p>A wonderful place</p>",
            "maximum_purchase_quantity" => 10,
            "certificates_to_generate_per_unit_quantity" => 1,
            "value_proposition" => "$30.00 for only $15.00!",
            "featured" => true,
            "shopping_mall" => true,
            "updated_at" => "2011-01-01T01:00:00Z",
            "starts_at" => "2011-01-01T00:00:00Z",
            "ends_at" => "2011-01-01T23:55:00Z",
            "expires_on" => nil,
            "minimum_purchase_quantity" => 1,
            "total_quantity_available" => 20,
            "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
            "location_required" => false,
            "value" => 30.0,
            "price" => 15.0,
            "connections"=> {
              "publisher" => "http://#{AppConfig.api_host}/publishers/#{@daily_deal.publisher.label}.json",
              "advertiser" => "http://#{AppConfig.api_host}/advertisers/#{@daily_deal.advertiser.to_param}.json",
              "status" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/status.json"
            },
            "methods" => {
              "purchase" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/daily_deal_purchases.json"
            }
          }
        }
        assert_equal expected, ActiveSupport::JSON.decode(@response.body)      
      end

      should "respect summary parameter" do
        @request.env['API-Version'] = "2.0.0"
        get :active, :publisher_id => @daily_deal.publisher.label, :summary => "true", :format => "json"

        assert_response :success
        expected = {
          @daily_deal.uuid => {
            "photo" => "#{@daily_deal.photo.url}",
            "maximum_purchase_quantity" => 10,
            "value_proposition" => "$30.00 for only $15.00!",
            "featured" => true,
            "shopping_mall" => false,
            "updated_at" => "2011-01-01T01:00:00Z",
            "starts_at" => "2011-01-01T00:00:00Z",
            "ends_at" => "2011-01-01T23:55:00Z",
            "expires_on" => nil,
            "minimum_purchase_quantity" => 1,
            "certificates_to_generate_per_unit_quantity" => 1,
            "total_quantity_available" => 20,
            "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
            "location_required" => false,
            "value" => 30.0,
            "price" => 15.0,
            "connections"=> {
              "publisher" => "http://#{AppConfig.api_host}/publishers/#{@daily_deal.publisher.label}.json",
              "advertiser" => "http://#{AppConfig.api_host}/advertisers/#{@daily_deal.advertiser.to_param}.json",
              "status" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/status.json",
              "details" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/details.json"
            },
            "methods" => {
              "purchase" => "http://#{AppConfig.api_host}/daily_deals/#{@daily_deal.to_param}/daily_deal_purchases.json"
            }
          }
        }
        actual = ActiveSupport::JSON.decode(@response.body)
        assert_equal expected, actual
        assert_nil actual["description"]
        assert_nil actual["terms"]
        assert_nil actual["highlights"]
      end
    
      should "return summary format for API version 3.0.0" do
        @request.env['API-Version'] = "3.0.0"
        get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"

        assert_response :success
        expected = [{
          "ends_at" => "2011-01-01T23:55:00Z",
          "featured" => true,
          "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
          "photo" => "http://test.host/images/missing/daily_deals/photos/standard.png",
          "price" => 15.0,
          "shopping_mall" => false,
          "starts_at" => "2011-01-01T00:00:00Z",
          "updated_at" => "2011-01-01T01:00:00Z",
          "sold_out_at" => nil,
          "value" => 30.0,
          "value_proposition" => "$30.00 for only $15.00!",
          "connections" => {
            "details" => "http://test.host/daily_deals/#{@daily_deal.id}/details.json",
            "status" => "http://test.host/daily_deals/#{@daily_deal.id}/status.json",
            "affiliate_url" => nil
          }
        }]
        actual = ActiveSupport::JSON.decode(@response.body)
        assert_equal expected, actual
      end

      should "return summary format for API version 3.0.0 with variations" do
        @daily_deal.publisher.update_attributes! :enable_daily_deal_variations => true , :payment_method => 'travelsavers'
        @daily_deal.publisher.update_attributes! :enable_daily_deal_variations => true
        @variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :price => 1, :value => 2, :travelsavers_product_code => 'TST')
        @request.env['API-Version'] = "3.0.0"
        get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"

        assert_response :success
        expected = [{
                        "ends_at" => "2011-01-01T23:55:00Z",
                        "featured" => true,
                        "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
                        "photo" => "http://test.host/images/missing/daily_deals/photos/standard.png",
                        "price" => 1.0,
                        "shopping_mall" => false,
                        "starts_at" => "2011-01-01T00:00:00Z",
                        "updated_at" => "2011-01-01T01:00:00Z",
                        "sold_out_at" => nil,
                        "value" => 2.0,
                        "value_proposition" => "$30.00 for only $15.00!",
                        "connections" => {
                            "variations"=>
                                "http://test.host/daily_deals/#{@daily_deal.id}/daily_deal_variations.json",
                            "details" => "http://test.host/daily_deals/#{@daily_deal.id}/details.json",
                            "status" => "http://test.host/daily_deals/#{@daily_deal.id}/status.json",
                            "affiliate_url" => nil
                        }
                    }]
        actual = ActiveSupport::JSON.decode(@response.body)
        assert_equal expected, actual
      end

      should "return summary format for API version 3.0.0 for sold out deal" do
        @request.env['API-Version'] = "3.0.0"
        @daily_deal.sold_out_at = Time.parse("2011-01-01T11:55:00Z")
        @daily_deal.save
        get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"

        assert_response :success
        response = ActiveSupport::JSON.decode(@response.body).first
        assert_equal "2011-01-01T11:55:00Z", response["sold_out_at"]
      end

      should "return summary format for API version 3.0.0 with affiliate_url set on deal" do
        @daily_deal.affiliate_url = "http://someawesome.url.com"
        @daily_deal.save
        @request.env['API-Version'] = "3.0.0"
        get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"
        assert_response :success
        response = ActiveSupport::JSON.decode(@response.body).first
        assert_equal "http://someawesome.url.com", response["connections"]["affiliate_url"]
      end
      
      context "version 3.5.0" do
        
        setup do
          @request.env['API-Version'] = "3.5.0"          
        end
        
        should "return summary format with no filter, sort or paging information" do
          @daily_deal.affiliate_url = "http://someawesome.url.com"
          @daily_deal.save
          
          get :active, :publisher_id => @daily_deal.publisher.label, :format => "json"
          assert_response :success
          response = ActiveSupport::JSON.decode(@response.body).first
          assert_equal "http://someawesome.url.com", response["connections"]["affiliate_url"]          
        end
        
        should "return summary format for daily deals only with in the category filter" do
          @publisher          = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
          @entertainment      = Factory(:daily_deal_category, :name => "Entertainment", :publisher => @publisher)
          @restuarant         = Factory(:daily_deal_category, :name => "Restuarant", :publisher => @publisher)
          @automotive         = Factory(:daily_deal_category, :name => "Automotive", :publisher => @publisher)
          
          @entertainment_deal = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @entertainment)        
          @restuarant_deal    = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @restuarant)        
          @automative_deal    = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @automotive)          
          
          get :active, :publisher_id => @publisher.label, :filter => {:categories => "Entertainment,Restuarant"}, :format => "json"
          assert_response :success
          response = ActiveSupport::JSON.decode(@response.body)
          assert_equal 2, response.size
        end
        
        should "return summary form for daily deals in the correct order with sorting on price ascending" do
          @publisher = Factory(:publisher)
          @daily_deal_1 = Factory(:side_daily_deal, :price => 100.00, :publisher => @publisher)
          @daily_deal_2 = Factory(:side_daily_deal, :price => 105.00, :publisher => @publisher)
          @daily_deal_3 = Factory(:side_daily_deal, :price => 99.00, :publisher => @publisher)

          get :active, :publisher_id => @publisher.label, :sort => {:by => "price", :direction => "ascending"}, :format => "json"
          assert_response :success
          response = ActiveSupport::JSON.decode(@response.body)
          assert_equal 3, response.size
          
          assert_equal @daily_deal_3.value_proposition, response.first["value_proposition"]
          assert_equal @daily_deal_1.value_proposition, response.second["value_proposition"]
          assert_equal @daily_deal_2.value_proposition, response.last["value_proposition"]          
        end
        
        should "return summary form for daily deals that on are on the current page" do
          @publisher = Factory(:publisher)
          1.upto(10).each do |i|
            Factory(:side_daily_deal, :publisher => @publisher)
          end
          
          get :active, :publisher_id => @publisher.label, :page => 2, :page_size => 7, :format => "json"
          assert_response :success
          
          response = ActiveSupport::JSON.decode(@response.body)
          assert_equal 3, response.size, "should only have 3 entries on the second page when page size is 7"
          
        end
        
      end
      
    end
    
    context "#show" do

      should "have correct fields for #show for widget" do
        get :show, :id => @daily_deal.to_param, :format => 'json'
        assert_response :success
        actual_deal = ActiveSupport::JSON.decode(@response.body)['daily_deal']
        assert_not_nil actual_deal
        %w{ title
            utc_end_time_in_milliseconds
            utc_start_time_in_milliseconds
            advertiser_logo_url
            publisher_host
            ending_time_in_milliseconds
            number_sold
            link image
            id
            advertiser_name
            is_sold_out }.each do |field|
          assert actual_deal.has_key?(field)
        end
      end
      
    end
    
    context "#details" do
      
      should "have correct response for details action for API version 2.0.0" do
        @request.env['API-Version'] = "2.0.0"
        get :details, :id => @daily_deal.to_param, :format => 'json'
        assert_response :success
        expected = {
                "uuid" => @daily_deal.uuid,
                "description" => "<p>this is my description</p>",
                "terms" => "<p>these are my terms</p>",
                "photo" => "#{@daily_deal.photo.url}",
                "highlights" => "<p>A wonderful place</p>",
                "maximum_purchase_quantity" => 10,
                "minimum_purchase_quantity" => 1,
                "total_quantity_available" => 20,
                "value_proposition" => "$30.00 for only $15.00!",
                "featured" => true,
                "updated_at" => "2011-01-01T01:00:00Z",
                "starts_at" => "2011-01-01T00:00:00Z",
                "ends_at" => "2011-01-01T23:55:00Z",
                "expires_on" => nil,
                "sold_out" => false,
                "value" => 30.0,
                "price" => 15.0,
        }
        actual = ActiveSupport::JSON.decode(@response.body)
        assert_equal expected, actual
      end
    
      should "have correct response for details action for API version 2.1.0" do
        @request.env['API-Version'] = "2.1.0"
        get :details, :id => @daily_deal.to_param, :format => 'json'
        assert_response :success
        expected = {
          "description" => "<p>this is my description</p>",
          "ends_at" => "2011-01-01T23:55:00Z",
          "expires_on" => nil,
          "featured" => true,
          "highlights" => "<p>A wonderful place</p>",
          "location_required" => false,
          "maximum_purchase_quantity" => 10,
          "minimum_purchase_quantity" => 1,
          "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
          "photo" => @daily_deal.photo.url,
          "price" => 15.0,
          "value_proposition" => "$30.00 for only $15.00!",
          "shopping_mall" => false,
          "starts_at" => "2011-01-01T00:00:00Z",
          "terms" => "<p>these are my terms</p>",
          "total_quantity_available" => 20,
          "updated_at" => "2011-01-01T01:00:00Z",
          "uuid" => @daily_deal.uuid,
          "value" => 30.0,
          "connections" => {
            "advertiser" => "http://test.host/advertisers/#{@daily_deal.advertiser.id}.json",
            "publisher" => "http://test.host/publishers/#{@daily_deal.publisher.label}.json",
            "status" => "http://test.host/daily_deals/#{@daily_deal.id}/status.json"
          },
          "methods" => {
            "purchase" => "http://test.host/daily_deals/#{@daily_deal.id}/daily_deal_purchases.json"
          }
        }
        actual = ActiveSupport::JSON.decode(@response.body)
        assert_equal expected, actual
      end
    
      should "have correct response for details action for API version 3.0.0" do
        @request.env['API-Version'] = "3.0.0"
        get :details, :id => @daily_deal.to_param, :format => 'json'
        assert_response :success
        expected = {
          "description" => "<p>this is my description</p>",
          "ends_at" => "2011-01-01T23:55:00Z",
          "expires_on" => nil,
          "featured" => true,
          "highlights" => "<p>A wonderful place</p>",
          "location_required" => false,
          "maximum_purchase_quantity" => 10,
          "minimum_purchase_quantity" => 1,
          "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
          "photo" => @daily_deal.photo.url,
          "price" => 15.0,
          "value_proposition" => "$30.00 for only $15.00!",
          "shopping_mall" => false,
          "starts_at" => "2011-01-01T00:00:00Z",
          "sold_out_at" => nil,
          "terms" => "<p>these are my terms</p>",
          "total_quantity_available" => 20,
          "updated_at" => "2011-01-01T01:00:00Z",
          "uuid" => @daily_deal.uuid,
          "value" => 30.0,
          "connections" => {
            "advertiser" => "http://test.host/advertisers/#{@daily_deal.advertiser.id}.json",
            "publisher" => "http://test.host/publishers/#{@daily_deal.publisher.label}.json",
            "status" => "http://test.host/daily_deals/#{@daily_deal.id}/status.json"
          },
          "methods" => {
            "purchase" => "http://test.host/daily_deals/#{@daily_deal.id}/daily_deal_purchases.json",
            "discount" => "http://test.host/daily_deals/#{@daily_deal.id}/deal_discount.json"
          }
        }
        actual = ActiveSupport::JSON.decode(@response.body)
        assert_equal expected, actual
      end

      should "have correct response for details action for API version 3.0.0 with variations and a publisher using the travelsavers payment method" do
        @daily_deal.publisher.update_attributes! :enable_daily_deal_variations => true , :payment_method => 'travelsavers'
        @daily_deal.publisher.update_attributes! :enable_daily_deal_variations => true
        @variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :price => 1, :value => 2, :travelsavers_product_code => 'TST')
        @request.env['API-Version'] = "3.0.0"
        get :details, :id => @daily_deal.to_param, :format => 'json'
        assert_response :success
        expected = {
            "description" => "<p>this is my description</p>",
            "ends_at" => "2011-01-01T23:55:00Z",
            "expires_on" => nil,
            "featured" => true,
            "highlights" => "<p>A wonderful place</p>",
            "location_required" => false,
            "maximum_purchase_quantity" => 10,
            "minimum_purchase_quantity" => 1,
            "permalink" => "http://sb1.analoganalytics.com/daily_deals/#{@daily_deal.id}",
            "photo" => @daily_deal.photo.url,
            "price" => 1.0,
            "value_proposition" => "$30.00 for only $15.00!",
            "shopping_mall" => false,
            "starts_at" => "2011-01-01T00:00:00Z",
            "sold_out_at" => nil,
            "terms" => "<p>these are my terms</p>",
            "total_quantity_available" => 20,
            "updated_at" => "2011-01-01T01:00:00Z",
            "uuid" => @daily_deal.uuid,
            "value" => 2.0,
            "connections" => {
                "advertiser" => "http://test.host/advertisers/#{@daily_deal.advertiser.id}.json",
                "publisher" => "http://test.host/publishers/#{@daily_deal.publisher.label}.json",
                "status" => "http://test.host/daily_deals/#{@daily_deal.id}/status.json",
                "variations"=>"http://test.host/daily_deals/#{@daily_deal.id}/daily_deal_variations.json"
            },
            "methods" => {
                "purchase" => "http://test.host/daily_deals/#{@daily_deal.id}/daily_deal_purchases.json",
                "purchase_url"=> "http://test.host/daily_deals/#{@daily_deal.id}/daily_deal_purchases/new",
                "discount" => "http://test.host/daily_deals/#{@daily_deal.id}/deal_discount.json"
            }
        }
        actual = ActiveSupport::JSON.decode(@response.body)
        assert_equal expected, actual
      end

      should "have correct response for details action for API version 3.0.0 for sold out deal" do
        @request.env['API-Version'] = "3.0.0"
        @daily_deal.sold_out_at = Time.parse("2011-01-01T11:55:00Z")
        @daily_deal.save
        get :details, :id => @daily_deal.to_param, :format => 'json'

        assert_response :success
        response = ActiveSupport::JSON.decode(@response.body)
        assert_equal "2011-01-01T11:55:00Z", response["sold_out_at"]
      end
      
    end

    context "#qr_encoded" do
      should "redirect to details action for qr_encoded as JSON" do
        @request.env['API-Version'] = "2.1.0"
        get :qr_encoded, :base36 => @daily_deal.id.to_s(36), :format => "json"
        assert_redirected_to details_daily_deal_url(@daily_deal, :protocol => "http", :host => AppConfig.api_host, :format => "json")
      end

      should "redirect to details action for qr_encoded as JSON if the deal is not active but has qr_code active set" do
        @daily_deal.update_attributes! :start_at => 2.days.ago, :hide_at => 1.days.ago, :qr_code_active => true
        @request.env['API-Version'] = "2.1.0"
        get :qr_encoded, :base36 => @daily_deal.id.to_s(36), :format => "json"
        assert_redirected_to details_daily_deal_url(@daily_deal, :protocol => "http", :host => AppConfig.api_host, :format => "json")
      end

      should "raise ActiveRecord::RecordNotFound for qr_encoded as JSON if the deal is not active and does not have qr_code active set" do
        @daily_deal.update_attributes! :start_at => 2.days.ago, :hide_at => 1.days.ago, :qr_code_active => false
        @request.env['API-Version'] = "2.1.0"
        assert_raise ActiveRecord::RecordNotFound do
          get :qr_encoded, :base36 => @daily_deal.id.to_s(36), :format => "json"
        end
      end

      should "redirect to the one_click purchase page if the user agent is a mobile browser" do
        @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
        get :qr_encoded, :base36 => @daily_deal.id.to_s(36)
        assert_redirected_to new_daily_deal_one_click_purchase_url(@daily_deal, :host => @daily_deal.publisher.daily_deal_host)
      end

      should "redirect to show action for qr_encoded as HTML for non-mobile user agent" do
      @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.56 Safari/535.11"
        get :qr_encoded, :base36 => @daily_deal.id.to_s(36)
        assert_redirected_to daily_deal_url(@daily_deal, :host => @daily_deal.publisher.daily_deal_host)
      end      
    end
    
    context "#deal_discount" do
      
      setup do
        @publisher = @daily_deal.publisher
        @discount  = Factory(:discount, :publisher => @publisher)
        @publisher.reload
      end
      
      should "have a discount associated with a publisher" do
        assert_not_nil @publisher.discounts.usable.find(@discount.id)
      end
      
      should "return :not_acceptable for version 1.0.0" do
        @request.env["API-Version"] = "1.0.0"
        post :deal_discount, :id => @daily_deal, :consumer => {:discount => "blah"}, :format => "json"
        assert_response :not_acceptable
      end
      
      should "return :not_acceptable for version 2.0.0" do
        @request.env["API-Version"] = "2.0.0"
        post :deal_discount, :id => @daily_deal, :consumer => {:discount => "blah"}, :format => "json"
        assert_response :not_acceptable
      end
      
      context "with version 3.0.0" do
        
        setup do
          @request.env["API-Version"] = "3.0.0"
        end
        
        should "return :not_acceptable with invalid discount code" do
          post :deal_discount, :id => @daily_deal, :consumer => {:discount => "blah"}, :format => "json"
          assert_response :not_acceptable
        end
        
        should "return :not_accestable with a valid discount code, but discount is not longer usable" do
          @discount.use!
          assert @discount.reload.used?
          post :deal_discount, :id => @daily_deal, :consumer => {:discount => @discount.code}, :format => "json"
          assert_response :not_acceptable
        end
        
        should "return a valid response with a valid discount code" do
          post :deal_discount, :id => @daily_deal, :consumer => {:discount => @discount.code}, :format => "json"
          json      = ActiveSupport::JSON.decode(@response.body)
          expected  = {
              "discount_uuid" => @discount.uuid,
              "amount" => @discount.amount.to_f
            }
          assert_equal expected, json
        end
        
      end
      
      
    end
    
  end
end
