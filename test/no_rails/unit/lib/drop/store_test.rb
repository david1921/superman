require File.dirname(__FILE__) + "/../drop_helper"
require 'liquid/drop'

# hydra class Drop::StoreTest
module Drop
  class StoreTest < Test::Unit::TestCase
    def setup
      Drop::Store.stubs(:delegate)
    end

    context "#address_line_2_blank?" do
      setup do
        @store = mock('Store')
        @drop = Drop::Store.new(@store)
      end

      should "return true when nil" do
        @store.stubs(:address_line_2).returns(nil)
        assert @drop.address_line_2_blank?
      end

      should "return true when empty string" do
        @store.stubs(:address_line_2).returns('')
        assert @drop.address_line_2_blank?
      end

      should "return false when non-empty string" do
        @store.stubs(:address_line_2).returns('Suite 2001')
        assert !@drop.address_line_2_blank?
      end
    end
  end
end
