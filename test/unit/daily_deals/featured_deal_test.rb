require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::FeaturedDealTest

module DailyDeals
  class FeaturedDealTest < ActiveSupport::TestCase

    context "featuring a deal with DailyDeal#featured=" do
      setup do
        @deal = Factory(:side_daily_deal)
        assert_not_nil @deal.side_start_at
        assert_not_nil @deal.side_end_at
      end

      should "make the side_start_at and side_end_at nil when passed a TRUE VALUE" do
        @deal.featured = true
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
      end

      should "make the side_start_at and side_end_at nil when passed the STRING 'true'" do
        @deal.featured = "true"
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
      end

      should "make the side_start_at and side_end_at nil when passed the STRING '1'" do
        @deal.featured = "1"
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
      end

      should "make the side_start_at and side_end_at nil when passed 1" do
        @deal.featured = 1
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
      end
    end

    context "unfeaturing a deal with DailyDeal#featured=" do
      setup do
        @deal = Factory(:featured_daily_deal)
        assert_not_nil @deal.start_at
        assert_not_nil @deal.hide_at
        assert_nil @deal.side_start_at
        assert_nil @deal.side_end_at
      end

      should "make the side_start_at and side_end_at equal to start_at and hide_at when passed a FALSE VALUE" do
        @deal.featured = false
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
      end

      should "make the side_start_at and side_end_at equal to start_at and hide_at when passed the STRING 'false'" do
        @deal.featured = "false"
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
      end

      should "make the side_start_at and side_end_at equal to start_at and hide_at when passed the STRING '0'" do
        @deal.featured = "0"
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
      end

      should "make the side_start_at and side_end_at equal to start_at and hide_at when passed 0" do
        @deal.featured = 0
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
        end

      should "make the side_start_at and side_end_at equal to start_at and hide_at when passed nil" do
        @deal.featured = nil
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
        @deal.save!
        @deal.reload
        assert_equal @deal.start_at, @deal.side_start_at
        assert_equal @deal.hide_at, @deal.side_end_at
      end
    end

    test "should allow overlapping non-featured deal" do
       publisher = Factory(:publisher)
       featured_deal = Factory(:featured_daily_deal,
                               :publisher => publisher,
                               :start_at => 12.days.from_now,
                               :hide_at => 14.days.from_now)
       assert_nil featured_deal.side_start_at
       assert_nil featured_deal.side_end_at

       side_deal = Factory.build(:side_daily_deal,
                                    :publisher => publisher,
                                    :start_at => 11.days.from_now,
                                    :hide_at => 13.days.from_now)

       assert_not_nil side_deal.side_start_at
       assert_not_nil side_deal.side_end_at
       assert_equal true, side_deal.valid?, "Should be valid"
       assert_nil side_deal.errors.on(:base), "Should not have errors on deal"
    end
    
    test "should NOT allow overlapping featured deals" do
      publisher = Factory(:publisher)
      featured_deal = Factory(:featured_daily_deal,
                              :publisher => publisher,
                              :start_at => 12.days.from_now,
                              :hide_at => 14.days.from_now)

      overlapping_featured_deal = Factory.build(:featured_daily_deal,
                                                :publisher => publisher,
                                                :start_at => 11.days.from_now,
                                                :hide_at => 13.days.from_now)

      assert_equal true, overlapping_featured_deal.invalid?, "Should be invalid"
      assert_match /Start at and hide at times overlap with another featured deal/i,
                   overlapping_featured_deal.errors.on(:base), "Should have errors on deal"
    end
    
    test "should allow overlapping non-featured deal with same market" do
      featured_deal = Factory(:featured_daily_deal,
                              :start_at => 12.days.from_now,
                              :hide_at => 14.days.from_now)
      market = Factory(:market, :publisher => featured_deal.publisher)
      featured_deal.markets << market
      featured_deal.save!
      side_deal = Factory(:side_daily_deal,
                             :publisher => featured_deal.publisher,
                             :start_at => 11.days.from_now,
                             :hide_at => 13.days.from_now)
      side_deal.markets << market
      assert_equal true, side_deal.valid?, "Should be valid"
      assert_nil side_deal.errors.on(:base), "Should not have errors on deal"
    end
    
    test "should allow overlapping featured deal with different market" do
      featured_deal = Factory(:featured_daily_deal,
                              :start_at => 12.days.from_now,
                              :hide_at => 14.days.from_now)
      market_1 = Factory(:market, :publisher => featured_deal.publisher)
      featured_deal.markets << market_1
      featured_deal.save!

      featured_deal_different_market = Factory.build(:featured_daily_deal,
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
      featured_deal = Factory(:featured_daily_deal,
                              :start_at => 12.days.from_now,
                              :hide_at => 14.days.from_now)
      market_1 = Factory(:market, :publisher => featured_deal.publisher)
      featured_deal.markets << market_1
      featured_deal.save!
      
      featured_deal_nil_market = Factory.build(:featured_daily_deal,
                                               :publisher => featured_deal.publisher,
                                               :start_at => 11.days.from_now,
                                               :hide_at => 13.days.from_now)
 
      assert_equal true, featured_deal_nil_market.valid?, "Should be valid, but had errors: #{featured_deal_nil_market.errors.full_messages.join(", ")}"
      assert_nil featured_deal_nil_market.errors.on(:base), "Should not have errors on deal"
    end
    
    test "should allow overlapping featured deal after nil market deal" do
      featured_deal_nil_market = Factory(:featured_daily_deal,
                                         :start_at => 12.days.from_now,
                                         :hide_at => 14.days.from_now)
      
      featured_deal = Factory.build(:featured_daily_deal,
                                    :publisher => featured_deal_nil_market.publisher,
                                    :start_at => 11.days.from_now,
                                    :hide_at => 13.days.from_now)
      market_1 = Factory(:market, :publisher => featured_deal_nil_market.publisher)
      featured_deal.markets << market_1

      assert_equal true, featured_deal.valid?, "Should be valid, but had errors: #{featured_deal.errors.full_messages.join(", ")}"
      assert_nil featured_deal.errors.on(:base), "Should not have errors on deal"
    end

    test "should not allow featured spans to overlap on deals with a side-deal window in the middle of the deal lifespan" do
      Timecop.freeze(Time.zone.now) do
        publisher = Factory(:publisher)

        featured_deal_with_side_window = Factory(:featured_daily_deal, :publisher_id => publisher.id,
                                                 :start_at => 2.weeks.ago, :hide_at => 2.weeks.from_now,
                                                 :side_start_at => 1.week.ago, :side_end_at => 1.week.from_now)

        second_featured_deal_with_side_window = Factory.build(:featured_daily_deal, :publisher_id => publisher.id,
                                                              :start_at => 2.weeks.ago, :hide_at => 2.weeks.from_now,
                                                              :side_start_at => 5.days.ago, :side_end_at => 9.days.from_now)

        assert_equal false, second_featured_deal_with_side_window.valid?
        assert_match /Start at and hide at times overlap with another featured deal/i,
                     second_featured_deal_with_side_window.errors.on(:base), "Should have errors on deal"

      end
    end

    test "should allow featured spans line up right next to each other" do
      Timecop.freeze(Time.zone.now) do
        publisher = Factory(:publisher)
        featured_deal_with_side_window = Factory(:featured_daily_deal, :publisher_id => publisher.id,
                                                 :start_at => 2.weeks.ago, :hide_at => 2.weeks.from_now,
                                                 :side_start_at => 1.week.ago, :side_end_at => 1.week.from_now)
        # 2        1              1       2
        # |-------|              |-------|   First deal: Side deal in the middle
        #         |--------------|       |   Second deal: Starts featured, goes side one second before the first deal goes featured again

        second_featured_deal_with_side_window = Factory.build(:featured_daily_deal, :publisher_id => publisher.id,
                                                              :start_at => 1.week.ago, :hide_at => 2.weeks.from_now,
                                                              :side_start_at => 1.weeks.from_now, :side_end_at => 2.weeks.from_now)

        # Make sure our dates are lined up as expected
        assert_equal featured_deal_with_side_window.side_start_at.to_i, second_featured_deal_with_side_window.start_at.to_i
        assert_equal featured_deal_with_side_window.side_end_at.to_i, second_featured_deal_with_side_window.side_start_at.to_i

        assert_equal true, second_featured_deal_with_side_window.valid?, "Should be valid, but had errors: #{second_featured_deal_with_side_window.errors.full_messages.join(", ")}"
        assert_nil second_featured_deal_with_side_window.errors.on(:base), "Should not have errors on deal"
      end
    end

    test "should not allow featured spans to overlap by a second" do
      Timecop.freeze(Time.zone.now) do
        publisher = Factory(:publisher)
        featured_deal_with_side_window = Factory(:featured_daily_deal, :publisher_id => publisher.id,
                                                 :start_at => 2.weeks.ago, :hide_at => 2.weeks.from_now,
                                                 :side_start_at => 1.week.ago + 1.second, :side_end_at => 1.week.from_now - 1.second)
        # 2        1              1       2
        # |--------|            |-------|    First deal: Side deal in the middle
        #         |--------------|       |   Second deal: Starts featured, goes side one second before the first deal goes featured again

        second_featured_deal_with_side_window = Factory.build(:featured_daily_deal, :publisher_id => publisher.id,
                                                              :start_at => 1.week.ago, :hide_at => 2.weeks.from_now,
                                                              :side_start_at => 1.weeks.from_now, :side_end_at => 2.weeks.from_now)

        # Make sure our dates are lined up as expected
        assert_equal featured_deal_with_side_window.side_start_at.to_i - 1, second_featured_deal_with_side_window.start_at.to_i
        assert_equal featured_deal_with_side_window.side_end_at.to_i + 1, second_featured_deal_with_side_window.side_start_at.to_i

        assert_equal false, second_featured_deal_with_side_window.valid?, "Should have errors"
      end
    end

    test "error message for overlapping featured deals should include the id of the overlapping deal" do
      publisher = Factory(:publisher)
      featured_deal = Factory(:featured_daily_deal,
                              :publisher => publisher,
                              :start_at => 12.days.from_now,
                              :hide_at => 14.days.from_now)

      overlapping_featured_deal = Factory.build(:featured_daily_deal,
                                                :publisher => publisher,
                                                :start_at => 11.days.from_now,
                                                :hide_at => 13.days.from_now)

      assert_equal true, overlapping_featured_deal.invalid?, "Should be invalid"
      assert overlapping_featured_deal.errors.on(:base).include?(featured_deal.id.to_s)
    end

    test "ordered_by_next_featured_in_category should order deals first by featured_in_category then by start_at" do
      publisher = Factory(:publisher)

      daily_deal1 = Factory(:side_daily_deal,
                            :publisher => publisher,
                            :start_at => 10.days.ago,
                            :hide_at => 5.days.ago,
                            :featured_in_category => true)
      daily_deal2 = Factory(:side_daily_deal,
                            :start_at => 20.days.ago,
                            :hide_at => 5.days.ago,
                            :publisher => publisher,
                            :featured_in_category => true)
      daily_deal3 = Factory(:side_daily_deal,
                            :start_at => 10.days.ago,
                            :hide_at => 5.days.ago,
                            :publisher => publisher,
                            :featured_in_category => false)
      daily_deal4 = Factory(:side_daily_deal,
                            :start_at => 20.days.ago,
                            :hide_at => 5.days.ago,
                            :publisher => publisher,
                            :featured_in_category => false)

      daily_deal_ids = publisher.daily_deals.ordered_by_next_featured_in_category.map(&:id)
      assert_equal [daily_deal2.id, daily_deal1.id, daily_deal4.id, daily_deal3.id], daily_deal_ids
    end

    context "DailyDeal#featured_dates" do
      setup do
        @deal_start = 2.weeks.ago
        @deal_end = 2.weeks.from_now
        @side_start = 1.week.ago
        @side_end = 1.week.from_now
      end
      
      should "return an empty array when the deal has been deleted" do
        Timecop.freeze(Time.zone.now) do
          deal = Factory(:daily_deal, :start_at => @deal_start, :hide_at => @deal_end,
                         :side_start_at => @side_start, :side_end_at => @side_end,
                         :deleted_at => 2.days.ago)
          dates = deal.featured_date_ranges
          assert dates.empty?
        end
      end

      should "return an empty array when the side dates span the life of the entire deal" do
        Timecop.freeze(Time.zone.now) do
          deal = Factory(:daily_deal, :start_at => @deal_start, :hide_at => @deal_end,
                         :side_start_at => @deal_start, :side_end_at => @deal_end)
          dates = deal.featured_date_ranges
          assert dates.empty?
        end
      end

      should "return one range equal to the lifespan of the deal when side dates are not present" do
        Timecop.freeze(Time.zone.now) do
          deal = Factory(:daily_deal, :start_at => @deal_start, :hide_at => @deal_end)
          dates = deal.featured_date_ranges
          assert_equal [@deal_start..@deal_end], dates
        end
      end

      should "return one range from side end to end if the deal starts as a side deal and becomes featured" do
        Timecop.freeze(Time.zone.now) do
          deal = Factory(:daily_deal, :start_at => @deal_start, :hide_at => @deal_end,
                         :side_start_at => @deal_start, :side_end_at => @side_end)

          dates = deal.featured_date_ranges
          assert_equal [@side_end..@deal_end], dates
        end
      end

      should "return one range from start to side start if the deal starts featured and ends as a side" do
        Timecop.freeze(Time.zone.now) do
          deal = Factory(:daily_deal, :start_at => @deal_start, :hide_at => @deal_end,
                         :side_start_at => @side_start, :side_end_at => @deal_end)

          dates = deal.featured_date_ranges
          assert_equal [@deal_start..@side_start], dates
        end
      end
      
      should "return two pairs of dates when the deal has a side deal range in the middle of its lifespan" do
        Timecop.freeze(Time.zone.now) do
          deal = Factory(:daily_deal, :start_at => @deal_start, :hide_at => @deal_end,
                         :side_start_at => @side_start, :side_end_at => @side_end)

          # Expecting: [@deal_start..@side_start, @side_end..@deal_end]
          dates = deal.featured_date_ranges
          assert_equal 2, dates.size
          assert_equal @deal_start, dates.first.first
          assert_equal @side_start, dates.first.last
          assert_equal @side_end, dates.second.first
          assert_equal @deal_end, dates.second.last
        end

      end

    end

  end
end
