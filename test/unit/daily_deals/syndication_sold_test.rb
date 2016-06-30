require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SyndicationSoldTest

module DailyDeals
  class SyndicationSoldTest < ActiveSupport::TestCase
    
    context "number sold" do
      
      should "NOT include syndicated deals in source deal calculation" do
        daily_deal                = Factory(:daily_deal_for_syndication)
        distributing_publisher = Factory(:publisher)
        syndicated_deal           = daily_deal.syndicated_deals.build(:publisher_id => distributing_publisher.id)
        syndicated_deal.save!
      
        daily_deal_advertiser       = daily_deal.advertiser
        syndicated_deal_advertiser  = syndicated_deal.advertiser
      
        daily_deal_consumer         = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => daily_deal.publisher )
        syndicated_deal_consumer_1    = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => syndicated_deal.publisher )
        syndicated_deal_consumer_2    = Factory(:consumer, :first_name => "Jane", :last_name => "Smith", :publisher => syndicated_deal.publisher )
      
        daily_deal_purchase         = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => daily_deal_consumer)
        syndicated_deal_purchase_1  = Factory(:authorized_daily_deal_purchase, :daily_deal => syndicated_deal, :consumer => syndicated_deal_consumer_1)
        syndicated_deal_purchase_2  = Factory(:captured_daily_deal_purchase, :daily_deal => syndicated_deal, :consumer => syndicated_deal_consumer_1)
        
        assert_equal 1, daily_deal.number_sold
        assert_equal 2, syndicated_deal.number_sold
        
        pending_syndicated_deal_purchase  = Factory(:pending_daily_deal_purchase, :daily_deal => syndicated_deal, :consumer => syndicated_deal_consumer_1)
        
        assert_equal 1, daily_deal.number_sold
        assert_equal 2, syndicated_deal.number_sold
        
      end
      
      should "NOT include source deals in syndicated deal calculation" do
        daily_deal                = Factory(:daily_deal_for_syndication)
        distributing_publisher = Factory(:publisher)
        syndicated_deal           = daily_deal.syndicated_deals.build(:publisher_id => distributing_publisher.id)
        syndicated_deal.save!
      
        daily_deal_advertiser       = daily_deal.advertiser
        syndicated_deal_advertiser  = syndicated_deal.advertiser
      
        daily_deal_consumer_1       = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => daily_deal.publisher )
        daily_deal_consumer_2       = Factory(:consumer, :first_name => "Jane", :last_name => "Smith", :publisher => daily_deal.publisher )
        syndicated_deal_consumer    = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => syndicated_deal.publisher )
      
        daily_deal_purchase_1       = Factory(:authorized_daily_deal_purchase, :daily_deal => daily_deal, :consumer => daily_deal_consumer_1)
        daily_deal_purchase_2       = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => daily_deal_consumer_2)
        syndicated_deal_purchase    = Factory(:authorized_daily_deal_purchase, :daily_deal => syndicated_deal, :consumer => syndicated_deal_consumer)
      
        assert_equal 2, daily_deal.number_sold
        assert_equal 1, syndicated_deal.number_sold
        
        pending_daily_deal_purchase       = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => daily_deal_consumer_2)
        assert_equal 2, daily_deal.number_sold
        assert_equal 1, syndicated_deal.number_sold
        
      end
      
    end
    
    context "number sold including syndicated" do
      
      setup do 
        @daily_deal = Factory(:daily_deal_for_syndication, :quantity => 7)
        
        @distributing_publisher = Factory(:publisher)
        @syndicated_deal = @daily_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
        @syndicated_deal.save!
      end
      
      context "for syndicated deal" do
        
        setup do
          @consumer_0 = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => @daily_deal.publisher )
          @consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => @syndicated_deal.publisher )
          @consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => @daily_deal.publisher )
        end
        
        should "include source deals" do
          daily_deal_purchase_1 = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer_0)
          assert_equal 1, @syndicated_deal.number_sold_including_syndicated
          
          daily_deal_purchase_2 = Factory(:authorized_daily_deal_purchase, :daily_deal => @syndicated_deal, :consumer => @consumer_1)
          assert_equal 2, @syndicated_deal.number_sold_including_syndicated
          
          daily_deal_purchase_3  = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer_2)
          assert_equal 3, @syndicated_deal.number_sold_including_syndicated
          
          pending_daily_deal_purchase  = Factory(:pending_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer_2)
          assert_equal 3, @syndicated_deal.number_sold_including_syndicated
        end
      end
      
      context "for source deal" do
        
        setup do
          @consumer_0 = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => @syndicated_deal.publisher )
          @consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => @daily_deal.publisher )
          @consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => @distributing_publisher )
        end
        
        should "include syndicated deals" do
          daily_deal_purchase_1 = Factory(:authorized_daily_deal_purchase, :daily_deal => @syndicated_deal, :consumer => @consumer_0)
          assert_equal 1, @daily_deal.number_sold_including_syndicated
          
          daily_deal_purchase_2 = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @consumer_1, :quantity => 3)
          assert_equal 4, @daily_deal.number_sold_including_syndicated
          
          daily_deal_purchase_3  = Factory(:authorized_daily_deal_purchase, :daily_deal => @syndicated_deal, :consumer => @consumer_2)
          assert_equal 5, @daily_deal.number_sold_including_syndicated
          
          pending_daily_deal_purchase  = Factory(:pending_daily_deal_purchase, :daily_deal => @syndicated_deal, :consumer => @consumer_2, :quantity => 2)
          assert_equal 5, @daily_deal.number_sold_including_syndicated
          
          daily_deal_purchase_4  = Factory(:authorized_daily_deal_purchase, :daily_deal => @syndicated_deal, :consumer => @consumer_2, :quantity => 2)
          assert_equal 7, @daily_deal.number_sold_including_syndicated
        end
      end
      
      context "for source and each syndicated deal" do
        setup do
          @distributing_publisher_2 = Factory(:publisher)
          @syndicated_deal_2 = @daily_deal.syndicated_deals.build(:publisher_id => @distributing_publisher_2.id)
          @syndicated_deal_2.save!
          
          @daily_deal_consumer = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => @daily_deal.publisher )
          @syndicated_deal_consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => @syndicated_deal.publisher )
          @syndicated_deal_consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => @syndicated_deal_2.publisher )
        end
        
        should "include source and all syndicated deals" do
          syndicated_deal_purchase_1 = Factory(:authorized_daily_deal_purchase, :daily_deal => @syndicated_deal, :consumer => @syndicated_deal_consumer_1, :quantity => 2)
          
          assert_equal 2, @daily_deal.number_sold_including_syndicated
          assert_equal 2, @syndicated_deal.number_sold_including_syndicated
          assert_equal 2, @syndicated_deal_2.number_sold_including_syndicated
          
          daily_deal_purchase = Factory(:authorized_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => @daily_deal_consumer, :quantity => 4)
          
          assert_equal 6, @daily_deal.number_sold_including_syndicated
          assert_equal 6, @syndicated_deal.number_sold_including_syndicated
          assert_equal 6, @syndicated_deal_2.number_sold_including_syndicated
          
          syndicated_deal_purchase_2  = Factory(:authorized_daily_deal_purchase, :daily_deal => @syndicated_deal_2, :consumer => @syndicated_deal_consumer_2)
          
          assert_equal 7, @daily_deal.number_sold_including_syndicated
          assert_equal 7, @syndicated_deal.number_sold_including_syndicated
          assert_equal 7, @syndicated_deal_2.number_sold_including_syndicated
        end
      end
    end
    
    context "sold_out?" do
      
      should "include source deals in syndicated deal calculation" do
        daily_deal = Factory(:daily_deal_for_syndication, :quantity => 3)
      
        distributing_publisher = Factory(:publisher)
        syndicated_deal = daily_deal.syndicated_deals.build(:publisher_id => distributing_publisher.id)
        syndicated_deal.save!
        
        consumer_0 = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => daily_deal.publisher )
        consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => syndicated_deal.publisher )
        consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => daily_deal.publisher )
        
        daily_deal_purchase_1 = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer_0)
        assert_equal false, syndicated_deal.sold_out?
        
        daily_deal_purchase_2 = Factory(:authorized_daily_deal_purchase, :daily_deal => syndicated_deal, :consumer => consumer_1)
        assert_equal false, syndicated_deal.sold_out?
        
        pending_daily_deal_purchase  = Factory(:pending_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer_2)
        assert_equal false, syndicated_deal.sold_out?
        
        daily_deal_purchase_3  = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer_2)
        assert_equal true, syndicated_deal.sold_out?
        
      end
      
      should "include syndicated deals in source deal calculation" do
        daily_deal = Factory(:daily_deal_for_syndication, :quantity => 3)
    
        distributing_publisher = Factory(:publisher)
        syndicated_deal = daily_deal.syndicated_deals.build(:publisher_id => distributing_publisher.id)
        syndicated_deal.save!
    
        consumer_0 = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => distributing_publisher )
        consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => daily_deal.publisher )
        consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => distributing_publisher )
    
        daily_deal_purchase_1 = Factory(:authorized_daily_deal_purchase, :daily_deal => syndicated_deal, :consumer => consumer_0)
        assert_equal false, daily_deal.sold_out?
    
        daily_deal_purchase_2 = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer_1)
        assert_equal false, daily_deal.sold_out?
        
        pending_daily_deal_purchase  = Factory(:pending_daily_deal_purchase, :daily_deal => syndicated_deal, :consumer => consumer_2)
        assert_equal false, daily_deal.sold_out?
        
        daily_deal_purchase_3  = Factory(:authorized_daily_deal_purchase, :daily_deal => syndicated_deal, :consumer => consumer_2)
        assert_equal true, daily_deal.sold_out?
        
      end
      
      should "include all syndicated deals and the source deal" do
        daily_deal = Factory(:daily_deal_for_syndication, :quantity => 5)
      
        distributing_publisher_1 = Factory(:publisher)
        syndicated_deal_1 = daily_deal.syndicated_deals.build(:publisher_id => distributing_publisher_1.id)
        syndicated_deal_1.save!
        
        distributing_publisher_2 = Factory(:publisher)
        syndicated_deal_2 = daily_deal.syndicated_deals.build(:publisher_id => distributing_publisher_2.id)
        syndicated_deal_2.save!
        
        daily_deal_consumer = Factory(:consumer, :first_name => "John", :last_name => "Smith", :publisher => daily_deal.publisher )
        syndicated_deal_consumer_1 = Factory(:consumer, :first_name => "Jill", :last_name => "Smith", :publisher => syndicated_deal_1.publisher )
        syndicated_deal_consumer_2 = Factory(:consumer, :first_name => "Jane", :last_name => "Doe", :publisher => syndicated_deal_2.publisher )
        
        syndicated_deal_purchase_1 = Factory(:authorized_daily_deal_purchase, :daily_deal => syndicated_deal_1, :consumer => syndicated_deal_consumer_1)
        
        assert_equal false, daily_deal.sold_out?, "Should NOT be sold out"
        assert_equal false, syndicated_deal_1.sold_out?, "Should NOT be sold out"
        assert_equal false, syndicated_deal_2.sold_out?, "Should NOT be sold out"
        
        assert_equal 1, daily_deal.number_sold_including_syndicated
        assert_equal 1, syndicated_deal_1.number_sold_including_syndicated
        assert_equal 1, syndicated_deal_2.number_sold_including_syndicated
        
        assert_equal 0, daily_deal.number_sold
        assert_equal 1, syndicated_deal_1.number_sold
        assert_equal 0, syndicated_deal_2.number_sold
        
        daily_deal_purchase = Factory(:authorized_daily_deal_purchase, :daily_deal => daily_deal, :consumer => daily_deal_consumer, :quantity => 3)
        
        assert_equal 4, daily_deal.number_sold_including_syndicated
        assert_equal 4, syndicated_deal_1.number_sold_including_syndicated
        assert_equal 4, syndicated_deal_2.number_sold_including_syndicated
        
        assert_equal 3, daily_deal.number_sold
        assert_equal 1, syndicated_deal_1.number_sold
        assert_equal 0, syndicated_deal_2.number_sold
        
        assert_equal false, daily_deal.sold_out?, "Should NOT be sold out"
        assert_equal false, syndicated_deal_1.sold_out?, "Should NOT be sold out"
        assert_equal false, syndicated_deal_2.sold_out?, "Should NOT be sold out"
        
        syndicated_deal_purchase_2  = Factory(:authorized_daily_deal_purchase, :daily_deal => syndicated_deal_2, :consumer => syndicated_deal_consumer_2)
        
        assert_equal 5, daily_deal.number_sold_including_syndicated
        assert_equal 5, syndicated_deal_1.number_sold_including_syndicated
        assert_equal 5, syndicated_deal_2.number_sold_including_syndicated
        
        assert_equal 3, daily_deal.number_sold
        assert_equal 1, syndicated_deal_1.number_sold
        assert_equal 1, syndicated_deal_2.number_sold
        
        assert_equal true, daily_deal.sold_out?, "Should NOT be sold out"
        assert_equal true, syndicated_deal_1.sold_out?, "Should NOT be sold out"
        assert_equal true, syndicated_deal_2.sold_out?, "Should NOT be sold out"
        
      end
    end
    
  end
end
