# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::DelegateTest < ActiveSupport::TestCase
  context "in_syndication_network?" do
    should "delegate to the publisher" do
      daily_deal = Factory(:daily_deal)
      publisher = daily_deal.publisher
      publisher.expects(:in_syndication_network?).at_least_once.returns(true)
      assert_equal true, daily_deal.in_syndication_network?
      publisher.expects(:in_syndication_network?).at_least_once.returns(false)
      assert_equal false, daily_deal.in_syndication_network?
    end

    should "allow nil" do
      assert_nil DailyDeal.new.in_syndication_network?
    end
  end
end