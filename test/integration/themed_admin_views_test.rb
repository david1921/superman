require File.dirname(__FILE__) + "/../test_helper"

class ThemedAdminViewsTest < ActionController::IntegrationTest
  def setup
    @publishing_group = Factory(:publishing_group, :label => "bespoke", :self_serve => true)
    @publisher = Factory(:publisher, :publishing_group => @publishing_group)
    @advertiser = Factory(:advertiser, :publisher => @publisher)
    @daily_deal = Factory(:daily_deal, :advertiser => @advertiser)
  end

  context "authenticated Bespoke publishing group user" do
    setup do
      @bespoke_admin = Factory(:user_without_company).tap do |user|
        user.user_companies.create(:company => @publishing_group)
      end
      assert_contains @bespoke_admin.reload.companies, @publishing_group

      assert_login(@bespoke_admin.login, "test")
    end

    should "use the publishing group's theme for the admin site" do
      assert_themed_layout_elements
      assert_themed_publishing_group_publishers_index
      assert_themed_advertiser_pages
      assert_themed_daily_deal_pages
    end
  end

  context "authenticated full admin" do
    setup do
      @full_admin = Factory(:admin)
      assert_login(@full_admin.login, "monkey")
    end

    should "use the default layout and templates" do
      assert_unthemed_publishers_index
      assert_unthemed_advertiser_pages
      assert_unthemed_daily_deal_pages
    end
  end


  private

  def assert_themed_publishing_group_publishers_index
    get publishing_group_publishers_path(@publishing_group)
    assert_response :success
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_layout(pub_group_or_pub)
    assert_select "body.#{pub_group_or_pub.label}"
  end

  def assert_themed_advertisers_index
    get publisher_advertisers_path(@publisher)
    assert_response :success
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_advertiser_pages
    assert_themed_advertisers_index
    assert_themed_new_advertiser
    assert_themed_edit_advertiser
    assert_themed_create_advertiser
    assert_themed_update_advertiser
  end

  def assert_themed_new_advertiser
    get new_publisher_advertiser_path(@publisher)
    assert_response :success
    assert_template "edit"
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_edit_advertiser
    get edit_publisher_advertiser_path(@publisher, @advertiser)
    assert_response :success
    assert_template "edit"
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_create_advertiser
    post publisher_advertisers_path(@publisher, :advertiser => {:active_coupon_limit => "invalid"})
    assert_response :success
    assert_template "edit"
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_update_advertiser
    put advertiser_path(@advertiser, :advertiser => {:active_coupon_limit => "invalid"})
    assert_response :success
    assert_template "edit"
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_layout_elements
    get publishing_group_publishers_path(@publishing_group)
    assert_response :success
    assert_themed_layout @publishing_group
    assert_select "title", :text => "Bespoke Offers: Publishers"
    assert_select "header.bespoke" do
      assert_select "img.logo"
    end
    assert_select "#content.bespoke"
    assert_select "footer.bespoke" do
      assert_select "#copyright", :text => "© Barclaycard #{Time.zone.now.year}"
    end
  end

  def assert_login(login, password)
    post session_path, :user => {:login => login, :password => password}
    assert_redirected_to root_path
  end

  def assert_unthemed_layout
    assert_select "body.default"
  end

  def assert_themed_daily_deal_pages
    assert_themed_new_daily_deal
    assert_themed_edit_daily_deal
    assert_themed_create_daily_deal
    assert_themed_update_daily_deal
  end

  def assert_themed_new_daily_deal
    get new_advertiser_daily_deal_path(@advertiser)
    assert_response :success
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_edit_daily_deal
    get edit_advertiser_daily_deal_path(@advertiser, @daily_deal)
    assert_response :success
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_create_daily_deal
    post advertiser_daily_deals_path(@advertiser, :daily_deal => {})
    assert_response :success
    assert_themed_layout(@publishing_group)
  end

  def assert_themed_update_daily_deal
    put advertiser_daily_deal_path(@advertiser, @daily_deal,  :daily_deal => {:price => "not a number"})
    assert_response :success
    assert_template "edit"
    assert_themed_layout(@publishing_group)
  end

  def assert_unthemed_publishers_index
    get publishers_path
    assert_response :success
    assert_template "index"
    assert_unthemed_layout
  end

  def assert_unthemed_advertisers_index(publisher)
    get publisher_advertisers_path(publisher)
    assert_response :success
    assert_template "index"
    assert_unthemed_layout
  end

  def assert_unthemed_advertiser_pages
    assert_unthemed_advertisers_index(@publisher)
    assert_unthemed_new_advertiser(@publisher)
    assert_unthemed_create_advertiser(@publisher)
    assert_unthemed_edit_advertiser(@advertiser)
    assert_unthemed_update_advertiser(@advertiser)
  end

  def assert_unthemed_new_advertiser(publisher)
    get new_publisher_advertiser_path(publisher)
    assert_response :success
    assert_template "edit"
    assert_unthemed_layout
  end

  def assert_unthemed_edit_advertiser(advertiser)
    get edit_publisher_advertiser_path(advertiser.publisher, advertiser)
    assert_response :success
    assert_template "edit"
    assert_unthemed_layout
  end

  def assert_unthemed_create_advertiser(publisher)
    post publisher_advertisers_path(publisher, :advertiser => {:active_coupon_limit => "invalid"})
    assert_response :success
    assert_template "edit"
    assert_unthemed_layout
  end

  def assert_unthemed_update_advertiser(advertiser)
    put advertiser_path(advertiser, :advertiser => {:active_coupon_limit => "invalid"})
    assert_response :success
    assert_template "edit"
    assert_unthemed_layout
  end

  def assert_unthemed_daily_deal_pages
    assert_unthemed_daily_deals_index(@publisher)
    assert_unthemed_new_daily_deal(@advertiser)
    assert_unthemed_edit_daily_deal(@daily_deal)
    assert_unthemed_create_daily_deal(@advertiser)
    assert_unthemed_update_daily_deal(@daily_deal)
  end

  def assert_unthemed_daily_deals_index(publisher)
    get publisher_daily_deals_path(publisher)
    assert_response :success
    assert_template "index"
    assert_unthemed_layout
  end

  def assert_unthemed_new_daily_deal(advertiser)
    get new_advertiser_daily_deal_path(advertiser)
    assert_response :success
    assert_unthemed_layout
  end

  def assert_unthemed_edit_daily_deal(daily_deal)
    get edit_daily_deal_path(daily_deal)
    assert_response :success
    assert_unthemed_layout
  end

  def assert_unthemed_create_daily_deal(advertiser)
    post advertiser_daily_deals_path(advertiser, :daily_deal => {})
    assert_response :success
    assert_unthemed_layout
  end

  def assert_unthemed_update_daily_deal(daily_deal)
    put daily_deal_path(daily_deal,  :daily_deal => {:price => "not a number"})
    assert_response :success
    assert_template "edit"
    assert_unthemed_layout
  end
end
