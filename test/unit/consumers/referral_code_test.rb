require File.dirname(__FILE__) + "/../../test_helper"

class Consumers::ReferralCodeTest < ActiveSupport::TestCase

  test "setting a blank referral_code should write nil" do
    consumer = Factory.build(:consumer, :referral_code => " ")
    assert_nil consumer.referral_code
  end

  test "setting referral_code should write stripped value" do
    consumer = Factory.build(:consumer, :referral_code => " abcd1234  ")
    assert_equal "abcd1234", consumer.referral_code
  end

  test "assignment of referrer code" do
    consumer = Factory.build(:consumer)
    assert_nil consumer.referrer_code, "Referrer code should not be present after factory build"
    consumer.save!
    assert_match /\A[[:xdigit:]]{8}-([[:xdigit:]]{4}-){3}[[:xdigit:]]{12}\z/, consumer.referrer_code
  end

  test "first daily_deal_purchase_captured with referral_code matching a referrer_code adds one credit to referrer" do
    daily_deal = Factory(:daily_deal)
    publisher = daily_deal.publisher
    referrer = Factory(:consumer, :publisher => publisher)
    referred = Factory(:consumer, :publisher => publisher, :referral_code => referrer.referrer_code)
    assert_equal 0, referrer.credits.count, "Referrer should not have credit"

    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => referred)
    assert_difference 'referrer.credits.count' do
      referred.daily_deal_purchase_captured! daily_deal_purchase
    end
    assert_equal daily_deal_purchase, referrer.credits(true).first.origin
  end

  test "second daily_deal_purchase_executed with referral_code matching a referrer_code does not create a credit" do
    daily_deal = Factory(:daily_deal)
    publisher = daily_deal.publisher
    referrer = Factory(:consumer, :publisher => publisher)
    referred = Factory(:consumer, :publisher => publisher, :referral_code => referrer.referrer_code)
    referred.daily_deal_purchase_executed! Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => referred)

    assert_no_difference 'Credit.count' do
      referred.daily_deal_purchase_executed! Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => referred)
    end
  end

  test "daily_deal_purchase_executed with referral_code matching own referrer_code does not create a credit" do
    daily_deal = Factory(:daily_deal)
    publisher = daily_deal.publisher
    referrer = Factory(:consumer, :publisher => publisher)

    assert_no_difference 'Credit.count' do
      referrer.daily_deal_purchase_executed! Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => referrer)
    end
  end

  test "daily_deal_purchase_executed with referral_code not matching a referrer_code does not create a credit" do
    daily_deal = Factory(:daily_deal)
    publisher = daily_deal.publisher
    consumer_1 = Factory(:consumer, :publisher => publisher)
    consumer_2 = Factory(:consumer, :publisher => publisher, :referral_code => "abcd1234" * 4)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer_2)

    assert_no_difference 'Credit.count' do
      consumer_2.daily_deal_purchase_executed! daily_deal_purchase
    end
  end

  test "daily_deal_purchase_executed with no referral_code does not create a credit" do
    daily_deal = Factory(:daily_deal)
    publisher = daily_deal.publisher
    consumer_1 = Factory(:consumer, :publisher => publisher)
    consumer_2 = Factory(:consumer, :publisher => publisher)
    daily_deal_purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer_2)

    assert_no_difference 'Credit.count' do
      consumer_2.daily_deal_purchase_executed! daily_deal_purchase
    end
  end

  test "referral credit default amount when publisher does not have it configured" do
    daily_deal = Factory(:daily_deal)
    publisher = daily_deal.publisher
    referrer = Factory(:consumer, :publisher => publisher)
    referred = Factory(:consumer, :publisher => publisher, :referral_code => referrer.referrer_code)

    assert_difference 'referrer.reload.credit_available', 10.00 do
      referred.daily_deal_purchase_captured! Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => referred)
    end
  end

  test "referral credit amount is the configured value when publisher has it configured" do
    publisher = Factory(:publisher, :daily_deal_referral_credit_amount => 5.00)
    daily_deal = Factory(:daily_deal, :publisher => publisher)
    referrer = Factory(:consumer, :publisher => publisher)
    referred = Factory(:consumer, :publisher => publisher, :referral_code => referrer.referrer_code)

    assert_difference 'referrer.reload.credit_available', 5.00 do
      referred.daily_deal_purchase_captured! Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => referred)
    end
  end

end
