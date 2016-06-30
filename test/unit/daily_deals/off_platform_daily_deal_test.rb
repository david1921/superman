require File.dirname(__FILE__) + "/../../test_helper"

class OffPlatformDailyDealTest < ActiveSupport::TestCase
  
  context "associations" do
    should have_one :off_platform_purchase_summary
  end
  
  context "create" do
    
    setup do
      @publisher = Factory(:publisher)
      @advertiser = Factory(:advertiser, :publisher_id => @publisher.id)
      @attributes = Factory(:side_daily_deal).attributes.merge(:advertiser_id => @advertiser.id)
    end
    
    context "with attribute off_platform set to true" do
      
      setup do
        @deal = DailyDeal.create!( @attributes.merge(:off_platform => true) )
        @deal = DailyDeal.find(@deal.id)
      end
      
      should "be an off_platform? daily deal" do
        assert @deal.off_platform?
      end

      should "have a listing that starts with OP-" do
        assert @deal.listing.starts_with?('OP-')
      end        
      
    end
    
    context "with attribute off_platform set to false" do
      
      setup do
        @deal = DailyDeal.create!( @attributes.merge(:off_platform => false) )
        @deal = DailyDeal.find(@deal.id)
      end
      
      should "not be an off_platform? daily deal" do
        assert !@deal.off_platform?
      end
      
      should "have a listing that starts with BBD-" do
        assert @deal.listing.starts_with?('BBD-')
      end
      
    end
    
  end
  
  context "update" do
    
    context "with an off platform deal" do
      
      setup do
        @deal = Factory(:off_platform_daily_deal)
      end

      should "be an off platform" do
        assert @deal.off_platform?
      end              
      
      should "have a listing that starts with OP-" do
        assert @deal.listing.starts_with?("OP-")
      end
      
      context "updating" do
        
        context "with off_platform set to false" do
          
          setup do
            @deal.update_attributes(:off_platform => false)
            @deal = DailyDeal.find(@deal.id)
          end
          
          should "not be an off platform" do
            assert !@deal.off_platform?
          end

          should "have a listing that starts with BBD-" do
            assert @deal.listing.starts_with?("BBD-")
          end
          
        end
        
        context "with off_platform set to true" do
          
          setup do
            @deal.update_attributes(:off_platform => true)
            @deal = DailyDeal.find(@deal.id)
          end
          
          should "be an off platform" do
            assert @deal.off_platform?
          end              

          should "have a listing that starts with OP-" do
            assert @deal.listing.starts_with?("OP-")
          end
                      
        end
        
      end
      
    end
    
    context "with a regular deal" do
      
      setup do
        @deal = Factory(:daily_deal)
      end
      
      should "not be an off platform" do
        assert !@deal.off_platform?
      end
      
      should "have a listing that starts with BBD-" do
        assert @deal.listing.starts_with?("BBD-")
      end
      
      context "with off_platform set to false" do
        
        setup do
          @deal.update_attributes(:off_platform => false)
          @deal = DailyDeal.find(@deal.id)
        end
        
        should "not be an off platform" do
          assert !@deal.off_platform?
        end

        should "have a listing that starts with BBD-" do
          assert @deal.listing.starts_with?("BBD-")
        end
        
      end
      
      context "with off_platform set to true" do
        
        setup do
          @deal.update_attributes(:off_platform => true)
          @deal = DailyDeal.find(@deal.id)
        end
        
        should "be an off platform" do
          assert @deal.off_platform?
        end              

        should "have a listing that starts with OP-" do
          assert @deal.listing.starts_with?("OP-")
        end
                    
      end
      
      
    end
    
    
  end
  
end  
