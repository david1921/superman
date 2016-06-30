require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SyndicationTest

module DailyDeals
  class SyndicationTest < ActiveSupport::TestCase
    
    context "syndication" do
    
      setup do
        @distributing_publisher = Factory(:publisher, :time_zone => "Eastern Time (US & Canada)")
        @source_publisher = Factory(:publisher, :time_zone => "Pacific Time (US & Canada)")
        @source_advertiser = Factory(:advertiser, :publisher => @source_publisher)
        @source_deal = Factory(:daily_deal_for_syndication,
                              :advertiser => @source_advertiser,
                              :advertiser_revenue_share_percentage => 5,
                              :affiliate_revenue_share_percentage => 10)
    
        @market = Factory.create(:market, :publisher => @source_publisher)
        @source_deal.markets << @market
      end
      
      context "with default values" do
        
        setup do
          @syndicated_deal = @source_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id)
          @source_deal.save!
        end
        
        should "not have errors" do
          assert @syndicated_deal.errors.empty?, @syndicated_deal.errors.full_messages.join(", ")
        end
    
        should "set publisher to syndicated publisher" do
          assert_equal @distributing_publisher, @syndicated_deal.publisher, "Should set publisher to distributing publisher"
        end
    
        should "be able to retrieve source publisher through accessor" do
          assert_equal @source_publisher, @syndicated_deal.source_publisher
        end
    
        should "build valid syndicated deals" do
          assert_equal @distributing_publisher, @syndicated_deal.publisher, "Should set publisher to publisher using syndicated deal"
          assert_equal @source_deal.id, @syndicated_deal.source_id, "Syndicated deal should have of source id of source deal"
          assert_equal @source_deal, @syndicated_deal.source, "Should set source deal"
          assert_equal @source_deal.advertiser, @syndicated_deal.advertiser, "Should set advertiser from source"
          assert_equal @source_deal.value_proposition, @syndicated_deal.value_proposition, "Should set value_proposition"
          assert_equal @source_deal.description, @syndicated_deal.description, "Should set description"
          assert_equal @source_deal.text, @syndicated_deal.text, "Should set text"
          assert_equal @source_deal.price, @syndicated_deal.price, "Should set price"
          assert_equal @source_deal.value, @syndicated_deal.value, "Should set value"
          assert_equal @source_deal.terms, @syndicated_deal.terms, "Should set terms"
          assert_equal @source_deal.highlights, @syndicated_deal.highlights, "Should set highlights"
          assert_equal @source_deal.photo_file_name, @syndicated_deal.photo_file_name, "Should set photo_file_name"
          assert_equal @source_deal.photo_content_type, @syndicated_deal.photo_content_type, "Should set photo_content_type"
          assert_equal @source_deal.photo_file_size, @syndicated_deal.photo_file_size, "Should set photo_file_size"
          assert_equal @source_deal.deleted_at, @syndicated_deal.deleted_at, "Should set deleted_at"
          assert_equal_dates @source_deal.start_at.utc, @syndicated_deal.start_at.utc, "Should set start_at"
          assert_equal_dates @source_deal.hide_at.utc, @syndicated_deal.hide_at.utc, "Should set hide_at"
          assert_equal @source_deal.expires_on, @syndicated_deal.expires_on, "Should set expires_on"
          assert_equal @source_deal.quantity, @syndicated_deal.quantity, "Should set quantity"
          assert @source_deal.bit_ly_url != @syndicated_deal.bit_ly_url, "Should reset bit_ly_url and create one different than source deal"
          assert_equal @source_deal.facebook_title_text, @syndicated_deal.facebook_title_text, "Should set facebook_title_text"
          assert_equal @source_deal.twitter_status_text, @syndicated_deal.twitter_status_text, "Should set twitter_status_text"
          assert_equal @source_deal.short_description, @syndicated_deal.short_description, "Should set short_description"
          assert_equal @source_deal.min_quantity, @syndicated_deal.min_quantity, "Should set min_quantity"
          assert_equal @source_deal.location_required, @syndicated_deal.location_required, "Should set location_required"
          assert_equal @source_deal.sold_out_at, @syndicated_deal.sold_out_at, "Should set sold_out_at"
          assert_equal @source_deal.listing, @syndicated_deal.listing, "Should set listing"
          assert_equal @source_deal.advertiser_revenue_share_percentage, @syndicated_deal.advertiser_revenue_share_percentage, "Should set advertiser_revenue_share_percentage" #del?
          assert_equal nil, @syndicated_deal.affiliate_revenue_share_percentage, "Should set affiliate"
          assert_equal @source_deal.max_quantity, @syndicated_deal.max_quantity, "Should set max quantity"
          assert_equal @source_deal.reviews, @syndicated_deal.reviews, "Should set reviews"
          assert_equal @source_deal.uuid, @syndicated_deal.uuid, "Should set uuid"
          assert_equal @source_deal.featured, @syndicated_deal.featured, "Should set featured"
          assert_equal @source_deal.bar_code_encoding_format, @syndicated_deal.bar_code_encoding_format, "Should set bar_code_encoding_format"
          assert_equal @source_deal.value_proposition_subhead, @syndicated_deal.value_proposition_subhead, "Should set value_proposition_subhead"
          assert_equal @source_deal.upcoming, @syndicated_deal.upcoming, "Should set upcoming"
          assert_equal @source_deal.analytics_category, @syndicated_deal.analytics_category, "Should set analytics_category"
    
        end
    
        should "set source to source deal id" do
          assert_equal @source_deal, @syndicated_deal.source, "Should set source deal"
        end
    
        should "merge source deal attributes" do
          assert_equal @source_deal.advertiser, @syndicated_deal.advertiser, "Should set advertiser from source"
          assert_equal @source_deal.value_proposition, @syndicated_deal.value_proposition, "Should set value_proposition"
          assert_equal @source_deal.description, @syndicated_deal.description, "Should set description"
          assert_equal @source_deal.text, @syndicated_deal.text, "Should set text"
          assert_equal @source_deal.price, @syndicated_deal.price, "Should set price"
          assert_equal @source_deal.value, @syndicated_deal.value, "Should set value"
          assert_equal @source_deal.terms, @syndicated_deal.terms, "Should set terms"
          assert_equal @source_deal.highlights, @syndicated_deal.highlights, "Should set highlights"
          assert_equal @source_deal.photo_file_name, @syndicated_deal.photo_file_name, "Should set photo_file_name"
          assert_equal @source_deal.photo_content_type, @syndicated_deal.photo_content_type, "Should set photo_content_type"
          assert_equal @source_deal.photo_file_size, @syndicated_deal.photo_file_size, "Should set photo_file_size"
          assert_equal @source_deal.deleted_at, @syndicated_deal.deleted_at, "Should set deleted_at"
          assert_equal_dates @source_deal.start_at.utc, @syndicated_deal.start_at.utc, "Should set start_at"
          assert_equal_dates @source_deal.hide_at.utc, @syndicated_deal.hide_at.utc, "Should set hide_at"
          assert_equal @source_deal.expires_on, @syndicated_deal.expires_on, "Should set expires_on"
          assert_equal @source_deal.quantity, @syndicated_deal.quantity, "Should set quantity"
          assert_equal @source_deal.facebook_title_text, @syndicated_deal.facebook_title_text, "Should set facebook_title_text"
          assert_equal @source_deal.twitter_status_text, @syndicated_deal.twitter_status_text, "Should set twitter_status_text"
          assert_equal @source_deal.short_description, @syndicated_deal.short_description, "Should set short_description"
          assert_equal @source_deal.min_quantity, @syndicated_deal.min_quantity, "Should set min_quantity"
          assert_equal @source_deal.location_required, @syndicated_deal.location_required, "Should set location_required"
          assert_equal @source_deal.sold_out_at, @syndicated_deal.sold_out_at, "Should set sold_out_at"
          assert_equal @source_deal.listing, @syndicated_deal.listing, "Should set listing"
          assert_equal @source_deal.advertiser_revenue_share_percentage, @syndicated_deal.advertiser_revenue_share_percentage, "Should set advertiser_revenue_share_percentage" #del?
          assert_equal @source_deal.max_quantity, @syndicated_deal.max_quantity, "Should set max quantity"
          assert_equal @source_deal.reviews, @syndicated_deal.reviews, "Should set reviews"
          assert_equal @source_deal.uuid, @syndicated_deal.uuid, "Should set uuid"
          assert_equal @source_deal.featured, @syndicated_deal.featured, "Should set featured"
          assert_equal @source_deal.bar_code_encoding_format, @syndicated_deal.bar_code_encoding_format, "Should set bar_code_encoding_format"
          assert_equal @source_deal.value_proposition_subhead, @syndicated_deal.value_proposition_subhead, "Should set value_proposition_subhead"
          assert_equal @source_deal.upcoming, @syndicated_deal.upcoming, "Should set upcoming"
          assert_equal @source_deal.analytics_category, @syndicated_deal.analytics_category, "Should set category"
          assert_equal @source_deal.national_deal, @syndicated_deal.national_deal, "Should be set to false"
        end
    
        should "reset bit_ly_url" do
           assert @source_deal.bit_ly_url != @syndicated_deal.bit_ly_url, "Should reset bit_ly_url and create one different than source deal"
        end
    
        should "set affiliate_revenue_share_percentage to nil" do
           assert_equal nil, @syndicated_deal.affiliate_revenue_share_percentage, "Should set affiliate"
        end
    
        should "set available_for_syndication to false" do
           assert_equal false, @syndicated_deal.available_for_syndication, "Should be set to false"
        end
    
        should "set the markets on the syndicated deal from the source" do
          assert_equal [], @syndicated_deal.markets # Markets are not yet copied over during syndication
        end        
        
      end
    
      context "with overwritable values" do
        
        setup do
          now = Time.zone.now
          @source_deal.update_attributes(:start_at => 1.day.from_now, :hide_at => 20.days.from_now, :side_start_at => nil, :side_end_at => nil)
          @syndicated_deal = @source_deal.syndicated_deals.build(:publisher_id => @distributing_publisher.id, :start_at => now + 2.days, :hide_at => now + 5.days, :side_start_at => now + 2.days, :side_end_at => now + 5.days)
          @source_deal.save!
        end
        
        should "not have errors" do
          assert @syndicated_deal.errors.empty?, @syndicated_deal.errors.full_messages.join(", ")
        end
    
        should "set publisher to syndicated publisher" do
          assert_equal @distributing_publisher, @syndicated_deal.publisher, "Should set publisher to distributing publisher"
        end
    
        should "be able to retrieve source publisher through accessor" do
          assert_equal @source_publisher, @syndicated_deal.source_publisher
        end   
        
        should "build valid syndicated deals with different start_at, hide_at, and featured" do
          assert_equal @distributing_publisher, @syndicated_deal.publisher, "Should set publisher to publisher using syndicated deal"
          assert_equal @source_deal.id, @syndicated_deal.source_id, "Syndicated deal should have of source id of source deal"
          assert_equal @source_deal, @syndicated_deal.source, "Should set source deal"
          assert_equal @source_deal.advertiser, @syndicated_deal.advertiser, "Should set advertiser from source"
          assert_equal @source_deal.value_proposition, @syndicated_deal.value_proposition, "Should set value_proposition"
          assert_equal @source_deal.description, @syndicated_deal.description, "Should set description"
          assert_equal @source_deal.text, @syndicated_deal.text, "Should set text"
          assert_equal @source_deal.price, @syndicated_deal.price, "Should set price"
          assert_equal @source_deal.value, @syndicated_deal.value, "Should set value"
          assert_equal @source_deal.terms, @syndicated_deal.terms, "Should set terms"
          assert_equal @source_deal.highlights, @syndicated_deal.highlights, "Should set highlights"
          assert_equal @source_deal.photo_file_name, @syndicated_deal.photo_file_name, "Should set photo_file_name"
          assert_equal @source_deal.photo_content_type, @syndicated_deal.photo_content_type, "Should set photo_content_type"
          assert_equal @source_deal.photo_file_size, @syndicated_deal.photo_file_size, "Should set photo_file_size"
          assert_equal @source_deal.deleted_at, @syndicated_deal.deleted_at, "Should NOT set deleted_at from source, but should override"
          assert_not_equal @source_deal.start_at, @syndicated_deal.start_at, "Should NOT set start_at from source, but should override"
          assert_not_equal @source_deal.hide_at, @syndicated_deal.hide_at, "Should set hide_at"
          assert_equal @source_deal.expires_on, @syndicated_deal.expires_on, "Should set expires_on"
          assert_equal @source_deal.quantity, @syndicated_deal.quantity, "Should set quantity"
          assert @source_deal.bit_ly_url != @syndicated_deal.bit_ly_url, "Should reset bit_ly_url and create one different than source deal"
          assert_equal @source_deal.facebook_title_text, @syndicated_deal.facebook_title_text, "Should set facebook_title_text"
          assert_equal @source_deal.twitter_status_text, @syndicated_deal.twitter_status_text, "Should set twitter_status_text"
          assert_equal @source_deal.short_description, @syndicated_deal.short_description, "Should set short_description"
          assert_equal @source_deal.min_quantity, @syndicated_deal.min_quantity, "Should set min_quantity"
          assert_equal @source_deal.location_required, @syndicated_deal.location_required, "Should set location_required"
          assert_equal @source_deal.sold_out_at, @syndicated_deal.sold_out_at, "Should set sold_out_at"
          assert_equal @source_deal.listing, @syndicated_deal.listing, "Should set listing"
          assert_equal @source_deal.advertiser_revenue_share_percentage, @syndicated_deal.advertiser_revenue_share_percentage, "Should set advertiser_revenue_share_percentage" #del?
          assert_equal nil, @syndicated_deal.affiliate_revenue_share_percentage, "Should set affiliate"
          assert_equal @source_deal.max_quantity, @syndicated_deal.max_quantity, "Should set max quantity"
          assert_equal @source_deal.reviews, @syndicated_deal.reviews, "Should set reviews"
          assert_equal @source_deal.uuid, @syndicated_deal.uuid, "Should set uuid"
          assert_equal @source_deal.featured, @syndicated_deal.featured, "Should NOT set featured from source deal, should use setting"
          assert_equal @source_deal.bar_code_encoding_format, @syndicated_deal.bar_code_encoding_format, "Should set bar_code_encoding_format"
          assert_equal @source_deal.value_proposition_subhead, @syndicated_deal.value_proposition_subhead, "Should set value_proposition_subhead"
          assert_equal @source_deal.upcoming, @syndicated_deal.upcoming, "Should set upcoming"
          assert_equal @source_deal.analytics_category, @syndicated_deal.analytics_category, "Should set analytics_category"
    
        end     
        
      end
    
    end
    
    context "destroy" do
      setup do
        @source_deal = Factory(:daily_deal_for_syndication)
      end
      should "allow destroy if no syndicated deals" do
        id = @source_deal.id
        assert @source_deal.syndicated_deals.empty?
        @source_deal.destroy
        assert !DailyDeal.exists?(id)
      end
      should "NOT allow destroy if syndicated deals exist" do
        syndicated_deal = syndicate(@source_deal, Factory(:publisher))
        id = @source_deal.id
        assert !@source_deal.syndicated_deals.empty?
        @source_deal.destroy
        assert DailyDeal.exists?(id), "Deal should exist"
      end
    end
    
    context "save source deal" do
      
      setup do
        @distributing_publisher = Factory(:publisher)
      end
      
      context "price" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :price => 1000)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal 1000, @syndicated_deal.price, "Should be created with source deal price"
          @source_deal.price = 500
        end
        
        should "raise an InvalidRecord exception" do
          assert_equal "Validation failed: Price can not be changed, because deal has been syndicated.", assert_raise(ActiveRecord::RecordInvalid) { @source_deal.save! }.message
        end

      end
    
      context "value" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :value => 20)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal 20, @syndicated_deal.value, "Should be created with source deal value"
          @source_deal.value = 30
          @source_deal.save!
          @source_deal.reload
        end
        should "update syndicated deal value" do
          assert_equal 30, @source_deal.value, "Value should be updated"
          assert_equal 30, @syndicated_deal.value, "Syndicated should be updated with source value"
        end
      end
    
      context "quantities" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :quantity => 15, :min_quantity => 10, :max_quantity => 19)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal 15, @syndicated_deal.quantity, "Should be created with source deal quantity"
          assert_equal 10, @syndicated_deal.min_quantity, "Should be created with source deal min_quantity"
          assert_equal 19, @syndicated_deal.max_quantity, "Should be created with source deal max_quantity"
          @source_deal.quantity = 13
          @source_deal.min_quantity = 11
          @source_deal.max_quantity = 18
          @source_deal.save!
          @source_deal.reload
        end
        should "update syndicated deal quantities" do
          assert_equal 13, @source_deal.quantity, "Quantity should be updated"
          assert_equal 11, @source_deal.min_quantity, "Min_quantity should be updated"
          assert_equal 18, @source_deal.max_quantity, "Max_quantity should be updated"
          assert_equal 13, @syndicated_deal.quantity, "Should be udpated with source deal quantity"
          assert_equal 11, @syndicated_deal.min_quantity, "Should be udpated with source deal min_quantity"
          assert_equal 18, @syndicated_deal.max_quantity, "Should be udpated with source deal max_quantity"
        end
      end
    
      context "expires on" do
        setup do
          original_expires_on = Date.today + 30.days
          @new_expires_on = Date.today + 30.days
          @source_deal = Factory(:daily_deal_for_syndication,
                               :start_at => 1.days.from_now,
                               :hide_at => 3.days.from_now,
                               :expires_on => original_expires_on)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal_dates original_expires_on, @syndicated_deal.expires_on, "Should be created with source expires on"
          @source_deal.expires_on = @new_expires_on
          @source_deal.save!
          @source_deal.reload
        end
        should "update syndicated deal expires on when saved" do
          assert_equal_dates @new_expires_on, @source_deal.expires_on, "Expires on should be updated"
          assert_equal_dates @new_expires_on, @syndicated_deal.expires_on, "Should be udpated with source deal expires on"
        end
      end
    
      context "dates" do
        setup do
          @original_start_at = 1.days.from_now
          @original_hide_at = 3.days.from_now
          @new_start_at = 5.days.from_now
          @new_hide_at = 7.days.from_now
          @source_deal = Factory(:daily_deal_for_syndication,
                              :start_at => @original_start_at,
                              :hide_at => @original_hide_at,
                              :expires_on => 30.days.from_now)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal_dates @original_start_at, @syndicated_deal.start_at, "Should be created with source start at"
          assert_equal_dates @original_hide_at, @syndicated_deal.hide_at, "Should be created with source hide at"
          @source_deal.start_at = @new_start_at
          @source_deal.hide_at = @new_hide_at
          @source_deal.save!
          @source_deal.reload
        end
        should "NOT update syndicated deal dates" do
          assert_equal_dates @new_start_at, @source_deal.start_at, "Start at should be updated"
          assert_equal_dates @new_hide_at, @source_deal.hide_at, "Hide at should be updated"
          assert_equal_dates @original_start_at, @syndicated_deal.start_at, "Should be udpated with source deal start at"
          assert_equal_dates @original_hide_at, @syndicated_deal.hide_at, "Should be udpated with source deal hide at"
        end
      end
    
      context "advertiser_revenue_share_percentage" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, 
                                 :advertiser_revenue_share_percentage => 31, 
                                 :affiliate_revenue_share_percentage => 11)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal 31, @syndicated_deal.advertiser_revenue_share_percentage, "Should be created with advertiser_revenue_share_percentage"
          @source_deal.advertiser_revenue_share_percentage = 22
          @source_deal.save!
          @source_deal.reload
        end
        should "update syndicated deal advertiser_revenue_share_percentage" do
          assert_equal 22, @source_deal.advertiser_revenue_share_percentage, "Advertiser_revenue_share_percentage should be updated"
          assert_equal 22, @syndicated_deal.advertiser_revenue_share_percentage, "Should be updated with advertiser_revenue_share_percentage"
        end
      end
    
      context "location required" do
        setup do
          advertiser = Factory(:advertiser)
          store1 = Factory(:store, :advertiser => advertiser)
          store2 = Factory(:store, :advertiser => advertiser)
          advertiser.stores true
          @source_deal = Factory(:daily_deal_for_syndication, :advertiser => advertiser, :location_required => true)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal true, @syndicated_deal.location_required?, "Should created with source location required"
          @source_deal.location_required = false
          @source_deal.save!
          @source_deal.reload
        end
        should "update syndicated deal location required when saved" do
          assert_equal false, @source_deal.location_required?, "Location required should be updated"
          assert_equal false, @syndicated_deal.location_required?, "Should be updated with source deal location required"
        end
      end
    
      context "bar code format" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :bar_code_encoding_format => 7)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal 7, @syndicated_deal.bar_code_encoding_format, "Should be created with source bar code encoding format"
          @source_deal.bar_code_encoding_format = 4
          @source_deal.save!
          @source_deal.reload
        end
        should "update syndicated deal bar code format" do
          assert_equal 4, @source_deal.bar_code_encoding_format, "Bar code encoding format should be updated"
          assert_equal 4, @syndicated_deal.bar_code_encoding_format, "Should be updated with source bar code encoding format"
        end
      end
    
      context "national deal" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :national_deal => false)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          assert_equal false, @syndicated_deal.national_deal, "Should be created with national deal false"
          @source_deal.national_deal = true
          @source_deal.save!
          @source_deal.reload
        end
        should "update syndicated deal national deal" do
          assert_equal true, @syndicated_deal.national_deal, "National deal should be true"
        end
      end
      
      context "missing analytics_category on source deal" do
        
        setup do
          @unassigned_category = Factory(:daily_deal_category, :name => "Unassigned", :abbreviation => "UN")
          @source_deal = Factory(:daily_deal_for_syndication, :analytics_category => nil)
          @distributing_publisher.update_attribute(:require_daily_deal_category, true)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
        end
        
        should "set syndicated deal analytics category to unassigned category" do
          assert_equal @unassigned_category, @syndicated_deal.analytics_category
        end
        
        
        
      end
    
    end
    
    context "save syndicated deal" do
    
      setup do
        @distributing_publisher = Factory(:publisher)
      end
    
      context "deal description" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :description => "very cool stuff")
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          @syndicated_deal.description = "cooler stuff"
          @syndicated_deal.save!
          @syndicated_deal.reload
        end
        should "NOT update source deal description" do
          assert_equal "cooler stuff", @syndicated_deal.description(:source), "Should copy description"
          assert_equal "very cool stuff", @source_deal.description(:source), "Should not modify source description"
        end
      end
    
      context "terms" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :terms => "one only")
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          @syndicated_deal.terms = "two only"
          @syndicated_deal.save!
          @syndicated_deal.reload
        end
        should "NOT update source deal terms" do
          assert_equal "two only", @syndicated_deal.terms(:source), "Should copy terms"
          assert_equal "one only", @source_deal.terms(:source), "Should not modify source terms"
        end
      end
    
      context "value proposition" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :value_proposition => "$20 for $10")
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          @syndicated_deal.value_proposition = "$60 for $30"
          @syndicated_deal.save!
          @syndicated_deal.reload
        end
        should "NOT update source deal value proposition" do
          assert_equal "$60 for $30", @syndicated_deal.value_proposition, "Should copy value proposition"
          assert_equal "$20 for $10", @source_deal.value_proposition, "Should not modify source value proposition"
        end
      end
    
      context "listing" do
        setup do
          @source_deal = Factory(:daily_deal_for_syndication, :listing => "BBD-123")
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
          @syndicated_deal.listing = "ABC-123"
          @syndicated_deal.save!
          @syndicated_deal.reload
        end
        should "NOT update source deal listing" do
          assert_equal "ABC-123", @syndicated_deal.listing, "Should copy listing"
          assert_equal "BBD-123", @source_deal.listing, "Should not modify source listing"
        end
      end
    
    end
    
    context "all_publishers_available_for_syndication" do
      context "including publishers for already syndicated deals" do
        context "entire syndication network" do
          setup do
            Publisher.destroy_all
    
            publishing_group = Factory(:publishing_group, :restrict_syndication_to_publishing_group => false)
            @publisher1 = Factory(:publisher, :publishing_group => publishing_group)
            @publisher2 = Factory(:publisher)
            @publisher3 = Factory(:publisher)
            @daily_deal = Factory(:daily_deal, :publisher => @publisher1)
          end
    
          should "return all publishers except the publisher called upon" do
            expected = Set.new(Publisher.all.map(&:id)) - [@publisher1.id]
            actual = @daily_deal.all_publishers_available_for_syndication(true).map(&:id)
            assert_same_elements expected, actual
          end
        end
    
        context "syndication restricted to publishing group" do
          setup do
            publishing_group = Factory(:publishing_group, :restrict_syndication_to_publishing_group => true)
            @publisher1 = Factory(:publisher, :publishing_group => publishing_group)
            @publisher2 = Factory(:publisher, :publishing_group => publishing_group)
            @publisher3 = Factory(:publisher)
            @daily_deal = Factory(:daily_deal, :publisher => @publisher1)
          end
    
          should "show checkboxes for publisher selection for syndication" do
            assert_equal [@publisher2.id], @daily_deal.all_publishers_available_for_syndication(true).map(&:id)
          end
        end
      end
    
      context "not including publishers for already syndicated deals" do
        setup do
          @distributing_publisher = Factory(:publisher)
          @source_deal = Factory(:daily_deal_for_syndication)
          @syndicated_deal = syndicate(@source_deal, @distributing_publisher)
        end
    
        should "NOT include the source publisher in publishers available for syndication" do
          publishers = @syndicated_deal.source.all_publishers_available_for_syndication
          assert publishers.size > 0, "Should find at least one publisher"
          assert !publishers.include?(@syndicated_deal.source.publisher), "Should not include the source publisher"
        end
    
        should "NOT include the syndicated deal publishers in publishers available for syndication" do
          publishers = @syndicated_deal.source.all_publishers_available_for_syndication
          assert publishers.size > 0, "Should find at least one publisher"
          assert !publishers.include?(@source_deal.publisher), "Should not include the syndicated deal publisher"
        end
      end

      context "on a Travelsavers deal" do
        setup do
          @source_deal = Factory(:travelsavers_daily_deal_for_syndication)
          @publisher_in_ts_syndication_network = Factory :publisher, :in_travelsavers_syndication_network => true
        end

        should "include only publishers that have in_travelsavers_syndication_network set to true" do
          assert_equal [@publisher_in_ts_syndication_network], @source_deal.all_publishers_available_for_syndication
        end
      end
    end
    
    context "assign_bar_code" do
    
      setup do
        @codes                = %w{ 01234 }
        @distributing_publisher = Factory(:publisher)
        @source_deal           = Factory(:daily_deal_for_syndication)
        @syndicated_deal      = syndicate(@source_deal, @distributing_publisher)
        @source_deal.import_bar_codes StringIO.new(@codes.join("\n") << "\n"), false, false
      end
    
      should "assign syndicated deal to daily deal" do
        assert_equal 1, @source_deal.syndicated_deals.size
      end
    
      should "assign 1 bar code to daily deal" do
        assert_equal 1, @source_deal.bar_codes.size
      end
    
      should "have syndicated_deal reference the daily_deal barcodes" do
        assert_equal 1, @syndicated_deal.bar_codes.size
        assert_equal @source_deal.bar_codes.first, @syndicated_deal.bar_codes.first
      end
    
      context "with all existing bar codes used up on source deal" do
    
        setup do
          @source_deal.bar_codes.first.update_attribute(:assigned, true)
        end
    
        should "have 0 unassigned bar codes on daily deal" do
          assert_equal 0, @source_deal.bar_codes.unassigned.size
        end
    
        should "raise error when trying to assign_bar_code on @source_deal" do
          assert_raise RuntimeError do
            @source_deal.assign_bar_code
          end
        end
    
        should "raise error when tyring to assign_bar_code on @syndicated_deal" do
          assert_raise RuntimeError do
            @syndicated_deal.assign_bar_code
          end
        end
    
      end
    
      context "with remaining bar codes on source deal" do
    
        should "have 1 unassigned bar code on daily deal" do
          assert_equal 1, @source_deal.bar_codes.unassigned.size
        end
    
        context "assign_bar_code on @source_deal" do
    
          setup do
            @source_deal.assign_bar_code
          end
    
          should "no longer have any unassigned bar codes on @source_deal" do
            assert_equal 0, @source_deal.bar_codes.unassigned.size
          end
    
          should "no longer have any unassigned bar codes on @syndicated_deal" do
            assert_equal 0, @syndicated_deal.bar_codes.unassigned.size
          end
    
        end
    
        context "assign_bar_code on @syndicated_deal" do
    
          setup do
            @syndicated_deal.assign_bar_code
          end
    
          should "no longer have any unassigned bar codes on @source_deal" do
            assert_equal 0, @source_deal.bar_codes.unassigned.size
          end
    
          should "no longer have any unassigned bar codes on @syndicated_deal" do
            assert_equal 0, @syndicated_deal.bar_codes.unassigned.size
          end
    
        end
    
      end
    
    end
    
    context "source deal not featured" do
      setup do
        @distributing_publisher = Factory(:publisher, :time_zone => "Eastern Time (US & Canada)")
        @source_publisher = Factory(:publisher, :time_zone => "Pacific Time (US & Canada)")
        @source_advertiser = Factory(:advertiser, :publisher => @source_publisher)
        @side_deal = Factory(:side_daily_deal_for_syndication,
                              :advertiser => @source_advertiser,
                              :advertiser_revenue_share_percentage => 5,
                              :affiliate_revenue_share_percentage => 10)
      end
      
      should "produce a distributed deal that is not featured when syndicated" do
        @distributed_side_deal = syndicate(@side_deal, @distributing_publisher)
        assert_equal false, @distributed_side_deal.featured
      end
      
    end
    
  end
end
