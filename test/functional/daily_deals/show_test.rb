require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::ShowTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  context "show with refering information" do

    setup do
      @publisher  = Factory(:publisher)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    context "kowabunga parameters" do

      context "with pubid parameter" do

        context "with no initial cookies[ref] value set" do
          setup do
            @request.cookies["ref"] = nil
            get :show, :id => @daily_deal.to_param, :pubid => "12345"
          end

          should "update the cookies[ref] to '12345'" do
            assert_equal '12345', cookies["ref"]
          end

          should "set the retain_until to 30 days from now" do
            assert_equal Time.zone.now.to_date + 30.days, cookies["retain_until"].to_date
          end
        end

        context "with initial cookie[ref] value set" do
          setup do
            @request.cookies["ref"] = "99999"
          end

          context "with retain_until in the past" do
            setup do
              @request.cookies["retain_until"] = 1.day.ago
              get :show, :id => @daily_deal.to_param, :pubid => "12345"
            end

            should "update the cookies[ref] to '12345'" do
              assert_equal '12345', cookies["ref"]
            end
          end

          context "with retain_until in the future" do
            setup do
              @request.cookies["retain_until"] = 2.days.from_now
              get :show, :id => @daily_deal.to_param, :pubid => "12345"
            end

            should "update cookies['ref'] until Inuvo tells us what they want to do with the retain_until logic" do
              assert_equal "12345", cookies["ref"]
            end
          end
        end
      end

      context "without pubid" do
        setup do
          get :show, :id => @daily_deal.to_param, :notpubid => "12345"
        end

        should "not set cookies[ref]" do
          assert_nil cookies["ref"]
        end
      end

      context "with sourceid parameter" do
        setup do
          get :show, :id => @daily_deal.to_param, :sourceid => "from_somewhere_special"
        end

        should "set session[src] to 'from_somewhere_special'" do
          assert_equal "from_somewhere_special", session[:src]
        end
      end

      context "without sourceid parameter" do
        setup do
          get :show, :id => @daily_deal.to_param, :nottherightsourceid => "from_somewhere_special"
        end

        should "set not set session[:src]" do
          assert_nil session[:src]
        end
      end

    end
  end

  context "show with affiliate_url on daily deal" do

    setup do
      @publishing_group = Factory(:publishing_group, :label => "freedom")
      @publisher  = Factory(:publisher, :label => "ocregister", :publishing_group => @publishing_group)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher, :affiliate_url => "http://someothersite.com/path/?param1=hello&abc=%ref%&xyz=%src%")
    end

    context "with cookies[ref] set" do

      setup do
        @request.cookies["ref"] = "12345"
        get :show, :id => @daily_deal.to_param
      end

      should "render the correct buy now button" do
        assert_select "#buy_now_button[href*='http://someothersite.com/path/?param1=hello&abc=12345&xyz=']", true, "should display buy now button with affiliate link with value for ref and no value for src"
      end

    end

    context "with session[src] set" do

      setup do
        session[:src] = "abcde"
        get :show, :id => @daily_deal.to_param
      end

      should "render the correct buy now button" do
        assert_select "#buy_now_button[href*='http://someothersite.com/path/?param1=hello&abc=&xyz=abcde']", true, "should display buy now button with affiliate link with no values for ref and a value for src"
      end

    end

    context "with no cookies[ref] or session[src] set" do

      setup do
        get :show, :id => @daily_deal.to_param
      end

      should "render the correct buy now button" do
        assert_select "#buy_now_button[href*='http://someothersite.com/path/?param1=hello&abc=&xyz=']", true, "should display buy now button with affiliate link with no values for ref and src"
      end

    end

  end

  test "should should allow https for js request" do
    ssl_on
    get :show, :id => daily_deals(:burger_king).to_param, :format => "js"
    assert_response :success
  end

  test "should should allow https for json request" do
    ssl_on
    get :show, :id => daily_deals(:burger_king).to_param, :format => "json"
    assert_response :success
  end

  test "should show deal" do
    get :show, :id => daily_deals(:burger_king).to_param

    assert_response :success
    assert_template :show
    assert_layout   :daily_deals

    daily_deal    = assigns(:daily_deal)
    assert_select "meta[name=title][content=?]", "MySpace Deal of the Day: $81 value for $39", 1, "title metatag for daily deal"

    assert_select "meta[name=description][content=?]",
                  "Burger King: Have it your way; $81 value for $39; These are the terms.", 1,
                  "description metatag for daily deal"

    assert_select "#deal_credit", 1
    assert_equal daily_deal.advertiser, assigns(:advertiser), "@advertiser"
  end

  test "should show deal with theme template" do
    publishing_group = Factory(:publishing_group, :name => "Freedom", :label => "freedom")
    publisher = Factory(:publisher,:name => "OC Register", :label => "ocregister", :publishing_group => publishing_group)
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
    daily_deal = advertiser.daily_deals.create!(
      :price => 39,
      :value => 80,
      :description => "awesome deal",
      :terms => "GPL",
      :value_proposition => "buy now",
      :start_at => 1.day.ago,
      :hide_at => 3.days.from_now
    )

    get :show, :id => daily_deal

    assert_response     :success
    assert_template     "themes/freedom/daily_deals/show"
    assert_theme_layout "freedom/layouts/daily_deals"

    assert_select "meta[property=og:title][content=?]", "OC Register Deal of the Day: buy now", 1, "og:title metatag for daily deal"

    assert_select "meta[name=description][content=?]",
                  "Advertiser; buy now; GPL.", 1,
                  "description metatag for daily deal"

  end

  test "should show deal and hide deal credit when logged in" do
    consumer = users(:john_public)
    consumer.save!

    login_as :john_public
    get :show, :id => daily_deals(:burger_king).to_param

    assert_response :success
    assert_template :show
    assert_layout   :daily_deals

    daily_deal    = assigns(:daily_deal)
    assert_select "meta[name=title][content=?]", "MySpace Deal of the Day: $81 value for $39", 1, "title metatag for daily deal"

    assert_select "meta[name=description][content=?]",
                  "Burger King: Have it your way; $81 value for $39; These are the terms.", 1,
                  "description metatag for daily deal"

    assert_select "#widgets #deal_credit", 0
  end

  test "show as JSON" do
    daily_deal = daily_deals(:burger_king)
    get :show, :format => 'json', :id => daily_deal.to_param
    json = ActiveSupport::JSON.decode( @response.body )

    assert_response :success
    assert_equal  daily_deal.ending_time_in_milliseconds, json['daily_deal']['ending_time_in_milliseconds']
    assert_equal  daily_deal.number_sold, json['daily_deal']['number_sold']
  end

  test "show future deal as JSON" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.tomorrow, :hide_at => 1.week.from_now(Time.zone.now))
    get :show, :format => "json", :id => daily_deal.to_param
    json = ActiveSupport::JSON.decode(@response.body)

    assert_response :success
    assert_equal daily_deal.ending_time_in_milliseconds, json['daily_deal']['ending_time_in_milliseconds']
    assert_equal 0, json['daily_deal']['number_sold']
  end

  test "show past deal as JSON" do
    daily_deal = Factory(:daily_deal, :start_at => 3.days.ago, :hide_at => Time.zone.now.yesterday)
    get :show, :format => "json", :id => daily_deal.to_param
    json = ActiveSupport::JSON.decode(@response.body)

    assert_response :success
    assert_equal daily_deal.ending_time_in_milliseconds, json['daily_deal']['ending_time_in_milliseconds']
    assert_equal 0, json['daily_deal']['number_sold']
  end

  context "js for the daily deal page" do

    setup do
      Publisher.destroy_all
    end

    context "for publishers" do

      context "with defaults" do

        setup do
          @publisher  = Factory(:publisher, :label => "8newsnow")
          @daily_deal = Factory(:daily_deal, :publisher => @publisher )
          get :show, :format => "js", :id => @daily_deal.to_param
        end

        should render_template("daily_deals/show.js.erb")

      end

      context "for buscaayuda" do

        setup do
          @publisher  = Factory(:publisher, :label => "buscaayuda")
          @daily_deal = Factory(:daily_deal, :publisher => @publisher)
          get :show, :format => "js", :id => @daily_deal.to_param
        end

        should "render customized show.js.erb" do
          assert_template "themes/#{@publisher.label}/daily_deals/show.js.erb"
        end

      end

      context "for buscaayuda-Spanish" do

        setup do
          @publisher  = Factory(:publisher, :label => "buscaayuda-Spanish")
          @daily_deal = Factory(:daily_deal, :publisher => @publisher)
          get :show, :format => "js", :id => @daily_deal.to_param
        end

        should "render customized show.js.erb" do
          assert_template "themes/#{@publisher.label}/daily_deals/show.js.erb"
        end

      end

      context "for newsday" do

        setup do
          @publisher  = Factory(:publisher, :label => "newsday")
          @daily_deal = Factory(:daily_deal, :publisher => @publisher)
          get :show, :format => "js", :id => @daily_deal.to_param
        end

        should "render customized show.js.erb" do
          assert_template "themes/#{@publisher.label}/daily_deals/show.js.erb"
        end

      end

      context "for nydailynews" do

        setup do
          @publisher  = Factory(:publisher, :label => "nydailynews")
          @daily_deal = Factory(:daily_deal, :publisher => @publisher)
          get :show, :format => "js", :id => @daily_deal.to_param
        end

        should "render customized show.js.erb" do
          assert_template "themes/#{@publisher.label}/daily_deals/show.js.erb"
        end

      end

    end

    context "for publishing groups" do

      context "for rr publishing group with custom show.js.erb" do

        setup do
          @publishing_group = Factory(:publishing_group, :label => "rr")
          @publisher        = Factory(:publisher, :label => "alabamalive", :publishing_group => @publishing_group)
          @daily_deal       = Factory(:daily_deal, :publisher => @publisher)
          get :show, :format => "js", :id => @daily_deal.to_param
        end

        should "render customized show.js.erb" do
          assert_template "themes/#{@publishing_group.label}/daily_deals/show.js.erb"
        end

      end

      context "for entertainment publishing group without custom show.js.erb" do

        setup do
          @publishing_group = Factory(:publishing_group, :label => "entertainment")
          @publisher        = Factory(:publisher, :label => "entertainmentdallas", :publishing_group => @publishing_group)
          @daily_deal       = Factory(:daily_deal, :publisher => @publisher)
          get :show, :format => "js", :id => @daily_deal.to_param
        end

        should "render default show.js.erb" do
          assert_template "daily_deals/show.js.erb"
        end

      end

    end

  end

  context "show feed" do

    setup do
      advertiser = Factory(:advertiser,
                           :name        => "Foo Advertiser",
                           :website_url => "http://example.com",
                           :stores      => [])

      Factory(:store,
              :advertiser     => advertiser,
              :address_line_1 => "123 Foo Street",
              :address_line_2 => "Suite 1",
              :city           => "Nowhere",
              :state          => "OK",
              :zip            => "73038",
              :phone_number   => "5551234567")

      @start_at = Time.utc(2012, 3, 28, 5, 15)
      @hide_at = @start_at + 10.days
      @daily_deal = Factory(:daily_deal,
                            :advertiser => advertiser,
                            :value_proposition => "Dummy proposition",
                            :value_proposition_subhead => "Dummy subhead",
                            :description => "Dummy description",
                            :short_description => "Dummy short desc",
                            :price => 1,
                            :quantity => 10,
                            :value => 100,
                            :highlights => "Dummy highlights",
                            :terms => "Dummy terms",
                            :reviews => "Dummy reviews",
                            :twitter_status_text => "Dummy twitter status",
                            :facebook_title_text => "Dummy facebook title",
                            :min_quantity => 5,
                            :max_quantity => 10,
                            :start_at => @start_at,
                            :hide_at => @hide_at,
                            :listing => "FOO-123")

    end

    should "show correct XML fields from a GET" do
      get :show, :format => 'xml', :id => @daily_deal.to_param

      xml = Hash.from_xml(@response.body)

      assert_response :success

      assert_select "deal##{@daily_deal.id}" do
        assert_select "title", "Dummy proposition"
        assert_select "advertiser_name", "Foo Advertiser"
        assert_select "link", daily_deal_url(@daily_deal, :host => @daily_deal.publisher.daily_deal_host)

        assert_select "subhead", "Dummy subhead"
        assert_select "description", "<p>Dummy description</p>"
        assert_select "short_description", "Dummy short desc"

        assert_select "price", "1.0"
        assert_select "quantity", "10"
        assert_select "value", "100.0"
        assert_select "highlights", "<p>Dummy highlights</p>"
        assert_select "terms", "<p>Dummy terms</p>"
        assert_select "reviews", "<p>Dummy reviews</p>"

        assert_select "twitter_status_text", "Dummy twitter status"
        assert_select "facebook_title_text", "Dummy facebook title"

        assert_select "min_quantity", "5"
        assert_select "max_quantity", "10"
        
        assert_select "number_sold", "0"

        assert_select "listing", "FOO-123"

        assert_select "start_at", @start_at.utc.iso8601
        assert_select "hide_at", @hide_at.utc.iso8601

        assert_select "advertiser" do
          assert_select "name", "Foo Advertiser"
          assert_select "website_url", "http://example.com"

          assert_select "store", 2 do
            assert_select "address_line_1", "123 Foo Street"
            assert_select "address_line_2", "Suite 1"
            assert_select "city", "Nowhere"
            assert_select "state", "OK"
            assert_select "zip_code", "73038"
            assert_select "phone_number", "15551234567" 
          end

        end
      end
    end

  end

  test "show future deal as XML" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.tomorrow, :hide_at => 1.week.from_now(Time.zone.now))

    get :show, :format => 'xml', :id => daily_deal.to_param

    xml = Hash.from_xml(@response.body)

    assert_response :success
    assert_equal daily_deal.id.to_s, xml['deal']['id']
    assert_equal daily_deal.value_proposition, xml['deal']['title']
    assert_equal daily_deal_url(daily_deal, :host => daily_deal.publisher.daily_deal_host), xml['deal']['link']
  end

  test "show past deal as XML" do
    daily_deal = Factory(:daily_deal, :start_at => 3.days.ago, :hide_at => Time.zone.now.yesterday)

    get :show, :format => 'xml', :id => daily_deal.to_param

    xml = Hash.from_xml(@response.body)

    assert_response :success
    assert_equal daily_deal.id.to_s, xml['deal']['id']
    assert_equal daily_deal.value_proposition, xml['deal']['title']
    assert_equal daily_deal_url(daily_deal, :host => daily_deal.publisher.daily_deal_host), xml['deal']['link']
  end

  test "show for freedom with one advertiser location" do
    publishing_group = Factory(:publishing_group, :name => "Freedom", :label => "freedom")
    publisher = Factory(:publisher,:name => "OC Register", :label => "ocregister", :publishing_group => publishing_group)
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
    advertiser.stores.create!(:address_line_1 => "123 Main Street", :city => "Laguna Beach", :state => "CA", :zip => "92651")
    daily_deal = advertiser.daily_deals.create!(
      :price => 39,
      :value => 80,
      :description => "awesome deal",
      :terms => "GPL",
      :value_proposition => "buy now",
      :start_at => 1.day.ago,
      :hide_at => 3.days.from_now
    )
    get :show, :id => daily_deal.to_param

    assert @controller.analytics_tag.landing?

    assert_response :success
    assert_template "themes/freedom/daily_deals/show"
    assert_select "div.location_container", /123 Main Street\s+Laguna Beach, CA 92651/, 1
  end

  test "show for freedom with two advertiser locations" do
    publishing_group = Factory(:publishing_group, :name => "Freedom", :label => "freedom")
    publisher = Factory(:publisher, :name => "OC Register", :label => "ocregister", :publishing_group => publishing_group)
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :description => "test description")
    advertiser.stores.create!(:address_line_1 => "123 Main Street", :city => "Laguna Beach", :state => "CA", :zip => "92651")
    advertiser.stores.create!(:address_line_1 => "456 Main Street", :city => "Laguna Beach", :state => "CA", :zip => "92652")
    daily_deal = advertiser.daily_deals.create!(
      :price => 39,
      :value => 80,
      :description => "awesome deal",
      :terms => "GPL",
      :value_proposition => "buy now",
      :start_at => 1.day.ago,
      :hide_at => 3.days.from_now
    )
    get :show, :id => daily_deal.to_param

    assert @controller.analytics_tag.landing?

    assert_response :success
    assert_template "themes/freedom/daily_deals/show"
    assert_select "div.location_container", 2
  end

  test "show with referral_code parameter should set referral_code cookie" do
    get :show, :id => daily_deals(:burger_king).to_param, :referral_code => "abcd1234"

    assert_response :success
    assert_equal "abcd1234", cookies["referral_code"]
  end

  context "GET show" do

    setup do
      @ocregister = Factory(:publisher, :label => "ocregister")
      @daily_deal = Factory(:daily_deal, :publisher => @ocregister)
    end

    context "with referral_code parameter" do
      setup do
        @referral_code = 'anything'
        @params = {:id => @daily_deal, :referral_code => @referral_code}
        @publisher = @ocregister
      end

      should "set the referral code cookie" do
        get :show, @params
        assert @referral_code, cookies['referral_code']
      end

      context "publisher with unlimited referral time disabled" do
        setup do
          @publisher.enable_daily_deal_referral = true
          @publisher.enable_unlimited_referral_time = false
          @publisher.save!
        end

        should "set the cookie expire time to 72 hours" do
          Timecop.freeze(1.second.from_now) do # Freeze to compare cookie expire times exactly; 1 second from now so deal is available
            get :show, @params
            assert_not_nil better_cookies['referral_code']['expires']
            assert_equal 72.hours.from_now.to_i, better_cookies['referral_code']['expires'].to_i # must compare as integer for some reason
          end
        end
      end

      context "publisher with unlimited referral time enabled" do
        setup do
          @publisher.enable_daily_deal_referral = true
          @publisher.enable_unlimited_referral_time = true
          @publisher.save!
        end

        should "set the referral_code cookie expire time to 10 years" do
          Timecop.freeze(1.second.from_now) do # Freeze to compare cookie expire times exactly; 1 second from now so deal is available
            get :show, @params
            assert @referral_code, better_cookies['referral_code']
            assert_equal 10.years.from_now.to_i, better_cookies['referral_code']['expires'].to_i # must compare as integer for some reason
          end
        end
      end
    end
  end

  test "viewing a daily deal page with placement_code parameter should set the placement_code cookie" do
    daily_deal = Factory(:daily_deal)
    uuid = UUIDTools::UUID.random_create.to_s

    get :show, :id => daily_deal.to_param, :placement_code => uuid
    assert_response :success

    assert_equal uuid, cookies['placement_code']
  end

  test "show should clear market id cookie" do
    @daily_deal = Factory(:daily_deal)
    @request.cookies["daily_deal_market_id"] = "2"
    get :show, :id => @daily_deal.to_param
    assert_response :success
    assert_template :show
    assert_layout :daily_deals
    assert @response.cookies["daily_deal_market_id"] == nil
  end

end
