require File.dirname(__FILE__) + "/../../test_helper"

class PublishersController::DealOfTheDayTest < ActionController::TestCase
  tests PublishersController

  context 'PublishingGroup#enable_redirect_to_users_publisher' do
    setup do
      @publishing_group = Factory(:publishing_group, :label => "bcbsa", :enable_redirect_to_users_publisher => true)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group, :label => 'test-pub')
      @source_deal = Factory(:daily_deal, :publisher => @publisher)
      @consumer = Factory(:consumer, :publisher => @publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
      @other_publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @main_publisher = Factory(:publisher, :publishing_group => @publishing_group, :main_publisher => true, :label => 'bcbsa-national')
      @other_deal = Factory(:daily_deal, :publisher => @other_publisher)
    end

    should "redirect to the consumer's publisher deal page when they are logged in" do
      login_as @consumer
      get :deal_of_the_day, :label => @other_publisher.label
      assert_redirected_to public_deal_of_day_path(@publisher.label)
    end

    should "redirect to the consumer's publisher deal page whey they have the publisher_label cookie" do
      @request.cookies['publisher_label'] = @publisher.label
      get :deal_of_the_day, :label => @other_publisher.label
      assert_redirected_to public_deal_of_day_path(@publisher.label)
    end

    should "not redirect because its the consumers publisher" do
      login_as @consumer
      get :deal_of_the_day, :label => @publisher.label
      assert_response :success
      assert_template :show
    end

    should "redirect to the groups main publisher's' deal page when the user is not logged in or cookied" do
      get :deal_of_the_day, :label => @publisher.label
      assert_redirected_to public_deal_of_day_path(@main_publisher.label)
    end

    should "not redirect a consumer with a master publisher membership code on a publishing group with single sign on enabled" do
      @publishing_group.update_attributes(:allow_single_sign_on => true)
      @publishing_group.update_attribute(:require_publisher_membership_codes, true)
      master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => @publisher, :master => true)
      @consumer.update_attribute(:publisher_membership_code, master_publisher_membership_code)
      login_as @consumer
      get :deal_of_the_day, :label => @other_publisher.label
      assert_response :success
      assert_template :show
      assert_nil flash[:notice]
    end
  end

  def test_deal_of_the_day_rss
    daily_deal = Factory(:daily_deal)
    get :deal_of_the_day, :label => daily_deal.publisher.label, :format => "rss"
    assert_equal "/publishers/#{daily_deal.publisher.label}/deal-of-the-day.rss", @request.request_uri
    assert_response :success
  end
  
  def test_deal_of_the_day_rss_with_market
    daily_deal = Factory(:daily_deal)
    market = Factory(:market, :publisher => daily_deal.publisher)
    daily_deal.markets << market
    daily_deal.save!
    get :deal_of_the_day, :label => daily_deal.publisher.label, :market_label => market.label, :format => "rss"
    assert_equal "/publishers/#{daily_deal.publisher.label}/#{market.label}/deal-of-the-day.rss", @request.request_uri
    assert_response :success
  end
  
  def test_deal_of_the_day_json
    daily_deal = Factory(:daily_deal)
    get :deal_of_the_day, :label => daily_deal.publisher.label, :format => "json"
    assert_equal "/publishers/#{daily_deal.publisher.label}/deal-of-the-day.json", @request.request_uri
    assert_response :success
  end
  
  def test_deal_of_the_day_json_with_market
    daily_deal = Factory(:daily_deal)
    market = Factory(:market, :publisher => daily_deal.publisher)
    daily_deal.markets << market
    daily_deal.save!
    get :deal_of_the_day, :label => daily_deal.publisher.label, :market_label => market.label, :format => "json"
    assert_equal "/publishers/#{daily_deal.publisher.label}/#{market.label}/deal-of-the-day.json", @request.request_uri
    assert_response :success
  end
  
  def test_deal_of_the_day_next_rss
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.tomorrow.beginning_of_day, :hide_at => Time.zone.now.tomorrow.end_of_day)
    get :next_deal_of_the_day, :label => daily_deal.publisher.label, :format => "rss"
    assert_response :success
  end
  
  test "deal_of_the_day sets landing analytics_tag if there is no flash value" do
    daily_deal = Factory(:daily_deal)
    
    get :deal_of_the_day, :label => daily_deal.publisher.label
    assert_response :success

    assert @controller.analytics_tag.landing?
  end

  test "deal_of_the_day uses flash value for analytics_tag if there is one" do
    daily_deal = Factory(:daily_deal)
    
    analytics_tag = AnalyticsTag.new
    analytics_tag.signup!

    @controller.stubs(:flash).returns({
      :analytics_tag => analytics_tag
    })

    get :deal_of_the_day, :label => daily_deal.publisher.label
    assert_response :success

    assert !@controller.analytics_tag.landing?
    assert @controller.analytics_tag.signup?
  end
  
  test "deal_of_the_day with referral_code parameter sets referral_code cookie" do
    daily_deal = Factory(:daily_deal)
    
    get :deal_of_the_day, :label => daily_deal.publisher.label, :referral_code => "abcd1234"
    assert_response :success
    assert_equal "abcd1234", cookies["referral_code"]
  end
  
  test "meta tags in deal_of_the_day with referral_code parameter" do
    publishing_group = Factory(:publishing_group, :name => "Freedom", :label => "freedom")
    publisher = Factory(:publisher,:name => "OC Register", :label => "ocregister", :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher, :name => "Science Center", :tagline => "Discover", :description => "test description")
    daily_deal = Factory(:daily_deal, :advertiser => advertiser, :value_proposition => "2 for 1", :terms => "Mondays only")
  
    get :deal_of_the_day, :label => "ocregister", :referral_code => "abcd1234" * 4
    
    assert_response :success
    assert_template "themes/freedom/daily_deals/show"
    assert_theme_layout "freedom/layouts/daily_deals"
    
    assert_equal "daily_deals", assigns(:page_context)
    assert_select "meta[property=og:title][content=?]", "Check out OC Register's daily deal", 1
    assert_select "meta[property=og:description][content=?]", "Check out OC Register's daily deal - huge discounts on the coolest stuff!", 1
    assert_select "meta[name=description][content=?]", "Science Center: Discover; 2 for 1; Mondays only.", 1
  end

  context "GET deal_of_the_day" do
    setup do
      @daily_deal = Factory(:daily_deal)
      @publisher = @daily_deal.publisher
      @params = {:label => @publisher.label}
    end

    context "with referral_code parameter" do
      setup do
        @referral_code = 'anything'
        @params[:referral_code] = @referral_code
      end

      should "set the referral code cookie" do
        get :deal_of_the_day, @params
        assert @referral_code, cookies['referral_code']
      end

      context "publisher with unlimited referral time disabled" do
        setup do
          @publisher.enable_unlimited_referral_time = false
          @publisher.save!
        end

        should "set the cookie expire time to 72 hours" do
          Timecop.freeze(1.second.from_now) do # Freeze to compare cookie expire times exactly; 1 second from now so deal is available
            get :deal_of_the_day, @params
            assert_not_nil better_cookies['referral_code']['expires']
            assert_equal 72.hours.from_now.to_i, better_cookies['referral_code']['expires'].to_i # must compare as integer for some reason
          end
        end
      end

      context "publisher with unlimited referral time enabled" do
        setup do
          @publisher.enable_unlimited_referral_time = true
          @publisher.save!
        end

        should "set the referral_code cookie expire time to 10 years" do
          Timecop.freeze(1.second.from_now) do # Freeze to compare cookie expire times exactly; 1 second from now so deal is available
            get :deal_of_the_day, @params
            assert @referral_code, better_cookies['referral_code']
            assert_equal 10.years.from_now.to_i, better_cookies['referral_code']['expires'].to_i # must compare as integer for some reason
          end
        end
      end
    end
  end
  
  test "deal_of_the_day with a publisher with USD currency code" do
    daily_deal = Factory :daily_deal, :value_proposition => "40% off your visa application!", :price => 60, :value => 100
    daily_deal.publisher.update_attributes(:currency_code => "USD")
    
    get :deal_of_the_day, :label => daily_deal.publisher.label
    assert_response :success
    
    %w($40 $60 $100).each do |amount|
      assert_select "div#dashboard table tr td", :text => amount, :count => 1
    end
  end
  
  test "deal_of_the_day with a publisher with GBP currency code" do
    daily_deal = Factory :daily_deal, :value_proposition => "40% off your visa application!", :price => 60, :value => 100
    daily_deal.publisher.update_attributes(:currency_code => "GBP")
    
    get :deal_of_the_day, :label => daily_deal.publisher.label
    assert_response :success
    
    %w(£40 £60 £100).each do |amount|
      assert_select "div#dashboard table tr td", :text => amount, :count => 1
    end
  end
  
  test "deal_of_the_day with a publisher with CAD currency code" do
    daily_deal = Factory :daily_deal, :value_proposition => "40% off your visa application!", :price => 60, :value => 100
    daily_deal.publisher.update_attributes(:currency_code => "CAD")
    
    get :deal_of_the_day, :label => daily_deal.publisher.label
    assert_response :success
    
    %w(C$40 C$60 C$100).each do |amount|
      assert_select "div#dashboard table tr td", :text => amount, :count => 1
    end
  end

  test "showing freedom deals should not raise TemplateError when rendering side deals" do
    freedom = Factory :publishing_group, :label => "freedom"
    %w(ocregister shelbystar themonitor gastongazette gazette oaoa).each do |freedom_pub_label|
      freedom_pub = Factory :publisher, :label => freedom_pub_label, :publishing_group => freedom
      advertiser = Factory :advertiser, :publisher => freedom_pub, :description => "test description"
      advertiser.stores.clear
      main_deal = Factory :daily_deal, :advertiser => advertiser
      side_deal = Factory :side_daily_deal, :advertiser => advertiser
  
      get :deal_of_the_day, :label => main_deal.publisher.label
  
      assert_response :success
      assert_select "div#side_deals", { :html => /TemplateError/i, :count => 0 },
                    "#{freedom_pub_label}'s deal of the day page should not raise TemplateError (#{freedom_pub_label})"
    end
  end

  context "freedom publisher omniture tags" do

    setup do
      @publishing_group = Factory(:publishing_group, :label => "freedom")
    end
    
    should "render for ocregister on http" do
      assert_publisher_has_ominuture_tags(@publishing_group, "ocregister", :scode => "ocregister", :domain => "dealoftheday.ocregister.com")
    end
    
    should "render for ocregister on https" do
      assert_publisher_has_ominuture_tags(@publishing_group, "ocregister", :protocol => :https, :scode => "ocregister", :domain => "dealoftheday.ocregister.com")
    end
  
    should "render for gazette on http" do
      assert_publisher_has_ominuture_tags(@publishing_group, "gazette", :scode => "colgazette", :domain => "dealoftheday.gazette.com")
    end
    
    should "render for gazette on https" do
      assert_publisher_has_ominuture_tags(@publishing_group, "gazette", :protocol => :https, :scode => "colgazette", :domain => "dealoftheday.gazette.com")
    end
  
    should "render for themonitor on http" do
      assert_publisher_has_ominuture_tags(@publishing_group, "themonitor", :scode => "monitortx", :domain => "themonitor.dealoftheday.freedom.com")
    end
    
    should "render for themonitor on https" do
      assert_publisher_has_ominuture_tags(@publishing_group, "themonitor", :protocol => :https, :scode => "monitortx", :domain => "themonitor.dealoftheday.freedom.com")
    end

    should "render for rgv on http" do
      assert_publisher_has_ominuture_tags(@publishing_group, "rgv", :scode => "valleywide", :domain => "rgv.dealoftheday.freedom.com")
    end

    should "render for rgv on https" do
      assert_publisher_has_ominuture_tags(@publishing_group, "rgv", :protocol => :https, :scode => "valleywide", :domain => "rgv.dealoftheday.freedom.com")
    end
    
  end
  
  context "GET deal-of-the-day" do
    
    setup do
      @publisher = Factory(:publisher)
    end
    
    context "with publisher and no market label" do
      
      context "deal without market" do
        setup do 
          @daily_deal = Factory(:daily_deal, 
                                 :publisher => @publisher, 
                                 :description => "deal without market",
                                 :start_at => 1.day.ago,
                                 :hide_at => 2.days.from_now)
        end
        
        should "be displayed" do
          get :deal_of_the_day, :label => @publisher.label
          assert_response :success
          assert_select ".description", :text => "deal without market", :count => 1
        end
      end
      
      context "deal with market" do
        setup do
          @zip_code = "90012"
          @request.cookies['zip_code'] = @zip_code
          @market_1 = Factory(:market, :publisher => @publisher)
          @market_1_to_zip = Factory(:market_zip_code, :market => @market_1, :zip_code => @zip_code)
          @daily_deal = Factory(:daily_deal, 
                                :publisher => @publisher, 
                                :description => "deal with market",
                                :start_at => 1.day.ago,
                                :hide_at => 2.days.from_now)
          @daily_deal.markets << @market_1
          @daily_deal.save!
        end
        
        should "redirect to current_market" do
          expected_path = public_deal_of_day_for_market_path(:label => @publisher.label, :market_label => @market_1.label)
          get :deal_of_the_day, :label => @publisher.label
          assert_redirected_to expected_path
        end

        context "current_market not functioning properly and returning nil market" do
          setup do
           Market.any_instance.stubs(:label).returns(nil)
          end
          should "raise if no label" do
            assert_raises ActionController::RoutingError do
              get :deal_of_the_day, :label => @publisher.label
            end
          end
        end

      end

    end
    
    context "fb comments div on a publisher using erb templates" do
      
      setup do
        @publisher = Factory :publisher, :label => "prowlingpanther"
        @advertiser = Factory :advertiser, :publisher => @publisher
        @daily_deal = Factory :daily_deal, :advertiser => @advertiser
      end
      
      should "render the fb comments div" do
        get :deal_of_the_day, :label => @publisher.label
        assert_response :success
        assert_select "div.facebook_comments"
      end
      
    end
    
    context "fb comments div on a publisher using liquid templates" do
      
      setup do
        @publishing_group = Factory :publishing_group, :label => "freedom"
        @publisher = Factory :publisher, :label => "gazette", :publishing_group => @publishing_group
        @advertiser = Factory :advertiser, :publisher => @publisher
        @daily_deal = Factory :daily_deal, :advertiser => @advertiser
      end
      
      should "render the fb comments div" do
        get :deal_of_the_day, :label => @publisher.label
        assert_response :success
        assert_select "div.facebook_comments"
      end
      
    end
      
    context "with publisher and market label" do
      
      setup do
        @market_1 = Factory(:market, :publisher => @publisher)
        @market_2 = Factory(:market, :publisher => @publisher)
        
        @daily_deal_1 = Factory(:daily_deal, 
                                :publisher => @publisher, 
                                :description => "deal in market 1",
                                :start_at => 1.day.ago,
                                :hide_at => 2.days.from_now)
        @daily_deal_1.markets << @market_1
        @daily_deal_1.save!
        
        @daily_deal_2 = Factory(:daily_deal, 
                                :publisher => @publisher, 
                                :description => "deal in market 2",
                                :start_at => 3.days.ago,
                                :hide_at => 2.days.from_now)
        @daily_deal_2.markets << @market_2
        @daily_deal_2.save!
        
        get :deal_of_the_day, :label => @publisher.label, :market_label => @market_1.label
      end

      should "NOT render deal in another market" do
        assert_response :success
        assert_select ".description", :text => "deal in market 2", :count => 0
      end

      should "render deal in market" do
        assert_response :success
        assert_select ".description", :text => "deal in market 1", :count => 1
      end

    end
    
  end
  
  def test_deal_of_the_day_puts_market_in_cookie
    daily_deal = Factory(:daily_deal)
    market = Factory(:market, :publisher => daily_deal.publisher)
    daily_deal.markets << market
    get :deal_of_the_day, :label => daily_deal.publisher.label, :market_label => market.label
    assert_response :success
    assert_equal market, assigns(:market)
    assert_equal market.to_param, @response.cookies["daily_deal_market_id"]
  end
  
  context "buscaayuda" do
    setup do
      @publisher = Factory(:publisher, :label => 'buscaayuda')
      Factory(:daily_deal, :publisher => @publisher)
    end

    should "have links to change locales" do
      get :deal_of_the_day, :label => @publisher.label

      assert_select "a[href='/publishers/buscaayuda/deal-of-the-day']", "English"
      assert_select "a[href='/es-MX/publishers/buscaayuda/deal-of-the-day']", "Espa&ntilde;ol"
    end

  end
  
  context "deal_of_the_day rss" do
    
    should "show the hide_at date for entercom publishers" do
      Timecop.freeze(Time.parse("2011-10-31T11:11:00Z")) do
        entercomnew = Factory :publishing_group, :label => "entercomnew"
        entercom_providence = Factory :publisher, :label => "entercom-providence", :publishing_group => entercomnew
        advertiser = Factory :advertiser, :publisher => entercom_providence
        daily_deal = Factory(:daily_deal, :start_at => 10.seconds.ago, :hide_at => 2.days.from_now, :advertiser => advertiser)
        get :deal_of_the_day, :label => daily_deal.publisher.label, :format => "rss"
        xml = Nokogiri::XML(@response.body)
        assert_equal "2011-11-02T11:11:00Z", xml.css("rss channel item hide_at").text
      end
    end
    
    should "not show the hide_at date for non-entercom publishers" do
      Timecop.freeze(Time.parse("2011-10-31T11:11Z")) do
        somepub = Factory :publisher, :label => "somepub"
        advertiser = Factory :advertiser, :publisher => somepub
        daily_deal = Factory(:daily_deal, :start_at => 10.seconds.ago, :hide_at => 2.days.from_now, :advertiser => advertiser)
        get :deal_of_the_day, :label => daily_deal.publisher.label, :format => "rss"
        xml = Nokogiri::XML(@response.body)
        assert xml.css("rss channel item hide_at").blank?
      end
    end
    
  end
  
  context "deal_of_the_day xml" do
    
    should "show the hide_at date for entercom publishers" do
      Timecop.freeze(Time.parse("2011-10-31T11:11:00Z")) do
        entercomnew = Factory :publishing_group, :label => "entercomnew"
        entercom_providence = Factory :publisher, :label => "entercom-providence", :publishing_group => entercomnew
        advertiser = Factory :advertiser, :publisher => entercom_providence
        daily_deal = Factory(:daily_deal, :start_at => 10.seconds.ago, :hide_at => 2.days.from_now, :advertiser => advertiser)
        get :deal_of_the_day, :label => daily_deal.publisher.label, :format => "xml"
        xml = Nokogiri::XML(@response.body)
        assert_equal "2011-11-02T11:11:00Z", xml.css("deal hide_at").text
      end
    end
    
  end
  
  context "deal_of_the_day for aamedge publishers" do

    should "show the market selection list for daily deals" do
      pub_group = Factory :publishing_group, :label => "aamedge"
      publisher = Factory :publisher, :label => "aamedge-eastvalley", :publishing_group => pub_group, :theme => "withtheme"
      daily_deal = Factory :daily_deal, :publisher => publisher
      get :deal_of_the_day, :label => publisher.label
      assert_response :success
    end
    
  end
  
  protected

  def create_daily_deal_for_publisher(publishing_group, label)
    publisher = Factory(:publisher, :label => label, :publishing_group => publishing_group)
    @daily_deal = Factory :daily_deal, :publisher => publisher
  end
  
  def assert_publisher_has_ominuture_tags(publishing_group, label, options = {})
    options[:protocol] ||= :http
  
    if options[:protocol] == :https
      ActionController::TestRequest.any_instance.stubs(:protocol).returns("https://")
    end

    @request.host = options[:domain] if options[:domain]

    create_daily_deal_for_publisher(publishing_group, label)
    get :deal_of_the_day, :label => label
    assert_response :success
    assert_select "body", :count => 1, :html => %r{script.*src=["']#{options[:protocol]}://.*scode=#{options[:scode]}.*domain=#{options[:domain]}}

    @request.host = 'test.host' if options[:domain]

  end

end
