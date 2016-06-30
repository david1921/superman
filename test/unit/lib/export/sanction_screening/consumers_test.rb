require File.dirname(__FILE__) + "/../../../../test_helper"

# hydra class Export::SanctionScreening::ConsumersTest

module Export

  module SanctionScreening

    class ConsumersTest < ActiveSupport::TestCase

      context "The consumer sanction file export" do

        setup do
          @screening_start_date = Time.zone.parse("Tue Apr 17 02:57:03 UTC 2012")
          @consumer = Factory :consumer
          Timecop.freeze(@screening_start_date) do
            Factory(:authorized_free_daily_deal_purchase, :payment_status => "captured")
            @p1 = pending_purchase_made_before_screening_start_date
            @p2 = pending_purchase_made_after_screening_start_date
            @p3 = captured_purchase_made_before_screening_start_date_but_refunded_after
            @p4 = captured_purchase_made_after_screening_start_date
            @p5 = captured_purchase_made_after_screening_start_date
            @p6 = captured_purchase_made_after_screening_start_date_with_consumer(@consumer)
            @p7 = captured_purchase_made_after_screening_start_date_with_consumer(@consumer)
            @p8 = voided_purchase_made_after_screening_start_date
            @p9 = captured_purchase_made_before_screening_start_date
            @p10 = authorized_purchase_made_before_screening_start_date
            @p11 = authorized_purchase_made_after_screening_start_date
            @p12 = purchased_gift_certificate
            @p13 = captured_purchase_made_after_screening_start_date # iphone purchase
            @p13.update_attributes(:device => "iphone-2.3.3")
            @p14 = captured_purchase_made_after_screening_start_date # purchase without billing name
            @p14.update_attributes(:billing_first_name => nil, :billing_last_name => nil)
            @p15 = captured_purchase_made_after_screening_start_date # purchase without billing name
            @p15.update_attributes(:billing_first_name => "", :billing_last_name => "")
          end

          Timecop.freeze(Time.parse("Tue May 17 02:57:03 UTC 2012")) do
            Export::SanctionScreening::Consumers.export_to_pipe_delimited_file!(@screening_start_date)
          end

          @expected_file_name = Rails.root.join("tmp", "sanction_screening_consumers_20120517025703.txt").to_s
          assert File.exists?(@expected_file_name), "couldn't find consumer sanction file in expected location #{@expected_file_name}"
          @csv_rows = FasterCSV.parse(File.read(@expected_file_name), :col_sep => "|")
        end

        fast_context ".export_to_pipe_delimited_file!" do

          should "output a header row" do
            assert_equal [
              "analog_id", "first_name", "last_name", "billing_address_1", "billing_address_2",
              "billing_city", "billing_state", "billing_zip", "cardholder_name", "credit_card_bin",
              "credit_card_last_4", "purchase_date"], @csv_rows.first
          end

          should "export only the number of purchases captured after the screening start date" do
            assert_equal 10, @csv_rows.length
          end

          should "export the consumer ID in the first column" do
            assert_equal @p4.consumer_id.to_s, @csv_rows[1][0]
            assert_equal @p5.consumer_id.to_s, @csv_rows[2][0]
            assert_equal @p6.consumer_id.to_s, @csv_rows[3][0]
            assert_equal @p7.consumer_id.to_s, @csv_rows[4][0]
            assert_equal @p11.consumer_id.to_s, @csv_rows[5][0]
            assert_equal @p12.paypal_payer_email, @csv_rows[6][0]
            assert_equal @p13.consumer_id.to_s, @csv_rows[7][0]
            assert_equal @p14.consumer_id.to_s, @csv_rows[8][0]
            assert_equal @p15.consumer_id.to_s, @csv_rows[9][0]
          end

          should "export the first name in the second column" do
            assert_equal @p4.daily_deal_payment.billing_first_name.to_s, @csv_rows[1][1]
            assert_equal @p5.daily_deal_payment.billing_first_name.to_s, @csv_rows[2][1]
            assert_equal @p6.daily_deal_payment.billing_first_name.to_s, @csv_rows[3][1]
            assert_equal @p7.daily_deal_payment.billing_first_name.to_s, @csv_rows[4][1]
            assert_equal @p11.daily_deal_payment.billing_first_name.to_s, @csv_rows[5][1]
            assert_equal @p12.paypal_first_name, @csv_rows[6][1]
            assert_equal @p13.daily_deal_payment.billing_first_name.to_s, @csv_rows[7][1]
            assert_equal @p14.daily_deal_payment.billing_first_name.to_s, @csv_rows[8][1]
            assert_equal @p15.daily_deal_payment.billing_first_name.to_s, @csv_rows[9][1]
          end

          should "export the last name in the third column" do
            assert_equal @p4.daily_deal_payment.billing_last_name.to_s, @csv_rows[1][2]
            assert_equal @p5.daily_deal_payment.billing_last_name.to_s, @csv_rows[2][2]
            assert_equal @p6.daily_deal_payment.billing_last_name.to_s, @csv_rows[3][2]
            assert_equal @p7.daily_deal_payment.billing_last_name.to_s, @csv_rows[4][2]
            assert_equal @p11.daily_deal_payment.billing_last_name.to_s, @csv_rows[5][2]
            assert_equal @p12.paypal_last_name, @csv_rows[6][2]
            assert_equal @p13.daily_deal_payment.billing_last_name.to_s, @csv_rows[7][2]
            assert_equal @p14.daily_deal_payment.billing_last_name.to_s, @csv_rows[8][2]
            assert_equal @p15.daily_deal_payment.billing_last_name.to_s, @csv_rows[9][2]
          end

          should "export the billing address 1 in the fourth column" do
            assert_equal @p4.daily_deal_payment.billing_address_line_1, @csv_rows[1][3]
            assert_equal @p5.daily_deal_payment.billing_address_line_1, @csv_rows[2][3]
            assert_equal @p6.daily_deal_payment.billing_address_line_1, @csv_rows[3][3]
            assert_equal @p7.daily_deal_payment.billing_address_line_1, @csv_rows[4][3]
            assert_equal @p11.daily_deal_payment.billing_address_line_1, @csv_rows[5][3]
            assert_equal @p12.paypal_address_street, @csv_rows[6][3]
            assert_equal @p13.daily_deal_payment.billing_address_line_1, @csv_rows[7][3]
            assert_equal @p14.daily_deal_payment.billing_address_line_1, @csv_rows[8][3]
            assert_equal @p15.daily_deal_payment.billing_address_line_1, @csv_rows[9][3]
          end

          should "export the billing address 2 in the fifth column" do
            assert_equal @p4.daily_deal_payment.billing_address_line_2, @csv_rows[1][4]
            assert_equal @p5.daily_deal_payment.billing_address_line_2, @csv_rows[2][4]
            assert_equal @p6.daily_deal_payment.billing_address_line_2, @csv_rows[3][4]
            assert_equal @p7.daily_deal_payment.billing_address_line_2, @csv_rows[4][4]
            assert_equal @p11.daily_deal_payment.billing_address_line_2, @csv_rows[5][4]
            assert_equal nil, @csv_rows[6][4]
            assert_equal @p13.daily_deal_payment.billing_address_line_2, @csv_rows[7][4]
            assert_equal @p14.daily_deal_payment.billing_address_line_2, @csv_rows[8][4]
            assert_equal @p15.daily_deal_payment.billing_address_line_2, @csv_rows[9][4]
          end

          should "export the billing city in the sixth column" do
            assert_equal @p4.daily_deal_payment.billing_city, @csv_rows[1][5]
            assert_equal @p5.daily_deal_payment.billing_city, @csv_rows[2][5]
            assert_equal @p6.daily_deal_payment.billing_city, @csv_rows[3][5]
            assert_equal @p7.daily_deal_payment.billing_city, @csv_rows[4][5]
            assert_equal @p11.daily_deal_payment.billing_city, @csv_rows[5][5]
            assert_equal @p12.paypal_address_city, @csv_rows[6][5]
            assert_equal @p13.daily_deal_payment.billing_city, @csv_rows[7][5]
            assert_equal @p14.daily_deal_payment.billing_city, @csv_rows[8][5]
            assert_equal @p15.daily_deal_payment.billing_city, @csv_rows[9][5]
          end

          should "export the billing state in the seventh column" do
            assert_equal @p4.daily_deal_payment.billing_state, @csv_rows[1][6]
            assert_equal @p5.daily_deal_payment.billing_state, @csv_rows[2][6]
            assert_equal @p6.daily_deal_payment.billing_state, @csv_rows[3][6]
            assert_equal @p7.daily_deal_payment.billing_state, @csv_rows[4][6]
            assert_equal @p11.daily_deal_payment.billing_state, @csv_rows[5][6]
            assert_equal @p12.paypal_address_state, @csv_rows[6][6]
            assert_equal @p13.daily_deal_payment.billing_state, @csv_rows[7][6]
            assert_equal @p14.daily_deal_payment.billing_state, @csv_rows[8][6]
            assert_equal @p15.daily_deal_payment.billing_state, @csv_rows[9][6]
          end

          should "export the billing zip code in the eighth column" do
            assert_equal @p4.daily_deal_payment.payer_postal_code, @csv_rows[1][7]
            assert_equal @p5.daily_deal_payment.payer_postal_code, @csv_rows[2][7]
            assert_equal @p6.daily_deal_payment.payer_postal_code, @csv_rows[3][7]
            assert_equal @p7.daily_deal_payment.payer_postal_code, @csv_rows[4][7]
            assert_equal @p11.daily_deal_payment.payer_postal_code, @csv_rows[5][7]
            assert_equal @p12.paypal_address_zip, @csv_rows[6][7]
            assert_equal @p13.daily_deal_payment.payer_postal_code, @csv_rows[7][7]
            assert_equal @p14.daily_deal_payment.payer_postal_code, @csv_rows[8][7]
            assert_equal @p15.daily_deal_payment.payer_postal_code, @csv_rows[9][7]
          end

          should "export the card name in the ninth column" do
            assert_equal @p4.daily_deal_payment.name_on_card, @csv_rows[1][8]
            assert_equal @p5.daily_deal_payment.name_on_card, @csv_rows[2][8]
            assert_equal @p6.daily_deal_payment.name_on_card, @csv_rows[3][8]
            assert_equal @p7.daily_deal_payment.name_on_card, @csv_rows[4][8]
            assert_equal @p11.daily_deal_payment.name_on_card, @csv_rows[5][8]
            assert_equal @p12.paypal_address_name, @csv_rows[6][8]
            assert_equal @p13.daily_deal_payment.name_on_card, @csv_rows[7][8]
            assert_equal @p14.daily_deal_payment.name_on_card, @csv_rows[8][8]
            assert_equal @p15.daily_deal_payment.name_on_card, @csv_rows[9][8]
          end

          should "export the credit card BIN in the tenth column" do
            assert_equal @p4.daily_deal_payment.credit_card_bin, @csv_rows[1][9]
            assert_equal @p5.daily_deal_payment.credit_card_bin, @csv_rows[2][9]
            assert_equal @p6.daily_deal_payment.credit_card_bin, @csv_rows[3][9]
            assert_equal @p7.daily_deal_payment.credit_card_bin, @csv_rows[4][9]
            assert_equal @p11.daily_deal_payment.credit_card_bin, @csv_rows[5][9]
            assert_equal nil, @csv_rows[6][9]
            assert_equal @p13.daily_deal_payment.credit_card_bin, @csv_rows[7][9]
            assert_equal @p14.daily_deal_payment.credit_card_bin, @csv_rows[8][9]
            assert_equal @p15.daily_deal_payment.credit_card_bin, @csv_rows[9][9]
          end

          should "export the credit card last four in the eleventh column" do
            assert_equal @p4.daily_deal_payment.credit_card_last_4, @csv_rows[1][10]
            assert_equal @p5.daily_deal_payment.credit_card_last_4, @csv_rows[2][10]
            assert_equal @p6.daily_deal_payment.credit_card_last_4, @csv_rows[3][10]
            assert_equal @p7.daily_deal_payment.credit_card_last_4, @csv_rows[4][10]
            assert_equal @p11.daily_deal_payment.credit_card_last_4, @csv_rows[5][10]
            assert_equal nil, @csv_rows[6][10]
            assert_equal @p13.daily_deal_payment.credit_card_last_4, @csv_rows[7][10]
            assert_equal @p14.daily_deal_payment.credit_card_last_4, @csv_rows[8][10]
            assert_equal @p15.daily_deal_payment.credit_card_last_4, @csv_rows[9][10]
          end

          should "export the purchase data in the twelfth column" do
            assert_equal @p4.executed_at.strftime("%Y-%m-%d"), @csv_rows[1][11]
            assert_equal @p5.executed_at.strftime("%Y-%m-%d"), @csv_rows[2][11]
            assert_equal @p6.executed_at.strftime("%Y-%m-%d"), @csv_rows[3][11]
            assert_equal @p7.executed_at.strftime("%Y-%m-%d"), @csv_rows[4][11]
            assert_equal @p11.executed_at.strftime("%Y-%m-%d"), @csv_rows[5][11]
            assert_equal @p12.paypal_payment_date.strftime("%Y-%m-%d"), @csv_rows[6][11]
            assert_equal @p13.executed_at.strftime("%Y-%m-%d"), @csv_rows[7][11]
            assert_equal @p14.executed_at.strftime("%Y-%m-%d"), @csv_rows[8][11]
            assert_equal @p15.executed_at.strftime("%Y-%m-%d"), @csv_rows[9][11]
          end

        end

        teardown do
          File.unlink(@expected_file_name) if @expected_file_name.present? && File.exist?(@expected_file_name)
        end

      end

      context "export_encrypt_and_upload!" do
    
        should "create a Job record with a sensible key, and started_at and finished_at populated" do
          assert !Job.exists?(:key => "sanction_screening:export_and_uploaded_encrypted_consumer_file")
          Export::SanctionScreening::Consumers.expects(:export_to_pipe_delimited_file!)
          Export::SanctionScreening::Upload.expects(:encrypt_upload_and_remove!)
          assert_difference "Job.count" do
            Export::SanctionScreening::Consumers.export_encrypt_and_upload!(
              not_used_in_this_test, not_used_in_this_test, not_used_in_this_test)
          end     
          job = Job.last
          assert_equal "sanction_screening:export_and_uploaded_encrypted_consumer_file", job.key
          assert job.started_at.present?
          assert job.finished_at.present?
        end

      end

      def pending_purchase_made_before_screening_start_date
        Factory :pending_daily_deal_purchase, :created_at => @screening_start_date - 1.day
      end

      def pending_purchase_made_after_screening_start_date
        Factory :pending_daily_deal_purchase, :created_at => @screening_start_date + 1.day
      end

      def captured_purchase_made_before_screening_start_date_but_refunded_after
        Factory :refunded_daily_deal_purchase_with_sanctions_info,
                :created_at => @screening_start_date - 1.week,
                :executed_at => @screening_start_date - 6.days,
                :refunded_at => @screening_start_date + 2.days
      end

      def captured_purchase_made_after_screening_start_date
        Factory :captured_daily_deal_purchase_with_sanctions_info, :executed_at => @screening_start_date + executed_at_offset
      end

      def captured_purchase_made_after_screening_start_date_with_consumer(consumer)
        deal = Factory :side_daily_deal, :publisher => consumer.publisher
        Factory :captured_daily_deal_purchase_with_sanctions_info,
                :created_at => @screening_start_date,
                :executed_at => @screening_start_date + executed_at_offset,
                :daily_deal => deal,
                :consumer => consumer
      end

      def voided_purchase_made_after_screening_start_date
        Factory :voided_daily_deal_purchase_with_sanctions_info, :created_at => @screening_start_date, :executed_at => @screening_start_date + executed_at_offset
      end

      def captured_purchase_made_before_screening_start_date
        Factory :captured_daily_deal_purchase_with_sanctions_info, :created_at => @screening_start_date - 10.days, :executed_at => @screening_start_date - 9.days
      end

      def authorized_purchase_made_before_screening_start_date
        Factory :authorized_daily_deal_purchase_with_sanctions_info, :created_at => @screening_start_date - 4.days, :executed_at => @screening_start_date - 1.second
      end

      def authorized_purchase_made_after_screening_start_date
        Factory :authorized_daily_deal_purchase_with_sanctions_info, :created_at => @screening_start_date, :executed_at => @screening_start_date + executed_at_offset
      end

      def purchased_gift_certificate
        Factory(:purchased_gift_certificate, :paypal_payment_date => (@screening_start_date + executed_at_offset).strftime("%H:%M:%S %b %d, %Y %Z"))
      end

      def executed_at_offset
        if @offset_for_ensuring_predictable_ordering_of_rows.present?
          @offset_for_ensuring_predictable_ordering_of_rows += 1
        else
          @offset_for_ensuring_predictable_ordering_of_rows = 1
        end
      end

    end

  end

end
