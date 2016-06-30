require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Accounting::PlatformRevenueSharingAgreementsControllerPublisherTest

class Accounting::PlatformRevenueSharingAgreementsControllerPublisherTest < ActionController::TestCase
  
  def setup
    @controller = Accounting::PlatformRevenueSharingAgreementsController.new
  end
  
  context "access_denied" do
    setup do
      @publisher = Factory(:publisher)
    end
    
    context "user without admin or accountant privileges" do
      setup do
        @user = Factory(:user)
        login_as(@user)
        get :new, :publisher_id => @publisher
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
        get :new, :publisher_id => @publisher
      end
      
      should "redirect to the login page" do
        assert_redirected_to new_session_path
      end
      
      should "set a flash notice" do
        assert_equal 'Unauthorized access', flash[:notice]
      end
    end
    
    context "accountant user without publishing group" do
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
      @publisher = Factory(:publisher)
      login_as(@accountant)
      get :new, :publisher_id => @publisher.to_param
    end
    
    should "redirect to the new page" do
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert assigns(:publisher)
      assert_nil assigns(:publishing_group)
      assert_nil flash[:notice]
    end
  end
  
  context "create" do
    setup do
      @accountant = Factory(:accountant)
      @publisher = Factory(:publisher)
      @agreement = Factory.build(:platform_revenue_sharing_agreement)
      login_as(@accountant)
    end
    
    should "create agreement" do
      assert_difference 'Accounting::PlatformRevenueSharingAgreement.count' do
        post :create, :publisher_id => @publisher.to_param, :accounting_platform_revenue_sharing_agreement => @agreement.attributes
      end
      assert_redirected_to edit_publisher_platform_revenue_sharing_agreement_path(@publisher, @publisher.platform_revenue_sharing_agreements.first)
      assert_equal "Created platform revenue sharing agreement.", flash[:notice]
    end
  end
  
  context "update" do
    setup do
      @accountant = Factory(:accountant)
      @publisher = Factory(:publisher)
      @agreement = Factory(:platform_revenue_sharing_agreement, :agreement => @publisher)
      login_as(@accountant)
    end
    
    should "update agreement" do
      post :update,
           :publisher_id => @publisher.to_param, 
           :id => @agreement.to_param, 
           :accounting_platform_revenue_sharing_agreement => {'platform_fee_gross_percentage' => 22}
      assert_equal 22.0, @agreement.reload.platform_fee_gross_percentage.to_f
      assert_redirected_to edit_publisher_platform_revenue_sharing_agreement_path(@publisher, @agreement)
      assert_equal "Updated platform revenue sharing agreement.", flash[:notice]
    end
  end
  
  context "index" do
    setup do
      @accountant = Factory(:accountant)
      @publisher = Factory(:publisher)
      @agreement_1 = Factory(:platform_revenue_sharing_agreement, :effective_date => 3.days.ago, :agreement => @publisher)
      @agreement_2 = Factory(:platform_revenue_sharing_agreement, :effective_date => 7.days.from_now, :agreement => @publisher)
      login_as(@accountant)
    end
    
    should "show agreements" do
      post :index, :publisher_id => @publisher.to_param
      assert_response :success
      assert_template :index
      assert_layout :application
    end
  end
  
  context "destroy" do
    setup do
      @accountant = Factory(:accountant)
      @publisher = Factory(:publisher)
      @agreement = Factory(:platform_revenue_sharing_agreement, :agreement => @publisher)
      login_as(@accountant)
    end
    
    should "delete agreement" do
      assert_difference 'Accounting::PlatformRevenueSharingAgreement.count', -1 do
        post :destroy, :publisher_id => @publisher.to_param, :id => @agreement.to_param
      end
      assert_redirected_to publisher_platform_revenue_sharing_agreements_path(@publisher)
      assert_equal "Deleted platform revenue sharing agreement.", flash[:notice]
    end
  end
  
end