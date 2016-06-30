require File.dirname(__FILE__) + "/../test_helper"

class SignupsControllerTest < ActionController::TestCase
  test "create with get" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
    publisher = daily_deal.publisher
    discount = Factory(:discount, :code => "SIGNUP_CREDIT", :publisher => publisher)
    
    get :create, :publisher_id => publisher.label, 
                 :email => "chih.chow@example.com", 
                 :utm_campaign => "tenoffpurchase-houston", 
                 :utm_medium => "DOTD-thrive-houston", 
                 :utm_source => "newsletter-houston"
    consumer = assigns(:consumer)
    assert_not_nil consumer, "@consumer"
    assert consumer.errors.empty?, consumer.errors.full_messages.join(", ")
    assert_redirected_to(thank_you_publisher_signups_path(
      publisher.label, 
      :email => "chih.chow@example.com", 
      :discount => "10.0",
      :email => "chih.chow@example.com", 
      :utm_campaign => "tenoffpurchase-houston", 
      :utm_medium => "DOTD-thrive-houston", 
      :utm_source => "newsletter-houston"
    ))
  end

  test "create with get and referral_code coookie" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
    publisher = daily_deal.publisher
    discount = Factory(:discount, :code => "SIGNUP_CREDIT", :publisher => publisher)
    
    @request.cookies["referral_code"] = "abcd1234"
    get :create, :publisher_id => publisher.label, 
                 :email => "chih.chow@example.com", 
                 :utm_campaign => "tenoffpurchase-houston", 
                 :utm_medium => "DOTD-thrive-houston", 
                 :utm_source => "newsletter-houston"
    consumer = assigns(:consumer)
    assert_not_nil consumer, "@consumer"
    assert_equal "abcd1234", consumer.referral_code
    assert consumer.errors.empty?, consumer.errors.full_messages.join(", ")
    assert_redirected_to(thank_you_publisher_signups_path(
      publisher.label, 
      :email => "chih.chow@example.com", 
      :discount => "10.0",
      :email => "chih.chow@example.com", 
      :utm_campaign => "tenoffpurchase-houston", 
      :utm_medium => "DOTD-thrive-houston", 
      :utm_source => "newsletter-houston"
    ))
  end
    
  test "create with invalid" do
    daily_deal = Factory(:daily_deal, :start_at => Time.zone.now.beginning_of_day, :hide_at => 2.days.from_now)
    publisher = daily_deal.publisher
    discount = Factory(:discount, :code => "SIGNUP_CREDIT", :publisher => publisher)
    
    get :create, :publisher_id => publisher.label, :email => "chih.chow"
    consumer = assigns(:consumer)
    assert_not_nil consumer, "@consumer"
    assert consumer.errors.any?, "Should have errors"
    assert_redirected_to error_publisher_signups_path(publisher.label)
  end
  
  test "thank_you" do
    publisher = Factory(:publisher, :label => "nydailynews")
    daily_deal = Factory.build(:daily_deal, :publisher => publisher, :advertiser => Factory(:advertiser, :publisher => publisher))
    consumer = Consumer.build_unactivated(publisher, :email => "ken.kalb@mac.com")
    consumer.save!
    
    get :thank_you, :publisher_id => publisher.label, :email => "ken.kalb@mac.com", :discount => 10
    assert_response :success
    assert_theme_layout "nydailynews/layouts/daily_deals"
  end

  test "invalid thank_you" do
    publisher = Factory(:publisher)
    get :thank_you, :publisher_id => publisher.label
    assert_redirected_to error_publisher_signups_path(publisher.label)
  end

  test "show error page" do
    publisher = Factory(:publisher)
    get :error, :publisher_id => publisher.label
    assert_response :success
  end
end
