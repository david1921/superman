require File.dirname(__FILE__) + "/../test_helper"

class WebCouponApiRequestTest < ActiveSupport::TestCase
  def test_create_without_existing_advertiser
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build(
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2400",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    )
    assert_difference "Advertiser.count" do
      assert web_coupon_api_request.save, "Web coupon API request should be valid"
    end
    offer = web_coupon_api_request.offer
    assert offer, "Should have an associated offer after save"
    assert_equal "Free Cannoli with Regular Pasta Dinner", offer.message
    assert_equal "Free Cannoli with Regular Pasta Dinner", offer.value_proposition
    assert_equal "Must finish pasta to get Cannoli", offer.terms
    assert_equal "Free Cannoli when you finish your pasta", offer.txt_message
    assert_equal "Restaurants: Italian", offer.category_names
    assert_equal Date.parse("Jan 01, 2008"), offer.show_on
    assert_equal Date.parse("Jan 31, 2008"), offer.expires_on
    assert_equal "category", offer.featured
    
    advertiser = offer.advertiser.reload
    assert advertiser, "New offer should belong to an advertiser"
    assert_equal "Advertiser One", advertiser.name
    assert_equal [client_id, location_id], advertiser.listing_parts
    assert advertiser.allows_clipping_only_via?("txt", "email")
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
  
  def test_create_without_existing_advertiser_no_store
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build(
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    )
    assert_difference "Advertiser.count" do
      assert web_coupon_api_request.save, "Web coupon API request should be valid"
    end
    offer = web_coupon_api_request.offer
    assert offer, "Should have an associated offer after save"
    assert_equal "Free Cannoli with Regular Pasta Dinner", offer.message
    assert_equal "Free Cannoli with Regular Pasta Dinner", offer.value_proposition
    assert_equal "Must finish pasta to get Cannoli", offer.terms
    assert_equal "Free Cannoli when you finish your pasta", offer.txt_message
    assert_equal "Restaurants: Italian", offer.category_names
    assert_equal Date.parse("Jan 01, 2008"), offer.show_on
    assert_equal Date.parse("Jan 31, 2008"), offer.expires_on
    assert_equal "category", offer.featured
    
    advertiser = offer.advertiser.reload
    assert advertiser, "New offer should belong to an advertiser"
    assert_equal "Advertiser One", advertiser.name
    assert_equal [client_id, location_id], advertiser.listing_parts
    assert advertiser.allows_clipping_only_via?("txt", "email")
    assert_equal "http://www.advertiser-one.com/", advertiser.website_url

    assert_nil advertiser.store, "Should not create store"
  end
  
  def test_create_with_existing_advertiser
    publisher = publishers(:houston_press)
    client_id, location_id = "12345", "9"

    publisher.advertisers.create!(
      :name => "Advertiser One",
      :listing_parts => [client_id, location_id],
      :coupon_clipping_modes => %w{ txt email },
      :website_url => "http://www.advertiser-one.com/",
      :logo => nil).stores.create!(
        :address_line_1 => "123 Main Street",
        :address_line_2 => "Unit 4",
        :city => "Houston",
        :state => "TX",
        :zip => "77002",
        :phone_number => "713-280-2400"
    )
    web_coupon_api_request = publisher.web_coupon_api_requests.build(
      :advertiser_name => "Advertiser Two",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
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
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "0"
    )
    assert_no_difference "Advertiser.count" do
      assert web_coupon_api_request.save, "Web coupon API request should be valid"
    end
    offer = web_coupon_api_request.offer
    assert offer, "Should have an associated offer after save"
    assert_equal "Free Cannoli with Regular Pasta Dinner", offer.message
    assert_equal "Free Cannoli with Regular Pasta Dinner", offer.value_proposition
    assert_equal "Must finish pasta to get Cannoli", offer.terms
    assert_equal "Free Cannoli when you finish your pasta", offer.txt_message
    assert_equal Date.parse("Jan 01, 2008"), offer.show_on
    assert_equal Date.parse("Jan 31, 2008"), offer.expires_on
    assert_equal "Services: Laundry", offer.category_names
    assert_equal "none", offer.featured
    
    advertiser = offer.advertiser.reload
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
  
  def test_create_cannot_set_call_clipping_mode
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build(
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email,call",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2400",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    )
    assert_difference "Advertiser.count" do
      p web_coupon_api_request.error unless web_coupon_api_request.valid?
      assert web_coupon_api_request.save, "Web coupon API request should be valid"
    end
    offer = web_coupon_api_request.offer
    assert offer, "Should have an associated offer after save"
    assert_equal "Free Cannoli with Regular Pasta Dinner", offer.message
    assert_equal "Free Cannoli with Regular Pasta Dinner", offer.value_proposition
    assert_equal "Must finish pasta to get Cannoli", offer.terms
    assert_equal "Free Cannoli when you finish your pasta", offer.txt_message
    assert_equal Date.parse("Jan 01, 2008"), offer.show_on
    assert_equal Date.parse("Jan 31, 2008"), offer.expires_on
    assert_equal "Restaurants: Italian", offer.category_names
    assert_equal "42", offer.label
    
    advertiser = offer.advertiser
    assert advertiser, "New offer should belong to an advertiser"
    assert_equal "Advertiser One", advertiser.name
    assert_equal [client_id, location_id], advertiser.listing_parts
    assert advertiser.allows_clipping_only_via?("txt", "email"), "Clipping modes should not include call"
    assert_equal "http://www.advertiser-one.com/", advertiser.website_url

    store = advertiser.store
    assert store, "Advertiser should have a store"
    assert_equal "123 Main Street", store.address_line_1
    assert_equal "Unit 4", store.address_line_2
    assert_equal "Houston", store.city
    assert_equal "TX", store.state
    assert_equal "77002", store.zip
    assert_equal "17132802400", store.phone_number
  end
  
  def test_create_with_invalid_advertiser_website_url
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build(
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "httpp://",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2400",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    )
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :advertiser_website_url, error.attr
  end
  
  def test_create_with_blank_store_address_fields
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    with_blank = lambda do |attr|
      web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
        :advertiser_name => "Advertiser One",
        :advertiser_client_id => client_id, :advertiser_location_id => location_id,
        :advertiser_coupon_clipping_modes => "txt,email",
        :advertiser_website_url => "http://www.advertiser-one.com/",
        :advertiser_logo => nil,
        :advertiser_industry_codes => "Restaurants: Italian",
        :advertiser_store_address_line_1 => "123 Main Street",
        :advertiser_store_address_line_2 => "Unit 4",
        :advertiser_store_city => "Houston",
        :advertiser_store_state => "TX",
        :advertiser_store_zip => "77002",
        :advertiser_store_phone_number => "713-280-2400",
        :web_coupon_label => "42",
        :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
        :web_coupon_terms => "Must finish pasta to get Cannoli",
        :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
        :web_coupon_image => nil,
        :web_coupon_show_on => "Jan 01,  2008",
        :web_coupon_expires_on => "Jan 31, 2008",
        :web_coupon_featured => "1"
      }.merge(attr => " "))
      assert_no_difference "Advertiser.count" do
        assert !web_coupon_api_request.save, "Web coupon API request should not be valid with blank #{attr}"
      end
      error = web_coupon_api_request.error
      assert error, "Web coupon API request should have an error with blank #{attr}"
      assert_equal attr, error.attr
    end
    with_blank.call(:advertiser_store_address_line_1)
    with_blank.call(:advertiser_store_city)
    with_blank.call(:advertiser_store_state)
    with_blank.call(:advertiser_store_zip)
  end

  def test_create_with_invalid_store_state
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "Texas",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2400",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :advertiser_store_state, error.attr
  end

  def test_create_with_invalid_store_zip
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "7700",
      :advertiser_store_phone_number => "713-280-2400",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :advertiser_store_zip, error.attr
  end

  def test_create_with_invalid_store_phone_number
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-240",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :advertiser_store_phone_number, error.attr
  end

  def test_create_with_blank_store_address_and_phone_number
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "",
      :advertiser_store_address_line_2 => "",
      :advertiser_store_city => "",
      :advertiser_store_state => "",
      :advertiser_store_zip => "",
      :advertiser_store_phone_number => "",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :advertiser_store_phone_number, error.attr
  end

  def test_create_with_blank_coupon_message
    client_id, location_id = ["12345", "9"]
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2401",
      :web_coupon_label => "42",
      :web_coupon_message => " ",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :web_coupon_message, error.attr
    assert_match(/can\'t be blank/i, error.text)
  end
  
  def test_create_with_blank_coupon_txt_message
    listing = "12345"
    assert_nil Advertiser.find_by_listing(listing), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_listing => listing,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2401",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => " ",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :web_coupon_txt_message, error.attr
    assert_match(/can\'t be blank/i, error.text)
  end

  def test_create_with_blank_coupon_txt_message
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2401",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "x" * 120,
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "1"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :web_coupon_txt_message, error.attr
    assert_match(/is too long/i, error.text)
  end

  def test_create_with_out_of_order_dates
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2401",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 31,  2008",
      :web_coupon_expires_on => "Jan 01, 2008",
      :web_coupon_featured => "1"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :web_coupon_show_on, error.attr
    assert_match(/cannot be after expiration/, error.text)
  end
  
  def test_create_with_invalid_featured
    client_id, location_id = "12345", "9"
    assert_nil Advertiser.find_by_listing("12345-9"), "Advertiser should not exist"
    
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build({
      :advertiser_name => "Advertiser One",
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt,email",
      :advertiser_website_url => "http://www.advertiser-one.com/",
      :advertiser_logo => nil,
      :advertiser_industry_codes => "Restaurants: Italian",
      :advertiser_store_address_line_1 => "123 Main Street",
      :advertiser_store_address_line_2 => "Unit 4",
      :advertiser_store_city => "Houston",
      :advertiser_store_state => "TX",
      :advertiser_store_zip => "77002",
      :advertiser_store_phone_number => "713-280-2401",
      :web_coupon_label => "42",
      :web_coupon_message => "Free Cannoli with Regular Pasta Dinner",
      :web_coupon_terms => "Must finish pasta to get Cannoli",
      :web_coupon_txt_message => "Free Cannoli when you finish your pasta",
      :web_coupon_image => nil,
      :web_coupon_show_on => "Jan 01,  2008",
      :web_coupon_expires_on => "Jan 31, 2008",
      :web_coupon_featured => "4"
    })
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
    assert_equal :web_coupon_featured, error.attr
    assert_match(/is not included in the list/, error.text)
  end
  
  def test_create_with_no_parameters
    web_coupon_api_request = publishers(:houston_press).web_coupon_api_requests.build
    assert_no_difference "Advertiser.count" do
      assert !web_coupon_api_request.save, "Web coupon API request should not be valid"
    end
    error = web_coupon_api_request.error
    assert error, "Web coupon API request should have an error"
  end
  
  def test_create_with_deleted_method
    publisher = publishers(:houston_press)
    advertiser = publisher.advertisers.create!(:name => "Advertiser", :listing => "12345-9")
    offer = advertiser.offers.create!(:message => "Deleted Offer", :label => "666")
    assert !offer.deleted?, "Offer should not have deleted flag set"
    
    assert_no_difference "Offer.count" do
      publisher.web_coupon_api_requests.create!({
        :advertiser_client_id => "12345",
        :advertiser_location_id => "9",
        :web_coupon_label => "666",
        :_method => "delete"
      })
    end
    assert offer.reload.deleted?, "Offer should have deleted flag set"
  end
  
  def test_create_with_same_label_as_deleted_offer
    publisher = publishers(:houston_press)
    client_id, location_id = "12345", "9"

    advertiser = publisher.advertisers.create!(
      :name => "Advertiser One",
      :listing_parts => [client_id, location_id],
      :coupon_clipping_modes => %w{ txt email },
      :website_url => "http://www.advertiser-one.com/",
      :logo => nil)
    advertiser.stores.create!(
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Unit 4",
      :city => "Houston",
      :state => "TX",
      :zip => "77002",
      :phone_number => "713-280-2400"
    )
    deleted_offer = advertiser.offers.create!(
      :label => "42",
      :message => "Deleted Message",
      :terms => "Deleted Terms",
      :txt_message => "Deleted TXT Message",
      :category_names => "Services:Laundry",
      :deleted_at => Time.now
    )
    web_coupon_api_request = publisher.web_coupon_api_requests.build(
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "txt",
      :advertiser_website_url => "http://www.advertiser-two.com/",
      :advertiser_store_address_line_2 => "Unit 8",
      :advertiser_store_zip => "77003",
      :web_coupon_label => "42",
      :web_coupon_image => nil,
      :web_coupon_show_on => "May 01,  2008",
      :web_coupon_expires_on => "May 31, 2008",
      :web_coupon_featured => "both"
    )
    assert_no_difference "advertiser.offers.count" do
      web_coupon_api_request.save!
    end
    assert offer = web_coupon_api_request.offer, "Web coupon should have an offer"
    assert_equal deleted_offer.reload.id, offer.id
    
    assert offer, "Should have an associated offer after save"
    assert_equal "Deleted Message", offer.message
    assert_equal "Deleted Message", offer.value_proposition
    assert_equal "Deleted Terms", offer.terms
    assert_equal "Deleted TXT Message", offer.txt_message
    assert_equal Date.parse("May 01, 2008"), offer.show_on
    assert_equal Date.parse("May 31, 2008"), offer.expires_on
    assert_equal "Services: Laundry", offer.category_names
    assert_equal "both", offer.featured
    
    advertiser = offer.advertiser.reload
    assert advertiser, "New offer should belong to an advertiser"
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

  def test_update_with_txt_clipping_mode_added
    publisher = publishers(:houston_press)
    client_id, location_id = "12345", "9"

    advertiser = publisher.advertisers.create!(
      :name => "Advertiser One",
      :listing_parts => [client_id, location_id],
      :coupon_clipping_modes => %w{ email },
      :website_url => "http://www.advertiser-one.com/",
      :logo => nil
    )
    advertiser.stores.create!(
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Unit 4",
      :city => "Houston",
      :state => "TX",
      :zip => "77002",
      :phone_number => "713-280-2400"
    )
    offer = advertiser.offers.create!(
      :label => "42",
      :message => "Old Message",
      :terms => "Old Terms",
      :category_names => "Services:Laundry"
    )
    web_coupon_api_request = publisher.web_coupon_api_requests.build(
      :advertiser_client_id => client_id, :advertiser_location_id => location_id,
      :advertiser_coupon_clipping_modes => "email,txt",
      :advertiser_website_url => "http://www.advertiser-two.com/",
      :advertiser_store_address_line_2 => "Unit 8",
      :advertiser_store_zip => "77003",
      :web_coupon_label => "42",
      :web_coupon_image => nil,
      :web_coupon_show_on => "May 01,  2008",
      :web_coupon_expires_on => "May 31, 2008",
      :web_coupon_message => "New Message",
      :web_coupon_txt_message => "New TXT Message",
      :web_coupon_terms => "New Terms",
      :web_coupon_featured => "both"
    )
    assert_no_difference "advertiser.offers.count" do
      web_coupon_api_request.save!
    end
    assert offer = web_coupon_api_request.offer, "Web coupon should have an offer"
    assert_equal offer.reload.id, offer.id
    
    assert offer, "Should have an associated offer after save"
    assert_equal "New Message", offer.message
    assert_equal "New Message", offer.value_proposition
    assert_equal "New Terms", offer.terms
    assert_equal "New TXT Message", offer.txt_message
    assert_equal Date.parse("May 01, 2008"), offer.show_on
    assert_equal Date.parse("May 31, 2008"), offer.expires_on
    assert_equal "Services: Laundry", offer.category_names
    assert_equal "both", offer.featured
    
    advertiser = offer.advertiser.reload
    assert advertiser, "New offer should belong to an advertiser"
    assert_equal "Advertiser One", advertiser.name, "Advertiser name should be updated"
    assert_equal [client_id, location_id], advertiser.listing_parts, "Advertiser listing should not change"
    assert advertiser.allows_clipping_only_via?("txt", "email"), "Advertiser coupon clipping modes should be updated"
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
