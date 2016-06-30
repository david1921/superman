require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Drop::DailyDealTest
module Drop
  class DailyDealTest < ActiveSupport::TestCase
    test "Should delegate specific methods" do
      daily_deal = Factory(
                     :daily_deal, 
                     :photo => ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/burger_king.png", 'image/png')
                   )
      drop = Drop::DailyDeal.new(daily_deal)
      assert_equal daily_deal.value_proposition, drop.value_proposition, "value_proposition should be the same"
      assert_match %r{http://s3.amazonaws.com/photos.daily-deals.analoganalytics.com/test/\d+/standard.png\?\d+}, 
                   drop.photo.standard_url, 
                   "Should delegate photo URL"

      assert_equal daily_deal.address, drop.address, "address should be the same"
      assert_equal daily_deal.twitter_status, drop.twitter_status, "twitter_status should be the same"
      assert_equal daily_deal.number_sold_display_threshold, drop.number_sold_display_threshold, "number sold display threshold should be the same"
      # Won't need these tests for all Drops, but confirm basic behavior here
      assert_raise NoMethodError do
        drop.destroy
      end
      
      assert_raise NoMethodError do
        drop.daily_deal
      end
    end

    context "market-aware methods" do
      setup do
        @daily_deal = Factory(:daily_deal)
        @drop = Drop::DailyDeal.new(@daily_deal)
      end

      should "return non-market-aware path with no market label in the params" do
        @drop.stubs(:params).returns({})
        assert_equal "http://#{@daily_deal.publisher.daily_deal_host}/publishers/#{@daily_deal.publisher.label}/daily_deals/#{@daily_deal.id}", @drop.url
      end

      should "return market-aware path with a market label in the params" do
        @drop.stubs(:params).returns({ :market_label => 'chicago' })
        assert_equal "http://#{@daily_deal.publisher.daily_deal_host}/publishers/#{@daily_deal.publisher.label}/chicago/daily_deals/#{@daily_deal.id}", @drop.url
      end
    end
    
    context "Drop::DailyDeal#side_deals_in_shopping_mall" do
      
      setup do
        @publisher = Factory :publisher
        @advertiser = Factory :advertiser, :publisher => @publisher
        @deal_1 = Factory :featured_daily_deal, :advertiser => @advertiser, :value_proposition => "first deal"
        @deal_2 = Factory :side_daily_deal, :advertiser => @advertiser, :value_proposition => "second deal", :shopping_mall => false
        @deal_3 = Factory :side_daily_deal, :advertiser => @advertiser, :value_proposition => "third deal", :shopping_mall => true
        
        @deal_drop = Drop::DailyDeal.new(@deal_1)
      end
      
      should "return only side deals whose shopping_mall flag is true" do
        assert_equal ["third deal"], @deal_drop.side_deals_in_shopping_mall.map(&:value_proposition)
      end
      
      should "return the side deals as liquid drops" do
        assert_equal 1, @deal_drop.side_deals_in_shopping_mall.size
        assert @deal_drop.side_deals_in_shopping_mall.first.is_a?(Drop::DailyDeal)
      end
    
      context "Drop::DailyDeal#random_side_deals_in_shopping_mall" do

        should "return the side deals" do
          assert_equal 1, @deal_drop.random_side_deals_in_shopping_mall.size
        end
        
      end
      
    end
    
    context "custom side deal methods for entercom" do
      
      setup do
        @publisher = Factory :publisher, :enable_publisher_daily_deal_categories => true
        @cat_deal_1 = Factory :daily_deal_category, :publisher => @publisher, :name => "Deal 1"
        @cat_deal_2 = Factory :daily_deal_category, :publisher => @publisher, :name => "Deal 2"
        @cat_deal_3 = Factory :daily_deal_category, :publisher => @publisher, :name => "Deal 3"
        @cat_deal_4 = Factory :daily_deal_category, :publisher => @publisher, :name => "Deal 4"
        @cat_other = Factory :daily_deal_category, :publisher => @publisher, :name => "Other Category"
        
        @featured_deal = Factory :daily_deal, :publisher => @publisher, :publishers_category => @cat_deal_1
        @deal_1 = Factory :side_daily_deal, :publisher => @publisher, :publishers_category => @cat_deal_1
        @deal_2 = Factory :side_daily_deal, :publisher => @publisher, :publishers_category => @cat_deal_2
        @deal_3 = Factory :side_daily_deal, :publisher => @publisher, :publishers_category => @cat_deal_3
        @deal_4 = Factory :side_daily_deal, :publisher => @publisher, :publishers_category => @cat_deal_4
        @deal_other = Factory :side_daily_deal, :publisher => @publisher, :publishers_category => @cat_other
        
        @featured_deal_drop = Drop::DailyDeal.new(@featured_deal)
      end
      
      context "Drop::DailyDeal#side_deals_in_deal_1_category" do
        
        should "return only side deals in category Deal 1" do
          assert_equal [@deal_1.id], @featured_deal_drop.side_deals_in_deal_1_category.map(&:id)
        end
        
      end

      context "Drop::DailyDeal#side_deals_in_deal_2_category" do
        
        should "return only side deals in category Deal 2" do
          assert_equal [@deal_2.id], @featured_deal_drop.side_deals_in_deal_2_category.map(&:id)
        end
        
      end

      context "Drop::DailyDeal#side_deals_in_deal_3_category" do
        
        should "return only side deals in category Deal 3" do
          assert_equal [@deal_3.id], @featured_deal_drop.side_deals_in_deal_3_category.map(&:id)
        end
        
      end

      context "Drop::DailyDeal#side_deals_in_deal_4_category" do
        
        should "return only side deals in category Deal 4" do
          assert_equal [@deal_4.id], @featured_deal_drop.side_deals_in_deal_4_category.map(&:id)
        end
        
      end
      
    end

    context "#side_deals_in_category" do
      context "when publishing group has categories" do
        setup do
          @publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
          @category = Factory(:daily_deal_category, :publishing_group => @publisher.publishing_group)
        end

        should "find deals in the category" do
          featured_deal = Factory(:daily_deal, :publisher => @publisher, :publishers_category => @category)
          deal = Factory(:side_daily_deal, :publisher => @publisher, :publishers_category => @category)
          drop = Drop::DailyDeal.new(featured_deal)
          assert_equal [deal.id], drop.side_deals_in_category(@category.name).map(&:id)
        end
      end
    end
    
    context "#side_deals_in_custom_entercom_order" do
      
      setup do
        @deal_drop = Drop::DailyDeal.new Factory(:daily_deal)
      end
      
      should "call DailyDeal#side_deals_in_custom_entercom_order passing in the deal" do
        deal = @deal_drop.send :daily_deal
        deal.expects(:side_deals_in_custom_entercom_order).once
        @deal_drop.side_deals_in_custom_entercom_order
      end
      
    end

  end
end
