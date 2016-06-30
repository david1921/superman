require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::SoftDeleteTest
class Advertisers::SoftDeleteTest < ActiveSupport::TestCase
  def setup
    AppConfig.expects(:default_voice_response_code).at_most_once.returns(nil)
  end

  context "acts_as_soft_deletable" do
    setup do
      @advertiser = Factory(:advertiser)
    end

    context "with an advertiser with no dependents" do
      should "not have any offers" do
        assert @advertiser.offers.empty?
      end

      should "not have any daily_deals" do
        assert @advertiser.daily_deals.empty?
      end

      should "not have any deal certificates" do
        assert @advertiser.gift_certificates.empty?
      end

      should "not be deleted?" do
        assert !@advertiser.deleted?
      end

      context "is deleted" do
        setup do
          @advertiser.delete!
        end

        should "be deleted" do
          assert @advertiser.deleted?
        end

        should "set deleted_at" do
          assert_not_nil @advertiser.deleted_at
        end
      end
    end

    context "with an advertiser with offers" do
      setup do
        @offer = Factory(:offer, :advertiser => @advertiser)
      end

      should "not be a deleted offer" do
        assert !@offer.deleted?
      end

      should "have not deleted offers" do
        assert @advertiser.offers.not_deleted.any?
      end

      should "have no deleted offers" do
        assert @advertiser.offers.deleted.empty?
      end

      context "is deleted" do
        setup do
          @advertiser.delete!
        end

        should "delete advertiser" do
          assert @advertiser.deleted?
        end

        should "soft delete the offer" do
          assert @offer.reload.deleted?, "should have marked the offer as deleted"
        end

        should "only have deleted offers" do
          assert @advertiser.offers.not_deleted.empty?, "should no longer have active offers"
        end
      end
    end

    context "with an advertiser with daily deals" do
      setup do
        @daily_deal = Factory(:daily_deal, :advertiser => @advertiser)
      end

      should "not be a deleted ddaily_deal" do
        assert !@daily_deal.deleted?
      end

      should "have not deleted daily deal" do
        assert @advertiser.daily_deals.not_deleted.any?
      end

      should "have no deleted daily deals" do
        assert @advertiser.daily_deals.deleted.empty?
      end

      context "is deleted" do
        setup do
          @advertiser.delete!
        end

        should "delete advertiser" do
          assert @advertiser.deleted?
        end

        should "soft delete the daily deal" do
          assert @daily_deal.reload.deleted?, "should have marked the daily deal as deleted"
        end

        should "only have deleted daily deals" do
          assert @advertiser.daily_deals.not_deleted.empty?, "should no longer have active daily deals"
        end
      end
    end

    context "with an advertiser with deal certificates" do
      setup do
        @deal_certificate = Factory(:gift_certificate, :advertiser => @advertiser)
      end

      should "not be a deleted daily_deal" do
        assert !@deal_certificate.deleted?
      end

      should "have not deleted deal certificates" do
        assert @advertiser.gift_certificates.not_deleted.any?
      end

      should "have no deleted deal certificates" do
        assert @advertiser.gift_certificates.deleted.empty?
      end

      context "is deleted" do
        setup do
          @advertiser.delete!
        end

        should "delete advertiser" do
          assert @advertiser.deleted?
        end

        should "soft delete the deal certificate" do
          assert @deal_certificate.reload.deleted?, "should have marked the deal certificate as deleted"
        end

        should "only have deleted daily deals" do
          assert @advertiser.gift_certificates.not_deleted.empty?, "should no longer have active deal certificates"
        end
      end
    end
  end
end
