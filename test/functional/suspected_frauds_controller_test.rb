require File.dirname(__FILE__) + "/../test_helper"

class SuspectedFraudsControllerTest < ActionController::TestCase

  context "#index" do
    
    setup do
      @deal = Factory :daily_deal
      @other_deal = Factory :daily_deal
      
      @publisher = @deal.publisher
      
      @p1 = Factory :daily_deal_purchase, :daily_deal => @deal
      @p2 = create_captured_purchase(@deal, :ip_address => "24.66.42.16",
                                            :credit_card_last_4 => "1234",
                                            :name => "Marcella Hazan",
                                            :email => "mhazan@example.com")
      @p3 = Factory :refunded_daily_deal_purchase, :daily_deal => @deal
      @p4 = Factory :captured_daily_deal_purchase, :daily_deal => @deal
      @p5 = Factory :captured_daily_deal_purchase, :daily_deal => @other_deal
      @p6 = Factory :captured_daily_deal_purchase, :daily_deal => @other_deal
      @p7 = create_captured_purchase(@deal, :ip_address => "24.16.12.9",
                                            :credit_card_last_4 => "6321",
                                            :name => "Bob Jones",
                                            :email => "bjones@example.com")
      @p8 = create_captured_purchase(@deal, :ip_address => "50.57.111.100",
                                            :credit_card_last_4 => "8171",
                                            :name => "Nigella Lawson",
                                            :email => "nlawson@example.com")
      @p9 = create_captured_purchase(@deal, :ip_address => "24.16.12.9",
                                            :credit_card_last_4 => "5321",
                                            :name => "Rachel Ray",
                                            :email => "rray@example.com")
      @p10 = create_captured_purchase(@deal, :ip_address => "24.16.12.9",
                                             :credit_card_last_4 => "5321",
                                             :name => "Julia Child",
                                             :email => "jchild@example.com")
      
      @sf1 = create_suspected_fraud(@p1, @p2)
      @sf2 = create_suspected_fraud(@p2, @p3)
      @sf3 = create_suspected_fraud(@p5, @p6)
      @sf4 = create_suspected_fraud(@p7, @p8)
      @sf5 = create_suspected_fraud(@p9, @p10)
      
      @admin = Factory :admin
      @publisher_user = Factory :user, :company => @publisher               
    end
    
    should "require authentication" do
      get :index, :publisher_id => @publisher.to_param
      assert_redirected_to new_session_path
    end
    
    should "response successfully for a full admin user" do
      login_as @admin
      get :index, :publisher_id => @publisher.to_param
      assert_response :success
    end
    
    should "not be accessible by a publisher user" do
      login_as @publisher_user
      get :index, :publisher_id => @publisher.to_param
      assert_redirected_to root_url
      assert_equal "Unauthorized access", flash[:notice]
    end
    
    should "assign only suspected fraud purchases in the Captured state to @suspected_fraud_purchases " +
           "ordered by ip address, then credit card last 4, then consumer name, then email, then created at" do
      login_as @admin
      get :index, :publisher_id => @publisher.to_param
      assert_response :success      
      assert_equal [@p9.id, @p7.id, @p2.id], assigns(:suspected_fraud_purchases).map(&:id)
    end
    
    should "render links to edit the purchases (for voiding or refunding)" do
      login_as @admin
      get :index, :publisher_id => @publisher.to_param
      assert_response :success      
      assert_select "a.edit-purchase", :count => 3
    end
    
    should "render successfully, even when a purchase has no payment attached to it" do
      @p2.daily_deal_payment.destroy
      login_as @admin
      get :index, :publisher_id => @publisher.to_param
      assert_response :success
      assert_select "a.edit-purchase", :count => 3
    end
    
  end
  
  def create_captured_purchase(deal, options)
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :ip_address => options[:ip_address]
    purchase.daily_deal_payment.update_attribute :credit_card_last_4, options[:credit_card_last_4]
    purchase.consumer.update_attributes :name => options[:name], :email => options[:email]
    purchase
  end
  
  def create_suspected_fraud(p1, p2)
    Factory :suspected_fraud, :suspect_daily_deal_purchase => p1, :matched_daily_deal_purchase => p2
  end

end
