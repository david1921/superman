require File.dirname(__FILE__) + "/../test_helper"

class DailyDealTest < ActiveSupport::TestCase

  include ActionView::Helpers::NumberHelper
  setup :setup_valid_attributes

  test "should have min quantity" do
    daily_deal = advertisers(:burger_king).daily_deals.create(
      @valid_attributes.merge(:min_quantity => 1)
    )
    assert true, daily_deal.respond_to?(:min_quantity)
    assert_equal 1, daily_deal.min_quantity
  end

  test "should NOT require a min value of 2 if price less then 10" do
    daily_deal = advertisers(:burger_king).daily_deals.create(
      @valid_attributes.merge(:min_quantity => 1, :price => 5.00)
    )
    assert true, daily_deal.respond_to?(:min_quantity)
    assert_no_match /must be at least 2 for deals priced under 10.00/, daily_deal.errors.on(:min_quantity)
  end

  test "default max_quantity" do
    daily_deal = advertisers(:burger_king).daily_deals.create(@valid_attributes.except(:max_quantity))
    assert_equal 10, daily_deal.max_quantity
  end

  test "number left" do
    assert_nil Factory(:daily_deal, :quantity => nil).number_left, "nil quantity"
    assert_equal 12, Factory(:daily_deal, :quantity => 12).number_left, "quantity of 12"

    daily_deal = Factory(:daily_deal, :quantity => 16)
    daily_deal.stubs(:number_sold).returns(14)
    assert_equal 2, daily_deal.number_left, "quantity of 16, sold 14"

    daily_deal = Factory(:daily_deal, :quantity => nil)
    daily_deal.stubs(:number_sold).returns(1_000_000)
    assert_equal nil, daily_deal.number_left, "quantity of nil, sold 1,000,000"
  end

  test "should accept value_proposition_subhead" do
    daily_deal = Factory(:daily_deal, :value_proposition_subhead => "Subordinate value")
    assert_equal "Subordinate value", daily_deal.value_proposition_subhead, "value_proposition_subhead"
  end

  test "associations" do
    assert_not_nil DailyDeal.reflect_on_association( :advertiser )
    assert_not_nil DailyDeal.reflect_on_association( :publisher )
    assert_not_nil DailyDeal.reflect_on_association( :daily_deal_purchases )
  end

  test "should accept hide_serial_number_if_bar_code_is_present" do
    daily_deal = advertisers(:burger_king).daily_deals.create!( @valid_attributes.merge( :hide_serial_number_if_bar_code_is_present => true ) )
    assert daily_deal.hide_serial_number_if_bar_code_is_present?
  end

  test "savings should return the difference between the value and price" do
    daily_deal = advertisers(:burger_king).daily_deals.create!( @valid_attributes )
    assert_equal @valid_attributes[:value] - @valid_attributes[:price], daily_deal.savings
  end

  test "sanitize website url with no http in the advertiser s website url" do
    advertiser = advertisers(:burger_king)
    advertiser.update_attribute(:website_url, "bugerking.com")
    daily_deal = advertiser.daily_deals.create!( @valid_attributes )
    assert_equal "bugerking.com", daily_deal.sanitized_website_url
  end

  test "sanitize website url with no http and uppercase letters in advertiser s website url" do
    advertiser = advertisers(:burger_king)
    advertiser.update_attribute(:website_url, "BugerKing.com")
    daily_deal = advertiser.daily_deals.create!( @valid_attributes )
    assert_equal "bugerking.com", daily_deal.sanitized_website_url, "should downcase url"
  end

  test "sanitize website url with http and uppercase letters in advertiser s website url" do
    advertiser = advertisers(:burger_king)
    advertiser.update_attribute(:website_url, "http://BugerKing.com")
    daily_deal = advertiser.daily_deals.create!( @valid_attributes )
    assert_equal "bugerking.com", daily_deal.sanitized_website_url, "should downcase url"
  end

  test "sanitize website url with https and uppercase letters in advertiser s website url" do
    advertiser = advertisers(:burger_king)
    advertiser.update_attribute(:website_url, "https://BugerKing.com")
    daily_deal = advertiser.daily_deals.create!( @valid_attributes )
    assert_equal "bugerking.com", daily_deal.sanitized_website_url, "should downcase url"
  end

  test "sanitize website url with http and path information" do
    advertiser = advertisers(:burger_king)
    advertiser.update_attribute(:website_url, "http://BugerKing.com/our/menu.pdf")
    daily_deal = advertiser.daily_deals.create!( @valid_attributes )
    assert_equal "bugerking.com", daily_deal.sanitized_website_url, "should downcase url"
  end

  test "sanitize website url with nil" do
    advertiser = advertisers(:burger_king)
    advertiser.update_attribute(:website_url, nil)
    daily_deal = advertiser.daily_deals.create!( @valid_attributes )
    assert_equal "", daily_deal.sanitized_website_url, "should downcase url"
  end

  test "mark as deleted" do
    advertiser = advertisers(:burger_king)
    advertiser.update_attribute(:website_url, nil)
    daily_deal = advertiser.daily_deals.create!( @valid_attributes )
    daily_deal.mark_as_deleted!

    assert daily_deal.deleted?, "should be marked as deleted"
    assert_equal 0, Advertiser.find( advertiser.id ).daily_deals.active.size
    assert_equal 1, Advertiser.find( advertiser.id ).daily_deals.deleted.size
  end

  test "number sold with publisher payment method paypal" do
    BaseDailyDealPurchase.delete_all
    daily_deal = daily_deals(:changos)
    assert daily_deal.publisher.pay_using?(:paypal)

    assert_equal 0, daily_deal.number_sold
    purchase_daily_deal(daily_deal, 1)
    assert_equal 1, daily_deal.number_sold
    purchase_daily_deal(daily_deal, 2)
    assert_equal 3, daily_deal.number_sold
  end

  test "number sold with publisher payment method credit" do
    BaseDailyDealPurchase.delete_all
    daily_deal = daily_deals(:changos)
    daily_deal.publisher.update_attributes! :payment_method => "credit"

    assert_equal 0, daily_deal.number_sold
    purchase_daily_deal(daily_deal, 1)
    assert_equal 1, daily_deal.number_sold
    purchase_daily_deal(daily_deal, 2)
    assert_equal 3, daily_deal.number_sold
  end

  test "ending time in milliseconds with daily deal that is started and ends in 6 minutes 30 seconds" do
    hide_at    = 6.minutes.from_now + 30.seconds
    daily_deal = advertisers(:burger_king).daily_deals.create!( @valid_attributes.merge( :start_at => 30.minutes.ago, :hide_at => hide_at) )
    assert_equal hide_at.to_i * 1000, daily_deal.ending_time_in_milliseconds
  end

  test "today" do
    midnight_today = Time.zone.now.midnight
    advertiser = advertisers(:burger_king)
    advertiser.daily_deals.create!(@valid_attributes.merge(:start_at => midnight_today - 24.hours, :hide_at => midnight_today - 1.seconds))
    daily_deal = advertiser.daily_deals.create!(@valid_attributes.merge(:start_at => midnight_today, :hide_at => midnight_today + 1.day))
    advertiser.daily_deals.create!(@valid_attributes.merge(:start_at => midnight_today + 2.days, :hide_at => midnight_today + 3.days))
    assert_equal daily_deal, publishers(:my_space).daily_deals.active.first
  end

  test "today with time range" do
    daily_deal = advertisers(:burger_king).daily_deals.create!(@valid_attributes.merge(
      :start_at => Time.zone.now - 1.week,
      :hide_at => Time.zone.now + 1.week)
    )
    assert_equal daily_deal, publishers(:my_space).daily_deals.active.first
  end

  test "hide at must be after start at" do
    daily_deal = daily_deals(:burger_king)
    daily_deal.update_attribute(:start_at, 10.days.from_now) # future start_at date to get around the new locking mechanism

    daily_deal.start_at = nil
    daily_deal.hide_at = nil
    assert !daily_deal.valid?, "no start_at nor hide_at"

    daily_deal.start_at = Time.now
    daily_deal.hide_at = nil
    assert !daily_deal.valid?, "no start_at"

    daily_deal.start_at = nil
    daily_deal.hide_at = Time.now
    assert !daily_deal.valid?, "no hide_at"

    now = Time.now
    daily_deal.start_at = now
    daily_deal.hide_at = now
    assert !daily_deal.valid?, "can't start and hide at the same time"

    now = Time.now
    daily_deal.start_at = now
    daily_deal.hide_at = now - 1
    assert !daily_deal.valid?, "hide at before start_at"

    now = Time.now
    daily_deal.start_at = now
    daily_deal.hide_at = now + 1
    assert daily_deal.valid?, "hide at right after start_at"
  end

  test "expires on must be after start at" do
    daily_deal = daily_deals(:burger_king)
    daily_deal.update_attribute(:start_at, 10.days.from_now) # future start_at date to get around the new locking mechanism

    daily_deal.start_at = nil
    daily_deal.expires_on = nil
    assert !daily_deal.valid?, "no start_at nor expires_on"

    daily_deal.start_at = Time.now
    daily_deal.hide_at = Time.now.tomorrow
    daily_deal.expires_on = nil
    assert daily_deal.valid?, "no expires_on"

    daily_deal.start_at = nil
    daily_deal.hide_at = Time.now.tomorrow
    daily_deal.expires_on = Time.now
    assert !daily_deal.valid?, "no start_at"

    now = Time.now
    daily_deal.start_at = now
    daily_deal.hide_at = now + 1.day
    daily_deal.expires_on = now
    assert !daily_deal.valid?, "can't start and expires_on the same time"

    now = Time.now
    daily_deal.start_at = now
    daily_deal.hide_at = now + 1.day
    daily_deal.expires_on = now - 1
    assert !daily_deal.valid?, "expires_on before start_at"

    now = Time.now
    daily_deal.start_at = now
    daily_deal.hide_at = now + 1.minute
    daily_deal.expires_on = now + 1.day
    assert daily_deal.valid?, "expires_on right after start_at, #{daily_deal.errors.full_messages.join(", ")}"
  end

  test "expires on must be after hide at" do
    daily_deal = daily_deals(:burger_king)

    daily_deal.hide_at = nil
    daily_deal.expires_on = nil
    assert !daily_deal.valid?, "no hide_at nor expires_on"

    daily_deal.hide_at = Time.now
    daily_deal.expires_on = nil
    assert daily_deal.valid?, "no expires_on. #{daily_deal.errors.full_messages}"

    daily_deal.hide_at = nil
    daily_deal.expires_on = Time.now
    assert !daily_deal.valid?, "no expires_on"

    now = Time.now
    daily_deal.hide_at = now
    daily_deal.expires_on = now
    assert !daily_deal.valid?, "can't hide_at and expires_on the same time"

    now = Time.now
    daily_deal.hide_at = now
    daily_deal.expires_on = now - 1
    assert !daily_deal.valid?, "expires_on before hide_at"

    now = Time.now
    daily_deal.hide_at = now
    daily_deal.expires_on = now + 1
    assert daily_deal.valid?, "expires_on right after hide_at"
  end

  test "overlapping deals" do
    deal = daily_deals(:burger_king)
    now = Time.zone.now
    deal.update_attribute(:start_at, now)
    deal.update_attribute(:hide_at, now+1.day)

    same_publisher_deal = deal.advertiser.publisher.advertisers.create!.daily_deals.create!(@valid_attributes.merge(
      :start_at => now + 2.days, :hide_at => now + 3.days
    ))
    other_publisher_deal = publishers(:sdreader).advertisers.create!.daily_deals.create!(@valid_attributes)

    same_publisher_deal.update_attribute(:start_at,now - 3.weeks)
    same_publisher_deal.update_attribute(:hide_at,now - 1.week)
    assert same_publisher_deal.valid?, "in the past should be valid, but: #{same_publisher_deal.errors.full_messages.join(", ")}"

    other_publisher_deal.update_attribute(:start_at, now - 3.weeks)
    other_publisher_deal.update_attribute(:hide_at, now - 1.week)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    same_publisher_deal.update_attribute(:start_at, now - 1.week)
    same_publisher_deal.update_attribute(:hide_at, now - 1.second)
    assert same_publisher_deal.valid?, "right before should be valid"

    other_publisher_deal.update_attribute(:start_at, now - 1.week)
    other_publisher_deal.update_attribute(:hide_at, now - 1.second)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    other_publisher_deal.update_attribute(:start_at, now - 1.week)
    other_publisher_deal.update_attribute(:hide_at, now + 20.second)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    same_publisher_deal.update_attribute(:start_at, now)
    same_publisher_deal.update_attribute(:hide_at, now + 1.day)
    assert !same_publisher_deal.valid?, "exact same range as another deal"

    same_publisher_deal.featured = false
    assert same_publisher_deal.valid?, "side deal with exact same range as another deal"

    other_publisher_deal.update_attribute(:start_at, now)
    other_publisher_deal.update_attribute(:hide_at, now + 1.day)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    same_publisher_deal.update_attribute(:start_at,  now + 1.second)
    same_publisher_deal.update_attribute(:hide_at, now + 1.day - 1.second)
    same_publisher_deal.featured = true
    assert !same_publisher_deal.valid?, "can't be within other deal's range"

    same_publisher_deal.featured = false
    assert same_publisher_deal.valid?, "side deal can be within other deal's range"

    other_publisher_deal.update_attribute(:start_at, now + 1.second)
    other_publisher_deal.update_attribute(:hide_at, now + 1.day - 1.second)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    same_publisher_deal.update_attribute(:start_at, now + 1.day - 1.second)
    same_publisher_deal.update_attribute(:hide_at, now + 2.days)
    same_publisher_deal.featured = true
    assert !same_publisher_deal.valid?, "can't be within other deal's range"

    same_publisher_deal.featured = false
    assert same_publisher_deal.valid?, "side deal can be within other deal's range"

    other_publisher_deal.update_attribute(:start_at, now + 1.second)
    other_publisher_deal.update_attribute(:hide_at, now + 2.days)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    same_publisher_deal.update_attribute(:start_at, now + 1.day)
    same_publisher_deal.update_attribute(:hide_at, now + 2.days)
    same_publisher_deal.featured = true
    assert same_publisher_deal.valid?, "start when another deal hides"

    other_publisher_deal.update_attribute(:start_at, now + 1.day)
    other_publisher_deal.update_attribute(:hide_at, now + 2.days)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    same_publisher_deal.update_attribute(:start_at, now + 1.day + 1.second)
    same_publisher_deal.update_attribute(:hide_at, now + 2.days)
    assert same_publisher_deal.valid?, "start a second after another deal hides"

    other_publisher_deal.update_attribute(:start_at, now + 1.day + 1.seconds)
    other_publisher_deal.update_attribute(:hide_at, now + 2.days)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    same_publisher_deal.update_attribute(:start_at, now + 3.days)
    same_publisher_deal.update_attribute(:hide_at, now + 4.days)
    assert same_publisher_deal.valid?, "start after another deal hides"

    other_publisher_deal.update_attribute(:start_at, now + 3.days)
    other_publisher_deal.update_attribute(:hide_at, now + 4.days)
    assert other_publisher_deal.valid?, "other publisher's deal should always be valid"

    deal.featured = false
    deal.save!

    same_publisher_deal.update_attribute(:start_at, now + 1.second)
    same_publisher_deal.update_attribute(:hide_at, now + 1.day - 1.second)
    same_publisher_deal.featured = true
    assert same_publisher_deal.valid?, "can't be within side deal's range"
  end

  context "current or previous" do
    context "without markets" do
      setup do
        @publisher = Factory(:publisher)
        @advertiser = Factory(:advertiser, :publisher => @publisher)
        @daily_deal = @advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.tomorrow, :hide_at => Time.zone.now.tomorrow.end_of_day))
      end

      should "return no deals" do
        assert_nil @publisher.daily_deals.current_or_previous
      end

      should "return deal in the future" do
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
          now_deal = @advertiser.daily_deals.create!(@valid_attributes.merge(
            :start_at => Time.zone.now - 5.minutes, :hide_at => Time.zone.now.end_of_day)
          )
          assert_equal now_deal, @publisher.daily_deals.current_or_previous
        end

      end

      should "return deal with same start_at but is still active and ends later" do
        Timecop.freeze(Time.zone.local(2011, 4, 11, 8, 0, 0)) do
          @daily_deal.start_at = Time.zone.now.beginning_of_day
          @daily_deal.hide_at = Time.zone.now - 30.minutes
          @daily_deal.save!
          concurrent_deal_ends_later = @advertiser.daily_deals.create!(@valid_attributes.merge(
            :start_at => @daily_deal.start_at, :hide_at => Time.zone.now + 30.minutes)
          )
          assert_equal concurrent_deal_ends_later, @publisher.daily_deals.current_or_previous
        end
      end
    end
  end

  context "sold out" do
    setup do
      @daily_deal = advertisers(:burger_king).daily_deals.create(
          @valid_attributes.merge(:min_quantity => 1, :price => 5.00)
      )
    end

    should "not be sold out" do
      assert_equal nil,  @daily_deal.sold_out_at
    end

    should "be have a sold out timestamp" do
      Timecop.freeze(now = Time.now) do
        @daily_deal.sold_out!(true)
        assert_equal now, @daily_deal.sold_out_at
      end
    end

    should "not update the sold out timestamp" do
      Timecop.freeze(now = Time.now) do
        @daily_deal.sold_out!(true)
        assert_equal now, @daily_deal.sold_out_at
      end
      @daily_deal.sold_out!(true)
      assert_equal now, @daily_deal.sold_out_at
    end
  end

  context "side deals" do
    should "side deals without markets" do
      daily_deal = Factory(:side_daily_deal)
      assert_equal [], daily_deal.side_deals, "Side deals"

      daily_deal = Factory(:side_daily_deal)
      same_publisher_deal = Factory(:side_daily_deal, :advertiser => daily_deal.advertiser, :publisher => daily_deal.publisher,
                                    :start_at => Time.zone.now.yesterday, :hide_at => Time.zone.now.tomorrow)
      other_publisher_deal = publishers(:sdreader).advertisers.create!.daily_deals.create!(@valid_attributes)

      assert_equal [ same_publisher_deal ], daily_deal.side_deals, "Side deals"
      assert_equal [ daily_deal ], same_publisher_deal.side_deals, "Side deals"
    end
  end

  context "side deals sorting" do
    setup do
      DailyDeal.destroy_all
      @featured_deal = Factory(:daily_deal,
                              :value_proposition => "featured",
                              :start_at => 3.days.ago,
                              :hide_at => 7.days.from_now)
      @side_deal_1 = Factory(:side_daily_deal,
                            :value_proposition => "side_deal_1",
                            :publisher => @featured_deal.publisher,
                            :start_at => 2.days.ago,
                            :hide_at => 4.days.from_now)
      @side_deal_2 = Factory(:side_daily_deal,
                            :value_proposition => "side_deal_2",
                            :publisher => @featured_deal.publisher,
                            :start_at => 5.days.ago,
                            :hide_at => 1.days.from_now)
      @side_deal_3 = Factory(:side_daily_deal,
                            :value_proposition => "side_deal_3",
                            :publisher => @featured_deal.publisher,
                            :start_at => 5.days.ago,
                            :hide_at => 10.days.from_now)
    end

    should "order by hide at" do
      sorted_deals = @featured_deal.side_deals { |deal| deal.hide_at }
      assert_equal ["side_deal_2", "side_deal_1", "side_deal_3"], sorted_deals.map(&:value_proposition), "should be ordered by hide at"
    end

  end

  test "current or previous for yesterday" do
    publisher = Factory(:publisher)
    advertiser = Factory(:advertiser, :publisher => publisher)

    # deal from yesterday, but none today
    daily_deal = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.yesterday.beginning_of_day, :hide_at => Time.zone.now.yesterday.end_of_day) )
    assert_equal daily_deal, publisher.daily_deals.current_or_previous

    # deal from yesterday to end of today
    daily_deal.start_at = Time.zone.now.yesterday.beginning_of_day
    daily_deal.hide_at = Time.zone.now.end_of_day
    daily_deal.save!
    assert_equal daily_deal, publisher.daily_deals.current_or_previous
  end

  test "active named scope should be dynamic" do
    assert_equal 0, DailyDeal.active.count, "Should have no active deals"
    deal = daily_deals(:burger_king)
    Timecop.freeze 1.minute.from_now do
      now = Time.zone.now
      deal.update_attribute(:start_at, now)
      deal.update_attribute(:hide_at, now + 1.day)
      assert_equal 1, DailyDeal.active.count, "Should have one active deals"
    end
  end

  test "with no purchases" do
    publisher = publishers(:sdh_austin)
    advertiser = publisher.advertisers.first
    daily_deal = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Date.parse("Jan 22, 2010") ) )

    dates = Date.parse("2010-01-20")..Date.parse("2010-01-30")

    assert_equal 0, daily_deal.purchases_count( dates )
    assert_equal 0, daily_deal.purchasers_count( dates )
    assert_equal 0.0, daily_deal.purchases_amount( dates )
  end

  test "big description" do
    daily_deal = daily_deals(:burger_king)
    description = ("This is a big description of exactly 100 charcters. I am typing some nonsense to get the exact number" * 6_300)
    daily_deal.description = description
    daily_deal.save!
    daily_deal.reload
    assert_equal 65_542, daily_deal.description.size, "description"
  end

  test "humanize_value" do
    daily_deal = Factory :daily_deal, :price => 24, :value => "80"
    daily_deal.publisher.update_attribute :currency_code, "GBP"
    assert_equal "£80.00", daily_deal.humanize_value

    daily_deal.publisher.update_attribute :currency_code, "CAD"
    assert_equal "C$80.00", daily_deal.humanize_value
  end

  test "date humanizing methods" do
    Timecop.freeze(Time.zone.local(2012, 1, 3, 8, 0, 0)) do
      daily_deal = Factory(:daily_deal,
                           :start_at => 2.weeks.ago,
                           :hide_at => 2.weeks.from_now,
                           :side_start_at => 1.week.ago,
                           :side_end_at => 1.week.from_now)

      assert_equal "12/20/11 08:00AM PST", daily_deal.humanize_start_at
      assert_equal "01/17/12 08:00AM PST", daily_deal.humanize_hide_at
      assert_equal "12/27/11 08:00AM PST", daily_deal.humanize_side_start_at
      assert_equal "01/10/12 08:00AM PST", daily_deal.humanize_side_end_at
    end
  end

  test "over with currently active deal" do
    daily_deal = advertisers(:burger_king).daily_deals.create!( @valid_attributes.merge( :start_at => Time.zone.now - 10.minutes, :hide_at => Time.zone.now + 30.minutes ) )
    assert daily_deal.active?
    assert !daily_deal.deleted?
    assert !daily_deal.over?
  end

  test "over with deal that has not started" do
    daily_deal = advertisers(:burger_king).daily_deals.create!( @valid_attributes.merge( :start_at => Time.zone.now + 30.minutes, :hide_at => 1.day.from_now ) )
    assert !daily_deal.active?
    assert !daily_deal.deleted?
    assert !daily_deal.over?
  end

  test "over with deal that already ran and not deleted" do
    daily_deal = advertisers(:burger_king).daily_deals.create!( @valid_attributes.merge( :start_at => Time.zone.now - 1.day, :hide_at => Time.zone.now - 30.minutes ) )
    assert !daily_deal.active?
    assert !daily_deal.deleted?
    assert daily_deal.over?
  end

  test "over with deal that already ran and deleted" do
    daily_deal = advertisers(:burger_king).daily_deals.create!( @valid_attributes.merge( :start_at => Time.zone.now - 1.day, :hide_at => Time.zone.now - 30.minutes, :deleted_at => Time.zone.now - 2.hours ) )
    assert !daily_deal.active?
    assert daily_deal.deleted?
    assert !daily_deal.over?
  end

  test "twitter status" do
    daily_deal = advertisers(:changos).daily_deals.create!(@valid_attributes)
    publisher = daily_deal.publisher
    assert_equal "MySDH.com Deal of the Day: $81 value for $39 at Changos #{daily_deal.bit_ly_url}", daily_deal.twitter_status

    publisher.brand_name = nil
    assert_equal "Student Discount Handbook Austin Deal of the Day: $81 value for $39 at Changos #{daily_deal.bit_ly_url}", daily_deal.twitter_status

    daily_deal.twitter_status_text = "Muchos tacos por $39"
    assert_equal "Student Discount Handbook Austin Deal of the Day: Muchos tacos por $39 #{daily_deal.bit_ly_url}", daily_deal.twitter_status
  end

  test "twitter status with publisher daily deal sharing message prefix" do
    publisher = Factory(:publisher, :daily_deal_sharing_message_prefix => "Custom Prefix")
    advertiser = Factory(:advertiser, :publisher => publisher, :name => "Advertiser Name")
    daily_deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    assert_equal "Custom Prefix: $30.00 for only $15.00! at Advertiser Name #{daily_deal.bit_ly_url}", daily_deal.twitter_status

    daily_deal.twitter_status_text = "Custom Status"
    assert_equal "Custom Prefix: Custom Status #{daily_deal.bit_ly_url}", daily_deal.twitter_status
  end

  test "twitter_status with translations" do
    daily_deal = DailyDeal.with_locale(:en) do
      Factory(:daily_deal, :twitter_status_text => "english twitter!")
    end

    I18n.locale = :es

    daily_deal.update_attributes!({:value_proposition => "spanish prop",
                                   :description => "a description in spanish",
                                   :terms => "some terms for you, senor",
                                   :twitter_status_text => "spanish twitter"})

    assert_equal "#{daily_deal.publisher_prefix}: spanish twitter", daily_deal.twitter_status(false)

    I18n.locale = :en

    assert_equal "#{daily_deal.publisher_prefix}: english twitter!", daily_deal.twitter_status(false)
  end

  test "twitter_status blank" do
    daily_deal = Factory(:daily_deal, :twitter_status_text => "")
    assert_equal "#{daily_deal.publisher_prefix}: #{daily_deal.value_proposition} at #{daily_deal.advertiser.name}", daily_deal.twitter_status(false)
  end

  test "facebook title" do
    daily_deal = advertisers(:changos).daily_deals.create!(@valid_attributes)
    publisher = daily_deal.publisher
    assert_equal "MySDH.com Deal of the Day: $81 value for $39", daily_deal.facebook_title

    publisher.brand_name = nil
    assert_equal "Student Discount Handbook Austin Deal of the Day: $81 value for $39", daily_deal.facebook_title

    daily_deal.facebook_title_text = "Muchos tacos por $39"
    assert_equal "Student Discount Handbook Austin Deal of the Day: Muchos tacos por $39", daily_deal.facebook_title
  end

  test "facebook title with publisher daily deal sharing message prefix" do
    publisher = Factory(:publisher, :daily_deal_sharing_message_prefix => "Custom Prefix")
    advertiser = Factory(:advertiser, :publisher => publisher, :name => "Advertiser Name")
    daily_deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    assert_equal "Custom Prefix: $30.00 for only $15.00!", daily_deal.facebook_title

    daily_deal.facebook_title_text = "Custom Title"
    assert_equal "Custom Prefix: Custom Title", daily_deal.facebook_title
  end

  test "facebook_title with translations" do
    daily_deal = DailyDeal.with_locale(:en) do
      Factory(:daily_deal, :facebook_title_text => "english facebook!")
    end

    I18n.locale = :es

    daily_deal.update_attributes!({:value_proposition => "spanish prop",
                                   :description => "a description in spanish",
                                   :terms => "some terms for you, senor",
                                   :facebook_title_text => "spanish facebook"})

    assert_equal "#{daily_deal.publisher_prefix}: spanish facebook", daily_deal.facebook_title

    I18n.locale = :en

    assert_equal "#{daily_deal.publisher_prefix}: english facebook!", daily_deal.facebook_title
  end

  test "facebook_title blank" do
    daily_deal = Factory(:daily_deal, :facebook_title_text => "")
    assert_equal "#{daily_deal.publisher_prefix}: #{daily_deal.value_proposition}", daily_deal.facebook_title
  end

  test "validation of short description" do
    daily_deal = advertisers(:changos).daily_deals.create!(@valid_attributes)
    publisher = daily_deal.publisher

    publisher.require_daily_deal_short_description = true

    daily_deal.short_description = nil
    assert daily_deal.invalid?, "Should not be valid with nil short description"
    assert_match /cannot have blank content/, daily_deal.errors.on(:short_description)

    daily_deal.short_description = " "
    assert daily_deal.invalid?, "Should not be valid with blank short description"
    assert_match /cannot have blank content/, daily_deal.errors.on(:short_description)

    daily_deal.short_description = "x" * 51
    assert daily_deal.invalid?, "Should not be valid with long short description"
    assert_match /is too long/, daily_deal.errors.on(:short_description)

    publisher.require_daily_deal_short_description = false

    daily_deal.short_description = nil
    assert daily_deal.valid?, "Should be valid with nil short description"

    daily_deal.short_description = " "
    assert daily_deal.valid?, "Should be valid with blank short description"

    daily_deal.short_description = "x" * 51
    assert daily_deal.invalid?, "Should not be valid with long short description"
    assert_match /is too long/, daily_deal.errors.on(:short_description)
  end

  test "location_required cannot be set if advertiser has one store" do
    daily_deal = Factory.build(:daily_deal, :location_required => true)
    assert_equal 1, daily_deal.advertiser.stores.length
    assert daily_deal.invalid?, "Should not be valid with location required and only one store"
    assert_match /cannot be set/i, daily_deal.errors.on(:location_required)
  end

  test "location_required can be set if advertiser has two stores" do
    advertiser = Factory(:advertiser)
    Factory :store, :advertiser => advertiser
    assert_equal 2, advertiser.stores(true).count

    daily_deal = Factory.build(:daily_deal, :advertiser => advertiser, :location_required => true)
    assert daily_deal.valid?, "Should be valid with location required and two stores"
  end

  test "business_fine_print" do
    daily_deal = Factory(:daily_deal, :business_fine_print => "some fine print")
    assert_equal "some fine print", daily_deal.business_fine_print
  end

  test "savings_as_percent no savings" do
    daily_deal = Factory(:daily_deal, :price => 100, :value => 100)
    assert_equal 0, daily_deal.savings_as_percentage
  end

  test "savings_as_percent is 100%" do
    daily_deal = Factory(:daily_deal, :price => 0, :value => 100)
    assert_equal 100, daily_deal.savings_as_percentage
  end

  test "if value is zero, saving_as_percent still functions properly" do
    daily_deal = Factory(:daily_deal, :price => 0, :value => 0)
    assert_equal 0, daily_deal.savings_as_percentage
  end

  test "saving_as_percent 60% savings" do
    daily_deal = Factory(:daily_deal, :price => 20, :value => 50)
    assert_equal 60, daily_deal.savings_as_percentage
  end

  test "saving_as_percent 51% and change" do
    daily_deal = Factory(:daily_deal, :price => 39, :value => 81)
    assert_in_delta 51.85, daily_deal.savings_as_percentage, 0.01
  end

  test "number_to_percentage will round with zero precision" do
    daily_deal = Factory(:daily_deal, :price => 39, :value => 81)
    assert_equal "52%", number_to_percentage(daily_deal.savings_as_percentage, :precision => 0)
  end

  test "should show Twitter and Facebook click counts" do
    daily_deal = Factory(:daily_deal)
    assert_equal 0, daily_deal.facebook_clicks, "Facebook click counts"
    assert_equal 0, daily_deal.twitter_clicks, "Twitter click counts"

    daily_deal.record_click "facebook"
    assert_equal 1, daily_deal.facebook_clicks, "Facebook click counts"
    assert_equal 0, daily_deal.twitter_clicks, "Twitter click counts"

    daily_deal.record_click "twitter"
    assert_equal 1, daily_deal.facebook_clicks, "Facebook click counts"
    assert_equal 1, daily_deal.click_counts.twitter.count, "Twitter click counts"

    daily_deal = DailyDeal.find(daily_deal.id)
    daily_deal.record_click "twitter"
    assert_equal 1, daily_deal.facebook_clicks, "Facebook click counts"
    click_count = ClickCount.twitter.first
    assert_equal daily_deal, click_count.clickable
    assert_equal daily_deal.publisher, click_count.publisher
    assert_equal 2, click_count.count
    daily_deal = DailyDeal.find(daily_deal.id)
    assert_equal 2, daily_deal.twitter_clicks, "Twitter click counts"

    daily_deal.record_click "twitter"
    click_count = ClickCount.twitter.first
    assert_equal daily_deal, click_count.clickable
    assert_equal 3, click_count.count
    daily_deal = DailyDeal.find(daily_deal.id)
    assert_equal 3, daily_deal.twitter_clicks, "Twitter click counts"
  end

  test "twitter_publisher_prefix" do
    daily_deal = Factory(:daily_deal, :publisher => Factory(:publisher, :name => "New York Daily News"))
    assert_equal "New York Daily News Deal of the Day", daily_deal.twitter_publisher_prefix

    daily_deal.publisher.brand_name = "NY Daily News"
    assert_equal "NY Daily News Deal of the Day", daily_deal.twitter_publisher_prefix

    daily_deal.publisher.daily_deal_sharing_message_prefix = "NY Daily News"
    assert_equal "NY Daily News", daily_deal.twitter_publisher_prefix

    daily_deal.publisher.daily_deal_twitter_message_prefix = "RT @NY Deal of the Day"
    assert_equal "RT @NY Deal of the Day", daily_deal.twitter_publisher_prefix
  end

  test "past with no deals" do
    assert_equal [], DailyDeal.past(Factory(:publisher)), "daily_deals"
  end

  test "past should only return some deals and not return deleted deals" do
    publisher = Factory(:publisher)
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :publisher => publisher, :advertiser => advertiser)
    13.times {
      daily_deal = Factory(
        :daily_deal, :publisher => publisher, :advertiser => advertiser,
        :start_at => 10.days.ago(daily_deal.start_at),
        :hide_at => 10.days.ago(daily_deal.hide_at)
      )
      Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal)
    }
    deleted_deal = Factory(
      :daily_deal, :publisher => publisher, :advertiser => advertiser,
      :start_at => 10.days.ago(daily_deal.start_at),
      :hide_at => 10.days.ago(daily_deal.hide_at)
    )
    deleted_deal.delete
    assert_equal 12, DailyDeal.past(publisher, 1).size, "daily_deals"
  end

  test "past should sort by number_sold, date" do
    publisher = Factory(:publisher)
    advertiser = Factory(:advertiser, :publisher => publisher)

    old_popular_deal = Factory(:daily_deal, :start_at => 5.weeks.ago, :hide_at => 4.weeks.ago,
                               :publisher => publisher, :advertiser => advertiser)
    Factory(:captured_daily_deal_purchase, :daily_deal => old_popular_deal)
    Factory(:captured_daily_deal_purchase, :daily_deal => old_popular_deal)
    Factory(:captured_daily_deal_purchase, :daily_deal => old_popular_deal)

    old_deal = Factory(:daily_deal, :start_at => 2.weeks.ago, :hide_at => 1.weeks.ago,
                       :publisher => publisher, :advertiser => advertiser)
    Factory(:captured_daily_deal_purchase, :daily_deal => old_deal)

    newer_deal = Factory(:daily_deal, :start_at => 2.days.ago, :hide_at => Time.zone.now.yesterday,
                         :publisher => publisher, :advertiser => advertiser)
    Factory(:captured_daily_deal_purchase, :daily_deal => newer_deal)
    Factory(:captured_daily_deal_purchase, :daily_deal => newer_deal)

    daily_deals = DailyDeal.past(publisher, 1)
    assert_equal [ old_popular_deal, newer_deal, old_deal ], daily_deals, "daily_deals"
  end

  test "todays returns empty array if there are no deals for a given publisher" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    assert_equal [], publisher.daily_deals.todays
  end

  test "todays returns a deal if there is a single deal for today for a given publisher" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    daily_deal = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day, :hide_at => Time.zone.now.end_of_day))
    assert_equal [daily_deal], publisher.daily_deals.todays
  end

  test "todays returns a deal if it spans a day but neither starts nor ends on the day" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    daily_deal = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day - 1.day, :hide_at => Time.zone.now.end_of_day + 1.day))
    assert_equal [daily_deal], publisher.daily_deals.todays
  end

  test "todays returns a deal if it is starts and ends on the same day" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    daily_deal = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.end_of_day - 2.hours, :hide_at => Time.zone.now.end_of_day - 1.hour))
    assert_equal [daily_deal], publisher.daily_deals.todays
  end

  test "todays returns a deal if it starts before the day starts but ends on the day" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    daily_deal = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day - 2.days, :hide_at => Time.zone.now.end_of_day - 2.hours))
    assert_equal [daily_deal], publisher.daily_deals.todays
  end

  test "todays returns a deal if it starts after the day starts but ends after the day ends" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    daily_deal = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day + 2.hours, :hide_at => Time.zone.now.end_of_day + 2.days))
    assert_equal [daily_deal], publisher.daily_deals.todays
  end

  test "todays returns multiple deals if they exist for today for a given publisher" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    daily_deal1 = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day, :hide_at => Time.zone.now.beginning_of_day + 10.hours))
    daily_deal2 = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day + 10.hours + 5.minutes, :hide_at => Time.zone.now.end_of_day))
    assert_equal [daily_deal1, daily_deal2], publisher.daily_deals.todays
  end

  test "todays returns multiple deals in the order they will occur in even if they were made in a different order" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    daily_deal2 = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day + 10.hours + 5.minutes, :hide_at => Time.zone.now.end_of_day))
    daily_deal1 = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day, :hide_at => Time.zone.now.beginning_of_day + 10.hours))
    assert_equal [daily_deal1, daily_deal2], publisher.daily_deals.todays
  end

  test "todays ignores past deals for a given publisher" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.yesterday.beginning_of_day, :hide_at => Time.zone.now.yesterday.end_of_day))
    advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.ago(2.weeks + 2.days), :hide_at => Time.zone.now.ago(2.weeks + 1.day).end_of_day))
    assert_equal [], publisher.daily_deals.todays
  end

  test "todays ignores future deals for a given publisher" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.tomorrow.beginning_of_day, :hide_at => Time.zone.now.tomorrow.end_of_day))
    advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now + 2.weeks, :hide_at => Time.zone.now + 3.weeks))
    assert_equal [], publisher.daily_deals.todays
  end

  test "today returns first item from todays" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    daily_deal2 = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day + 10.hours + 5.minutes, :hide_at => Time.zone.now.end_of_day))
    daily_deal1 = advertiser.daily_deals.create!( @valid_attributes.merge(:start_at => Time.zone.now.beginning_of_day, :hide_at => Time.zone.now.beginning_of_day + 10.hours))
    assert_equal daily_deal1, publisher.daily_deals.today
  end

  test "in_order" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    advertiser.daily_deals.clear
    assert_equal [], publisher.daily_deals.in_order
    deals = [
      Factory.create(:daily_deal, :advertiser => advertiser, :start_at => Time.zone.now.beginning_of_day - 3.days, :hide_at => Time.zone.now.beginning_of_day - 2.days),
      Factory.create(:daily_deal, :advertiser => advertiser, :start_at => Time.zone.now.beginning_of_day + 2.days, :hide_at => Time.zone.now.beginning_of_day + 3.days),
      Factory.create(:daily_deal, :advertiser => advertiser, :start_at => Time.zone.now.beginning_of_day, :hide_at => Time.zone.now.beginning_of_day + 1.days),
      Factory.create(:daily_deal, :advertiser => advertiser, :start_at => Time.zone.now.beginning_of_day - 4.days, :hide_at => Time.zone.now.beginning_of_day - 3.days)
    ]
    assert_equal [deals[3], deals[0], deals[2], deals[1]], publisher.daily_deals.in_order
  end

  test "daily_deals.active with no side deals" do
    publisher = Factory(:publisher)
    assert publisher.daily_deals.active.empty?, "Should have no active deals if no deals"
  end

  test "no daily_deals.active if just one active deal" do
    daily_deal = Factory(:daily_deal)
    assert_equal [ daily_deal ], daily_deal.publisher.daily_deals.active, "Should one active deal"
  end

  test "daily_deals.active should find side deal" do
    publisher = Factory(:publisher)
    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = Factory(:daily_deal, :advertiser => advertiser)

    advertiser = advertiser = Factory(:advertiser, :publisher => publisher)
    side_deal = Factory(:side_daily_deal, :advertiser => advertiser)

    daily_deals = daily_deal.publisher.daily_deals.active
    assert_equal 2, daily_deals.size, "Active deals"
    assert daily_deals.include?(daily_deal), "Featured deal"
    assert daily_deals.include?(side_deal), "Side deal"
    assert_equal daily_deal, daily_deal.publisher.daily_deals.current_or_previous, "current_or_previous"
  end

  test "daily_deals.active should find current featured deal and side deals out of several deals" do
    publisher = Factory(:publisher)
    advertiser = Factory(:advertiser, :publisher => publisher)
    now = Time.zone.today

    # Expired deals
    Factory(:daily_deal, :advertiser => advertiser, :start_at => 4.days.ago, :hide_at => 3.days.ago, :value_proposition => "expired")
    Factory(:side_daily_deal, :advertiser => advertiser, :start_at => 4.days.ago, :hide_at => 3.days.ago, :value_proposition => "expired side deal")

    daily_deal = Factory(:daily_deal, :advertiser => advertiser, :value_proposition => "deal", :start_at => 2.days.ago, :hide_at => 1.day.from_now)
    side_deal = Factory(:side_daily_deal, :advertiser => advertiser, :value_proposition => "side deal", :start_at => 2.days.ago, :hide_at => 1.day.from_now)
    side_deal_2 = Factory(:side_daily_deal, :advertiser => advertiser, :value_proposition => "side deal 2", :start_at => 2.days.ago, :hide_at => 1.day.from_now)

    # Future deals
    Factory(:daily_deal, :advertiser => advertiser, :start_at => 2.days.from_now, :hide_at => 3.days.from_now, :value_proposition => "future")
    Factory(:side_daily_deal, :advertiser => advertiser, :start_at => 2.days.from_now, :hide_at => 5.days.from_now, :value_proposition => "future side")

    other_publisher = Factory(:publisher)
    other_advertiser = Factory(:advertiser, :publisher => other_publisher)
    Factory(:daily_deal, :advertiser => other_advertiser, :value_proposition => "other publisher", :start_at => 2.days.ago, :hide_at => 1.day.from_now)
    Factory(:side_daily_deal, :advertiser => other_advertiser, :value_proposition => "other publisher side", :start_at => 2.days.ago, :hide_at => 1.day.from_now)

    daily_deals = daily_deal.publisher.daily_deals.active
    assert_equal 3, daily_deals.size, "Active deals"
    assert daily_deals.include?(daily_deal), "Should have featured deal"
    assert daily_deals.include?(side_deal), "Should have side deal"
    assert daily_deals.include?(side_deal_2), "Should have side deal"
    assert_equal daily_deal, daily_deal.publisher.daily_deals.current_or_previous, "current_or_previous"
  end

  test "now should be in publisher time zone" do
    daily_deal = Factory(:daily_deal)
    assert_equal_dates Time.zone.now, daily_deal.now
  end

  test "affiliate_revenue_share_percentage" do
    daily_deal = Factory(:daily_deal)
    assert_nil daily_deal.affiliate_revenue_share_percentage
    daily_deal.affiliate_revenue_share_percentage = 10.30
    daily_deal.save
    assert_equal 10.30, daily_deal.affiliate_revenue_share_percentage
    daily_deal.affiliate_revenue_share_percentage = 0.0
    daily_deal.save
    assert daily_deal.errors.on(:affiliate_revenue_share_percentage)
  end

  test "line_item_name should use publisher's currency code" do
    advertiser = Factory(:advertiser, :name => "test advertiser")
    daily_deal = Factory(:daily_deal, :advertiser => advertiser, :price => 21, :value => 60)
    assert_equal "USD", daily_deal.publisher.currency_code
    assert_equal "$60.00 Deal to test advertiser", daily_deal.line_item_name

    daily_deal.publisher.update_attributes :currency_code => "GBP"
    assert_equal "£60.00 Deal to test advertiser", daily_deal.line_item_name

    daily_deal.publisher.update_attributes :currency_code => "CAD"
    assert_equal "C$60.00 Deal to test advertiser", daily_deal.line_item_name
  end

  test "publishers_with_purchase_totals_for_24h_and_30d" do
    yesterday_start = Time.zone.now.yesterday.beginning_of_day

    gbp_pub_1 = Factory :gbp_publisher, :name => "GBP 1"
    gbp_pub_2 = Factory :gbp_publisher, :currency_code => "GBP", :name => "GBP 2"
    gbp_advertiser_1 = Factory :advertiser, :publisher => gbp_pub_1
    gbp_advertiser_2 = Factory :advertiser, :publisher => gbp_pub_1
    gbp_advertiser_3 = Factory :advertiser, :publisher => gbp_pub_2
    gbp_deal_1 = Factory :daily_deal, :advertiser => gbp_advertiser_1, :price => 18, :value => 50
    gbp_deal_2 = Factory :side_daily_deal, :advertiser => gbp_advertiser_2, :price => 23, :value => 60
    gbp_ddp_pending = Factory :pending_daily_deal_purchase, :daily_deal => gbp_deal_1, :executed_at => yesterday_start + 1.minute
    gbp_ddp_authorized = Factory :authorized_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => yesterday_start + 5.minutes
    gbp_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => yesterday_start + 30.minutes
    gbp_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => yesterday_start + 10.hours
    gbp_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_1, :executed_at => yesterday_start + 18.hours
    older_gbp_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => 5.days.ago
    older_gbp_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_2, :executed_at => 7.days.ago
    older_gbp_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => gbp_deal_1, :executed_at => 12.days.ago

    usd_pub_1 = Factory :usd_publisher, :name => "USD 1"
    usd_pub_2 = Factory :usd_publisher, :name => "USD 2"
    usd_pub_3 = Factory :usd_publisher, :name => "USD 3"
    usd_advertiser_1 = Factory :advertiser, :publisher => usd_pub_1
    usd_advertiser_2 = Factory :advertiser, :publisher => usd_pub_2
    usd_advertiser_3 = Factory :advertiser, :publisher => usd_pub_2
    usd_deal_1 = Factory :daily_deal, :advertiser => usd_advertiser_1, :price => 12, :value => 30
    usd_deal_2 = Factory :side_daily_deal, :advertiser => usd_advertiser_2, :price => 18, :value => 40
    usd_ddp_pending = Factory :pending_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => yesterday_start + 45.minutes
    usd_ddp_authorized = Factory :authorized_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => yesterday_start + 3.hours
    usd_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => yesterday_start + 4.hours
    usd_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => yesterday_start + 7.hours
    usd_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => yesterday_start + 9.hours
    usd_ddp_captured_4 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => yesterday_start + 12.hours
    usd_ddp_captured_5 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => yesterday_start + 22.hours
    older_usd_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => 5.days.ago
    older_usd_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_2, :executed_at => 7.days.ago
    older_usd_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => usd_deal_1, :executed_at => 12.days.ago

    cad_pub_1 = Factory :cad_publisher, :name => "cad 1"
    cad_pub_2 = Factory :cad_publisher, :name => "cad 2"
    cad_advertiser_1 = Factory :advertiser, :publisher => cad_pub_1
    cad_advertiser_2 = Factory :advertiser, :publisher => cad_pub_1
    cad_advertiser_3 = Factory :advertiser, :publisher => cad_pub_2
    can_deal_1 = Factory :daily_deal, :advertiser => cad_advertiser_1, :price => 19, :value => 51
    can_deal_2 = Factory :side_daily_deal, :advertiser => cad_advertiser_2, :price => 24, :value => 61
    can_ddp_pending = Factory :pending_daily_deal_purchase, :daily_deal => can_deal_1, :executed_at => yesterday_start + 1.minute
    can_ddp_authorized = Factory :authorized_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => yesterday_start + 5.minutes
    can_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => yesterday_start + 30.minutes
    can_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => yesterday_start + 10.hours
    can_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_1, :executed_at => yesterday_start + 18.hours
    older_can_ddp_captured_1 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => 5.days.ago
    older_can_ddp_captured_2 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_2, :executed_at => 7.days.ago
    older_can_ddp_captured_3 = Factory :captured_daily_deal_purchase, :daily_deal => can_deal_1, :executed_at => 12.days.ago

    gbp_totals = DailyDeal.publishers_with_purchase_totals_for_24h_and_30d(:gbp).sort { |a, b| a[0].name <=> b[0].name }
    assert_equal 1, gbp_totals.length
    assert_equal "GBP 1", gbp_totals[0][0].name
    assert_equal "£64.00", number_to_currency(gbp_totals[0][1][:in_24h], :unit => "£")
    assert_equal "£128.00", number_to_currency(gbp_totals[0][1][:in_30d], :unit => "£")

    usd_totals = DailyDeal.publishers_with_purchase_totals_for_24h_and_30d(:usd).sort { |a, b| a[0].name <=> b[0].name }
    assert_equal 2, usd_totals.length
    assert_equal "USD 1", usd_totals[0][0].name
    assert_equal "$36.00", number_to_currency(usd_totals[0][1][:in_24h], :unit => "$")
    assert_equal "$48.00", number_to_currency(usd_totals[0][1][:in_30d], :unit => "$")

    assert_equal "USD 2", usd_totals[1][0].name
    assert_equal "$36.00", number_to_currency(usd_totals[1][1][:in_24h], :unit => "$")
    assert_equal "$72.00", number_to_currency(usd_totals[1][1][:in_30d], :unit => "$")

    cad_totals = DailyDeal.publishers_with_purchase_totals_for_24h_and_30d(:cad).sort { |a, b| a[0].name <=> b[0].name }
    assert_equal 1, cad_totals.length
    assert_equal "cad 1", cad_totals[0][0].name
    assert_equal "C$67.00", number_to_currency(cad_totals[0][1][:in_24h], :unit => "C$")
    assert_equal "C$134.00", number_to_currency(cad_totals[0][1][:in_30d], :unit => "C$")
  end


  context "#cobrand_deal_vouchers" do

    setup do
      @source_deal = Factory :daily_deal_for_syndication
      @syndicated_publisher = Factory :publisher
    end

    should "be allowed to be true on a syndication source deal" do
      assert !@source_deal.syndicated?
      assert_nil @source_deal.cobrand_deal_vouchers
      assert @source_deal.valid?

      @source_deal.update_attribute :cobrand_deal_vouchers, true
      assert @source_deal.valid?
    end

    should "be required to be nil on a syndicated deal" do
      syndicated_deal = syndicate @source_deal, @syndicated_publisher
      assert_nil syndicated_deal.cobrand_deal_vouchers
      assert syndicated_deal.valid?
      syndicated_deal.cobrand_deal_vouchers = true
      assert syndicated_deal.invalid?
      assert_equal "Cobrand deal vouchers must be nil for syndicated deals", syndicated_deal.errors.on(:cobrand_deal_vouchers)
    end

    should "return the value of cobrand_deal_vouchers of the source syndication deal when called on a syndicated deal" do
      syndicated_deal = syndicate @source_deal, @syndicated_publisher
      assert_nil @source_deal.cobrand_deal_vouchers
      assert_nil syndicated_deal.cobrand_deal_vouchers

      @source_deal.update_attribute :cobrand_deal_vouchers, false
      assert_equal false, syndicated_deal.reload.cobrand_deal_vouchers

      @source_deal.update_attribute :cobrand_deal_vouchers, true
      assert_equal true, syndicated_deal.reload.cobrand_deal_vouchers
    end

  end

  test "shopping_mall" do
    assert !Factory(:daily_deal).shopping_mall?, "#shopping_mall should default to false"
  end

  test "shopping_mall scope" do
    mall_dd      = Factory(:side_daily_deal, :shopping_mall => true)
    publisher    = mall_dd.publisher
    mall_dd2     = Factory(:side_daily_deal, :shopping_mall => true, :publisher => publisher)
    featured_dd  = Factory(:daily_deal, :publisher => publisher)
    random_dd    = Factory(:side_daily_deal, :publisher => publisher)

    assert_equal 3, publisher.daily_deals.shopping_mall_or_featured.size
    [featured_dd, mall_dd2, mall_dd].each do |expected|
      assert publisher.daily_deals.shopping_mall_or_featured.include?(expected)
    end
  end

  test "update deal with custom email_voucher_redemption_message" do
    publisher   = Factory(:publisher, :label => "clickondetriot")
    advertiser  = Factory(:advertiser, :publisher => publisher )
    daily_deal  = advertiser.daily_deals.create!( @valid_attributes )
    daily_deal.email_voucher_redemption_message = "custom message that is better"
    daily_deal.save!
    assert_equal "custom message that is better", daily_deal.reload.email_voucher_redemption_message
  end

  test "create deal with publisher.allow_admins_to_edit_advertiser_revenue_share_percentage to false with ad rev percent sent" do
    publisher  = Factory(:publisher, :allow_admins_to_edit_advertiser_revenue_share_percentage => false)
    advertiser = Factory(:advertiser, :publisher => publisher)

    assert_raise ActiveRecord::RecordInvalid do
      Factory(:daily_deal, :advertiser => advertiser, :advertiser_revenue_share_percentage => 2)
    end
  end

  test "create deal with publisher.allow_admins_to_edit_advertiser_revenue_share_percentage to false and rev percent not sent" do
    publisher  = Factory(:publisher, :allow_admins_to_edit_advertiser_revenue_share_percentage => false)
    advertiser = Factory(:advertiser, :publisher => publisher)
    dd = Factory(:daily_deal, :advertiser => advertiser)

    assert dd.errors.empty?
  end

  test "ignore_short_description_size" do
    publisher = Factory(:publisher, :ignore_daily_deal_short_description_size => true)
    advertiser = Factory(:advertiser, :publisher => publisher)
    dd = Factory(:daily_deal, :advertiser => advertiser,
                :short_description => "This description is not shorter than 50 characters which will hopefully prove this test works and everything is good")

    assert dd.errors.empty?
  end

  test "show_on_landing_page named scope" do
    deal_1 = Factory :daily_deal, :show_on_landing_page => false
    deal_2 = Factory :daily_deal, :show_on_landing_page => true
    assert_equal [deal_2], DailyDeal.show_on_landing_page
  end

  context "daily deal analytic category" do

    setup do
      @dining     = Factory(:daily_deal_category, :name => "Dining", :publisher_id => nil)
      @education  = Factory(:daily_deal_category, :name => "Education", :publisher_id => nil)
    end

    should "have @dining in analytics daily deal categories" do
      assert DailyDealCategory.analytics.include?( @dining )
    end

    should "have @education in analytics daily deal categories" do
      assert DailyDealCategory.analytics.include?( @education )
    end

    context "with no publisher specific categories" do

      setup do
        @publisher  = Factory(:publisher)
        @daily_deal = Factory(:daily_deal, :publisher => @publisher)
      end

      should "have 2 categories" do
        assert_equal 2, DailyDealCategory.analytics.size
      end

      should "have @dining category" do
        assert DailyDealCategory.analytics.include?( @dining )
      end

      should "have @education category" do
        assert DailyDealCategory.analytics.include?( @education )
      end

    end

    context "with a publisher with specific categories" do

      setup do
        @publisher  = Factory(:publisher)
        @daily_deal = Factory(:daily_deal, :publisher => @publisher)
        @automotive = Factory(:daily_deal_category, :name => "Automotive", :publisher => @publisher)
      end

      should "have 2 categories" do
        assert_equal 2, DailyDealCategory.analytics.size
      end

      should "have @automotive" do
        assert !DailyDealCategory.analytics.include?( @automotive )
      end

      should "not have @dining" do
        assert DailyDealCategory.analytics.include?( @dining )
      end

      should "not have @education" do
        assert DailyDealCategory.analytics.include?( @education )
      end

    end

    context "with a publishing group with specific categories" do

      setup do
        @publishing_group = Factory(:publishing_group)
        @publisher        = Factory(:publisher, :publishing_group => @publishing_group )
        @daily_deal       = Factory(:daily_deal, :publisher => @publisher )
        @home_improvement = Factory(:daily_deal_category, :name => "Home Improvement", :publishing_group => @publishing_group)
      end

      should "have 2 categories" do
        assert_equal 2, DailyDealCategory.analytics.size
      end

      should "not have @home_improvement" do
        assert !DailyDealCategory.analytics.include?( @home_improvement )
      end

      should "have @dining" do
        assert DailyDealCategory.analytics.include?( @dining )
      end

      should "have @education" do
        assert DailyDealCategory.analytics.include?( @education )
      end

    end

  end

  context "daily deal publisher category" do

    setup do
      DailyDealCategory.destroy_all
    end

    context "with publisher enabled for daily deal categories" do


      context "with categories associated to the publisher" do

        setup do
          @publisher  = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
          @dining     = Factory(:daily_deal_category, :name => "Dining", :publisher_id => @publisher.id)
          @education  = Factory(:daily_deal_category, :name => "Education", :publisher_id => @publisher.id)
          @daily_deal = Factory(:daily_deal, :publisher => @publisher)
        end

        should "have 2 categories on publisher" do
          assert_equal 2, @publisher.daily_deal_categories.size
        end

        should "not be able to assign a non-publisher category to publisher category" do
          @automotive = Factory(:daily_deal_category, :name => "Automotive", :publisher_id => nil)
          @daily_deal.update_attribute(:publishers_category, @automotive)
          assert !@daily_deal.valid?
        end

        should "be able to assign a publisher category" do
          @daily_deal.update_attribute(:publishers_category, @dining)
          assert @daily_deal.valid?
        end

      end

      context "with categories associated to the publishing group" do

        setup do
          @publishing_group = Factory(:publishing_group)
          @publisher        = Factory(:publisher, :publishing_group => @publishing_group, :enable_publisher_daily_deal_categories => true)
          @dining           = Factory(:daily_deal_category, :name => "Dining", :publishing_group_id => @publishing_group.id)
          @education        = Factory(:daily_deal_category, :name => "Education", :publishing_group_id => @publishing_group.id)
          @daily_deal       = Factory(:daily_deal, :publisher => @publisher)
        end

        should "have 2 categories on publishing_group" do
          assert_equal 2, @publishing_group.daily_deal_categories.size
        end

        should "not be able to assign a non-publishing group category to publisher category" do
          @automotive = Factory(:daily_deal_category, :name => "Automotive", :publisher_id => nil)
          @daily_deal.update_attribute(:publishers_category, @automotive)
          assert !@daily_deal.valid?
        end

        should "be able to assign a publishing group category" do
          @daily_deal.update_attribute(:publishers_category, @dining)
          assert @daily_deal.valid?
        end

      end

    end

    context "without the publisher being enabled for publisher daily deal categorires" do

      setup do
        @publisher  = Factory(:publisher, :enable_publisher_daily_deal_categories => false)
        @dining     = Factory(:daily_deal_category, :name => "Dining", :publisher_id => @publisher.id)
        @education  = Factory(:daily_deal_category, :name => "Education", :publisher_id => @publisher.id)
        @daily_deal = Factory(:daily_deal, :publisher => @publisher)
      end

      should "not be able to set a publisher category" do
        @daily_deal.update_attribute(:publishers_category, @dining)
        assert !@daily_deal.valid?
        assert_equal "Publishers category must enable publisher daily deal categories on the publisher.", @daily_deal.errors.on(:publishers_category)
      end

    end

  end

  test "should be versioned" do
    assert DailyDeal.versioned?
  end

  test "should version advertiser_revenue_share_percentage" do
    daily_deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => nil, :price => 15.00)
    daily_deal.update_attribute(:quantity, 23)
    # at 2 because :price is set initially
    assert_equal 2, daily_deal.version
    daily_deal.update_attribute(:advertiser_revenue_share_percentage, 2)
    assert_equal 3, daily_deal.version
  end

  test "should version price" do
    daily_deal = Factory(:daily_deal, :price => 15.00)
    daily_deal.update_attribute(:quantity, 43)
    # at 2 because :price is set initially
    assert_equal 2, daily_deal.version
    daily_deal.update_attribute(:price, 16.00)
    assert_equal 3, daily_deal.version
  end

  test "should use User.current to capture updated_by in versioning" do
    User.current = Factory(:admin)
    daily_deal = Factory(:daily_deal)
    daily_deal.update_attribute(:advertiser_revenue_share_percentage, 2)
    assert_equal User.current.id, daily_deal.versions.last.user.id
  end

  test "last_author_for should return the user of who edited column last" do
    admin = Factory(:admin)
    user = Factory(:user)
    User.current = admin
    daily_deal = Factory(:daily_deal)
    author = daily_deal.last_author_for(:advertiser_revenue_share_percentage)

    assert_equal nil, author

    daily_deal.update_attribute(:advertiser_revenue_share_percentage, 2)
    author = daily_deal.last_author_for(:advertiser_revenue_share_percentage)

    assert_equal admin, author

    User.current = user
    daily_deal.update_attribute(:advertiser_revenue_share_percentage, 3)
    author = daily_deal.last_author_for(:advertiser_revenue_share_percentage)

    assert_equal user, author

    author = daily_deal.last_author_for(:price)

    assert_equal admin, author
    assert_equal nil, daily_deal.last_author_for(:random_column)
  end

  test "should validate advertiser_revenue_share_percentage if require_advertiser_revenue_share_percentage is true" do
    publisher = Factory(:publisher, :require_advertiser_revenue_share_percentage => true)
    daily_deal = Factory.build(:daily_deal, :publisher => publisher, :advertiser_revenue_share_percentage => "")
    assert !daily_deal.valid?
    assert daily_deal.errors.on(:advertiser_revenue_share_percentage)
  end

  test "should allow blank advertiser_revenue_share_percentage if require_advertiser_revenue_share_percentage is false" do
    publisher = Factory(:publisher, :require_advertiser_revenue_share_percentage => false)
    daily_deal = Factory.build(:daily_deal, :publisher => publisher, :advertiser_revenue_share_percentage => "")
    assert daily_deal.valid?
  end

  test "should allow nil advertiser_revenue_share_percentage if require_advertiser_revenue_share_percentage is false" do
    publisher = Factory(:publisher, :require_advertiser_revenue_share_percentage => false)
    daily_deal = Factory.build(:daily_deal, :publisher => publisher, :advertiser_revenue_share_percentage => nil)
    assert daily_deal.valid?
  end

  test "should allow 100% for advertiser_revenue_share_percentage if require_advertiser_revenue_share_percentage is true" do
    publisher = Factory(:publisher, :require_advertiser_revenue_share_percentage => true)
    daily_deal = Factory.build(:daily_deal, :publisher => publisher, :advertiser_revenue_share_percentage => 100)
    assert daily_deal.valid?
  end

  test "in_publishers_categories scope" do
    publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
    categories = []
    daily_deals = []

    # Create two deals in each of three categories
    3.times do |i|
      categories << category = Factory(:daily_deal_category, :name => "Category #{i}", :publisher => publisher)
      publisher.reload
      2.times do |j|
        daily_deals << Factory(:side_daily_deal, :publisher => publisher, :publishers_category => category)
      end
    end

    # assert that when called with one or two categories, only deals that match are returned
    [[categories.first], categories[0..1]].each do |cats|
      expected_deals = daily_deals.select { |dd| cats.include? dd.publishers_category }
      result = DailyDeal.in_publishers_categories(cats)

      expected_deals.each do |daily_deal|
        assert_contains result.map(&:id), daily_deal.id
      end

      unexpected_deals = (daily_deals - expected_deals)
      unexpected_deals.each do |daily_deal|
        assert_does_not_contain result.map(&:id), daily_deal.id
      end
    end
  end

  context "translated daily deal attributes" do
    setup do
      I18n.stubs(:locale).returns(:en)
      @daily_deal = Factory(:daily_deal, :value_proposition => "100 Tacos for $20")
    end

    should "save translations based on locale" do
      I18n.stubs(:locale).returns(:es)
      @daily_deal.update_attribute(:value_proposition, '100 Tacos de $ 20')
      assert_equal '100 Tacos de $ 20', @daily_deal.value_proposition

      I18n.stubs(:locale).returns(:en)
      assert_equal '100 Tacos for $20', @daily_deal.value_proposition

      I18n.stubs(:locale).returns(:es)
      assert_equal '100 Tacos de $ 20', @daily_deal.value_proposition
    end

    should "fallback to english translations when spanish not given" do
      I18n.stubs(:locale).returns(:es)
      assert_equal '100 Tacos for $20', @daily_deal.reload.value_proposition
    end
  end

  test "time remaining text display" do
    Timecop.freeze(Time.zone.local(2011, 4, 14, 12, 0, 0)) do

      start_at = Time.zone.local(2011, 4, 14, 11, 0, 0)

      deal_day_remaining = Factory(:daily_deal,
                                   :start_at => start_at,
                                   :hide_at => Time.zone.local(2011, 4, 15, 12, 35, 0))
      assert_equal "1 day", deal_day_remaining.time_remaining_text_display

      deal_days_remaining = Factory(:daily_deal,
                                   :start_at => start_at,
                                   :hide_at => Time.zone.local(2011, 4, 17, 13, 0, 0))
      assert_equal "3 days", deal_days_remaining.time_remaining_text_display

      deal_hour_remaining = Factory(:daily_deal,
                                   :start_at => start_at,
                                   :hide_at => Time.zone.local(2011, 4, 14, 13, 1, 0))
      assert_equal "1 hour", deal_hour_remaining.time_remaining_text_display

      deal_hours_remaining = Factory(:daily_deal,
                                   :start_at => start_at,
                                   :hide_at => Time.zone.local(2011, 4, 14, 15, 1, 0))
      assert_equal "3 hours", deal_hours_remaining.time_remaining_text_display

      deal_min_remaining = Factory(:daily_deal,
                                   :start_at => start_at,
                                   :hide_at => Time.zone.local(2011, 4, 14, 12, 1, 56))
      assert_equal "1 min", deal_min_remaining.time_remaining_text_display

      deal_mins_remaining = Factory(:daily_deal,
                                   :start_at => start_at,
                                   :hide_at => Time.zone.local(2011, 4, 14, 12, 3, 56))
      assert_equal "3 mins", deal_mins_remaining.time_remaining_text_display

      deal_min_remaining = Factory(:daily_deal,
                                   :start_at => start_at,
                                   :hide_at => Time.zone.local(2011, 4, 14, 12, 0, 56))
      assert_equal "0 mins", deal_min_remaining.time_remaining_text_display

      deal_min_remaining = Factory(:daily_deal,
                                   :start_at => start_at,
                                   :hide_at => Time.zone.local(2011, 4, 14, 11, 59, 30))
      assert_equal "Deal Over", deal_min_remaining.time_remaining_text_display
    end
  end

  should "include DailyDeals::EmailBlast" do
    assert_contains DailyDeal.ancestors, DailyDeals::EmailBlast
  end

  private

  def syndicate(daily_deal, syndicated_publisher)
    daily_deal.syndicated_deals.build(:publisher_id => syndicated_publisher.id)
    daily_deal.save!
    daily_deal.syndicated_deals.last
  end

  # You can now use factories
  # Factory(.build)(:daily_deal)
  def setup_valid_attributes
    @valid_attributes = {
      :value_proposition => "$81 value for $39",
      :price => 39.00,
      :value => 81.00,
      :quantity => 100,
      :terms => "these are my terms",
      :description => "this is my description",
      :start_at => 10.days.ago,
      :hide_at => Time.zone.now.tomorrow,
      :short_description => "A wonderful deal"
    }
  end

  def purchase_daily_deal(daily_deal, quantity)
    daily_deal_purchase = daily_deal.daily_deal_purchases.build
    daily_deal_purchase.consumer = users(:john_public)
    daily_deal_purchase.quantity = quantity
    daily_deal_purchase.daily_deal_payment = PaypalPayment.new
    daily_deal_purchase.save!
    DailyDealMailer.expects(:deliver_purchase_confirmation_with_certificates).at_least(0).returns(nil)
    DailyDealPurchase.handle_buy_now(
      "invoice" => daily_deal_purchase.analog_purchase_id,
      "item_number" => daily_deal_purchase.paypal_item,
      "protection_eligibility" => "Eligible",
      "tax" => "0.00",
      "payment_status" => "Completed",
      "business" => "demo_merchant@analoganalytics.com",
      "payer_email" => "tbuscher@gmail.com",
      "receiver_id" => "96GH9L6W5QGLA",
      "residence_country"=>"US",
      "handling_amount" => "0.00",
      "payment_gross" => "%.2f" % (quantity * daily_deal.price),
      "receiver_email" => "demo_merchant@analoganalytics.com",
      "verify_sign" => "AmHf4UgW-l1HczXnT5wIeQmi8WIxA27fsg2vin5EA9DOGpG2mn9K-DQF",
      "action" => "create",
      "quantity" => quantity.to_s,
      "txn_type" => "web_accept",
      "mc_currency" => "USD",
      "transaction_subject" => "GC",
      "charset" => "windows-1252",
      "txn_id" => Array.new(10) { ('0'..'9').to_a.sample },
      "item_name" => daily_deal.description,
      "controller" => "paypal_notifications",
      "notify_version" => "2.8",
      "payer_status" => "verified",
      "payment_fee" => "1.00",
      "receipt_id" => "3625-4706-3930-0684",
      "payment_date" => "12:34:56 Jan 01, 2010 PST",
      "mc_fee" => "1.00",
      "shipping" => "0.00",
      "payment_type" => "instant",
      "mc_gross" => "%.2f" % (quantity * daily_deal.price),
      "payer_id" => "4DRVF75YKJG2A",
      "custom" => "DAILY_DEAL_PURCHASE"
    )
    daily_deal.reload
  end

  def update_with_no_validation_and_no_auto_timestamps(record, attributes)
    record.attributes = attributes.except(:created_at, :updated_at)
    record.save_with_validation(false)
    class << record
      def record_timestamps; false end
    end
    record.update_attribute :created_at, attributes[:created_at] if attributes.has_key?(:created_at)
    record.update_attribute :updated_at, attributes[:updated_at] if attributes.has_key?(:updated_at)
    class << record
      def record_timestamps; super end
    end
  end

  context "with active and inactive deals" do
    setup do
      @publisher = Factory(:publisher)
      @deal_1 = Factory(:daily_deal, :publisher => @publisher, :start_at => 1.days.ago, :hide_at => 1.days.from_now)
      @deal_2 = Factory(:daily_deal, :publisher => @publisher, :start_at => 2.days.ago, :hide_at => 1.days.ago)
    end

    context "the active named scope" do
      should "include only the active deal when all deals have the qr_code_active flag set" do
        @deal_1.update_attributes! :qr_code_active => true
        @deal_2.update_attributes! :qr_code_active => true
        assert_equal [@deal_1], @publisher.daily_deals.active
      end

      should "include only the active deal when no deals have the qr_code_active flag set" do
        @deal_1.update_attributes! :qr_code_active => false
        @deal_2.update_attributes! :qr_code_active => false
        assert_equal [@deal_1], @publisher.daily_deals.active
      end
    end

    context "the active_or_qr_code_active named scope" do
      should "include all deals when all deals have the qr_code_active flag set" do
        @deal_1.update_attributes! :qr_code_active => true
        @deal_2.update_attributes! :qr_code_active => true
        assert_equal [@deal_1, @deal_2], @publisher.daily_deals.active_or_qr_code_active
      end

      should "include only the active deal when only the active deal has the qr_code_active flag set" do
        @deal_1.update_attributes! :qr_code_active => true
        @deal_2.update_attributes! :qr_code_active => false
        assert_equal [@deal_1], @publisher.daily_deals.active_or_qr_code_active
      end

      should "include all deals when only the inactive deal has the qr_code_active flag set" do
        @deal_1.update_attributes! :qr_code_active => false
        @deal_2.update_attributes! :qr_code_active => true
        assert_equal [@deal_1, @deal_2], @publisher.daily_deals.active_or_qr_code_active
      end

      should "include only the active deal when no deals have the qr_code_active flag set" do
        @deal_1.update_attributes! :qr_code_active => false
        @deal_2.update_attributes! :qr_code_active => false
        assert_equal [@deal_1], @publisher.daily_deals.active_or_qr_code_active
      end

      should "include no deals when all deals are deleted and have the qr_code_active flag set" do
        @deal_1.update_attributes! :qr_code_active => true, :deleted_at => Time.zone.now
        @deal_2.update_attributes! :qr_code_active => true, :deleted_at => Time.zone.now
        assert_equal [], @publisher.daily_deals.active_or_qr_code_active
      end
    end
  end

  context "campaign code" do
    setup do
      @deal = Factory(:daily_deal)
    end

    should "exist" do
      assert @deal.respond_to?(:campaign_code)
    end

    should "accept letters and numbers" do
      @deal.campaign_code = "abcd"
      assert @deal.valid?

      @deal.campaign_code = "1234"
      assert @deal.valid?

      @deal.campaign_code = "abc123"
      assert @deal.valid?
    end

    should "reject non-alphanumeric codes" do
      @deal.campaign_code = "abc$123"
      assert @deal.invalid?

      @deal.campaign_code = "abc#^"
      assert @deal.invalid?
    end

    should "be unique" do
      @deal.campaign_code = "abc123"
      @deal.save!
      dup_deal = Factory(:daily_deal)
      dup_deal.campaign_code = "abc123"

      assert dup_deal.invalid?
    end
  end
end
