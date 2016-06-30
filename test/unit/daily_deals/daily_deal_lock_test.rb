require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::DailyDealLockTest

module DailyDeals
  class DailyDealLockTest < ActiveSupport::TestCase
    
    context "with a non paychex publisher" do
      
      setup do
        Publisher.any_instance.stubs(:uses_paychex?).returns(false)
      end
      
      context "start_at" do
        
        should "be able to update if start_at date is in the future" do
          deal = Factory(:daily_deal, :start_at => 2.days.from_now, :hide_at => 10.days.from_now)
          assert deal.update_attributes(:start_at => 1.day.from_now)
        end
        
        should "be able to update if start_at in the past but no deals sold" do
          deal = Factory(:daily_deal, :start_at => 2.days.ago, :hide_at => 10.days.from_now )
          deal.stubs(:number_sold).returns(0)
          assert deal.update_attributes(:start_at => 1.day.ago)
        end
        
        should "be able to update start_at in the past if at least one deal is sold" do
          # NOTE: this use to lock, but we turned off for all publishers for Entertainment per Christina
          deal = Factory(:daily_deal, :start_at => 2.days.ago, :hide_at => 10.days.from_now )
          deal.stubs(:number_sold).returns(1)
          assert deal.update_attributes(:start_at => 1.day.ago)
        end
        
      end
      
      context "price" do
        
        should "be able to update price if deal is not syndicated or has any purchases" do
          deal = Factory(:daily_deal, :price => 100.00)
          deal.stubs(:number_sold).returns(0)
          deal.stubs(:source?).returns(false)
          assert deal.update_attributes(:price => 99.00)
        end
        
        should "NOT be able to update price if deal is not syndicated but has at least on purchase" do
          deal = Factory(:daily_deal, :price => 100.00)
          deal.stubs(:number_sold).returns(1)
          deal.stubs(:source?).returns(false)
          assert !deal.update_attributes(:price => 99.00)
        end
        
        should "NOT be able to update price if deal is syndicated and has no purchases" do
          deal = Factory(:daily_deal, :price => 100.00)
          deal.stubs(:number_sold).returns(0)
          deal.stubs(:available_for_syndication?).returns(true)          
          deal.stubs(:source?).returns(true)
          assert !deal.update_attributes(:price => 99.00)
        end
        
        should "NOT be able to update price if deal is syndicated and has purchases" do
          deal = Factory(:daily_deal, :price => 100.00)
          deal.stubs(:number_sold).returns(1)
          deal.stubs(:available_for_syndication?).returns(true)          
          deal.stubs(:source?).returns(true)
          assert !deal.update_attributes(:price => 99.00)
        end        
        
      end
      
      context "hide_at" do
        
        should "be able to update hide_at if deal is not syndicated and has no purchases" do
          deal = Factory(:daily_deal, :start_at => 2.days.ago, :hide_at => 25.hours.ago)
          deal.stubs(:number_sold).returns(0)
          deal.stubs(:source?).returns(false)
          assert deal.update_attributes(:hide_at => 2.days.from_now)
        end
        
        should "be able to update hide_at if deal is syndicated and has purchases" do
          deal = Factory(:daily_deal, :start_at => 2.days.ago, :hide_at => 25.hours.ago)
          deal.stubs(:number_sold).returns(1)
          deal.stubs(:available_for_syndication?).returns(true)
          deal.stubs(:source?).returns(true)
          assert deal.update_attributes(:hide_at => 2.days.from_now)
        end
        
      end
      
      
    end
    
    context "with a paychex publisher" do
      
      setup do
        Publisher.any_instance.stubs(:uses_paychex?).returns(true)
      end
      
      context "start_at" do

        should "be able to update if start_at date is in the future" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :start_at => 2.days.from_now, :hide_at => 10.days.from_now)
          assert deal.update_attributes(:start_at => 1.day.from_now)
        end
        
        should "be able to update if start_at in the past but no deals sold" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :start_at => 2.days.ago, :hide_at => 10.days.from_now )
          deal.stubs(:number_sold).returns(0)
          assert deal.update_attributes(:start_at => 1.day.ago)
        end
        
        should "be able to update start_at in the past if at least one deal is sold" do
          # NOTE: we use to lock on the start at date, we turned off for all publisher for Entertainment per Christina
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :start_at => 2.days.ago, :hide_at => 10.days.from_now )
          deal.stubs(:number_sold).returns(1)
          assert deal.update_attributes(:start_at => 1.day.ago)
        end
        
      end
      
      context "price" do
        
        should "be able to update price if deal is not syndicated or has any purchases" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :price => 100.00)
          deal.stubs(:number_sold).returns(0)
          deal.stubs(:source?).returns(false)
          assert deal.update_attributes(:price => 99.00)
        end
        
        should "NOT be able to update price if deal is not syndicated but has at least on purchase" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :price => 100.00)
          deal.stubs(:number_sold).returns(1)
          deal.stubs(:source?).returns(false)
          assert !deal.update_attributes(:price => 99.00)
        end
        
        should "NOT be able to update price if deal is syndicated and has no purchases" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :price => 100.00)
          deal.stubs(:number_sold).returns(0)
          deal.stubs(:available_for_syndication?).returns(true)          
          deal.stubs(:source?).returns(true)
          assert !deal.update_attributes(:price => 99.00)
        end
        
        should "NOT be able to update price if deal is syndicated and has purchases" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :price => 100.00)
          deal.stubs(:number_sold).returns(1)
          deal.stubs(:available_for_syndication?).returns(true)          
          deal.stubs(:source?).returns(true)
          assert !deal.update_attributes(:price => 99.00)
        end        
        
      end
      
      context "hide_at" do
      
        should "be able to set hide_at to 25.hours.ago on create" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :start_at => 2.days.ago, :hide_at => 25.hours.ago )
          assert deal.valid?
        end
        
        should "be able to update hide_at if hide_at is less than 24 hours ago" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :start_at => 2.days.ago, :hide_at => 23.hours.ago )
          assert deal.update_attributes(:hide_at => 25.hours.ago)
        end
        
        should "be able to update hide_at if hide_at is over 24 hours ago and no purhcases" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :start_at => 2.days.ago, :hide_at => 25.hours.ago )
          assert deal.update_attributes(:hide_at => 23.hours.ago)
        end

        should "NOT be able to update hide_at if hide_at is over 24 hours ago and there are purchases" do
          deal = Factory(:daily_deal, :advertiser_revenue_share_percentage => 42, :start_at => 2.days.ago, :hide_at => 25.hours.ago)
          deal.stubs(:number_sold).returns(1)
          assert !deal.update_attributes(:hide_at => 23.hours.ago)
        end

      end      
      
    end
        
  end
end
