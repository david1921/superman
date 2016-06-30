require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::SyndicationRevenueSplitsControllerTest < ActionController::TestCase
  
  context "access_denied" do
    
    context "unauthorized user" do
      setup do
        @daily_deal = Factory(:daily_deal_for_syndication)
        @syndication_revenue_sharing_agreement = Factory(:syndication_revenue_sharing_agreement, 
                                                         :agreement => @daily_deal)
        @user = Factory(:user)
        get :new, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the login page with message" do
        assert_redirected_to new_session_path
        assert_equal 'Unauthorized access', flash[:notice]
      end
    end
    
    context "user that does not belong to the source publisher" do
      setup do
        @daily_deal = Factory(:daily_deal_for_syndication)
        @user = Factory(:user)
        login_as(@user)
        get :edit, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the login page with message" do
        assert_redirected_to new_session_path
        assert_equal 'Only the source publisher can edit the syndication revenue split.', flash[:notice]
      end
    end
    
    context "admin" do
      setup do
        @daily_deal = Factory(:daily_deal_for_syndication)
        @syndication_revenue_sharing_agreement = Factory(:syndication_revenue_sharing_agreement, 
                                                         :agreement => @daily_deal)
        @user = Factory(:admin)
        login_as(@user)
        get :new, :daily_deal_id => @daily_deal.to_param
      end
      
      should "be logged in" do
        assert_response :success
        assert_template :edit
        assert_layout :application
        assert assigns(:daily_deal)
      end
    end
    
  end
  
  context "new" do
    
    context "happy path" do
      setup do
        @daily_deal = Factory(:daily_deal_for_syndication)
        @syndication_revenue_sharing_agreement = Factory(:syndication_revenue_sharing_agreement, 
                                                         :agreement => @daily_deal)
        @user = Factory(:user, :company => @daily_deal.publisher)
        login_as(@user)
        get :new, :daily_deal_id => @daily_deal.to_param
      end
    
      should "redirect to the login page with message" do
        assert_response :success
        assert_template :edit
        assert_layout :application
        assert assigns(:daily_deal)
        assert assigns(:syndication_revenue_split)
      end
    end
    
    context "deal that is not available for syndication" do
      setup do
        @daily_deal = Factory(:daily_deal)
        @user = Factory(:user, :company => @daily_deal.publisher)
        login_as(@user)
        get :new, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the edit daily deal page with message" do
        assert_redirected_to edit_daily_deal_path(@daily_deal)
        assert_equal 'Deal must be available for syndication.', flash[:error]
      end
    end
    
    context "without syndication revenue sharing agreement" do
      setup do
        @daily_deal = Factory(:daily_deal_for_syndication)
        @user = Factory(:user, :company => @daily_deal.publisher)
        login_as(@user)
        get :new, :daily_deal_id => @daily_deal.to_param
      end
      
      should "redirect to the edit daily deal page with message" do
        assert_redirected_to edit_daily_deal_path(@daily_deal)
        assert_equal 'A current syndication deal revenue sharing agreement must exist and be approved.', flash[:error]
      end
    end
    
  end
  
  context "create" do
    setup do
      @daily_deal = Factory(:daily_deal_for_syndication)
      @syndication_revenue_sharing_agreement = Factory(:syndication_revenue_sharing_agreement, 
                                                       :agreement => @daily_deal)
      @user = Factory(:user, :company => @daily_deal.publisher)
      @syndication_revenue_split = Factory.build(:syndication_gross_revenue_split)
      login_as(@user)
    end
    
    should "create a syndication revenue split for deal" do
      assert_nil @daily_deal.syndication_revenue_split
      assert @syndication_revenue_split.valid?, @syndication_revenue_split.errors.full_messages.join(", ")
      post :create, :daily_deal_id => @daily_deal.to_param, :daily_deals_syndication_revenue_split => @syndication_revenue_split.attributes
      assert_redirected_to edit_daily_deal_syndication_revenue_split_path(@daily_deal)
      assert @daily_deal.reload.syndication_revenue_split
    end
  end
  
  context "edit" do
    setup do
      @syndication_revenue_split = Factory.build(:syndication_gross_revenue_split)
      @daily_deal = Factory(:daily_deal_for_syndication, :syndication_revenue_split => @syndication_revenue_split)
      @syndication_revenue_sharing_agreement = Factory(:syndication_revenue_sharing_agreement, 
                                                       :agreement => @daily_deal)
      @user = Factory(:user, :company => @daily_deal.publisher)
      login_as(@user)
      get :edit, :daily_deal_id => @daily_deal.to_param
    end
    
    should "redirect to the login page with message" do
      assert_response :success
      assert_template :edit
      assert_layout :application
      assert assigns(:daily_deal)
      assert assigns(:syndication_revenue_split)
    end
  end
  
  context "update" do
    setup do
      @syndication_revenue_split = Factory.build(:syndication_gross_revenue_split)
      @daily_deal = Factory(:daily_deal_for_syndication, :syndication_revenue_split => @syndication_revenue_split)
      @syndication_revenue_sharing_agreement = Factory(:syndication_revenue_sharing_agreement, 
                                                       :agreement => @daily_deal)
      @user = Factory(:user, :company => @daily_deal.publisher)
      login_as(@user)
    end
    
    should "update a syndication revenue split for deal" do
      assert_equal 20, @daily_deal.syndication_revenue_split.source_gross_percentage
      assert_equal 30, @daily_deal.syndication_revenue_split.merchant_gross_percentage
      @syndication_revenue_split.source_gross_percentage = 17
      @syndication_revenue_split.merchant_gross_percentage = 33
      assert @syndication_revenue_split.valid?, @syndication_revenue_split.errors.full_messages.join(", ")
      
      post :update, :daily_deal_id => @daily_deal.to_param, :daily_deals_syndication_revenue_split => @syndication_revenue_split.attributes
      assert_redirected_to edit_daily_deal_syndication_revenue_split_path(@daily_deal)
      assert_equal 17.0, @daily_deal.reload.syndication_revenue_split.source_gross_percentage.to_f
      assert_equal 33.0, @daily_deal.syndication_revenue_split.merchant_gross_percentage.to_f
    end
  end
  
end