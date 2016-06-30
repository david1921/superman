# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchase::ConfirmationEmailTest < ActiveSupport::TestCase
  include DailyDealPurchasesTestHelper

  context "confirmation email text" do

    setup do
      ActionMailer::Base.deliveries.clear
    end

    should "tell customer to bring a 'valid photo ID'" do
      daily_deal_purchase = Factory :pending_daily_deal_purchase
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
      email = ActionMailer::Base.deliveries.first
      assert_match /valid photo ID/, email.body
    end

    should "tell customer to bring a valid ID, with examples, for thomsonlocal" do
      thomson = Factory :publisher, :label => "thomsonlocal"
      advertiser = Factory :advertiser, :publisher => thomson
      daily_deal = Factory :daily_deal, :advertiser => advertiser
      daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal => daily_deal
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
      email = ActionMailer::Base.deliveries.first
      assert_match /Please bring your printed voucher and valid ID, e.g. driving licence, passport or a bill showing your address, when you go to redeem your deal at/, email.body
    end

    should "say that the deal certificates are attached" do
      daily_deal_purchase = Factory :pending_daily_deal_purchase
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
      email = ActionMailer::Base.deliveries.first
      assert_match /Your deal certificates are attached/, email.body
    end

    should "say that the deal voucher is attached, for thomsonlocal" do
      thomson = Factory :publisher, :label => "thomsonlocal"
      advertiser = Factory :advertiser, :publisher => thomson
      daily_deal = Factory :daily_deal, :advertiser => advertiser
      daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal => daily_deal
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
      email = ActionMailer::Base.deliveries.first
      assert_match /Your deal voucher is attached/, email.body
    end
    
    should "use publisher locale file if available" do
      bcbsa = Factory :publishing_group, :label => "bcbsa"
      bcbsvt = Factory :publisher, :label => "BCBSVT", :publishing_group => bcbsa
      advertiser = Factory :advertiser, :publisher => bcbsvt
      daily_deal = Factory :daily_deal, :advertiser => advertiser
      daily_deal_purchase = Factory :pending_daily_deal_purchase, :daily_deal => daily_deal
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
      email = ActionMailer::Base.deliveries.first
      assert_match /Purchase Confirmed: .*? Deal for/, email.subject
    end
  
    should "use system defaults if local file not available" do
      daily_deal_purchase = Factory :pending_daily_deal_purchase
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
      email = ActionMailer::Base.deliveries.first
      assert_match /Purchase Confirmed:/, email.subject 
    end

    should "use the purchased deal's publisher logo, not the consumer's origin logo" do
      other_publisher = Factory :publisher, :label => "otherpublisher"
      consumer = Factory :consumer, :publisher => other_publisher
      daily_deal_purchase = Factory :pending_daily_deal_purchase
      braintree_transaction = braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::SubmittedForSettlement)
      daily_deal_purchase.handle_braintree_sale! braintree_transaction
      
      other_publisher.stubs(:logo).returns(stub(:url => "other_publisher_logo"))
      purchase_publisher = daily_deal_purchase.daily_deal.publisher
      purchase_publisher.stubs(:logo).returns(stub(:url => "other_publisher_logo"))

      assert_equal 1, ActionMailer::Base.deliveries.size, "Should have sent confirmation email after settlement"
      email = ActionMailer::Base.deliveries.first
      assert_match /#{purchase_publisher.daily_deal_logo.url}/, email.body      
    end
  end
end
