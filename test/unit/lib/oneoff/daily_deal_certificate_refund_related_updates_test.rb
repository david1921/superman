require File.dirname(__FILE__) + "/../../../test_helper"
require File.expand_path("lib/oneoff/tasks/daily_deal_certificate_refund_related_updates", RAILS_ROOT)

class DailyDealCertificateRefundRelatedUpdatesTest < ActiveSupport::TestCase

  include DailyDealCertificateRefundRelatedUpdates

  context "Refund" do
    should "have the methods included from the module" do
      assert respond_to?(:full_refund?)
      assert respond_to?(:update_status_and_refund_as_appropriate)
      assert respond_to?(:update_status_to_redeemed_for_redeemed_certs)
    end
  end

  context "full_refund?" do
    context "bogus refund amounts" do
      should "return false" do
        assert !full_refund?(0, nil)
        assert !full_refund?(30, 29)
        assert !full_refund?(30, 15)
        assert !full_refund?(15, 0)
      end
    end
    context "full refund amounts" do
      context "one cert" do
        should "return true as long as actual purchase price <= refund amount " do
          assert full_refund?(15, 15)
          assert full_refund?(400, 400)
          assert full_refund?(1, 1)
          assert full_refund?(15, 30)
          assert full_refund?(0, 0)
        end
      end
    end
    context "partial refund amounts" do
       should "not update any certs in the case of a partial refund" do
         assert !full_refund?(14, 7)
         assert !full_refund?(14, 13)
       end
    end
  end

  context "marking certs redeemed" do
    setup do
      DailyDealCertificate.destroy_all
      10.times do |i|
        cert = Factory(:daily_deal_certificate)
        if i % 2 == 0
          cert.update_attribute(:redeemed_at, Time.now)
        end
      end
    end
    should "be proper setup" do
      assert_equal 5, DailyDealCertificate.count(:redeemed_at)
      assert_equal 0, DailyDealCertificate.count(:conditions => ["status = 'redeemed'"])
    end
    should "update statuses of redeemed certs" do
      update_status_to_redeemed_for_redeemed_certs
      assert_equal 5, DailyDealCertificate.count(:redeemed_at)

      assert_equal 5, DailyDealCertificate.count(:conditions => ["status = 'redeemed'"])
      DailyDealCertificate.all.each do |cert|
        if cert.redeemed_at.nil?
          assert cert.status != 'redeeemed'
        else
          assert_equal 'redeemed', cert.status
        end
      end
    end
    context "status and redeemed at are set" do
      setup do
        DailyDealCertificate.update_all("status = 'voided'")
      end
      should "not update status if not active" do
        update_status_to_redeemed_for_redeemed_certs
        assert_equal 0, DailyDealCertificate.count(:conditions => ["status = 'redeemed'"])
      end
    end
  end

end