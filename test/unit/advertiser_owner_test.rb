require File.dirname(__FILE__) + "/../test_helper"

class AdvertiserOwnerTest < ActiveSupport::TestCase
  context 'belongs_to advertiser' do
    setup do
      @advertiser_owner = Factory(:advertiser_owner, :advertiser => nil)
    end

    should 'not belong to an advertiser' do
      assert_equal nil, @advertiser_owner.advertiser, 'should not have an advertiser'
    end

    should 'belong to an advertiser' do
      @advertiser_owner.advertiser = Factory(:advertiser)
      assert_not_nil @advertiser_owner.advertiser
    end
  end
end
