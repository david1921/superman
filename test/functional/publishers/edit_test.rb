require File.dirname(__FILE__) + "/../../test_helper"

class PublishersController::EditTest < ActionController::TestCase
  tests PublishersController

  def test_edit_with_simple_layout
    publisher = publishers(:my_space)
    publisher.update_attribute(:theme, "simple")
    publisher.update_attribute(:enable_fraud_detection, true)
    with_admin_user_required(:quentin, :aaron) do
      get(:edit, :id => publisher.to_param)
    end
    assert_response(:success)
    assert_not_nil(assigns(:publisher), "assigns(:publisher)")
    assert_not_nil assigns(:publishing_groups), "@publishing_groups assignment"

    assert_equal("simple", publisher.theme)
    assert_select "form#edit_publisher_#{publisher.id}[enctype=multipart/form-data]", 1 do
      assert_select "input[type=checkbox][name='publisher[enable_fraud_detection]']"
      assert_select "select[name='publisher[publishing_group_id]']", 1 do
        assert_select "option[value='']", "New", 1
        PublishingGroup.all { |group| assert_select "option[value=#{group.id}]", group.name, 1 }
      end
      assert_select "input[name='publisher[listing]']", 1
      assert_select "input[name='publisher[publishing_group_name]']", 1
      assert_select "input[type=checkbox][name='publisher[used_exclusively_for_testing]']", 1
      assert_select "input[name='publisher[production_subdomain]']", 1
      assert_select "input[name='publisher[production_host]']", 1
      assert_select "input[name='publisher[production_daily_deal_host]']", 1
      assert_select "input[name='publisher[qr_code_host]']"
      assert_select "input[name='publisher[login_url]']"
      assert_select "input[name='publisher[apple_app_store_url]']"
      assert_select "input[name='publisher[enable_search_by_publishing_group]']", false
      assert_select "input[name='publisher[place_offers_with_group]']", false
      assert_select "input[name='publisher[place_all_group_offers]']", false
      assert_select "input[type=text][name='publisher[address_line_1]']", 1
      assert_select "input[type=text][name='publisher[address_line_2]']", 1
      assert_select "input[type=text][name='publisher[city]']", 1
      assert_select "input[type=text][name='publisher[region]']", true
      assert_select "select[name='publisher[country_id]']", true
      assert_select "select[name='publisher[state]']", true
      assert_select "select[name='publisher[time_zone]']", true
      assert_select "input[type=text][name='publisher[zip]']", 1
      assert_select "input[type=text][name='publisher[phone_number]']", 1
      assert_select "input[type=text][name='publisher[support_phone_number]']", 1
      assert_select "input[name='publisher[brand_name]']", 1
      assert_select "input[name='publisher[daily_deal_brand_name]']", 1
      assert_select "input[name='publisher[brand_headline]']", 1
      assert_select "input[name='publisher[brand_txt_header]']", 1
      assert_select "input[name='publisher[brand_twitter_prefix]']", 1
      assert_select "input[name='publisher[google_analytics_account_ids]']", 1
      assert_select "input[type=file][name='publisher[logo]']", 1
      assert_select "input[type=file][name='publisher[daily_deal_logo]']", 1
      assert_select "input[type=file][name='publisher[paypal_checkout_header_image]']", 1
      assert_select "input[name='publisher[txt_keyword_prefix]']", 1
    end
    assert_select "select[name='publisher[theme]']", 1 do
      assert_select "option[value='simple'][selected='selected']", "Simple"
      assert_select "option[value='standard']", "Standard"
      assert_select "option[value='enhanced']", "Enhanced"
      assert_select "option[value='narrow']", "Narrow"
    end
    assert_select "input[name='publisher[sub_theme]']"
    assert_select "select[name='publisher[coupon_border_type]']", 1 do
      assert_select "option[value='solid'][selected='selected']", "solid"
      assert_select "option[value='dotted']", "dotted"
      assert_select "option[value='dashed']", "dashed"
    end
    assert_select "select[name='publisher[payment_method]']", 1 do
      assert_select "option[value='credit']", "Braintree - Credit Card"
      assert_select "option[value='paypal'][selected='selected']", "PayPal"
      assert_select "option[value='optimal']", "Optimal - Credit Card"
    end
    assert_select "input[name='publisher[coupon_page_url]']"
    assert_select "input[name='publisher[support_email_address]']"
    assert_select "input[name='publisher[sales_email_address]']"
    assert_select "input[name='publisher[suggested_daily_deal_email_address]']"
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
    assert_select "input[type=checkbox][name='publisher[enable_sales_agent_id_for_advertisers]']"
    assert_select "input[type=checkbox][name='publisher[offer_has_listing]']"
    assert_select "input[type=checkbox][name='publisher[random_coupon_order]']"
    assert_select "input[type=checkbox][name='publisher[subcategories]']"
    assert_select "input[type=checkbox][name='publisher[search_box]']"
    assert_select "input[type=checkbox][name='publisher[show_zip_code_search_box]']"
    assert_select "input[type=checkbox][name='publisher[show_bottom_pagination]']"
    assert_select "input[type=checkbox][name='publisher[coupons_home_link]']", false
    assert_select "input[type=checkbox][name='publisher[random_coupon_order]']"
    assert_select "input[name='publisher[default_offer_search_postal_code]']"
    assert_select "input[name='publisher[default_offer_search_distance]']"
    assert_select "input[type=checkbox][name='publisher[link_to_email]']"
    assert_select "input[type=checkbox][name='publisher[link_to_map]']"
    assert_select "input[type=checkbox][name='publisher[link_to_website]']"
    assert_select "input[type=checkbox][name='publisher[show_phone_number]']"
    assert_select "input[type=checkbox][name='publisher[show_call_button]']", false
    assert_select "input[type=checkbox][name='publisher[show_twitter_button]']"
    assert_select "input[type=checkbox][name='publisher[show_facebook_button]']"
    assert_select "input[type=checkbox][name='publisher[show_small_icons]']"
    assert_select "input[type=checkbox][name='publisher[show_gift_certificate_button]']", false
    assert_select "input[name='publisher[coupon_code_prefix]']"
    assert_select "input[type=checkbox][name='publisher[generate_coupon_code]']"
    assert_select "input[type=checkbox][name='publisher[allow_gift_certificates]']"
    assert_select "input[type=checkbox][name='publisher[allow_daily_deals]']"
    assert_select "input[type=checkbox][name='publisher[enable_daily_deal_statuses]']"
    assert_select "input[type=checkbox][name='publisher[enable_daily_deal_variations]']"
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
    assert_select "input[type=checkbox][name='publisher[allow_consumer_show_action]']"
    assert_select "input[type=checkbox][name='publisher[can_preview_daily_deal_certificates]']"
    assert_select "textarea[name='publisher[gift_certificate_disclaimer]']"
    assert_select "textarea[name='publisher[daily_deal_universal_terms]']"
    assert_select "input[type=checkbox][name='publisher[enable_daily_deal_referral]']"
    assert_select "input[type=checkbox][name='publisher[enable_unlimited_referral_time]']"
    assert_select "input[name='publisher[daily_deal_referral_message_head]']", 1
    assert_select "input[name='publisher[daily_deal_referral_message_body]']", 1
    assert_select "input[name='publisher[daily_deal_referral_credit_amount]']", 1
    assert_select "select[name='publisher[email_blast_hour]']", 1
    assert_select "select[name='publisher[email_blast_minute]']", 1
    assert_select "select[name='publisher[email_blast_day_of_week]']", 1
    assert_select "input[name='publisher[weekly_email_blast_scheduling_window_start_in_hours]']", 1
    assert_select "input[type=text][name='publisher[market_name]']"
    assert_select "input[type=text][name='publisher[number_sold_display_threshold_default]']", 1
    assert_select "input[type=checkbox][name='publisher[in_syndication_network]']"
    assert_select "input[type=checkbox][name='publisher[in_travelsavers_syndication_network]']"
    assert_select "input[type=checkbox][name='publisher[daily_deals_available_for_syndication_by_default_override]']"
    assert_select "input[name='publisher[enable_daily_deal_yelp_reviews]']"
    assert_select "input[name='publisher[yelp_consumer_key]']"
    assert_select "input[name='publisher[yelp_consumer_secret]']"
    assert_select "input[name='publisher[yelp_token]']"
    assert_select "input[name='publisher[yelp_token_secret]']"
    assert_select "input[name='publisher[silverpop_list_identifier]']"
    assert_select "input[name='publisher[silverpop_template_identifier]']"
    assert_select "input[name='publisher[silverpop_seed_database_identifier]']"
    assert_select "input[name='publisher[silverpop_seed_template_identifier]']"

    assert_select "input[type=text][name='publisher[federal_tax_id]']"
    assert_select "input[type=text][name='publisher[started_at]']"
    assert_select "input[type=text][name='publisher[launched_at]']"
    assert_select "input[type=text][name='publisher[terminated_at]']"

    assert_select "input[type=checkbox][name='publisher[send_weekly_email_blast_to_contact_list]']"
    assert_select "input[type=checkbox][name='publisher[send_weekly_email_blast_to_seed_list]']"

    assert_select "input[type=checkbox][name='publisher[allow_daily_deal_disclaimer]']"
    assert_select "input[type=checkbox][name='publisher[uses_daily_deal_subscribers_presignup]']"
    assert_select "input[type=checkbox][name='publisher[shopping_mall]']"
    assert_select "input[type=checkbox][name='publisher[send_litle_campaign]']"
    assert_select "select[name='publisher[parent_theme]']", 1 do
      Publisher.ready_made_theme_names.each do |theme|
        assert_select "option[value='#{theme}']", theme
      end
    end

    assert_select "div.related" do
      assert_select "h3", "Syndication Preferences"
      assert_select "a[href=#{edit_publisher_syndication_preferences_path(publisher.to_param)}]", :content => 'Edit'
    end
    
    assert_select "div.related" do
      assert_select "h3", "Fraud Risks"
      assert_select "p", :text => "No transactions appear to be fraud risks"
    end

    assert_select "input[type=checkbox][name='publisher[enable_advertiser_statuses]']"
  end

  def test_edit_with_standard_layout
    publisher = publishers(:sdreader)
    publisher.update_attribute(:theme, 'standard')
    with_admin_user_required(:quentin, :aaron) do
      get(:edit, :id => publisher.to_param)
    end

    assert_response(:success)
    assert_not_nil(assigns(:publisher), "assigns(:publisher)")
    assert_not_nil assigns(:publishing_groups), "@publishing_groups assignment"

    assert_select "form#edit_publisher_#{publisher.id}[enctype=multipart/form-data]", 1 do
      assert_select "select[name='publisher[publishing_group_id]']", 1 do
        assert_select "option[value='']", "New", 1
        PublishingGroup.all { |group| assert_select "option[value=#{group.id}]", group.name, 1 }
      end
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
      assert_select "input[type=text][name='publisher[city]']", 1
      assert_select "input[type=text][name='publisher[region]']", true
      assert_select "select[name='publisher[country_id]']", true
      assert_select "input[type=text][name='publisher[region]']", true
      assert_select "select[name='publisher[country_id]']", true
      assert_select "select[name='publisher[state]']", true
      assert_select "input[type=text][name='publisher[zip]']", 1
      assert_select "input[type=text][name='publisher[phone_number]']", 1
      assert_select "input[name='publisher[brand_name]']", 1
      assert_select "input[name='publisher[daily_deal_brand_name]']", 1
      assert_select "input[name='publisher[brand_headline]']", 1
      assert_select "input[name='publisher[brand_txt_header]']", 1
      assert_select "input[type=file][name='publisher[logo]']", 1
      assert_select "input[type=file][name='publisher[daily_deal_logo]']", 1
      assert_select "input[type=file][name='publisher[paypal_checkout_header_image]']", 1
      assert_select "input[name='publisher[brand_twitter_prefix]']", 1
      assert_select "input[name='publisher[google_analytics_account_ids]']", 1
    end
    assert_select "select[name='publisher[theme]']", 1 do
      assert_select "option[value='simple']", "Simple"
      assert_select "option[value='standard'][selected='selected']", "Standard"
      assert_select "option[value='enhanced']", "Enhanced"
      assert_select "option[value='narrow']", "Narrow"
    end
    assert_select "input[name='publisher[sub_theme]']"
    assert_select "select[name='publisher[coupon_border_type]']", false
    assert_select "select[name='publisher[payment_method]']", 1 do
      assert_select "option[value='credit']", "Braintree - Credit Card"
      assert_select "option[value='paypal'][selected='selected']", "PayPal"
      assert_select "option[value='optimal']", "Optimal - Credit Card"
    end
    assert_select "input[name='publisher[coupon_page_url]']"
    assert_select "input[name='publisher[support_email_address]']"
    assert_select "input[name='publisher[sales_email_address]']"
    assert_select "input[name='publisher[suggested_daily_deal_email_address]']"
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
    assert_select "input[type=checkbox][name='publisher[show_special_deal]']"
    assert_select "input[type=checkbox][name='publisher[require_billing_address]']", 1
    assert_select "input[type=checkbox][name='publisher[send_intro_txt]']"
    assert_select "input[type=checkbox][name='publisher[self_serve]']"
    assert_select "input[type=checkbox][name='publisher[advertiser_self_serve]']"
    assert_select "input[type=checkbox][name='publisher[enable_sales_agent_id_for_advertisers]']"
    assert_select "input[type=checkbox][name='publisher[random_coupon_order]']"
    assert_select "input[type=checkbox][name='publisher[subcategories]']"
    assert_select "input[type=checkbox][name='publisher[search_box]']"
    assert_select "input[type=checkbox][name='publisher[show_zip_code_search_box]']"
    assert_select "input[type=checkbox][name='publisher[show_bottom_pagination]']", false
    assert_select "input[type=checkbox][name='publisher[coupons_home_link]']"
    assert_select "input[type=checkbox][name='publisher[random_coupon_order]']"
    assert_select "input[name='publisher[default_offer_search_postal_code]']"
    assert_select "input[name='publisher[default_offer_search_distance]']"
    assert_select "input[type=checkbox][name='publisher[link_to_email]']"
    assert_select "input[type=checkbox][name='publisher[link_to_map]']"
    assert_select "input[type=checkbox][name='publisher[link_to_website]']"
    assert_select "input[type=checkbox][name='publisher[show_phone_number]']", false
    assert_select "input[type=checkbox][name='publisher[show_call_button]']"
    assert_select "input[type=checkbox][name='publisher[show_twitter_button]']"
    assert_select "input[type=checkbox][name='publisher[show_facebook_button]']"
    assert_select "input[type=checkbox][name='publisher[show_small_icons]']", false
    assert_select "input[type=checkbox][name='publisher[show_gift_certificate_button]']"
    assert_select "input[name='publisher[coupon_code_prefix]']"
    assert_select "input[type=checkbox][name='publisher[generate_coupon_code]']"
    assert_select "input[type=checkbox][name='publisher[allow_gift_certificates]']"
    assert_select "input[type=checkbox][name='publisher[allow_daily_deals]']"
    assert_select "input[type=checkbox][name='publisher[enable_daily_deal_statuses]']"
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
    assert_select "textarea[name='publisher[gift_certificate_disclaimer]']"
    assert_select "textarea[name='publisher[daily_deal_universal_terms]']"
    assert_select "input[name='publisher[daily_deal_referral_credit_amount]']", 1
    assert_select "input[type=checkbox][name='publisher[enable_daily_deal_referral]']"
    assert_select "input[type=checkbox][name='publisher[enable_unlimited_referral_time]']"
    assert_select "input[name='publisher[daily_deal_referral_message_head]']", 1
    assert_select "input[name='publisher[daily_deal_referral_message_body]']", 1
    assert_select "input[name='publisher[daily_deal_referral_credit_amount]']", 1
    assert_select "select[name='publisher[email_blast_hour]']", 1
    assert_select "select[name='publisher[email_blast_minute]']", 1
    assert_select "select[name='publisher[email_blast_day_of_week]']", 1
    assert_select "input[name='publisher[enable_daily_deal_yelp_reviews]']"
    assert_select "input[name='publisher[yelp_consumer_key]']"
    assert_select "input[name='publisher[yelp_consumer_secret]']"
    assert_select "input[name='publisher[yelp_token]']"
    assert_select "input[name='publisher[yelp_token_secret]']"
    assert_select "input[type=checkbox][name='publisher[allow_daily_deal_disclaimer]']"
    assert_select "input[type=checkbox][name='publisher[uses_daily_deal_subscribers_presignup]']"
    assert_select "input[type=checkbox][name='publisher[send_litle_campaign]']"
  end

  def test_edit_with_publisher_in_publishing_group
    publishing_group = PublishingGroup.create!(:name => "My Publishing Group")
    publisher = publishers(:sdreader)
    publisher.update_attributes(:theme => 'standard', :publishing_group => publishing_group)
    with_admin_user_required(:quentin, :aaron) do
      get(:edit, :id => publisher.to_param)
    end

    assert_response(:success)
    assert_not_nil(assigns(:publisher), "assigns(:publisher)")
    assert_not_nil assigns(:publishing_groups), "@publishing_groups assignment"

    assert_select "form#edit_publisher_#{publisher.id}[enctype=multipart/form-data]", 1 do
      assert_select "select[name='publisher[publishing_group_id]']", 1 do
        assert_select "option[value='']", "New", 1
        PublishingGroup.all { |group| assert_select "option[value=#{group.id}]", group.name, 1 }
      end
      assert_select "input[name='publisher[publishing_group_name]']", 1
      assert_select "input[name='publisher[production_subdomain]']", 1
      assert_select "input[name='publisher[production_host]']", 1
      assert_select "input[name='publisher[production_daily_deal_host]']", 1
      assert_select "input[name='publisher[login_url]']"
      assert_select "input[name='publisher[enable_search_by_publishing_group]']", true
      assert_select "input[name='publisher[place_offers_with_group]']", true
      assert_select "input[name='publisher[place_all_group_offers]']", true
      assert_select "input[type=text][name='publisher[address_line_1]']", 1
      assert_select "input[type=text][name='publisher[address_line_2]']", 1
      assert_select "input[type=text][name='publisher[city]']", 1
      assert_select "input[type=text][name='publisher[region]']", true
      assert_select "select[name='publisher[country_id]']", true
      assert_select "select[name='publisher[state]']", true
      assert_select "input[type=text][name='publisher[zip]']", 1
      assert_select "input[type=text][name='publisher[phone_number]']", 1
      assert_select "input[name='publisher[brand_name]']", 1
      assert_select "input[name='publisher[daily_deal_brand_name]']", 1
      assert_select "input[name='publisher[brand_headline]']", 1
      assert_select "input[name='publisher[brand_txt_header]']", 1
      assert_select "input[type=file][name='publisher[logo]']", 1
      assert_select "input[type=file][name='publisher[daily_deal_logo]']", 1
      assert_select "input[type=file][name='publisher[paypal_checkout_header_image]']", 1
      assert_select "input[name='publisher[brand_twitter_prefix]']", 1
      assert_select "input[name='publisher[google_analytics_account_ids]']", 1
    end
    assert_select "select[name='publisher[theme]']", 1 do
      assert_select "option[value='simple']", "Simple"
      assert_select "option[value='standard'][selected='selected']", "Standard"
      assert_select "option[value='enhanced']", "Enhanced"
      assert_select "option[value='narrow']", "Narrow"
    end
    assert_select "input[name='publisher[sub_theme]']"
    assert_select "select[name='publisher[coupon_border_type]']", false
    assert_select "select[name='publisher[payment_method]']", 1 do
      assert_select "option[value='credit']", "Braintree - Credit Card"
      assert_select "option[value='paypal'][selected='selected']", "PayPal"
      assert_select "option[value='optimal']", "Optimal - Credit Card"
    end
    assert_select "input[name='publisher[coupon_page_url]']"
    assert_select "input[name='publisher[support_email_address]']"
    assert_select "input[name='publisher[sales_email_address]']"
    assert_select "input[name='publisher[suggested_daily_deal_email_address]']"
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
    assert_select "input[type=checkbox][name='publisher[enable_sales_agent_id_for_advertisers]']"
    assert_select "input[type=checkbox][name='publisher[random_coupon_order]']"
    assert_select "input[type=checkbox][name='publisher[subcategories]']"
    assert_select "input[type=checkbox][name='publisher[search_box]']"
    assert_select "input[type=checkbox][name='publisher[show_zip_code_search_box]']"
    assert_select "input[type=checkbox][name='publisher[show_bottom_pagination]']", false
    assert_select "input[type=checkbox][name='publisher[coupons_home_link]']"
    assert_select "input[type=checkbox][name='publisher[random_coupon_order]']"
    assert_select "input[type=checkbox][name='publisher[enable_loyalty_program_for_new_deals]']"
    assert_select "input[type=text][name='publisher[referrals_required_for_loyalty_credit_for_new_deals]']"
    assert_select "input[name='publisher[default_offer_search_postal_code]']"
    assert_select "input[name='publisher[default_offer_search_distance]']"
    assert_select "input[type=checkbox][name='publisher[link_to_email]']"
    assert_select "input[type=checkbox][name='publisher[link_to_map]']"
    assert_select "input[type=checkbox][name='publisher[link_to_website]']"
    assert_select "input[type=checkbox][name='publisher[show_phone_number]']", false
    assert_select "input[type=checkbox][name='publisher[show_call_button]']"
    assert_select "input[type=checkbox][name='publisher[show_twitter_button]']"
    assert_select "input[type=checkbox][name='publisher[show_facebook_button]']"
    assert_select "input[type=checkbox][name='publisher[show_small_icons]']", false
    assert_select "input[type=checkbox][name='publisher[show_gift_certificate_button]']"
    assert_select "input[name='publisher[coupon_code_prefix]']"
    assert_select "input[type=checkbox][name='publisher[generate_coupon_code]']"
    assert_select "input[type=checkbox][name='publisher[allow_gift_certificates]']"
    assert_select "input[type=checkbox][name='publisher[allow_daily_deals]']"
    assert_select "input[type=checkbox][name='publisher[enable_daily_deal_statuses]']"
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
    assert_select "textarea[name='publisher[gift_certificate_disclaimer]']"
    assert_select "textarea[name='publisher[daily_deal_universal_terms]']"
    assert_select "input[name='publisher[daily_deal_referral_credit_amount]']", 1
    assert_select "input[type=checkbox][name='publisher[enable_daily_deal_referral]']"
    assert_select "input[type=checkbox][name='publisher[enable_unlimited_referral_time]']"
    assert_select "input[name='publisher[daily_deal_referral_message_head]']", 1
    assert_select "input[name='publisher[daily_deal_referral_message_body]']", 1
    assert_select "input[name='publisher[daily_deal_referral_credit_amount]']", 1
    assert_select "select[name='publisher[email_blast_hour]']", 1
    assert_select "select[name='publisher[email_blast_minute]']", 1
    assert_select "select[name='publisher[email_blast_day_of_week]']", 1
    assert_select "input[name='publisher[enable_daily_deal_yelp_reviews]']"
    assert_select "input[name='publisher[yelp_consumer_key]']"
    assert_select "input[name='publisher[yelp_consumer_secret]']"
    assert_select "input[name='publisher[yelp_token]']"
    assert_select "input[name='publisher[yelp_token_secret]']"
    assert_select "input[type=checkbox][name='publisher[allow_daily_deal_disclaimer]']"
    assert_select "input[type=checkbox][name='publisher[uses_daily_deal_subscribers_presignup]']"
    assert_select "input[type=checkbox][name='publisher[send_litle_campaign]']"
  end

  test "edit with USD publisher and discount codes displayed" do
    admin_user = Factory :admin
    @controller.stubs(:current_user).returns(admin_user)
    publisher = Factory :publisher, :currency_code => "USD"
    discount = Factory :discount, :publisher_id => publisher.id, :amount => "42"
    get :edit, :id => publisher.id

    assert_response :success
    assert_select "div.discount p.credit", :text => "$42.00", :count => 1
  end

  test "edit with GBP publisher and discount codes displayed" do
    admin_user = Factory :admin
    @controller.stubs(:current_user).returns(admin_user)
    publisher = Factory :publisher, :currency_code => "GBP"
    discount = Factory :discount, :publisher_id => publisher.id, :amount => "31"
    get :edit, :id => publisher.id

    assert_response :success
    assert_select "div.discount p.credit", :text => "£31.00", :count => 1
  end

  test "can't get to publisher edit page if not admin" do
    login_as Factory(:user)
    get :edit, :id => Factory(:publisher).id
    assert_response :redirect
  end
  
  test "edit when there are suspected frauds" do
    login_as Factory(:admin)
    publisher = Factory(:publisher, :enable_fraud_detection => true)
    daily_deal = Factory :daily_deal, :publisher => publisher
    p1 = Factory :captured_daily_deal_purchase, :daily_deal => daily_deal
    p2 = Factory :captured_daily_deal_purchase, :daily_deal => daily_deal
    p3 = Factory :voided_daily_deal_purchase, :daily_deal => daily_deal
    p4 = Factory :refunded_daily_deal_purchase, :daily_deal => daily_deal
    Factory :suspected_fraud, :suspect_daily_deal_purchase => p1, :matched_daily_deal_purchase => p2
    Factory :suspected_fraud, :suspect_daily_deal_purchase => p3, :matched_daily_deal_purchase => p4
    
    get :edit, :id => publisher.to_param
    assert_response :success
    assert_select "div.related" do
      assert_select "h3", "Fraud Risks"
      assert_select "a", "1 suspected fraud"
    end
  end
  
  test "edit when Publisher#enable_fraud_detection? is false" do
    login_as Factory(:admin)
    publisher = Factory :publisher, :enable_fraud_detection => false
    get :edit, :id => publisher.to_param
    assert_response :success
    assert_select "h3", :text => "Fraud Risks", :count => 0
  end
  
end
