require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::SyndicationRevenueSharingAgreementsControllerTest < ActionController::TestCase
  
  context "access_denied" do
    setup do
      @daily_deal = Factory(:daily_deal_for_syndication)
    end
    
    context "user without admin or accountant privileges" do
      setup do
        @user = Factory(:user)
        login_as(@user)
        get :edit, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the login page" do
        assert_redirected_to new_session_path
        assert_equal 'Unauthorized access', flash[:notice]
      end
    end
    
    context "admin user without accountant privileges" do
      setup do
        @admin = Factory(:admin)
        login_as(@admin)
        get :edit, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the login page" do
        assert_redirected_to new_session_path
      end
      
      should "set a flash notice" do
        assert_equal 'Unauthorized access', flash[:notice]
      end
    end
    
    context "accountant user without daily_deal" do
      setup do
        @accountant = Factory(:accountant)
        login_as(@accountant)
        get :edit
      end
      
      should "redirect to the login page" do
        assert_redirected_to new_session_path
        assert_equal 'Unauthorized access', flash[:notice]
      end
    end
  end
  
  context "edit" do
    
    context "deal that is not available for syndication" do
      setup do
        @daily_deal = Factory(:daily_deal)
        @accountant = Factory(:accountant)
        login_as(@accountant)
        get :edit, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the edit daily deal page with message" do
        assert_redirected_to edit_daily_deal_path(@daily_deal)
        assert_equal 'Deal must be available for syndication.', flash[:error]
      end
    end
    
    context "without approved agreement" do
      setup do
        @daily_deal = Factory(:daily_deal_for_syndication)
        @syndication_revenue_sharing_agreement = Factory(:syndication_revenue_sharing_agreement, 
                                                         :agreement => @daily_deal.publisher,
                                                         :approved => false)
        @accountant = Factory(:accountant)
        login_as(@accountant)
        get :edit, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the edit daily deal page with message" do
        assert_redirected_to edit_daily_deal_path(@daily_deal)
        assert_equal 'A current publishing group or publisher syndication revenue sharing agreement must exist and be approved.', flash[:error]
      end
    end
    
    context "without an existing agreement" do
      setup do
        @daily_deal = Factory(:daily_deal_for_syndication)
        @accountant = Factory(:accountant)
        login_as(@accountant)
        get :edit, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the edit daily deal page with message" do
        assert_redirected_to edit_daily_deal_path(@daily_deal)
        assert_equal 'A current publishing group or publisher syndication revenue sharing agreement must exist and be approved.', flash[:error]
      end
    end
    
    context "with publisher agreement" do
      setup do
        @daily_deal = Factory(:daily_deal_for_syndication)
        @agreement = Factory(:syndication_revenue_sharing_agreement, :agreement => @daily_deal.publisher)
        @accountant = Factory(:accountant)
        login_as(@accountant)
        get :edit, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the new page" do
        assert_response :success
        assert_template :edit
        assert_layout :application
        assert assigns(:daily_deal)
        assert_nil assigns(:publisher)
        assert_nil assigns(:publishing_group)
        assert_select "input[name='accounting_syndication_revenue_sharing_agreement[syndication_fee_gross_percentage]'][value='#{@agreement.syndication_fee_gross_percentage}']"
      end
    end
    
    context "with publishing group agreement" do
      setup do
        @publishing_group = Factory(:publishing_group)
        @publisher = Factory(:publisher, :publishing_group => @publishing_group)
        @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher)
        @agreement = Factory(:syndication_revenue_sharing_agreement, :agreement => @publishing_group)
        @accountant = Factory(:accountant)
        login_as(@accountant)
        get :edit, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the new page" do
        assert_response :success
        assert_template :edit
        assert_layout :application
        assert assigns(:daily_deal)
        assert_nil assigns(:publisher)
        assert_nil assigns(:publishing_group)
        assert_select "input[name='accounting_syndication_revenue_sharing_agreement[syndication_fee_gross_percentage]'][value='#{@agreement.syndication_fee_gross_percentage}']"
      end
    end
    
  end
  
  context "create" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @daily_deal = Factory(:daily_deal_for_syndication, :publisher => @publisher)
      @agreement = Factory(:syndication_revenue_sharing_agreement, :agreement => @publishing_group)
      @accountant = Factory(:accountant)
      login_as(@accountant)
    end
    
    should "redirect to the new page" do
      assert_nil @daily_deal.syndication_revenue_sharing_agreement
      post :create, :daily_deal_id => @daily_deal.to_param, :accounting_syndication_revenue_sharing_agreement => @agreement.attributes
      assert_redirected_to edit_daily_deal_syndication_revenue_sharing_agreement_path(@daily_deal)
      assert @daily_deal.reload.syndication_revenue_sharing_agreement
    end
  end
  
  context "update" do
    setup do
      @daily_deal = Factory(:daily_deal_for_syndication)
      @agreement = Factory(:syndication_revenue_sharing_agreement, :agreement => @daily_deal)
      @accountant = Factory(:accountant)
      login_as(@accountant)
    end
    
    should "redirect to the new page" do
      assert_equal 13, @daily_deal.syndication_revenue_sharing_agreement.syndication_fee_gross_percentage
      @agreement.syndication_fee_gross_percentage = 17
      post :update, :daily_deal_id => @daily_deal.to_param, :accounting_syndication_revenue_sharing_agreement => @agreement.attributes
      assert_redirected_to edit_daily_deal_syndication_revenue_sharing_agreement_path(@daily_deal)
      assert_equal 17, @daily_deal.reload.syndication_revenue_sharing_agreement.syndication_fee_gross_percentage
    end
  end
  
end
