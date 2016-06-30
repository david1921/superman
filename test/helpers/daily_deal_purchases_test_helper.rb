module DailyDealPurchasesTestHelper
  def stub_flash_analytics_tag_with(daily_deal_purchase)
   @controller.stubs(:flash).returns({
      :analytics_tag => {
        :value    => daily_deal_purchase.amount,
        :quantity => daily_deal_purchase.quantity,
        :item_id  => daily_deal_purchase.daily_deal_id,
        :sale_id  => daily_deal_purchase.id
      }
    })
  end

  def post_create_with_consumer_params(daily_deal, params = {}, ddp_params = {})
    post :create, :daily_deal_id => daily_deal.to_param, :consumer => params, :daily_deal_purchase => { :quantity => "1", :gift => "0" }.merge(ddp_params)
  end

  def partially_refunded_purchase(daily_deal, purchase_quantity, refund_amount)
    purchase = Factory(:captured_daily_deal_purchase, :quantity => purchase_quantity, :daily_deal => daily_deal)
    expect_braintree_partial_refund(purchase, refund_amount)
    purchase.partial_refund!(Factory(:admin), [purchase.daily_deal_certificates.first.id.to_s])
    refunded_at = daily_deal.start_at + 6.hours
    purchase.update_attributes!(:refunded_at => refunded_at)
    purchase.daily_deal_certificates.first.update_attributes!(:refunded_at => refunded_at)
    assert purchase.partially_refunded?
    purchase
  end

  def build_with_attributes(attrs)
    DailyDealPurchase.new.tap do |daily_deal_purchase|
      attrs.each do |key, val|
        daily_deal_purchase.send("#{key}=", val)
      end
    end
  end

  def buy_now_ipn_params(options={})
    ipn_params = {
      "protection_eligibility" => "Eligible",
      "tax" => "0.00",
      "payment_status" => "Completed",
      "business" => "demo_merchant@analoganalytics.com",
      "payer_email" => "tbuscher@gmail.com",
      "receiver_id" => "96GH9L6W5QGLA",
      "residence_country"=>"US",
      "handling_amount" => "0.00",
      "payment_gross" => "%.2f" % (@valid_attributes[:quantity] * @valid_attributes[:daily_deal].price),
      "receiver_email" => "demo_merchant@analoganalytics.com",
      "verify_sign" => "AmHf4UgW-l1HczXnT5wIeQmi8WIxA27fsg2vin5EA9DOGpG2mn9K-DQF",
      "action" => "create",
      "quantity" => @valid_attributes[:quantity].to_s,
      "txn_type" => "web_accept",
      "mc_currency" => "USDD",
      "transaction_subject" => "GC",
      "charset" => "windows-1252",
      "txn_id" => "38D93468JC7166634",
      "item_name" => @valid_attributes[:daily_deal].description,
      "controller" => "paypal_notifications",
      "notify_version" => "2.8",
      "payer_status" => "verified",
      "payment_fee" => "1.00",
      "receipt_id" => "3625-4706-3930-0684",
      "payment_date" => "12:34:56 Jan 01, 2010 PST",
      "mc_fee" => "1.00",
      "shipping" => "0.00",
      "payment_type" => "instant",
      "mc_gross" => "%.2f" % (@valid_attributes[:quantity] * @valid_attributes[:daily_deal].price),
      "payer_id" => "4DRVF75YKJG2A",
      "custom" => "DAILY_DEAL_PURCHASE"
    }.merge(options)
  end

  def chargeback_ipn_params(daily_deal_purchase, options={})
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
      "parent_txn_id" => daily_deal_purchase.payment_gateway_id,
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
      "item_number" => daily_deal_purchase.paypal_item,
      "custom" => "DAILY_DEAL_PURCHASE"
    }.merge(options)
  end

  def chargeback_reversal_ipn_params(daily_deal_purchase, options={})
    ipn_params = {
      "payment_status" => "Canceled_Reversal",
      "reason_code" => "other",
      "invoice" => "3-1263504293",
      "verify_sign" => "A45-n-qFAO8WJ7OWDZnKMaxnYpdVALmICWN0.QoluUwKGFl4KYGstHGm",
      "txn_id" => "571181717",
      "parent_txn_id" => daily_deal_purchase.payment_gateway_id,
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
      "item_number" => daily_deal_purchase.paypal_item,
      "custom"=>"DAILY_DEAL_PURCHASE",
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

  def refund_ipn_params(daily_deal_purchase, options={})
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
      "parent_txn_id" => daily_deal_purchase.payment_gateway_id,
      "custom"=>"DAILY_DEAL_PURCHASE"
    }.merge(options)
  end

  def syndicate(daily_deal, syndicated_publisher)
    daily_deal.syndicated_deals.build(:publisher_id => syndicated_publisher.id)
    daily_deal.save!
    daily_deal.syndicated_deals.last
  end

  def partial_refund(daily_deal, quantity, refund_amount)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => quantity, :daily_deal => daily_deal)
    expect_braintree_partial_refund(daily_deal_purchase, refund_amount)
    daily_deal_purchase.partial_refund!(Factory(:admin), [daily_deal_purchase.daily_deal_certificates.first.id.to_s])
    refunded_at = daily_deal.start_at + 6.hours
    daily_deal_purchase.update_attributes!(:refunded_at => refunded_at)
    daily_deal_purchase.daily_deal_certificates.first.update_attributes!(:refunded_at => refunded_at)
    assert daily_deal_purchase.partially_refunded?
    daily_deal_purchase
  end

  def full_refund(daily_deal, quantity)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :quantity => quantity, :daily_deal => daily_deal)
    expect_braintree_full_refund(daily_deal_purchase)
    daily_deal_purchase.void_or_full_refund!(Factory(:admin))
    refunded_at = daily_deal.start_at + 6.hours
    daily_deal_purchase.update_attributes!(:refunded_at => refunded_at)
    daily_deal_purchase.daily_deal_certificates.each { |c| c.update_attributes!(:refunded_at => refunded_at) }
    assert daily_deal_purchase.fully_refunded?
    daily_deal_purchase
  end
end
