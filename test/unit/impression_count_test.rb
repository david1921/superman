require File.dirname(__FILE__) + "/../test_helper"

class ImpressionCountTest < ActiveSupport::TestCase
  def test_record
    offer0 = offers(:my_space_burger_king_free_fries)
    advertiser = offer0.advertiser
    publisher = advertiser.publisher
    offer1 = advertiser.offers.create!(:message => "Offer")
    assert_equal 0, ImpressionCount.count
    
    ImpressionCount.record(offer0, publisher.id)
    assert_equal 1, ImpressionCount.count, "Impression count after record created"
    impression_count = ImpressionCount.find_by_viewable_id_and_viewable_type(offer0, 'Offer')
    assert_equal 1, impression_count.count
    assert_equal publisher, impression_count.publisher
    impression_count = ImpressionCount.find_by_viewable_id_and_viewable_type(offer1, 'Offer')
    assert_nil impression_count, "impression_count for offer1"

    ImpressionCount.record(offer0, publisher.id)
    assert_equal 1, ImpressionCount.count, "Should increment count on existing record"
    impression_count = ImpressionCount.find_by_viewable_id_and_viewable_type(offer0, 'Offer')
    assert_equal impression_count, ImpressionCount.find_by_viewable_id_and_viewable_type(offer0, 'Offer')
    assert_equal 2, impression_count.count
    assert_equal publisher, impression_count.publisher
    impression_count = ImpressionCount.find_by_viewable_id_and_viewable_type(offer1, 'Offer')
    assert_nil impression_count, "impression_count for offer1"

    ImpressionCount.record(offer1, publisher.id)
    assert_equal 2, ImpressionCount.count, "Should create a new record"
    assert_not_nil (impression_count = ImpressionCount.find_by_viewable_id_and_viewable_type(offer1, 'Offer'))
    assert_equal 1, impression_count.count, "Should count one click on offer1"
    assert_equal publisher, impression_count.publisher
    assert_not_nil (impression_count = ImpressionCount.find_by_viewable_id_and_viewable_type(offer0, 'Offer'))
    assert_equal 2, impression_count.count, "Should not change count on offer0"
    assert_equal publisher, impression_count.publisher
  end
end
