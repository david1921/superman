require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SyndicationStatusTest

module DailyDeals
  class SyndicationStatusTest < ActiveSupport::TestCase
    
    def setup
      @publisher = Factory(:publisher, :self_serve => true)
      
      @user = Factory(:user, :company => @publisher, :allow_syndication_access => true)
      @distributing_publisher = Factory(:publisher)
      @publisher_not_in_network = Factory(:publisher, :in_syndication_network => false, :self_serve => true)
      
      @publisher_excluded_by_publisher = Factory(:publisher)
      @publisher_excluded_by_publisher.publishers_excluded_from_distribution << @publisher
      @publisher_excluded_by_publisher.save!
      
      #These deals should never be included
      @deal_of_publisher_not_in_network = Factory(:daily_deal, 
                                                  :publisher => @publisher_not_in_network, 
                                                  :start_at => 5.days.from_now, 
                                                  :hide_at => 6.days.from_now)
      @deal_of_publisher_excluded_by_publisher = Factory(:daily_deal_for_syndication, 
                                                   :publisher => @publisher_excluded_by_publisher, 
                                                   :start_at => 5.days.from_now, 
                                                   :hide_at => 6.days.from_now)
      @deal_not_owned_by_publisher_and_not_available_for_syndication = Factory(:daily_deal,
                                                                         :start_at => 3.days.ago,
                                                                         :hide_at => 6.days.from_now)
      
      #These deals are returned by default and are filtered
      @deal_owned_by_publisher_and_not_available_for_syndication = Factory(:daily_deal,
                                                                     :publisher => @publisher,
                                                                     :start_at => 3.days.ago,
                                                                     :hide_at => 2.days.from_now)
      @deal_sourced_by_publisher = Factory(:daily_deal_for_syndication, 
                                     :publisher => @publisher, 
                                     :start_at => 3.days.from_now, 
                                     :hide_at => 4.days.from_now)
      @deal_sourced_by_publisher_and_distributed_by_network = Factory(:daily_deal_for_syndication, 
                                                                :publisher => @publisher, 
                                                                :start_at => 5.days.from_now, 
                                                                :hide_at => 6.days.from_now)
      @deal_sourced_by_network = Factory(:daily_deal_for_syndication, 
                                         :start_at => 3.days.from_now, 
                                         :hide_at => 4.days.from_now)
      @deal_sourced_by_network_and_distributed_by_network = Factory(:daily_deal_for_syndication, 
                                                                    :start_at => 7.days.from_now, 
                                                                    :hide_at => 8.days.from_now)
      
      @distributed_deal_sourced_by_publisher_and_distributed_by_network = @deal_sourced_by_publisher_and_distributed_by_network.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
      @deal_sourced_by_publisher_and_distributed_by_network.save!
      
      @distributed_deal_sourced_by_network_and_distributed_by_network = @deal_sourced_by_network_and_distributed_by_network.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
      @deal_sourced_by_network_and_distributed_by_network.save!
      
      @distributed_deal_sourced_by_network_and_distributed_by_publisher = @deal_sourced_by_network_and_distributed_by_network.syndicated_deals.build(:publisher_id => @publisher.id)
      @deal_sourced_by_network_and_distributed_by_network.save!
    end
    
    fast_context "sourceable_by_publisher" do
      should "return correct deals" do
        assert_equal false, @deal_of_publisher_not_in_network.sourceable_by_publisher?(@publisher)
        assert_equal false, @deal_of_publisher_excluded_by_publisher.sourceable_by_publisher?(@publisher)
        assert_equal false, @deal_not_owned_by_publisher_and_not_available_for_syndication.sourceable_by_publisher?(@publisher)
        assert_equal true, @deal_owned_by_publisher_and_not_available_for_syndication.sourceable_by_publisher?(@publisher)
        assert_equal false, @deal_sourced_by_publisher.sourceable_by_publisher?(@publisher)
        assert_equal false, @deal_sourced_by_publisher_and_distributed_by_network.sourceable_by_publisher?(@publisher)
        assert_equal false, @deal_sourced_by_network.sourceable_by_publisher?(@publisher)
        assert_equal false, @deal_sourced_by_network_and_distributed_by_network.sourceable_by_publisher?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_publisher_and_distributed_by_network.sourceable_by_publisher?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_network.sourceable_by_publisher?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_publisher.sourceable_by_publisher?(@publisher)
      end
    end
    
    fast_context "sourced_by_network" do
      should "return correct deals" do
        assert_equal false, @deal_of_publisher_not_in_network.sourced_by_network?(@publisher)
        assert_equal true, @deal_of_publisher_excluded_by_publisher.sourced_by_network?(@publisher)
        assert_equal false, @deal_not_owned_by_publisher_and_not_available_for_syndication.sourced_by_network?(@publisher)
        assert_equal false, @deal_owned_by_publisher_and_not_available_for_syndication.sourced_by_network?(@publisher)
        assert_equal false, @deal_sourced_by_publisher.sourced_by_network?(@publisher)
        assert_equal false, @deal_sourced_by_publisher_and_distributed_by_network.sourced_by_network?(@publisher)
        assert_equal true, @deal_sourced_by_network.sourced_by_network?(@publisher)
        assert_equal true, @deal_sourced_by_network_and_distributed_by_network.sourced_by_network?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_publisher_and_distributed_by_network.sourced_by_network?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_network.sourced_by_network?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_publisher.sourced_by_network?(@publisher)
      end
    end
    
    fast_context "distributed_by_publisher" do
      should "return correct deals" do
        assert_equal false, @deal_of_publisher_not_in_network.distributed_by_publisher?(@publisher)
        assert_equal false, @deal_of_publisher_excluded_by_publisher.distributed_by_publisher?(@publisher)
        assert_equal false, @deal_not_owned_by_publisher_and_not_available_for_syndication.distributed_by_publisher?(@publisher)
        assert_equal false, @deal_owned_by_publisher_and_not_available_for_syndication.distributed_by_publisher?(@publisher)
        assert_equal false, @deal_sourced_by_publisher.distributed_by_publisher?(@publisher)
        assert_equal false, @deal_sourced_by_publisher_and_distributed_by_network.distributed_by_publisher?(@publisher)
        assert_equal false, @deal_sourced_by_network.distributed_by_publisher?(@publisher)
        assert_equal true, @deal_sourced_by_network_and_distributed_by_network.distributed_by_publisher?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_publisher_and_distributed_by_network.distributed_by_publisher?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_network.distributed_by_publisher?(@publisher)
        assert_equal true, @distributed_deal_sourced_by_network_and_distributed_by_publisher.distributed_by_publisher?(@publisher)
      end
    end
    
    fast_context "distributed_by_network" do
      should "return correct deals" do
        assert_equal false, @deal_of_publisher_not_in_network.distributed_by_network?(@publisher)
        assert_equal false, @deal_of_publisher_excluded_by_publisher.distributed_by_network?(@publisher)
        assert_equal false, @deal_not_owned_by_publisher_and_not_available_for_syndication.distributed_by_network?(@publisher)
        assert_equal false, @deal_owned_by_publisher_and_not_available_for_syndication.distributed_by_network?(@publisher)
        assert_equal false, @deal_sourced_by_publisher.distributed_by_network?(@publisher)
        assert_equal true, @deal_sourced_by_publisher_and_distributed_by_network.distributed_by_network?(@publisher)
        assert_equal false, @deal_sourced_by_network.distributed_by_network?(@publisher)
        assert_equal true, @deal_sourced_by_network_and_distributed_by_network.distributed_by_network?(@publisher)
        assert_equal true, @distributed_deal_sourced_by_publisher_and_distributed_by_network.distributed_by_network?(@publisher)
        assert_equal true, @distributed_deal_sourced_by_network_and_distributed_by_network.distributed_by_network?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_publisher.distributed_by_network?(@publisher)
      end
    end
    
    fast_context "sourceable" do
      should "return correct deals" do
        assert_equal false, @deal_of_publisher_not_in_network.sourceable?(@publisher)
        assert_equal false, @deal_of_publisher_excluded_by_publisher.sourceable?(@publisher)
        assert_equal false, @deal_not_owned_by_publisher_and_not_available_for_syndication.sourceable?(@publisher)
        assert_equal true, @deal_owned_by_publisher_and_not_available_for_syndication.sourceable?(@publisher)
        assert_equal false, @deal_sourced_by_publisher.sourceable?(@publisher)
        assert_equal false, @deal_sourced_by_publisher_and_distributed_by_network.sourceable?(@publisher)
        assert_equal false, @deal_sourced_by_network.sourceable?(@publisher)
        assert_equal false, @deal_sourced_by_network_and_distributed_by_network.sourceable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_publisher_and_distributed_by_network.sourceable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_network.sourceable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_publisher.sourceable?(@publisher)
      end
    end
    
    fast_context "unsourceable" do
      should "return correct deals" do
        assert_equal false, @deal_of_publisher_not_in_network.unsourceable?(@publisher)
        assert_equal false, @deal_of_publisher_excluded_by_publisher.unsourceable?(@publisher)
        assert_equal false, @deal_not_owned_by_publisher_and_not_available_for_syndication.unsourceable?(@publisher)
        assert_equal false, @deal_owned_by_publisher_and_not_available_for_syndication.unsourceable?(@publisher)
        assert_equal true, @deal_sourced_by_publisher.unsourceable?(@publisher)
        assert_equal false, @deal_sourced_by_publisher_and_distributed_by_network.unsourceable?(@publisher)
        assert_equal false, @deal_sourced_by_network.unsourceable?(@publisher)
        assert_equal false, @deal_sourced_by_network_and_distributed_by_network.unsourceable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_publisher_and_distributed_by_network.unsourceable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_network.unsourceable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_publisher.unsourceable?(@publisher)
      end
    end
    
    fast_context "distributable" do
      should "return correct deals" do
        assert_equal false, @deal_of_publisher_not_in_network.distributable?(@publisher)
        assert_equal false, @deal_of_publisher_excluded_by_publisher.distributable?(@publisher)
        assert_equal false, @deal_not_owned_by_publisher_and_not_available_for_syndication.distributable?(@publisher)
        assert_equal false, @deal_owned_by_publisher_and_not_available_for_syndication.distributable?(@publisher)
        assert_equal false, @deal_sourced_by_publisher.distributable?(@publisher)
        assert_equal false, @deal_sourced_by_publisher_and_distributed_by_network.distributable?(@publisher)
        assert_equal true, @deal_sourced_by_network.distributable?(@publisher)
        assert_equal false, @deal_sourced_by_network_and_distributed_by_network.distributable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_publisher_and_distributed_by_network.distributable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_network.distributable?(@publisher)
        assert_equal false, @distributed_deal_sourced_by_network_and_distributed_by_publisher.distributable?(@publisher)
      end
    end
    
  end
end
