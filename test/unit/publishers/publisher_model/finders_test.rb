require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::FindersTest
module Publishers
  module PublisherModel
    class FindersTest < ActiveSupport::TestCase
      test "find category by category label" do
        publisher = publishers(:houston_press)
        advertiser = publisher.advertisers.create!(:name => "My Advertiser", :listing => "mylisting")
        offer = advertiser.offers.create!(:message => "My Message", :category_names => "Entertainment : Events")

        entertainment_category = publisher.find_category_by_category_label("entertainment")
        events_category = publisher.find_category_by_category_label("events")
        assert_not_nil entertainment_category
        assert_equal "Entertainment", entertainment_category.name

        assert_not_nil events_category
        assert_equal "Events", events_category.name
      end

      test "find category by path with parent category with no offers" do
        Offer.destroy_all
        publisher = publishers(:houston_press)
        category = Category.create!(:name => "Rentals")
        assert_equal category, publisher.find_category_by_path(["", "rentals"])
      end

      test "find category by path with duplicate parent category with publishers offers" do
        rentals_1 = Category.create!(:name => "Rentals")
        rentals_2 = Category.create!(:name => "Rentals")
        publisher = publishers(:houston_press)
        advertiser = publisher.advertisers.create!(:name => "My Advertiser", :listing => "mylisting")
        offer = advertiser.offers.create!(:message => "My Message")

        assert_equal 2, Category.find(:all, :conditions => ["label = ?", 'rentals']).size

        # let's make sure to assign the rentals category that will not be found by Category.find_by_label,
        # so we know our publisher category lookup code is working.
        offer_category = Category.find_by_label("rentals") == rentals_1 ? rentals_2 : rentals_1
        offer.categories << offer_category
        offer.save

        assert_equal offer.categories.first, publisher.find_category_by_path(["", "rentals"])
        assert_equal offer_category, publisher.find_category_by_path(["", "rentals"])
      end

      test "find category by path with child category with no offers" do
        Offer.destroy_all
        publisher = publishers(:houston_press)
        entertainment = Category.create!(:name => "Entertainment")
        event = entertainment.children.create!(:name => "Events")
        assert_equal event, publisher.find_category_by_path(["entertainment", "events"])
      end

      test "find_by_label!" do
        publisher = Factory(:publisher)
        # Ensure missing label raises a RecordNotFound, not first Publisher with no label
        Factory(:publisher, :label => nil)
        Factory(:publisher, :label => "")

        assert_raise ActiveRecord::RecordNotFound do
          Publisher.find_by_label! "not a publisher label"
        end

        assert_raise ActiveRecord::RecordNotFound do
          Publisher.find_by_label! ""
        end

        assert_raise ActiveRecord::RecordNotFound do
          Publisher.find_by_label! nil
        end

        assert_equal publisher, Publisher.find_by_label!(publisher.label), "Should find publisher"
      end

      context "force_password_reset?" do
        setup do
          @publisher = Factory(:publisher)
          @consumer = Factory(:consumer, :publisher => @publisher, :email => "joe@yahoo.com")
        end
        should "return false when consumer does not have force reset set" do
          assert !@consumer.force_password_reset?
          assert !@publisher.force_password_reset?("joe@yahoo.com")
        end
        should "return true when consumer has force reset set" do
          @consumer.force_password_reset = true
          @consumer.save!
          assert @publisher.force_password_reset?("joe@yahoo.com")
        end
        should "return false when consumer doe snot exist" do
          assert !@publisher.force_password_reset?("doesnotexist@nowheresville.domc")
        end
      end

    end
  end
end
