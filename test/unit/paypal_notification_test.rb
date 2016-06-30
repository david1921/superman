require File.dirname(__FILE__) + "/../test_helper"

class PaypalNotificationTest < ActiveSupport::TestCase
  def test_dispatch_buy_now_with_duplicate
    gift_certificate = advertisers(:changos).gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3)
    paypal_notification = PaypalNotification.new(buy_now_raw_post(gift_certificate))

    assert_difference "PurchasedGiftCertificate.count" do
      paypal_notification.dispatch!
    end
    assert_equal 1, gift_certificate.purchased_gift_certificates.count

    assert_raise ActiveRecord::RecordInvalid do
      paypal_notification.dispatch!
    end
    assert_equal 1, gift_certificate.purchased_gift_certificates.count
  end
  
  def test_dispatch_chargeback
    gift_certificate = advertisers(:changos).gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3)
    purchased_gift_certificate = PurchasedGiftCertificate.create!({
      :gift_certificate => gift_certificate,
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
    })
    paypal_notification = PaypalNotification.new(chargeback_raw_post(purchased_gift_certificate))
                                                                
    assert_no_difference "PurchasedGiftCertificate.count" do
      paypal_notification.dispatch!
    end
    assert_equal "reversed", purchased_gift_certificate.reload.payment_status
    assert_equal paypal_notification.transaction_id, purchased_gift_certificate.payment_status_updated_by_txn_id
  end

  def test_dispatch_chargeback_reversal
    gift_certificate = advertisers(:changos).gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3)
    purchased_gift_certificate = PurchasedGiftCertificate.create!({
      :gift_certificate => gift_certificate,
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
      :payment_status => "reversed",
      :payment_status_updated_at => Time.zone.now,
      :payment_status_updated_by_txn_id => "38D93468JC7166634"
    })
    paypal_notification = PaypalNotification.new(chargeback_reversal_raw_post(purchased_gift_certificate))
                                                                
    assert_no_difference "PurchasedGiftCertificate.count" do
      paypal_notification.dispatch!
    end
    assert_equal "completed", purchased_gift_certificate.reload.payment_status
    assert_equal paypal_notification.transaction_id, purchased_gift_certificate.payment_status_updated_by_txn_id
  end
  
  def test_dispatch_refund
    gift_certificate = advertisers(:changos).gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3)
    purchased_gift_certificate = PurchasedGiftCertificate.create!({
      :gift_certificate => gift_certificate,
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
    })
    paypal_notification = PaypalNotification.new(refund_raw_post(purchased_gift_certificate))
                                                                
    assert_no_difference "PurchasedGiftCertificate.count" do
      paypal_notification.dispatch!
    end
    assert_equal "refunded", purchased_gift_certificate.reload.payment_status
    assert_equal paypal_notification.transaction_id, purchased_gift_certificate.payment_status_updated_by_txn_id
  end
  
  def test_dispatch_partial_refund_for_shopping_cart_purchase
    advertiser = Factory :advertiser
    first_cert = Factory :gift_certificate, :price => 3, :value => 10, :handling_fee => 0, :advertiser_id => advertiser.id
    second_cert = Factory :gift_certificate, :price => 4, :value => 12, :handling_fee => 0, :advertiser_id => advertiser.id
    
    first_purchased_cert, second_purchased_cert = [first_cert, second_cert].map do |gc|
      purchased_cert = Factory.build :purchased_gift_certificate,
                                     :gift_certificate_id => gc.id,
                                     :paypal_payment_date => "14:18:05 Jan 14, 2010 PST",
                                     :paypal_txn_id => "38D93468JC7166634",
                                     :paypal_receipt_id => "3625-4706-3930-0684",
                                     :paypal_payment_gross => gc.price,
                                     :paypal_payer_email => "superchristina@gmail.com",
                                     :paypal_payer_status => "verified",
                                     :paypal_invoice => "123456789",
                                     :paypal_address_name => "Christina Liao",
                                     :paypal_first_name => "Christina",
                                     :paypal_last_name => "Liao",
                                     :paypal_address_street => "1 Penny Lane",
                                     :paypal_address_city =>"London",
                                     :paypal_address_state => "KY",
                                     :paypal_address_zip => "40742",
                                     :paypal_address_status => "confirmed",
                                     :payment_status => "completed",
                                     :payment_status_updated_at => Time.zone.now,
                                     :payment_status_updated_by_txn_id => "38D93468JC7166634"
      purchased_cert.bought_with_shopping_cart!
      purchased_cert.save!
      purchased_cert
    end
    
    paypal_notification = PaypalNotification.new(shopping_cart_refund_raw_post([first_purchased_cert]))
    paypal_notification.dispatch!
    
    first_purchased_cert.reload
    second_purchased_cert.reload
    
    assert_equal "refunded", first_purchased_cert.payment_status
    assert_equal "FAKE-REFUND-TXID-1", first_purchased_cert.payment_status_updated_by_txn_id

    assert_equal "completed", second_purchased_cert.payment_status
    assert_equal "38D93468JC7166634", second_purchased_cert.payment_status_updated_by_txn_id
  end
  
  def test_dispatch_full_refund_for_shopping_cart_purchase
    advertiser = Factory :advertiser
    first_cert = Factory :gift_certificate, :price => 3, :value => 10, :handling_fee => 0, :advertiser_id => advertiser.id
    second_cert = Factory :gift_certificate, :price => 4, :value => 12, :handling_fee => 0, :advertiser_id => advertiser.id
    
    first_purchased_cert, second_purchased_cert = [first_cert, second_cert].map do |gc|
      purchased_cert = Factory.build :purchased_gift_certificate,
                                     :gift_certificate_id => gc.id,
                                     :paypal_payment_date => "14:18:05 Jan 14, 2010 PST",
                                     :paypal_txn_id => "38D93468JC7166634",
                                     :paypal_receipt_id => "3625-4706-3930-0684",
                                     :paypal_payment_gross => gc.price,
                                     :paypal_payer_email => "superchristina@gmail.com",
                                     :paypal_payer_status => "verified",
                                     :paypal_invoice => "123456789",
                                     :paypal_address_name => "Christina Liao",
                                     :paypal_first_name => "Christina",
                                     :paypal_last_name => "Liao",
                                     :paypal_address_street => "1 Penny Lane",
                                     :paypal_address_city =>"London",
                                     :paypal_address_state => "KY",
                                     :paypal_address_zip => "40742",
                                     :paypal_address_status => "confirmed",
                                     :payment_status => "completed",
                                     :payment_status_updated_at => Time.zone.now,
                                     :payment_status_updated_by_txn_id => "38D93468JC7166634"
      purchased_cert.bought_with_shopping_cart!
      purchased_cert.save!
      purchased_cert
    end
    
    paypal_notification = PaypalNotification.new(shopping_cart_refund_raw_post([first_purchased_cert, second_purchased_cert]))
    paypal_notification.dispatch!
    
    first_purchased_cert.reload
    second_purchased_cert.reload
    
    assert_equal "refunded", first_purchased_cert.payment_status
    assert_equal "FAKE-REFUND-TXID-1", first_purchased_cert.payment_status_updated_by_txn_id

    assert_equal "refunded", second_purchased_cert.payment_status
    assert_equal "FAKE-REFUND-TXID-1", second_purchased_cert.payment_status_updated_by_txn_id
  end
  
  def test_dispatch_shopping_cart_purchase_for_multiple_gift_certificates
    advertiser = Factory :advertiser
    first_cert = Factory :gift_certificate, :price => 3, :value => 10, :handling_fee => 0, :advertiser_id => advertiser.id
    second_cert = Factory :gift_certificate, :price => 4, :value => 12, :handling_fee => 0, :advertiser_id => advertiser.id
    
    paypal_notification = PaypalNotification.new(buy_now_using_cart_raw_post([first_cert, second_cert]))
  
    assert_equal 0, advertiser.purchased_gift_certificates.size
    assert_difference("PurchasedGiftCertificate.count", 2) { paypal_notification.dispatch! }
    assert_equal 2, advertiser.purchased_gift_certificates.size
    assert_equal [3, 4], advertiser.purchased_gift_certificates.map { |pgc| pgc.paypal_payment_gross }.sort
  end
  
  def test_dispatch_shopping_cart_purchase_for_gift_certificates_with_quantity_greater_than_one
    advertiser = Factory :advertiser
    first_cert = Factory :gift_certificate, :price => 3, :value => 10, :handling_fee => 0, :advertiser_id => advertiser.id
    second_cert = Factory :gift_certificate, :price => 4, :value => 12, :handling_fee => 0, :advertiser_id => advertiser.id
    
    paypal_notification = PaypalNotification.new(
      buy_now_using_cart_raw_post([first_cert, second_cert], { "quantity1" => "3", "mc_gross_1" => "9.00"}))
  
    assert_equal 0, advertiser.purchased_gift_certificates.size
    assert_difference("PurchasedGiftCertificate.count", 4) { paypal_notification.dispatch! }
    assert_equal 4, advertiser.purchased_gift_certificates.size
    assert_equal [3, 3, 3, 4], advertiser.purchased_gift_certificates.map { |pgc| pgc.paypal_payment_gross }.sort
  end
  
  private
  
  def raw_post(params)
    params.map { |key, val| "#{key}=#{CGI.escape(val)}" }.join("&")
  end
  
  def buy_now_using_cart_raw_post(gift_certificates, options={})
    item_data = {}
    gift_certificates.each_with_index do |gc, idx|
      num = idx + 1
      item_data["item_number#{num}"] = gc.id.to_s
      item_data["item_name#{num}"] = gc.item_name
      item_data["mc_handling#{num}"] = gc.handling_fee.to_s || "0"
      item_data["mc_shipping#{num}"] = "0"
      item_data["quantity#{num}"] = "1"
      item_data["mc_gross_#{num}"] = gc.price.to_s
    end

    raw_post({
      "mc_gross" => "90.50",
      "invoice" => "424-1293571149",
      "protection_eligibility" => "Ineligible",
      "tax" => "0.00",
      "payer_id" => "CBTPRYYSUT7MN",
      "payment_date" => "13:24:11 Dec 28, 2010 PST",
      "payment_status" => "Completed",
      "charset" => "windows-1252",
      "mc_shipping" => "0.00",
      "mc_handling" => "0.00",
      "first_name" => "Marianne",
      "mc_fee" => "2.56",
      "notify_version" => "3.0",
      "custom" => "PURCHASED_GIFT_CERTIFICATE",
      "payer_status" => "unverified",
      "business" => "kathleen.winer@analoganalytics.com",
      "num_cart_items" => "4",
      "verify_sign" => "AqBqA1nSf.CEBj1d5rbDP.LO-woKApMyUr56bTf.kW7uW6fLK8fcR36K",
      "payer_email" => "marianne.lontoc@analoganalytics.com",
      "txn_id" => "0FT64920WR581853E",
      "payment_type" => "instant",
      "last_name" => "Lontoc",
      "receiver_email" => "kathleen.winer@analoganalytics.com",
      "payment_fee" => "2.56",
      "receiver_id" => "6VN93T9HSVN58",
      "txn_type" => "cart",
      "mc_currency" => "USD",
      "residence_country" => "US",
      "receipt_id" => "5046-6591-0956-7840",
      "transaction_subject" => "PURCHASED_GIFT_CERTIFICATE",
      "payment_gross" => "90.50"
    }.merge(item_data).merge(options))
  end
  
  def buy_now_raw_post(gift_certificate, options={})
    raw_post({
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
      "payment_gross" => "%.2f" % gift_certificate.price,
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
      "item_number" => gift_certificate.item_number
    }.merge(options))
  end
  
  def chargeback_raw_post(purchased_gift_certificate, options={})
    raw_post({
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
      "item_number" => purchased_gift_certificate.gift_certificate.item_number,
      "custom" => "PURCHASED_GIFT_CERTIFICATE"
    }.merge(options))
  end

  def chargeback_reversal_raw_post(purchased_gift_certificate, options={})
    raw_post({
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
      "item_number" => purchased_gift_certificate.gift_certificate.item_number,
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
    }.merge(options))
  end
  
  def refund_raw_post(purchased_gift_certificate, options={})
    raw_post({
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
    }.merge(options))
  end
  
  def shopping_cart_refund_raw_post(purchased_gift_certificates, options={})
    item_data = {}
    purchased_gift_certificates.map(&:gift_certificate).each_with_index do |gc, idx|
      num = idx + 1
      item_data["item_number#{num}"] = gc.id.to_s
      item_data["item_name#{num}"] = gc.item_name
      item_data["mc_handling#{num}"] = gc.handling_fee.to_s || "0"
      item_data["mc_shipping#{num}"] = "0"
      item_data["quantity#{num}"] = "1"
      item_data["mc_gross_#{num}"] = gc.price.to_s
    end
    
    raw_post({
      "payment_status"=>"Refunded",
      "payer_email"=>purchased_gift_certificates.first.paypal_payer_email,
      "business"=>"demo_merchant@analoganalytics.com",
      "receiver_id"=>"6VN93T9HSVN58",
      "residence_country"=>"US",
      "tax"=>"0.00",
      "receiver_email"=>"demo_merchant@analoganalytics.com",
      "reason_code"=>"refund",
      "verify_sign"=>"AZxbwZ9bPVPFFf7hCCNemacLJwlCAnWfmg0hXJe8.MUBUzoLbdMtDdVn",
      "mc_currency"=>"USD",
      "txn_id"=>"FAKE-REFUND-TXID-1",
      "charset"=>"windows-1252",
      "payer_status"=>"verified",
      "notify_version"=>"3.0",
      "payment_date"=>"09:37:55 Jan. 17, 2010 PST",
      "mc_fee"=>"-1.00",
      "test_ipn"=>"1",
      "payment_type"=>"instant",
      "first_name"=>"Christina",
      "last_name"=>"Liao",
      "payer_id"=>"4DRVF75YKJG2A",
      "mc_gross"=>purchased_gift_certificates.map(&:paypal_payment_gross).sum.to_s,
      "parent_txn_id" => purchased_gift_certificates.first.paypal_txn_id,
      "custom"=>"PURCHASED_GIFT_CERTIFICATE"
    }.merge(item_data).merge(options))
  end
  
end
