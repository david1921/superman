require File.dirname(__FILE__) + "/../../test_helper"

class PhoneTest < ActiveSupport::TestCase
  
  def test_require_phone_when_lacking_address
    advertiser = advertisers(:di_milles)
    assert !advertiser.stores.create.valid?, "Store lacking address and phone should not be valid"
  end

  def test_phone_number_validation_and_formatting
    advertiser = advertisers(:di_milles)
    test_phone_number = lambda do |number, valid, formatted_s|
      if valid
        store = advertiser.stores.create(:phone_number => number, :country => Country::US)
        assert store.valid?, "Store should be valid with phone number #{number}"
        assert_equal formatted_s, store.formatted_phone_number
      else
        assert !advertiser.stores.create(:phone_number => number, :country => Country::US).valid?, "Store should not be valid with phone number #{number}"
      end
    end
    test_phone_number.call "858 123 4567", true, "(858) 123-4567"
    test_phone_number.call "858*123!4567", true, "(858) 123-4567"
    test_phone_number.call "800-CALL-ATT", true, "800-CALL-ATT"
    test_phone_number.call "58-123-4567", false, nil
    test_phone_number.call "00-CALL-ATT", false, nil
  end

  def test_international_phone_number_validation_and_formatting
    advertiser = advertisers(:di_milles)
    test_phone_number = lambda do |number, valid, formatted_s|
      if valid
        store = advertiser.stores.create(:phone_number => number, :country => Country::UK)
        assert store.valid?, "Store should be valid with phone number #{number}"
        assert_equal formatted_s, store.formatted_phone_number
      else
        assert !advertiser.stores.create(:phone_number => number, :country => Country::UK).valid?, "Store should not be valid with phone number #{number}"
      end
    end
    test_phone_number.call "01252 555 555", true, "01252 555 555"
    test_phone_number.call "01252555555", true, "01252 555 555"
    test_phone_number.call "01252-555!555", true, "01252 555 555"
    test_phone_number.call "0800 9 55 44 55", true, "08009 554 455"
    test_phone_number.call "858 123 4567", false, nil
    test_phone_number.call "00-CALL-ATT", false, nil
  end

end
