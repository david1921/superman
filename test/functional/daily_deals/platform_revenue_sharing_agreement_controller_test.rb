require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::PlatformRevenueSharingAgreementControllerTest < ActionController::TestCase
  context "access_denied" do
    setup do
      @daily_deal = Factory(:daily_deal)
    end
    
    context "user without admin or accountant privileges" do
      setup do
        @user = Factory(:user)
        login_as(@user)
        get :new, :daily_deal_id => @daily_deal.to_param
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
        get :new, :daily_deal_id => @daily_deal.to_param
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
        get :new
      end
      
      should "redirect to the login page" do
        assert_redirected_to new_session_path
        assert_equal 'Unauthorized access', flash[:notice]
      end
    end
  end

  context "new" do
    setup do
      @accountant = Factory(:accountant)
      @daily_deal = Factory(:daily_deal)
      login_as(@accountant)
      get :new, :daily_deal_id => @daily_deal.to_param
    end
    
    should "redirect to the new page" do
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert assigns(:daily_deal)
    end
  end

  context "create" do
    setup do
      @accountant = Factory(:accountant)
      @daily_deal = Factory(:daily_deal)
      @agreement = Factory.build(:platform_revenue_sharing_agreement)
      login_as(@accountant)
    end

    should "redirect to edit on success" do
      assert_difference "Accounting::PlatformRevenueSharingAgreement.count" do
        post :create, :daily_deal_id => @daily_deal.to_param,
        :accounting_platform_revenue_sharing_agreement => @agreement.attributes
      end
      @daily_deal.reload
      assert_not_nil @daily_deal.platform_revenue_sharing_agreement
      assert_redirected_to edit_daily_deal_platform_revenue_sharing_agreement_path(@daily_deal)
    end

    should "render edit page on failure" do
      post :create, :daily_deal_id => @daily_deal.to_param,
        :accounting_platform_revenue_sharing_agreement => {}
      assert_template :edit
      assert assigns(:platform_revenue_sharing_agreement)
    end
  end

  context "update" do
    setup do
      @accountant = Factory(:accountant)
      @daily_deal = Factory(:daily_deal)
      @agreement  = Factory(:platform_revenue_sharing_agreement, :agreement => @daily_deal)
      login_as(@accountant)
    end

    should "redirect to edit on success" do
      post :update, :daily_deal_id => @daily_deal.to_param,
        :accounting_platform_revenue_sharing_agreement => { :platform_fee_gross_percentage => 4 }
      assert_equal 4.0, @daily_deal.reload.platform_revenue_sharing_agreement.platform_fee_gross_percentage.to_f
      assert_redirected_to edit_daily_deal_platform_revenue_sharing_agreement_path(@daily_deal)
    end

    should "render edit on failure" do
      post :update, :daily_deal_id => @daily_deal.to_param,
        :accounting_platform_revenue_sharing_agreement => { :platform_fee_gross_percentage => nil, :platform_fee_net_percentage => nil}
      assert_template :edit
      assert assigns(:platform_revenue_sharing_agreement)
    end
  end

  context "edit" do
    setup do
      @accountant = Factory(:accountant)
      @daily_deal = Factory(:daily_deal)
      @agreement = Factory(:platform_revenue_sharing_agreement, :agreement => @daily_deal, :platform_fee_gross_percentage => 5)
      login_as(@accountant)
      get :edit, :daily_deal_id => @daily_deal.to_param
    end

    should "have agreement attributes filled out" do
      assert_response :success
      assert_template :edit
      assert_equal @daily_deal, assigns(:daily_deal)
      assert_equal @agreement, assigns(:platform_revenue_sharing_agreement)
      assert_select "input[name='accounting_platform_revenue_sharing_agreement[platform_fee_gross_percentage]']"
    end
  end
end
