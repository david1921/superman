require File.dirname(__FILE__) + "/../test_helper"

class SubscriptionRateScheduleTest < ActiveSupport::TestCase
  def test_create
    subscription_rate_schedule = publishers(:sdh_boulder).subscription_rate_schedules.create!(
      :name => "Standard Rate Schedule"
    )
    assert_equal "Standard Rate Schedule", subscription_rate_schedule.name
    assert_match /[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}/, subscription_rate_schedule.uuid.to_s
  end
end
