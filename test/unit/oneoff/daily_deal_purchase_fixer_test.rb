require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Oneoff::DailyDealPurchaseFixerTest

module Oneoff

  class DailyDealPurchaseFixerTest < ActiveSupport::TestCase

    context "A DailyDealPurchaseFixer instance" do

      setup do
        @purchase_fixer = DailyDealPurchaseFixer.new
      end

      context ".generate_broken_purchases_and_vouchers_report!" do

        should "raise an ArgumentError if PURCHASE_IDS_FILE and OUTFILE env vars are not set" do
          File.stubs(:open).returns(StringIO.new)
          begin
            e = assert_raises(ArgumentError) { @purchase_fixer.generate_broken_purchases_and_vouchers_report! }
            assert_equal "missing required argument PURCHASE_IDS_FILE", e.message
            ENV["PURCHASE_IDS_FILE"] = "/some/fake/file"

            e = assert_raises(ArgumentError) { @purchase_fixer.generate_broken_purchases_and_vouchers_report! }
            assert_equal "missing required argument OUTFILE", e.message
            ENV["OUTFILE"] = "/some/other/fake/file"

            assert_nothing_raised { @purchase_fixer.generate_broken_purchases_and_vouchers_report! }
          ensure
            ENV["PURCHASE_IDS_FILE"] = ENV["OUTFILE"] = nil
          end
        end

        should "write out some data to the file named by OUTFILE about the purchases referred to in the PURCHASE_IDS_FILE" do
          captured_no_certs = Factory :captured_daily_deal_purchase_no_certs
          captured_with_certs = Factory :captured_daily_deal_purchase
          refund_no_certs = Factory :refunded_daily_deal_purchase_no_certs
          refund_with_certs = Factory :refunded_daily_deal_purchase
          stub_ids_file = StringIO.new("#{captured_no_certs.id}\n#{refund_no_certs.id}")
          stub_output_file = StringIO.new

          begin
            ENV["PURCHASE_IDS_FILE"] = "/some/fake/file"
            ENV["OUTFILE"] = "/some/other/fake/file"
            @purchase_fixer.expects(:get_purchase_ids_file).returns(stub_ids_file)
            @purchase_fixer.expects(:get_outfile).returns(stub_output_file) 
            @purchase_fixer.generate_broken_purchases_and_vouchers_report!
          ensure
            ENV["PURCHASE_IDS_FILE"] = ENV["OUTFILE"] = nil
          end

          stub_output_file.seek(0)
          csv_lines = FasterCSV.parse(stub_output_file.read)

          assert_equal 3, csv_lines.size
          assert_equal %w(publisher_label purchase_id purchase_created_at purchase_executed_at
                          purchase_refunded_at deal_id value_prop purchase_status actual_purchase_price
                          certificate_id certificate_status), csv_lines.first
          assert_equal 11, csv_lines.second.size 
          assert_equal 11, csv_lines.third.size 
        end

      end
      
      context ".fix_purchases_with_missing_vouchers!" do
        
        should "raise an ArgumentError if PURCHASE_IDS_FILE env var is not set" do
          e = assert_raises(ArgumentError) { @purchase_fixer.fix_purchases_with_missing_vouchers! }
          assert_equal "missing required argument PURCHASE_IDS_FILE", e.message
        end

        should "call .generate_vouchers_for_purchase_missing_vouchers for each purchase matching an ID in the PURCHASE_IDS_FILE" do
          captured_no_certs = Factory :captured_daily_deal_purchase_no_certs
          captured_with_certs = Factory :captured_daily_deal_purchase
          refund_no_certs = Factory :refunded_daily_deal_purchase_no_certs
          refund_with_certs = Factory :refunded_daily_deal_purchase
          stub_ids_file = StringIO.new("#{captured_no_certs.id}\n#{refund_no_certs.id}")

          @purchase_fixer.expects(:generate_vouchers_for_purchase_missing_vouchers).with(equals(captured_no_certs), {})
          @purchase_fixer.expects(:generate_vouchers_for_purchase_missing_vouchers).with(equals(refund_no_certs), {})
          @purchase_fixer.expects(:generate_vouchers_for_purchase_missing_vouchers).with(equals(captured_with_certs), {}).never
          @purchase_fixer.expects(:generate_vouchers_for_purchase_missing_vouchers).with(equals(refund_with_certs), {}).never
          File.expects(:open).with("/some/fake/file").returns(stub_ids_file)

          begin
            ENV["PURCHASE_IDS_FILE"] = "/some/fake/file"
            @purchase_fixer.fix_purchases_with_missing_vouchers!
          ensure
            ENV["PURCHASE_IDS_FILE"] = nil
          end
        end

        should "return a successful count and a list of purchases and exceptions, for purchases that encountered errors" do
          captured_no_certs = Factory :captured_daily_deal_purchase_no_certs
          captured_with_certs = Factory :captured_daily_deal_purchase
          refund_no_certs = Factory :refunded_daily_deal_purchase_no_certs
          refund_with_certs = Factory :refunded_daily_deal_purchase
          stub_ids_file = StringIO.new("#{captured_no_certs.id}\n#{refund_no_certs.id}")

          @purchase_fixer.expects(:generate_vouchers_for_purchase_missing_vouchers).with(equals(captured_no_certs), {})
          @purchase_fixer.expects(:generate_vouchers_for_purchase_missing_vouchers).with(equals(refund_no_certs), {}).raises(Exception, "something broke")
          @purchase_fixer.expects(:generate_vouchers_for_purchase_missing_vouchers).with(equals(captured_with_certs), {}).never
          @purchase_fixer.expects(:generate_vouchers_for_purchase_missing_vouchers).with(equals(refund_with_certs), {}).never
          File.expects(:open).with("/some/fake/file").returns(stub_ids_file)

          begin
            ENV["PURCHASE_IDS_FILE"] = "/some/fake/file"
            success_count, errors = @purchase_fixer.fix_purchases_with_missing_vouchers!
            assert_equal 1, success_count
            assert_equal 1, errors.size

            purchase_with_error, error_raised = errors.first
            assert_equal refund_no_certs, purchase_with_error
            assert_instance_of Exception, error_raised
            assert_equal "something broke", error_raised.message
          ensure
            ENV["PURCHASE_IDS_FILE"] = nil
          end
        end

      end

      context ".generate_vouchers_for_purchase_missing_vouchers" do

        should "raise an ArgumentError if passed a refunded purchase that has vouchers" do
          refund_with_vouchers = Factory :refunded_daily_deal_purchase
          assert refund_with_vouchers.daily_deal_certificates.present?
          e = assert_raises(ArgumentError) { @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(refund_with_vouchers) }
          assert_match %r{can't generate vouchers for refunded DailyDealPurchase \d+; this purchase already has vouchers}, e.message
        end

        should "raise an ArgumentError if passed a captured purchase that has vouchers" do
          purchase_with_vouchers = Factory :captured_daily_deal_purchase
          assert purchase_with_vouchers.daily_deal_certificates.present?
          e = assert_raises(ArgumentError) { @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(purchase_with_vouchers) }
          assert_match %r{can't generate vouchers for captured DailyDealPurchase \d+; this purchase already has vouchers}, e.message
        end

        should "raise an ArgumentError if passed a purchase that is not captured or refunded" do
          pending_purchase = Factory :pending_daily_deal_purchase
          assert pending_purchase.daily_deal_certificates.blank?
          e = assert_raises(ArgumentError) { @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(pending_purchase) }
          assert_match %r{can't generate vouchers for pending DailyDealPurchase \d+; purchase must be refunded or captured}, e.message
        end

        should "raise an ArgumentError when passed a captured purchase that is not of type 'DailyDealPurchase'" do
          non_voucher_purchase = Factory :captured_non_voucher_daily_deal_purchase
          e = assert_raises(ArgumentError) { @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(non_voucher_purchase) }
          assert_match %r{can't generate vouchers for captured DailyDealPurchase \d+; type must be DailyDealPurchase, but is NonVoucherDailyDealPurchase}, e.message
        end

        should "generate vouchers for a captured purchase that has no vouchers, plugging in DailyDealCertificate column values " +
               "that approximate what they would have been if the vouchers were generated correctly the first time" do
          captured_purchase_no_certs = Factory :captured_daily_deal_purchase_no_certs, :quantity => 2
          assert captured_purchase_no_certs.daily_deal_certificates.blank?
          assert captured_purchase_no_certs.memo.blank?

          assert_difference "DailyDealCertificate.count", 2 do
            assert_no_difference "ActionMailer::Base.deliveries.size" do
              @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(captured_purchase_no_certs)
            end
          end
          captured_purchase_no_certs.reload

          assert_equal "had vouchers regenerated by Brad B. as part of fixing https://www.pivotaltracker.com/story/show/31784553",
                       captured_purchase_no_certs.memo

          captured_purchase_no_certs.daily_deal_certificates.each do |c|
            assert c.active?
            assert c.redeemed_at.blank?
            assert_equal "John Public", c.redeemer_name
            assert c.serial_number.present?
            assert c.bar_code.blank?
            assert_equal 15, c.actual_purchase_price
            assert_equal 0, c.refund_amount
            assert c.refunded_at.blank?
            assert !c.serial_number_generated_by_third_party?
            assert !c.marked_used_by_user?
          end
        end

        should "generate vouchers for a refunded purchase that has no vouchers, plugging in DailyDealCertificate column values " +
               "that approximate what they would have been if the vouchers were generated correctly the first time, and " +
               "hardcoding the refunded_at column to July 16, per instructions from accounting" do
          refunded_at = 20.days.ago
          refunded_purchase_no_certs = Factory :refunded_daily_deal_purchase_no_certs, :quantity => 5, :refunded_at => refunded_at
          assert refunded_purchase_no_certs.daily_deal_certificates.blank?

          assert_difference "DailyDealCertificate.count", 5 do
            assert_no_difference "ActionMailer::Base.deliveries.size" do
              @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(refunded_purchase_no_certs)
            end
          end

          july_16_pdt = Time.zone.parse("2012-07-16 9:00 PDT")
          refunded_purchase_no_certs.reload
          refunded_purchase_no_certs.daily_deal_certificates.each do |c|
            assert c.refunded?
            assert c.redeemed_at.blank?
            assert_equal "John Public", c.redeemer_name
            assert c.serial_number.present?
            assert c.bar_code.blank?
            assert_equal 15, c.actual_purchase_price
            assert_equal 15, c.refund_amount
            assert !c.serial_number_generated_by_third_party?
            assert !c.marked_used_by_user?
            assert_equal july_16_pdt.to_s, c.refunded_at.to_s
          end
        end

        should "generate vouchers with recipient names, when provided" do
          captured_purchase_no_certs = Factory :captured_daily_deal_purchase_no_certs, :quantity => 3,
                                               :recipient_names => ["Nigella Lawson", "Jamie Oliver", "Nigel Slater"]
          assert_difference "DailyDealCertificate.count", 3 do
            assert_no_difference "ActionMailer::Base.deliveries.size" do
              @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(captured_purchase_no_certs)
            end
          end
          captured_purchase_no_certs.reload
          assert_same_elements ["Nigella Lawson", "Jamie Oliver", "Nigel Slater"], captured_purchase_no_certs.daily_deal_certificates.map(&:redeemer_name)
        end

        should "generate a purchase quantity x certificates_to_generate_per_unit_quantity vouchers" do
          multi_voucher_deal = Factory :daily_deal, :certificates_to_generate_per_unit_quantity => 3
          refunded_purchase_no_certs = Factory :refunded_daily_deal_purchase_no_certs, :quantity => 1, :daily_deal => multi_voucher_deal
          assert_difference "DailyDealCertificate.count", 3 do
            assert_no_difference "ActionMailer::Base.deliveries.size" do
              @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(refunded_purchase_no_certs)
            end
          end
        end

        should "set DailyDealCertificate#refunded_at to July 16, per instructions from accounting" do
          july_16_pdt = Time.zone.parse("2012-07-16 9:00 PDT")
          refunded_at = 1.day.ago
          refunded_purchase_no_certs = Factory :refunded_daily_deal_purchase_no_certs, :quantity => 1, :refunded_at => refunded_at
          assert_difference "DailyDealCertificate.count", 1 do
            assert_no_difference "ActionMailer::Base.deliveries.size" do
              @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(refunded_purchase_no_certs)
            end
          end
          refunded_purchase_no_certs.reload
          assert_equal july_16_pdt.to_s, refunded_purchase_no_certs.daily_deal_certificates.first.refunded_at.to_s
        end

        should "set refunded_at on both the purchase and the refunded vouchers to July 16, when refunded_at is nil" do
          july_16_pdt = Time.zone.parse("2012-07-16 9:00 PDT")
          refunded_purchase_no_certs = Factory :refunded_daily_deal_purchase_no_certs, :quantity => 1
          refunded_purchase_no_certs.update_attribute :refunded_at, nil
          assert refunded_purchase_no_certs.refunded_at.blank?
          assert_difference "DailyDealCertificate.count", 1 do
            assert_no_difference "ActionMailer::Base.deliveries.size" do
              @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(refunded_purchase_no_certs)
            end
          end
          refunded_purchase_no_certs.reload
          assert_equal july_16_pdt.to_s, refunded_purchase_no_certs.refunded_at.to_s
          assert_equal july_16_pdt.to_s, refunded_purchase_no_certs.daily_deal_certificates.first.refunded_at.to_s
        end

        should "raise a NotImplementedError if dealing with a purchase of a deal that does not use internal serial numbers" do
          third_party_deals_api_config = Factory :third_party_deals_api_config
          third_party_deal = Factory :daily_deal, :publisher => third_party_deals_api_config.publisher
          third_party_captured_purchase_no_certs = Factory :captured_daily_deal_purchase_no_certs, :daily_deal => third_party_deal
          e = assert_raises(NotImplementedError) do 
            assert_no_difference "DailyDealCertificate.count" do
              @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(third_party_captured_purchase_no_certs)
            end
          end
          assert_equal "generating missing vouchers is not supported for third party deals", e.message
        end
        
        should "raise a NotImplementedError if dealing with a purchase that is only partially refunded" do
          partially_refunded_purchase_no_certs = Factory :refunded_daily_deal_purchase_no_certs, :quantity => 3, :actual_purchase_price => 45, :refund_amount => 30
          e = assert_raises(NotImplementedError) do 
            assert_no_difference "DailyDealCertificate.count" do
              @purchase_fixer.generate_vouchers_for_purchase_missing_vouchers(partially_refunded_purchase_no_certs)
            end
          end
          assert_equal "generating missing vouchers is not supported for partial refunds", e.message
        end

      end

    end

  end

end
