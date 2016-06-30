require File.dirname(__FILE__) + "/../../test_helper"

class Reports::DailyDealsControllerTest < ActionController::TestCase

  context "daily deals api" do
    setup do
      login_as(Factory(:admin))

      @advertiser = Factory.create(:advertiser_with_listing, :website_url => "http://www.exampledeal.com/deal")
      @advertiser.stores << Factory.create(:store, :advertiser => @advertiser, :listing => "123456")
      @publisher = @advertiser.publisher
      @category = Factory.create(:daily_deal_category)

      @daily_deal_one = Factory.create(:daily_deal, attributes_for_daily_deal)

      2.times { @daily_deal_one.markets << Factory.create(:market) }

      @daily_deal_two = Factory.create(:side_daily_deal, attributes_for_daily_deal)
      @daily_deal_three = Factory.create(:side_daily_deal, attributes_for_daily_deal)

      assert_equal 2, @advertiser.stores.size
      assert_equal 2, @daily_deal_one.markets.size

      @deal_array = [@daily_deal_one, @daily_deal_two, @daily_deal_three]

      get :index, :publisher_id => @publisher.id, :format => "xml"
      @doc = Nokogiri.parse(@response.body, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
      assert_equal "http://analoganalytics.com/api/daily_deals", @doc.root.namespace.href
      @doc.remove_namespaces!
    end

    context "syndicated daily deal export (GET to :syndicated_daily_deals, format XML)" do

      setup do
        @publisher = Factory :publisher
        @user = Factory :user, :company => @publisher
        @advertiser = Factory :advertiser, :publisher => @publisher
        @other_pub_deal_1 = Factory :side_daily_deal_for_syndication
        @other_pub_deal_2 = Factory :side_daily_deal_for_syndication
        @other_pub_deal_3 = Factory :side_daily_deal_for_syndication
        @non_syndicated_deal = Factory :daily_deal, :advertiser => @advertiser
        @syndicated_deal_1 = syndicate @other_pub_deal_1, @publisher
        @syndicated_deal_2 = syndicate @other_pub_deal_2, @publisher
        @syndicated_deal_deleted = syndicate @other_pub_deal_3, @publisher
        @syndicated_deal_deleted.mark_as_deleted!
      end

      should "return HTTP 401 Unauthorized when accessed without basic auth provided" do
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response 401
      end

      should "return HTTP 401 Unauthorized when accessed with incorrect basic auth creds" do
        login_with_basic_auth(:login => @user.login, :password => "WRONG")
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response 401
      end

      should "return HTTP 401 Unauthorized when accessed with a locked account" do
        login_with_basic_auth(@user)
        @user.lock_access!
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response 401
      end

      should "return HTTP 200 OK when accessed with correct basic auth creds" do
        login_with_basic_auth(@user)
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response :success
      end

      should "exclude regular, non-syndicated deals" do
        login_with_basic_auth(@user)
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response :success
        assert !assigns(:daily_deals).include?(@non_syndicated_deal)
      end

      should "exclude syndicated deals that have been deleted" do
        login_with_basic_auth(@user)
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response :success
        assert !assigns(:daily_deals).include?(@syndicated_deal_deleted)
      end

      should "return only syndicated deals that haven't been deleted" do
        login_with_basic_auth(@user)
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response :success
        assert_equal [@syndicated_deal_1, @syndicated_deal_2], assigns(:daily_deals).sort_by(&:id)
      end

      should "render the syndicated deals with the index XML template" do
        login_with_basic_auth(@user)
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response :success
        assert_template "daily_deals/index.xml.builder"
      end

      should "render only syndicated deals that haven't been deleted" do
        login_with_basic_auth(@user)
        get :syndicated_daily_deals, :publisher_id => @publisher.to_param, :format => "xml"
        assert_response :success
        xml = Nokogiri::XML @response.body
        assert_equal 2, xml.css("daily_deal").length
        assert_equal [@syndicated_deal_1.id, @syndicated_deal_2.id], xml.css("daily_deal id").map { |e| e.text }.sort.map(&:to_i)
      end

    end

    should "return success on a GET for xml format" do
      get :index, :publisher_id => @publisher.id, :format => "xml"
      assert_response   :success
      assert_template   :daily_deals
      assert_equal "application/xml", @response.content_type
    end

    should "return xml with the expected attributes in the top-level element" do
      root = @doc.xpath("/daily_deals")
      assert_equal @publisher.label, root.attribute("publisher_label").value
    end

    should "return xml with the top-level daily deal elements" do
      assert_equal 3, @doc.xpath("//daily_deals").children.size

      @deal_array.each_with_index do |deal, i|
        n = i+1
        css_selector = "daily_deal:nth-child(#{n})"

        assert_equal deal.id.to_s, @doc.css("#{css_selector} id").first.text
        assert_equal daily_deal_url(deal, :host => deal.publisher.production_daily_deal_host), @doc.css("#{css_selector}  deal_url").text
        assert_equal deal.website_url, @doc.css("#{css_selector}  url").text
        assert_equal deal.listing, @doc.css("#{css_selector} listing").first.text
        assert_equal deal.analytics_category.name, @doc.css("#{css_selector} category").text
        assert_equal deal.value_proposition, @doc.css("#{css_selector}  value_proposition").text
        assert_equal deal.value_proposition_subhead, @doc.css("#{css_selector} value_proposition_subhead").text
        assert_cdata_text(@doc.css("#{css_selector} description"), deal.description)
        assert_cdata_text(@doc.css("#{css_selector} terms"), deal.terms)
        assert_equal deal.short_description, @doc.css("#{css_selector} short_description").text
        assert_cdata_text(@doc.css("#{css_selector} highlights"), deal.highlights)
        assert_cdata_text(@doc.css("#{css_selector} reviews"), deal.reviews)
        assert_equal deal.photo.url, @doc.css("#{css_selector} photo_url").text
        assert_equal deal.value.to_s, @doc.css("#{css_selector} value").text
        assert_equal deal.price.to_s, @doc.css("#{css_selector}  price").text
        assert_equal "2011-06-01T19:30:00Z", @doc.css("#{css_selector} starts_at").text
        assert_equal "2011-06-11T19:30:00Z", @doc.css("#{css_selector} ends_at").text
        assert_equal deal.expires_on.to_s, @doc.css("#{css_selector} expires_on").text
        assert_equal deal.facebook_title_text, @doc.css("#{css_selector} facebook_title_text").text
        assert_equal deal.twitter_status_text, @doc.css("#{css_selector} twitter_status_text").text
        assert_equal deal.featured.to_s, @doc.css("#{css_selector} featured").text
        assert_equal deal.quantity.to_s, @doc.css("#{css_selector} quantity_available").text
        assert_equal deal.min_quantity.to_s, @doc.css("#{css_selector} min_purchase_quantity").text
        assert_equal deal.max_quantity.to_s, @doc.css("#{css_selector} max_purchase_quantity").text
        assert_equal deal.custom_1, @doc.css("#{css_selector} custom_1").text
        assert_equal deal.custom_2, @doc.css("#{css_selector} custom_2").text
        assert_equal deal.custom_3, @doc.css("#{css_selector} custom_3").text
      end
    end

    should "return xml with the merchant fragment" do
      @deal_array.each_with_index do |deal, i|
        n = i+1
        css_selector = "daily_deal:nth-child(#{n}) merchant"
        assert_equal deal.advertiser.listing, @doc.css("#{css_selector} listing").first.text
        assert_equal deal.advertiser.name, @doc.css("#{css_selector} brand_name").first.text
        assert_equal deal.advertiser.logo.url, @doc.css("#{css_selector} logo_url").text
        assert_equal deal.advertiser.website_url, @doc.css("#{css_selector} website_url").text
      end
    end

    should "return xml with multiple locations" do
      assert_equal 2, @doc.css("daily_deals daily_deal:nth-child(1) merchant locations").children.size

      @daily_deal_one.advertiser.stores.each_with_index do |store, i|
        n = i+1
        css_selector = "daily_deals daily_deal:nth-child(1) merchant locations location:nth-child(#{n})"
        assert_equal store.listing, @doc.css("#{css_selector} listing").text
        assert_equal store.address_line_1, @doc.css("#{css_selector} address_line_1").text
        assert_equal store.address_line_2, @doc.css("#{css_selector} address_line_2").text
        assert_equal store.city, @doc.css("#{css_selector} city").text
        assert_equal store.state, @doc.css("#{css_selector} state").text
        assert_equal store.zip, @doc.css("#{css_selector} zip").text
        assert_equal store.latitude.to_s, @doc.css("#{css_selector} latitude").text
        assert_equal store.longitude.to_s, @doc.css("#{css_selector} longitude").text
        assert_equal store.phone_number, @doc.css("#{css_selector} phone_number").text
      end
    end

    should "return xml with markets" do
      assert_equal 2, @doc.css("daily_deals daily_deal:nth-child(1) markets").children.size, @doc

      @daily_deal_one.markets.each_with_index do |market, i|
        n = i+1
        css_selector = "daily_deals daily_deal:nth-child(1) markets market:nth-child(#{n})"
        assert_equal market.id.to_s, @doc.css("#{css_selector} id").text
        assert_equal market.name, @doc.css("#{css_selector} name").text
      end
    end

    should "render empty locations fragment when missing stores" do
      @advertiser.stores.clear
      get :index, :publisher_id => @publisher.id, :format => "xml"
      doc = Nokogiri.parse(@response.body, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
      doc.remove_namespaces!

      assert @advertiser.stores.empty?, "should have no stores"
      assert doc.css("daily_deals daily_deal:nth-child(1) merchant locations").children.empty?, "should have no locations"
    end

    should "render empty markets fragment when missing markets" do
      @daily_deal_one.markets.clear
      get :index, :publisher_id => @publisher.id, :format => "xml"
      doc = Nokogiri.parse(@response.body, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS)
      doc.remove_namespaces!

      assert @daily_deal_one.markets.empty?, "should have no markets"
      assert doc.css("daily_deals daily_deal:nth-child(1) markets").children.empty?, "should have no markets"
    end

  end

  fast_context "daily deal pagination" do

    setup do
      login_as(Factory(:admin))
      @publisher = Factory(:publisher)
      25.times do
        Factory(:side_daily_deal, :publisher => @publisher)
      end
    end

    should "have a publisher with a bunch of deals" do
      assert_equal 25, @publisher.daily_deals.size
    end

    should "get all the deals if request has no pagination parameters" do
      get :index, :publisher_id => @publisher.id, :format => "xml"
      assert_equal 25, assigns(:daily_deals).size
    end

    should "get only some deals if request has pagination parameters" do
      get :index, :publisher_id => @publisher.id, :format => "xml", :page => 1, :per_page => 5
      assert_equal 5, assigns(:daily_deals).size
      assert_equal @publisher.daily_deals.not_deleted.in_order[0,5].map(&:id), assigns(:daily_deals)[0,5].map(&:id)
    end

    should "get zero deals when page is greater than the number of pages available" do
      get :index, :publisher_id => @publisher.id, :format => "xml", :page => 6, :per_page => 5
      assert_response :success
      assert_equal 0, assigns(:daily_deals).size
    end

    should "get zero deals even when the page is way out of bounds" do
      get :index, :publisher_id => @publisher.id, :format => "xml", :page => 1000, :per_page => 5
      assert_response :success
      assert_equal 0, assigns(:daily_deals).size
    end

    should "be able to request page but not specify per_page and get default per page" do
      get :index, :publisher_id => @publisher.id, :format => "xml", :page => 1
      assert_equal 20, assigns(:daily_deals).size
    end

  end

  fast_context "syndicated daily deal pagination" do
    setup do
      admin = Factory(:admin)
      login_with_basic_auth(:login => admin.login, :password => "monkey")
      @publisher = Factory(:publisher)
      source_deal = Factory(:daily_deal_for_syndication)
      25.times do
        Factory(:side_daily_deal, :publisher => @publisher, :source_id => source_deal.id)
      end
      assert_equal 25, @publisher.daily_deals.size
    end

    should "get all the syndicated deals if request has no pagination parameters" do
      get :syndicated_daily_deals, :publisher_id => @publisher.id, :format => "xml"
      assert_equal 25, assigns(:daily_deals).size
    end

    should "get only some syndicated deals if request has pagination parameters" do
      get :syndicated_daily_deals, :publisher_id => @publisher.id, :format => "xml", :page => 1, :per_page => 5
      assert_equal 5, assigns(:daily_deals).size
      assert_equal @publisher.daily_deals.not_deleted.in_order[0,5].map(&:id), assigns(:daily_deals)[0,5].map(&:id)
    end

    should "get zero syndicated deals when page is greater than the number of pages available" do
      get :syndicated_daily_deals, :publisher_id => @publisher.id, :format => "xml", :page => 6, :per_page => 5
      assert_response :success
      assert_equal 0, assigns(:daily_deals).size
    end

    should "get zero syndicated deals even when the page is way out of bounds" do
      get :syndicated_daily_deals, :publisher_id => @publisher.id, :format => "xml", :page => 1000, :per_page => 5
      assert_response :success
      assert_equal 0, assigns(:daily_deals).size
    end

    should "be able to request page but not specify per_page and get default per page" do
      get :syndicated_daily_deals, :publisher_id => @publisher.id, :format => "xml", :page => 1
      assert_equal 20, assigns(:daily_deals).size
    end
  end

  private

  def attributes_for_daily_deal
    {
        :publisher => @publisher,
        :advertiser => @advertiser,
        :analytics_category => @category,
        :value_proposition_subhead => "Value prop subhead one",
        :highlights => "<ul><li>You should do it!</li><li>Doit!</li></ul>",
        :reviews => "<ul><li>Great stuff!</li><li>I loved it!</li></ul>",
        :facebook_title_text => "I'm on Facebook and I'm a deal.",
        :twitter_status_text => "I'm on Twitter and I'm a deal.",
        :custom_1 => "Custom info one",
        :custom_2 => "Custom info two",
        :custom_3 => "Custom info three",
        :start_at => Time.zone.local(2011, 6, 1, 12, 30),
        :hide_at => Time.zone.local(2011, 6, 11, 12, 30)
    }
  end
end

