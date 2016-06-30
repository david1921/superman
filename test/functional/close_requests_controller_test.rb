require File.dirname(__FILE__) + "/../test_helper"

class CloseRequestsControllerTest < ActionController::TestCase

  context "creating" do
    setup do
      @publisher = Factory(:publisher, :self_serve => true)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher, :listing => "DT-123456")
      assert_equal false, @daily_deal.sold_out?, "Deal should not be sold out"
    end

    should "be successful with a valid user" do
      user = Factory(:user, :company => @publisher)
      login_with_basic_auth(:login => user.login, :password => "test")
      put :create, :label => @publisher.label, :listing => @daily_deal.listing
      assert_response :success
    end

    should "not be successful with an invalid user" do
      login_with_basic_auth(:login => "i_dont_exist", :password => "fail")
      put :create, :id => @publisher.id, :daily_deal_id => @daily_deal.id
      assert_response 401
    end

    should "not allow a user to modify a deal that is not theirs" do
      user = Factory(:user, :company => Factory(:publisher))
      login_with_basic_auth(:login => user.login, :password => "test")
      put :create, :label => @publisher.label, :listing => @daily_deal.listing
      assert_response 401
    end

    should "make deal sold out" do
      user = Factory(:user, :company => @publisher)
      login_with_basic_auth(:login => user.login, :password => "test")
      put :create, :label => @publisher.label, :listing => @daily_deal.listing
      @daily_deal.reload
      assert @daily_deal.sold_out_via_third_party, "Deal should now be sold out"
    end
  end

end
