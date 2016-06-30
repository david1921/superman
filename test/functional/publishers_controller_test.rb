require File.dirname(__FILE__) + "/../test_helper"

class PublishersControllerTest < ActionController::TestCase
  assert_no_angle_brackets :except => [ :test_coupon_ad_page, :test_coupons_page ]
  
  test "index as admin" do
    user = Factory(:admin)
    login_as user
    get :index
    assert_response :success
    assert assigns(:publishers).empty?, "@publishers should be empty without search param"
    assert assigns(:publishing_groups).empty?, "@publishing_groups should be empty without search param"
    assert_nil assigns(:publishing_group), "@publishing_group should be nil"
    [:publishers_path, :admins_path, :consumers_path, :reports_path, :logout_path].each do |path|
      assert_select "a[href=#{send(path)}]"
    end
  end
  test "index as restricted admin" do
    user = Factory(:restricted_admin)
    login_as user
    get :index
    assert_response :success
    [:publishers_path, :consumers_path, :reports_path, :logout_path ].each do |path|
      assert_select "a[href=#{send(path)}]"
    end
    assert_select "a[href=#{admins_path}]", false
  end

  test "index as admin whose account has been locked" do
    user = Factory(:admin)
    login_as user
    user.lock_access!
    get :index
    assert_redirected_to new_session_url
  end
  
  test "index as admin wildcard" do
    Factory(:publisher)
    Factory(:publisher)
    Factory(:publisher)
    
    user = Factory(:admin)
    login_as user
    get :index, :text => "*"
    assert_response :success
    assert_equal Publisher.no_publishing_group.all.map(&:label).sort, assigns(:publishers).map(&:label).sort, "@publishers should include all pubs for '*'"
    assert_equal PublishingGroup.all.sort, assigns(:publishing_groups).sort, "@publishing_groups should include all PublishingGroup for *"
    assert_nil assigns(:publishing_group), "@publishing_group should be nil"
  end
  
  test "index as admin with matching text" do
    publisher = Factory(:publisher, :name => "The Syracuse Herald-Journal")
    user = Factory(:admin)

    login_as user
    get :index, :text => "syr   "
    assert_response :success

    assert_equal [ publisher.label ], assigns(:publishers).map(&:label), "@publishers should match search param"
    assert assigns(:publishing_groups).empty?, "@publishing_groups should be empty without search param"
    assert_nil assigns(:publishing_group), "@publishing_group should be nil"
    
    assert_application_page_title "Publishers"
    
    assert_select "form[action=#{publishers_delete_path}]", 1 do
      assert_select "table.publishers", 1 do
        [ publisher ].each do |publisher|
          assert_select "tr[id=publisher_#{publisher.id}]", 1 do
            assert_select "td.check input[type=checkbox][name='id[]'][value=#{publisher.id}]", 1
            assert_select "td.name", :text => publisher.name, :count => 1
            assert_select "td.advertisers", :text => "Advertisers", :count => 1
            assert_select "td.last a[href=#{edit_publisher_path(publisher)}]", 1
          end
        end
      end
      assert_select "input[type=submit]"
    end
  end
  
  test "index as admin and text matches publishing group" do
    publishing_group = Factory(:publishing_group, :label => "advance-net")
    publisher_1 = Factory(:publisher, :publishing_group => publishing_group)
    publisher_2 = Factory(:publisher, :publishing_group => publishing_group)
    
    user = Factory(:admin)
    login_as user
    get :index, :text => "advance-net"
    assert_response :success
    assert_equal [], assigns(:publishers), "@publishers should not match search param"
    assert_equal [ publishing_group ], assigns(:publishing_groups), "@publishing_groups should match search param"
    assert_nil assigns(:publishing_group), "@publishing_group should be nil"
    
    assert_select "table.publishers", 1 do
      assert_select "tr[id=publisher_#{publisher_1.id}]", 1
      assert_select "tr[id=publisher_#{publisher_2.id}]", 1
    end
  end
  
  test "index as admin should not dupe publishers in response" do
    publishing_group = Factory(:publishing_group, :label => "advance-net")
    name_match = Factory(:publisher, :publishing_group => publishing_group, :name => "KADV")
    label_match = Factory(:publisher, :publishing_group => publishing_group, :label => "advance-1")
    pub_group_match = Factory(:publisher, :publishing_group => publishing_group, :label => "foo")
    no_pub_group = Factory(:publisher, :label => "advance-week")
    
    user = Factory(:admin)
    login_as user
    get :index, :text => "adv"
    assert_response :success
    assert_equal [ no_pub_group.label ], assigns(:publishers).map(&:label), "@publishers"
    assert_equal [ publishing_group ], assigns(:publishing_groups), "@publishing_groups should match search param"
    assert_nil assigns(:publishing_group), "@publishing_group should be nil"
  end
  
  test "index as admin no text match" do
    user = Factory(:admin)
    login_as user
    get :index, :text => "foo bar publisher"
    assert_response :success
    assert assigns(:publishers).empty?, "@publishers should be empty"
    assert assigns(:publishing_groups).empty?, "@publishing_groups should be empty"
    assert_nil assigns(:publishing_group), "@publishing_group should be nil"
  end
  
  test "index as admin no match for empty text" do
    user = Factory(:admin)
    login_as user
    get :index, :text => ""
    assert_response :success
    assert assigns(:publishers).empty?, "@publishers should be empty"
    assert assigns(:publishing_groups).empty?, "@publishing_groups should be empty"
    assert_nil assigns(:publishing_group), "@publishing_group should be nil"
  end
  
  def test_publishing_group_index
    publisher = publishers(:sdh_austin)
    publishing_group = publisher.publishing_group
    publishers = publishing_group.publishers
    
    check = lambda do |role|
      assert_response :success, role
      assert_equal publishers, assigns(:publishers), "@publishers assignment as #{role}"
      assert_application_page_title "Publishers"
    
      assert_select "form[action=#{publishers_delete_path}]", 0
      assert_select "table.publishers", 1 do
        publishers.each do |publisher|
          assert_select "tr[id=publisher_#{publisher.id}]", 1 do
            assert_select "td.check input[type=checkbox][name='id[]'][value=#{publisher.id}]", 0
            assert_select "td.name", :text => publisher.name, :count => 1
            assert_select "td.label", :text => publisher.label, :count => 1
            assert_select "td.users", :text => (publisher.users.count if publisher.users.count > 0), :count => 1
            assert_select "td.advertisers", :text => (publisher.advertisers.count if publisher.advertisers.count > 0), :count => 1
            assert_select "td.last a[href=#{edit_publisher_path(publisher)}]", 0
          end
        end
      end
      assert_select "input[type=submit]", 0
    end
    
    with_self_serve_publishing_group_user_required(publisher, check) do
      get :index, :publishing_group_id => publishing_group.to_param
    end
  end
  
  def test_new
    with_admin_user_required(:quentin, :aaron) do
      get :new
    end
    assert_response :success
    assert_not_nil assigns(:publisher), "@publisher assignment"
    assert_not_nil assigns(:publishing_groups), "@publishing_groups assignment"
    
    assert_select "form#new_publisher[enctype=multipart/form-data]", 1 do
      assert_select "select[name='publisher[publishing_group_id]']", 1 do
        assert_select "option[value='']", "New", 1
        PublishingGroup.all { |group| assert_select "option[value=#{group.id}]", group.name, 1 }
      end
      assert_select "input[name='publisher[name]']", 1 
      assert_select "input[name='publisher[label]']", 1
      assert_select "input[name='publisher[listing]']", 1
      assert_select "input[name='publisher[publishing_group_name]']", 1
      assert_select "input[name='publisher[production_subdomain]']", 1
      assert_select "input[name='publisher[production_host]']", 1
      assert_select "input[name='publisher[production_daily_deal_host]']", 1
      assert_select "input[name='publisher[login_url]']"
      assert_select "input[name='publisher[enable_search_by_publishing_group]']", false
      assert_select "input[name='publisher[place_offers_with_group]']", false
      assert_select "input[name='publisher[place_all_group_offers]']", false
      assert_select "input[type=text][name='publisher[address_line_1]']", 1
      assert_select "input[type=text][name='publisher[address_line_2]']", 1
      assert_select "input[type=text][name='publisher[region]']", true
      assert_select "select[name='publisher[country_id]']", true
      assert_select "select[name='publisher[state]']", true
      assert_select "input[type=text][name='publisher[city]']", 1
      assert_select "input[type=text][name='publisher[zip]']", 1
      assert_select "input[type=text][name='publisher[phone_number]']", 1
      assert_select "input[name='publisher[brand_name]']", 1
      assert_select "input[name='publisher[daily_deal_brand_name]']", 1
      assert_select "input[name='publisher[brand_headline]']", 1
      assert_select "input[name='publisher[brand_txt_header]']", 1 
      assert_select "input[name='publisher[txt_keyword_prefix]']", 1
      assert_select "input[name='publisher[brand_twitter_prefix]']", 1
      assert_select "input[type=file][name='publisher[logo]']", 1
      assert_select "input[type=file][name='publisher[daily_deal_logo]']", 1
      assert_select "input[type=file][name='publisher[paypal_checkout_header_image]']", 1
      assert_select "select[name='publisher[theme]']", 1 do
        assert_select "option[value='simple'][selected='selected']", "Simple"
        assert_select "option[value='standard']", "Standard"
        assert_select "option[value='enhanced']", "Enhanced"
        assert_select "option[value='narrow']", "Narrow"
      end
      assert_select "input[name='publisher[sub_theme]']"
      assert_select "input[name='publisher[coupon_page_url]']"
      assert_select "input[name='publisher[support_email_address]']"
      assert_select "input[name='publisher[sales_email_address]']"
      assert_select "input[name='publisher[support_url]']"
      assert_select "input[name='publisher[approval_email_address]']"
      assert_select "input[name='publisher[subscriber_recipients]']"
      assert_select "input[name='publisher[categories_recipients]']"
      assert_select "input[name='publisher[active_coupon_limit]']"
      assert_select "input[name='publisher[active_txt_coupon_limit]']"
      assert_select "input[name='publisher[bit_ly_login]']", 1
      assert_select "input[name='publisher[bit_ly_api_key]']", 1
      assert_select "input[name='publisher[daily_deal_sharing_message_prefix]']", 1
      assert_select "input[name='publisher[daily_deal_twitter_message_prefix]']", 1
      assert_select "input[type=checkbox][name='publisher[send_intro_txt]']"      
      assert_select "input[type=checkbox][name='publisher[self_serve]']"
      assert_select "input[type=checkbox][name='publisher[advertiser_self_serve]']"
      assert_select "input[type=checkbox][name='publisher[advertiser_has_listing]']"
      assert_select "input[type=checkbox][name='publisher[offer_has_listing]']"
      assert_select "input[type=checkbox][name='publisher[random_coupon_order]']"
      assert_select "input[type=checkbox][name='publisher[subcategories]']"      
      assert_select "input[type=checkbox][name='publisher[search_box]']"
      assert_select "input[type=checkbox][name='publisher[show_zip_code_search_box]']"
      assert_select "input[type=checkbox][name='publisher[show_bottom_pagination]']"      
      assert_select "input[type=checkbox][name='publisher[coupons_home_link]']", false
      assert_select "input[name='publisher[default_offer_search_postal_code]']"
      assert_select "input[name='publisher[default_offer_search_distance]']"
      assert_select "input[type=checkbox][name='publisher[link_to_email]']"            
      assert_select "input[type=checkbox][name='publisher[link_to_map]']"
      assert_select "input[type=checkbox][name='publisher[link_to_website]']"
      assert_select "input[type=checkbox][name='publisher[show_call_button]']", false
      assert_select "input[type=checkbox][name='publisher[show_twitter_button]']"
      assert_select "input[type=checkbox][name='publisher[show_facebook_button]']"
      assert_select "input[type=checkbox][name='publisher[show_small_icons]']"
      assert_select "input[type=checkbox][name='publisher[show_gift_certificate_button]']", false
      assert_select "input[name='publisher[coupon_code_prefix]']"
      assert_select "input[type=checkbox][name='publisher[generate_coupon_code]']"
      assert_select "input[type=checkbox][name='publisher[allow_gift_certificates]']"
      assert_select "input[type=checkbox][name='publisher[allow_daily_deals]']"
      assert_select "input[type=checkbox][name='publisher[enable_daily_deal_voucher_headline]']"
      assert_select "input[type=checkbox][name='publisher[enable_publisher_daily_deal_categories]']"
      assert_select "input[type=checkbox][name='publisher[enable_side_deal_value_proposition_features]']"
      assert_select "input[type=checkbox][name='publisher[enable_offer_headline]']"
      assert_select "input[type=checkbox][name='publisher[enable_paypal_buy_now]']" 
      assert_select "input[type=checkbox][name='publisher[enable_featured_gift_certificate]']"
      assert_select "input[type=checkbox][name='publisher[enable_sweepstakes]']"  
      assert_select "input[type=checkbox][name='publisher[use_production_host_for_facebook_shares]']"
      assert_select "input[type=checkbox][name='publisher[auto_insert_expiration_date]']"
      assert_select "input[type=checkbox][name='publisher[require_daily_deal_short_description]']"
      assert_select "input[type=checkbox][name='publisher[ignore_daily_deal_short_description_size]']"
      assert_select "input[type=checkbox][name='publisher[notify_via_email_on_coupon_changes]']"
      assert_select "input[type=checkbox][name='publisher[allow_discount_codes]']"
      assert_select "input[type=checkbox][name='publisher[allow_admins_to_edit_advertiser_revenue_share_percentage]']"
      assert_select "input[type=checkbox][name='publisher[require_advertiser_revenue_share_percentage]']"
      assert_select "input[type='checkbox'][name='publisher[allow_registration_during_purchase]']"
      assert_select "textarea[name='publisher[gift_certificate_disclaimer]']"
      assert_select "textarea[name='publisher[daily_deal_universal_terms]']"
      assert_select "input[type=checkbox][name='publisher[enable_daily_deal_referral]']"
      assert_select "input[type=checkbox][name='publisher[enable_unlimited_referral_time]']"
      assert_select "input[name='publisher[daily_deal_referral_message_head]']", 1
      assert_select "input[name='publisher[daily_deal_referral_message_body]']", 1
      assert_select "input[name='publisher[daily_deal_referral_credit_amount]']", 1
      assert_select "textarea[name='publisher[account_sign_up_message]']"
      assert_select "input[type=text][name='publisher[daily_deal_referral_message]']"
      assert_select "select[name='publisher[email_blast_hour]']", 1
      assert_select "select[name='publisher[email_blast_minute]']", 1
      assert_select "input[type=text][name='publisher[market_name]']"
      assert_select "input[type=checkbox][name='publisher[offers_available_for_syndication]']"
      assert_select "input[type=checkbox][name='publisher[allow_secondary_daily_deal_photo]']"
      assert_select "input[type=text][name='publisher[federal_tax_id]']"
      assert_select "input[type=text][name='publisher[started_at]']"
      assert_select "input[type=text][name='publisher[launched_at]']"
      assert_select "input[type=text][name='publisher[terminated_at]']"
    end
  end

  def test_delete_without_daily_deals
    publishers = [Factory(:publisher), Factory(:publisher)]

    assert_difference 'Publisher.count', -publishers.size do
      login_as Factory(:admin)
      post :delete, "delete.x" => "39", "delete.y" => "15", "action" => "delete", "id" => publishers.map(&:to_param)
    end

    publishers.each do |publisher|
      assert_nil Publisher.find_by_id(publisher.id), "#{publisher.name} should no longer exist" 
    end
  end

  def test_delete_with_daily_deal
    publisher_with_daily_deal = Factory :publisher
    daily_deal = Factory :daily_deal, :publisher => publisher_with_daily_deal

    publisher_without_daily_deal_1 = Factory :publisher
    publisher_without_daily_deal_2 = Factory :publisher

    publishers = [publisher_with_daily_deal, publisher_without_daily_deal_1, publisher_without_daily_deal_2]

    login_as Factory(:admin)

    assert_difference 'Publisher.count', -2 do
      post :delete, "delete.x" => "39", "delete.y" => "15", "action" => "delete", "id" => publishers.map(&:to_param)
    end

    assert_equal "Deleted 2 publishers.", flash[:notice]

    assert_not_nil Publisher.find_by_id(publisher_with_daily_deal.id)
    assert_nil Publisher.find_by_id(publisher_without_daily_deal_1.id)
    assert_nil Publisher.find_by_id(publisher_without_daily_deal_2.id)
  end

  def test_coupon_ad
    get :coupon_ad, :label => publishers(:my_space).label
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
  end
  
  def test_coupon_ad_page
    get :coupon_ad_page, :label => publishers(:my_space).label
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
  end
  
  def test_embed_coupon_ad
    get :embed_coupon_ad, :label => publishers(:my_space).label, :format => :js
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
  end
  
  def test_coupons_page
    get :coupons_page, :label => publishers(:my_space).label
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
  end
  
  def test_embed_coupons
    get :embed_coupons, :label => publishers(:my_space).label, :format => :js
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
    assert_match public_offers_url(publishers(:my_space), :path_only => false, :host => "sb1.analoganalytics.com"), @response.body
  end
  
  def test_embed_coupons_with_page_size
    get :embed_coupons, :label => publishers(:my_space).label, :page_size => 6, :format => :js
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
    url = public_offers_url(publishers(:my_space), :path_only => false, :host => "sb1.analoganalytics.com", :layout => "iframe", :page_size => 6)
    assert_match CGI.escapeHTML(url), @response.body
  end
  
  def test_embed_coupons_with_page_and_iframe_size
    get :embed_coupons, :label => publishers(:my_space).label, :page_size => 6, :iframe_width => 400, :iframe_height => 800, :format => :js
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
    assert_match "http://sb1.analoganalytics.com/publishers/#{publishers(:my_space).id}/offers?iframe_height=800&amp;iframe_width=400&amp;layout=iframe&amp;page_size=6", @response.body
  end
  
  def test_embed_coupons_with_text_and_category_id
    category_id = categories(:restaurants).to_param
    get :embed_coupons, :label => publishers(:my_space).label, :text => "mexican", :category_id => category_id, :format => :js
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
    assert_match "http://sb1.analoganalytics.com/publishers/#{publishers(:my_space).id}/offers?category_id=#{category_id}&amp;layout=iframe&amp;page_size=4&amp;text=mexican", @response.body
  end
  
  def test_embed_coupons_with_page_and_iframe_size_with_standard_layout
    publisher = publishers(:my_space)
    publisher.update_attribute :theme, "standard"
    get :embed_coupons, :label => publisher.label, :page_size => 6, :iframe_width => "", :iframe_height => "", :format => :js
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
  end
  
  def test_embed_coupons_with_page_and_iframe_size_with_sdcitybeat_layout
    publisher = publishers(:my_space)
    publisher.update_attribute :theme, "sdcitybeat"
    get :embed_coupons, :label => publisher.label, :page_size => 6, :iframe_width => "", :iframe_height => "", :format => :js
    assert_response :success
    assert_equal publishers(:my_space), assigns(:publisher), "@publisher"
    assert_layout nil
  end
  
  def test_embed_coupons_not_found
    get :embed_coupons, :label => "foobar", :format => :js
    assert_response :not_found
  end
  
  def test_embed_coupon_ad_not_found
    get :embed_coupon_ad, :label => "foodbar", :format => :js
    assert_response :not_found
  end
  
  def test_index_coupons_without_page_size
    publisher = publishers(:my_space)
    get :index_coupons, :label => publisher.label
    assert_redirected_to public_offers_path(publisher, :page_size => 4, :iframe_width => 936, :iframe_height => 750)
  end
  
  def test_index_coupons_with_page_size
    publisher = publishers(:my_space)
    get :index_coupons, :label => publisher.label, :page_size => 2
    assert_redirected_to public_offers_path(publisher, :page_size => 2, :iframe_width => 936, :iframe_height => 446)
  end
  
  def test_index_coupons_with_invalid_label
    assert_raises ActiveRecord::RecordNotFound do
      get :index_coupons, :label => "nosuchpublisher"
    end
  end
  
  def test_create_with_uk_address
    uk = Country::UK
    with_admin_user_required(:quentin, :aaron) do
      post(:create, :publisher => { 
                     :name => "Thomsonlocal.com Directories",
                     :label => "thomsonlocal",
                     :address_line_1 => "Thomson House",
                     :address_line_2 => "296 Farnborough Road",
                     :city => "Farnborough",
                     :region => "Hants",
                     :zip => "GU14 7NU",
                     :phone_number => "01252 555 555",
                     :country_id => uk.id,
                     :federal_tax_id => "12-12121212"
                     })
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}" if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert flash[:notice].present?, "Should have flash"
    assert_nil publisher.publishing_group, "Should not have a publishing group"
    assert_equal uk, publisher.country
    assert_equal "Hants", publisher.region
    assert_equal nil, publisher.state
  end
  
  def test_update_with_uk_address
    uk = Country::UK
    publisher = Factory(:publisher_with_uk_address)
    with_admin_user_required(:quentin, :aaron) do
      put(:update, :id => publisher.to_param, :publisher => {
        :address_line_1 => "296 Farnborough Road",
        :address_line_2 => nil,
        :zip => "GU24 7NU",
        :phone_number => "01252 666 555",
      })
    end
    publisher = assigns(:publisher)
    assert publisher.errors.empty?, "@publisher should not have errors, but has: #{publisher.errors.full_messages}" if publisher
    assert_redirected_to edit_publisher_path(assigns(:publisher))
    assert flash[:notice].present?, "Should have flash"
    assert_nil publisher.publishing_group, "Should not have a publishing group"
    assert_equal uk, publisher.country
    assert_equal "Hants", publisher.region
    assert_equal nil, publisher.state
    assert_equal "GU24 7NU", publisher.zip
    assert_equal "4401252666555", publisher.phone_number
  end
  
  context "publishers controller api actions" do

    setup do
      Time.stubs(:now).returns(Time.parse("Jan 01, 2011 01:00:00 UTC"))
      @publisher = Factory(:publisher, {
        :label => "nytimes",
        :name => "NY Times",
        :phone_number => "212-555-1212",
        :support_url => "http://support.nytimes.com/",
        :support_email_address => "support@nytimes.com"
      })
    end
    
    should "return failure for show.json if the API-Version request header is missing" do
      get :show, :id => @publisher.label, :format => "json"
      assert_response :not_acceptable
      assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
      assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
    end
  
    should "return failure for show.json if the API-Version request header is wrong" do
      @request.env['API-Version'] = "9.9.9"
      get :show, :id => @publisher.label, :format => "json"
      assert_response :not_acceptable
      assert_equal Api::Versioning::VALID_API_VERSIONS.last, @response.headers["API-Version"]
      assert_equal [{ "API-Version" => "is not valid" }], ActiveSupport::JSON.decode(@response.body)
    end
  
    should "have correct JSON response for show.json (v 1.0.0)" do
      @request.env['API-Version'] = "1.0.0"
      get :show, :id => @publisher.label, :format => 'json'
      assert_response :success
      assert_equal "1.0.0", @response.headers["API-Version"]
    end

    should "have correct JSON response for show.json (v 2.1.0)" do
      @request.env['API-Version'] = "2.1.0"
      get :show, :id => @publisher.label, :format => 'json'
      assert_response :success
      assert_equal "2.1.0", @response.headers["API-Version"]
      
      json = JSON.parse(@response.body)
      assert_equal "FNDG.ME", json["qr_code_host"]
    end
  end

  test "generate_qa_data" do
    publisher = Factory :publisher

    assert_difference 'publisher.advertisers.count', 1 do
      assert_difference 'publisher.daily_deals.count', 3 do
        login_as Factory(:admin)
        post :generate_qa_data, :id => publisher.id
      end
    end

    assert_redirected_to publisher_daily_deals_url(publisher.id)
  end

end
