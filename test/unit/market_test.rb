require File.dirname(__FILE__) + "/../test_helper"

class MarketTest < ActiveSupport::TestCase
  should have_many(:market_zip_codes)

  context "basic plumbing for factory" do
    setup do
      @market = Factory(:market, :name => "oprah's followers")
    end
    should "have a publisher" do
      assert_not_nil @market.publisher
    end
    should "have a name" do
      assert_equal "oprah's followers", @market.name
    end
  end
  
  context "label" do
    setup do
      @market = Factory(:market, :name => "portland, OR")
    end
    should "parameterize name to create label" do
      assert_equal "portland-or", @market.label
    end
  end
  
end

