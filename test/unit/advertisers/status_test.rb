require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::StatusTest

class Advertisers::StatusTest < ActiveSupport::TestCase
  
  context "on create" do

    setup do
      @advertiser = Factory(:advertiser)
    end

    should "have status of 'pending'" do
      assert_equal Advertisers::Status::PENDING.to_s, @advertiser.status
    end

    context "approve!" do

      setup do
        @advertiser.approve!
      end

      should "have status of 'approved'" do
        assert_equal Advertisers::Status::APPROVED.to_s, @advertiser.status
      end

    end

    context "suspend!" do

      setup do
        @advertiser.suspend!
      end

      should "have status of 'suspended'" do
        assert_equal Advertisers::Status::SUSPENDED.to_s, @advertiser.status
      end

    end    

  end

end