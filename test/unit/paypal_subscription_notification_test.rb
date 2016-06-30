require File.dirname(__FILE__) + "/../test_helper"

class PaypalSubscriptionNotificationTest < ActiveSupport::TestCase
  def test_handle_ipn_for_signup
    advertiser = publishers(:sdh_austin).advertisers.create!(
      :name => "Paid Advertiser",
      :paid => true,
      :subscription_rate_schedule => subscription_rate_schedules(:sdh_austin_rates)
    )
    signup_params = {
      "residence_country"=>"US",
      "business" => "demo_merchant@analoganalytics.com",
      "payer_email" => "demo@analoganalytics.com",
      "subscr_date" => "14:27:54 Mar 23, 2010 PDT",
      "period3" => "1 M",
      "receiver_email" => "demo_merchant@analoganalytics.com",
      "subscr_id" => "I-3LEXNNHKMA52",
      "invoice" => "#{advertiser.to_param}-1269379426",
      "verify_sign" => "AfW2QPUeV1nUr7tu2AoFHeqepSYzATn.Kr1U17ub8gqf8cx.EplCR1ze",
      "action" => "create",
      "txn_type" => "subscr_signup",
      "mc_currency" => "USD",
      "item_name" => "Changos Self Serve Coupon Account",
      "charset" => "windows-1252",
      "controller" => "paypal_notifications",
      "payer_status" => "verified",
      "notify_version" => "2.9",
      "recurring" => "1",
      "mc_amount3" => "23.99",
      "test_ipn" => "1",
      "first_name" => "Demo",
      "reattempt" => "1",
      "last_name" => "Buyer",
      "amount3" => "23.99",
      "payer_id" => "MZRXQPPPY7TDN",
      "item_number" => advertiser.to_param,
      "custom" => "ADVERTISER"
    }
    assert_difference 'PaypalSubscriptionNotification.count' do
      PaypalSubscriptionNotification.handle_ipn(signup_params)
    end
      
    assert_equal 1, advertiser.paypal_subscription_notifications(true).count
    paypal_subscription_notification = advertiser.paypal_subscription_notifications.first
    %w{ txn_type invoice mc_currency period3 recur_times subscr_id first_name last_name payer_email }.each do |attr|
      assert_equal signup_params[attr], paypal_subscription_notification.send("paypal_#{attr}"), attr
    end
    assert_equal 23.99, paypal_subscription_notification.paypal_mc_amount3
    assert_equal true, paypal_subscription_notification.paypal_recurring
    assert_equal true, paypal_subscription_notification.paypal_reattempt
    assert_nil paypal_subscription_notification.paypal_subscr_effective, "Subscription signup should not have an effective date"
    assert_equal Time.parse("Mar 23, 2010 21:27:54 UTC"), paypal_subscription_notification.paypal_subscr_date.utc

    assert advertiser.subscribed?, "Advertiser should be subscribed after subscription signup"
    assert !advertiser.active?, "Advertiser should be not active after subscription signup"
  end
end
