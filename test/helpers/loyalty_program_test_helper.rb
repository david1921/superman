module LoyaltyProgramTestHelper
  
  def publisher_with_loyalty_program_enabled
    Factory :publisher, :enable_loyalty_program_for_new_deals => true, :referrals_required_for_loyalty_credit_for_new_deals => 3
  end
  
  def deal_with_loyalty_program_enabled(publisher, options={})
    deal = Factory :side_daily_deal, { :publisher => publisher }.merge(options)
    deal.update_attributes :enable_loyalty_program => true,
                           :referrals_required_for_loyalty_credit => publisher.referrals_required_for_loyalty_credit_for_new_deals || 3
    deal
  end
  
  def deal_with_loyalty_program_disabled(publisher, options={})
    deal = Factory :side_daily_deal, { :publisher => publisher }.merge(options)
    deal.update_attributes :enable_loyalty_program => false,
                          :referrals_required_for_loyalty_credit => publisher.referrals_required_for_loyalty_credit_for_new_deals || 3
    deal
  end

  def purchase_that_earned_loyalty_credit(deal, consumer)
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    deal.referrals_required_for_loyalty_credit.times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    end
    purchase
  end

  def purchase_that_earned_loyalty_credit_with_variation(deal, variation, consumer)
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :daily_deal_variation => variation, :consumer => consumer
    deal.referrals_required_for_loyalty_credit.times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :daily_deal_variation => variation, :loyalty_program_referral_code => consumer.referrer_code
    end
    purchase
  end

  def purchase_that_match_referrals_required_for_loyalty_credit_with_different_variations(deal, variations, consumer)
    raise ArgumentError, "must supply an array of variations" unless Array === variations
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :daily_deal_variation => variations.first, :consumer => consumer
    (deal.referrals_required_for_loyalty_credit-1).times do |i|
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :daily_deal_variation => variations[i % 2], :loyalty_program_referral_code => consumer.referrer_code
    end
    purchase
  end
  
  def purchase_with_no_loyalty_referrals(deal, consumer)
    Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
  end
  
  def purchase_with_num_loyalty_referrals_less_than_referrals_required(deal, consumer)
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    (deal.referrals_required_for_loyalty_credit - 1).times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    end
    purchase
  end
  
  def purchase_that_earned_loyalty_credit_from_purchases_made_by_single_sign_on_users(deal, consumer)
    unless deal.publishing_group.allow_single_sign_on?
      raise ArgumentError, "deal publishing group must allow single sign on"
    end
    
    other_publisher_in_group = Factory :publisher, :publishing_group => deal.publishing_group
    consumer_from_other_pub = Factory :consumer, :publisher => other_publisher_in_group    

    referrers_purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer_from_other_pub,
            :loyalty_program_referral_code => consumer.referrer_code
    (deal.referrals_required_for_loyalty_credit - 1).times do
      consumer_from_deal_pub = Factory :consumer, :publisher => deal.publisher
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer_from_deal_pub,
              :loyalty_program_referral_code => consumer.referrer_code
    end
    
    referrers_purchase
  end
  
  def purchase_with_required_number_of_referrals_but_all_from_same_consumer(deal, consumer)
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    other_consumer = Factory :consumer, :publisher => deal.publisher
    deal.referrals_required_for_loyalty_credit.times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code, :consumer => other_consumer
    end
    purchase
  end
  
  def pending_purchase_with_loyalty_referrals_equal_to_referrals_required(deal, consumer)
    purchase = Factory :pending_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    deal.referrals_required_for_loyalty_credit.times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    end
    purchase
  end
  
  def captured_purchase_with_num_referrals_equal_to_referrals_required_but_not_all_captured(deal, consumer)
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    (deal.referrals_required_for_loyalty_credit - 1).times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    end
    Factory :pending_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    purchase
  end
  
  def purchase_that_would_earn_loyalty_credit_but_deal_has_disabled_loyalty_program(deal, consumer)
    raise "expected deal with loyalty program disabled" if deal.enable_loyalty_program?
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    deal.referrals_required_for_loyalty_credit.times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    end
    purchase
  end
  
  def refunded_purchase_with_loyalty_referrals_equal_to_referrals_required(deal, consumer)
    purchase = Factory :refunded_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    deal.referrals_required_for_loyalty_credit.times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    end
    purchase
  end
  
  def purchase_that_earned_the_loyalty_credit_twice(deal, consumer)
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    (deal.referrals_required_for_loyalty_credit * 2).times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    end
    purchase
  end
  
  def purchase_that_earned_loyalty_credit_and_has_received_the_credit(deal, consumer)
    purchase = Factory :captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer
    deal.referrals_required_for_loyalty_credit.times do
      Factory :captured_daily_deal_purchase, :daily_deal => deal, :loyalty_program_referral_code => consumer.referrer_code
    end
    expect_braintree_full_refund(purchase)
    purchase.loyalty_refund!(@admin)
    purchase
  end
  
end