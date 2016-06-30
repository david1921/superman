require File.dirname(__FILE__) + "/../test_helper"

class PaypalNotificationsControllerTest < ActionController::TestCase
  setup :setup_certificates, :clear_deliveries
  
  def setup_certificates
    @gift_certificate = advertisers(:changos).gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3)
  end
  
  def clear_deliveries
    ActionMailer::Base.deliveries.clear
  end
  
  def test_create_with_acknowledged_buy_now
    PaypalNotification.any_instance.expects(:acknowledge).returns true
    PaypalNotification.any_instance.expects(:params).at_least_once.returns buy_now_ipn_params
    
    assert_difference 'PurchasedGiftCertificate.count' do
      post :create
      assert_response :success
    end
    assert_equal 1, @gift_certificate.purchased_gift_certificates.count
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_create_with_unacknowledged_buy_now
    PaypalNotification.any_instance.expects(:acknowledge).returns false
    PaypalNotification.any_instance.expects(:params).at_least(0).returns buy_now_ipn_params
    
    assert_raise RuntimeError do
      post :create
    end
    assert_equal 0, PurchasedGiftCertificate.count
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
  
  def test_create_with_acknowledged_chargeback
    purchased_gift_certificate = create_purchased_gift_certificate
    ActionMailer::Base.deliveries.clear
    
    PaypalNotification.any_instance.expects(:acknowledge).returns true
    PaypalNotification.any_instance.expects(:params).at_least_once.returns chargeback_ipn_params(purchased_gift_certificate)

    assert_no_difference 'PurchasedGiftCertificate.count' do
      post :create
      assert_response :success
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_equal "reversed", purchased_gift_certificate.reload.payment_status
  end

  def test_create_with_unacknowledged_chargeback
    purchased_gift_certificate = create_purchased_gift_certificate
    ActionMailer::Base.deliveries.clear
    
    PaypalNotification.any_instance.expects(:acknowledge).returns false
    PaypalNotification.any_instance.expects(:params).at_least(0).returns chargeback_ipn_params(purchased_gift_certificate)

    assert_raise RuntimeError do
      post :create
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_equal "completed", purchased_gift_certificate.reload.payment_status
  end

  def test_create_with_acknowledged_chargeback_reversal
    purchased_gift_certificate = create_purchased_gift_certificate
    purchased_gift_certificate.update_attributes! :payment_status => "reversed"
    ActionMailer::Base.deliveries.clear
    
    PaypalNotification.any_instance.expects(:acknowledge).returns true
    PaypalNotification.any_instance.expects(:params).at_least_once.returns chargeback_reversal_ipn_params(purchased_gift_certificate)

    assert_no_difference 'PurchasedGiftCertificate.count' do
      post :create
      assert_response :success
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_equal "completed", purchased_gift_certificate.reload.payment_status
  end

  def test_create_with_unacknowledged_chargeback_reversal
    purchased_gift_certificate = create_purchased_gift_certificate
    purchased_gift_certificate.update_attributes! :payment_status => "reversed"
    ActionMailer::Base.deliveries.clear
    
    PaypalNotification.any_instance.expects(:acknowledge).returns false
    PaypalNotification.any_instance.expects(:params).at_least(0).returns chargeback_reversal_ipn_params(purchased_gift_certificate)

    assert_raise RuntimeError do
      post :create
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_equal "reversed", purchased_gift_certificate.reload.payment_status
  end

  def test_create_with_acknowledged_refund
    purchased_gift_certificate = create_purchased_gift_certificate
    ActionMailer::Base.deliveries.clear
    
    PaypalNotification.any_instance.expects(:acknowledge).returns true
    PaypalNotification.any_instance.expects(:params).at_least_once.returns refund_ipn_params(purchased_gift_certificate)

    assert_no_difference 'PurchasedGiftCertificate.count' do
      post :create
      assert_response :success
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_equal "refunded", purchased_gift_certificate.reload.payment_status
  end

  def test_create_with_unacknowledged_refund
    purchased_gift_certificate = create_purchased_gift_certificate
    ActionMailer::Base.deliveries.clear
    
    PaypalNotification.any_instance.expects(:acknowledge).returns false
    PaypalNotification.any_instance.expects(:params).at_least(0).returns refund_ipn_params(purchased_gift_certificate)

    assert_raise RuntimeError do
      post :create
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_equal "completed", purchased_gift_certificate.reload.payment_status
  end

  def test_create_with_subscription_start
    advertiser = publishers(:sdh_austin).advertisers.create!(
      :name => "Paid Advertiser",
      :paid => true,
      :subscription_rate_schedule => subscription_rate_schedules(:sdh_austin_rates)
    )
    PaypalNotification.any_instance.expects(:acknowledge).returns true
    PaypalNotification.any_instance.expects(:params).at_least_once.returns subscription_start_ipn_params(advertiser)

    assert_difference 'advertiser.paypal_subscription_notifications.starting.count' do
      post :create
    end
  end

  def test_create_with_paypal_configuration_in_production_mode
    PaypalConfiguration.expects(:use_sandbox?).at_least_once.returns(false)
    PaypalNotification.expects(:ipn_url=).with(PaypalConfiguration.production_ipn_url)

    PaypalNotification.any_instance.expects(:acknowledge).returns true
    PaypalNotification.any_instance.expects(:params).at_least_once.returns buy_now_ipn_params
    
    assert_difference 'PurchasedGiftCertificate.count' do
      post :create
      assert_response :success
    end
    assert_equal 1, @gift_certificate.purchased_gift_certificates.count
    assert_equal 1, ActionMailer::Base.deliveries.size

  end

    def test_create_with_paypal_configuration_NOT_in_production_mode
    PaypalConfiguration.expects(:use_sandbox?).at_least_once.returns(true)
    PaypalNotification.expects(:ipn_url=).never

    PaypalNotification.any_instance.expects(:acknowledge).returns true
    PaypalNotification.any_instance.expects(:params).at_least_once.returns buy_now_ipn_params
    
    assert_difference 'PurchasedGiftCertificate.count' do
      post :create
      assert_response :success
    end
    assert_equal 1, @gift_certificate.purchased_gift_certificates.count
    assert_equal 1, ActionMailer::Base.deliveries.size

  end
  
  private
  
  def create_purchased_gift_certificate
    PurchasedGiftCertificate.create!(
      :gift_certificate => @gift_certificate,
      :paypal_payment_date => "14:18:05 Jan 14, 2010 PST",
      :paypal_txn_id => "38D93468JC7166634",
      :paypal_receipt_id => "3625-4706-3930-0684",
      :paypal_invoice => "123456789",
      :paypal_payment_gross => "23.99",
      :paypal_payer_email => "higgins@london.com",
      :paypal_payer_status => "verified",
      :paypal_address_name => "Henry Higgins",
      :paypal_first_name => "Henry",
      :paypal_last_name => "Higgins",
      :paypal_address_street => "1 Penny Lane",
      :paypal_address_city =>"London",
      :paypal_address_state => "KY",
      :paypal_address_zip => "40742",
      :paypal_address_status => "confirmed",
      :payment_status => "completed",
      :payment_status_updated_at => Time.zone.now,
      :payment_status_updated_by_txn_id => "38D93468JC7166634"
    )
  end
  
  def buy_now_ipn_params(options={})
    ipn_params = {
      "protection_eligibility" => "Eligible",
      "tax" => "0.00",
      "payment_status" => "Completed",
      "address_name" => "Henry Higgins",
      "business" => "demo_merchant@analoganalytics.com",
      "address_country" => "United States",
      "address_city" => "London",
      "payer_email" => "tbuscher@gmail.com",
      "receiver_id" => "96GH9L6W5QGLA",
      "residence_country" => "US",
      "handling_amount" => "0.00",
      "payment_gross" => "%.2f" % @gift_certificate.price,
      "receiver_email" => "demo_merchant@analoganalytics.com",
      "invoice" => "3-1263504293",
      "address_street" => "1 Penny Lane",
      "verify_sign" => "AmHf4UgW-l1HczXnT5wIeQmi8WIxA27fsg2vin5EA9DOGpG2mn9K-DQF",
      "action" => "create",
      "address_zip" => "40742",
      "quantity" => "1",
      "txn_type" => "web_accept",
      "mc_currency" => "USD",
      "transaction_subject" => "GC",
      "charset" => "windows-1252",
      "address_country_code" => "US",
      "txn_id" => "38D93468JC7166634",
      "item_name" => "$25.00 Anastasio's Ristorante Deal Certificate",
      "controller" => "paypal_notifications",
      "notify_version" => "2.8",
      "payer_status" => "verified",
      "address_state" => "KY",
      "payment_fee" => "1.00",
      "receipt_id" => "3625-4706-3930-0684",
      "address_status" => "confirmed",
      "payment_date" => "14:18:05 Jan 14, 2010 PST",
      "mc_fee" => "1.00",
      "shipping" => "0.00",
      "first_name" => "Henry",
      "payment_type" => "instant",
      "mc_gross" => "23.99",
      "payer_id" => "4DRVF75YKJG2A",
      "last_name" => "Higgins",
      "custom" => "PURCHASED_GIFT_CERTIFICATE",
      "item_number" => @gift_certificate.item_number
    }.merge(options)
  end
  
  def chargeback_ipn_params(purchased_gift_certificate, options={})
    ipn_params = {
      "payment_status"=>"Reversed",
      "payer_email" => "tbuscher@gmail.com",
      "business" => "demo_merchant@analoganalytics.com",
      "receiver_id" => "96GH9L6W5QGLA",
      "residence_country"=>"US",
      "receiver_email" => "demo_merchant@analoganalytics.com",
      "reason_code"=>"chargeback",
      "verify_sign"=>"AFcWxV21C7fd0v3bYYYRCpSSRl31Au9CoiAZqdJCsqSW-qvVKUP.cBug",
      "quantity"=>"1",
      "mc_currency"=>"USD",
      "txn_id"=>"301181649",
      "parent_txn_id" => purchased_gift_certificate.paypal_txn_id,
      "charset"=>"windows-1252",
      "payer_status"=>"verified",
      "notify_version"=>"2.1",
      "receipt_id" => "3625-4706-3930-0684",
      "payment_date" => "14:18:05 Jan 14, 2010 PST",
      "shipping" => "0.00",
      "mc_fee" => "-1.00",
      "payment_type"=>"instant",
      "first_name"=>"Henry",
      "last_name"=>"Higgins",
      "payer_id" => "4DRVF75YKJG2A",
      "mc_gross" => "-23.99",
      "item_number" => @gift_certificate.item_number,
      "custom" => "PURCHASED_GIFT_CERTIFICATE"
    }.merge(options)
  end

  def chargeback_reversal_ipn_params(purchased_gift_certificate, options={})
    ipn_params = {
      "payment_status" => "Canceled_Reversal",
      "reason_code" => "other",
      "invoice" => "3-1263504293",
      "verify_sign" => "A45-n-qFAO8WJ7OWDZnKMaxnYpdVALmICWN0.QoluUwKGFl4KYGstHGm",
      "txn_id" => "571181717",
      "parent_txn_id" => purchased_gift_certificate.paypal_txn_id,
      "address_street" => "1 Penny Lane",
      "charset"=>"windows-1252",
      "payer_status"=>"verified",
      "address_state"=>"CA",
      "notify_version"=>"2.1",
      "payment_date" => "14:18:05 Jan 14, 2010 PST",
      "address_status" => "confirmed",
      "shipping" => "0.00",
      "mc_fee" => "1.00",
      "payment_type"=>"instant",
      "first_name"=>"Henry",
      "last_name"=>"Higgins",
      "payer_id" => "4DRVF75YKJG2A",
      "mc_gross" => "23.99",
      "item_number" => @gift_certificate.item_number,
      "custom"=>"PURCHASED_GIFT_CERTIFICATE",
      "payer_email" => "tbuscher@gmail.com",
      "address_name" => "Henry Higgins",
      "address_country"=>"United States",
      "address_city" => "London",
      "business" => "demo_merchant@analoganalytics.com",
      "receiver_id" => "96GH9L6W5QGLA",
      "residence_country"=>"US",
      "receiver_email" => "demo_merchant@analoganalytics.com",
      "address_zip" => "40742",
      "quantity"=>"1",
      "mc_currency"=>"USD",
      "address_country_code"=>"US",
      "item_name" => "$25.00 Anastasio's Ristorante Deal Certificate"
    }.merge(options)
  end
  
  def refund_ipn_params(purchased_gift_certificate, options={})
    ipn_params = {
      "payment_status"=>"Refunded",
      "payer_email"=>"higgins@london.com",
      "business"=>"demo_merchant@analoganalytics.com",
      "receiver_id"=>"96GH9L6W5QGLA",
      "residence_country"=>"US",
      "tax"=>"0.00",
      "receiver_email"=>"demo_merchant@analoganalytics.com",
      "reason_code"=>"refund",
      "verify_sign"=>"A8R-A6Q-kz6GCaa1nyijplzfLYsEAkDQHiJHRx.uFgWBiq76JP-pKiJj",
      "quantity"=>"1",
      "mc_currency"=>"USD",
      "txn_type"=>"web_accept",
      "txn_id"=>"551181737",
      "charset"=>"windows-1252", "payer_status"=>"verified",
      "notify_version"=>"2.1",
      "payment_date"=>"09:37:55 Jan. 17, 2010 PST",
      "shipping"=>"0.00",
      "mc_fee"=>"-1.00",
      "test_ipn"=>"1",
      "payment_type"=>"instant",
      "first_name"=>"Henry",
      "last_name"=>"Higgins",
      "payer_id"=>"4DRVF75YKJG2A",
      "mc_gross"=>"-23.99",
      "parent_txn_id" => purchased_gift_certificate.paypal_txn_id,
      "custom"=>"PURCHASED_GIFT_CERTIFICATE"
    }.merge(options)
  end
  
  def subscription_start_ipn_params(advertiser, options={})
    ipn_params = {
      "residence_country"=>"US",
      "business" => "demo_merchant@analoganalytics.com",
      "payer_email" => "demo@analoganalytics.com",
      "subscr_date" => "14:27:54 Mar 23, 2010 PDT",
      "period3" => "1 M",
      "receiver_email" => "demo_merchant@analoganalytics.com",
      "subscr_id" => "I-3LEXNNHKMA52",
      "invoice" => "AD-#{advertiser.to_param}-1",
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
    }.merge(options)
  end
end                 

