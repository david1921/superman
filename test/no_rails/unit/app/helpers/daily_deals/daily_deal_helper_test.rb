require File.dirname(__FILE__) + "/../../helpers_helper"

class DailyDealHelperTest < Test::Unit::TestCase

  class MockHelper
    include DailyDealHelper
  end

  def setup
    @helper = MockHelper.new
    @daily_deal = mock("daily_deal")
  end

  context "show_syndication_financials?" do
    context "new record" do
      should "return false" do
        @daily_deal.expects(:new_record?).returns(true)
        assert_equal false, @helper.send(:show_syndication_financials?, @daily_deal)
      end
    end
    
    context "not available for syndication" do
      should "return false" do
        @daily_deal.expects(:new_record?).returns(false)
        @daily_deal.expects(:available_for_syndication?).returns(false)
        assert_equal false, @helper.send(:show_syndication_financials?, @daily_deal)
      end
    end
    
    context "non-accountant existing record and available for syndication" do
      should "return true" do
        @daily_deal.expects(:new_record?).returns(false)
        @daily_deal.expects(:available_for_syndication?).returns(true)
        assert_equal true, @helper.send(:show_syndication_financials?, @daily_deal)
      end
    end
  end

  context "#market_aware_daily_deal_url" do
    setup do
      @publisher = mock('publisher')
      @publisher.stubs(:label).returns("anything")
      @publisher.stubs(:daily_deal_host).returns("somehost.com")
      @daily_deal.stubs(:publisher).returns(@publisher)
      @daily_deal.stubs(:id).returns(10)
    end

    should "include supplied params in returned url" do
      referral_code = "09029343242-093423-049-09324"
      params = {:host => @publisher.daily_deal_host, :id => @daily_deal.id, :referral_code => referral_code}
      @helper.expects(:publisher_daily_deal_url).with(params.merge(:publisher_id => @publisher.label))
      @helper.send(:market_aware_daily_deal_url, @daily_deal, :referral_code => referral_code)

      market_label = "marketlabel"
      @helper.expects(:publisher_daily_deal_for_market_url).with(params.merge(:label => @publisher.label, :market_label => market_label))
      @helper.send(:market_aware_daily_deal_url, @daily_deal, :referral_code => referral_code, :market_label => market_label)
    end
  end
end