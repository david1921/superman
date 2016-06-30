require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Offers::ScopesTest
module Offers
  class ScopesTest < ActiveSupport::TestCase
    test "offers by popularity with offers" do
      publisher = publishers(:houston_press)
      publisher.offers.destroy_all
      advertiser = publisher.advertisers.create!(:listing => "mylisting")
      offer_1 = advertiser.offers.create!(:message => "My Offer", :popularity => 12.0 )
      offer_2 = advertiser.offers.create!(:message => "My POPULAR OFfer", :popularity => 23.0 )

      offers = publisher.offers.by_popularity
      assert_equal offer_2, offers.first
      assert_equal offer_1, offers.last
    end

    test "offers by popularity with limit" do
      publisher = publishers(:houston_press)
      publisher.offers.destroy_all
      advertiser = publisher.advertisers.create!(:listing => "mylisting")
      offer_1 = advertiser.offers.create!(:message => "My Offer", :popularity => 12.0 )
      offer_2 = advertiser.offers.create!(:message => "My POPULAR OFfer", :popularity => 23.0 )
      offer_3 = advertiser.offers.create!(:message => "Another POPULAR Offer", :popularity => 15.0)
      offer_4 = advertiser.offers.create!(:message => "Not so popular", :popularity => 0.19)
      offer_5 = advertiser.offers.create!(:message => "No one likes")

      offers = publisher.offers.by_popularity.limit(2)
      assert_equal 2, offers.length
      assert_equal offer_2, offers.first
      assert_equal offer_3, offers.last
    end

    context "active_between" do

      setup do
        @publisher = Factory(:publisher)
        @advertiser = Factory(:advertiser, :publisher => @publisher)
        @advertiser2 = Factory(:advertiser, :publisher => @publisher)
      end

      should "work when zero offers are to be found" do
        @publisher = Factory(:publisher)
        assert_equal 0, @publisher.offers.active_between(Time.now.beginning_of_year..Time.now).length
      end

      should "only find offers in the range" do
        jan = Time.utc(2011, 1, 1)
        feb = Time.utc(2011, 2, 1)
        march = Time.utc(2011, 3, 1)
        april = Time.utc(2011, 4, 1)
        may = Time.utc(2011, 5, 1)
        june = Time.utc(2011, 6, 1)
        Timecop.freeze march do
          offers = [
            Factory(:offer, :message => "offer 0", :advertiser => @advertiser, :show_on => feb, :expires_on => feb + 15.days),
            Factory(:offer, :message => "offer 1", :advertiser => @advertiser2, :show_on => feb + 15.days, :expires_on => march + 15.days),
            Factory(:offer, :message => "offer 2", :advertiser => @advertiser, :show_on => march, :expires_on => april),
            Factory(:offer, :message => "offer 3", :advertiser => @advertiser2, :show_on => feb, :expires_on => june),
            Factory(:offer, :message => "offer 4", :advertiser => @advertiser, :show_on => may, :expires_on => june)
          ]
          expected = [
            "offer 1", "offer 2", "offer 3"
          ]
          assert_equal expected, @publisher.offers.active_between(march..april).map(&:message).sort
        end
      end

    end

  end
end
