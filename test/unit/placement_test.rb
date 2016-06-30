require File.dirname(__FILE__) + "/../test_helper"

class PlacementTest < ActiveSupport::TestCase

  context "#self.place_offer" do

    setup do
      @publisher = stub :place_offers_with => 'some pubs'
    end

    should "reload the publisher when placing an offer to avoid a potential AR bug" do
      @offer = stub :publisher => nil
      @reloaded_offer = stub :publisher => @publisher
      @offer.expects(:reload).returns(@reloaded_offer)
      @offer.expects(:place_with).with('some pubs')
      Placement.place_offer(@offer)
    end

    should "no reload the publisher when one already exists" do
      @offer = stub :publisher => @publisher
      @offer.expects(:reload).never
      @offer.expects(:place_with).with('some pubs')
      Placement.place_offer(@offer)
    end
  end
end
