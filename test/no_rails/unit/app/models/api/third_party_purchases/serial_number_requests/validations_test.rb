require File.dirname(__FILE__) + "/../../../../models_helper"

# hydra class Api::ThirdPartyPurchases::SerialNumberRequests::ValidationsTest

module Api::ThirdPartyPurchases::SerialNumberRequests
  class ValidationsTest < Test::Unit::TestCase
    def setup
      @obj = Object.new.extend(Validations)
    end

    context "#validate_xml" do
      setup do
        @doc = mock('xml document')
        @obj.instance_variable_set(:@doc, @doc)
      end

      should "validate the root, uuid and purchase elements" do
        @obj.expects(:validate_xml_root).with(@doc)
        @obj.expects(:validate_xml_uuid).with(@doc)
        @obj.expects(:validate_xml_purchase_elements).with(@doc)
        @obj.validate_xml
      end
    end

    context "#validate_daily_deal_listing" do
      should "not set @daily_deal if invalid xml" do
        @obj.stubs(:valid_xml?).returns(false)

        @obj.validate_daily_deal_listing

        assert_nil @obj.instance_variable_get(:@daily_deal)
      end

      context "with valid xml and present listing" do
        setup do
          @obj.stubs(:valid_xml?).returns(true)
          @deal = mock('deal')
          @obj.stubs(:xml_data).returns({:daily_deal_listing => 'listing'})
          @errors = mock('errors')
          @obj.stubs(:errors).returns(@errors)
        end

        should "set @daily_deal to deal with matching listing" do
          @obj.stubs(:find_daily_deal_by_listing).returns(@deal)
          @errors.expects(:add).never
          @obj.validate_daily_deal_listing
          assert_equal @deal, @obj.instance_variable_get(:@daily_deal)
        end

        should "add an error if the deal is unknown" do
          @obj.stubs(:find_daily_deal_by_listing).returns(nil)
          @errors.expects(:add).with(:daily_deal_listing, "unknown daily deal listing")
          @obj.validate_daily_deal_listing
          assert_nil @obj.instance_variable_get(:@daily_deal)
        end
      end
    end

    context "#validate_store(node)" do
      should "not set @store if invalid xml" do
        @obj.stubs(:valid_xml?).returns(false)

        @obj.validate_store

        assert_nil @obj.instance_variable_get(:@store)
      end

      should "not find store unless listing" do
        @obj.stubs(:valid_xml?).returns(true)
        @obj.stubs(:xml_data).returns({})
        @obj.expects(:find_store_by_listing).never

        @obj.validate_store

        assert_nil @obj.instance_variable_get(:@store)
      end

      should "set @store to store with matching listing" do
        @obj.stubs(:valid_xml?).returns(true)
        @obj.stubs(:xml_data).returns({:location_listing => '2345'})
        store = mock('store')
        @obj.stubs(:find_store_by_listing).returns(store)

        @obj.validate_store

        assert_equal store, @obj.instance_variable_get(:@store)
      end

      should "add an error if the store is unknown" do
        @obj.stubs(:valid_xml?).returns(true)
        @obj.stubs(:xml_data).returns({:location_listing => '1234'})
        @obj.stubs(:find_store_by_listing).returns(nil)
        errors = mock('errors')
        @obj.stubs(:errors).returns(errors)
        errors.expects(:add).with(:location_listing, "unknown location")

        @obj.validate_store
      end
    end

    context "#validate_deal_availability" do
      should "add an error if the insufficient qty remains" do
        @obj.stubs(:insufficient_deal_qty?).returns(true)
        errors = mock('errors')
        @obj.stubs(:errors).returns(errors)
        errors.expects(:add).with(:availability, "%{attribute} is of an insufficient quantity")

        @obj.validate_deal_availability
      end
    end

    context "#validate_executed_at" do
      should "to accept iso8601 dates" do
        @obj.stubs(:valid_xml?).returns(true)
        @obj.stubs(:xml_data).returns({:executed_at => "2011-12-13T22:01:44-0600"})
        errors = mock('errors')
        @obj.stubs(:errors).returns(errors)
        errors.expects(:add).never

        @obj.validate_executed_at
      end
    end
  end
end
