require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::EmailTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  context "#email" do
    setup do
      @publisher = Publisher.last || Factory(:publisher)
      @advertiser = @publisher.advertisers.last || Factory(:advertiser, :publisher => @publisher)

      @now = Time.parse("2012-02-07T09:00:00-0800")
      Timecop.freeze(@now) do
        @featured_now = Factory(:daily_deal, :advertiser => @advertiser,
                               :start_at => Time.zone.now, :hide_at => 2.days.from_now,
                               :side_start_at => 20.hours.from_now, :side_end_at => 2.days.from_now)
        @featured_tomorrow = Factory(:featured_daily_deal, :advertiser => @advertiser,
                                     :start_at => @featured_now.side_start_at, :hide_at => @featured_now.hide_at + 2.days)
      end
    end

    context "tomorrow => true" do
      setup do
        Timecop.freeze(@now) do
          @active_tomorrow = Factory(:side_daily_deal, :advertiser => @advertiser,
                                    :start_at => @featured_tomorrow.start_at - 1.hour, :hide_at => @featured_tomorrow.hide_at)
        end
      end

      should "render the deal featured 24 hours from now" do
        Timecop.freeze(@now) do
          get :email, :label => @publisher.label, :tomorrow => "1"
          assert_equal assigns(:daily_deal), @featured_tomorrow, "Expected deal #{@featured_tomorrow.id}, was deal #{assigns(:daily_deal).id}"
        end
      end
    end

    context "next => true" do
      setup do
        Timecop.freeze(@now) do
          @featured_next = @featured_tomorrow
          @featured_after_next = Factory(:featured_daily_deal, :advertiser => @advertiser,
                                     :start_at => @featured_next.hide_at, :hide_at => @featured_next.hide_at + 1.day)
        end
      end

      should "render the next featured deal" do
        Timecop.freeze(@now) do
          get :email, :label => @publisher.label, :next => "1"
          assert_equal assigns(:daily_deal), @featured_next, "Expected deal #{@featured_next.id}, was deal #{assigns(:daily_deal).id}"
        end
      end
    end
  end

  test "email" do
    advertiser = advertisers(:changos)
    daily_deal = advertiser.daily_deals.create!(get_valid_attributes.merge(:start_at => Time.zone.now - 1.hour))

    publisher = publishers(:sdh_austin)
    get :email, :label => publisher.label
    assert_response :success
    assert_layout nil
    assert_no_match(/href=("|')*\//, @response.body, "All hrefs in email should include host, but found href='/")
    assert_no_match(/src=("|')*\//, @response.body, "All srcs in email should include host, but found src='/")
  end

  test "email rss" do
    daily_deal = Factory :daily_deal
    get :email, :label => daily_deal.publisher.label, :format => "rss"
    assert_response :success
    assert_layout nil
    assert_template 'daily_deals/email.rss.builder'
  end

  test "email with next param should only show featured deals" do
    daily_deal = Factory(:side_daily_deal, :start_at => 5.days.from_now, :hide_at => 7.days.from_now)
    assert_raise ActiveRecord::RecordNotFound do
      get :email, :label => daily_deal.publisher.label, :next => true
    end
  end

  test "email should be ignored by newrelic" do
    daily_deal = Factory :daily_deal
    get :email, :label => daily_deal.publisher.label
    assert_equal({:only => [:email]}, @controller.class.instance_variable_get("@do_not_trace"))
  end

  test "8newsnow email" do
    publisher = Factory(:publisher, :label => "8newsnow")
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)

    get :email, :label => "8newsnow"
    assert_response :success
    assert_layout nil
    assert_no_match(/href=("|')*\//, @response.body, "All hrefs in email should include host, but found href='/")
    assert_no_match(/src=("|')*\//, @response.body, "All srcs in email should include host, but found src='/")
  end

  test "lang email" do
    publishing_group = Factory(:publishing_group, :label => "lang")
    publisher = Factory(:publisher, :name => "LA Daily News", :label => "dailynews", :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)

    get :email, :label => publisher.label
    assert_response :success
    assert_layout nil
    assert_template "themes/lang/daily_deals/email"

    assert_select "title", "$30.00 for only $15.00!"
    assert_no_match(/href=("|')*\//, @response.body, "All hrefs in email should include host, but found href='/")
    assert_no_match(/src=("|')*\//, @response.body, "All srcs in email should include host, but found src='/")
  end

  test "ocregister email" do
    publishing_group = Factory(:publishing_group, :name => "Freedom", :label => "freedom")
    publisher = Factory(:publisher, :name => "OC Register", :label => "ocregister", :publishing_group => publishing_group)
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

    get :email, :label => publisher.label
    assert_response :success
    assert_layout nil
    assert_template "themes/freedom/daily_deals/email"
    assert_no_match(/href=("|')*\//, @response.body, "All hrefs in email should include host, but found href='/")
    assert_no_match(/src=("|')*\//, @response.body, "All srcs in email should include host, but found src='/")
  end

  test "newsday html email" do
    publisher = Factory(:publisher, :name => "Newsday", :label => "newsday")
    advertiser = publisher.advertisers.create!(:name => "Advertiser")
    daily_deal = advertiser.daily_deals.create!(
        :price => 39,
        :value => 80,
        :description => "awesome deal",
        :short_description => "awesome deal email subject!",
        :terms => "GPL",
        :value_proposition => "buy now",
        :start_at => 1.day.ago,
        :hide_at => 3.days.from_now
    )

    get :email, :label => publisher.label, :format => "html"
    assert_response :success
    assert_layout nil
    assert_template "themes/newsday/daily_deals/email"
    assert_match %r|<!-- Subject: awesome deal email subject! -->|, @response.body
    assert_match %r|<!-- From: "Newsday daily deal" -->|, @response.body
  end

  test "newsday text email" do
    publisher = Factory(:publisher, :name => "Newsday", :label => "newsday")
    advertiser = publisher.advertisers.create!(:name => "Awesome Advertiser")
    daily_deal = advertiser.daily_deals.create!(
        :price => 39,
        :value => 80,
        :description => "awesome deal",
        :short_description => "awesome deal email subject!",
        :terms => "GPL",
        :value_proposition => "$5 for $1000 worth of awesomeness",
        :start_at => 1.day.ago,
        :hide_at => 3.days.from_now
    )

    get :email, :label => publisher.label, :format => "txt"
    assert_response :success
    assert_layout nil
    assert_template "themes/newsday/daily_deals/email.text.plain"
    assert_match %r|Subject: awesome deal email subject!|, @response.body
    assert_match %r|From: "Newsday daily deal"|, @response.body
    assert_match %r|Today\'s deal:\n\$5 for \$1000 worth of awesomeness|, @response.body
    assert_match %r|Offered by:\nAwesome Advertiser|, @response.body
  end

  test "novadog email" do
    publisher = Factory(:publisher, :label => "novadog", :production_daily_deal_host => "localhost")
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)

    get :email, :label => publisher.label

    assert_response :success
    assert_layout nil
    assert_select "a#email-buy-now" do
      assert_select "[href=?]", /.*#{publisher_daily_deal_url(publisher.label, daily_deal, :host => publisher.production_daily_deal_host)}.*/
      assert_select "[href=?]", /.*referral_code=email.*/
      assert_select "[href=?]", /.*utm_source.*/
      assert_select "[href=?]", /.*utm_medium.*/
      assert_select "[href=?]", /.*utm_campaign.*/
    end
  end

  test "Check email parameters for google analytics" do
    publabels = ["localdealsandmore"]
    publabels.each do |publabel|
      publisher = Factory(:publisher, :label => publabel, :production_daily_deal_host => "localhost")
      advertiser = Factory(:advertiser, :publisher => publisher)
      daily_deal = Factory(:daily_deal, :advertiser => advertiser)
      get :email, :label => publisher.label
      assert_response :success
      assert_layout nil
      assert_select "a#buy_now_button" do
        assert_select "[href=?]", /.*utm_source.*/
        assert_select "[href=?]", /.*utm_medium.*/
        assert_select "[href=?]", /.*utm_campaign.*/
      end
    end
  end

  test "email no current or previous deal" do
    publisher = Factory(:publisher, :label => "ocregister")
    assert_raise ActiveRecord::RecordNotFound do
      get :email, :label => publisher.label
    end
  end

  test "Use Liquid template for email" do
    # In reality, "entercomnew" is a PublishingGroup
    publisher = Factory(:publisher, :label => "entercomnew")
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)

    get :email, :label => "entercomnew"
    assert_response :success
    assert_layout nil
    assert_no_match(/href=("|')*\//, @response.body, "All hrefs in email should include host, but found href='/")
    assert_no_match(/src=("|')*\//, @response.body, "All srcs in email should include host, but found src='/")
    assert_template "entercomnew/daily_deals/email"
    assert_match daily_deal.value_proposition, @response.body, "Should evaluate Liquid"
  end

  test "Use publishing group Liquid template" do
    publishing_group = Factory(:publishing_group, :label => "entercomnew")
    publisher = Factory(:publisher, :publishing_group => publishing_group)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)

    get :email, :label => daily_deal.publisher.label
    assert_response :success
    assert_layout nil
    assert_no_match(/href=("|')*\//, @response.body, "All hrefs in email should include host, but found href='/")
    assert_no_match(/src=("|')*\//, @response.body, "All srcs in email should include host, but found src='/")
    assert_template "entercomnew/daily_deals/email"
    assert_match daily_deal.value_proposition, @response.body, "Should evaluate Liquid"
  end


  def get_valid_attributes
    {
        :value_proposition => "$25 value for $12.99",
        :description => "This is a daily deal. Enjoy!",
        :terms => "These are the terms. Obey!",
        :quantity => 100,
        :min_quantity => 1,
        :price => 12.99,
        :value => 25.00,
        :start_at => 10.days.ago,
        :hide_at => Time.zone.now.tomorrow,
        :upcoming => true,
        :account_executive => "Bob Mann"
    }
  end

end
