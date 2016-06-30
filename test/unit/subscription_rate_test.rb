require File.dirname(__FILE__) + "/../test_helper"

class SubscriptionRateTest < ActiveSupport::TestCase
  def test_create
    subscription_rate = subscription_rate_schedules(:sdh_austin_rates).subscription_rates.create!(
      :name => "One year paid monthly",
      :description_1 => "Our most affordable plan",
      :description_2 => "Only $9.99 per month",
      :description_1 => "Cancel at any time",
      :regular_price => "9",
      :regular_period => "1",
      :regular_time_unit => "month",
      :recurs => "1",
      :recurring_count => "11"
    )
    assert_equal 9.00, subscription_rate.regular_price
    assert_equal 1, subscription_rate.regular_period
    assert_equal true, subscription_rate.recurs
    assert_equal 11, subscription_rate.recurring_count
    
    subscription_rate = subscription_rate_schedules(:sdh_austin_rates).subscription_rates.create!(
      :name => "One year paid in full",
      :regular_price => "119.99",
      :regular_period => "1",
      :regular_time_unit => "year"
    )
    assert_equal 119.99, subscription_rate.regular_price
    assert_equal false, subscription_rate.recurs
  end
  
  def test_validation_of_regular_period_and_time_unit
    subscription_rate = subscription_rate_schedules(:sdh_austin_rates).subscription_rates.build(
      :name => "Five years paid in full",
      :regular_price => "699.99",
      :regular_period => "60",
      :regular_time_unit => "month"
    )
    assert subscription_rate.invalid?, "Should require 5 years instead of 60 months"
    assert_match /invalid for time unit/i, subscription_rate.errors.on(:regular_period)

    subscription_rate = subscription_rate_schedules(:sdh_austin_rates).subscription_rates.create!(
      :name => "Five years paid in full",
      :regular_price => "699.99",
      :regular_period => "5",
      :regular_time_unit => "year"
    )
  end
end
