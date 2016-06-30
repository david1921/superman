require File.dirname(__FILE__) + "/../../test_helper"

class AdvertisersController::EditTest < ActionController::TestCase
  tests AdvertisersController

  def setup
    setup_publisher_and_advertiser_and_users!
    login_as @admin_user
  end

  should "deny unauthorized users" do
    unauthorized_user = Factory(:user_without_company)
    login_as unauthorized_user
    get :edit, :id => @advertiser.to_param
    assert_redirected_to new_session_path
  end

  context "as a publisher user" do
    setup do
      login_as @publisher_user
    end

    should "render standard inputs, page elements" do
      get :edit, :id => @advertiser.to_param
      assert_select "form#edit_advertiser_#{@advertiser.id}[enctype=multipart/form-data]" do
        assert_select "input[type=checkbox][name='advertiser[used_exclusively_for_testing]']"

        assert_select "input[type=text][name='advertiser[name]'][value='Desperate Salon']"
        assert_select "input[type=file][name='advertiser[logo]']"
        assert_select "input[type=text][name='advertiser[website_url]'][value=http://www.advertiser.com/some/page]"
        assert_select "input[type=text][name='advertiser[email_address]'][value='john@advertiser.com']"
        assert_select "select[name='advertiser[stores_attributes][0][country_id]']" do
          assert_select "option[value=#{Country::CA.id}][selected]"
        end
        assert_select "input[type=text][name='advertiser[stores_attributes][0][address_line_1]'][value='123 Hall St']"
        assert_select "input[type=text][name='advertiser[stores_attributes][0][address_line_2]'][value='Apt C']"
        assert_select "input[type=text][name='advertiser[stores_attributes][0][city]'][value=Beaverton]"
        assert_select "select[name='advertiser[stores_attributes][0][state]']", :count => 2
        assert_select "select[name='advertiser[stores_attributes][0][state]']" do
          assert_select "option[value=BC][selected]"
        end
        assert_select "input[type=text][name='advertiser[stores_attributes][0][zip]'][value='K2H 7K9']"
        assert_select "input[type=text][name='advertiser[stores_attributes][0][phone_number]'][value='(123) 456-7890']"
        assert_select "input[type=checkbox][name='advertiser[do_not_show_map]'][checked]"
        assert_select "#store_#{@advertiser.stores.first.id}_delete_link.delete_link", 1
      end
    end

    should "render required phone help messages for locale en" do
      get :edit, :locale => 'en', :id => @advertiser.to_param
      assert_select "div[class=help]", "Required unless phone given"
    end

    should "NOT render required phone help messages for locale en-GB" do
      get :edit, :locale => 'en-GB', :id => @advertiser.to_param
      assert_select "div[class=help]", ""
    end

    fast_context "publisher with disabled features" do
      setup do
        @publisher.publishing_group.update_attributes!(:advertiser_financial_detail => false)
        @publisher.update_attributes!(
            :allow_gift_certificates => false, :allow_daily_deals => false, :advertiser_has_listing => false,
            :enable_sales_agent_id_for_advertisers => false, :txt_keyword_prefix => nil
        )
        @publisher.stubs(:enable_google_offers_feed?).returns(false)
        get :edit, :id => @advertiser.to_param
        assert_template 'edit'
      end

      should "not have certificate preview (disabled in publisher)" do
        assert_select "div#certificate_preview", false
      end

      should "not have daily deals preview (disabled in publisher)" do
        assert_select "div#daily_deals_preview", false
      end

      should "not have txt coupons preview (disabled in publisher)" do
        assert_select "div#daily_deals_preview", false
      end

      should "not have advertiser listing input (disabled in publisher)" do
        assert_select "input[type=text][name='advertiser[listing]']", false
      end

      should "not have advertiser description input (only for ocregister)" do
        assert_select "textarea#advertiser_description", false
      end

      should "not have sales agent id input (disabled in publisher)" do
        assert_select "input[type=text][name='advertiser[sales_agent_id]']", false
      end

      should "not have active_txt_coupon_limit and txt_keyword_prefix (disabled in publisher)" do
        assert_select "input[type=text][name='advertiser[active_txt_coupon_limit]']", false
        assert_select "input[type=text][name='advertiser[txt_keyword_prefix]']", false
      end

      should "not show inputs for financial details (disabled in publishing group)" do
        assert_select "input[type=text][name='advertiser[rep_name]']", false
        assert_select "input[type=text][name='advertiser[rep_id]']", false
        assert_select "input[type=text][name='advertiser[merchant_contact_name]']", false
        assert_select "input[type=text][name='advertiser[merchant_commission_percentage]']", false
        assert_select "input[type=text][name='advertiser[revenue_share_percentage]']", false
        assert_select "input[type=text][name='advertiser[bank_account_number]']", false
        assert_select "input[type=text][name='advertiser[bank_routing_number]']", false
        assert_select "input[type=select][name='advertiser[payment_type]']", false
        assert_select "input[type=text][name='advertiser[federal_tax_id]']", false
        assert_select "input[type=text][name='advertiser[merchant_id]']", false
      end
    end

    fast_context "publisher with enabled features" do
      setup do
        @publisher.publishing_group.update_attributes!(:advertiser_financial_detail => true)
        @publisher.update_attributes!(
            :allow_gift_certificates => true, :allow_daily_deals => true, :advertiser_has_listing => true,
            :enable_sales_agent_id_for_advertisers => true, :txt_keyword_prefix => "PUB"
        )
        @publisher.stubs(:enable_google_offers_feed?).returns(true)
        @advertiser.offers.create!(:deleted_at => Time.now, :message => "I was deleted")
        @advertiser.txt_offers.create!(:keyword => "PUBADVKEY", :message => "TXT Message", :deleted => true)
        Factory(:daily_deal, :advertiser => @advertiser, :deleted_at => 2.days.ago)
        @advertiser.gift_certificates.create!(
            :message => "my message",
            :terms => "These are my terms. Accept them!",
            :value => 25.00,
            :price => 12.99,
            :number_allocated => 10
        )
        get :edit, :id => @advertiser.to_param
      end

      should "have input for sales agent id (enabled in publisher)" do
        assert_select "input[type=text][name='advertiser[sales_agent_id]'][value=agent15]"
      end

      should "have input for active_txt_coupon_limit and txt_keyword_prefix (enabled in publisher)" do
        assert_select "input[type=text][name='advertiser[active_txt_coupon_limit]'][value=20]"
        assert_select "input[type=text][name='advertiser[txt_keyword_prefix]'][value='ADV']"
      end

      should "have inputs for advertiser financial detail (enabled in publishing group)" do
        assert_select "input[type=text][name='advertiser[rep_name]'][value='Steve Rep']"
        assert_select "input[type=text][name='advertiser[rep_id]'][value='rep id']"

        assert_select "input[type=text][name='advertiser[merchant_name]'][value='sample merchant name']"
        assert_select "input[type=text][name='advertiser[merchant_contact_name]'][value='John Merchant']"
        assert_select "input[type=text][name='advertiser[merchant_commission_percentage]'][value=10]"

        assert_select "input[type=text][name='advertiser[revenue_share_percentage]'][value=40]"
        assert_select "select[name='advertiser[payment_type]']" do
          assert_select "option[value=ACH][selected]"
        end

        assert_select "input[type=text][name='advertiser[check_payable_to]'][value='sample payable to']"
        assert_select "input[type=text][name='advertiser[check_mailing_address_line_1]'][value='500 SW High Way']"
        assert_select "input[type=text][name='advertiser[check_mailing_address_line_2]'][value='Apt 123']"
        assert_select "input[type=text][name='advertiser[check_mailing_address_city]'][value='Beaverton']"
        assert_select "select[name='advertiser[check_mailing_address_state]']" do
          [""] + Addresses::Codes::US::STATE_CODES.each do |state_code|
            assert_select "option[value=#{state_code}]"
          end
          assert_select "option[value=OR][selected]"
        end
        assert_select "input[type=text][name='advertiser[check_mailing_address_zip]'][value='97005']"

        assert_select "input[type=text][name='advertiser[bank_name]'][value='Some Credit Union']"
        assert_select "input[type=text][name='advertiser[bank_account_number]'][value=123456789]"
        assert_select "input[type=text][name='advertiser[bank_routing_number]'][value=321654987]"
        assert_select "input[type=text][name='advertiser[name_on_bank_account]'][value='Rich Guy']"

        assert_select "input[type=text][name='advertiser[federal_tax_id]'][value='543213213-123']"
        assert_select "input[type=text][name='advertiser[merchant_id]'][value='sample merchant id']"
      end

      should "show daily deal preview without deleted daily deals" do
        assert_select "div#daily_deals_preview" do
          assert_select "a", :text => "Add New Daily Deal"
        end
      end

      should "show gift certificate preview" do
        gift_certificate = @advertiser.reload.gift_certificates.last

        assert_select "div#certificate_preview" do
          assert_select "div.wrapper" do
            assert_select "div.certificate" do
              assert_select "div.body" do
                assert_select "div.logo"
                assert_select "h3", :text => @advertiser.name.upcase
                assert_select "div.text" do
                  assert_select "p.message", :text => gift_certificate.message
                  assert_select "p.terms", :text => "These are my terms. Accept them!"
                  assert_select "p.price", :text => "Price: $12.99"
                end
                assert_select "div.footer" do
                  assert_select "a[href='#{edit_advertiser_gift_certificate_path(@advertiser, gift_certificate)}']"
                end
              end
            end
          end
          assert_select "a", :text => "Edit"
        end
      end

      should "show gift certificates preview" do
        assert_select "div#certificate_preview" do
          assert_select "h3", "Deal Certificates"
          assert_select "#certificate_#{@advertiser.gift_certificates.first.id}.certificate"
        end
      end

      should "show coupons preview and omit deleted coupons" do
        assert_select "div#coupons_preview", /no coupons/i do
          assert_select "div.coupon", 0
        end
        assert !@response.body["I was deleted"], "Should not show deleted coupon"
      end

      should "show txt coupons preview without deleted txt offers" do
        assert_select "div#txt_coupons_preview", /no txt coupons/i do
          assert_select "div.txt_coupon", 0
        end
      end

    end

    should "have publisher label (vs id) in locm offer link" do
      @publisher.update_attributes!(:label => "1234")
      offer = @advertiser.offers.create!(:message => "I was deleted")

      @request.host = "locm.analoganalytics.com"
      get :edit, 'id' => @advertiser.to_param

      assert_select "#coupons_preview a" do
        assert_select "[href=?]", /\/publishers\/#{@publisher.label}\/offers\?offer_id=#{offer.id}/, 1
      end
    end

    should "display price with currency" do
      @publisher.update_attributes!(:allow_gift_certificates => true)
      Factory :gift_certificate, :price => 17, :value => 40, :advertiser => @advertiser

      [["USD", "$"], ["CAD", "C$"], ["GBP", "£"]].each do |currency_code, currency_symbol|
        @publisher.update_attributes!(:currency_code => currency_code)
        get :edit, :id => @advertiser.to_param
        assert_select "div.certificate p.price", :text => "Price: #{currency_symbol}17.00"
      end
    end

    context "store select and delete link" do
      should "not show for advertiser without stores" do
        @advertiser.stores.destroy_all
        get :edit, :id => @advertiser.to_param
        assert_select "form.edit_advertiser" do
          assert_select "select[name=store_id]", false
          assert_select ".store .delete_link", 0
        end
      end

      should "show when at least one store" do
        @advertiser.stores.create!(Factory.attributes_for(:store))
        assert @advertiser.reload.stores.present?
        get :edit, :id => @advertiser.to_param
        assert_select "select[name=store_id]"
        assert_select ".store .delete_link"
      end
    end

    should "have correct gift certificate preview with no gift certificates" do
      @publisher.update_attributes!(:allow_gift_certificates => true)
      @advertiser.gift_certificates.destroy_all
      get :edit, :id => @advertiser.to_param
      assert_select "div#certificate_preview", /No Deal Certificates/ do
        assert_select "a", :text => "Add New Deal Certificate"
      end
    end
  end

  context "as advertiser user (special cases)" do
    setup do
      @publisher.update_attributes!(:enable_sales_agent_id_for_advertisers => true, :txt_keyword_prefix => "PRE")
      @publisher.publishing_group.update_attributes!(:advertiser_financial_detail => true)
      login_as @advertiser_user
    end

    should "not see unauthorized inputs (active_coupon_limit, listing, financials, etc)" do
      get :edit, :id => @advertiser.to_param
      assert_select "form.edit_advertiser" do
        misc_attrs = [:active_coupon_limit, :active_txt_coupon_limit, :txt_keyword_prefix, :sales_agent_id, :listing]
        financial_attrs = [
            :rep_id, :merchant_name, :merchant_contact_name, :merchant_commission_percentage,
            :revenue_share_percentage, :check_payable_to, :check_mailing_address_line_1,
            :check_mailing_address_line_2, :check_mailing_address_city, :check_mailing_address_state,
            :check_mailing_address_zip, :bank_name, :bank_account_number, :bank_routing_number, :name_on_bank_account,
            :federal_tax_id, :merchant_id
        ]
        (misc_attrs + financial_attrs).each do |financial_attr|
          assert_select "input[type=text][name='advertiser[#{financial_attr}]']", false
        end
        assert_select "select[name='advertiser[payment_type]']", false
      end
    end
  end

  context "as admin user (special cases)" do
    setup do
      login_as @admin_user
    end

    should "see admin-only inputs (coupon_limit, google_map_url, voice_response_code)" do
      get :edit, :id => @advertiser.to_param
      %w(coupon_limit google_map_url voice_response_code).each do |attr|
        assert_select "input[type=text][name='advertiser[#{attr}]']"
      end
    end

    should "see advertiser status if the publisher has enable_advertiser_statuses set" do
      @advertiser.publisher.update_attribute(:enable_advertiser_statuses, true)
      get :edit, :id => @advertiser.to_param
      assert_select "select[name='advertiser[status]']" do
        assert_select "option[value=pending]", "Pending"
        assert_select "option[value=approved][selected]", "Approved"
        assert_select "option[value=suspended]", "Suspended"
      end
    end

    should "not see advertiser status if the publisher does not enable_advertiser_statuses set" do
      @advertiser.publisher.update_attribute(:enable_advertiser_statuses, false)
      get :edit, :id => @advertiser.to_param
      assert_select "select[name='advertiser[status]']", 0
    end
  end
  context "as regular user, not admin" do
    should "not show admin-only inputs" do
      login_as @publisher_user
      get :edit, :id => @advertiser.to_param
      assert_select "select[name='advertiser[status]']", false
    end
  end

  context "other special cases" do
    context "OC Register" do
      should "have input for advertiser description (enabled in publisher)" do
        @publisher.update_attributes!(:label => "ocregister")
        @advertiser.update_attributes!(:description => "my amazing description")
        get :edit, :id => @advertiser.to_param
        assert_select "textarea#advertiser_description", "my amazing description"
      end
    end

  end

  context "#advertiser_size" do
    setup do
      @publisher = Factory(:publisher, :label => "bespoke" )
      setup_advertiser!
    end

    should "have size drop-down" do
      get :edit, :id => @advertiser.to_param
      assert_select "select[name='advertiser[size]']" do
        assert_select "option[value=]", ""
        assert_select "option[value=SME]", "SME"
        assert_select "option[value=Large][selected]", "Large"
        assert_select "option[value=SoleTrader]", "SoleTrader"
      end
    end
  end

  context "#advertiser_coupon_modes" do
    setup do
      @publisher = Factory(:publisher, :label => "bespoke" )
      @publisher.update_attributes!(
            :enable_sales_agent_id_for_advertisers => true, :txt_keyword_prefix => "PUB"
        )
      setup_advertiser!
    end

    should "have inputs visible to non-advertiser users" do
      get :edit, :id => @advertiser.to_param
      assert_select "input[type=text][name='advertiser[active_coupon_limit]'][value=10]"
      assert_select "input[type=text][name='advertiser[active_txt_coupon_limit]'][value=20]"
    end
  end

  context "#advertiser_owners" do
    setup do
      @publisher = Factory(:publisher, :label => "bespoke" )
      @advertiser = Factory(:advertiser, :publisher => @publisher)
    end

    should "have a new advertiser owner link" do
      get :edit, :id => @advertiser.to_param
      assert_select "a[href='/advertisers/#{@advertiser.to_param}/advertiser_owners/new']", "Create new owner"
    end

    should "have an advertiser owners table" do
      @owner = Factory.create(:advertiser_owner, :advertiser => @advertiser, :first_name => 'beef', :last_name => 'pork')
      get :edit, :id => @advertiser.to_param
      assert_select "table[id='advertiser_owners_table']" do
        assert_select "tr", {:count => 2}, 'header and one data row'
        assert_select "td", 'beef', 'owners first name'
        assert_select "td", 'pork', 'owners last name'
      end
    end
  end

  context "publisher-specific fields" do
    context "general publisher" do
      setup do
        @publisher = Factory(:publisher, :label => "pglabel" )
        @advertiser = Factory(:advertiser, :publisher => @publisher)
      end

      should "render default template" do
        get :edit, :id => @advertiser.id
        assert_response :success
        assert_template :partial => '_publisher_specific_fields'
      end
    end

    context "bespoke publisher" do
      setup do
        @publisher = Factory(:publisher, :label => "bespoke" )
        @advertiser = Factory(:advertiser, :publisher => @publisher)
      end

      should "render default template" do
        get :edit, :id => @advertiser.id
        assert_response :success
        assert_template :partial => 'bespoke/advertisers/_publisher_specific_fields'
      end

      context "business category fields" do
        should "render business category fields with no secondary categories if no primary business category exists" do
          @advertiser.update_attributes(:primary_business_category => nil, :secondary_business_category => nil)
          get :edit, :id => @advertiser.id
          assert_select "select[name='advertiser[primary_business_category]']" do
            Advertiser::PRIMARY_CATEGORY_KEYS.each do |key|
              assert_select "option[value=#{key}]"
            end
          end
          assert_select "select[name='advertiser[secondary_business_category]']" do
            assert_select "option[value='']", 1
            assert_select "option:not([value=''])", 0
          end
        end

        should "render business category fields with secondary categories if a primary business category exists" do
          @advertiser.update_attributes(:primary_business_category => 'entertainment', :secondary_business_category => nil)
          get :edit, :id => @advertiser.id
          assert_select "select[name='advertiser[primary_business_category]']" do
            Advertiser::PRIMARY_CATEGORY_KEYS.each do |key|
              assert_select "option[value=#{key}]"
            end
          end
          assert_select "select[name='advertiser[secondary_business_category]']" do
            Advertiser::SECONDARY_CATEGORY_KEYS['entertainment'].each do |key, value|
              assert_select "option[value=#{key}]", value
            end
          end
        end
      end
    end
  end

  private

  def setup_publisher_and_advertiser_and_users!
    @publisher = Factory(:publisher, :self_serve => true, :advertiser_self_serve => true).tap do |pub|
      pub.countries << Country::CA
    end

    setup_advertiser!
    setup_store!

    subscription_rate_schedule = @advertiser.create_subscription_rate_schedule(:name => "Standard Rate Schedule", :item_owner => @publisher)
    @advertiser.update_attributes!(:subscription_rate_schedule_id => subscription_rate_schedule.id)

    assert_equal Country::CA, @advertiser.reload.stores.first.country

    @advertiser_user = Factory(:user_without_company).tap do |u|
      u.user_companies.create!(:company => @advertiser)
    end

    @publisher_user = Factory(:user_without_company).tap do |u|
      u.user_companies.create!(:company => @publisher)
    end

    @admin_user = Factory(:admin)
  end

  def setup_advertiser!
    @advertiser = Factory(:advertiser,
        :publisher => @publisher,
        :name => "Desperate Salon",
        :status => "approved",
        :size => "Large",
        :website_url => "http://www.advertiser.com/some/page",
        :email_address => "john@advertiser.com",
        :do_not_show_map => true,
        :active_txt_coupon_limit => 20,
        :active_coupon_limit => 10,
        :sales_agent_id => "agent15",
        :rep_name => "Steve Rep",
        :rep_id => "rep id",
        :name => "Desperate Salon",
        :merchant_name => "sample merchant name",
        :merchant_contact_name => "John Merchant",
        :merchant_commission_percentage => 10,
        :revenue_share_percentage => 40,
        :payment_type => "ACH",
        :check_payable_to => "sample payable to",
        :check_mailing_address_line_1 => "500 SW High Way",
        :check_mailing_address_line_2 => "Apt 123",
        :check_mailing_address_city => "Beaverton",
        :check_mailing_address_state => "OR",
        :check_mailing_address_zip => "97005",
        :bank_name => "Some Credit Union",
        :bank_account_number => "123456789",
        :bank_routing_number => "321654987",
        :name_on_bank_account => "Rich Guy",
        :federal_tax_id => "543213213-123",
        :merchant_id => "sample merchant id",
        :txt_keyword_prefix => "ADV"
    )
  end

  def setup_store!
    @advertiser.stores.first.update_attributes!(
        :country_id => Country::CA.id,
        :address_line_1 => "123 Hall St",
        :address_line_2 => "Apt C",
        :city => "Beaverton",
        :state => "BC",
        :zip => "K2H 7K9",
        :phone_number => "123-456-7890",
        :listing => "12345"
    )
  end
end
