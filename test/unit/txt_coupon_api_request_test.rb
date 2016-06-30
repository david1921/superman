require File.dirname(__FILE__) + "/../test_helper"

class TxtCouponApiRequestTest < ActiveSupport::TestCase

  def test_create_without_existing_advertiser
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    txt_coupon_api_request = publishers(:houston_press).txt_coupon_api_requests.build(
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => "12345", :advertiser_location_id => "9",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2400",
      
      :txt_coupon_label       => "My Label",
      :txt_coupon_keyword     => "houtaco",
      :txt_coupon_message     => "my message",
      :txt_coupon_appears_on  => "Jan 01, 2009",
      :txt_coupon_expires_on  => "Jan 30, 2009"
    )
    assert_difference "Advertiser.count" do
      assert txt_coupon_api_request.save, "Txt coupon API request should be valid"
    end
    txt_offer = txt_coupon_api_request.txt_offer
    assert_equal "My Label", txt_offer.label
    assert_not_nil txt_offer.short_code
    assert_equal "HOUTACO", txt_offer.keyword
    assert_equal "my message", txt_offer.message
    assert_equal Date.parse("Jan 01, 2009"), txt_offer.appears_on
    assert_equal Date.parse("Jan 30, 2009"), txt_offer.expires_on

    advertiser = txt_offer.advertiser.reload
    assert advertiser, "New offer should belong to an advertiser"
    assert_equal "Advertiser One", advertiser.name
    assert_equal ["12345", "9"], advertiser.listing_parts
    assert_equal "http://www.advertiser-one.com/", advertiser.website_url    
    
    store = advertiser.store.reload
    assert store, "Advertiser should have a store"
    assert_equal "123 Main Street", store.address_line_1
    assert_equal "Unit 4", store.address_line_2
    assert_equal "Houston", store.city
    assert_equal "TX", store.state
    assert_equal "77002", store.zip
    assert_equal "17132802400", store.phone_number    
  end
  
  def test_create_with_existing_advertiser
    publisher = publishers(:houston_press)
    client_id = "12345"
    location_id = "9"
    
    publisher.advertisers.create!(
      :name => "Advertiser One",
      :listing_parts => [ client_id, location_id ],
      :coupon_clipping_modes => %w{ txt email },
      :website_url => "http://www.advertiser-one.com/",
      :logo => nil
    ).stores.create!(
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Unit 4",
      :city => "Houston",
      :state => "TX",
      :zip => "77002",
      :phone_number => "713-280-2400"
    )
    txt_coupon_api_request = publisher.txt_coupon_api_requests.build(
      :advertiser_name => "Advertiser Two",
      :advertiser_client_id => client_id, 
      :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt",
      :advertiser_website_url => "http://www.advertiser-two.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Services: Laundry",
      :advertiser_store_address_line_1 => "987 Main Street",
      :advertiser_store_address_line_2 => "Unit 6",
      :advertiser_store_city => "Los Angeles",
      :advertiser_store_state => "CA",
      :advertiser_store_zip => "90210",
      :advertiser_store_phone_number => "323-555-1212",
      
      :txt_coupon_label       => "My Label",
      :txt_coupon_keyword     => "houtaco",
      :txt_coupon_message     => "my message",
      :txt_coupon_appears_on  => "Jan 01, 2009",
      :txt_coupon_expires_on  => "Jan 30, 2009"
    )
    assert_no_difference "Advertiser.count" do
      assert txt_coupon_api_request.save, "Txt coupon API request should be valid"
    end
    txt_offer = txt_coupon_api_request.txt_offer
    assert_equal "My Label", txt_offer.label
    assert_equal "HOUTACO", txt_offer.keyword
    assert_equal "my message", txt_offer.message
    assert_equal Date.parse("Jan 01, 2009"), txt_offer.appears_on
    assert_equal Date.parse("Jan 30, 2009"), txt_offer.expires_on
    
    assert_not_nil txt_offer.short_code
    
    advertiser = txt_offer.advertiser.reload
    assert advertiser, "New offer should belong to an advertiser"
    assert_equal "Advertiser Two", advertiser.name, "Advertiser name should be updated"
    assert_equal [client_id, location_id], advertiser.listing_parts, "Advertiser listing should not change"
    assert advertiser.allows_clipping_only_via?("txt"), "Advertiser coupon clipping modes should be updated"
    assert_equal "http://www.advertiser-two.com/", advertiser.website_url, "Advertiser website URL should be updated"

    store = advertiser.store.reload
    assert store, "Advertiser should have a store"
    assert_equal "987 Main Street", store.address_line_1, "Store address line 1 should be updated"
    assert_equal "Unit 6", store.address_line_2, "Store address line 2 should be updated"
    assert_equal "Los Angeles", store.city, "Store city should be updated"
    assert_equal "CA", store.state, "Store state should be updated"
    assert_equal "90210", store.zip, "Store ZIP should be updated"
    assert_equal "13235551212", store.phone_number, "Store phone number should be updated"
  end

  def test_create_with_invalid_keyword_prefix_and_keyword_too_long
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    txt_coupon_api_request = publishers(:houston_press).txt_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => "12345", :advertiser_location_id => "9",
      :advertiser_coupon_clipping_modes => "",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Services: Laundry",
      :advertiser_store_address_line_1 => "987 Main Street",
      :advertiser_store_address_line_2 => "Unit 6",
      :advertiser_store_city => "Los Angeles",
      :advertiser_store_state => "CA",
      :advertiser_store_zip => "90210",
      :advertiser_store_phone_number => "323-555-1212",
      :txt_coupon_label => "My Label",
      :txt_coupon_keyword => "TACOTACOTACOTACOTACOTACO",
      :txt_coupon_message => "Buy one taco, get one free",
      :txt_coupon_appears_on => "Jan 01, 2009",
      :txt_coupon_expires_on => "Jan 30, 2009"
    })
    assert_no_difference "Advertiser.count" do
      assert !txt_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = txt_coupon_api_request.error
    assert error, "TXT coupon API request should have an error"
    assert_equal :txt_coupon_keyword, error.attr
    assert_equal "Validation errors: txt_coupon_keyword is too long (maximum is 20 characters), txt_coupon_keyword has an invalid prefix", error.text
  end

  def test_create_with_deleted_method
    publisher = publishers(:houston_press)
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :listing => "12345-9")
    
    txt_offer = advertiser.txt_offers.create!(:keyword => "HOUTACO", :message => "Free taco", :label => 666)
    assert !txt_offer.deleted, "TXT offer should not have deleted flag set"
    
    assert_no_difference "TxtOffer.count" do
      publisher.txt_coupon_api_requests.create!({
        :advertiser_client_id => "12345",
        :advertiser_location_id => "9",
        :txt_coupon_label => "666",
        :_method => "delete"
      })
    end
    assert txt_offer.reload.deleted?, "TXT offer should have deleted flag set"
  end
  
  def test_create_with_same_label_as_deleted_txt_offer
    publisher = publishers(:houston_press)
    client_id, location_id = "12345", "9"

    advertiser = publisher.advertisers.create!(
      :name => "Advertiser One",
      :listing_parts => [client_id, location_id],
      :coupon_clipping_modes => %w{ txt email },
      :website_url => "http://www.advertiser-one.com/",
      :logo => nil
    )
    advertiser.stores.create(
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Unit 4",
      :city => "Houston",
      :state => "TX",
      :zip => "77002",
      :phone_number => "713-280-2400"
    )
    deleted_txt_offer = advertiser.txt_offers.create!(:keyword => "HOU1", :message => "Deleted Message", :label => "42", :deleted => true)
    txt_coupon_api_request = publisher.txt_coupon_api_requests.build(
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt",
      :advertiser_website_url => "http://www.advertiser-two.com/",
      :advertiser_store_address_line_2 => "Unit 8",
      :advertiser_store_zip => "77003",

      :txt_coupon_label       => "42",
      :txt_coupon_message     => "New Message",
      :txt_coupon_appears_on  => "May 01, 2009",
      :txt_coupon_expires_on  => "May 30, 2009"
    )
    assert_no_difference "advertiser.txt_offers.count" do
      txt_coupon_api_request.save!
    end

    assert_not_nil txt_offer = txt_coupon_api_request.txt_offer, "TXT coupon API request should have a TXT offer"
    assert_equal deleted_txt_offer.reload.label, txt_offer.label
    assert_equal deleted_txt_offer.id, txt_offer.id

    assert_equal "HOU1", txt_offer.keyword
    assert_equal "New Message", txt_offer.message
    assert_equal Date.parse("May 01, 2009"), txt_offer.appears_on
    assert_equal Date.parse("May 30, 2009"), txt_offer.expires_on
    
    assert_not_nil txt_offer.short_code
    
    advertiser = txt_offer.advertiser.reload
    assert advertiser, "TXT offer should belong to an advertiser"
    assert_equal "Advertiser One", advertiser.name, "Advertiser name should be updated"
    assert_equal [client_id, location_id], advertiser.listing_parts, "Advertiser listing should not change"
    assert advertiser.allows_clipping_only_via?("txt"), "Advertiser coupon clipping modes should be updated"
    assert_equal "http://www.advertiser-two.com/", advertiser.website_url, "Advertiser website URL should be updated"

    store = advertiser.store.reload
    assert store, "Advertiser should have a store"
    assert_equal "123 Main Street", store.address_line_1, "Store address line 1 should be updated"
    assert_equal "Unit 8", store.address_line_2, "Store address line 2 should be updated"
    assert_equal "Houston", store.city, "Store city should be updated"
    assert_equal "TX", store.state, "Store state should be updated"
    assert_equal "77003", store.zip, "Store ZIP should be updated"
    assert_equal "17132802400", store.phone_number, "Store phone number should be updated"
  end
end
