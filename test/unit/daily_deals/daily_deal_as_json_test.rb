require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealAsJsonTest < ActiveSupport::TestCase
  
  context "overridden as_json" do
    
    setup do
      @deal = Factory(:daily_deal)
    end
    
    should "call overridden as_json method when :only and :except options no present" do
      json = @deal.as_json(:link => 'link')
      assert json[:daily_deal]
      assert_equal @deal.advertiser_name, json[:daily_deal][:advertiser_name]
      assert_equal @deal.advertiser_logo_url, json[:daily_deal][:advertiser_logo_url]
      assert_equal @deal.ending_time_in_milliseconds, json[:daily_deal][:ending_time_in_milliseconds]
      assert_equal @deal.utc_ending_time_in_milliseconds, json[:daily_deal][:utc_end_time_in_milliseconds]
      assert_equal @deal.utc_starting_time_in_milliseconds, json[:daily_deal][:utc_start_time_in_milliseconds]
      assert_equal @deal.id, json[:daily_deal][:id]
      assert_equal nil, json[:daily_deal][:image]
      assert_equal 'link', json[:daily_deal][:link]
      assert_equal @deal.is_sold_out, json[:daily_deal][:is_sold_out]
      assert_equal @deal.number_sold, json[:daily_deal][:number_sold]
      assert_equal @deal.publisher.host, json[:daily_deal][:publisher_host]
      assert_equal @deal.value_proposition, json[:daily_deal][:title]
    end
    
  end
  
  context "json for calendar" do
    
    setup do
      @deal = Factory(:daily_deal)
    end
    
    should "call original as_json method when :only option present" do
      json = @deal.as_json_with_options({:only => [:value_proposition], :methods => [:start_at_date_only] })
      assert json[:daily_deal]
      assert_equal @deal.value_proposition, json[:daily_deal][:value_proposition]
      assert_equal @deal.start_at_date_only, json[:daily_deal][:start_at_date_only]
      assert_nil json[:daily_deal][:id]
    end
    
    should "call original as_json method when :except option present" do
      json = @deal.as_json_with_options({:except => [:value_proposition], :methods => [:start_at_date_only] })
      assert json[:daily_deal]
      assert_nil json[:daily_deal][:value_proposition]
      assert_equal @deal.start_at_date_only, json[:daily_deal][:start_at_date_only]
      assert_equal @deal.id, json[:daily_deal][:id]
    end
  end
  
end