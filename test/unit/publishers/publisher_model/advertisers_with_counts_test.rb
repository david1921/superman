require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::AdvertisersWithCountsTest
module Publishers
  module PublisherModel
    class AdvertisersWithCountsTest < ActiveSupport::TestCase

      test "advertisers with deal certificates counts" do
        publisher = publishers(:sdh_austin)

        a_1 = publisher.advertisers.create(:name => "A1")
        g_1_1 = a_1.gift_certificates.create!(
          :message => "A1G1",
          :value => 40.00,
          :price => 19.99,
          :show_on => "Nov 13, 2008",
          :expires_on => "Nov 17, 2008",
          :number_allocated => 10
        )
        g_1_2 = a_1.gift_certificates.create!(
          :message => "A1G2",
          :value => 20.00,
          :price => 9.99,
          :show_on => "Nov 16, 2008",
          :expires_on => "Nov 19, 2008",
          :number_allocated => 20
        )
        a_2 = publisher.advertisers.create(:name => "A2")
        g_2_1 = a_2.gift_certificates.create!(
          :message => "A2G1",
          :value => 30.00,
          :price => 14.99,
          :show_on => "Nov 18, 2008",
          :expires_on => "Nov 20, 2008",
          :number_allocated => 30
        )
        i = 10
        purchase = lambda do |gift_certificate, purchase_time, payment_status|
          i += 1
          gift_certificate.purchased_gift_certificates.create!(
            :gift_certificate => gift_certificate,
            :paypal_payment_date => purchase_time,
            :paypal_txn_id => "38D93468JC71666#{i}",
            :paypal_receipt_id => "3625-4706-3930-06#{i}",
            :paypal_invoice => "1234567#{i}",
            :paypal_payment_gross => "%.2f" % gift_certificate.price,
            :paypal_payer_email => "higgins@london.com",
            :payment_status => payment_status
          )
        end
        purchase.call(g_1_1, "00:00:00 Nov 15, 2008 PST", "completed")
        purchase.call(g_1_1, "00:00:01 Nov 15, 2008 PST", "reversed")
        purchase.call(g_1_1, "12:34:56 Nov 15, 2008 PST", "completed")
        purchase.call(g_1_1, "23:59:59 Nov 15, 2008 PST", "completed")
        purchase.call(g_1_1, "00:00:00 Nov 16, 2008 PST", "completed")
        purchase.call(g_1_1, "12:34:56 Nov 16, 2008 PST", "completed")
        purchase.call(g_1_1, "00:00:00 Nov 17, 2008 PST", "reversed")
        purchase.call(g_1_1, "23:59:59 Nov 17, 2008 PST", "completed")

        purchase.call(g_1_2, "00:00:00 Nov 16, 2008 PST", "completed")
        purchase.call(g_1_2, "00:00:01 Nov 16, 2008 PST", "reversed")
        purchase.call(g_1_2, "12:34:56 Nov 16, 2008 PST", "completed")
        purchase.call(g_1_2, "23:59:59 Nov 16, 2008 PST", "reversed")
        purchase.call(g_1_2, "00:00:00 Nov 17, 2008 PST", "completed")
        purchase.call(g_1_2, "12:34:56 Nov 17, 2008 PST", "completed")
        purchase.call(g_1_2, "00:00:00 Nov 18, 2008 PST", "completed")
        purchase.call(g_1_2, "23:59:59 Nov 18, 2008 PST", "completed")
        purchase.call(g_1_2, "00:00:00 Nov 19, 2008 PST", "refunded")
        purchase.call(g_1_2, "12:34:56 Nov 19, 2008 PST", "completed")
        purchase.call(g_1_2, "12:34:56 Nov 19, 2008 PST", "completed")
        purchase.call(g_1_2, "23:59:59 Nov 16, 2008 PST", "reversed")

        purchase.call(g_2_1, "00:00:00 Nov 18, 2008 PST", "completed")
        purchase.call(g_2_1, "00:00:01 Nov 18, 2008 PST", "reversed")
        purchase.call(g_2_1, "12:34:56 Nov 18, 2008 PST", "completed")
        purchase.call(g_2_1, "00:00:00 Nov 19, 2008 PST", "completed")
        purchase.call(g_2_1, "12:34:56 Nov 19, 2008 PST", "completed")
        purchase.call(g_2_1, "00:00:00 Nov 20, 2008 PST", "refunded")
        purchase.call(g_2_1, "23:59:59 Nov 20, 2008 PST", "completed")

        advertisers = publisher.advertisers_with_gift_certificates_counts(Date.parse("Nov 15, 2008")..Date.parse("Nov 20, 2008"))
        assert_equal 2, advertisers.size

        advertiser = advertisers.detect { |a| a.id == a_1.id }
        assert_not_nil advertiser
        assert_equal "10", advertiser.available_count_begin
        assert_equal "199.90", advertiser.available_revenue_begin
        assert_equal "14", advertiser.purchased_count
        assert_equal "199.86", advertiser.purchased_revenue
        assert_equal "0", advertiser.available_count_end
        assert_equal "0.00", advertiser.available_revenue_end

        advertiser = advertisers.detect { |a| a.id == a_2.id }
        assert_not_nil advertiser
        assert_equal "0", advertiser.available_count_begin
        assert_equal "0.00", advertiser.available_revenue_begin
        assert_equal "5", advertiser.purchased_count
        assert_equal "74.95", advertiser.purchased_revenue
        assert_equal "0", advertiser.available_count_end
        assert_equal "0.00", advertiser.available_revenue_end

        advertisers = publisher.advertisers_with_gift_certificates_counts(Date.parse("Nov 16, 2008")..Date.parse("Nov 17, 2008"))
        assert_equal 2, advertisers.size

        advertiser = advertisers.detect { |a| a.id == a_1.id }
        assert_not_nil advertiser
        assert_equal "27", advertiser.available_count_begin
        assert_equal "339.73", advertiser.available_revenue_begin
        assert_equal "7", advertiser.purchased_count
        assert_equal "99.93", advertiser.purchased_revenue
        assert_equal "16", advertiser.available_count_end
        assert_equal "159.84", advertiser.available_revenue_end

        advertiser = advertisers.detect { |a| a.id == a_2.id }
        assert_not_nil advertiser
        assert_equal "0", advertiser.available_count_begin
        assert_equal "0.00", advertiser.available_revenue_begin
        assert_equal "0", advertiser.purchased_count
        assert_equal "0.00", advertiser.purchased_revenue
        assert_equal "30", advertiser.available_count_end
        assert_equal "449.70", advertiser.available_revenue_end

        advertisers = publisher.advertisers_with_gift_certificates_counts(Date.parse("Nov 13, 2008")..Date.parse("Nov 14, 2008"))
        assert_equal 1, advertisers.size

        advertiser = advertisers.detect { |a| a.id == a_1.id }
        assert_not_nil advertiser
        assert_equal "10", advertiser.available_count_begin
        assert_equal "199.90", advertiser.available_revenue_begin
        assert_equal "0", advertiser.purchased_count
        assert_equal "0.00", advertiser.purchased_revenue
        assert_equal "10", advertiser.available_count_end
        assert_equal "199.90", advertiser.available_revenue_end
      end
    end
  end
end