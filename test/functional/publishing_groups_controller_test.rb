require File.dirname(__FILE__) + "/../test_helper"

class PublishingGroupsControllerTest < ActionController::TestCase

  
  test "edit without admin" do
    get :edit, :id => 999    
    assert_redirected_to "/session/new"
  end
  
  test "edit with admin" do
    publishing_group = publishing_groups(:student_discount_handbook)
    with_admin_user_required(:quentin, :aaron) do
      get :edit, :id => publishing_group.to_param
    end
    
    assert_response   :success
    assert_template   :edit
    assert_layout     :application
    assert_select "input[type='text'][name='publishing_group[number_sold_display_threshold_default]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[advertiser_financial_detail]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[require_federal_tax_id]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[stick_consumer_to_publisher_based_on_zip_code]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[require_login_for_active_daily_deal_feed]']", :count => 1    
    assert_select "input[type='checkbox'][name='publishing_group[self_serve]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[redirect_to_deal_of_the_day_on_market_lookup]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[require_publisher_membership_codes]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[restrict_syndication_to_publishing_group]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[show_daily_deals_on_landing_page]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[allow_consumer_show_action]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[allow_single_sign_on]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[unique_email_across_publishing_group]']", :count => 1
    assert_select "input[type='checkbox'][name='publishing_group[allow_publisher_switch_on_login]']", :count => 1
    assert_select "input[type='text'][name='publishing_group[qr_code_host]']"
    assert_select "input[type='text'][name='publishing_group[apple_app_store_url]']"
    assert_select "select[name='publishing_group[parent_theme]']", 1 do
      assert_select "option[value='howlingwolf']", "howlingwolf"
      assert_select "option[value='roaringlion']", "roaringlion"
      assert_select "option[value='cleverbetta']", "cleverbetta"
    end
    assert_select "input[type='text'][name='publishing_group[yelp_consumer_key]']"
    assert_select "input[type='text'][name='publishing_group[yelp_consumer_secret]']"
    assert_select "input[type='text'][name='publishing_group[yelp_token]']"
    assert_select "input[type='text'][name='publishing_group[yelp_token_secret]']"
    assert_select "input[type='text'][name='publishing_group[silverpop_api_host]']"
    assert_select "input[type='text'][name='publishing_group[silverpop_api_username]']"
    assert_select "input[type='password'][name='publishing_group[silverpop_api_password]']"
    assert_select "input[type='text'][name='publishing_group[silverpop_database_identifier]']"
    assert_select "input[type='text'][name='publishing_group[silverpop_template_identifier]']"
    assert_select "input[type='text'][name='publishing_group[silverpop_seed_template_identifier]']"
    assert_select "select[name='publishing_group[silverpop_account_time_zone]']", true
    assert_select "input[type='checkbox'][name='publishing_group[uses_paychex]']", :count => 1
    assert_select "input[type='text'][name='publishing_group[paychex_initial_payment_percentage]']"
    assert_select "input[type='text'][name='publishing_group[paychex_num_days_after_which_full_payment_released]']"
    assert_select "input[type='checkbox'][name='publishing_group[enable_daily_deal_variations]']"
    assert_select "input[type=checkbox][name='publishing_group[send_litle_campaign]']"
    assert_select "input[type='checkbox'][name='publishing_group[enable_daily_deal_variations]']"
    assert_select "input[type=checkbox][name='publishing_group[allow_non_voucher_deals]']"
    assert_select "input[type=file][name='publishing_group[logo]']", 1
    assert_select "input[type=checkbox][name='publishing_group[enable_force_valid_consumers]']"
  end

  test "offers with wgs84 format" do
    publishing_group = publishing_groups(:student_discount_handbook)
    get :offers, :id => publishing_group.to_param, :format => "wgs84"
    
    assert_response :success
    assert_not_nil assigns(:offers), "should assign offers"    
    assert !@response.body["http://http"], "Should add http protocol and host only once"
  end
  
  test "offers with wgs84 format with houston press" do
    publishing_group = publishing_groups(:vvm)
    houston_press    = publishing_group.publishers.find_by_name("Houston Press")
    advertiser       = houston_press.advertisers.create!(:listing => "mylisting", :name => "My Advertiser")
    advertiser.stores.create!(:phone_number => "111-111-1111", :address_line_1 => "123 Main St", :city => "Houston", :state => "TX", :zip => "66009")
    offer            = advertiser.offers.create!(:message => "my offer")
        
    get :offers, :id => publishing_group.to_param, :format => "wgs84"
    assert_response :success
    assert_not_nil assigns(:offers)
    assert assigns(:offers).include?( offer ), "should include houston press offer's"
   
    root = REXML::Document.new(@response.body).root
    assert_not_nil root
    assert_equal "2.0", root.attributes['version']
    assert_equal "http://www.w3.org/2003/01/geo/wgs84_pos#", root.attributes['xmlns:geo']
    
    channel = root.elements['channel']
    assert_not_nil channel
    assert_equal "Coupons For #{publishing_group.name}", channel.elements['title'].text
    assert_equal @request.url, channel.elements['link'].text
    
    item  = channel.elements['item']
    assert_not_nil item
    
    assert_equal offer.value_proposition, item.elements['title'].text
    assert_equal offer.terms_with_expiration, item.elements['description'].text
    assert_equal offer.advertiser_name, item.elements['store'].text
  end
  
  test "offers with wgs84 format with demo account" do
    publishing_group = publishing_groups(:vvm)
    demo = publishing_group.publishers.create!(:name => "VVM DEMO", :label => "vvm-demo")
    demo_offer = demo.advertisers.create!.offers.create!(:message => "demo offer")
    
    get :offers, :id => publishing_group.to_param, :format => "wgs84"
    assert_response :success
    assert_not_nil assigns(:offers)
    assert !assigns(:offers).include?( demo_offer ), "demo offers should not be included"
  end
  
  test "update" do
    publishing_group = Factory(:publishing_group)
    with_admin_user_required(:quentin, :aaron) do
      put(:update, :id => publishing_group.to_param, :publishing_group => {
        :name => "updated",
        :label => "updated",
        :require_federal_tax_id => true,
        :advertiser_financial_detail => true
      })
    end
    assert_not_nil assigns(:publishing_group)
    assert assigns(:publishing_group).errors.empty?, "@publishing_group should not have errors, but has: #{assigns(:publishing_group).errors.full_messages}"
    assert_redirected_to edit_publishing_group_path(assigns(:publishing_group))
    assert flash[:notice].any?, "Should have flash"
  end
  
  test "about for time warner cable (rr)" do
    publishing_group = Factory(:publishing_group, :label => 'rr')
    get :about_us, :id => publishing_group.label
    assert_theme_layout("rr/layouts/landing_pages")
    assert_template("rr/publishing_groups/about_us")
  end
  
  test "about for time warner cable (rr) with layout set to popup" do
    publishing_group = Factory(:publishing_group, :label => 'rr')
    get :about_us, :id => publishing_group.label, :layout => "popup"
    assert_layout nil
    assert_template("rr/publishing_groups/about_us")
  end
  
  test "terms for time warner cable (rr)" do
    publishing_group = Factory(:publishing_group, :label => 'rr')
    get :terms, :id => publishing_group.label
    assert_theme_layout("rr/layouts/landing_pages")
    assert_template("rr/publishing_groups/terms")
  end
  
  test "terms for time warner cable (rr) with layout set to popup" do
    publishing_group = Factory(:publishing_group, :label => 'rr')
    get :terms, :id => publishing_group.label, :layout => "popup"
    assert_layout nil
    assert_template("rr/publishing_groups/terms")
  end
  
  test "privacy_policy for time warner cable (rr)" do
    publishing_group = Factory(:publishing_group, :label => 'rr')
    get :privacy_policy, :id => publishing_group.label
    assert_theme_layout("rr/layouts/landing_pages")
    assert_template("rr/publishing_groups/privacy_policy")
  end
  
  test "privacy_policy for time warner cable (rr) with layout set to popup" do
    publishing_group = Factory(:publishing_group, :label => 'rr')
    get :privacy_policy, :id => publishing_group.label, :layout => "popup"
    assert_layout nil
    assert_template("rr/publishing_groups/privacy_policy")
  end  
  
  
end
