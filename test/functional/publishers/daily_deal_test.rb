require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::DailyDealTest < ActionController::TestCase
  tests PublishersController
  
  test "deal of the day with a current deal" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
    
    get :deal_of_the_day, :label => daily_deal.publisher.label
    
    assert_template "daily_deals/show"
    assert_layout   :daily_deals
    assert_equal    daily_deal.publisher, assigns(:publisher)
    assert_equal    daily_deal, assigns(:daily_deal)
    assert_equal    daily_deal.advertiser, assigns(:advertiser)
  end
  
  test "UNlaunched deal of the day xml" do
    valid_attributes = {
      :value_proposition => "$25 value for $12.99",
      :description => "This is a daily deal. Enjoy!",
      :terms => "These are the terms. Obey!",
      :quantity => 100,
      :price => 12.99,
      :value => 25.00,
      :photo_content_type => "image/jpeg",
      :photo_file_name => "myphoto.jpg",
      :photo_file_size => 32087
    }
    now = Time.zone.now
    publisher  = publishers(:my_space)
    publisher.disable!
    publisher.advertisers.first.daily_deals.create!( 
      valid_attributes.merge(:start_at => now - 2.hours, :hide_at => now + 1.hour) 
    )
    
    get :deal_of_the_day, :label => publisher.label, :format => 'xml'
    
    assert_equal    publisher, assigns(:publisher)
    
    daily_deal = assigns(:daily_deal)
    assert_select "deal##{daily_deal.id}" do
      assert_select "title", :text => daily_deal.value_proposition
      assert_select "advertiser_name", :text => daily_deal.advertiser_name
      assert_select "link", :text => daily_deal_url(daily_deal, :host => publisher.host)
      assert_select "image", :text => "#{daily_deal.photo.url(:widget)}" 
    end
  end
  
  test "deal of the day with no deals yet for UNlaunched freedom publisher" do
    publisher = publishers(:my_space)
    publisher.disable!
    publisher.update_attributes! :label => "ocregister"
    DailyDeal.destroy( publisher.daily_deals.collect(&:id) )
    get :deal_of_the_day, :label => publisher.label
    
    assert_equal    publisher, assigns(:publisher)
    assert_redirected_to presignup_publisher_consumers_url(publisher, :protocol => "https")
  end
  
  test "deal of the day with no deals yet for launched freedom publisher" do
    publisher = publishers(:my_space)
    publisher.update_attributes! :label => "ocregister"
    DailyDeal.destroy( publisher.daily_deals.collect(&:id) )
    assert_raise ActiveRecord::RecordNotFound do
      get :deal_of_the_day, :label => publisher.label
    end
  end

  test "deal of the day with a current deal with freedom theme" do
    publishing_group = publishing_groups(:student_discount_handbook)
    publishing_group.update_attributes! :label => "freedom"
    publisher = publishers(:my_space)
    publisher.update_attributes!(:label => "ocregister",
                                 :publishing_group => publishing_group)
    daily_deal = publisher.daily_deals.first
    daily_deal.update_attributes( :start_at => 30.minutes.ago, :hide_at => 3.hours.from_now )
    
    get :deal_of_the_day, :label => publisher.label
    
    assert_template "themes/freedom/daily_deals/show"
    assert_equal "themes/freedom/layouts/daily_deals", @response.layout
    assert_equal  publisher, assigns(:publisher)
    assert_equal  daily_deal, assigns(:daily_deal)
    
    assert_select "head > title", "Today's deal from Burger King - Deal of the Day: MySpace"
  end 
  
  test "deal of the day with a current deal for nydailynews" do
    publisher = publishers(:my_space)
    publisher.update_attributes! :label => "nydailynews"
    daily_deal = publisher.daily_deals.first
    daily_deal.update_attributes( :start_at => 30.minutes.ago, :hide_at => 3.hours.from_now )
    
    get :deal_of_the_day, :label => publisher.label
    
    assert_template     "themes/nydailynews/daily_deals/show"
    assert_theme_layout "nydailynews/layouts/daily_deals"
    assert_equal        publisher, assigns(:publisher)
    assert_equal        daily_deal, assigns(:daily_deal)    
  end  
  
  test "deal of the day with a current deal with no store for advertiser for nydailynews" do
    publisher = publishers(:my_space)
    publisher.update_attributes! :label => "nydailynews"
    daily_deal = publisher.daily_deals.first
    daily_deal.advertiser.stores.destroy_all
    daily_deal.update_attributes( :start_at => 30.minutes.ago, :hide_at => 3.hours.from_now )
    
    get :deal_of_the_day, :label => publisher.label
    
    assert_template     "themes/nydailynews/daily_deals/show"
    assert_theme_layout "nydailynews/layouts/daily_deals"
    assert_equal        publisher, assigns(:publisher)
    assert_equal        daily_deal, assigns(:daily_deal)    
  end
  
  test "deal of the day with a current deal for nydailynews for rss" do
    publisher = publishers(:my_space)
    publisher.update_attributes! :label => "nydailynews"
    daily_deal = publisher.daily_deals.first
    daily_deal.update_attributes( :start_at => 30.minutes.ago, :hide_at => 3.hours.from_now )
    
    get :deal_of_the_day, :label => publisher.label, :format => 'rss'
    
    assert_template     "themes/nydailynews/daily_deals/show.rss.builder"
    assert_equal        publisher, assigns(:publisher)
    assert_equal        daily_deal, assigns(:daily_deal)    
  end    
  
  test "deal of the day with a current deal for pennlive for rss" do
    publisher = publishers(:my_space)
    publisher.publishing_group = Factory(:publishing_group, :name => "Advance.net", :label => "advance")
    publisher.update_attributes! :label => "pennlive"
    daily_deal = publisher.daily_deals.first
    daily_deal.update_attributes( :start_at => 30.minutes.ago, :hide_at => 3.hours.from_now )
    
    assert_not_nil publisher.publishing_group
    
    get :deal_of_the_day, :label => publisher.label, :format => 'rss'
    
    assert_template     "daily_deals/show.rss.builder"
    assert_equal        publisher, assigns(:publisher)
    assert_equal        daily_deal, assigns(:daily_deal)  
    assert_not_nil      assigns(:time)
    
    assert_select "rss" do
      assert_select "channel" do
        assert_select "title",  :text => "#{publisher.brand_name} Daily Deals RSS".strip
        assert_select "link",   :text => "http://#{publisher.host}"
        assert_select "lastBuildDate", :text => publisher.localize_time(assigns(:time)).rfc822
        assert_select "item" do
          assert_select "pubDate", :text => publisher.localize_time(daily_deal.start_at).rfc822
          assert_select "title", :text => daily_deal.value_proposition
          assert_select "description", :text => daily_deal.description   
          assert_select "link", :text => "http://#{publisher.host}/daily_deals/#{daily_deal.id}"
        end
      end
    end
      
  end
  
  test "deal of the day invalid (not found) label" do
    begin
      ActionController::Base.consider_all_requests_local = false
      @request.env["REMOTE_ADDR"] = "65.102.59.65"
      @request.host = "sb1.analoganalytics.com"
      get :deal_of_the_day, :label => "picayune-observer-scanner"
      assert_template "public/404.html"
      assert_response :missing
    ensure
      ActionController::Base.consider_all_requests_local = true
    end
  end
  
  test "navbar is hidden when publisher is disabled" do
    publisher = publishers(:my_space)
    publisher.update_attributes! :label => "ocregister", :launched => false
    
    get :deal_of_the_day, :label => publisher.label
    
    assert_no_tag :tag => "a", :parent => { :tag => "div", :attributes => { :id => "nav" }}
  end

  test "deal of the day with a current deal and a previous deal" do
    publisher = publishers(:my_space)
    
    valid_attributes = {
      :value_proposition => "$25 value for $12.99",
      :description => "This is a daily deal. Enjoy!",
      :terms => "These are the terms. Obey!",
      :quantity => 100,
      :price => 12.99,
      :value => 25.00
    }
    
    advertiser = publisher.advertisers.first
    now = Time.zone.now
    current_deal = advertiser.daily_deals.create!( valid_attributes.merge(:start_at => now - 2.hours, :hide_at => now + 1.hour) )
    previous_deal = advertiser.daily_deals.create!( valid_attributes.merge(:start_at => now - 10.hours, :hide_at => now - 2.hours) )
    
    get :deal_of_the_day, :label => publisher.label

    assert_template "daily_deals/show"
    assert_layout   :daily_deals
    assert_equal    publisher, assigns(:publisher)
    assert_equal    current_deal, assigns(:daily_deal)    
    
  end
  
  test "deal of the day with a future deal and a previous deal" do
    publisher = publishers(:my_space)
    
    valid_attributes = {
      :value_proposition => "$25 value for $12.99",
      :description => "This is a daily deal. Enjoy!",
      :terms => "These are the terms. Obey!",
      :quantity => 100,
      :price => 12.99,
      :value => 25.00
    }
    
    advertiser = publisher.advertisers.first
    now = Time.zone.now
    future_deal = advertiser.daily_deals.create!( valid_attributes.merge(:start_at => now + 40.minutes, :hide_at => now + 4.hours) )
    previous_deal = advertiser.daily_deals.create!( valid_attributes.merge(:start_at => now - 10.hours, :hide_at => now - 2.hours) )
    
    get :deal_of_the_day, :label => publisher.label

    assert_template "daily_deals/show"
    assert_layout   :daily_deals
    assert_equal    publisher, assigns(:publisher)
    assert_equal    previous_deal, assigns(:daily_deal)    
    
  end
  
  test "deal of the day should use side deal if no featured deals" do
    deal = Factory(:side_daily_deal)
    
    get :deal_of_the_day, :label => deal.publisher.label

    assert_response :success
    assert_template "daily_deals/show"
    assert_equal    deal, assigns(:daily_deal)    
  end
  
  test "deal of the day should use past side deal if no featured deals" do
    deal = Factory(:side_daily_deal, :start_at => 10.hours.ago, :hide_at => 2.hours.ago)
    
    get :deal_of_the_day, :label => deal.publisher.label

    assert_response :success
    assert_template "daily_deals/show"
    assert_equal    deal, assigns(:daily_deal)    
  end
  
  test "deal of the day should use active side deal if no featured deals" do
    deal = Factory(:side_daily_deal)
    Factory(:side_daily_deal, :start_at => 10.hours.ago, :hide_at => 2.hours.ago)
    
    get :deal_of_the_day, :label => deal.publisher.label

    assert_response :success
    assert_template "daily_deals/show"
    assert_equal    deal, assigns(:daily_deal)    
  end
  
  test "deal of the day should return 404 if there are no deals" do
    assert_raise ActiveRecord::RecordNotFound do
      get :deal_of_the_day, :label => Factory(:publisher).label
    end
  end
  
  test "deal of the day with xml format" do
    publisher = publishers(:my_space)
    
    valid_attributes = {
      :value_proposition => "$25 value for $12.99",
      :description => "This is a daily deal. Enjoy!",
      :terms => "These are the terms. Obey!",
      :quantity => 100,
      :price => 12.99,
      :value => 25.00,
      :photo_content_type => "image/jpeg",
      :photo_file_name => "myphoto.jpg",
      :photo_file_size => 32087
    }
    
    advertiser = publisher.advertisers.first
    now = Time.zone.now
    current_deal = advertiser.daily_deals.create!( valid_attributes.merge(:start_at => now - 2.hours, :hide_at => now + 1.hour) )
    get :deal_of_the_day, :label => publisher.label, :format => 'xml'
    
    daily_deal = assigns(:daily_deal)
    assert_select "deal##{daily_deal.id}" do
      assert_select "title", :text => daily_deal.value_proposition
      assert_select "advertiser_name", :text => daily_deal.advertiser_name
      assert_select "link", :text => daily_deal_url(daily_deal, :host => publisher.host)
      assert_select "image", :text => "#{daily_deal.photo.url(:widget)}" 
    end
  end
  
  test "deal of the day with xml format and publisher theme" do
    publisher = Factory(:publisher, :publishing_group => Factory(:publishing_group, :label => "freedom"))
    advertiser = Factory(:advertiser, :name => "Discovery Science Center", :publisher => publisher)
    
    valid_attributes = {
      :value_proposition => "$25 value for $12.99",
      :description => "This is a daily deal. Enjoy!",
      :terms => "These are the terms. Obey!",
      :quantity => 100,
      :price => 12.50,
      :value => 25.00,
      :photo_content_type => "image/jpeg",
      :photo_file_name => "myphoto.jpg",
      :photo_file_size => 32087
    }
    now = Time.zone.now
    current_deal = advertiser.daily_deals.create!( valid_attributes.merge(:start_at => now - 2.hours, :hide_at => now + 1.hour) )
    get :deal_of_the_day, :label => publisher.label, :format => 'xml'
    
    daily_deal = assigns(:daily_deal)
    assert_select "deal##{daily_deal.id}" do
      assert_select "title", :text => "$25 value for $12.99"
      assert_select "advertiser_name", :text => "Discovery Science Center"
      assert_select "link", :text => daily_deal_url(daily_deal, :host => publisher.host)
      assert_select "image", :text => "#{daily_deal.photo.url(:widget)}" 
    end
  end
  
  test "deal of the day with json format" do
    daily_deal = stubbed_daily_deal
    
    get :deal_of_the_day, :label => daily_deal.publisher.label, :format => "json"
    assert_response :success
    
    daily_deal = assigns(:daily_deal)
    json = ActiveSupport::JSON.decode(@response.body)["daily_deal"]
    assert_equal daily_deal.id, json["id"], "id"
    assert_equal daily_deal.value_proposition, json["title"], "value_proposition"
    assert_equal daily_deal.advertiser_name, json["advertiser_name"], "advertiser_name"
    assert_equal "http://photos.daily_deals.analoganalytics.com/production/12187/widget.png?1284066113", json["image"], "image"
    assert_equal "http://sb1.analoganalytics.com/daily_deals/#{daily_deal.to_param}", json["link"], "link"
    assert_nil @response.headers["Set-Cookie"], "Should not Set-Cookie for JSON response"
  end
  
  test "deal of the day as JSONP" do
    daily_deal = stubbed_daily_deal
    callback = "jsonp1289316949524"
    get :deal_of_the_day, :label => daily_deal.publisher.label, :format => "json", :callback => callback
    assert_response :success

    assert_match %r{jsonp1289316949524\(\{\"daily_deal\":}, @response.body, "Should wrap JSON as JSONP"
    json = @response.body[(callback.length + 1)..-2]
    
    json = ActiveSupport::JSON.decode(json)["daily_deal"]
    daily_deal = assigns(:daily_deal)
    assert_equal daily_deal.id, json["id"], "id"
    assert_equal daily_deal.value_proposition, json["title"], "value_proposition"
    assert_equal daily_deal.advertiser_name, json["advertiser_name"], "advertiser_name"
    assert_equal "http://photos.daily_deals.analoganalytics.com/production/12187/widget.png?1284066113", json["image"], "image"
    assert_equal "http://sb1.analoganalytics.com/daily_deals/#{daily_deal.to_param}", json["link"], "link"
  end

  test "tomorrow deal of the day" do
    publisher  = publishers(:my_space)
    daily_deal = publisher.daily_deals.first
    daily_deal.update_attribute(:start_at, Time.zone.now.end_of_day + 30.minutes )
    daily_deal.update_attribute(:hide_at, Time.zone.now.end_of_day + 14.hours )
    
    get :tomorrow_deal_of_the_day, :label => publisher.label
    
    assert_template "daily_deals/show"
    assert_layout   :daily_deals
    assert_equal    publisher, assigns(:publisher)
    assert_equal    daily_deal, assigns(:daily_deal)    
  end 
  
  test "tomorrow deal of the day with a current deal" do
    publisher  = publishers(:my_space)
    advertiser = publisher.advertisers.create!( :name => "Advertiser" )
    current_daily_deal  = advertiser.daily_deals.create!( :price => 12.00, :value => 24.00, :description => "current deal", :terms => "My terms", :value_proposition => "value prop", :start_at => Time.zone.now.beginning_of_day, :hide_at => Time.zone.now.end_of_day - 5.minutes)
    tomorrow_daily_deal = advertiser.daily_deals.create!( :price => 12.00, :value => 24.00, :description => "tomorrow deal", :terms => "My terms", :value_proposition => "value prop", :start_at => Time.zone.now.beginning_of_day + 1.day, :hide_at => Time.zone.now.end_of_day + 14.hours )
    
    get :tomorrow_deal_of_the_day, :label => publisher.label
    
    assert_template "daily_deals/show"
    assert_layout   :daily_deals
    assert_equal    publisher, assigns(:publisher)
    assert_equal    tomorrow_daily_deal, assigns(:daily_deal)    
  end
  
  test "tomorrow deal of the day with no deal tomorrow" do
    publisher = Factory(:publisher)
    assert_raise ActiveRecord::RecordNotFound do
      get :tomorrow_deal_of_the_day, :label => publisher.label
    end
  end 

  test "test deal of the direct redirect includes query string" do
    publisher = Factory(:publisher, :launched => false)
    get :deal_of_the_day, :label => publisher.label, :referral_code => "123456789"
    assert_redirected_to presignup_publisher_consumers_url(publisher, :referral_code => "123456789", :protocol => "https")
  end

  context "uses_daily_deal_subscribers_presignup" do
    setup do
      @publisher = Factory(:publisher, :launched => false)
    end

    context "when set" do
      setup do
        @publisher.update_attributes(:uses_daily_deal_subscribers_presignup => true, :label => "pub-label")
      end

      should "redirect to subscribers presignup page" do
        get :deal_of_the_day, :label => @publisher.label
        assert_redirected_to presignup_publisher_daily_deal_subscribers_url(@publisher, :protocol => "https")
      end
    end

    context "when not set" do
      should "redirect to consumers presignup page" do
        get :deal_of_the_day, :label => @publisher.label
        assert_redirected_to presignup_publisher_consumers_url(@publisher, :protocol => "https")
      end
    end
  end

  context "deal for publisher with affiliate popup enabled" do
    setup do
      @daily_deal = Factory(:daily_deal,
                            :affiliate_url => "http://dealmiddleman.com/xyz",
                            :advertiser => Factory(:advertiser,
                                                   :publisher => Factory(:publisher,
                                                                         :label => "kowabunga",
                                                                         :enable_affiliate_url_popup => true)))

      assert @daily_deal.active?
    end

    should "render confirmation dialog when the user is logged in" do
      user = Factory(:consumer)
      login_as user

      get :deal_of_the_day, :label => @daily_deal.advertiser.publisher.label
      assert_equal @daily_deal, assigns(:daily_deal)

      assert_response :success
      assert_template "kowabunga/daily_deals/show"

      assert_select "#affiliate_link_confirmation" do
        assert_select "#cancel_redirect"
        assert_select "#confirm_redirect"
      end
    end

    should "render new subscriber form when the user is not logged in" do
      get :deal_of_the_day, :label => @daily_deal.advertiser.publisher.label

      assert_response :success
      assert_template "kowabunga/daily_deals/show"
      assert_select "#affiliate_link_popup_content"
    end
    
  end
end
