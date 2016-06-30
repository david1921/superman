require File.dirname(__FILE__) + "/../test_helper"

class ClickCountTest < ActiveSupport::TestCase
  test "should record" do
    offer0 = offers(:my_space_burger_king_free_fries)
    advertiser = offer0.advertiser
    publisher = advertiser.publisher
    offer1 = advertiser.offers.create!(:message => "Offer 1")
    assert_equal 0, ClickCount.count
    
    ClickCount.record(offer0, publisher.id)
    assert_equal 1, ClickCount.count, "Click count after record created"
    click_count = ClickCount.find(:first)
    assert_equal offer0, click_count.clickable
    assert_equal publisher, click_count.publisher
    assert_equal 1, click_count.count

    ClickCount.record(offer0, publisher.id)
    assert_equal 1, ClickCount.count, "Should increment count on existing record"
    click_count.reload
    assert_equal click_count, ClickCount.find(:first)
    assert_equal offer0, click_count.clickable
    assert_equal publisher, click_count.publisher
    assert_equal 2, click_count.count

    ClickCount.record(offer0, publisher.id)
    assert_equal 1, ClickCount.count, "Should increment count on existing record"
    click_count.reload
    assert_equal click_count, ClickCount.find(:first)
    assert_equal offer0, click_count.clickable
    assert_equal publisher, click_count.publisher
    assert_equal 3, click_count.count

    ClickCount.record(offer1, publisher.id)
    assert_equal 2, ClickCount.count, "Should create a new record"
    assert_not_nil (click_count = ClickCount.find_by_clickable_type_and_clickable_id('Offer', offer1))
    assert_equal publisher, click_count.publisher
    assert_equal 1, click_count.count, "Should count one click on offer1"
    assert_not_nil (click_count = ClickCount.find_by_clickable_type_and_clickable_id('Offer', offer0))
    assert_equal publisher, click_count.publisher
    assert_equal 3, click_count.count, "Should not change count on offer0"
  end
  
  test "should record from model" do
    offer0 = offers(:my_space_burger_king_free_fries)
    advertiser = offer0.advertiser
    publisher = advertiser.publisher
    offer1 = advertiser.offers.create!(:message => "Offer 1")
    assert_equal 0, ClickCount.count
    
    offer0.record_click(publisher.id)
    assert_equal 1, ClickCount.count, "Click count after record created"
    click_count = ClickCount.find(:first)
    assert_equal offer0, click_count.clickable
    assert_equal publisher, click_count.publisher
    assert_equal 1, click_count.count

    offer0.record_click(publisher.id)
    assert_equal 1, ClickCount.count, "Should increment count on existing record"
    click_count.reload
    assert_equal click_count, ClickCount.find(:first)
    assert_equal offer0, click_count.clickable
    assert_equal publisher, click_count.publisher
    assert_equal 2, click_count.count

    offer0.record_click(publisher.id)
    assert_equal 1, ClickCount.count, "Should increment count on existing record"
    click_count.reload
    assert_equal click_count, ClickCount.find(:first)
    assert_equal offer0, click_count.clickable
    assert_equal publisher, click_count.publisher
    assert_equal 3, click_count.count

    offer1.record_click(publisher.id)
    assert_equal 2, ClickCount.count, "Should create a new record"
    assert_not_nil (click_count = ClickCount.find_by_clickable_type_and_clickable_id('Offer', offer1))
    assert_equal publisher, click_count.publisher
    assert_equal 1, click_count.count, "Should count one click on offer1"
    assert_not_nil (click_count = ClickCount.find_by_clickable_type_and_clickable_id('Offer', offer0))
    assert_equal publisher, click_count.publisher
    assert_equal 3, click_count.count, "Should not change count on offer0"
  end
end
