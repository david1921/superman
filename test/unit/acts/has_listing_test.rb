require File.dirname(__FILE__) + "/../../test_helper"

class HasListingTest < ActiveSupport::TestCase
  
  def test_has_listing_on_advertiser
    assert Advertiser.included_modules.include?(HasListing)
    publisher = Factory.create(:publisher)
    advertiser = Factory.create(:advertiser, :publisher => publisher)
    publisher.advertiser_has_listing = false
    assert !advertiser.listing?
    advertiser.listing = nil
    advertiser.save!
    advertiser.listing = "not blank"
    assert_nothing_raised { advertiser.save! }
    publisher.advertiser_has_listing = true 
    assert advertiser.listing?
    advertiser.listing = "not blank"
    advertiser.save!
    advertiser.listing = nil
    assert_raise ActiveRecord::RecordInvalid do
      advertiser.save!
    end
  end
  
  def test_has_listing_on_offer
    assert Offer.included_modules.include?(HasListing)
    publisher = Factory.create(:publisher)
    advertiser = Factory.create(:advertiser, :publisher => publisher)
    offer = Factory.create(:offer, :advertiser => advertiser)

    assert_equal publisher, advertiser.publisher
    assert_equal publisher, offer.publisher
    publisher.offer_has_listing = false
    assert !offer.listing?
    offer.listing = nil
    offer.save!
    offer.listing = "not blank"
    publisher = Publisher.find(publisher.id)
    assert_nothing_raised { offer.save! }
    publisher.offer_has_listing = true 
    publisher.save! 
    # do not understand exactly why
    # we have to re-find here...
    offer = Offer.find(offer.id)
    assert offer.listing?
    offer.listing = "not blank"  
    offer.save!
    offer.listing = nil
    assert_raise ActiveRecord::RecordInvalid do
      offer.save!
    end
  end
  
end