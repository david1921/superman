require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::AdvertisersWithWebOffersTest
module Publishers
  module PublisherModel
    class AdvertisersWithWebOffersTest < ActiveSupport::TestCase

      test "advertisers with web offers by zip codes" do

        ZipCode.destroy_all
        ZipCode.create!( :zip => "97206", :city => "PORTLAND", :state => "OR", :latitude => 45.479927, :longitude => -122.600566, :zip_class => "MULTNOMAH" )
        ZipCode.create!( :zip => "97222", :city => "PORTLAND", :state => "OR", :latitude => 45.442184, :longitude => -122.61861, :zip_class => "CLACKAMAS" )
        ZipCode.create!( :zip => "97201", :city => "PORTLAND", :state => "OR", :latitude => 45.507416, :longitude => -122.689838, :zip_class => "MULTNOMAH" )
        ZipCode.create!( :zip => "97217", :city => "PORTLAND", :state => "OR", :latitude => 45.589592, :longitude => -122.692988, :zip_class => "MULTNOMAH" )

        assert_equal 4, ZipCode.count

        publisher = Factory(:publisher, {:name => "Publisher"})    
        show_on   = Time.zone.now - 1.day

        advertiser_97206 = publisher.advertisers.create!( :name => "Advertiser 97206" )
        advertiser_97206.stores.create({
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Suite 4",
          :city => "Portland",
          :state => "OR",
          :zip => "97206",
          :phone_number => "858-123-4567"
        })
        advertiser_97206.offers.create!( :message => "Advertiser 97206 Offer", :show_on => show_on )

        advertiser_97222 = publisher.advertisers.create!( :name => "Advertiser 97222" )
        advertiser_97222.stores.create({
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Suite 4",
          :city => "Portland",
          :state => "OR",
          :zip => "97222",
          :phone_number => "858-123-4567"
        })
        advertiser_97222.offers.create!( :message => "Advertiser 97222 Offer", :show_on => show_on )

        advertiser_97201 = publisher.advertisers.create!( :name => "Advertiser 97201" )
        advertiser_97201.stores.create({
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Suite 4",
          :city => "Portland",
          :state => "OR",
          :zip => "97201",
          :phone_number => "858-123-4567"
        })
        advertiser_97201.offers.create!( :message => "Advertiser 97201 Offer", :show_on => show_on )

        advertiser_97217 = publisher.advertisers.create!( :name => "Advertiser 97217" )
        advertiser_97217.stores.create({
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Suite 4",
          :city => "Portland",
          :state => "OR",
          :zip => "97217",
          :phone_number => "858-123-4567"
        })
        advertiser_97217.offers.create!( :message => "Advertiser 97217 Offer", :show_on => show_on )

        assert_equal 4, publisher.offers.size

        search_request = SearchRequest.new( :publisher => publisher, :postal_code => "97206", :sort => "Distance", :radius => "5" )
        advertisers    = publisher.advertisers_with_web_offers(search_request)
        assert_equal 3, advertisers.size

        assert_equal advertiser_97206, advertisers[0]
        assert_equal advertiser_97222, advertisers[1]
        assert_equal advertiser_97201, advertisers[2]

      end

      test "advertisers with web offers searching on name" do
        ZipCode.destroy_all
        ZipCode.create!( :zip => "97206", :city => "PORTLAND", :state => "OR", :latitude => 45.479927, :longitude => -122.600566, :zip_class => "MULTNOMAH" )
        ZipCode.create!( :zip => "97222", :city => "PORTLAND", :state => "OR", :latitude => 45.442184, :longitude => -122.61861, :zip_class => "CLACKAMAS" )
        ZipCode.create!( :zip => "97201", :city => "PORTLAND", :state => "OR", :latitude => 45.507416, :longitude => -122.689838, :zip_class => "MULTNOMAH" )
        ZipCode.create!( :zip => "97217", :city => "PORTLAND", :state => "OR", :latitude => 45.589592, :longitude => -122.692988, :zip_class => "MULTNOMAH" )

        assert_equal 4, ZipCode.count

        publisher = Factory(:publisher, {:name => "Publisher"})    
        show_on   = Time.zone.now - 1.day

        advertiser_97206 = publisher.advertisers.create!( :name => "Advertiser 97206" )
        advertiser_97206.stores.create({
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Suite 4",
          :city => "Portland",
          :state => "OR",
          :zip => "97206",
          :phone_number => "858-123-4567"
        })
        advertiser_97206.offers.create!( :message => "Advertiser 97206 Offer", :show_on => show_on )

        advertiser_97222 = publisher.advertisers.create!( :name => "Advertiser 97222" )
        advertiser_97222.stores.create({
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Suite 4",
          :city => "Portland",
          :state => "OR",
          :zip => "97222",
          :phone_number => "858-123-4567"
        })
        advertiser_97222.offers.create!( :message => "Advertiser 97222 Offer", :show_on => show_on )

        advertiser_97201 = publisher.advertisers.create!( :name => "Advertiser 97201" )
        advertiser_97201.stores.create({
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Suite 4",
          :city => "Portland",
          :state => "OR",
          :zip => "97201",
          :phone_number => "858-123-4567"
        })
        advertiser_97201.offers.create!( :message => "Advertiser 97201 Offer -- Incredible Hot Dogs", :show_on => show_on )

        advertiser_97217 = publisher.advertisers.create!( :name => "Advertiser 97217" )
        advertiser_97217.stores.create({
          :address_line_1 => "123 Main Street",
          :address_line_2 => "Suite 4",
          :city => "Portland",
          :state => "OR",
          :zip => "97217",
          :phone_number => "858-123-4567"
        })
        advertiser_97217.offers.create!( :message => "Advertiser 97217 Offer", :show_on => show_on )

        assert_equal 4, publisher.offers.size

        search_request = SearchRequest.new( :publisher => publisher, :text => "Dog" )
        advertisers    = publisher.advertisers_with_web_offers(search_request)
        assert_equal 1, advertisers.size, "should return just on advertiser"
        assert_equal advertiser_97201, advertisers.first, "should return advertiser_97201"
      end
      
    end
  end
end
