require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::AffiliateUrlTest < ActiveSupport::TestCase

  context "publisher_label replacement" do
    setup do
      @affiliate_url = "http://example.com?label=%publisher_label%"
      publisher = Factory(:publisher, :label => "test-label")
      @daily_deal = Factory(:daily_deal, :publisher => publisher)
    end

    context "affiliate_url is not set" do
      should "do nothing" do
        assert_equal nil, @daily_deal.affiliate_url
      end
    end

    context "affiliate_url is set" do
      setup do
        @daily_deal.update_attributes(:affiliate_url => @affiliate_url)
      end

      should "replace on access" do
        assert_equal "http://example.com?label=test-label", @daily_deal.affiliate_url
      end

      should "not replace on create" do
        assert_equal @affiliate_url, @daily_deal.read_attribute(:affiliate_url)
      end
    end
  end

end
