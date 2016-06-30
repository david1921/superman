require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::OffersTest
module Publishers
  module PublisherModel
    class OffersTest < ActiveSupport::TestCase
      test "offers" do
        publisher = Factory(:publisher, :name => "Test Publisher")
        assert_equal [], publisher.offers, "offers"

        offer_1 = publisher.advertisers.create!.offers.create! :message => "message"
        assert_equal [ offer_1 ], publisher.offers(true), "offers"

        offer_2 = publisher.advertisers.create!.offers.create! :message => "message"
        assert_equal [ offer_1, offer_2 ].sort, publisher.offers(true).sort, "offers"
      end

      test "active offers count no offers" do
        assert_equal 0, Factory(:publisher, :name => "P").active_offers_count, "active_offers_count with no offers"
      end

      test "active offers count" do
        assert_equal 1, publishers(:my_space).active_offers_count, "active_offers_count"
      end

      test "active offers count many offers" do
        advertisers(:burger_king).offers.create!(:message => "msg")
        assert_equal 2, publishers(:my_space).active_offers_count, "active_offers_count"
      end

      test "active offers count expired" do
        advertisers(:burger_king).offers.create!(:message => "msg", :expires_on => 1.day.ago)
        assert_equal 1, publishers(:my_space).active_offers_count, "active_offers_count with expired offer"
      end

      test "active offers count expired and deleted" do
        advertisers(:burger_king).offers.create!(:message => "msg", :expires_on => 1.day.ago)
        advertisers(:burger_king).offers.create!(:message => "msg", :deleted_at => Time.now)
        assert_equal 1, publishers(:my_space).active_offers_count, "active_offers_count with expired offer and deleted offer"
      end

      test "active offers count city state no offers" do
        publisher = Factory(:publisher, :name => "P", :default_offer_search_distance => 10)
        assert_equal 0, publisher.active_offers_count("Seattle", "WA"), "active_offers_count with no offers"
      end

      test "active offers count no default offer search distance" do
        publisher = publishers(:my_space)

        advertiser = publisher.advertisers.create!
        advertiser.stores.create(:address_line_1 => "123 Main Street", :city => "Cazenovia", :state => "NY", :zip => "13035")
        advertiser.offers.create!(:message => "!")

        advertiser = publisher.advertisers.create!
        advertiser.stores.create(:address_line_1 => "123 Main Street", :city => "San Diego", :state => "NY", :zip => "92101")
        advertiser.offers.create!(:message => "!")

        assert_equal 0, publishers(:my_space).active_offers_count("Cazenovia", "NY"), "active_offers_count"
        assert_equal 0, publishers(:my_space).active_offers_count("San Diego", "CA"), "active_offers_count"
        assert_equal 0, publishers(:my_space).active_offers_count("Monterey", "CA"), "active_offers_count"
      end

      test "active offers count with city and state" do
        publisher = publishers(:my_space)
        publisher.update_attribute :default_offer_search_distance, 10

        advertiser = publisher.advertisers.create!
        assert advertiser.stores.create(:address_line_1 => "Sesame Street", :city => "Sheds", :state => "NY", :zip => "13035").valid?
        advertiser.offers.create!(:message => "!")

        advertiser = publisher.advertisers.create!
        assert advertiser.stores.create(:address_line_1 => "Easy Street", :city => "San Diego", :state => "CA", :zip => "92101").valid?
        advertiser.offers.create!(:message => "!")

        assert_equal 1, publishers(:my_space).active_offers_count("Cazenovia", "NY"), "active_offers_count"
        assert_equal 1, publishers(:my_space).active_offers_count("San Diego", "CA"), "active_offers_count"
        assert_equal 0, publishers(:my_space).active_offers_count("Monterey", "CA"), "active_offers_count"
      end

      test "active offers count with city and state and expired and deleted" do
        publisher = publishers(:my_space)
        publisher.update_attribute :default_offer_search_distance, 10

        advertiser = publisher.advertisers.create!
        assert advertiser.stores.create(:address_line_1 => "Sesame Street", :city => "Sheds", :state => "NY", :zip => "13035").valid?
        advertiser.offers.create!(:message => "!")
        advertiser.offers.create!(:message => "!", :deleted_at => Time.now)

        assert advertiser.stores.create(:address_line_1 => "Sesame Street", :city => "Cazenovia", :state => "NY", :zip => "13035").valid?
        advertiser.offers.create!(:message => "***")

        advertiser = publisher.advertisers.create!
        assert advertiser.stores.create(:address_line_1 => "Easy Street", :city => "San Diego", :state => "CA", :zip => "92101").valid?
        advertiser.offers.create!(:message => "!")
        advertiser.offers.create!(:message => "!", :expires_on => Time.zone.now.yesterday)

        assert_equal 2, publishers(:my_space).active_offers_count("Cazenovia", "NY"), "active_offers_count"
        assert_equal 1, publishers(:my_space).active_offers_count("San Diego", "CA"), "active_offers_count"
        assert_equal 0, publishers(:my_space).active_offers_count("Monterey", "CA"), "active_offers_count"
      end

      test "active offers count missing city or state" do
        assert_equal 1, publishers(:my_space).active_offers_count(nil, "AK"), "active_offers_count"
        assert_equal 1, publishers(:my_space).active_offers_count("Anchorage", nil), "active_offers_count"
        assert_equal 1, publishers(:my_space).active_offers_count("", "AK"), "active_offers_count"
        assert_equal 1, publishers(:my_space).active_offers_count("Anchorage", "   "), "active_offers_count"
      end

      test "active placed offers count with city and state and expired and deleted" do
        publisher = publishers(:my_space)
        publisher.update_attribute :default_offer_search_distance, 10

        advertiser = publisher.advertisers.create!
        assert advertiser.stores.create(:address_line_1 => "Sesame Street", :city => "Sheds", :state => "NY", :zip => "13035").valid?
        advertiser.offers.create!(:message => "!")
        advertiser.offers.create!(:message => "!", :deleted_at => Time.now)

        assert advertiser.stores.create(:address_line_1 => "Sesame Street", :city => "Cazenovia", :state => "NY", :zip => "13035").valid?
        advertiser.offers.create!(:message => "***")

        advertiser = publisher.advertisers.create!
        assert advertiser.stores.create(:address_line_1 => "Easy Street", :city => "San Diego", :state => "CA", :zip => "92101").valid?
        advertiser.offers.create!(:message => "!")
        advertiser.offers.create!(:message => "!", :expires_on => Time.zone.now.yesterday)

        assert_equal 2, publishers(:my_space).active_placed_offers_count("Cazenovia", "NY"), "active_offers_count"
        assert_equal 1, publishers(:my_space).active_placed_offers_count("San Diego", "CA"), "active_offers_count"
        assert_equal 0, publishers(:my_space).active_placed_offers_count("Monterey", "CA"), "active_offers_count"
      end


      test "active placed offers count with publisher with enable search by publishing group" do
        publishing_group = PublishingGroup.create!( :name => "Publshing Group")
        publisher_1      = Factory(:publisher,  :name => "Publisher 1", :publishing_group => publishing_group, :enable_search_by_publishing_group => true )
        publisher_2      = Factory(:publisher,  :name => "Publisher 2", :publishing_group => publishing_group, :enable_search_by_publishing_group => true )

        assert publisher_1.search_by_publishing_group?
        assert publisher_2.search_by_publishing_group?

        advertiser_1_1   = publisher_1.advertisers.create!
        advertiser_1_1.offers.create!( :message => "Offer 1 For Advertiser 1" )

        advertiser_2_1   = publisher_2.advertisers.create!
        advertiser_2_1.offers.create!( :message => "Offer 1 For Advertiser 2" )

        assert_equal 2, publisher_1.active_placed_offers_count(nil, nil)
        assert_equal 2, publisher_2.active_placed_offers_count(nil, nil)
      end
    end
  end
end