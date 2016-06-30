require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::AddressValidationTest
module Publishers
  module PublisherModel
    class AddressValidationTest < ActiveSupport::TestCase
      test "change from uk to us" do
        publisher = Factory(:publisher_with_uk_address)
        attrs = {
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Suite 4",
            :city => "San Diego",
            :state => "CA",
            :zip => "92121-1234",
            :phone_number => "858-123-4567"
        }
        us = Country::US
        publisher.country = us
        publisher.update_attributes(attrs)
        assert_equal true, publisher.valid?,
                     "Should be valid since region will be reset, but had the follow errors: " +
                         publisher.errors.full_messages.join(", ")
        assert_equal nil, publisher.region
        assert_equal "123 Main Street", publisher.address_line_1
        assert_equal "Suite 4", publisher.address_line_2
        assert_equal "San Diego", publisher.city
        assert_equal "CA", publisher.state
        assert_equal "921211234", publisher.zip
        assert_equal "(858) 123-4567", publisher.formatted_phone_number
        assert_equal "18581234567", publisher.phone_number
        assert_equal us, publisher.country
      end

      test "change from us to uk" do
        publisher = Factory(:publisher_with_address)
        attrs = {
            :address_line_1 => "Thomson House",
            :address_line_2 => "296 Farnborough Road",
            :city => "Farnborough",
            :region => "Hants",
            :zip => "GU14 7NU",
            :phone_number => "01252 555 555",
        }
        uk = Country::UK
        publisher.country = Country::UK
        publisher.update_attributes(attrs)
        assert_equal true, publisher.valid?,
                     "Should be valid since state will be reset, but had the follow errors: " +
                         publisher.errors.full_messages.join(", ")
        assert_equal nil, publisher.state
        assert_equal "Thomson House", publisher.address_line_1
        assert_equal "296 Farnborough Road", publisher.address_line_2
        assert_equal "Hants", publisher.region
        assert_equal "Farnborough", publisher.city
        assert_equal "GU14 7NU", publisher.zip
        assert_equal "4401252555555", publisher.phone_number
        assert_equal uk, publisher.country
      end

      test "address normalization" do
        publisher = Factory(:publisher, {
                                         :name => "Publisher",
                                         :address_line_1 => "\r  123  Main Street  \t",
                                         :address_line_2 => "\n Suite   4  \t",
                                         :city => "\t  San    Diego  \r",
                                         :state => "\t  ca \n",
                                         :zip => "92121",
                                     })
        assert_not_nil publisher, "Should have created a publisher"

        assert_equal "123 Main Street", publisher.address_line_1
        assert_equal "Suite 4", publisher.address_line_2
        assert_equal "San Diego", publisher.city
        assert_equal "CA", publisher.state
        assert_equal "92121", publisher.zip
      end

      test "require complete us address when lacking phone" do
        attrs = {
            :name => "Publisher",
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Suite 4",
            :city => "San Diego",
            :state => "CA",
            :zip => "92121-1234"
        }
        test_missing_attributes = lambda do |attrs, keys|
          keys.each do |key|
            new_attrs = attrs.except(key)
            assert Factory.build(:publisher_without_address, new_attrs).invalid?, "Publisher should not be valid with only #{new_attrs.keys.map(&:to_s).join(',')}"
            key == :country ? value = nil : value = ""
            assert Factory.build(:publisher_without_address, new_attrs.merge(key => value)).invalid?, "Publisher should not be valid with blank #{key}"
            test_missing_attributes.call(new_attrs, keys - [key])
          end
        end
        test_missing_attributes.call(attrs, [:address_line_1, :city, :state, :zip])
      end
      
      test "require complete ca address when lacking phone" do
        attrs = {
            :name => "Publisher",
            :address_line_1 => "755 Burrard Street",
            :address_line_2 => "Suite 216",
            :city => "Vancouver",
            :region => "British Columbia",
            :zip => "V6Z 1X6",
            :country => Country::CA
        }
        test_missing_attributes = lambda do |attrs, keys|
          keys.each do |key|
            new_attrs = attrs.except(key)
            assert Factory.build(:publisher_without_address, new_attrs).invalid?, "Publisher should not be valid with only #{new_attrs.keys.map(&:to_s).join(',')}"
            key == :country ? value = nil : value = ""
            assert Factory.build(:publisher_without_address, new_attrs.merge(key => value)).invalid?, "Publisher should not be valid with blank #{key}"
            test_missing_attributes.call(new_attrs, keys - [key])
          end
        end
        test_missing_attributes.call(attrs, [:address_line_1, :city, :zip, :country])
      end
      
      test "require complete UK address when lacking phone" do
        attrs = {
            :name => "Thomsonlocal.com Directories",
            :address_line_1 => "Thomson House",
            :address_line_2 => "296 Farnborough Road",
            :city => "Farnborough",
            :region => "Hants",
            :zip => "GU14 7NU",
            :country => Country::UK
        }
        test_missing_attributes = lambda do |attrs, keys|
          keys.each do |key|
            new_attrs = attrs.except(key)
            assert Factory.build(:publisher_without_address, new_attrs).invalid?, "Publisher should not be valid with only #{new_attrs.keys.map(&:to_s).join(',')}"
            key == :country ? value = nil : value = ""
            assert Factory.build(:publisher_without_address, new_attrs.merge(key => value)).invalid?, "Publisher should not be valid with blank #{key}"
            test_missing_attributes.call(new_attrs, keys - [key])
          end
        end
        test_missing_attributes.call(attrs, [:address_line_1, :city, :country, :zip])
      end

      test "phone number validation and formatting" do
        test_phone_number = lambda do |number, valid, formatted_s|
          if valid
            publisher = Factory.build(:publisher, :name => "Publisher", :phone_number => number)
            assert publisher.valid?, "Publisher should be valid with phone number #{number}"
            assert_equal formatted_s, publisher.formatted_phone_number
          else
            assert Factory.build(:publisher, :name => "Publisher", :phone_number => number).invalid?, "Publisher should not be valid with phone number #{number}"
          end
        end
        test_phone_number.call "858 123 4567", true, "(858) 123-4567"
        test_phone_number.call "858*123!4567", true, "(858) 123-4567"
        test_phone_number.call "800-CALL-ATT", true, "800-CALL-ATT"
        test_phone_number.call "58-123-4567", false, nil
        test_phone_number.call "00-CALL-ATT", false, nil
      end

      test "support phone number validation and formatting" do
        test_support_phone_number = lambda do |number, valid, formatted_s|
          if valid
            publisher = Factory.build(:publisher, :name => "Publisher", :support_phone_number => number)
            assert publisher.valid?, "Publisher should be valid with phone number #{number}"
            assert_equal formatted_s, publisher.formatted_support_phone_number
          else
            assert Factory.build(:publisher, :name => "Publisher", :support_phone_number => number).invalid?, "Publisher should not be valid with phone number #{number}"
          end
        end
        test_support_phone_number.call "858 123 4567", true, "(858) 123-4567"
        test_support_phone_number.call "858*123!4567", true, "(858) 123-4567"
        test_support_phone_number.call "800-CALL-ATT", true, "800-CALL-ATT"
        test_support_phone_number.call "58-123-4567", false, nil
        test_support_phone_number.call "00-CALL-ATT", false, nil
      end

      test "international phone number validation and formatting" do
        uk = Country::UK
        test_phone_number = lambda do |number, valid, formatted_s|
          if valid
            publisher = Factory.build(:publisher, :name => "Publisher", :phone_number => number, :country => uk, :zip => "GU14 7NU")
            assert publisher.valid?, "Publisher should be valid with phone number #{number}, but had the following errors: " + publisher.errors.full_messages.join(", ")
            assert_equal formatted_s, publisher.formatted_phone_number
          else
            assert Factory.build(:publisher, :name => "Publisher", :phone_number => number, :country => uk).invalid?, "Publisher should not be valid with phone number #{number}"
          end
        end
        test_phone_number.call "01252 555 555", true, "01252 555 555"
        test_phone_number.call "01252555555", true, "01252 555 555"
        test_phone_number.call "01252-555!555", true, "01252 555 555"
        test_phone_number.call "0800 9 55 44 55", true, "08009 554 455"
        test_phone_number.call "858 123 4567", false, nil
        test_phone_number.call "00-CALL-ATT", false, nil
      end

      test "us zip validation" do
        attrs = {
            :name => "Publisher",
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Suite 4",
            :city => "Hicksville",
            :state => "NY"
        }
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "90036")).valid?, "Should be valid with valid ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "90036-1234")).valid?, "Should be valid with valid ZIP+4"

        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "90036 1234")).invalid?, "Should be valid with valid ZIP+4"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "9003")).invalid?, "Should not be valid with short ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "90036-123")).invalid?, "Should not be valid with short ZIP+4"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "90036+1234")).invalid?, "Should not be valid with bad ZIP char"
      end

      test "ca zip validation" do
        attrs = {
            :name => "Publisher",
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Suite 4",
            :city => "Vancouver",
            :state => "BC",
            :phone_number => "604-123-4567",
            :country => Country::CA
        }
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "G3M 5T9")).valid?, "Should be valid with valid ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "C3M5T9")).valid?, "Should be valid with valid ZIP"

        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "G3M 5T!")).invalid?, "Should be INVALID with invalid ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "G@M5T9")).invalid?, "Should be INVALID with invalid ZIP"
      end

      test "uk zip validation" do
        attrs = {
            :name => "Publisher",
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Suite 4",
            :city => "London",
            :country => Country::UK
        }
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "M2 5BQ")).valid?, "Should be valid with valid ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "EC1A 1HQ")).valid?, "Should be valid with valid ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "GIR 0AA")).valid?, "Should be valid with valid ZIP"

        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "GIR0AA")).invalid?, "Should be INVALID with invalid ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "M2 BQ5")).invalid?, "Should be INVALID with invalid ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "E31A 1HQ")).invalid?, "Should be INVALID with invalid ZIP"
        assert Factory.build(:publisher_without_address, attrs.merge(:zip => "G$R 0AA")).invalid?, "Should be INVALID with invalid ZIP"
      end

      test "us state validation" do
        advertiser = advertisers(:di_milles)
        attrs = {
            :name => "Publisher",
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Suite 4",
            :city => "Hicksville",
            :zip => "11801",
        }
        assert Factory.build(:publisher_without_address, attrs.merge(:state => "NY")).valid?, "Should be valid with a known state code"
        assert Factory.build(:publisher_without_address, attrs.merge(:state => "XY")).invalid?, "Should not be valid with unknown state code"
      end

      test "ca state validation" do
        advertiser = advertisers(:di_milles)
        attrs = {
            :name => "Publisher",
            :address_line_1 => "123 Main Street",
            :address_line_2 => "Suite 4",
            :city => "Vancouver",
            :zip => "V6E 1N2",
            :country => Country::CA
        }
        assert Factory.build(:publisher_without_address, attrs.merge(:state => "BC")).valid?, "Should be valid with a known state code"
        assert Factory.build(:publisher_without_address, attrs.merge(:state => "XY")).invalid?, "Should not be valid with unknown state code"
      end

      test "publisher has zip and zip_code" do
        publisher = Factory(:publisher_with_address, :zip => "97214")
        assert_equal "97214", publisher.zip
        assert_equal "97214", publisher.zip_code
        publisher.zip = "97215"
        assert_equal "97215", publisher.zip
        assert_equal "97215", publisher.zip_code
        publisher.zip_code = "97216"
        assert_equal "97216", publisher.zip
        assert_equal "97216", publisher.zip_code
      end

      test "validates us zip" do
        publisher = Factory(:publisher_with_address, :zip => "97214")
        assert publisher.valid?
        publisher.zip = "12"
        assert !publisher.valid?
      end
    end
  end
end
