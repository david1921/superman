require File.dirname(__FILE__) + "/../test_helper"

class DailyDealWithFactoriesTest < ActiveSupport::TestCase
  test "#active_between scope should contain deal if start_at is inside the given date range" do
    range = [ Date.parse("Jun 10 2010"), Date.parse("Jun 30 2010") ]
    deal = Factory(:daily_deal, :start_at => Time.zone.parse("Jun 12 2010"))
    deals = deal.publisher.daily_deals.active_between( range )
    assert_contains deals, deal
  end
  
  test "#active_between scope should contain deal if hide_at is inside the given date range" do
    range = [ Date.parse("Jun 10 2010"), Date.parse("Jun 30 2010") ]
    deal = Factory(
      :daily_deal, 
      :start_at => Time.zone.parse("Jun 9 2010"), 
      :hide_at => Time.zone.parse("Jun 12 2010")
    )
    deals = deal.publisher.daily_deals.active_between( range )
    assert_contains deals, deal
  end
  
  test "#active_between scope should contain deal if start_at and hide_at bookend the given date range" do
    range = [ Date.parse("Jun 10 2010"), Date.parse("Jun 30 2010") ]
    deal = Factory(
      :daily_deal, 
      :start_at => Time.zone.parse("Jun 9 2010"), 
      :hide_at => Time.zone.parse("Jul 1 2010")
    )
    deals = deal.publisher.daily_deals.active_between( range )
    assert_contains deals, deal
  end
  
  test "#active_between scope should NOT contain deal if start_at and hide_at are outside the given date range" do
    range = [ Date.parse("Jun 10 2010"), Date.parse("Jun 30 2010") ]
    deal = Factory(
      :daily_deal, 
      :start_at => Time.zone.parse("Jun 8 2010"), 
      :hide_at => Time.zone.parse("Jun 9 2010")
    )
    deals = deal.publisher.daily_deals.active_between( range )
    assert_does_not_contain deals, deal
  end
  
  test "#active_between scope should NOT contain deal even when the hide_at is just moments before the start of range" do
    range = [ Time.zone.parse("Mar 01, 2009"), Time.zone.parse("Mar 09, 2009") ]
    deal = Factory(
      :daily_deal, 
      :start_at => Time.zone.parse("Feb 28, 2009 06:00:00"), 
      :hide_at => Time.zone.parse("Feb 28, 2009 23:59:00")
    )
    deals = deal.publisher.daily_deals.active_between( range )
    assert_does_not_contain deals, deal
  end
  
  test "#upcoming deals should contain deal if upcoming is true and they start after now" do 
      publisher = Factory(:publisher)
      advertiser = Factory(:advertiser, :name => "Advertiser 1", :publisher => publisher)
  
      daily_deals = [
          daily_deal_not_upcoming = Factory(
          :side_daily_deal,
          :upcoming => false,
          :advertiser => advertiser,
          :start_at => Time.zone.parse("Jun 9 2010"), 
          :hide_at => Time.zone.parse("Jun 12 2010")
        ),
        daily_deal_featured_today_and_upcoming = Factory(
          :daily_deal, 
          :upcoming => true,
          :advertiser => advertiser,
          :start_at => Time.zone.parse("Jun 9 2010"), 
          :hide_at => Time.zone.parse("Jun 12 2010")
        ),
        daily_deal_upcoming = Factory(
          :daily_deal, 
          :upcoming => true,
          :advertiser => advertiser,
          :start_at => Time.zone.parse("Jun 13 2010"), 
          :hide_at => Time.zone.parse("Jun 16 2010")
        ),
        daily_deal_upcoming_in_past = Factory(
          :daily_deal, 
          :upcoming => true,
          :advertiser => advertiser,
          :start_at => Time.zone.parse("May 13 2010"), 
          :hide_at => Time.zone.parse("May 16 2010")
        ),
        daily_deal_upcoming_deleted = Factory(
          :daily_deal, 
          :upcoming => true,
          :advertiser => advertiser,
          :deleted_at => Time.zone.parse("Jan 13 2010"), 
          :start_at => Time.zone.parse("May 13 2011"), 
          :hide_at => Time.zone.parse("May 16 2011")
        )]
      daily_deals = [daily_deal_not_upcoming, daily_deal_upcoming]
  
      Timecop.freeze Time.zone.local(2010, 6, 11) do
        expected_daily_deals = [daily_deal_upcoming]
        actual_daily_deals = publisher.daily_deals.upcoming
        assert_equal expected_daily_deals, actual_daily_deals
      end
    end
    
  test "#start_at of 5/4 11:55 PM should not cause validation error when expires_on is 5/5" do
    Timecop.freeze Time.zone.local(2011, 4, 2) do
      deal = Factory.build(
        :daily_deal, 
        :start_at => Time.zone.parse("May 4, 2011 23:55:00"), 
        :hide_at => Time.zone.parse("May 4, 2011 23:56:00"),
        :expires_on => Date.parse("2011-05-05")
      )
      assert_equal true, deal.valid?, "deal should be valid"
    end
  end
  
  test "#hide_at of 5/4 11:55 PM should not cause validation error when expires_on is 5/5" do
    Timecop.freeze Time.zone.local(2011, 4, 2) do
      deal = Factory.build(
        :daily_deal, 
        :start_at => Time.zone.parse("May 1, 2011 06:00:00"), 
        :hide_at => Time.zone.parse("May 4, 2011 23:55:00"),
        :expires_on => Date.parse("2011-05-05")
      )
      assert_equal true, deal.valid?, "deal should be valid"
    end
  end
  
  test "with_text should return deals with text in value proposition, advertiser name or category" do
    publisher = Factory(:publisher)
    category = Factory(:daily_deal_category, :name => "Food")
    advertiser = Factory(:advertiser, :name => "great food restaurant")
    deal_1 = Factory(:daily_deal_for_syndication, :value_proposition => "$50 of great food for $25")
    deal_2 = Factory(:daily_deal_for_syndication, :value_proposition => "$50 of something for $25", :advertiser => advertiser)
    deal_3 = Factory(:daily_deal_for_syndication, :value_proposition => "$50 for $25", :analytics_category => category)
    deal_4 = Factory(:daily_deal_for_syndication, :value_proposition => "$50 for $25")
    deal_5 = Factory(:daily_deal_for_syndication, :value_proposition => "50% off")
    deals = DailyDeal.with_text("food")
    assert deals.include?(deal_1), "Should include deal with value proposition: " << deal_1.value_proposition
    assert deals.include?(deal_2), "Should include deal with advertiser name: " << advertiser.name
    assert deals.include?(deal_3), "Should include deal with category name: " << category.name
    assert !deals.include?(deal_4), "Should not include deal with value proposition: " << deal_4.value_proposition
    assert !deals.include?(deal_5), "Should not include deal with value proposition: " << deal_5.value_proposition
    assert_equal 3, deals.size
  end
  
  test "in_zips with on zip should return deals with advertiser stores in zip code" do
    Store.delete_all
    advertiser_1 = Factory(:advertiser_without_stores, :name => "advertiser_1")
    store_1 = Factory(:store, :advertiser => advertiser_1, :zip => "78704")
    store_2 = Factory(:store, :advertiser => advertiser_1, :zip => "78777")
    advertiser_2 = Factory(:advertiser_without_stores, :name => "advertiser_2")
    store_3 = Factory(:store, :advertiser => advertiser_2, :zip => "78704-1234")
    advertiser_3 = Factory(:advertiser_without_stores, :name => "advertiser_3")
    store_4 = Factory(:store, :advertiser => advertiser_3, :zip => "98671")
    
    deal_1 = Factory(:daily_deal, :advertiser => advertiser_1, :start_at => 1.days.from_now, :hide_at => 2.days.from_now)
    deal_2 = Factory(:daily_deal, :advertiser => advertiser_1, :start_at => 3.days.from_now, :hide_at => 4.days.from_now)
    deal_3 = Factory(:daily_deal, :advertiser => advertiser_2)
    deal_4 = Factory(:daily_deal, :advertiser => advertiser_3)
    
    deals = DailyDeal.in_zips(["78704"])
    assert deals.include?(deal_1), "Should include deal with advertiser store in zip"
    assert deals.include?(deal_2), "Should include deal with advertiser store in zip"
    assert deals.include?(deal_3), "Should include deal with advertiser store in zip"
    assert !deals.include?(deal_4), "Should not include deal with advertiser store not in zip"
    assert_equal 3, deals.size
  end
  
  test "in_zips with multiple zips should return deals with advertiser stores in zip code" do
     Store.delete_all
     advertiser_1 = Factory(:advertiser_without_stores, :name => "advertiser_1")
     store_1 = Factory(:store, :advertiser => advertiser_1, :zip => "78704")
     store_2 = Factory(:store, :advertiser => advertiser_1, :zip => "78777")
     advertiser_2 = Factory(:advertiser_without_stores, :name => "advertiser_2")
     store_3 = Factory(:store, :advertiser => advertiser_2, :zip => "78704-1234")
     advertiser_3 = Factory(:advertiser_without_stores, :name => "advertiser_3")
     store_4 = Factory(:store, :advertiser => advertiser_3, :zip => "98671")
     advertiser_4 = Factory(:advertiser_without_stores, :name => "advertiser_4")
     store_5 = Factory(:store, :advertiser => advertiser_4, :zip => "79053")
     
     deal_1 = Factory(:daily_deal, :advertiser => advertiser_1, :start_at => 1.days.from_now, :hide_at => 2.days.from_now)
     deal_2 = Factory(:daily_deal, :advertiser => advertiser_1, :start_at => 3.days.from_now, :hide_at => 4.days.from_now)
     deal_3 = Factory(:daily_deal, :advertiser => advertiser_2)
     deal_4 = Factory(:daily_deal, :advertiser => advertiser_3)
     deal_5 = Factory(:daily_deal, :advertiser => advertiser_4)
     
     deals = DailyDeal.in_zips(["78704", "79053"])
     assert deals.include?(deal_1), "Should include deal with advertiser store in zip"
     assert deals.include?(deal_2), "Should include deal with advertiser store in zip"
     assert deals.include?(deal_3), "Should include deal with advertiser store not in zip"
     assert !deals.include?(deal_4), "Should not include deal with advertiser store in zip"
     assert deals.include?(deal_5), "Should include deal with advertiser store in zip"
     assert_equal 4, deals.size
   end
  
private

  # These will go away with shoulda or get moved to test_helper
  def assert_contains(array, item)
    assert_equal true, array.include?( item )
  end
  
  def assert_does_not_contain(array, item)
    assert_equal false, array.include?( item )
  end
    
end