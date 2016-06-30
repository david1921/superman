require File.dirname(__FILE__) + "/../test_helper"

# hydra class Markets::ZipCodeTest
module Markets
  class ZipCodeTest < ActiveSupport::TestCase
    
    context "validation" do
      setup do
        @mzc = Factory(:market_zip_code)
      end

      should "be valid" do
        assert @mzc.valid?
      end

      should "have a valid market" do
        assert_not_nil @mzc.market
        assert @mzc.market.valid?
      end

      should "require zip code" do
        @mzc.zip_code = nil
        assert ! @mzc.valid?
        assert_equal "Zip code can't be blank", @mzc.errors[:zip_code]
      end

      should "require a unique zip code for this market" do
        new_mzc = Factory.build :market_zip_code, :market => @mzc.market, :zip_code => @mzc.zip_code
        assert ! new_mzc.valid?
        assert_equal "Zip code has already been taken", new_mzc.errors[:zip_code]
      end

      should "have a valid publisher" do
        assert_not_nil @mzc.publisher
        assert @mzc.publisher.valid?
      end

      should "not allow same zip code under same publisher" do
        market = Factory :market, :publisher => @mzc.publisher
        new_mzc = Factory.build :market_zip_code, :market => market, :zip_code => @mzc.zip_code
        assert !new_mzc.valid?
        assert_equal 'market zip code can only belong to one publisher', new_mzc.errors[:base]
      end

      should "require state code" do
        new_mzc = Factory.build(:market_zip_code, :market => @mzc.market, :state_code => nil)
        assert !new_mzc.valid?
        assert_equal "State code is invalid", new_mzc.errors[:state_code]
      end

      should "require a valid state code" do
        new_mzc = Factory.build(:market_zip_code, :market => @mzc.market, :state_code => "DU")
        assert !new_mzc.valid?
        assert_equal "State code is invalid", new_mzc.errors[:state_code]
      end
    end
  end
end
