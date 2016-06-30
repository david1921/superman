require File.dirname(__FILE__) + "/../../test_helper"


class SyndicationDailyDealVariationsControllerTest < ActionController::TestCase
  tests DailyDealVariationsController

  context "edit" do

    setup do
      @source_deal = Factory(:daily_deal_for_syndication)
      @source_publisher = @source_deal.publisher
      @source_publisher.update_attributes( :self_serve => true, :enable_daily_deal_variations => true )
      @source_user = Factory(:user, :company => @source_publisher)

      @variation  = Factory(:daily_deal_variation, :daily_deal => @source_deal)
    end

    should "not be disable the variation inputs if the @source_deal has not been syndicated yet" do
      login_as @source_user
      get :edit, :daily_deal_id => @source_deal.to_param, :id => @variation.to_param
      assert assigns(:daily_deal), "should assign daily deal"
      assert assigns(:daily_deal_variation), "should assign daily deal variation"
      assert_template "edit"
      assert_layout "application"
      assert_select "form[action='#{daily_deal_daily_deal_variation_path(@source_deal, @variation)}'][method='post']" do          
        assert_select "input[type=hidden][name='_method'][value='put']", true
        assert_select "input[type=text][name='daily_deal_variation[value_proposition_subhead]']"
        assert_select "input[type=text][name='daily_deal_variation[value_proposition]']"
        assert_select "input[type=text][name='daily_deal_variation[voucher_headline]']"
        assert_select "input[type=text][name='daily_deal_variation[value]']"
        assert_select "input[type=text][name='daily_deal_variation[price]']"
        assert_select "input[type=text][name='daily_deal_variation[value_proposition_subhead]']"
        assert_select "input[type=text][name='daily_deal_variation[listing]']"

        # quantity do not have default values, since they delegate to the daily deal if not set.
        assert_select "input[type=text][name='daily_deal_variation[quantity]']"
        assert_select "input[type=text][name='daily_deal_variation[min_quantity]']"
        assert_select "input[type=text][name='daily_deal_variation[max_quantity]']"

        # barcodes
        assert_select "input[type=file][name='daily_deal_variation[bar_codes_csv]']"
        assert_select "select[name='daily_deal_variation[bar_code_encoding_format]']"
        assert_select "input[type=checkbox][name='daily_deal_variation[allow_duplicate_bar_codes]']"
        assert_select "input[type=checkbox][name='daily_deal_variation[delete_existing_unassigned_bar_codes]']"

        assert_select "textarea[name='daily_deal_variation[terms]']"
        assert_select "input[type=submit][value='Save']"
      end      
    end

    context "with a distributed deal" do

      setup do
        @distributed_publisher = Factory(:publisher, :enable_daily_deal_variations => true, :self_serve => true)        
        @distributed_user = Factory(:user, :company => @distributed_publisher)
        @distributed_deal = syndicate( @source_deal, @distributed_publisher )

      end

      should "disable the variation inputs when viewed as a @source_publisher user" do
        login_as @source_user
        get :edit, :daily_deal_id => @source_deal.to_param, :id => @variation.to_param
        assert assigns(:daily_deal), "should assign daily deal"
        assert assigns(:daily_deal_variation), "should assign daily deal variation"
        assert_template "edit"
        assert_layout "application"
        assert_select "form[action='#{daily_deal_daily_deal_variation_path(@source_deal, @variation)}'][method='post']" do          
          assert_select "input[type=hidden][name='_method'][value='put']", true
          assert_select "input[type=text][name='daily_deal_variation[value_proposition_subhead]'][disabled=disabled]"
          assert_select "input[type=text][name='daily_deal_variation[value_proposition]'][disabled=disabled]"
          assert_select "input[type=text][name='daily_deal_variation[voucher_headline]'][disabled=disabled]"
          assert_select "input[type=text][name='daily_deal_variation[value]'][disabled=disabled]"
          assert_select "input[type=text][name='daily_deal_variation[price]'][disabled=disabled]"
          assert_select "input[type=text][name='daily_deal_variation[listing]'][disabled=disabled]"

          # quantity do not have default values, since they delegate to the daily deal if not set.
          assert_select "input[type=text][name='daily_deal_variation[quantity]'][disabled=disabled]"
          assert_select "input[type=text][name='daily_deal_variation[min_quantity]'][disabled=disabled]"
          assert_select "input[type=text][name='daily_deal_variation[max_quantity]'][disabled=disabled]"

          # barcodes
          assert_select "input[type=file][name='daily_deal_variation[bar_codes_csv]'][disabled=disabled]"
          assert_select "select[name='daily_deal_variation[bar_code_encoding_format]'][disabled=disabled]"
          assert_select "input[type=checkbox][name='daily_deal_variation[allow_duplicate_bar_codes]'][disabled=disabled]"
          assert_select "input[type=checkbox][name='daily_deal_variation[delete_existing_unassigned_bar_codes]'][disabled=disabled]"

          assert_select "textarea[name='daily_deal_variation[terms]'][disabled=disabled]"
          assert_select "input[type=submit][value='Save']"
        end 
      end

      should "redirect to new session path, since @distributed_user can't mange @source_publisher" do
        login_as @distributed_user
        get :edit, :daily_deal_id => @source_deal.to_param, :id => @variation.to_param
        assert_redirected_to new_session_path
      end

    end

  end
end
