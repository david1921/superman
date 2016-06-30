require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SyndicationValidationTest

module DailyDeals
  class SyndicationValidationTest < ActiveSupport::TestCase
    
    context "syndication no variations" do
      setup do
        @distributing_publisher = Factory(:publisher)
        @source_publisher = Factory(:publisher, :in_syndication_network => true)
        @source_advertiser = Factory(:advertiser, :publisher => @source_publisher)
        @source_deal = Factory(:daily_deal_for_syndication, :advertiser => @source_advertiser)
        @distributed_deal = syndicate(@source_deal, @distributing_publisher)
      end
      
      should "NOT accept same publisher as the source deal" do
        assert_no_difference "DailyDeal.count" do
          assert_no_difference "@source_deal.reload.syndicated_deals.count" do
            @source_deal.syndicated_deals.build(:publisher_id => @source_deal.publisher.id)
            assert !@source_deal.valid?
            assert @source_deal.errors.full_messages[0] =~ /Invalid distributed deal: Distributing publisher cannot be the same as the source publisher./
          end
        end
      end
      
      should "NOT accept syndicated deal to be syndicated" do
        assert_no_difference "DailyDeal.count" do
          assert_no_difference "@source_deal.reload.syndicated_deals.count" do
            @distributed_deal.syndicated_deals.build(:publisher_id => Factory(:publisher).id)
            assert !@distributed_deal.valid?
            assert @distributed_deal.errors.full_messages[0] =~ /Invalid distributed deal: Distributed deal cannot be distributed./
          end
        end
      end
      
      should "NOT allow a syndicated deal to be made available for syndication" do
        @distributed_deal.available_for_syndication = true
        assert @distributed_deal.invalid?
        assert @distributed_deal.errors.full_messages.include?("A distributed deal cannot be made available for syndication.")
      end
      
      should "NOT allow syndicated deal to be syndicated via source_id" do
        assert_no_difference "DailyDeal.count" do
          new_deal = Factory.build(:daily_deal, :source_id => @distributed_deal.id)
          assert !new_deal.valid?
          assert new_deal.errors.full_messages.include? "Distributed deal cannot be distributed."
        end
      end
      
      should "NOT allow deal to be syndicated via source_id under same publisher" do
        assert_no_difference "DailyDeal.count" do
          new_deal = Factory.build(:daily_deal, :publisher => @source_deal.publisher, :source_id => @source_deal.id)
          assert !new_deal.valid?
          assert new_deal.errors.full_messages.include? "Distributing publisher cannot be the same as the source publisher."
        end
      end
      
      context "restrict_syndication_to_publishing_group" do
        setup do
          publishing_group = Factory(:publishing_group, :restrict_syndication_to_publishing_group => true)
          @distributing_publisher = Factory(:publisher, :publishing_group => publishing_group)
          @source_publisher.update_attributes(:publishing_group => publishing_group)
        end
        
        should "NOT allow deal to be syndicated outside of publishing group" do
          outside_publisher = Factory(:publisher)
          
          assert_no_difference "DailyDeal.count" do
            new_deal = Factory.build(:daily_deal, :publisher => outside_publisher, :source_id => @source_deal.id)
            assert !new_deal.valid?
            assert new_deal.errors.full_messages.include? "Deal cannot be distributed by the requested publisher."
          end
        end
        
        should "NOT allow outside deal to be syndicated by publishing group publisher" do
          outside_deal = Factory(:daily_deal_for_syndication)
          
          assert_no_difference "DailyDeal.count" do
            new_deal = Factory.build(:daily_deal, :publisher => @distributing_publisher, :source_id => outside_deal.id)
            assert !new_deal.valid?
            assert new_deal.errors.full_messages.include? "Deal cannot be distributed by the requested publisher."
          end
        end
      end
      
      should "raise error when syndicated deal start at exceeds expired on" do
        exception = assert_raise(ActiveRecord::RecordInvalid) {
          @distributed_deal.start_at = 25.days.from_now
          @distributed_deal.hide_at = 25.days.from_now + 1.second
          @distributed_deal.expires_on = 24.days.from_now
          @distributed_deal.save!
        }
        assert_match /Expires on must be after start at, Expires on must be after hide at/, exception.message
      end
      
    end
    
    context "featured deals" do
      
      setup do
        DailyDeal.delete_all
        @distributing_publisher = Factory(:publisher)
        @other_source_deal = Factory(:daily_deal,
                                     :available_for_syndication => true,
                                     :start_at => 2.days.from_now,
                                     :hide_at => 4.days.from_now,
                                     :expires_on => 30.days.from_now)
      end
      
      should "NOT overlap with other featured syndicated deal when syndicated" do
        other_syndicated = syndicate(@other_source_deal, @distributing_publisher)
        source_deal = Factory(:daily_deal,
                              :available_for_syndication => true,
                              :start_at => 3.days.ago,
                              :hide_at => 3.days.from_now,
                              :expires_on => 30.days.from_now)
        source_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
        distributed_deal = source_deal.syndicated_deals.first
        assert_equal true, distributed_deal.valid?, "Should be valid because deal was made a side deal"
        assert_equal false, distributed_deal.featured?
      end
      
      should "flip syndicated deal to side deal when overlap with non-syndicated featured deal when syndicated" do
        source_deal = Factory(:daily_deal,
                              :available_for_syndication => true,
                              :start_at => 3.days.ago,
                              :hide_at => 3.days.from_now,
                              :expires_on => 30.days.from_now)
        other_deal = Factory(:daily_deal,
                              :publisher => @distributing_publisher,
                              :start_at => 2.days.from_now,
                              :hide_at => 4.days.from_now,
                              :expires_on => 30.days.from_now)
        source_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
        distributed_deal = source_deal.syndicated_deals.first
        assert_equal true, distributed_deal.valid?, "Should be valid because it should have been flipped to a side_deal"
        assert_equal false, distributed_deal.featured?
      end
      
      should "NOT overlap with non-syndicated featured deal when updating daily deal start and hide at" do
        source_deal = Factory(:daily_deal,
                              :available_for_syndication => true,
                              :start_at => 3.days.ago,
                              :hide_at => 3.days.from_now,
                              :expires_on => 30.days.from_now)
        distributed_deal = source_deal.syndicated_deals.build(:publisher => @distributing_publisher)
        assert_equal true, source_deal.valid?
        overlapping_deal = Factory.build(:daily_deal,
                                    :publisher => @distributing_publisher,
                                    :start_at => 40.days.from_now,
                                    :hide_at => 45.days.from_now)
        assert_equal true, overlapping_deal.valid?
        distributed_deal.start_at = 42.days.from_now
        distributed_deal.hide_at = 44.days.from_now
        assert_equal false, distributed_deal.valid?
        assert_equal false, source_deal.valid?, "syndicated deals are invalid, so source deal should be too"
        distributed_deal.start_at = 3.days.ago
        distributed_deal.hide_at = 5.days.from_now
        assert_equal true, distributed_deal.valid?
        assert_equal true, source_deal.valid?, "syndicated deals are now valid, so source deal should be okay again"
        assert_equal true, overlapping_deal.valid?
      end
      
      should "allow source deal to go from side deal to featured with overlapping distributed and non-distributed deals" do
        source_deal = Factory(:side_daily_deal_for_syndication,
                              :start_at => 3.days.ago,
                              :hide_at => 3.days.from_now,
                              :expires_on => 30.days.from_now)
        distributed_deal = source_deal.syndicated_deals.build(:publisher => @distributing_publisher)
        assert source_deal.valid?
        source_deal.save!
        
        distributed_deal.featured = true
        assert distributed_deal.valid?
        distributed_deal.save!
        
        source_deal.featured = true
        assert source_deal.valid?
        source_deal.save!
        
        another_source_deal = Factory(:daily_deal_for_syndication,
                                      :start_at => 2.days.ago,
                                      :hide_at => 4.days.from_now,
                                      :expires_on => 30.days.from_now)
        another_distributed_deal = source_deal.syndicated_deals.build(:publisher => Factory(:publisher))
        assert source_deal.valid?
        source_deal.save!
      end
      
      should "overlap with other syndicated featured deal when updating source deal" do
        source_deal = Factory(:daily_deal_for_syndication,
                              :start_at => 3.days.from_now,
                              :hide_at => 4.days.from_now,
                              :expires_on => 30.days.from_now)
        distributed_deal = syndicate(source_deal, @distributing_publisher)
        distributed_deal.start_at = 1.days.from_now
        distributed_deal.hide_at = 2.days.from_now
        distributed_deal.save!
        #runs 2-4 days from now
        @other_source_deal = Factory(:daily_deal_for_syndication,
                                     :start_at => 3.days.from_now,
                                     :hide_at => 4.days.from_now,
                                     :expires_on => 30.days.from_now)
        other_distributed_deal = syndicate(@other_source_deal, @distributing_publisher)
        source_deal.reviews = "test"
        assert_equal true, source_deal.valid?, "Should be valid"
        assert_equal true, source_deal.reload.featured_during_lifespan?
        assert_equal true, @other_source_deal.reload.featured_during_lifespan?
        assert_equal true, distributed_deal.reload.featured_during_lifespan?
        assert_equal true, other_distributed_deal.reload.featured_during_lifespan?
      end
      
      should "overlap with non-syndicated featured deal when updating source deal" do
        source_deal = Factory(:daily_deal_for_syndication,
                              :start_at => 3.days.from_now,
                              :hide_at => 4.days.from_now,
                              :expires_on => 30.days.from_now)
        distributed_deal = syndicate(source_deal, @distributing_publisher)
        distributed_deal.start_at = 1.days.from_now
        distributed_deal.hide_at = 2.days.from_now
        distributed_deal.save!
        other_deal = Factory(:daily_deal,
                              :publisher => @distributing_publisher,
                              :start_at => 3.days.from_now,
                              :hide_at => 4.days.from_now,
                              :expires_on => 30.days.from_now)
        source_deal.reviews = "test"
        assert_equal true, source_deal.valid?, "Should be valid"
        assert_equal true, source_deal.reload.featured_during_lifespan?
        assert_equal true, other_deal.reload.featured_during_lifespan?
        assert_equal true, distributed_deal.reload.featured_during_lifespan?
      end
      
    end

    context "short description" do
      setup do
        @publisher = Factory(:publisher, :require_daily_deal_short_description => false)
        @daily_deal = Factory(:daily_deal, :available_for_syndication => true, :short_description => "")
        @distributing_publisher = Factory(:publisher, :require_daily_deal_short_description => true)
        @distributed_deal = @daily_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
      end
      
      should "not be required for syndicated deal" do
        assert @distributed_deal.valid?, "Should build a valid syndicated deal"
      end
    end

    context "syndicating a featured deal that conflicts with an existing deal" do
      setup do
        @source_publisher = Factory(:publisher, :name => "source pub inc")
        @distributing_publisher = Factory(:publisher, :name => "distributing pub llc")
        @source_deal = Factory(:daily_deal,
                               :available_for_syndication => true,
                               :publisher => @source_publisher,
                               :start_at => 3.days.ago,
                               :hide_at => 3.days.from_now)
        @conflicting_deal_for_distributing_publishing = Factory(:daily_deal,
                                                                :publisher => @distributing_publisher,
                                                                :start_at => @source_deal.start_at,
                                                                :hide_at => @source_deal.hide_at)
        @distributed_deal = @source_deal.syndicated_deals.build(:publisher => @distributing_publisher)
      end

      should "be setup properly" do
        assert_equal @source_deal, @distributed_deal.source
      end

      should "be valid but not featured after syndication" do
        assert_equal true, @distributed_deal.valid?, @distributed_deal.errors.full_messages.join(",")
        assert_equal false, @distributed_deal.featured?
      end

    end

    context "available_for_syndication" do
      should "allow change to true if publisher is in network" do
        @publisher = Factory(:publisher, :in_syndication_network => true)
        @deal = Factory(:daily_deal, :publisher => @publisher, :available_for_syndication => false)
        @deal.available_for_syndication = true
        assert @deal.valid?, @deal.errors.full_messages.join(",")
      end
      should "not allow change to true if publisher is not in network" do
        @publisher = Factory(:publisher, :in_syndication_network => false)
        @deal = Factory(:daily_deal, :publisher => @publisher, :available_for_syndication => false)
        @deal.available_for_syndication = true
        assert @deal.invalid?, "deal should be invalid because publisher is not in network"
      end
    end

    context "setting source requires in_network" do
      should "if the source deal's publisher is in_network, the deal should be settable as a source" do
        @providing_publisher = Factory(:publisher, :in_syndication_network => true)
        @provided_deal = Factory(:daily_deal, :publisher => @providing_publisher, :available_for_syndication => true)
        @receiving_publisher = Factory(:publisher)
        @received_deal = Factory.build(:daily_deal, :available_for_syndication => false)
        @received_deal.source = @provided_deal
        assert @providing_publisher.in_syndication_network?
        assert @provided_deal.available_for_syndication?
        assert @received_deal.valid?, @received_deal.errors.full_messages.join(",")
      end
      should "fail validation if source is set and publisher is not in network" do
        @providing_publisher = Factory(:publisher, :in_syndication_network => true)
        @provided_deal = Factory(:daily_deal, :publisher => @providing_publisher, :available_for_syndication => true)
        @providing_publisher.update_attribute(:in_syndication_network, false)
        @receiving_publisher = Factory(:publisher)
        @received_deal = Factory.build(:daily_deal)
        @received_deal.source = @provided_deal
        assert @received_deal.invalid?
      end
    end

    context "syndication with variations" do

      setup do
        @distributing_publisher = Factory(:publisher)
        @source_publisher = Factory(:publisher, :in_syndication_network => true)
        @source_advertiser = Factory(:advertiser, :publisher => @source_publisher)
        @source_deal = Factory(:daily_deal_for_syndication, :advertiser => @source_advertiser)
      end

      context "enable_daily_deal_variations" do

        should "not allow distribution of a deal with variations unless the distributing publisher sets enable_daily_deal_variations" do
          @source_publisher.update_attributes!(:enable_daily_deal_variations => true)
          @distributing_publisher.update_attributes!(:enable_daily_deal_variations => false)

          daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => @source_deal)

          distributed_deal = @source_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id)

          assert !distributed_deal.valid?
          assert distributed_deal.errors.full_messages.include? "Deal cannot be distributed unless variations are enabled on the distributing publisher."
        end

        should "allow distribution of a deal with variations if the distributing publisher sets enable_daily_deal_variations" do
          @source_publisher.update_attributes!(:enable_daily_deal_variations => true)
          @distributing_publisher.update_attributes!(:enable_daily_deal_variations => true)

          daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => @source_deal)
          distributed_deal = syndicate(@source_deal, @distributing_publisher)

          assert distributed_deal.valid?
        end
      end

    end
    
  end

end
