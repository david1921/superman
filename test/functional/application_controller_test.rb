require File.dirname(__FILE__) + "/../test_helper"

class ApplicationControllerTest < ActionController::TestCase
  class StubController < ApplicationController
    def index
      render :text => 'index action'
    end

    def daily_deal
      @daily_deal = DailyDeal.find(params[:id])
      render :text => 'daily_deal action'
    end
  end

  tests ApplicationControllerTest::StubController

  context "redirecting to admin from reports" do
    setup do
      stub_host_as_reports_server
    end
    should_redirect_to_admin_server_for(:index)
  end

  test "#detect_zip_code" do
    ip_address = '173.164.122.114' # PDX office
    @request.stubs(:remote_ip).returns(ip_address)
    geo = GeoIP.new(AppConfig.geoip_data_file).city(ip_address)
    assert_not_nil geo.postal_code
    assert_equal geo.postal_code, @controller.send(:detect_zip_code)
  end
  
  test "current market with nil publisher" do
    assert_nil @controller.send(:current_market, nil)
  end
  
  test "current market with no markets" do
    publisher = Factory(:publisher)
    assert_nil @controller.send(:current_market, publisher)
  end
  
  test "current market with current zip code present" do
    publisher = Factory(:publisher)
    market = Factory(:market, :publisher => publisher, :name => 'Portlandia')
    market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => '97200')
    @controller.stubs(:current_zip_code).returns('97200')
    assert_equal market, @controller.send(:current_market, publisher)
  end
  
  test "current market with detection of zip code" do
    publisher = Factory(:publisher)
    market = Factory(:market, :publisher => publisher, :name => 'Portlandia')
    market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => '97200')
    @controller.stubs(:detect_zip_code).returns('97200')
    assert_equal market, @controller.send(:current_market, publisher)
  end
  
  test "current market without current zip and failure to detect zip code" do
    publisher = Factory(:publisher)
    market = Factory(:market, :publisher => publisher, :name => 'Portlandia')
    national_market = Factory(:market, :publisher => publisher, :name => 'National')
    market_zip_code = Factory(:market_zip_code, :market => market, :zip_code => '97200')
    @controller.stubs(:current_zip_code).returns(nil)
    @controller.stubs(:detect_zip_code).returns(nil)
    assert_equal national_market, @controller.send(:current_market, publisher)
  end
  
  test "robots.txt should be empty in production" do
    Rails.env.stubs(:production?).returns(true)
    get :robots_txt
    assert_response :success
    assert_match "", @response.body
  end
  test "robots.txt should be disallow when NOT production" do
    Rails.env.stubs(:production?).returns(false)
    get :robots_txt
    assert_response :success
    assert_match "Disallow", @response.body
  end

  context "#browse_market_name" do
    context "when market label in request path" do
      should "return request market label" do
        @market_label = 'Portland'
        get :index, {:market_label => @market_label}
        assert_equal @market_label, @controller.send(:browse_market_name)
      end
    end

    context "when market label in request path has one or more dashes" do
      should "return market label with all dashes replaced by spaces and titleized" do
        @market_label = 'portland-vancouver-hillsboro'
        get :index, {:market_label => @market_label}
        assert_equal 'Portland Vancouver Hillsboro', @controller.send(:browse_market_name)
      end
    end

    context "when request does not have a market label and a daily deal present" do
      setup do
        @daily_deal = Factory(:daily_deal)
        @market = Factory(:market, :publisher => @daily_deal.publisher)
        @daily_deal.markets << @market
        get :daily_deal, :id => @daily_deal.id
      end

      should "return daily deal's first market" do
        assert_equal @market.name, @controller.send(:browse_market_name)
      end
    end

    context "when request does not have a market label and there is no daily deal" do
      should "return 'National'" do
        get :index
        assert_equal 'National', @controller.send(:browse_market_name)
      end
    end
  end

  context "consumer_password_reset_url" do

    should "return custom url if available" do
      publishing_group = Factory(:publishing_group, :custom_consumer_password_reset_url => "http://custom.com/reset")
      publisher = Factory(:publisher, :publishing_group => publishing_group)
      assert_equal "http://custom.com/reset", @controller.send(:consumer_password_reset_path_or_url, publisher)
    end

    should "return regular helper result if publisher has no custom url" do
      publisher = Factory(:publisher)
      @controller.expects(:default_consumer_password_reset_path).with(publisher).returns("http://test.com/reset")
      assert_equal "http://test.com/reset", @controller.send(:consumer_password_reset_path_or_url, publisher)
    end

  end

  context "#default_url_options" do
    should "return a hash containing the current locale" do
      I18n.locale = :en
      assert_equal Hash[:locale => :en], @controller.send(:default_url_options)
      I18n.locale = :es
      assert_equal Hash[:locale => :es], @controller.send(:default_url_options)
      I18n.locale = :zh
      assert_equal Hash[:locale => :zh], @controller.send(:default_url_options)
    end
  end


end
