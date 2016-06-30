require File.dirname(__FILE__) + "/../test_helper"

class TritonLoyaltyTest < ActiveSupport::TestCase
  context "calling the Triton Loyalty sandbox" do
    setup do
      @triton_loyalty = TritonLoyalty.new(:partner_code => "analog", :shared_secret => "d8bl3a6n6l7t1cs")
      @site_code = "1753"
      @subscription_id = "6219"
    end
    
    context "with an existing consumer record" do
      setup do
        @consumer = Factory(:consumer, {
          :email => "system.test@analoganalytics.com",
          :first_name => "System", :last_name => "Test",
          :gender => "F",
          :zip_code => "90210",
          :mobile_number => "213-555-1212"
        })
        @local_record_id = "9876543210"
        @remote_record_id = "27473977"
      end
      
      should "return a valid Triton member ID from update_member" do
        assert_equal @remote_record_id, @triton_loyalty.update_member(@site_code, @consumer, @local_record_id)
      end
      
      should "return valid member data from find_member" do
        member_data = @triton_loyalty.find_member(@remote_record_id)
        
        assert_equal @site_code, member_data["siteID"]
        assert_equal "system.test@analoganalytics.com", member_data["email"]
        assert_equal "System", member_data["firstName"]
        assert_equal "Test", member_data["lastName"]
        assert_equal "F", member_data["gender"]
        assert_equal "90210     ", member_data["zipCode"]
        assert_equal "213-555-1212", member_data["mobilePhone"]
      end

      should "be able to disable a subscription via update_member_subscriptions" do
        assert_equal @remote_record_id, @triton_loyalty.update_member_subscriptions(@site_code, @remote_record_id, @subscription_id => false)
        assert_opted_out @site_code, @remote_record_id, @subscription_id
      end

      should "be able to enable a subscription via update_member_subscriptions" do
        assert_equal @remote_record_id, @triton_loyalty.update_member_subscriptions(@site_code, @remote_record_id, @subscription_id => true)
        assert_opted_in @site_code, @remote_record_id, @subscription_id
      end
    end
  end
  
  private
  
  def assert_subscription_opt_in site_code, remote_record_id, subscription_id, opt_in
    subscription_data = @triton_loyalty.get_site_subscriptions(@site_code, @remote_record_id)
    
    assert_not_nil(subscription_data = subscription_data["SubscriptionGroups"], "Should have a SubscriptionGroups key")
    assert_not_nil(subscription_data = subscription_data["SubscriptionGroup"], "Should have a SubscriptionGroup subkey")
    assert_not_nil(subscription_data = subscription_data["Subscriptions"], "Should have a Subscriptions subkey")
    assert_not_nil(subscription_data = subscription_data["SubscriptionInfo"], "Should have a SubscriptionInfo subkey")
    
    assert_equal subscription_id, subscription_data["SubscriptionID"]
    assert_equal opt_in, subscription_data["OptIn"]
  end
  
  def assert_opted_in site_code, remote_record_id, subscription_id
    assert_subscription_opt_in site_code, remote_record_id, subscription_id, "true"
  end

  def assert_opted_out site_code, remote_record_id, subscription_id
    assert_subscription_opt_in site_code, remote_record_id, subscription_id, "false"
  end
end
