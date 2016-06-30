require File.dirname(__FILE__) + "/../test_helper"

class StoreTest < ActiveSupport::TestCase

  should "create with valid attributes" do
    store = Factory(:store,
                    :address_line_1 => "123 Main Street",
                    :address_line_2 => "Suite 4",
                    :city => "San Diego",
                    :state => "CA",
                    :zip => "92121-1234",
                    :phone_number => "858-123-4567"
    )

    assert_not_nil store, "Should have created a store"
    assert_equal "123 Main Street", store.address_line_1
    assert_equal "Suite 4", store.address_line_2
    assert_equal "San Diego", store.city
    assert_equal "CA", store.state
    assert_equal "921211234", store.zip
    assert_equal "92121-1234", store.formatted_zip
    assert_equal "18581234567", store.phone_number
    assert_equal "(858) 123-4567", store.formatted_phone_number
  end

  context "validation" do

    should "require a valid address for paychex publisher" do
      publisher   = Factory(:publisher_using_paychex)
      assert publisher.uses_paychex?

      advertiser  = Factory(:advertiser, :publisher => publisher)
      store       = advertiser.stores.build
      assert !store.valid?, "store should not be valid"
    end

    should "require a valid address, even if just a phone number is supplied for paychex publishers" do
      publisher   = Factory(:publisher_using_paychex)
      assert publisher.uses_paychex?

      advertiser  = Factory(:advertiser, :publisher => publisher)
      store       = advertiser.stores.build(:phone_number => "123-456-8790")
      assert store.invalid?, "store should not be valid"
    end

    should "not require a valid address for non paychex publishers" do
      publisher   = Factory(:publisher)
      assert !publisher.uses_paychex?

      advertiser  = Factory(:advertiser, :publisher => publisher)
      store       = advertiser.stores.build(:phone_number => "123-456-8790")
      assert store.valid?, "store should be valid"
    end
    
  end

  def test_google_map_url_for_us_store
    store = advertisers(:di_milles).stores.create({
                                                    :address_line_1 => "123 Main Street",
                                                    :city => "San Diego",
                                                    :state => "CA",
                                                    :zip => "92173",
                                                    :country => Country::US
                                                  })
    assert_equal "http://maps.google.com/maps?li=d&hl=en&f=d&iwstate1=dir:to&daddr=123+Main+Street%2C+San+Diego%2C+CA+92173+%28foo%29",
                 store.google_map_url("foo")
  end

  def test_google_map_url_for_uk_store
    store = advertisers(:di_milles).stores.create({
                                                    :address_line_1 => "296 Farnborough Road",
                                                    :address_line_2 => "Thomson House",
                                                    :city => "Farnborough",
                                                    :region => "Hants",
                                                    :zip => "GU14 7NU",
                                                    :country => Country::UK
                                                  })
    assert_equal "http://maps.google.com/maps?li=d&hl=en&f=d&iwstate1=dir:to&daddr=296+Farnborough+Road%2C+Farnborough%2C+United+Kingdom+GU14+7NU+%28foo%29",
                 store.google_map_url("foo")
  end

  context "listing" do
    context "no listing" do
      setup do
        @store = Factory(:store)
      end
      should "be able to make a store without a listing" do
        assert @store.listing.nil?
      end
    end
    context "with a listing" do
      setup do
        @advertiser = Factory(:advertiser)
        @store = Factory(:store, :advertiser => @advertiser, :listing => "123")
      end
      should "be able to make a store with a listing" do
        assert @store.listing.present?
      end
      context "2nd store with same listing and different advertiser" do
        setup do
          @store2 = Factory.build(:store, :listing => "123")
        end
        should "be valid" do
          assert @store2.valid?
        end
      end
      context "2nd store with same listing and same advertiser" do
        setup do
          @store2 = Factory.build(:store, :advertiser => @advertiser, :listing => "123")
        end
        should "be invalid" do
          assert !@store2.valid?
        end
      end
    end
  end

  context "delegation" do
    should "delegate launched_at to the publisher" do
      launched_at = Time.parse("2012-04-25 12:34:56")
      @store = Factory(:store)
      @store.advertiser.publisher.tap do |pub|
        pub.launched_at = launched_at
        pub.save!
      end
      @store.reload
      assert_equal launched_at, @store.launched_at
    end

    should "delegate publisher to advertiser" do
      @store = Factory(:store)
      publisher = @store.advertiser.publisher
      assert_equal publisher, @store.publisher
    end

    should "delegate federal_tax_id to advertiser" do
      @store = Factory(:store)
      federal_tax_id = "12345-7890"
      @store.advertiser.update_attributes!(:federal_tax_id => federal_tax_id)
      @store.reload
      assert_equal federal_tax_id, @store.federal_tax_id
    end
  end

end
