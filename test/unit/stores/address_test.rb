require File.dirname(__FILE__) + "/../../test_helper"

class AddressTest < ActiveSupport::TestCase

  def test_create_ca_store
    ca = Country::CA
    advertiser = advertisers(:di_milles)
    store = advertiser.stores.build({
                                      :address_line_1 => "123 Main Street",
                                      :address_line_2 => "Suite 4",
                                      :city => "Vancouver",
                                      :state => "BC",
                                      :zip => "V6E 1N2",
                                      :phone_number => "604-123-4567",
                                      :country => ca
                                    })
    assert_equal true, advertiser.valid?, "Should be valid a advertiser, but had errors: " + advertiser.errors.full_messages.join(", ")
    advertiser.save!
    assert_not_nil store, "Should have created a store"

    assert_equal "123 Main Street", store.address_line_1
    assert_equal "Suite 4", store.address_line_2
    assert_equal "Vancouver", store.city
    assert_equal "BC", store.state
    assert_equal ca, store.country
    assert_equal "V6E1N2", store.zip
    assert_equal "V6E 1N2", store.formatted_zip
    assert_equal "16041234567", store.phone_number
  end

  def test_create_uk_store
    uk = Country::UK
    advertiser = advertisers(:di_milles)
    store = advertiser.stores.build({
                                      :address_line_1 => "Thomson House",
                                      :address_line_2 => "296 Farnborough Road",
                                      :city => "Farnborough",
                                      :region => "Hants",
                                      :zip => "GU14 7NU",
                                      :phone_number => "01252 555 555",
                                      :country => uk
                                    })
    assert_equal true, advertiser.valid?, "Should be valid a advertiser, but had errors: " + advertiser.errors.full_messages.join(", ")
    advertiser.save!
    assert_not_nil store, "Should have created a store"

    assert_equal "Thomson House", store.address_line_1
    assert_equal "296 Farnborough Road", store.address_line_2
    assert_equal "Farnborough", store.city
    assert_equal "Hants", store.region
    assert_equal nil, store.state
    assert_equal "GU14 7NU", store.zip
    assert_equal "GU14 7NU", store.formatted_zip
    assert_equal "4401252555555", store.phone_number
    assert_equal uk, store.country
  end

  def test_create_store_no_postal_code_regex
    fb = Factory(:country, :name => "Foobar", :code => "fb", :postal_code_regex => nil)
    store = Factory.build(:store, :country => fb)
    store.address_line_1 = "3440 SE Sherman St"
    store.city = "Portland"
    store.state = "OR"
    store.zip = "anything goes because there is no postal code regex"
    assert store.valid?, "Store should be valid, but had errors: " + store.errors.full_messages.join(", ")
  end

  def test_create_with_invalid_country
    country = Country.new(:code => "F", :name => "Foo")
    store = advertisers(:di_milles).stores.create({
                                                    :address_line_1 => "123 Main Street",
                                                    :address_line_2 => "Suite 4",
                                                    :city => "San Diego",
                                                    :state => "CA",
                                                    :zip => "92121-1234",
                                                    :phone_number => "858-123-4567",
                                                    :country => country
                                                  })
    assert_equal false, store.valid?, "Should NOT be valid a publisher"
    assert_equal "Country does not exist",
                 store.errors.on(:country), "Should have error message for country"
  end

  def test_address_normalization
    store = advertisers(:di_milles).stores.create({
                                                    :address_line_1 => "\r  123  Main Street  \t",
                                                    :address_line_2 => "\n Suite   4  \t",
                                                    :city => "\t  San    Diego  \r",
                                                    :state => "\t  ca \n",
                                                    :zip => "92121",
                                                  })
    assert_not_nil store, "Should have created a store"

    assert_equal "123 Main Street", store.address_line_1
    assert_equal "Suite 4", store.address_line_2
    assert_equal "San Diego", store.city
    assert_equal "CA", store.state
    assert_equal "92121", store.zip
    assert_equal -121.56724, store.longitude
    assert_equal 45.538069,  store.latitude
  end

  def test_require_complete_us_address_when_lacking_phone
    advertiser = advertisers(:di_milles)
    attrs = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Hicksville",
      :state => "NY",
      :zip => "11801",
      :country => Country::US
    }
    test_missing_attributes = lambda do |atts, keys|
      keys.each do |key|
        new_atts = atts.except(key)
        assert advertiser.stores.build(new_atts).invalid?, "Store should not be valid with only #{new_atts.keys.map(&:to_s).join(',')}"
        key == :country ? value = nil : value = ""
        assert advertiser.stores.build(new_atts.merge(key => value)).invalid?, "Store should not be valid with blank #{key}"
        test_missing_attributes.call(new_atts, keys - [key])
      end
    end
    test_missing_attributes.call(attrs, [:address_line_1, :city, :state, :zip])
  end

  def test_require_complete_ca_address_when_lacking_phone
    advertiser = advertisers(:di_milles)
    attrs = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Vancouver",
      :state => "BC",
      :zip => "V6E 1N2",
      :country => Country::CA
    }
    test_missing_attributes = lambda do |atts, keys|
      keys.each do |key|
        new_atts = atts.except(key)
        assert advertiser.stores.create(new_atts).invalid?, "Store should not be valid with only #{new_atts.keys.map(&:to_s).join(',')}"
        key == :country ? value = nil : value = ""
        assert advertiser.stores.create(new_atts.merge(key => value)).invalid?, "Store should not be valid with blank #{key}"
        test_missing_attributes.call(new_atts, keys - [key])
      end
    end
    test_missing_attributes.call(attrs, [:address_line_1, :city, :state, :zip, :country])
  end

  def test_require_complete_uk_address_when_lacking_phone
    advertiser = advertisers(:di_milles)
    attrs = {
      :address_line_1 => "Thomson House",
      :address_line_2 => "296 Farnborough Road",
      :city => "Farnborough",
      :region => "Hants",
      :zip => "GU14 7NU",
      :country => Country::UK
    }
    test_missing_attributes = lambda do |atts, keys|
      keys.each do |key|
        new_atts = atts.except(key)
        assert advertiser.stores.create(new_atts).invalid?, "Store should not be valid with only #{new_atts.keys.map(&:to_s).join(',')}"
        key == :country ? value = nil : value = ""
        assert advertiser.stores.create(new_atts.merge(key => value)).invalid?, "Store should not be valid with blank #{key}"
        test_missing_attributes.call(new_atts, keys - [key])
      end
    end
    test_missing_attributes.call(attrs, [:address_line_1, :city, :zip, :country])
  end


  def test_us_zip_validation
    advertiser = advertisers(:di_milles)
    attrs = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Hicksville",
      :state => "NY",
      :country => Country::US
    }
    assert  advertiser.stores.create(attrs.merge(:zip => "90036")).valid?, "Should be valid with valid ZIP"
    assert  advertiser.stores.create(attrs.merge(:zip => "90036-1234")).valid?, "Should be valid with valid ZIP+4"

    assert advertiser.stores.create(attrs.merge(:zip => "90036 1234")).invalid?, "Should be valid with valid ZIP+4"
    assert advertiser.stores.create(attrs.merge(:zip => "9003")).invalid?, "Should not be valid with short ZIP"
    assert advertiser.stores.create(attrs.merge(:zip => "90036-123")).invalid?, "Should not be valid with short ZIP+4"
    assert advertiser.stores.create(attrs.merge(:zip => "90036+1234")).invalid?, "Should not be valid with bad ZIP char"
  end

  def test_ca_zip_validation
    advertiser = advertisers(:di_milles)
    attrs = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Vancouver",
      :state => "BC",
      :country => Country::CA
    }
    assert  advertiser.stores.create(attrs.merge(:zip => "G3M 5T9")).valid?, "Should be valid with valid ZIP"
    assert  advertiser.stores.create(attrs.merge(:zip => "C3M5T9")).valid?, "Should be valid with valid ZIP"

    assert advertiser.stores.create(attrs.merge(:zip => "G3M 5T!")).invalid?, "Should not be valid with invalid ZIP"
    assert advertiser.stores.create(attrs.merge(:zip => "G@M5T9")).invalid?, "Should not be valid with invalid ZIP"
  end

  def test_uk_zip_validation
    advertiser = advertisers(:di_milles)
    attrs = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Hicksville",
      :state => "NY",
      :country => Country::UK
    }
    assert  advertiser.stores.create(attrs.merge(:zip => "M2 5BQ")).valid?, "Should be valid with valid ZIP"
    assert  advertiser.stores.create(attrs.merge(:zip => "EC1A 1HQ")).valid?, "Should be valid with valid ZIP"
    assert  advertiser.stores.create(attrs.merge(:zip => "GIR 0AA")).valid?, "Should be valid with valid ZIP"

    assert  advertiser.stores.create(attrs.merge(:zip => "GIR0AA")).invalid?, "Should be INVALID with invalid ZIP"
    assert  advertiser.stores.create(attrs.merge(:zip => "M2 BQ5")).invalid?, "Should be INVALID with invalid ZIP"
    assert  advertiser.stores.create(attrs.merge(:zip => "E31A 1HQ")).invalid?, "Should be INVALID with invalid ZIP"
    assert  advertiser.stores.create(attrs.merge(:zip => "G$R 0AA")).invalid?, "Should be INVALID with invalid ZIP"
  end

  def test_us_state_validation
    advertiser = advertisers(:di_milles)
    attrs = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Hicksville",
      :zip => "11801",
    }
    assert advertiser.stores.create(attrs.merge(:state => "NY")).valid?, "Should be valid with a known state code"
    assert advertiser.stores.create(attrs.merge(:state => "XY")).invalid?, "Should not be valid with unknown state code"
  end

  def test_ca_state_validation
    advertiser = advertisers(:di_milles)
    attrs = {
      :address_line_1 => "123 Main Street",
      :address_line_2 => "Suite 4",
      :city => "Vancouver",
      :zip => "V6E 1N2",
      :country => Country::CA
    }
    assert advertiser.stores.create(attrs.merge(:state => "BC")).valid?, "Should be valid with a known state code"
    assert advertiser.stores.create(attrs.merge(:state => "XY")).invalid?, "Should not be valid with unknown state code"
  end

  def test_not_valid_after_changing_advertiser
    store = advertisers(:di_milles).stores.create(:phone_number => "858-882-8100")
    assert_not_nil store, "Should create a store"
    store.advertiser = advertisers(:burger_king)
    assert !store.valid?, "Should not be valid after assigning a new advertiser"
  end

  def test_address_query
    store = advertisers(:burger_king).stores.create

    store.address_line_1 = "1204 SE Pershing St."
    assert store.address?, "Address with address line 1"

    store.address_line_1 = nil
    store.city = "Portland"
    assert store.address?, "Address with city"

    store.city = nil
    store.state = "OR"
    assert store.address?, "Address with state"

    store.state = nil
    store.zip = "97202"
    assert store.address?, "Address with ZIP"
  end

  def test_us_address_mappable
    us = Country::US
    store = advertisers(:burger_king).stores.create
    store.country = us

    store.address_line_1 = "1204 SE Pershing St."
    assert !store.address_mappable?, "Address with address line 1"

    store.address_line_1 = nil
    store.city = "Portland"
    assert !store.address_mappable?, "Address with city"

    store.city = nil
    store.state = "OR"
    assert !store.address_mappable?, "Address with state"

    store.state = nil
    store.zip = "97202"
    assert !store.address_mappable?, "Address with ZIP"

    store.address_line_1 = "1204 SE Pershing St."
    store.city = "Portland"
    assert !store.address_mappable?, "Address with street, city"

    store.state = "OR"
    assert store.address_mappable?, "Address with street, city, state"

    store.zip = "97202"
    assert store.address_mappable?, "Address with street, city, state, ZIP"
  end

  def test_uk_address_mappable
    uk = Country::UK
    store = advertisers(:burger_king).stores.create

    store.address_line_1 = "Thomson House"
    assert !store.address_mappable?, "Address with address line 1"

    store.address_line_1 = nil
    store.city = "Farnborough"
    assert !store.address_mappable?, "Address with city"

    store.city = nil
    store.country = uk
    assert !store.address_mappable?, "Address with country"

    store.city = nil
    store.zip = "GU14 7NU"
    assert !store.address_mappable?, "Address with ZIP"

    store.address_line_1 = "296 Farnborough Road"
    store.city = "Farnborough"
    store.country = nil
    assert !store.address_mappable?, "Address with street, city"

    store.country = uk
    assert store.address_mappable?, "Address with street, city, country"

    store.zip = "GU14 7NU"
    assert store.address_mappable?, "Address with street, city, country, ZIP"
  end

  def test_us_address
    store = advertisers(:di_milles).stores.create({
                                                    :address_line_1 => "123 Main Street",
                                                    :city => "San Diego",
                                                    :state => "CA",
                                                    :zip => "92121",
                                                    :phone_number => "858-123-4567"
                                                  })
    assert_not_nil store, "Should have created a store"
    lines = returning([]) { |array| store.address { |line| array << line }}
    assert_equal ["123 Main Street", "San Diego, CA 92121"], lines, "Store address"
    assert_equal ["123 Main Street", "San Diego, CA 92121"], store.address, "Store address"

    store.update_attributes! :address_line_2 => "Suite 4", :zip => "92121-1234"
    lines = returning([]) { |array| store.address { |line| array << line }}
    assert_equal ["123 Main Street, Suite 4", "San Diego, CA 92121-1234"], lines, "Store address"
    assert_equal ["123 Main Street, Suite 4", "San Diego, CA 92121-1234"], store.address, "Store address"
  end

  def test_uk_address
    store = advertisers(:di_milles).stores.create({
                                                    :address_line_1 => "296 Farnborough Road",
                                                    :city => "Farnborough",
                                                    :zip => "GU14 7NU",
                                                    :country => Country::UK
                                                  })
    assert_not_nil store, "Should have created a store"
    lines = returning([]) { |array| store.address { |line| array << line }}
    assert_equal [
                   "296 Farnborough Road",
                   "Farnborough",
                   "GU14 7NU",
                   "United Kingdom"], lines, "Store address"
    assert_equal [
                   "296 Farnborough Road",
                   "Farnborough",
                   "GU14 7NU",
                   "United Kingdom"], store.address, "Store address"

    store.update_attributes! :address_line_1 => "Thomson House", :address_line_2 => "296 Farnborough Road", :region => "Hants"
    lines = returning([]) { |array| store.address { |line| array << line }}
    assert_equal [
                   "Thomson House",
                   "296 Farnborough Road",
                   "Farnborough",
                   "Hants",
                   "GU14 7NU",
                   "United Kingdom"], lines, "Store address"
    assert_equal   [
                     "Thomson House",
                     "296 Farnborough Road",
                     "Farnborough",
                     "Hants",
                     "GU14 7NU",
                     "United Kingdom"], store.address, "Store address"
  end

  def test_us_address_with_all_fields_blank
    store = advertisers(:di_milles).stores.create({
                                                    :address_line_1 => "",
                                                    :address_line_2 => "",
                                                    :city => "",
                                                    :state => "",
                                                    :zip => "",
                                                    :phone_number => "858-123-4567"
                                                  })
    assert_not_nil store, "Should have created a store"
    lines = returning([]) { |array| store.address { |line| array << line }}
    assert lines.empty?, "Store with blank address"
    assert store.address.empty?, "Store with blank address"
  end

  def test_uk_address_with_all_fields_blank
    store = advertisers(:di_milles).stores.create({
                                                    :address_line_1 => "",
                                                    :address_line_2 => "",
                                                    :city => "",
                                                    :state => "",
                                                    :zip => "",
                                                    :phone_number => "01252 555 555",
                                                    :country => Country::UK
                                                  })
    assert_not_nil store, "Should have created a store"
    lines = returning([]) { |array| store.address { |line| array << line }}
    assert lines.empty?, "Store with blank address"
    assert store.address.empty?, "Store with blank address"
  end

  def test_us_summary
    store = Store.new
    assert_equal "New Store", store.summary

    store = Store.new(:phone_number => "313 777-1919")
    assert_equal "(313) 777-1919", store.summary

    store = Store.new(
      :address_line_1 => "123 Main Street",
      :state => "CA",
      :zip => "92121"
    )
    assert_equal "123 Main Street, CA", store.summary

    store.city = "San Diego"
    assert_equal "123 Main Street, San Diego, CA", store.summary

    store.phone_number = "411"
    assert_equal "123 Main Street, San Diego, CA", store.summary
  end

  def test_uk_summary
    store = Store.new
    assert_equal "New Store", store.summary

    store = Store.new(:phone_number => "01252 555 555", :country => Country::UK)
    assert_equal "01252 555 555", store.summary

    store = Store.new(
      :address_line_1 => "296 Farnborough Road",
      :country => Country::UK,
      :zip => "GU14 7NU"
    )
    assert_equal "296 Farnborough Road, UK", store.summary

    store.city = "Farnborough"
    assert_equal "296 Farnborough Road, Farnborough, UK", store.summary

    store.phone_number = "411"
    assert_equal "296 Farnborough Road, Farnborough, UK", store.summary
  end

  test "store has zip and zip_code" do
    store = Factory(:store_with_address, :zip => "97214")
    assert_equal "97214", store.zip
    assert_equal "97214", store.zip_code
    store.zip = "97215"
    assert_equal "97215", store.zip
    assert_equal "97215", store.zip_code
    store.zip_code = "97216"
    assert_equal "97216", store.zip
    assert_equal "97216", store.zip_code
  end

  def test_country_not_in_publishers_countries
    advertiser = advertisers(:di_milles)
    publisher = advertiser.publisher
    publisher.countries = [ Country::US, Country::CA ]
    store = advertiser.stores.build({
                                      :address_line_1 => "296 Farnborough Road",
                                      :city => "Farnborough",
                                      :zip => "GU14 7NU",
                                      :country => Country::UK
                                    })
    assert_equal true, store.invalid?, "Should NOT be valid a publisher"
    assert_equal "Country is not in the list of allowed countries for this publisher", store.errors.on(:country), "Should have error message for country"
  end

  context "postal_code_regex" do
    should "return us if there is no country code passed in" do
      assert_equal Country.postal_code_regex("US"), Store.postal_code_regex(nil)
    end
  end
end
