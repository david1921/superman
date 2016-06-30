require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::EditTest < ActionController::TestCase
  tests DailyDealsController
  include DailyDealHelper

  context "edit with daily deal categories" do
    setup do
      @default_category = Factory(:daily_deal_category, :name => "Default Category")

      @publisher = Factory(:publisher)
      @publisher_category = Factory(:daily_deal_category, :name => "Publisher Category", :publisher_id => @publisher.id)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    context "without the publisher being enabled for publisher daily deal categories" do
      setup do
        login_as Factory(:admin)
        get :edit, :id => @daily_deal
      end

      should "render just the analytics categories" do
        assert_select "select[name='daily_deal[analytics_category_id]']" do
          assert_select "option[value='#{@default_category.id}']", :text => @default_category.name_with_abbreviation
        end
        assert_select "select[name='daily_deal[publishers_category_id]']", false
      end
    end

    context "with the publisher being enabled for publisher daily deal categories" do
      setup do
        @publisher.update_attributes(:enable_publisher_daily_deal_categories => true)
        login_as Factory(:admin)
        get :edit, :id => @daily_deal
      end

      should "render just the analytics categories" do
        assert_select "select[name='daily_deal[analytics_category_id]']" do
          assert_select "option[value='#{@default_category.id}']", :text => @default_category.name_with_abbreviation
        end
        assert_select "select[name='daily_deal[publishers_category_id]']" do
          assert_select "option[value='#{@publisher_category.id}']", :text => @publisher_category.name_with_abbreviation
        end
      end

      should "render a checkbox for featured_in_category" do
        assert_select "input[type='checkbox'][name='daily_deal[featured_in_category]']", true
      end

    end

    context "with the publisher not enabled for publisher daily deal categories" do
      setup do
        @publisher.update_attributes(:enable_publisher_daily_deal_categories => false)
        login_as Factory(:admin)
        get :edit, :id => @daily_deal
      end

      should "not render a checkbox for featured_in_category" do
        assert_select "input[type='checkbox'][name='daily_deal[featured_in_category]']", false
      end
    end

  end

  context "edit" do
    setup do
      @daily_deal = Factory(:daily_deal_for_syndication,
                            :photo_file_name => "standard.png",
                            :photo_content_type => "image/png",
                            :photo_file_size => 164576,
                            :business_fine_print => nil)
      @advertiser = @daily_deal.advertiser
      @admin = Factory(:admin)
    end

    context "business_fine_print" do

      context "as admin user" do

        setup do
          login_as @admin
          get :edit, :id => @daily_deal.to_param
        end

        should "display Distributor Gross Revenue Commission Percent when not yet populated in the db" do
          assert_select "textarea[name='daily_deal[business_fine_print]']", :text => "Distributor Gross Revenue Commission Percent"
        end

      end

      context "as account user" do

        setup do
          login_as Factory(:accountant)
          get :edit, :id => @daily_deal.to_param
        end

        should "display Distributor Gross Revenue Commission Percent when not yet populated in the db" do
          assert_select "textarea[name='daily_deal[business_fine_print]']", :text => "Distributor Gross Revenue Commission Percent"
        end

      end

      context "as normal user" do

        setup do
          @advertiser.publisher.update_attributes(:advertiser_self_serve => true)
          login_as Factory(:user, :company => @advertiser)
          get :edit, :id => @daily_deal.to_param
        end

        should "display Distributor Gross Revenue Commission Percent when not yet populated in the db and field should be disabled" do
          assert_select "textarea[name='daily_deal[business_fine_print]'][disabled='disabled']", :text => "Distributor Gross Revenue Commission Percent"
        end

        should "not display source_channel field" do
          assert_select "select[name='daily_deal[source_channel]']", false
        end

      end


    end

    # fields related to syndication can be found in # edit_with_syndication_test.rb
    should "display standard edit fields" do
      login_as @admin
      get :edit, :id => @daily_deal.to_param

      assert_response :success
      assert_template :edit
      assert_layout :application

      assert_select "input[type='text'][name='daily_deal[value_proposition]']"
      assert_select "input[type='text'][name='daily_deal[side_deal_value_proposition]']", false
      assert_select "input[type='text'][name='daily_deal[side_deal_value_proposition_subhead]']", false
      assert_select "textarea[name='daily_deal[description]']"
      assert_select "input[type='text'][name='daily_deal[price]']"
      assert_select ".last_edited", :count => 0
      assert_select "input[type='text'][name='daily_deal[value]']"
      assert_select "input[type='text'][name='daily_deal[min_quantity]']"
      assert_select "input[type='text'][name='daily_deal[max_quantity]']"
      assert_select "input[type='text'][name='daily_deal[quantity]']"
      assert_select "textarea[name='daily_deal[highlights]']"
      assert_select "textarea[name='daily_deal[terms]']"
      assert_select "textarea[name='daily_deal[reviews]']"
      assert_select "textarea[name='daily_deal[voucher_steps]']", :text => @daily_deal.publisher.default_voucher_steps(@daily_deal.advertiser.name)
      assert_select "textarea[name='daily_deal[business_fine_print]']"
      assert_select "textarea[name='daily_deal[facebook_title_text]']"
      assert_select "textarea[name='daily_deal[twitter_status_text]']"
      assert_select "textarea[name='daily_deal[short_description]']"
      assert_select "img[src='http://s3.amazonaws.com/photos.daily-deals.analoganalytics.com/test/#{@daily_deal.id}/standard.png']", :count => 1
      assert_select "input[name='daily_deal[photo]'][style='display: none']", :count => 1
      assert_select "a[href=?]", "#", :text => "Delete Photo", :count => 1
      assert_select "input[name='daily_deal[start_at]']"
      assert_select "input[name='daily_deal[hide_at]']"
      assert_select "input[name='daily_deal[expires_on]']"
      assert_select "input[name='daily_deal[tipping_point]']", :count => 0
      assert_select "input[name='daily_deal[advertiser_revenue_share_percentage]']"
      assert_select "input[name='daily_deal[affiliate_revenue_share_percentage]']"
      assert_select "input[name='daily_deal[affiliate_url]']", :minimum=>0, :maximum=>1
      assert_select "input[type='text'][name='daily_deal[account_executive]']"
      assert_select "input[name='daily_deal[listing]']"
      assert_select "input[type=checkbox][name='daily_deal[enable_daily_email_blast]']"
      assert_select "input[type=checkbox][name='daily_deal[location_required]']"
      assert_select "input[type='file'][name='daily_deal[bar_codes_csv]']"
      assert_select "input[type=checkbox][name='daily_deal[allow_duplicate_bar_codes]']"
      assert_select "input[type=checkbox][name='daily_deal[delete_existing_unassigned_bar_codes]']"
      assert_select "input[type=checkbox][name='daily_deal[hide_serial_number_if_bar_code_is_present]']"
      assert_select "input[type=checkbox][name='daily_deal[national_deal]']"
      assert_select "select[name='daily_deal[bar_code_encoding_format]']"
      assert_select "textarea[name='daily_deal[email_voucher_redemption_message]']", :text => "Please bring your printed voucher and valid photo ID when you go to redeem your deal at #{@daily_deal.try(:advertiser).try :name}."
      assert_select "input[type='text'][name='daily_deal[custom_1]']"
      assert_select "input[type='text'][name='daily_deal[custom_2]']"
      assert_select "input[type='text'][name='daily_deal[custom_3]']"
      assert_select "select[name='daily_deal[email_voucher_offer_id]']"
      assert_select "input[type=checkbox][name='daily_deal[requires_shipping_address]']"
      assert_select "input[type='text'][name='daily_deal[shipping_address_message]']"
      assert_select "input[type='text'][name='daily_deal[number_sold_display_threshold]']", 1
      assert_select "input[type=checkbox][name='daily_deal[enable_loyalty_program]']"
      assert_select "input[type=text][name='daily_deal[referrals_required_for_loyalty_credit]']"
      assert_select "input[type=checkbox][name='daily_deal[shopping_mall]']", 0
      assert_select "select[name='daily_deal[certificates_to_generate_per_unit_quantity]']"
      assert_select "select[name='daily_deal[status]']", false
      assert_select "select[name='daily_deal[source_channel]']", true, "should display source_channel select for admin user"
    end

    should "display status select when publisher is enabled" do
      # NOTE: this is a temporary addition to make sure it only shows
      # for bespoke.  When we actually move to using the status field
      # we can remove the :enable_daily_deal_statuses from the publisher
      publisher = Factory(:publisher, :enable_daily_deal_statuses => true)
      daily_deal = Factory(:daily_deal, :publisher => publisher)
      login_as @admin
      get :edit, :id => daily_deal.to_param

      assert_response :success
      assert_template :edit

      assert_select "select[name='daily_deal[status]']", true
    end

    should "display shopping mall checkbox if pub uses shopping mall" do
      publisher = Factory(:publisher, :shopping_mall => true)
      daily_deal = Factory(:daily_deal, :publisher => publisher)
      login_as @admin
      get :edit, :id => daily_deal.to_param

      assert_response :success
      assert_template :edit

      assert_select "input[type=checkbox][name='daily_deal[shopping_mall]']", 1
    end

    should "display market label and fields for a publisher with markets" do
      @market = Factory.create(:market, :publisher => @daily_deal.publisher)
      @daily_deal.markets << @market
      login_as @admin
      get :edit, :id => @daily_deal.to_param
      assert_select "input[type=checkbox][name='daily_deal[market_ids][]']"
      assert_select "label[for='daily_deal_market_ids']", "Markets:", :count => 1
    end

    should "disable the quantity field when this deal has barcodes associated with it" do
      deal = Factory :daily_deal
      deal.bar_codes_csv = StringIO.new("foo\nbar")
      deal.save!
      login_as @admin
      get :edit, :id => deal.to_param

      assert_response :success
      assert_select "input[name='daily_deal[quantity]'][disabled=disabled]"
      assert_select "select[name='daily_deal[certificates_to_generate_per_unit_quantity]'][disabled=disabled]"
    end

    should "disable the certificates_to_generate_per_unit_quantity field on syndicated deals" do
      publisher = Factory :publisher
      deal = Factory :daily_deal, :available_for_syndication => true
      syndicated_deal = syndicate(deal, publisher)
      login_as @admin
      get :edit, :id => syndicated_deal.to_param
      assert_response :success
      assert_select "select[name='daily_deal[certificates_to_generate_per_unit_quantity]'][disabled=disabled]"
    end

    should "disable the certificates_to_generate_per_unit_quantity once a purchase has been made" do
      purchase = Factory :daily_deal_purchase
      login_as @admin
      get :edit, :id => purchase.daily_deal.to_param
      assert_response :success
      assert_select "select[name='daily_deal[certificates_to_generate_per_unit_quantity]'][disabled=disabled]"
    end

    should "not display market label or fields for a publisher without markets" do
      login_as @admin
      get :edit, :id => @daily_deal.to_param
      assert_select "input[type=checkbox][name='daily_deal[market_ids][]']", :count => 0
      assert_select "label[for='daily_deal_market_ids']", :count => 0
    end


    should "disable requires_shipping_address checkbox for normal user" do
      publisher = Factory(:publisher, :advertiser_self_serve => true)
      advertiser = Factory(:advertiser, :publisher => publisher)
      normal_user = Factory(:user, :company => advertiser)
      deal = Factory(:daily_deal, :advertiser => advertiser)
      assert !normal_user.has_admin_privilege?
      login_as normal_user
      get :edit, :id => deal.to_param
      assert_response :success
      assert_select "input[type=checkbox][name='daily_deal[requires_shipping_address]'][disabled='disabled']"
    end

    should "display side_deal_value_proposition fields if enable_side_deal_value_proposition_features is set to true on publisher" do
      login_as @admin
      @daily_deal.publisher.update_attribute(:enable_side_deal_value_proposition_features, true)
      get :edit, :id => @daily_deal.to_param
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert_select "input[type='text'][name='daily_deal[value_proposition]']"
      assert_select "input[type='text'][name='daily_deal[side_deal_value_proposition]']"
      assert_select "input[type='text'][name='daily_deal[side_deal_value_proposition_subhead]']"
    end

    should "display voucher_headline for publisher that have enabled daily deal voucher headline" do
      login_as @admin
      @daily_deal.publisher.update_attribute(:enable_daily_deal_voucher_headline, true)
      get :edit, :id => @daily_deal.to_param
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert_select "input[type='text'][name='daily_deal[voucher_headline]']"
    end

    context "email voucher offer select input and options" do
      setup do
        login_as @admin
      end

      should "have a blank option" do
        get :edit, :id => @daily_deal
        assert_select "select[name='daily_deal[email_voucher_offer_id]']" do
          assert_select "option[value='']", :text => ''
        end
      end

      context "with some unexpired offers" do
        setup do
          # Ensure some offers exist
          if (@offers = @daily_deal.publisher.offers.unexpired).empty? || @offers.size < 3
            (3 - @offers.size).times { Factory(:offer, :advertiser => @daily_deal.advertiser, :expires_on => 10.days.from_now) }
          end
        end

        should "have unexpired offers for the advertiser" do
          get :edit, :id => @daily_deal
          assert_select "select[name='daily_deal[email_voucher_offer_id]']" do
            @daily_deal.publisher.offers.unexpired.each do |offer|
              assert_select "option[value='#{offer.id}']", :text => Rack::Utils.escape_html(email_voucher_offer_option_text(offer))
            end
          end
        end

        context "with an associated email voucher offer" do
          setup do
            @daily_deal.email_voucher_offer = @offers.first
            @daily_deal.save!
          end

          should "have the current offer selected" do
            get :edit, :id => @daily_deal
            assert_select "select[name='daily_deal[email_voucher_offer_id]']" do
              assert_select "option[value='#{@daily_deal.email_voucher_offer_id}'][selected]"
            end
          end
        end

        context "with an associated email voucher offer that is expired" do
          setup do
            @daily_deal.email_voucher_offer = Factory(:offer, :advertiser => @daily_deal.advertiser, :expires_on => 1.day.ago)
            @daily_deal.save!
          end

          should "have the current offer and it should be selected" do
            get :edit, :id => @daily_deal
            assert_select "select[name='daily_deal[email_voucher_offer_id]']" do
              assert_select "option[value='#{@daily_deal.email_voucher_offer_id}'][selected]"
            end
          end
        end
      end
    end

    should "show 'available_for_syndication' when publisher is in the syndication network" do
      publisher = Factory(:publisher, :in_syndication_network => true)
      advertiser = Factory(:advertiser, :publisher => publisher)
      daily_deal = Factory(:daily_deal, :advertiser => advertiser)
      login_as @admin
      get :edit, :id => daily_deal.to_param
      assert_response :success
      assert_select "input[type=checkbox][name='daily_deal[available_for_syndication]']"
    end

    context "yelp business id" do
      setup do
        login_as @admin
      end

      context "given yelp credentials present and yelp reviews are enabled" do
        setup do
        end

        should "show yelp business id field" do
          publisher = Factory(:publisher_with_yelp_credentials, :enable_daily_deal_yelp_reviews => true)
          @daily_deal.update_attributes(:publisher => publisher)
          get :edit, :id => @daily_deal.to_param
          assert_select "input[type='text'][name='daily_deal[yelp_api_business_id]']", 1
        end
      end

      context "given yelp credentials not present but yelp reviews are enabled" do
        should "not show yelp business id field" do
          @daily_deal.update_attributes(:publisher => @publisher)
          @daily_deal.publisher.update_attributes(:enable_daily_deal_yelp_reviews => true)
          get :edit, :id => @daily_deal.to_param
          assert_select "input[type='text'][name='daily_deal[yelp_api_business_id]']", 0
        end
      end

      context "given yelp credentials present but yelp reviews are not enabled" do
        should "not show yelp business id field" do
          publisher = Factory(:publisher_with_yelp_credentials, :enable_daily_deal_yelp_reviews => false)
          @daily_deal.update_attributes(:publisher => publisher)
          get :edit, :id => @daily_deal.to_param
          assert_select "input[type='text'][name='daily_deal[yelp_api_business_id]']", 0
        end
      end
    end

    context "allow_non_voucher_deals" do
      setup do
        login_as @admin
      end

      should "show non_voucher_deal field when allow_non_voucher_deals is true" do
        @daily_deal.publisher.publishing_group.update_attributes(:allow_non_voucher_deals => true)
        get :edit, :id => @daily_deal.to_param
        assert_select "input[type=checkbox][name='daily_deal[non_voucher_deal]']"
        assert_select "textarea[name='daily_deal[redemption_page_description]']"
      end

      should "not show non_voucher_deal field when allow_non_voucher_deals is false" do
        @daily_deal.publisher.publishing_group.update_attributes(:allow_non_voucher_deals => false)
        get :edit, :id => @daily_deal.to_param
        assert_select "input[type=checkbox][name='daily_deal[non_voucher_deal]']", false
        assert_select "textarea[name='daily_deal[redemption_page_description]']", false
      end
    end
  end

  context "editing a daily deal whose publisher is in the Eastern time zone" do
    setup do
      save_current_time_zone
      Time.zone = nil
      setup_deal_with_publisher_in_time_zone
      get :edit, :advertiser_id => @advertiser.id, :id => @daily_deal.to_param
    end

    should respond_with :success

    should "display the daily deal times in the publisher's time zone" do
      assert_select "input#daily_deal_start_at[value=June 14, 2010 03:00 AM]"
      assert_select "input#daily_deal_hide_at[value=June 14, 2010 10:00 PM]"
      assert_select "input#daily_deal_expires_on[value=December 31, 2010]"
    end

    should "display the time zone beside each of the editable date/time fields" do
      %w(start_at hide_at expires_on).each do |s|
        assert_select "div##{s}_help", :text => "Eastern Time (US &amp; Canada)"
      end
    end

    teardown do
      restore_saved_time_zone
    end
  end

  context "deal editing and daily deal categories for NYDN" do
    setup do
      @nydn = Factory :publisher, :label => "nydailynews"
      @nydn_advertiser = Factory :advertiser, :publisher_id => @nydn.id
      Factory(:daily_deal_category, :name => "foo")
      @category = Factory(:daily_deal_category)
      @nydn_daily_deal = Factory :daily_deal, :advertiser_id => @nydn_advertiser.id, :analytics_category => @category

      @admin_user = Factory(:admin)
      @controller.stubs(:current_user).returns(@admin_user)
    end

    should "show a dropdown widget to select a daily deal category" do
      get :edit, :advertiser_id => @nydn_advertiser.to_param, :id => @nydn_daily_deal.to_param
      assert_response :success
      assert_select "select#daily_deal_analytics_category_id"
      assert_select "select#daily_deal_analytics_category_id option", 3
      assert_select "select#daily_deal_analytics_category_id option[selected=selected]", :count => 1, :text => @category.name_with_abbreviation
    end
  end

  context "deal editing and daily deal categories for a publisher other than NYDN" do
    setup do
      @other_pub = Factory :publisher, :label => "otherpub"
      @other_pub_advertiser = Factory :advertiser, :publisher_id => @other_pub.id
      @other_pub_daily_deal = Factory :daily_deal, :advertiser_id => @other_pub_advertiser.id

      @admin_user = Factory(:admin)
      @controller.stubs(:current_user).returns(@admin_user)
    end

    should "NOT show a dropdown widget to select a daily deal category" do
      get :edit, :advertiser_id => @other_pub_advertiser.to_param, :id => @other_pub_daily_deal.to_param
      assert_response :success
      assert_select "select#daily_deal_category", 0
    end

  end

  context "disclaimer" do
    setup do
      @advertiser = advertisers(:changos)
      @daily_deal = Factory(:daily_deal, :advertiser => @advertiser)
    end

    context "given allow_daily_deal_disclaimer is true" do
      setup do
        @advertiser.publisher.update_attribute(:allow_daily_deal_disclaimer, true)
      end

      should "show disclaimer field" do
        check_response = lambda do |role|
          assert_select "textarea[name='daily_deal[disclaimer]']"
        end
        with_login_managing_advertiser_required(@advertiser, check_response) do
          get :edit, :id => @daily_deal.id
        end
      end
    end

    context "given allow_daily_deal_disclaimer is false" do
      setup do
        @advertiser.publisher.update_attribute(:allow_daily_deal_disclaimer, false)
      end

      should "not show disclaimer field" do
        check_response = lambda do |role|
          assert_select "textarea[name='daily_deal[disclaimer]']", 0
        end
        with_login_managing_advertiser_required(@advertiser, check_response) do
          get :edit, :id => @daily_deal.id
        end
      end
    end
  end

  context "show_on_landing_page" do
    setup do
      @advertiser = advertisers(:changos)
      @daily_deal = Factory(:daily_deal, :advertiser => @advertiser)
    end

    context "given show_daily_deals_on_landing_page is true" do
      setup do
        @advertiser.publisher.publishing_group.update_attribute(:show_daily_deals_on_landing_page, true)
      end

      should "show disclaimer field" do
        check_response = lambda do |role|
          assert_select "input[name='daily_deal[show_on_landing_page]']"
        end
        with_login_managing_advertiser_required(@advertiser, check_response) do
          get :edit, :id => @daily_deal.id
        end
      end
    end

    context "given show_daily_deals_on_landing_page is false" do
      setup do
        @advertiser.publisher.publishing_group.update_attribute(:show_daily_deals_on_landing_page, false)
      end

      should "not show disclaimer field" do
        check_response = lambda do |role|
          assert_select "input[name='daily_deal[show_on_landing_page]']", 0
        end
        with_login_managing_advertiser_required(@advertiser, check_response) do
          get :edit, :id => @daily_deal.id
        end
      end
    end
  end

  test "edit with allow_secondary_daily_deal_photo" do
    advertiser = advertisers(:changos)

    advertiser.publisher.update_attribute(:allow_secondary_daily_deal_photo, true)

    daily_deal = Factory(:daily_deal,
                         :advertiser => advertiser,
                         :secondary_photo_file_name => "standard.png",
                         :secondary_photo_content_type => "image/png",
                         :secondary_photo_file_size => 164576)

    check_response = lambda { |role|
      assert_select "input[name='daily_deal[secondary_photo]']"
      assert_select "a[href=?]", "#", :text => "Delete Secondary Photo", :count => 1
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :edit, :id => daily_deal.id
    end
  end

  context "preview daily deal certificate" do

    setup do
      @daily_deal = Factory(:daily_deal)
    end

    should "display for admin user" do
      login_as Factory(:admin)
      get :edit, :id => @daily_deal.to_param
      assert_select "a[href='#{preview_pdf_daily_deal_path(@daily_deal.to_param)}']"
    end

    context "with self serve publisher user" do

      setup do
        @publisher = @daily_deal.publisher
        @user      = Factory(:user, :company => @publisher)
        @publisher.update_attributes(:self_serve => true)
      end

      should "not display link if can_preview_daily_deal_certificates is set to false" do
        @publisher.update_attribute(:can_preview_daily_deal_certificates, false)
        @daily_deal.reload
        login_as @user
        get :edit, :id => @daily_deal.to_param
        assert_select "a[href='#{preview_pdf_daily_deal_path(@daily_deal.to_param)}']", false
      end

      should "display link if can_preview_daily_deal_certificates is set to true" do
        @publisher.update_attribute(:can_preview_daily_deal_certificates, true)
        @daily_deal.reload
        login_as @user
        get :edit, :id => @daily_deal.to_param
        assert_select "a[href='#{preview_pdf_daily_deal_path(@daily_deal.to_param)}']", true
      end

      should "not display link if the redemption page preview is available" do
        @daily_deal = Factory(:daily_deal, :price => 0, :max_quantity => 1, :min_quantity => 1)
        @publisher = @daily_deal.publisher.update_attribute(:can_preview_daily_deal_certificates, true)
        @daily_deal.update_attributes! :non_voucher_deal => true
        login_as Factory(:admin)
        get :edit, :id => @daily_deal.to_param
        assert_select "a[href='#{preview_pdf_daily_deal_path(@daily_deal.to_param)}']", false
      end

    end

  end

  context "preview non voucher redemption page" do

    setup do
      @daily_deal = Factory(:daily_deal, :price => 0, :max_quantity => 1, :min_quantity => 1)
      @publisher = @daily_deal.publisher
      @user      = Factory(:admin)
    end

    should "should display a preview link if the daily deal non_voucher_deal flag is true" do
      @daily_deal.update_attributes! :non_voucher_deal => true
      login_as @user
      get :edit, :id => @daily_deal.to_param
      assert_select "a[href='#{preview_non_voucher_redemption_daily_deal_path(@daily_deal.to_param)}']", true
    end

    should "should not display a preview link if the daily deal non_voucher_deal flag is false" do
      @daily_deal.update_attributes! :non_voucher_deal => false
      login_as @user
      get :edit, :id => @daily_deal.to_param
      assert_select "a[href='#{preview_non_voucher_redemption_daily_deal_path(@daily_deal.to_param)}']", false
    end

  end

  context "the travelsavers product code" do

    setup do
      login_as(Factory :admin)
    end

    should "be editable on a source deal whose publisher uses the travelsavers payment method" do
      deal = Factory :travelsavers_daily_deal
      get :edit, :id => deal.to_param
      assert_response :success
      assert_select "input[type=text][name='daily_deal[travelsavers_product_code]']"
    end

    should "not be shown at all on a source deal whose publisher does not use the travelsavers payment method" do
      deal = Factory :daily_deal
      assert !deal.pay_using?(:travelsavers)
      get :edit, :id => deal.to_param
      assert_response :success
      assert_select "input[type=text][name='daily_deal[travelsavers_product_code]']", false
    end

    should "be visible, read-only, on a distributed deal whose source deal uses the travelsavers payment method" do
      syndicated_deal = Factory :distributed_daily_deal
      syndicated_deal.source.publisher.update_attributes! :payment_method => "travelsavers"
      syndicated_deal.source.update_attributes! :travelsavers_product_code => "CXP-TEST"
      get :edit, :id => syndicated_deal.to_param
      assert_response :success
      assert_select "input[type=text][name='daily_deal[travelsavers_product_code]'][disabled=disabled]"
    end

    should "be visible, read-only, on a travelsavers source deal with associated purchases" do
      deal = Factory :travelsavers_daily_deal
      Factory :pending_daily_deal_purchase, :daily_deal => deal
      deal.daily_deal_purchases.reload
      get :edit, :id => deal.to_param
      assert_response :success
      assert_select "input[type=text][name='daily_deal[travelsavers_product_code]'][disabled=disabled]"
    end

    should "not be visible on a syndicated deal whose source deal does not use the travelsavers payment method" do
      syndicated_deal = Factory :distributed_daily_deal
      assert !syndicated_deal.source.pay_using?(:travelsavers)
      get :edit, :id => syndicated_deal.to_param
      assert_response :success
      assert_select "input[type=text][name='daily_deal[travelsavers_product_code]']", false
    end

  end

  context "with sales_agent_id" do

    setup do
      @daily_deal = Factory(:daily_deal)
    end

    context "without daily deal publisher being enabled for sales_agent_id_for_advertisers" do

      should "not display the text input form for the sales_agent_id" do
        login_as Factory(:admin)
        get :edit, :id => @daily_deal
        assert_select "input[type=text][name='daily_deal[sales_agent_id]']", false
      end

    end

    context "with daily deal publisher being enabled for sales_agent_id_for_advertisers" do

      setup do
        @daily_deal.publisher.update_attribute(:enable_sales_agent_id_for_advertisers, true)
      end

      should "display the text input form for the sales_agent_id" do
        login_as Factory(:admin)
        get :edit, :id => @daily_deal
        assert_select "input[type=text][name='daily_deal[sales_agent_id]']", true
      end

    end

  end

  context "campaign code" do
    setup do
      @daily_deal = Factory(:daily_deal)
    end

    should "be present on the edit page" do
      login_as Factory(:admin)
      get :edit, :id => @daily_deal
      assert_select "input[type='text'][name='daily_deal[campaign_code]']"
    end
  end

  protected

  def setup_deal_with_publisher_in_time_zone(time_zone = "Eastern Time (US & Canada)")
    @publisher_in_time_zone = Factory(:publisher, :time_zone => time_zone)
    @advertiser = Factory(:advertiser, :publisher_id => @publisher_in_time_zone.id)
    @daily_deal = Factory(:daily_deal,
                          :advertiser_id => @advertiser.id,
                          :start_at => "2010-06-14 07:00:00 UTC",
                          :hide_at => "2010-06-15 02:00:00 UTC",
                          :expires_on => "2010-12-31")
    @admin_user = Factory(:admin)
    @controller.stubs(:current_user).returns(@admin_user)
  end

  def save_current_time_zone
    @original_tz = Time.zone
  end

  def restore_saved_time_zone
    Time.zone = @original_tz
  end

end
