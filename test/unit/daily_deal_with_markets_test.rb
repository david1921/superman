require File.dirname(__FILE__) + "/../test_helper"

class DailyDealWithMarketsTest < ActiveSupport::TestCase
  context "current or previous" do
    context "with market" do
      setup do
        @publisher = Factory(:publisher)
        @advertiser = Factory(:advertiser, :publisher => @publisher)
        @daily_deal = Factory(:daily_deal,
                              :advertiser => @advertiser,
                              :start_at => Time.zone.now.tomorrow,
                              :hide_at => Time.zone.now.tomorrow.end_of_day)
        @market = Factory(:market, :publisher => @publisher)
        @daily_deal.markets << @market
        @daily_deal.save!
      end
    
      should "return no deals" do
        assert_nil @publisher.daily_deals.current_or_previous
      end
    
      should "not return deal in the future" do
        assert_nil @publisher.daily_deals.current_or_previous
      end
    
      should "return deal for today" do
        @daily_deal.start_at = Time.zone.now.beginning_of_day
        @daily_deal.hide_at = Time.zone.now.end_of_day
        @daily_deal.save!
        assert_equal @daily_deal, @publisher.daily_deals.current_or_previous
      end
    
      should "return deal earlier in the day, and now" do
        Timecop.freeze(Time.zone.local(2011, 4, 11, 8, 0, 0)) do
          @daily_deal.start_at = Time.zone.now.beginning_of_day
          @daily_deal.hide_at = Time.zone.now - 30.minutes
          @daily_deal.save!
          now_deal = Factory(:daily_deal,
                             :advertiser => @advertiser,
                             :start_at => Time.zone.now - 5.minutes,
                             :hide_at => Time.zone.now.end_of_day)
          assert_equal now_deal, @publisher.daily_deals.current_or_previous
        end
      
      end
    
      should "return deal with same start_at but is still active and ends later" do
        Timecop.freeze(Time.zone.local(2011, 4, 11, 8, 0, 0)) do
          @daily_deal.start_at = Time.zone.now.beginning_of_day
          @daily_deal.hide_at = Time.zone.now - 30.minutes
          @daily_deal.save!
          concurrent_deal_ends_later = Factory(:daily_deal,
                                               :advertiser => @advertiser,
                                               :start_at => @daily_deal.start_at,
                                               :hide_at => Time.zone.now + 30.minutes)
          assert_equal concurrent_deal_ends_later, @publisher.daily_deals.current_or_previous
        end
      end
    end
  end

  context "side deals" do
    should "side deals with markets" do
      @publisher = Factory.create(:publisher)
      @market = Factory.create(:market, :publisher => @publisher)
      @elsewhere_market = Factory.create(:market, :publisher => @publisher)

      @featured_deal = Factory.create(:daily_deal,
                                      :publisher => @publisher)
      @featured_deal.markets << @market

      @side_deal_1 = Factory.create(:side_daily_deal, :publisher => @publisher)
      @side_deal_1.markets << @market
      @side_deal_2 = Factory.create(:side_daily_deal, :publisher => @publisher)
      @side_deal_2.markets << @market
      
      @featured_deal_elsewhere = Factory.build(:daily_deal,
                                                :publisher => @publisher)

      @featured_deal_elsewhere.markets << @elsewhere_market
      @featured_deal_elsewhere.save!

      @side_deal_elsewhere = Factory.create(:side_daily_deal, :publisher => @publisher)
      @side_deal_elsewhere.markets << @elsewhere_market

      @side_deal_no_market = Factory.create(:side_daily_deal, :publisher => @publisher)

      @featured_deal_another_publisher = Factory.create(:daily_deal)
      @side_deal_another_publisher = Factory.create(:side_daily_deal)

      side_deals = @featured_deal.side_deals

      assert_equal false, side_deals.include?(@featured_deal)
      assert_equal true, side_deals.include?(@side_deal_1)
      assert_equal true, side_deals.include?(@side_deal_2)

      assert_equal false, side_deals.include?(@featured_deal_elsewhere)
      assert_equal false, side_deals.include?(@side_deal_elsewhere)

      assert_equal false, side_deals.include?(@side_deal_no_market)
      assert_equal false, side_deals.include?(@featured_deal_another_publisher)
      assert_equal false, side_deals.include?(@side_deal_another_publisher)
    end
  end

  context "daily deals and their markets" do
    setup do
      @publisher = Factory(:publisher)
      @market = Factory(:market, :publisher => @publisher)
      @deal = Factory(:daily_deal, :publisher => @publisher)
    end
    should "be setup properly" do
      assert_equal 0, @deal.markets.size
      assert_equal @market.publisher, @deal.publisher
    end
    should "be valid with no markets" do
      assert @deal.valid?
    end
    should "be able to add a market to a deal" do
      @deal.markets << @market
      assert_equal 1, @deal.markets.size
      assert @deal.valid?, @deal.errors.full_messages
    end
    context "another publisher with a market" do
      setup do
        @interloper = Factory(:publisher)
        @interloper_market = Factory(:market, :publisher => @interloper, :name => "Interloper's Market")
      end
      should "not be able to add a market to a daily deal if the market's publisher is not the same as the deal's" do
        @deal.markets << @interloper_market
        assert !@deal.valid?
      end
    end
  end

  test "should allow overlapping non-featured deal with same market" do
    featured_deal = Factory(:daily_deal,
                            :start_at => 12.days.from_now, 
                            :hide_at => 14.days.from_now)
    market = Factory(:market, :publisher => featured_deal.publisher)
    featured_deal.markets << market
    featured_deal.save!
    regular_deal = Factory(:side_daily_deal,
                                 :publisher => featured_deal.publisher,
                                 :start_at => 11.days.from_now,
                                 :hide_at => 13.days.from_now)
    regular_deal.markets << market
    assert_equal true, regular_deal.valid?, "Should be valid"
    assert_nil regular_deal.errors.on(:base), "Should not have errors on deal"
  end
  
  test "should allow overlapping featured deal with different market" do
     featured_deal = Factory(:daily_deal,
                              :start_at => 12.days.from_now, 
                              :hide_at => 14.days.from_now)
     market_1 = Factory(:market, :publisher => featured_deal.publisher)
     featured_deal.markets << market_1
     featured_deal.save!
     featured_deal_different_market = Factory.build(:daily_deal,
                                                    :publisher => featured_deal.publisher,
                                                    :start_at => 11.days.from_now, 
                                                    :hide_at => 13.days.from_now)
     market_2 = Factory(:market, :publisher => featured_deal.publisher)
     featured_deal_different_market.markets << market_2
     
     assert_equal true, featured_deal_different_market.valid?, "Should be valid"
     assert_nil featured_deal_different_market.errors.on(:base), "Should not have errors on deal"
   end
  
  test "should NOT allow overlapping featured deals with same market" do
    featured_deal = Factory(:featured_daily_deal,
                            :start_at => 12.days.from_now, 
                            :hide_at => 14.days.from_now)
    market = Factory(:market, :publisher => featured_deal.publisher)
    featured_deal.markets << market
    featured_deal.save!
    overlapping_featured_deal = Factory.build(:featured_daily_deal,
                                               :publisher => featured_deal.publisher,
                                               :start_at => 11.days.from_now, 
                                               :hide_at => 13.days.from_now)
    overlapping_featured_deal.markets << market
    assert_equal true, overlapping_featured_deal.invalid?, "Should be invalid"
    assert_match /Start at and hide at times overlap with another featured deal/i,
                  overlapping_featured_deal.errors.on(:base), "Should have errors on deal"
  end
  
  test "should allow overlapping featured deal with nil market" do
    featured_deal = Factory(:daily_deal,
                            :start_at => 12.days.from_now, 
                            :hide_at => 14.days.from_now)
    market_1 = Factory(:market, :publisher => featured_deal.publisher)
    featured_deal.markets << market_1
    featured_deal.save!
    featured_deal_nil_market = Factory.build(:daily_deal,
                                            :publisher => featured_deal.publisher,
                                            :start_at => 11.days.from_now, 
                                            :hide_at => 13.days.from_now)

    assert_equal true, featured_deal_nil_market.valid?, "Should be valid, but had errors: #{featured_deal_nil_market.errors.full_messages.join(", ")}"
    assert_nil featured_deal_nil_market.errors.on(:base), "Should not have errors on deal"
  end
 
  test "should allow overlapping featured deal after nil market deal" do
    featured_deal_nil_market = Factory(:daily_deal,
                                       :start_at => 12.days.from_now, 
                                       :hide_at => 14.days.from_now)
    featured_deal = Factory.build(:daily_deal,
                                  :publisher => featured_deal_nil_market.publisher,
                                  :start_at => 11.days.from_now, 
                                  :hide_at => 13.days.from_now)
    market_1 = Factory(:market, :publisher => featured_deal_nil_market.publisher)
    featured_deal.markets << market_1
    
    assert_equal true, featured_deal.valid?, "Should be valid, but had errors: #{featured_deal.errors.full_messages.join(", ")}"
    assert_nil featured_deal.errors.on(:base), "Should not have errors on deal"
  end
  
  test "in_market named scope" do
    deal_1 = Factory(:daily_deal,
                     :start_at => 1.days.from_now, 
                     :hide_at => 2.days.from_now)
    market_1 = Factory(:market, :publisher => deal_1.publisher)
    deal_1.markets << market_1
    deal_1.save!
    
    #same publisher different market
    deal_2 = Factory.build(:daily_deal,
                     :publisher => deal_1.publisher,
                     :start_at => 1.days.ago,
                     :hide_at => 2.days.from_now)
    market_2 = Factory(:market, :publisher => deal_1.publisher)
    deal_2.markets << market_2
    deal_2.save!
    
    #diff publisher different market
    deal_3 = Factory(:daily_deal,
                     :start_at => 1.days.ago, 
                     :hide_at => 2.days.from_now)
    market_3 = Factory(:market, :publisher => deal_3.publisher)
    deal_3.markets << market_3
    deal_3.save!
    
    #different deal - same publisher and same market - featured
    deal_4 = Factory(:daily_deal,
                     :publisher => deal_1.publisher,
                     :start_at => 3.days.from_now, 
                     :hide_at => 4.days.from_now)
    deal_4.markets << market_1
    deal_4.save!
    
    #different deal - same publisher and same market - not featured
    deal_5 = Factory(:side_daily_deal,
                     :publisher => deal_1.publisher,
                     :start_at => 1.days.ago, 
                     :hide_at => 2.days.from_now)
    deal_5.markets << market_1
    deal_5.save!
    
    assert_equal [deal_1, deal_4, deal_5], DailyDeal.in_market(market_1), "Should have deals in market"
    
  end
  
  test "without_market named scope" do
    deal_1 = Factory(:daily_deal,
                     :start_at => 1.days.from_now, 
                     :hide_at => 2.days.from_now,
                     :description => "deal 1")
    market_1 = Factory(:market, :publisher => deal_1.publisher)
    deal_1.markets << market_1
    deal_1.save!
    
    #same publisher different market
    deal_2 = Factory(:daily_deal,
                     :publisher => deal_1.publisher,
                     :description => "deal 2",
                     :start_at => 3.days.from_now,
                     :hide_at => 4.days.from_now)
    market_2 = Factory(:market, :publisher => deal_1.publisher)
    deal_2.markets << market_2
    deal_2.save!
    
    #same publisher without market
    deal_3 = Factory(:daily_deal,
                     :publisher => deal_1.publisher,
                     :description => "deal 3",
                     :start_at => 5.days.from_now,
                     :hide_at => 6.days.from_now)
    
    #diff publisher without market
    deal_4 = Factory(:daily_deal,
                     :description => "deal 4",
                     :start_at => 7.days.ago, 
                     :hide_at => 8.days.from_now)
    deals = DailyDeal.without_market
    assert_equal false, deals.include?(deal_1)
    assert_equal false, deals.include?(deal_2)
    assert_equal true, deals.include?(deal_3)
    assert_equal true, deals.include?(deal_4)
  end
  
  test "market_belongs_to_daily_deal" do
    daily_deal = Factory(:daily_deal)
    other_deal = Factory(:daily_deal)
    
    market_1 = Factory(:market, :publisher => daily_deal.publisher)
    market_2 = Factory(:market, :publisher => daily_deal.publisher)
    market_3 = Factory(:market, :publisher => other_deal.publisher)
    market_4 = Factory(:market, :publisher => other_deal.publisher)
    daily_deal.markets << market_1
    daily_deal.markets << market_2
    
    assert_equal true, daily_deal.market_belongs_to_daily_deal?(nil)
    assert_equal true, daily_deal.market_belongs_to_daily_deal?(market_1.id)
    assert_equal true, daily_deal.market_belongs_to_daily_deal?(market_2.id)
    assert_equal false, daily_deal.market_belongs_to_daily_deal?(market_3.id)
    assert_equal false, daily_deal.market_belongs_to_daily_deal?(market_4.id)
  end
end
