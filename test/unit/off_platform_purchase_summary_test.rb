require File.dirname(__FILE__) + "/../test_helper"

class OffPlatformPurchaseSummaryTest < ActiveSupport::TestCase

  context "associations" do
    should belong_to :daily_deal
  end

end
