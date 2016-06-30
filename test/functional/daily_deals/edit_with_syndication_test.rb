require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealsController::EditWithSyndicaitonTest < ActionController::TestCase
  tests DailyDealsController

  context "edit" do
    setup do
      @advertiser = advertisers(:changos)
      @daily_deal = Factory(:daily_deal_for_syndication, :photo_file_name => "standard.png", :photo_content_type => "image/png", :photo_file_size => 164576)
      @admin = Factory(:admin)
    end

    should "display edit fields for unsyndicated deal" do
      login_as @admin
      get :edit, :id => @daily_deal.to_param
      assert_response :success
      assert_template :edit
      assert_layout :application

      assert_select "input[type=checkbox][name='daily_deal[available_for_syndication]']"
    end

    should "display edit fields for syndicated deal" do
      target_publisher = Factory(:publisher)
      @daily_deal.syndicated_deals.build(:publisher_id => target_publisher.id)
      @daily_deal.save!
      syndicated_deal = @daily_deal.syndicated_deals.last
      assert syndicated_deal.advertiser

      login_as @admin
      get :edit, :id => syndicated_deal.to_param

      assert_response :success
      assert_template :edit
      assert_layout :application

      assert_select "input[type='text'][name='daily_deal[value_proposition]'][disabled='disabled']", :count => 0
      assert_select "input[type='text'][name='daily_deal[value_proposition]']"
      assert_select "input[type='text'][name='daily_deal[price]'][disabled='disabled']"
      assert_select "input[type='text'][name='daily_deal[value]'][disabled='disabled']"
      assert_select "input[type='text'][name='daily_deal[min_quantity]'][disabled='disabled']"
      assert_select "input[type='text'][name='daily_deal[max_quantity]'][disabled='disabled']"
      assert_select "input[type='text'][name='daily_deal[quantity]'][disabled='disabled']"
      assert_select "input[name='daily_deal[photo]'][style='display: none']", :count => 1
      assert_select "input[name='daily_deal[start_at]'][disabled='disabled']", :count => 0
      assert_select "input[name='daily_deal[start_at]']"
      assert_select "input[name='daily_deal[hide_at]'][disabled='disabled']", :count => 0
      assert_select "input[name='daily_deal[hide_at]']"
      assert_select "input[name='daily_deal[expires_on]'][disabled='disabled']"
      assert_select "input[name='daily_deal[advertiser_revenue_share_percentage]']", :count => 0
      assert_select "input[name='daily_deal[listing]'][disabled='disabled']", :count => 0
      assert_select "input[name='daily_deal[listing]']"
      assert_select "input[type=checkbox][name='daily_deal[location_required]'][disabled='disabled']"
      assert_select "input[type='text'][name='daily_deal[bar_codes_csv]']", :count => 0
      assert_select "input[type=checkbox][name='daily_deal[allow_duplicate_bar_codes]']", :count => 0
      assert_select "input[type=checkbox][name='daily_deal[delete_existing_unassigned_bar_codes]']", :count => 0
      assert_select "input[type=checkbox][name='daily_deal[available_for_syndication]']", :count => 0
      assert_select "input[type=checkbox][name='daily_deal[national_deal]'][disabled='disabled']"
      assert_select "select[name='daily_deal[bar_code_encoding_format]']", :count => 0
    end

    should "display source deal values for delegated attributes after source deal updated" do
      target_publisher = Factory(:publisher)
      @daily_deal.syndicated_deals.build(:publisher_id => target_publisher.id)
      @daily_deal.save!
      syndicated_deal = @daily_deal.syndicated_deals.last
      @daily_deal.value = 86
      @daily_deal.min_quantity = 2
      @daily_deal.max_quantity = 17
      @daily_deal.quantity = 23
      @daily_deal.save!

      login_as @admin
      get :edit, :id => syndicated_deal.to_param
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert_select "input[type='text'][name='daily_deal[value]'][disabled='disabled'][value='86.0']"
      assert_select "input[type='text'][name='daily_deal[min_quantity]'][disabled='disabled'][value='2']"
      assert_select "input[type='text'][name='daily_deal[max_quantity]'][disabled='disabled'][value='17']"
      assert_select "input[type='text'][name='daily_deal[quantity]'][disabled='disabled'][value='23']"
      assert_select "input[name='daily_deal[tipping_point]']", 0
    end

    should "display syndicate link if not syndicated" do
      login_as @admin
      get :edit, :id => @daily_deal.to_param
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert_select "label", :count => 1, :text => "Syndicated to Publishers:"
      assert_select "a[href=?]", daily_deal_syndicated_deals_path(@daily_deal),
                    :count => 1, :text=>"Syndicate"
    end

    should "display edit link if deal has been syndicated" do
      target_publisher = Factory(:publisher)
      @daily_deal.syndicated_deals.build(:publisher_id => target_publisher.id)
      @daily_deal.save!
      syndicated_deal = @daily_deal.syndicated_deals.last

      login_as @admin
      get :edit, :id => @daily_deal.to_param
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert_select "label", :count => 1, :text => "Syndicated to Publishers:"
      assert_select "a[href=?]", daily_deal_syndicated_deals_path(@daily_deal),
                    :count => 1, :text => "Edit"
      assert_select "a[href=?]", edit_daily_deal_path(syndicated_deal),
                    :count => 1, :text => target_publisher.name
    end

    should "NOT display syndication if deal is a syndicated deal" do
      target_publisher = Factory(:publisher)
      @daily_deal.syndicated_deals.build(:publisher_id => target_publisher.id)
      @daily_deal.save!
      syndicated_deal = @daily_deal.syndicated_deals.last

      login_as @admin
      get :edit, :id => syndicated_deal.to_param
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert_select "label", :count => 0, :text => "Syndicated to Publishers:"
      assert_select "a[href=?]", daily_deal_syndicated_deals_path(syndicated_deal),
                    :count => 0, :text => "Edit"
    end
    
    should "not disable terms or voucher steps for admin user" do
      login_as @admin
      get :edit, :id => @daily_deal.to_param
      assert_select "textarea[name='daily_deal[terms]']"
      assert_select "textarea[name='daily_deal[voucher_steps]']"
      assert_select "textarea[name='daily_deal[terms]'][disabled=disabled]", :count => 0
      assert_select "textarea[name='daily_deal[voucher_steps]'][disabled=disabled]", :count => 0
    end
    
    should "not disable terms or voucher steps for accountant user" do
      login_as Factory(:accountant)
      get :edit, :id => @daily_deal.to_param
      assert_select "textarea[name='daily_deal[terms]']"
      assert_select "textarea[name='daily_deal[voucher_steps]']"
      assert_select "textarea[name='daily_deal[terms]'][disabled=disabled]", :count => 0
      assert_select "textarea[name='daily_deal[voucher_steps]'][disabled=disabled]", :count => 0
    end
    
    should "not disable terms or voucher steps for normal user" do
      @daily_deal.publisher.update_attribute(:advertiser_self_serve, true)
      login_as Factory(:user, :company => @daily_deal.advertiser)
      get :edit, :id => @daily_deal.to_param
      assert_select "textarea[name='daily_deal[terms]']"
      assert_select "textarea[name='daily_deal[voucher_steps]']"
      assert_select "textarea[name='daily_deal[terms]'][disabled=disabled]", :count => 0
      assert_select "textarea[name='daily_deal[voucher_steps]'][disabled=disabled]", :count => 0
    end

    context "syndication restricted to publishing group" do
      setup do
        publishing_group = Factory(:publishing_group, :restrict_syndication_to_publishing_group => true)
        @publisher1 = @daily_deal.publisher
        @publisher1.update_attributes(:publishing_group => publishing_group)
        @publisher2 = Factory(:publisher, :publishing_group => publishing_group)
        @publisher3 = Factory(:publisher, :publishing_group => publishing_group, :launched => false)
      end

      should "show checkboxes for publisher selection for syndication" do
        login_as @admin
        get :edit, :id => @daily_deal.id

        assert_select "input[type='checkbox'][name='daily_deal[syndicated_deal_publisher_ids][]'][value='#{@publisher2.id}']", 1
        assert_select "input[type='checkbox'][name='daily_deal[syndicated_deal_publisher_ids][]']", :count => 1

        assert_select "input[type='checkbox'][name='daily_deal[syndicated_deal_publisher_ids][]'][value='#{@publisher1.id}']", 0, "should not show daily deal publisher"
        assert_select "input[type='checkbox'][name='daily_deal[syndicated_deal_publisher_ids][]'][value='#{@publisher3.id}']", 0, "should not show launched"
      end
    end
  end

  context "edit syndicated deal" do
    setup do
      Time.zone = ActiveSupport::TimeZone.new("Central Time (US & Canada)")
      source_start_at = Time.zone.local(2011, 4, 18, 00, 10, 00)
      source_hide_at = Time.zone.local(2011, 4, 18, 23, 55, 00)
      @source_publisher = Factory(:publisher, :time_zone => "Central Time (US & Canada)")
      @source_advertiser = Factory(:advertiser, :publisher => @source_publisher)
      @source_deal = Factory(:daily_deal_for_syndication,
                             :advertiser => @source_advertiser,
                             :publisher => @source_publisher,
                             :start_at => source_start_at,
                             :hide_at => source_hide_at,
                             :expires_on => "April 28, 2011")

      @syndicated_deal_publisher = Factory(:publisher, :time_zone => "Eastern Time (US & Canada)")
      @syndicated_deal = syndicate(@source_deal, @syndicated_deal_publisher)
      @admin = Factory(:admin)
    end

    should "show syndicated deal start and hide at in syndicated publisher time zone" do
      Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 34, 56)) do
        login_as @admin
        get :edit, :id => @syndicated_deal.to_param
        assert_response :success
        assert_template :edit
        assert_layout :application

        assert_select "input[name='daily_deal[start_at]']", :value => "April 18, 2011 01:10 AM"
        assert_select "div[id='start_at_help']", :text => "Eastern Time (US &amp; Canada)"
        assert_select "input[name='daily_deal[hide_at]']", :value => "April 18, 2011 12:55 PM"
        assert_select "div[id='hide_at_help']", :text => "Eastern Time (US &amp; Canada)"
      end
    end

    should "show the cobrand deal voucher checkbox, disabled and renamed so that its value is" +
               "ignored in the updating of the deal" do
      login_as @admin
      assert @admin.has_admin_privilege?
      get :edit, :id => @syndicated_deal.to_param
      assert_response :success
      assert_select "input#cobrand_deal_vouchers_ignored[type=checkbox][disabled=disabled]", :count => 1
    end
    
    should "not disable terms or voucher steps for admin user" do
      login_as @admin
      get :edit, :id => @syndicated_deal.to_param
      assert_select "textarea[name='daily_deal[terms]']"
      assert_select "textarea[name='daily_deal[voucher_steps]']"
      assert_select "textarea[name='daily_deal[terms]'][disabled=disabled]", :count => 0
      assert_select "textarea[name='daily_deal[voucher_steps]'][disabled=disabled]", :count => 0
    end
    
    should "not disable terms or voucher steps for accountant user" do
      login_as Factory(:accountant)
      get :edit, :id => @syndicated_deal.to_param
      assert_select "textarea[name='daily_deal[terms]']"
      assert_select "textarea[name='daily_deal[voucher_steps]']"
      assert_select "textarea[name='daily_deal[terms]'][disabled=disabled]", :count => 0
      assert_select "textarea[name='daily_deal[voucher_steps]'][disabled=disabled]", :count => 0
    end
    
    should "disable terms or voucher steps for normal user" do
      @syndicated_deal_publisher.update_attribute(:self_serve, true)
      login_as Factory(:user, :company => @syndicated_deal_publisher)
      get :edit, :id => @syndicated_deal.to_param
      assert_select "textarea[name='daily_deal[terms]'][disabled=disabled]"
      assert_select "textarea[name='daily_deal[voucher_steps]'][disabled=disabled]"
    end

  end

  private

  def syndicate(daily_deal, syndicated_publisher)
    daily_deal.syndicated_deals.build(:publisher_id => syndicated_publisher.id)
    daily_deal.save!
    daily_deal.syndicated_deals.last
  end

end
