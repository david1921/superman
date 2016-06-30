require File.dirname(__FILE__) + "/../test_helper"
# GeoIP mock
require File.dirname(__FILE__) + "/../mocks/test/geoip"

class DailyDealSubscribersControllerTest < ActionController::TestCase

  test "presignup for queens courier" do
    publisher = Factory(:publisher, :label => "queenscourier")
    get :presignup, :publisher_id => publisher.id
    assert_response :success
    assert_select 'form.new_subscriber'
  end

  context "bcbsa template should pre-populate the new subscriber form from params" do
    setup do
      @publisher = Factory(:publisher, :label => "bcbsa")
    end

    should "pre-populate the form" do
      get :presignup, :publisher_id => @publisher.id, :name => 'pork beef man', :email => 'pork.beef@man.com', :zip_code => '90210'
      assert_response :success
      assert_select 'form.presignup' do
        assert_select "input[name='subscriber[name]'][value='pork beef man']"
        assert_select "input[name='subscriber[email]'][value='pork.beef@man.com']"
        assert_select "input[name='subscriber[zip_code]'][value='90210']"
      end
    end
  end

  test "presignup create for queens courier" do
    publisher = Factory(:publisher, :label => "queenscourier")
    assert_equal 0, publisher.subscribers.count
    post :create, :publisher_id => publisher.id, :subscriber => {
      :email => "bradb@example.com",
      :zip_code => "90210",
      :city => "Vancouver",
      :birth_year => "1978",
      :gender => "M"
    }
    assert_match /^#{thank_you_publisher_daily_deal_subscribers_url(publisher.label)}/, @response.redirected_to
    assert_equal 1, publisher.subscribers.count
    last_subscriber = publisher.subscribers.last
    assert_equal "bradb@example.com", last_subscriber.email, "Queens Courier subscriber email"
    assert_equal "90210", last_subscriber.zip_code, "Queens Courier zip code"
    assert_equal "Vancouver", last_subscriber.city, "Queens Courier city"
    assert_equal 1978, last_subscriber.birth_year, "Queens Courier birth year"
    assert_equal "M", last_subscriber.gender, "Queens Courier gender"
  end

  context "market deal page redirects" do

    should "not redirect based on zip code cookie if the PUBLISHER IS NOT LAUNCHED" do
      publisher = Factory(:publisher, :label => "kowabunga", :launched => false)
      market    = Factory(:market, :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => "97211")

      @request.cookies['zip_code'] = "97211"
      get :presignup, :publisher_id => publisher.id
      assert_response :success
      assert_template "presignup"
    end

    should "not redirect based on zip code detection if the PUBLISHER IS NOT LAUNCHED" do
      ip_address = '173.164.122.114' # PDX office
      @request.env['REMOTE_ADDR'] = ip_address
      geo = GeoIP.new(AppConfig.geoip_data_file).city(ip_address)
      assert_not_nil geo.postal_code
      publisher = Factory(:publisher, :label => "kowabunga", :launched => false)
      market = Factory(:market, :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => geo.postal_code)

      get :presignup, :publisher_id => publisher.id
      assert_response :success
      assert_template "presignup"
    end

    should "not redirect to the national market if the PUBLISHER IS NOT LAUNCHED" do
      ip_address = '0.0.0.0'
      @request.env['REMOTE_ADDR'] = ip_address
      geo = GeoIP.new(AppConfig.geoip_data_file).city(ip_address)
      assert_nil geo
      publisher = Factory(:publisher, :label => 'kowabunga', :launched => false)
      portland_market    = Factory(:market, :name => "Portland", :publisher => publisher)
      national_market    = Factory(:market, :name => "National", :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => portland_market, :zip_code => "97211")

      get :presignup, :publisher_id => publisher.id
      assert_response :success
      assert_template "presignup"
    end

    should "redirect to a market for a publisher with markets, when zip_code cookie is set for valid market" do
      publisher = Factory(:publisher, :label => "kowabunga")
      market    = Factory(:market, :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => "97211")

      @request.cookies['zip_code'] = "97211"
      get :presignup, :publisher_id => publisher.id
      assert_redirected_to public_deal_of_day_for_market_path(:label => publisher.label, :market_label => market.label)
    end

    should "not redirect to a market for a publisher WITHOUT markets, when zip_code cookie is set for valid market" do
      publisher = Factory(:publisher, :label => "kowabunga")
      another_publisher = Factory(:publisher, :label => "anotherpub")
      market    = Factory(:market, :publisher => another_publisher)
      market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => "97211")

      @request.cookies['zip_code'] = "97211"
      get :presignup, :publisher_id => publisher.id
      assert_response :success
      assert_template "presignup"
    end

    should "redirect to market for a publisher with markets, with successful zip code detection" do
      ip_address = '173.164.122.114' # PDX office
      @request.env['REMOTE_ADDR'] = ip_address
      geo = GeoIP.new(AppConfig.geoip_data_file).city(ip_address)
      assert_not_nil geo.postal_code
      publisher = Factory(:publisher, :label => "kowabunga")
      market = Factory(:market, :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => geo.postal_code)

      get :presignup, :publisher_id => publisher.id
      assert_redirected_to public_deal_of_day_for_market_path(:label => publisher.label, :market_label => market.label)
      assert_not_nil cookies['zip_code']
      assert_equal geo.postal_code, cookies['zip_code']
    end

    should "not redirect to market for a publisher WITHOUT markets, when there is no zip code cookie (just making sure we don't get to any IP-based redirects with no markets)" do
      ip_address = '173.164.122.114' # PDX office
      @request.env['REMOTE_ADDR'] = ip_address
      geo = GeoIP.new(AppConfig.geoip_data_file).city(ip_address)
      assert_not_nil geo.postal_code
      publisher = Factory(:publisher, :label => "kowabunga")

      get :presignup, :publisher_id => publisher.id
      assert_response :success
      assert_template "presignup"
    end

    should "redirect to a PRE-EXISTING NATIONAL MARKET when COOKIED ZIP doesn't match an existing non-national market, and the publisher is using markets" do
      publisher = Factory(:publisher, :label => "kowabunga")
      portland_market    = Factory(:market, :name => "Portland", :publisher => publisher)
      national_market    = Factory(:market, :name => "National", :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => portland_market, :zip_code => "97211")

      @request.cookies['zip_code'] = "66601" # Topeka, in case you were wondering
      get :presignup, :publisher_id => publisher.id
      assert_redirected_to public_deal_of_day_for_market_path(:label => publisher.label, :market_label => national_market.label)
    end

    should "redirect to a PRE-EXISTING NATIONAL MARKET when DETECTED ZIP doesn't match an existing non-national market, and the publisher is using markets" do
      ip_address = '0.0.0.0'
      @request.env['REMOTE_ADDR'] = ip_address
      geo = GeoIP.new(AppConfig.geoip_data_file).city(ip_address)
      assert_nil geo
      publisher = Factory(:publisher, :label => 'kowabunga')
      portland_market    = Factory(:market, :name => "Portland", :publisher => publisher)
      national_market    = Factory(:market, :name => "National", :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => portland_market, :zip_code => "97211")

      get :presignup, :publisher_id => publisher.id
      assert_redirected_to public_deal_of_day_for_market_path(:label => publisher.label, :market_label => national_market.label)
    end

    should "CREATE NATIONAL MARKET and redirect it when COOKIED ZIP doesn't match an existing non-national market, the publisher is using markets, and the national market does not already exist" do
      publisher = Factory(:publisher, :label => "kowabunga")
      portland_market    = Factory(:market, :name => "Portland", :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => portland_market, :zip_code => "97211")

      @request.cookies['zip_code'] = "66601" # Topeka, in case you were wondering
      get :presignup, :publisher_id => publisher.id
      national_market = publisher.markets.find_by_name("National")
      assert national_market, "National market should have been created during the request"
      assert_redirected_to public_deal_of_day_for_market_path(:label => publisher.label, :market_label => national_market.label)
    end

    should "CREATE NATIONAL MARKET and redirect to it when DETECTED ZIP doesn't match an existing non-national market, the publisher is using markets, and the national market does not already exist" do
      ip_address = '0.0.0.0'
      @request.env['REMOTE_ADDR'] = ip_address
      geo = GeoIP.new(AppConfig.geoip_data_file).city(ip_address)
      assert_nil geo
      publisher = Factory(:publisher, :label => 'kowabunga')
      portland_market    = Factory(:market, :name => "Portland", :publisher => publisher)
      market_zip_code = Factory(:market_zip_code, :market => portland_market, :zip_code => "97211")

      get :presignup, :publisher_id => publisher.id
      national_market = publisher.markets.find_by_name("National")
      assert national_market, "National market should have been created during the request"
      assert_redirected_to public_deal_of_day_for_market_path(:label => publisher.label, :market_label => national_market.label)
    end

  end

  test "create for market zip code with valid zip code" do
    publisher = Factory(:publisher, :label => "kowabunga")
    market    = Factory(:market, :publisher => publisher)
    market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => "97211")

    Timecop.freeze(Time.now) do
      assert_difference "publisher.subscribers.count" do
        post :create, :publisher_id => "kowabunga", :subscriber => {
          :email             => "johnny@coolemail.com",
          :zip_code          => "97211",
          :zip_code_required => "true"
        }
      end

      assert_equal "97211", cookies['zip_code']
      assert_equal 10.years.from_now.to_i, better_cookies['zip_code']['expires'].to_i
    end
  end

  test "create for market zip code with invalid zip code" do
    publisher = Factory(:publisher, :label => "kowabunga")
    market    = Factory(:market, :publisher => publisher)
    market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => "97211")

    assert_difference "publisher.subscribers.count" do
      post :create, :publisher_id => "kowabunga", :subscriber => {
        :email             => "johnny@coolemail.com",
        :zip_code          => "00023",
        :zip_code_required => "true"
      }
    end

    assert_equal nil, cookies['zip_code']
  end

  test "create for entertainment when zip in publisher zip codes" do
    pub_group = Factory(:publishing_group, :name => "entertainment")
    publisher = Factory(:publisher, :name=> "entertainment", :label => "entertainment", :publishing_group => pub_group)
    publisher_assigned_from_zip = Factory(:publisher, :name=> "los angeles north", :label => "lanorth", :publishing_group => pub_group)
    Factory :publisher_zip_code, :publisher_id => publisher_assigned_from_zip.id, :zip_code => "90210"

    assert_difference 'publisher_assigned_from_zip.subscribers.count' do
      post :create, :publisher_id => "entertainment", :subscriber => {
        :email => "john@public.com",
        :zip_code => "90210",
        :zip_code_required => "true",
        :other_options => { "referral_code" => "abc123" }
      }
    end

    assert_match /^#{thank_you_publisher_daily_deal_subscribers_url(publisher.label)}/, @response.redirected_to
    assert flash[:analytics_tag].signup?

    subscriber = publisher_assigned_from_zip.subscribers.last
    assert_not_nil subscriber
    assert_equal "john@public.com", subscriber.email
    assert_equal "90210", subscriber.zip_code
    assert_equal publisher_assigned_from_zip.label, subscriber.publisher.label
    assert_equal({ "referral_code" => "abc123" }, subscriber.other_options)
  end

  test "create for entertainment zip not in publisher zip codes" do
    pub_group = Factory(:publishing_group, :name => "entertainment")
    publisher = Factory(:publisher, :name=> "entertainment", :label => "entertainment", :publishing_group => pub_group)
    publisher_assigned_from_zip = Factory(:publisher, :name=> "los angeles north", :label => "lanorth", :publishing_group => pub_group)
    Factory :publisher_zip_code, :publisher_id => publisher_assigned_from_zip.id, :zip_code => "90210"

    assert_difference 'publisher.subscribers.count' do
      post :create, :publisher_id => "entertainment", :subscriber => {
        :email => "john@public.com",
        :zip_code => "85034",
        :zip_code_required => "true",
        :other_options => { "referral_code" => "abc123"}
      }
    end

    assert_match /^#{thank_you_publisher_daily_deal_subscribers_url(publisher.label)}/, @response.redirected_to
    assert flash[:analytics_tag].signup?

    subscriber = publisher.subscribers.last
    assert_not_nil subscriber
    assert_equal "john@public.com", subscriber.email
    assert_equal "85034", subscriber.zip_code
    assert_equal publisher.label, subscriber.publisher.label
    assert_equal({ "referral_code" => "abc123"}, subscriber.other_options)
  end

  test "create for entertainment with missing zip" do
    publisher = Factory(:publisher, :label => "entertainment")
    @request.env["HTTP_REFERER"] = url = "http://deals.entertainment.com/publishers/entertainment/daily_deal_subscribers/new?referral_code=abc123"

    assert_no_difference 'publisher.subscribers.count' do
      post :create, :publisher_id => "entertainment", :subscriber => {
        :email => "john@public.com",
        :zip_code => "",
        :zip_code_required => "true",
        :other_options => { "referral_code" => "abc123", "city" => "Detroit" }
      }
    end
    assert_redirected_to url
    assert_nil flash[:analytics_tag]
    assert_match /could not subscribe/i, flash[:warn]
  end

  test "create for entertainment with missing email" do
    publisher = Factory(:publisher, :label => "entertainment")
    @request.env["HTTP_REFERER"] = url = "http://deals.entertainment.com/publishers/entertainment/daily_deal_subscribers/new?referral_code=abc123"

    assert_no_difference 'publisher.subscribers.count' do
      post :create, :publisher_id => "entertainment", :subscriber => {
        :email => "",
        :zip_code => "90201",
        :zip_code_required => "true",
        :other_options => { "referral_code" => "abc123", "city" => "Detroit" }
      }
    end
    assert_redirected_to url
    assert_nil flash[:analytics_tag]
    assert_match /could not subscribe/i, flash[:warn]
  end

  test "create with market_publisher_id" do
    publishing_group = Factory(:publishing_group)
    publisher1 = Factory(:publisher, :publishing_group => publishing_group)
    publisher2 = Factory(:publisher, :publishing_group => publishing_group)

    assert_no_difference 'publisher1.subscribers.count' do
      assert_difference 'publisher2.subscribers.count' do
        post :create, :publisher_id => publisher1.label, :subscriber => {
          :email => "john@public.com",
          :zip_code => "85034",
          :zip_code_required => "true",
          :market_publisher_id => publisher2.id
        }
      end
    end

    assert_match /^#{thank_you_publisher_daily_deal_subscribers_url(publisher2.label)}/, @response.redirected_to
  end

  test "create with blank market_publisher_id" do
    publishing_group = Factory(:publishing_group)
    publisher1 = Factory(:publisher, :publishing_group => publishing_group)
    publisher2 = Factory(:publisher, :publishing_group => publishing_group)

    @request.env["HTTP_REFERER"] = url = publisher_daily_deal_subscribers_path(publisher1)

    assert_no_difference 'publisher1.subscribers.count' do
      assert_no_difference 'publisher2.subscribers.count' do
        post :create, :publisher_id => publisher1.label, :subscriber => {
          :email => "john@public.com",
          :zip_code => "85034",
          :zip_code_required => "true",
          :market_publisher_id => ""
        }
      end
    end

    assert_match /select a city/, flash[:warn]

    assert_redirected_to url
  end

  test "create with device and user_agent" do
    publisher = Factory(:publisher, :label => "entertainment")
    @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)"

    assert_difference 'publisher.subscribers.count' do
      post :create, :publisher_id => "entertainment", :subscriber => {
        :email => "john@public.com",
        :zip_code => "90210",
        :zip_code_required => "true",
        :other_options => { "referral_code" => "abc123", "city" => "Detroit" },
        :device => "tablet"
      }
    end

    subscriber = publisher.subscribers.last
    assert_equal "tablet", subscriber.device
    assert_equal "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)", subscriber.user_agent
  end

  # test "thank_you for entertainment" do
  #   publisher = Factory(:publisher, :label => "entertainment")
  #
  #   assert_no_difference 'Subscriber.count' do
  #     get :thank_you, { :publisher_id => publisher.label }, nil, { :analytics_tag => AnalyticsTag.new.signup! }
  #   end
  #   assert_response :success
  #   assert_theme_layout "entertainment/layouts/daily_deal_subscribers"
  #   assert_template "themes/entertainment/daily_deal_subscribers/thank_you"
  #
  #   assert @controller.analytics_tag.signup?
  # end

  test "create for entertainment via api" do
    publisher = Factory(:publisher, :label => "entertainment")

    assert_difference 'publisher.subscribers.count' do
      post :create, :api_access_key => "2K9Id8vvMq41821l", :publisher_id => "entertainment", :subscriber => {
        :email => "john@public.com",
        :zip_code => "90210",
        :other_options => { "referral_code" => "abc123", "city" => "Detroit" }
      }
    end
    assert_response :success
    assert_equal({ "response" => { "result" => "success" }}, Hash.from_xml(@response.body))

    subscriber = publisher.subscribers.last
    assert_equal "john@public.com", subscriber.email
    assert_equal "90210", subscriber.zip_code
    assert_equal({ "referral_code" => "abc123", "city" => "Detroit" }, subscriber.other_options)
  end

  test "create for entertainment via api with missing email" do
    publisher = Factory(:publisher, :label => "entertainment")

    @controller.expects(:log_subscribers_api_call_info).with("Failed to add subscriber '' to any publisher: Email can't be blank")
    assert_no_difference 'Subscriber.count' do
      post :create, :api_access_key => "2K9Id8vvMq41821l", :publisher_id => "entertainment", :subscriber => {
        :zip_code => "90210",
        :other_options => { "referral_code" => "abc123", "city" => "Detroit" }
      }
    end
    assert_response :bad_request
    assert_equal({ "response" => { "result" => "failure", "errors" => { "error" => "Email can't be blank" }}}, Hash.from_xml(@response.body))
  end

  test "create for entertainment via api with missing zip code" do
    publisher = Factory(:publisher, :label => "entertainment")

    assert_difference 'Subscriber.count' do
      post :create, :api_access_key => "2K9Id8vvMq41821l", :publisher_id => "entertainment", :subscriber => {
        :email => "john@public.com",
        :other_options => { "referral_code" => "abc123", "city" => "Detroit" }
      }
    end
    assert_response :success
    assert_equal({ "response" => { "result" => "success" }}, Hash.from_xml(@response.body))

    subscriber = publisher.subscribers.last
    assert_equal "john@public.com", subscriber.email
    assert_equal({ "referral_code" => "abc123", "city" => "Detroit" }, subscriber.other_options)
  end

  test "create via api for not entertainment with market publisher not found" do
    publisher = Factory(:publisher, :label => "foobar")
    @controller.expects(:log_subscribers_api_call_info).with("Failed to add subscriber 'john@public.com' to any publisher: no publisher with ID foobar found")
    assert_no_difference 'Subscriber.count' do
      post :create, :api_access_key => "2K9Id8vvMq41821l", :publisher_id => "foobar", :subscriber => {
        :market_publisher_id => 1111111,
        :email => "john@public.com",
        :other_options => { "referral_code" => "abc123", "city" => "Detroit" }
      }
    end  
    assert_response :bad_request  
  end

  test "create for entertainment with bad api_access_key" do
    publisher = Factory(:publisher, :label => "entertainment")

    assert_no_difference 'Subscriber.count' do
      assert_raises ActionController::InvalidAuthenticityToken do
        post :create, :publisher_id => publisher.label, :api_access_key => "xxxxxxxx"
      end
    end
  end

  context "create subscribers with publisher zip codes" do

    setup do
      @entertainment_group = Factory(:publishing_group, :label => "entertainment")

      @entertainment_houston = Factory(:publisher, :label => "entertainmenthouston", :publishing_group => @entertainment_group)
      Factory(:publisher_zip_code, :publisher => @entertainment_houston, :zip_code => "90210")

      @entertainment = Factory(:publisher, :publishing_group => @entertainment_group, :name => "Entertainment", :label => "entertainment")

      @entertainment_tucson = Factory(:publisher, :label => "entertainmenttucson", :publishing_group => @entertainment_group)
      Factory(:publisher_zip_code, :publisher => @entertainment_tucson, :zip_code => "94110")
    end

    should "create subscriber for the entertainment publisher matching the zip code via api" do
      @controller.expects(:log_subscribers_api_call_info).with("Successfully added subscriber 'john@public.com' to publisher entertainmenthouston")
      assert_difference 'Subscriber.count', 1 do
        post :create, :api_access_key => "2K9Id8vvMq41821l", :publisher_id => "entertainment", :subscriber => {
          :email => "john@public.com",
          :zip_code => "90210",
          :other_options => { "referral_code" => "abc123", "city" => "detroit" }
        }
      end
      assert_response :success
      assert_equal({ "response" => { "result" => "success" }}, Hash.from_xml(@response.body))
      assert_equal @entertainment_houston.id, assigns(:subscriber).publisher_id
      assert_equal "john@public.com", assigns(:subscriber).email
      assert_equal "90210", assigns(:subscriber).zip_code
      assert_equal({ "referral_code" => "abc123", "city" => "detroit" }, assigns(:subscriber).other_options)
    end

    should "create a subscriber on the generic entertainment publisher when the zip code doesn't match any publisher" do
      assert_difference 'Subscriber.count', 1 do
        post :create, :api_access_key => "2K9Id8vvMq41821l", :publisher_id => "entertainment", :subscriber => {
          :email => "john@public.com",
          :zip_code => "99999",
          :other_options => { "referral_code" => "abc123", "city" => "detroit" }
        }
      end
      assert_response :success
      assert_equal({ "response" => { "result" => "success" }}, Hash.from_xml(@response.body))
      assert_equal @entertainment.id, assigns(:subscriber).publisher_id
      assert_equal "john@public.com", assigns(:subscriber).email
      assert_equal "99999", assigns(:subscriber).zip_code
      assert_equal({ "referral_code" => "abc123", "city" => "detroit" }, assigns(:subscriber).other_options)
    end

  end

  test "create should redirect with a hashed subscriber id as a query param" do
    publisher = Factory(:publisher)

    post :create, :publisher_id => publisher.label, :subscriber => {
      :email => 'joe@example.com',
      :terms => 'on'
    }

    subscriber = publisher.subscribers.last
    assert @response.redirected_to.include?({:id => subscriber.hashed_id}.to_query)
  end


  context "POST #presignup, format fbtab" do

    setup do
      @seattlepi = Factory :publisher, :label => "hearst-seattlepi"
    end

    should "render the themed layout and fbtab template when the fbtab format is requested" do
      post :presignup, :publisher_id => @seattlepi.to_param, :format => "fbtab"
      assert_response :success

      assert_theme_layout "hearst-seattlepi/layouts/presignup"
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/presignup.fbtab.liquid"
      assert_equal "text/html", @response.content_type
    end

  end

  context "GET #thank_you" do

    setup do
      @seattlepi = Factory :publisher, :label => "hearst-seattlepi"
    end

    should "render the html template when format is html" do
      get :thank_you, :publisher_id => @seattlepi.to_param
      assert_response :success
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/thank_you.html.liquid"
      assert_theme_layout "hearst-seattlepi/layouts/daily_deal_subscribers"
    end

    should "render the fbtab template when format is fbtab" do
      get :thank_you, :publisher_id => @seattlepi.to_param, :format => "fbtab"
      assert_response :success
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/thank_you.fbtab.liquid"
      assert_theme_layout "hearst-seattlepi/layouts/presignup"
    end

    should "render 404 page if invalid signature exception is thrown" do
      Subscriber.expects(:find_by_hashed_id).raises(ActiveSupport::MessageVerifier::InvalidSignature)
      get :thank_you, :publisher_id => @seattlepi.to_param, :id => "akjadlfkjaldkfjasldjflajdfkjsdf"
      assert_response :not_found
    end

  end

  context "POST #thank_you" do

    setup do
      @seattlepi = Factory :publisher, :label => "hearst-seattlepi"
    end

    should "render the html template when format is html" do
      post :thank_you, :publisher_id => @seattlepi.to_param
      assert_response :success
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/thank_you.html.liquid"
      assert_theme_layout "hearst-seattlepi/layouts/daily_deal_subscribers"
    end

    should "render the fbtab template when format is fbtab" do
      post :thank_you, :publisher_id => @seattlepi.to_param, :format => "fbtab"
      assert_response :success
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/thank_you.fbtab.liquid"
      assert_theme_layout "hearst-seattlepi/layouts/presignup"
    end

  end

  context "GET #thank_you_2" do

    setup do
      @seattlepi = Factory :publisher, :label => "hearst-seattlepi"
    end

    should "render the html template when format is html" do
      get :thank_you_2, :publisher_id => @seattlepi.to_param
      assert_response :success
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/thank_you_2.html.liquid"
      assert_theme_layout "hearst-seattlepi/layouts/daily_deal_subscribers"
    end

    should "render the fbtab template when format is fbtab" do
      get :thank_you_2, :publisher_id => @seattlepi.to_param, :format => "fbtab"
      assert_response :success
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/thank_you_2.fbtab.liquid"
      assert_theme_layout "hearst-seattlepi/layouts/presignup"
    end

  end

  context "POST #thank_you_2" do

    setup do
      @seattlepi = Factory :publisher, :label => "hearst-seattlepi"
    end

    should "render the html template when format is html" do
      post :thank_you_2, :publisher_id => @seattlepi.to_param
      assert_response :success
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/thank_you_2.html.liquid"
      assert_theme_layout "hearst-seattlepi/layouts/daily_deal_subscribers"
    end

    should "render the fbtab template when format is fbtab" do
      post :thank_you_2, :publisher_id => @seattlepi.to_param, :format => "fbtab"
      assert_response :success
      assert_template "themes/hearst-seattlepi/daily_deal_subscribers/thank_you_2.fbtab.liquid"
      assert_theme_layout "hearst-seattlepi/layouts/presignup"
    end

  end

  context "P3P header" do

    setup do
      @seattlepi = Factory :publisher, :label => "hearst-seattlepi"
    end

    should "be set on a POST to :presignup" do
      post :presignup, :publisher_id => @seattlepi.to_param, :format => "fbtab"
      assert_response :success
      assert_equal 'CP="CAO PSA OUR"', @response.headers['P3P']
    end

  end

end
