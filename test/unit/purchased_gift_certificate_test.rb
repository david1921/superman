require File.dirname(__FILE__) + "/../test_helper"

class PurchasedGiftCertificateTest < ActiveSupport::TestCase        
  def setup
    assign_valid_attributes
    ActionMailer::Base.deliveries.clear
  end

  def test_create_not_physical
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    assert !purchased_gift_certificate.physical_gift_certificate?, "Should not be a physical deal certificate"
    
    purchased_gift_certificate.reload
    [ :gift_certificate,
      :paypal_txn_id,
      :paypal_receipt_id,
      :paypal_invoice,
      :paypal_payer_email,
      :paypal_payer_status,
      :paypal_address_name,
      :paypal_first_name,
      :paypal_last_name,
      :paypal_address_street,
      :paypal_address_city,
      :paypal_address_state,
      :paypal_address_zip,
      :paypal_address_status,
      :payment_status,
      :payment_status_updated_by_txn_id
    ].each do |attr|
      assert_equal @valid_attributes[attr], purchased_gift_certificate.send(attr), attr
    end
    assert_equal Time.parse("Jan 14, 2010 22:18:05 UTC"), purchased_gift_certificate.paypal_payment_date.utc
    assert_not_nil purchased_gift_certificate.payment_status_updated_at
    assert_equal 25.24, purchased_gift_certificate.paypal_payment_gross
    assert_match /\A\d{4}-\d{4}\z/, purchased_gift_certificate.serial_number
    assert !purchased_gift_certificate.redeemed?
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.first
    assert_equal "multipart/mixed", email.content_type, "Content-Type: header"
    assert_equal 2, email.parts.size, "Email message should have 2 parts"
    assert_equal 1, email.attachments.size, "Should have one attachment"
  end

  def test_create_physical
    @gift_certificate.update_attributes! :physical_gift_certificate => true
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    assert purchased_gift_certificate.physical_gift_certificate?, "Should be a physical deal certificate"
    
    purchased_gift_certificate.reload
    [ :gift_certificate,
      :paypal_txn_id,
      :paypal_receipt_id,
      :paypal_invoice,
      :paypal_payer_email,
      :paypal_payer_status,
      :paypal_address_name,
      :paypal_first_name,
      :paypal_last_name,
      :paypal_address_street,
      :paypal_address_city,
      :paypal_address_state,
      :paypal_address_zip,
      :paypal_address_status,
      :payment_status,
      :payment_status_updated_by_txn_id
    ].each do |attr|
      assert_equal @valid_attributes[attr], purchased_gift_certificate.send(attr), attr
    end
    assert_equal Time.parse("Jan 14, 2010 22:18:05 UTC"), purchased_gift_certificate.paypal_payment_date.utc
    assert_not_nil purchased_gift_certificate.payment_status_updated_at
    assert_equal 25.24, purchased_gift_certificate.paypal_payment_gross
    assert_match /\A\d{4}-\d{4}\z/, purchased_gift_certificate.serial_number
    assert !purchased_gift_certificate.redeemed?
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.first
    assert_equal "multipart/mixed", email.content_type, "Content-Type: header"
    assert_equal 1, email.parts.size, "Email message should have 1 part"
    assert_equal 0, email.attachments.size, "Should have no attachments"
  end

  def test_required_attributes
    gift_certificate = advertisers(:changos).gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3)

    assert_required = lambda do |attr, test_blank|
      purchased_gift_certificate = PurchasedGiftCertificate.new(@valid_attributes.merge(:gift_certificate => gift_certificate).except(attr))
      assert purchased_gift_certificate.invalid?, "Should not be valid with missing #{attr}"
      assert purchased_gift_certificate.errors.on(attr), "Should have error on #{attr} when missing"

      return unless test_blank
      
      purchased_gift_certificate = PurchasedGiftCertificate.new(@valid_attributes.merge(:gift_certificate => gift_certificate, attr => " "))
      assert purchased_gift_certificate.invalid?, "Should not be valid with blank #{attr}"
      assert purchased_gift_certificate.errors.on(attr), "Should have error on #{attr} when blank"
    end
    gift_certificate.update_attributes! :physical_gift_certificate => false
    assert_required.call :gift_certificate, false
    assert_required.call :paypal_payment_gross, true
    assert_required.call :paypal_txn_id, true
    assert_required.call :paypal_invoice, true
    assert_required.call :paypal_payer_email, true
    assert_required.call :payment_status, true

    gift_certificate.update_attributes! :physical_gift_certificate => true
    assert_required.call :gift_certificate, false
    assert_required.call :paypal_payment_gross, true
    assert_required.call :paypal_invoice, true
    assert_required.call :paypal_payer_email, true
    assert_required.call :payment_status, true
    assert_required.call :paypal_address_street, true
    assert_required.call :paypal_address_city, true
    assert_required.call :paypal_address_state, true
    assert_required.call :paypal_address_zip, true
  end
  
  def test_unique_attributes
    unique_attributes = {
      :paypal_txn_id => "38D93468JC7166635",
      :paypal_invoice => "123456785"
    }
    unique_attributes.keys.each { |attr| assert unique_attributes[attr] != @valid_attributes[attr], attr }
    existing_record = PurchasedGiftCertificate.create!(@valid_attributes)
    
    unique_attributes.each do |attr, value|
      purchased_gift_certificate = PurchasedGiftCertificate.new(@valid_attributes.merge(unique_attributes.except(attr)))
      assert purchased_gift_certificate.invalid?, "Should not be valid with duplicate #{attr} value"
      assert_match /has already been taken/, purchased_gift_certificate.errors.on(attr), "Error on #{attr}"
    end
    purchased_gift_certificate = PurchasedGiftCertificate.new(@valid_attributes.merge(unique_attributes))
    purchased_gift_certificate.serial_number = existing_record.serial_number
    assert purchased_gift_certificate.invalid?, "Should not be valid with duplicate serial number"
    assert_match /is not unique across all certificates/, purchased_gift_certificate.errors.on(:serial_number)
  end
  
  def test_immutability_of_serial_number
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    purchased_gift_certificate.serial_number = "1234-5678"
    assert purchased_gift_certificate.invalid?, "Should not be valid with updated serial number"
    assert_match /cannot be changed/, purchased_gift_certificate.errors.on(:serial_number)
  end
  
  def test_validation_of_paypal_payment_gross
    purchased_gift_certificate = PurchasedGiftCertificate.new(@valid_attributes.merge(:paypal_payment_gross => "5.00"))
    assert purchased_gift_certificate.invalid?, "Should not be valid when paypal payment gross doesn't match price"
    assert_match /deal certificate price/i, purchased_gift_certificate.errors.on(:paypal_payment_gross)
  end

  def test_no_validation_of_paypal_payment_gross_after_create
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    @gift_certificate.update_attributes! :handling_fee => @gift_certificate.handling_fee + 5.00
    assert purchased_gift_certificate.valid?, "Should be valid when total price changed after create"
  end

  def test_validation_of_payment_status
    purchased_gift_certificate = PurchasedGiftCertificate.new(@valid_attributes)
    %w{ completed reversed refunded }.each do |payment_status|
      purchased_gift_certificate.payment_status = payment_status
      assert purchased_gift_certificate.valid?, "Should be valid with payment_status '#{payment_status}'"
    end
    purchased_gift_certificate.payment_status = "xxxxxxxxx"
    assert purchased_gift_certificate.invalid?, "Should not be valid with bad payment_status"
    assert_match /is not included/i, purchased_gift_certificate.errors.on(:payment_status)
  end
  
  def test_gift_certificate_association
    assert PurchasedGiftCertificate.reflect_on_association(:gift_certificate)
  end
  
  def test_advertiser_and_publisher_methods
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    assert advertiser = purchased_gift_certificate.advertiser, "Should have an advertiser"
    assert_equal advertiser, purchased_gift_certificate.advertiser
    assert publisher = advertiser.publisher, "Should have a publisher"
    assert_equal publisher, purchased_gift_certificate.publisher
  end

  def test_destroy_publisher
    BaseDailyDealPurchase.delete_all
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    assert publisher = purchased_gift_certificate.publisher, "Should have a publisher"
    test_destroy_parent_with_purchased_gift_certificate(publisher, purchased_gift_certificate)
  end
  
  def test_destroy_advertiser
    BaseDailyDealPurchase.delete_all
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    assert advertiser = purchased_gift_certificate.advertiser, "Should have an advertiser"
    test_destroy_parent_with_purchased_gift_certificate(advertiser, purchased_gift_certificate)
  end
  
  def test_destroy_gift_certificate
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    assert gift_certificate = purchased_gift_certificate.gift_certificate, "Should have a gift_certificate"
    test_destroy_parent_with_purchased_gift_certificate(gift_certificate, purchased_gift_certificate)
  end
  
  def test_handle_buy_now
    ipn_params = buy_now_ipn_params
    assert_difference "@gift_certificate.purchased_gift_certificates.count" do
      PurchasedGiftCertificate.handle_buy_now ipn_params
    end
    purchased_gift_certificate = @gift_certificate.purchased_gift_certificates(true).first
    
    assert_equal Time.parse("Jan 14, 2010 22:18:05 UTC"), purchased_gift_certificate.paypal_payment_date.utc
    assert_equal "38D93468JC7166634", purchased_gift_certificate.paypal_txn_id
    assert_equal "3625-4706-3930-0684", purchased_gift_certificate.paypal_receipt_id
    assert_equal "3-1263504293", purchased_gift_certificate.paypal_invoice
    assert_equal @gift_certificate.price_with_handling_fee, purchased_gift_certificate.paypal_payment_gross
    assert_equal "tbuscher@gmail.com", purchased_gift_certificate.paypal_payer_email
    assert_equal "verified", purchased_gift_certificate.paypal_payer_status
    assert_equal "Henry Higgins", purchased_gift_certificate.paypal_address_name
    assert_equal "Henry", purchased_gift_certificate.paypal_first_name
    assert_equal "Higgins", purchased_gift_certificate.paypal_last_name
    assert_equal "1 Penny Lane", purchased_gift_certificate.paypal_address_street
    assert_equal "London", purchased_gift_certificate.paypal_address_city
    assert_equal "KY", purchased_gift_certificate.paypal_address_state
    assert_equal "40742", purchased_gift_certificate.paypal_address_zip
    assert_equal "confirmed", purchased_gift_certificate.paypal_address_status
    assert_equal "completed", purchased_gift_certificate.payment_status
    assert_equal "38D93468JC7166634", purchased_gift_certificate.payment_status_updated_by_txn_id
  end
  
  def test_handle_buy_now_with_duplicate
    ipn_params = buy_now_ipn_params
    assert_difference "PurchasedGiftCertificate.count" do
      PurchasedGiftCertificate.handle_buy_now ipn_params
    end
    assert_equal 1, @gift_certificate.purchased_gift_certificates.count

    assert_raise ActiveRecord::RecordInvalid do
      PurchasedGiftCertificate.handle_buy_now ipn_params
    end
    assert_equal 1, @gift_certificate.purchased_gift_certificates.count
  end

  def test_handle_buy_now_with_unknown_item_number
    ipn_params = buy_now_ipn_params("item_number" => "12345")
    
    assert_raise RuntimeError do
      PurchasedGiftCertificate.handle_buy_now ipn_params
    end
    assert_equal 0, @gift_certificate.purchased_gift_certificates.count
  end
  
  def test_handle_chargeback
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    ipn_params = chargeback_ipn_params(purchased_gift_certificate)
    
    assert_no_difference "PurchasedGiftCertificate.count" do
      PurchasedGiftCertificate.handle_chargeback ipn_params
    end
    purchased_gift_certificate.reload
    assert_equal "reversed", purchased_gift_certificate.payment_status
    assert_equal ipn_params["txn_id"], purchased_gift_certificate.payment_status_updated_by_txn_id
  end
  
  def test_handle_chargeback_reversal
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    ipn_params = chargeback_reversal_ipn_params(purchased_gift_certificate)
    
    assert_no_difference "PurchasedGiftCertificate.count" do
      PurchasedGiftCertificate.handle_chargeback_reversal ipn_params
    end
    purchased_gift_certificate.reload
    assert_equal "completed", purchased_gift_certificate.payment_status
    assert_equal ipn_params["txn_id"], purchased_gift_certificate.payment_status_updated_by_txn_id
  end
  
  def test_handle_refund
    purchased_gift_certificate = PurchasedGiftCertificate.create!(@valid_attributes)
    ipn_params = refund_ipn_params(purchased_gift_certificate)
    
    assert_no_difference "PurchasedGiftCertificate.count" do
      PurchasedGiftCertificate.handle_refund ipn_params
    end
    purchased_gift_certificate.reload
    assert_equal "refunded", purchased_gift_certificate.payment_status
    assert_equal ipn_params["txn_id"], purchased_gift_certificate.payment_status_updated_by_txn_id
  end
  
  def test_completed_scope
    purchase = lambda do |i, date, payment_status|
      @gift_certificate.purchased_gift_certificates.create!(@valid_attributes.merge({
        :paypal_txn_id => "38D93468JC71666#{i}",
        :paypal_receipt_id => "3625-4706-3930-06#{i}",
        :paypal_invoice => "12345678#{i}",
        :paypal_payment_date => date,
        :payment_status => payment_status
      }))
    end
    purchase.call(10, "15:59:59 Jan 14, 2010 PST", "completed")
    purchase.call(11, "15:59:59 Jan 14, 2010 PST", "reversed")
    purchase.call(12, "16:00:00 Jan 14, 2010 PST", "completed")
    purchase.call(13, "16:00:00 Jan 14, 2010 PST", "reversed")
    purchase.call(14, "12:34:56 Jan 15, 2010 PST", "completed")
    purchase.call(15, "12:34:56 Jan 15, 2010 PST", "reversed")
    purchase.call(16, "12:34:56 Jan 16, 2010 PST", "reversed")
    purchase.call(17, "15:59:59 Jan 16, 2010 PST", "completed")
    purchase.call(18, "15:59:59 Jan 16, 2010 PST", "reversed")
    purchase.call(19, "16:00:00 Jan 16, 2010 PST", "completed")
    purchase.call(20, "16:00:00 Jan 16, 2010 PST", "reversed")
    
    assert_equal 5, PurchasedGiftCertificate.completed(nil).count
    assert_equal 4, PurchasedGiftCertificate.completed(Date.parse("Jan 14, 2010") .. Date.parse("Jan 16, 2010")).count
    assert_equal 3, PurchasedGiftCertificate.completed(Date.parse("Jan 15, 2010") .. Date.parse("Jan 16, 2010")).count
    assert_equal 1, PurchasedGiftCertificate.completed(Date.parse("Jan 16, 2010") .. Date.parse("Jan 16, 2010")).count
  end
  
  def test_recipient_name
    assert_recipient_name = lambda do |first_name, last_name, address_name, recipient_name|
      purchased_gift_certificate = PurchasedGiftCertificate.new(@valid_attributes.merge(
        :paypal_first_name => first_name,
        :paypal_last_name => last_name,
        :paypal_address_name => address_name
      ))
      assert_equal recipient_name, purchased_gift_certificate.recipient_name
    end
    
    assert_recipient_name.call "John", "Doe", "Henry Higgins", "John Doe"
    assert_recipient_name.call "John", "Doe", nil, "John Doe"
    assert_recipient_name.call nil, nil, "Henry Higgins", "Henry Higgins"
    assert_recipient_name.call nil, nil, nil, "Deal Certificate Customer"
  end

  def test_collect_address_validation
    pgc = Factory.build(:purchased_gift_certificate, :paypal_address_street => "", :paypal_address_city => "", :paypal_address_state => "", :paypal_address_zip => "")
    assert pgc.valid?
    pgc.gift_certificate.physical_gift_certificate = true
    assert !pgc.valid?
    pgc.gift_certificate.physical_gift_certificate = false
    assert pgc.valid?
    pgc.gift_certificate.collect_address = true
    assert !pgc.valid?, "if the deal certificate is supposed to collect address, the purchased_gift_certificate is not valid unless the address is there"
  end
  
  private
  
  def assign_valid_attributes
    @gift_certificate = advertisers(:changos).gift_certificates.create!(:message => "buy", :price => 23.99, :value => 40.00, :number_allocated => 3, :handling_fee => 1.25)
    @valid_attributes = {
      :gift_certificate => @gift_certificate,
      :paypal_payment_date => "14:18:05 Jan 14, 2010 PST",
      :paypal_txn_id => "38D93468JC7166634",
      :paypal_receipt_id => "3625-4706-3930-0684",
      :paypal_invoice => "123456789",
      :paypal_payment_gross => "25.24",
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
    }
  end
  
  def test_destroy_parent_with_purchased_gift_certificate(parent, purchased_gift_certificate)
    parent.class.find(parent.id).destroy
    assert parent.class.exists?(parent.id), "#{parent.class.name.underscore.humanize} should not have been destroyed"
  end

  context "#redeemable?" do
    context "captured purchase" do
      setup do
        @completed_gift_certificate = Factory(:purchased_gift_certificate)
      end
      should "be completed" do
        assert_equal "completed", @completed_gift_certificate.payment_status
      end
      context "not redeemed" do
        should "not be redeemed" do
          assert !@completed_gift_certificate.redeemed?
        end
        should "be redeemable?" do
          assert @completed_gift_certificate.redeemable?
        end
      end
      context "redeemed" do
       setup do
         @completed_gift_certificate.redeemed = true
         @completed_gift_certificate.save!
       end
        should "not be redeemable?" do
          assert !@completed_gift_certificate.redeemable?
        end
      end
    end
    context "refunded purchase" do
      setup do
        @refunded_gift_certificate = Factory(:refunded_gift_certificate)
      end
      context "not redeemed" do
        should "not be redeemable? when certificate is refunded" do
          assert !@refunded_gift_certificate.redeemable?
        end
      end
      context "redeemed" do
        setup do
          @refunded_gift_certificate.redeemed = true
          @refunded_gift_certificate.save!
        end
        should "not be redeemable? when certificate has already been redeemed" do
          assert !@refunded_gift_certificate.redeemable?
        end
      end
    end
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
      "handling_amount" => "1.25",
      "payment_gross" => "%.2f" % (@gift_certificate.price + @gift_certificate.handling_fee),
      "receiver_email" => "demo_merchant@analoganalytics.com",
      "invoice" => "3-1263504293",
      "address_street" => "1 Penny Lane",
      "verify_sign" => "AmHf4UgW-l1HczXnT5wIeQmi8WIxA27fsg2vin5EA9DOGpG2mn9K-DQF",
      "action" => "create",
      "address_zip" => "40742",
      "quantity" => "1",
      "txn_type" => "web_accept",
      "mc_currency" => "USD",
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
end
