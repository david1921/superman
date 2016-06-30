require File.dirname(__FILE__) + "/../test_helper"

class DailyDealAffiliateRedirectTest < ActiveSupport::TestCase
  should belong_to(:daily_deal)
  should belong_to(:consumer)
end
