require File.dirname(__FILE__) + "/../test_helper"

# Don't believe that this test is slow. It loads first, and test_benchmark blames it for Rails test bootstrap.
class AdvertiserImportTest < ActiveSupport::TestCase
  test "import" do
    Timecop.freeze(Time.now) do
      advertiser_count = Advertiser.count
      publisher_count = Publisher.count
      
      locm = publishing_groups(:locm)

      # Will be updated
      existing_publisher = locm.publishers.create! :name => "ROCHESTERMINNESOTA", :label => "1072", :advertiser_has_listing => true
      existing_publisher.users.create!(
        :login => "not_admin", 
        :email => "scott@goatse.cx",
        :password => "secret",
        :password_confirmation => "secret")
      existing_advertiser = existing_publisher.advertisers.create!(:name => "Car-X", :listing => "437384")
      existing_advertiser.stores.create(
        :phone_number => "5072822299", 
        :address_line_1 => "424 37th Street NE",
        :city => "Rochester",
        :state => "MN",
        :zip => "55906"
      ).save!

      # Will move to new Publisher
      existing_advertiser = existing_publisher.advertisers.create! :name => "Chandler-Gilbert Community College", :listing => "435200"
      existing_advertiser.stores.create(
        :phone_number => "4807327000", 
        :address_line_1 => "2626 E Pecos Rd",
        :city => "Chandler",
        :state => "AZ",
        :zip => "85225"
      ).save!
      offer = existing_advertiser.offers.create!(:message => "Free!")
      ImpressionCount.record offer, existing_publisher.id
      
      # Advertiser will move to existing Publisher journalstandard
      journalstandard = locm.publishers.create!(:name => "journalstandard", :label => "738", :advertiser_has_listing => true)
      existing_advertiser = existing_publisher.advertisers.create!(:name => "O\"Maddys", :listing => "304254")
      offer = existing_advertiser.offers.create!(:message => "2 for 1")
      ImpressionCount.record offer, journalstandard.id
      offer = existing_advertiser.offers.create!(:message => "Gratuit")
      ImpressionCount.record offer, journalstandard.id
      
      # Will be deleted because not in import, even though it has store, offers and impressions
      existing_publisher.advertisers.create!(:name => "Palio Cafe", :listing => "999999999")
      publisher_to_delete = locm.publishers.create!(:name => "Ladd's Addition", :label => "111222444", :advertiser_has_listing => true)
      advertiser = publisher_to_delete.advertisers.create!(:name => "Una Mas", :listing => "12361263")
      offer = advertiser.offers.create!(:message => "2 for 1")
      ImpressionCount.record offer, publisher_to_delete.id
      advertiser.stores.create(
        :phone_number => "3156552961", 
        :address_line_1 => "1 Maple Street",
        :city => "Mulberry",
        :state => "NC",
        :zip => "85225"
      ).save!
      
      # Same information as import file should not be updated
      no_changes_publisher = locm.publishers.create! :name => "doverpost", :label => "1114", :advertiser_has_listing => true
      no_changes_advertiser = no_changes_publisher.advertisers.create!(:name => "DOVER, DE-PARKVIEW RV", :listing => "191619")
      no_changes_advertiser.stores.create(
        :phone_number => "8004331348", 
        :address_line_1 => "5511 DuPOINT PARKWAY",
        :city => "Smyrna",
        :state => "DE",
        :zip => "19977"
      ).save!
      
      # Non-Local.com publishers and advertisers
      non_locm_publisher = Factory(:publisher, :name => "Portland Mercury")
      non_locm_advertiser = non_locm_publisher.advertisers.create!(:name => "Stumptown")
      
      oregon_live = PublishingGroup.create!(:name => "OregonLive")
      oregon_live_publisher = oregon_live.publishers.create!(:name => "Oregonian")
      oregon_live_advertiser = oregon_live_publisher.advertisers.create!(:name => "Tonkin Cars")
      
      # There's also a full-size fixture: AAListingFullList_20100301.csv
      quietly do
        Advertiser.import "#{Rails.root}/test/fixtures/files/small.csv"
      end
    
      # Assert that we handle double-quotes correctly
      advertiser = Advertiser.find_by_listing("325381")
      assert_not_nil advertiser, "Should create Advertiser with listing 325381"
      assert_equal "Pet Supplies \"Plus\"", advertiser.name, "Advertiser name"
      assert_equal 1, Advertiser.count(:conditions => "listing = 325381"), "Advertiser count with listing 325381"
      
      advertiser = Advertiser.find_by_listing("304254")
      assert_not_nil advertiser, "Should create Advertiser with listing 304254"
      assert_equal "O\"Maddys", advertiser.name, "Advertiser name"
      assert_equal journalstandard, advertiser.publisher, "Should move advertiser to existing publisher"
      assert_equal 1, Advertiser.count(:conditions => "listing = 304254"), "Advertiser count with listing 304254"
      assert_equal 2, advertiser.offers.count, "Advertiser should retain offers"
      assert_equal 1, advertiser.offers.first.impression_counts.count, "Should preseve impression counts"
      assert_not_nil advertiser.store, "Should add store"
      assert_equal "18152660880", advertiser.store.phone_number, "phone_number"
      assert_equal "109 Galena Street", advertiser.store.address_line_1, "address_line_1"
      assert_equal "Freeport", advertiser.store.city, "city"
      assert_equal "IL", advertiser.store.state, "state"
      assert_equal "61032", advertiser.store.zip, "zip"

      advertiser = Advertiser.find_by_listing("190808")
      assert_not_nil advertiser, "Should create Advertiser with listing 190808"
      assert_equal "ATHENS AGWAY \"Everything Outdoors\"", advertiser.name, "Advertiser name"
      assert_equal 1, Advertiser.count(:conditions => "listing = 190808"), "Advertiser count with listing 190808"
      
      advertiser = Advertiser.find_by_listing("437384")
      assert_not_nil advertiser, "Should create Advertiser with listing 437384"
      assert_equal "Car-X Auto Service", advertiser.name, "Should update Advertiser name"
      assert_equal "15072822288", advertiser.store.phone_number, "Should update Advertiser store phone_number"
      assert_equal "424 37th St Ne", advertiser.store.address_line_1, "Should update Advertiser store address_line_1"
      assert_equal 1, Advertiser.count(:conditions => "listing = 437384"), "Advertiser count with listing 437384"
      
      publisher = Publisher.find_by_label("1468")
      assert_not_nil publisher, "Should have Publisher with label 1468"
      assert_equal "timesleader", publisher.name, "Publisher name"
      assert_equal locm, publisher.publishing_group, "New Publisher's PublishingGroup"
      assert_equal 1, Publisher.count(:conditions => "label = 1468"), "Publisher count with listing 1468"
      
      publisher = Publisher.find_by_label("1072")
      assert_not_nil publisher, "Should have Publisher with label 1072"
      assert_equal "rochestermn", publisher.name, "Should update Publisher name"
      assert_equal locm, publisher.publishing_group, "Existing Publisher's PublishingGroup"
      assert_equal 1, publisher.users.count, "Should preserve users"
      assert_equal 1, Publisher.count(:conditions => "label = 1072"), "Publisher count with listing 1072"
      
      assert !Advertiser.first(:conditions => ["name = ?", "Palio Cafe"], :joins => :translations), "Should delete advertiser that is not in import file"
      assert !Advertiser.exists?(:listing => "999999999"), "Should delete advertiser that is not in import file"

      assert Publisher.exists?(:name => "Ladd's Addition"), "Should not delete publisher even if it is not in import file"
      assert Publisher.exists?(:label => "111222444"), "Should not delete publisher even if it is not in import file"
      assert !Advertiser.exists?(:listing => "12361263"), "Should delete advertiser that is not in import file"
          
      advertiser = Advertiser.find_by_listing("435200")
      assert_not_nil advertiser, "Should preserve advertiser with new publisher"
      assert_equal "eastvalleytribune", advertiser.publisher.name, "New publisher name for moved advertiser"
      assert_equal "534", advertiser.publisher.label, "New publisher label for moved advertiser"
      assert_equal 1, advertiser.offers.count, "Advertiser should retain offers"
      assert_equal "Free!", advertiser.offers.first.message, "offer message"
      assert_equal 1, advertiser.offers.first.impression_counts.count, "Should preseve impression counts"
      assert_equal 1, Advertiser.count(:conditions => "listing = 435200"), "Advertiser count with listing 534"

      publisher = Publisher.find_by_label("738")
      assert_not_nil publisher, "Should have Publisher with label 738"
      assert_equal "journalstandard", publisher.name, "Should update Publisher name"
      assert_equal locm, publisher.publishing_group, "Existing Publisher's PublishingGroup"
      assert_equal 1, Publisher.count(:conditions => "label = 738"), "Publisher count with listing 738"
      
      publisher = Publisher.find(no_changes_publisher.id)
      assert_equal_date_times no_changes_publisher.updated_at, publisher.updated_at, "Should not update publisher if import file has same info"
      assert_equal_date_times no_changes_publisher.created_at, publisher.created_at, "Should not update publisher if import file has same info"
      
      advertiser = Advertiser.find(no_changes_advertiser.id)
      assert_equal_date_times no_changes_advertiser.updated_at, advertiser.updated_at, "Should not update advertiser if import file has same info"
      assert_equal_date_times no_changes_advertiser.created_at, advertiser.created_at, "Should not update advertiser if import file has same info"
      
      assert Publisher.exists?(non_locm_publisher.id), "Should not delete non-Local.com publishers"
      assert Advertiser.exists?(non_locm_advertiser.id), "Should not delete non-Local.com advertisers"

      assert PublishingGroup.exists?(oregon_live.id), "Should not delete publishing groups"
      assert Publisher.exists?(oregon_live_publisher.id), "Should not delete non-Local.com publishers"
      assert Advertiser.exists?(oregon_live_advertiser.id), "Should not delete non-Local.com advertisers"
      
      assert_equal 9, Advertiser.count - advertiser_count, "Should import all advertisers from file"
      assert_equal 9, Publisher.count - publisher_count, "Should create new publishers from file"
    end
  end
end
