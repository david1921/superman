require File.dirname(__FILE__) + "/../test_helper"

class Api2ControllerTest < ActionController::TestCase
  def test_root_routing
    options = { :protocol => "https", :controller => "api2", :action => "root", :format => "xml" }
    assert_routing "/api2", options
  end

  def test_api_root_with_no_authentication
    for_each_api_version do |api_version|
      get :root, :format => :xml
      assert_response :unauthorized, api_version
      assert_nil @response.headers['API-Version'], api_version
    end
  end
  
  def test_api_root_with_bad_password
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "foobar")
      get :root, :format => :xml
      assert_response :unauthorized, api_version
      assert_nil @response.headers['API-Version'], api_version
    end
  end
  
  def test_api_root
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
      get :root, :format => :xml
      assert_response :success, api_version
      assert_equal "application/xml", @response.content_type, api_version
      assert_equal api_version, @response.headers['API-Version']

      root = REXML::Document.new(@response.body).root
      assert_equal "services", root.name, api_version
      
      returned_services = {}.tap do |hash|
        root.each_element do |elem|
          assert_equal "service", elem.name, api_version
          name = elem.elements["name"].text
          href = elem.elements["link"].attributes["href"]
          hash[name] = href
        end
      end
      expected_services = returning({}) do |hash|
        %w{ WebCoupons }.each do |name|
          hash[name] = eval("api2_#{name.underscore}_url")
        end
      end
      assert_equal expected_services, returned_services, api_version
    end
  end
  
  def test_api_root_with_missing_version_header
    set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
    get :root, :format => :xml
    assert_response :not_acceptable
    assert_equal "2.0.0", @response.headers['API-Version']
    assert_api_error_response_xml /missing or invalid API-Version/i
  end

  def test_api_root_with_invalid_version_header
    set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
    @request.env['API-Version'] = "2.0"
    get :root, :format => :xml
    assert_response :not_acceptable
    assert_equal "2.0.0", @response.headers['API-Version']
    assert_api_error_response_xml /missing or invalid API-Version/i
  end
  
  def test_index_with_no_authentication
    for_each_api_version do |api_version|
      get :web_coupons, :publisher_label => "mysdh-austin", :format => :xml
      assert_response :unauthorized
      assert_nil @response.headers['API-Version'], api_version
    end
  end

  def test_index_with_bad_password
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "foobar")
      get :web_coupons, :publisher_label => "mysdh-austin", :format => :xml
      assert_response :unauthorized
      assert_nil @response.headers['API-Version'], api_version
    end
  end
  
  def test_index_with_missing_publisher
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
      get :web_coupons, :format => :xml
      assert_response :forbidden, api_version
      assert_equal api_version, @response.headers['API-Version']
    end
  end
  
  def test_index_with_invalid_publisher
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
      get :web_coupons, :publisher_label => "nosuch", :format => :xml
      assert_response :forbidden
      assert_equal api_version, @response.headers['API-Version']
    end
  end
  
  def test_index_with_user_publisher_mismatch
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
      get :web_coupons, :publisher_label => "myspace", :format => :xml
      assert_response :forbidden
      assert_equal api_version, @response.headers['API-Version']
    end
  end
  
  def test_index
    publisher = publishers(:sdh_austin)
    advertiser, offer_1, offer_2, offer_3 = nil
    
    Timecop.freeze(Time.utc(2010, 3, 15, 12).in_time_zone) do
      advertiser = Factory(:advertiser, :publisher => publisher)
    end

    Timecop.freeze(Time.utc(2010, 3, 15, 12, 35, 56).in_time_zone) do
      offer_1 = advertiser.offers.create!(:message => "Offer 1")
    end

    Timecop.freeze(Time.utc(2010, 3, 15, 12, 35, 56).in_time_zone) do
      offer_2 = advertiser.offers.create!(:message => "Offer 2")
    end
    Timecop.freeze(Time.utc(2010, 3, 15, 12, 35, 57).in_time_zone) do
      offer_2.update_attributes! :terms => "New terms"
    end
    
    Timecop.freeze(Time.utc(2010, 3, 15, 12, 0, 1).in_time_zone) do
      advertiser = Factory(:advertiser, :publisher => publisher)
    end

    Timecop.freeze(Time.utc(2010, 3, 15, 12, 35, 56).in_time_zone) do
      offer_3 = advertiser.offers.create!(:message => "Offer 3")
    end
    Timecop.freeze(Time.utc(2010, 3, 15, 12, 35, 58).in_time_zone) do
      offer_3.delete!
    end

    Timecop.freeze(Time.utc(2010, 3, 15, 12, 36, 8).in_time_zone) do
      for_each_api_version do |api_version|
        set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
        get :web_coupons, :publisher_label => "mysdh-austin", :format => :xml
      
        assert_response :success, api_version
        assert_equal "application/xml", @response.content_type, api_version
        assert_equal api_version, @response.headers['API-Version']

        expected_response = {
          "web_coupons" => {
            "timestamp_max" => "2010-03-15T12:35:58Z",
            "web_coupon" => [{
              "id" => "#{offer_1.id}-offer",
              "created_at" => "2010-03-15T12:35:56Z",
              "updated_at" => "2010-03-15T12:35:56Z",
              "link" => { "href" => api2_web_coupons_url(:id => offer_1.to_param) }
            }, {
              "id" => "#{offer_2.id}-offer",
              "created_at" => "2010-03-15T12:35:56Z",
              "updated_at" => "2010-03-15T12:35:57Z",
              "link" => { "href" => api2_web_coupons_url(:id => offer_2.to_param) }
            }, {
              "id" => "#{offer_3.id}-offer",
              "created_at" => "2010-03-15T12:35:56Z",
              "deleted_at" => "2010-03-15T12:35:58Z",
              "updated_at" => "2010-03-15T12:35:58Z"
            }]
          }
        }
        assert_equal expected_response, Hash.from_xml(@response.body)
      end
    end
  end
  
  def test_index_with_no_offers
    publisher = publishers(:sdh_austin)
    publisher.offers.destroy_all

    Timecop.freeze(Time.parse("2010-03-15T12:36:08Z"))
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
      get :web_coupons, :publisher_label => "mysdh-austin", :format => :xml
      
      assert_response :success, api_version
      assert_equal "application/xml", @response.content_type, api_version
      assert_equal api_version, @response.headers['API-Version']

      expected_response = { "web_coupons" => { "timestamp_max" => "2010-03-15T12:35:58Z" }}
      assert_equal expected_response, Hash.from_xml(@response.body.gsub!(/\n/, ""))
    end
  end
  
  def test_show
    advertiser = advertisers(:changos)
    advertiser.offers.destroy_all

    Timecop.freeze(Time.parse("Mar 15, 2010 12:35:56 UTC"))
    offer_1 = advertiser.offers.create!(
      :message => "Offer 1",
      :value_proposition => "Offer 1 Value",
      :show_on => "Mar 01, 2010",
      :expires_on => "Mar 30, 2010",
      :category_names => "Restaurants, Health: Dental"
    )
    Timecop.freeze(Time.parse("Mar 15, 2010 12:35:56 UTC"))
    offer_2 = advertiser.offers.create!(
      :message => "Offer 2",
      :value_proposition => "Offer 2 Value",
      :terms => "Offer 2 Terms",
      :show_on => "Mar 02, 2010",
      :category_names => "Household",
      :photo => ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    )
    Timecop.freeze(Time.parse("Mar 15, 2010 12:35:57 UTC"))
    offer_2.update_attributes! :terms => "New terms"
    
    advertiser = advertisers(:el_greco)
    advertiser.offers.destroy_all

    Timecop.freeze(Time.parse("Mar 15, 2010 12:35:56 UTC"))
    offer_3 = advertiser.offers.create!(
      :message => "Offer 3",
      :value_proposition => "Offer 3 Value",
      :expires_on => "Mar 29, 2010"
    )
    Timecop.freeze(Time.parse("Mar 15, 2010 12:35:58 UTC"))
    offer_3.delete!

    Timecop.freeze(Time.parse("Mar 15, 2010 12:36:08"))
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
      get :web_coupons, :id => [offer_1, offer_2, offer_3].map(&:to_param).join(","), :format => :xml
      
      assert_response :success, api_version
      assert_equal "application/xml", @response.content_type, api_version
      assert_equal api_version, @response.headers['API-Version']
      
      web_coupons_list = Hash.from_xml(@response.body)["web_coupons"]["web_coupon"]
      assert_equal 3, web_coupons_list.size, api_version
      response_data = web_coupons_list.map { |hash| hash.except("content") }
      expected_data = [
        {
          "id" => "#{offer_1.id}-offer",
          "value_proposition" => "Offer 1 Value",
          "terms" => "One coupon per customer while supplies last",
          "advertiser" => {
            "id" => "#{advertisers(:changos).id}-advertiser",
            "name" => "Changos",
            "address" => { "address_line_1" => "3005 South Lamar", "city" => "Austin", "state" => "TX", "zip" => "78704" },
            "phone" => "(512) 416-1500",
            "website_url" => "http://www.changos.com"
          },
          "show_at" => "2010-03-01T08:00:00Z",
          "hide_at" => "2010-03-31T06:59:59Z",
          "categories" => { "category" => [{
            "name" => "Health", "id" => "#{categories(:health).id}-category", "categories" => { "category" => {
              "name"=>"Dental", "id"=>"#{categories(:dental).id}-category"
          }}}, {
            "name"=>"Restaurants", "id"=>"#{categories(:restaurants).id}-category"
          }]}
        }, {
          "id" => "#{offer_2.id}-offer",
          "value_proposition" => "Offer 2 Value",
          "terms" => "New terms",
          "photo_url" => "http://s3.amazonaws.com/photos.offers.analoganalytics.com/test/#{offer_2.id}/large.jpg?1268656556",
          "advertiser" => {
            "id" => "#{advertisers(:changos).id}-advertiser",
            "name" => "Changos",
            "address" => { "address_line_1" => "3005 South Lamar", "city" => "Austin", "state" => "TX", "zip" => "78704" },
            "phone" => "(512) 416-1500",
            "website_url" => "http://www.changos.com"
          },
          "show_at" => "2010-03-02T08:00:00Z",
          "categories" => { "category" => {
            "name" => "Household", "id"=>"#{categories(:household).id}-category"
          }},
        }, {
          "id" => "#{offer_3.id}-offer",
          "value_proposition" => "Offer 3 Value",
          "terms" => "One coupon per customer while supplies last",
          "advertiser" => {
            "id" => "#{advertisers(:el_greco).id}-advertiser",
            "name" => "El Greco",
          },
          "hide_at" => "2010-03-30T06:59:59Z",
        }
      ]
      assert_equal expected_data, response_data, api_version
    end
  end
  
  def test_show_with_no_ids
    advertiser = advertisers(:changos)
    advertiser.offers.destroy_all

    Timecop.freeze(Time.parse("Mar 15, 2010 12:35:56 UTC"))
    offer_1 = advertiser.offers.create!(:message => "Offer 1")

    Timecop.freeze(Time.parse("Mar 15, 2010 12:36:08"))
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
      get :web_coupons, :id => "", :format => :xml
      assert_response :success, api_version
      assert_equal "application/xml", @response.content_type, api_version
      assert_equal api_version, @response.headers['API-Version']
      assert_api_error_response_xml /id must be present/i
    end
  end
  
  def test_web_coupons_categories
    advertiser = advertisers(:changos)
    advertiser.offers.destroy_all

    offer_1 = advertiser.offers.create!(
      :message => "Offer 1",
      :value_proposition => "Offer 1 Value",
      :show_on => "Mar 01, 2010",
      :expires_on => "Mar 30, 2010",
      :category_names => "Restaurants, Health: Dental"
    )
    advertiser = advertisers(:el_greco)
    advertiser.offers.destroy_all

    offer_2 = advertiser.offers.create!(
      :message => "Offer 2",
      :value_proposition => "Offer 2 Value",
      :terms => "Offer 2 Terms",
      :show_on => "Mar 02, 2010",
      :category_names => "Household"
    )
    offer_2.delete!
    
    for_each_api_version do |api_version|
      set_http_basic_authentication(:name => users(:mickey).login, :pass => "monkey")
      get :web_coupons_categories, :publisher_label => "mysdh-austin", :format => :xml
      
      assert_response :success, api_version
      assert_equal "application/xml", @response.content_type, api_version
      assert_equal api_version, @response.headers['API-Version']

      response_data = Hash.from_xml(@response.body)
      expected_data = {
          "categories" => {
            "category" => [{
              "name" => "Health", "id" => "#{categories(:health).id}-category", "categories" => { 
                "category" => {
                  "name"=>"Dental", "id"=>"#{categories(:dental).id}-category"
                }
              }
            }, {
              "name"=>"Restaurants", "id"=>"#{categories(:restaurants).id}-category"
            }, {
              "name" => "Household", "id"=>"#{categories(:household).id}-category"
            }]
          }
        }
      assert_equal expected_data, response_data, api_version
    end
  end
  
  fast_context "#web_coupons_count_impressions" do
    setup do
      @kansascity = Factory :publisher, :label => "kansascity"
      @kansascity_advertiser = Factory :advertiser, :publisher_id => @kansascity.id
      @other_advertiser = Factory :advertiser

      @kansascity_offer_1 = Factory :offer, :advertiser_id => @kansascity_advertiser.id
      @kansascity_offer_2 = Factory :offer, :advertiser_id => @kansascity_advertiser.id
      @other_offer_1 = Factory :offer, :advertiser_id => @other_advertiser.id
      
      @kansas_offer_ids = [@kansascity_offer_1, @kansascity_offer_2].map { |o| "#{o.id}-offer" }.join(",")
    end
    
    should "work as a GET request" do
      options = { :protocol => "https", :controller => "api2", :action => "web_coupons_count_impressions", :format => "xml" }
      assert_routing({ :method => :get, :path => 'api2/web_coupons/count_impressions' }, options)
    end
    
    should "not allow a publisher_label that does not exist" do
      get :web_coupons_count_impressions, :publisher_label => "nosuchlabel", :ids => @kansas_offer_ids, :format => "xml"
      assert_response :missing
      assert_equal "Unknown publisher: nosuchlabel", @response.body
    end
    
    should "require a comma-separated ids parameter (the ids have a '-offer' suffix)" do
      get :web_coupons_count_impressions, :publisher_label => @kansascity.label, :format => "xml"
      assert_response :not_acceptable
      assert_equal "Missing required parameter: ids", @response.body
    end
    
    should "require a publisher_label parameter" do
      get :web_coupons_count_impressions, :ids => @kansas_offer_ids, :format => "xml"
      assert_response :not_acceptable
      assert_equal "Missing required parameter: publisher_label", @response.body
    end
    
    should "update impression counts when passed a valid publisher_label and valid ids" do
      assert_difference '@kansascity_offer_1.impressions', 1 do
        assert_difference '@kansascity_offer_2.impressions', 1 do
          get :web_coupons_count_impressions, :publisher_label => @kansascity.label, :ids => @kansas_offer_ids, :format => "xml"
        end
      end
      assert_response :success      
    end
    
    should "return a 404 when passed IDs that either don't exist or aren't editable by this user" do
      get :web_coupons_count_impressions, {
        :publisher_label => @kansascity.label,
        :ids => "#{@kansas_offer_ids},#{@other_offer_1.id}-offer,1234567890-offer",
        :format => "xml"
      }
      assert_response :missing
      assert_equal "Unknown offer IDs: #{@other_offer_1.id}-offer, 1234567890-offer", @response.body
    end
    
  end

  fast_context "#syndicated_web_coupons" do
    setup do
      @request.env['API-Version'] = "2.0.0"
    end

    should "work as a GET request" do
      options = { :protocol => "https", :controller => "api2", :action => "syndicated_web_coupons", :format => "xml" }
      assert_routing({ :method => :get, :path => 'api2/web_coupons/syndicated' }, options)
    end

    fast_context "user without proper permissions" do
      setup do
        user = Factory(:user, :password => "foobar", :password_confirmation => "foobar")
        set_http_basic_authentication(:name => user.login, :pass => "foobar")
      end

      should "be forbidden" do
        get :syndicated_web_coupons, :format => :xml
        assert_response :forbidden
        assert_equal "2.0.0", @response.headers['API-Version']
      end
    end

    fast_context "user with proper permissions" do
      setup do
        user = Factory(:user,
                       :password => "foobar",
                       :password_confirmation => "foobar",
                       :allow_offer_syndication_access => true)
        set_http_basic_authentication(:name => user.login, :pass => "foobar")

        @publisher1 = Factory(:publisher, :offers_available_for_syndication => false)
        @publisher2 = Factory(:publisher, :offers_available_for_syndication => true)

        @offer1 = Factory(:offer)
        @offer1.place_with(@publisher1)
      end

      fast_context "without syndicated offers" do
        should "respond successfully with no offers" do
          Timecop.freeze(Time.parse("2011-09-09T00:00:00Z")) do
            get :syndicated_web_coupons, :format => :xml
          end
          assert_response :success
          assert_equal "application/xml", @response.content_type
          assert_equal "2.0.0", @response.headers['API-Version']

          assert_select "web_coupons[timestamp_max='2011-09-08T23:59:50Z']" do
            assert_select "web_coupon", 0
          end
        end
      end

      fast_context "with syndicated offers" do
        setup do
          Timecop.freeze(Time.parse("2011-09-08T00:00:00Z")) do
            @offer2 = Factory(:offer)
            @offer2.place_with(@publisher2)
            @offer3 = Factory(:offer)
            @offer3.place_with(@publisher2)
          end          
        end

        should "respond successfully with syndicated offers" do
          Timecop.freeze(Time.parse("2011-09-09T00:00:00Z")) do
            get :syndicated_web_coupons, :format => :xml
          end

          assert_response :success
          assert_equal "application/xml", @response.content_type
          assert_equal "2.0.0", @response.headers['API-Version']

          expected_response = {
            "web_coupons" => {
              "timestamp_max" => "2011-09-08T23:59:50Z",
              "web_coupon" => [
                {
                  "id" => "#{@offer2.id}-offer",
                  "created_at" => "2011-09-08T00:00:00Z",
                  "updated_at" => "2011-09-08T00:00:00Z",
                  "link" => { "href" => api2_web_coupons_url(:id => @offer2.to_param) }
                },
                {
                  "id" => "#{@offer3.id}-offer",
                  "created_at" => "2011-09-08T00:00:00Z",
                  "updated_at" => "2011-09-08T00:00:00Z",
                  "link" => { "href" => api2_web_coupons_url(:id => @offer3.to_param) }
                }
              ]
            }
          }          
          response_data = Hash.from_xml(@response.body)
          assert_equal expected_response, response_data
        end
        
        context "with pagination parameters" do
          
          should "return only the first result when passed per_page 1 and page 1" do
            Timecop.freeze(Time.parse("2011-09-09T00:00:00Z")) do
              get :syndicated_web_coupons, :page => "1", :per_page => "1", :format => :xml
            end
            
            assert_response :success
            assert_equal "application/xml", @response.content_type
            assert_equal "2.0.0", @response.headers['API-Version']

            expected_response = {
              "web_coupons" => {
                "timestamp_max" => "2011-09-08T23:59:50Z",
                "web_coupon" => {
                    "id" => "#{@offer2.id}-offer",
                    "created_at" => "2011-09-08T00:00:00Z",
                    "updated_at" => "2011-09-08T00:00:00Z",
                    "link" => { "href" => api2_web_coupons_url(:id => @offer2.to_param) }
                }
              }
            }          
            
            response_data = Hash.from_xml(@response.body)
            assert_equal expected_response, response_data
          end
          
          should "return only the second result when passed per_page 1 and page 2" do
            Timecop.freeze(Time.parse("2011-09-09T00:00:00Z")) do
              get :syndicated_web_coupons, :page => "2", :per_page => "1", :format => :xml
            end
            
            assert_response :success
            assert_equal "application/xml", @response.content_type
            assert_equal "2.0.0", @response.headers['API-Version']

            expected_response = {
              "web_coupons" => {
                "timestamp_max" => "2011-09-08T23:59:50Z",
                "web_coupon" => {
                    "id" => "#{@offer3.id}-offer",
                    "created_at" => "2011-09-08T00:00:00Z",
                    "updated_at" => "2011-09-08T00:00:00Z",
                    "link" => { "href" => api2_web_coupons_url(:id => @offer3.to_param) }
                }
              }
            }                      
            response_data = Hash.from_xml(@response.body)
            assert_equal expected_response, response_data            
          end
          
          should "default to 500 results per page, when only the page parameter is provided" do
            ActiveRecord::NamedScope::Scope.any_instance.expects(:all).once.with(:limit => 500, :offset => 500, :order => "updated_at ASC, id ASC").returns([])
            Timecop.freeze(Time.parse("2011-09-09T00:00:00Z")) do
              get :syndicated_web_coupons, :page => "2", :format => :xml
            end            
            assert_response :success
          end
          
          should "default to no limit or offset when page and per_page are not provided" do
            ActiveRecord::NamedScope::Scope.any_instance.expects(:all).once.with(:limit => nil, :offset => nil, :order => "updated_at ASC, id ASC").returns([])
            Timecop.freeze(Time.parse("2011-09-09T00:00:00Z")) do
              get :syndicated_web_coupons, :format => :xml
            end            
            assert_response :success            
          end

          should "return no results when there are no results for a given page" do
            Timecop.freeze(Time.parse("2011-09-09T00:00:00Z")) do
              get :syndicated_web_coupons, :page => "100", :format => :xml
            end            
            assert_response :success
            assert_equal "application/xml", @response.content_type
            assert_equal "2.0.0", @response.headers['API-Version']

            expected_response = { "web_coupons" => "\n" }                      
            response_data = Hash.from_xml(@response.body)
            assert_equal expected_response, response_data            
          end
          
        end
        
      end
    end
  end
  
  private
  
  def set_http_basic_auth_for_admin
    set_http_basic_authentication(:name => @admin.login, :pass => "monkey")
  end
  
  def for_each_api_version
    %w{ 2.0.0 }.each do |api_version|
      @controller = nil
      setup_controller_request_and_response
      @request.env['API-Version'] = api_version
      yield api_version
    end
  end

  def assert_api_error_response_xml(regex)
    assert_equal "application/xml", @response.content_type
    
    elem = REXML::Document.new(@response.body).root
    assert_not_nil elem
    assert_equal "errors", elem.name

    assert_equal 1, elem.elements.size
    elem = elem.elements[1]
    assert_equal "error", elem.name
    
    assert_equal 1, elem.elements.size
    elem = elem.elements[1]
    assert_equal "text", elem.name
    assert_match regex, elem.text, "XML error text"
  end
end
