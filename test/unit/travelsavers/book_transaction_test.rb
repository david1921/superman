require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Travelsavers::BookTransactionTest

module Travelsavers

  class BookTransactionTest < ActiveSupport::TestCase

    def setup
      FakeWeb.allow_net_connect = false
      @booking_id = "84"
      @url = "https://psclient:TSvH78%23L$@bookingservices.travelsavers.com:443/productservice.svc/REST/BookingTransaction?TransactionID=#{@booking_id}"
      stub_ts_vendor_booking_errors_response(@url)
      @purchase_stub = stub(:id => 1234)
    end

    should "call parse! when initialized" do
      Travelsavers::BookTransaction.any_instance.expects(:parse!)
      Travelsavers::BookTransaction.new("", @booking_id, @purchase_stub)
    end


    context "Travelsavers::BookTransaction" do

      context ".get" do

        should "return a Travelsavers::BookTransaction instance" do
          assert_instance_of Travelsavers::BookTransaction, Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
        end

        should "raise a UnexpectedHTTPResponseError with a helpful message" do
          error_message =
              "Travelsavers purchases might be broken! The booking status URL " +
              "for DailyDealPurchase #{@purchase_stub.id} (#{@url}) should have returned a " +
              "2xx status, but returned 500. This means we don't know whether " +
              "the booking succeeded or failed. Please contact Daniel or Brad for " +
              "further assistance."

          stub_ts_server_500_error_response(@url)
          e = assert_raise Travelsavers::BookTransaction::UnexpectedHTTPResponseError do
            Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          end

          assert_match /Travelsavers purchases might be broken!/, e.message
          assert_match /\(https:\/\/.*\) should have returned a 2xx status, but returned 500/, e.message
        end
      end

    end

    context "A Travelsavers::BookTransaction instance" do

      setup do
        @book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
      end

      context "#parse!" do

        should "raise an exception when the BookTransaction is invalid" do
          stub_ts_invalid_book_transaction_response(@url)
          assert_raises(RuntimeError) { Travelsavers::BookTransaction.get(@booking_id, @purchase_stub) }
        end

        should "not raise an exception when the BookTransaction is valid" do
          stub_ts_success_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert_nothing_raised { book_transaction.parse! }
        end

      end

      context "#success?" do

        should "raise an exception if parse! has not yet been called" do
          Travelsavers::BookTransaction.any_instance.stubs(:parse!)
          stub_ts_success_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert_raises(RuntimeError) { book_transaction.success? }
        end

        should "not raise an exception if parse! has been called" do
          stub_ts_success_response(@url)
          assert_nothing_raised { Travelsavers::BookTransaction.get(@booking_id, @purchase_stub) }
        end

        should "return true when the booking succeeded" do
          stub_ts_success_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert book_transaction.success?
        end

        should "return false when the booking failed" do
          stub_ts_vendor_booking_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert !book_transaction.success?
        end

        should "raise a Travelsavers::BookTransaction::UnknownBookingStatusError when the booking status is unknown" do
          stub_ts_unknown_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert_raises(Travelsavers::BookTransaction::UnknownBookingStatusError) { book_transaction.success? }
        end

        should "set the validation_errors attribute to instances of BookTransaction::ValidationError " +
                   "when there are errors with ErrorSourceID 1" do
          stub_ts_validation_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)

          assert !book_transaction.success?
          assert book_transaction.validation_errors?
          assert !book_transaction.vendor_booking_errors?
          assert !book_transaction.ts_tx_retrieval_errors?
          assert !book_transaction.vendor_booking_retrieval_errors?

          assert_equal 5, book_transaction.validation_errors.size
          assert book_transaction.validation_errors.all? { |error| error.is_a?(BookTransaction::ValidationError) }
          assert book_transaction.validation_errors.any? { |error| error.code == "105" && error.message == "Missing or invalid credit card cardholder first name." }
        end

        should "set fixable_errors to an array of error messages of errors that are user-fixable" do
          stub_ts_validation_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)

          assert !book_transaction.success?
          assert book_transaction.unfixable_errors.blank?
          assert !book_transaction.has_sold_out_error?
          assert_equal 5, book_transaction.fixable_errors.size
          assert book_transaction.fixable_errors.all? { |error| error.is_a?(BookTransaction::ValidationError) }
        end

        should "set unfixable_errors to an array of error messages that are *not* user-fixable" do
          stub_ts_unknown_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert_raises(Travelsavers::BookTransaction::UnknownBookingStatusError) { !book_transaction.success? }
          assert book_transaction.fixable_errors.blank?
          assert_equal 1, book_transaction.unfixable_errors.size
          assert_instance_of BookTransaction::TsTxRetrievalError, book_transaction.unfixable_errors.first
        end

        should "be sold out" do
          stub_ts_sold_out_error_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert book_transaction.fixable_errors.blank?
          assert_equal 1, book_transaction.unfixable_errors.size
          assert_instance_of BookTransaction::ValidationError, book_transaction.unfixable_errors.first
          assert book_transaction.has_sold_out_error?
        end

        should "set the checkout_form_values attribute when form values are provided in the response" do
          stub_ts_validation_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)

          assert book_transaction.checkout_form_values.present?
          assert_equal({
                           "credit_card[billing][address_line_1]" => "123 Test Lane",
                           "traveler[0][birth_date]" => "30/05/1969",
                           "traveler[0][citizenship]" => "US",
                           "traveler[0][email]" => "jtest@test.com",
                           "traveler[1][first_name]" => "Jane",
                           "traveler[1][gender]" => "F"
                       }, book_transaction.checkout_form_values)
        end

        should "set the vendor_booking_errors attribute when there are errors with ErrorSourceID 2" do
          stub_ts_vendor_booking_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)

          assert !book_transaction.success?
          assert book_transaction.vendor_booking_errors?
          assert !book_transaction.validation_errors?
          assert !book_transaction.ts_tx_retrieval_errors?
          assert !book_transaction.vendor_booking_retrieval_errors?

          assert_equal 1, book_transaction.vendor_booking_errors.size
          assert book_transaction.vendor_booking_errors.all? { |error| error.is_a?(BookTransaction::BookingError) }
          assert book_transaction.vendor_booking_errors.any? { |error| error.code == "132" && error.message =~ /cabin is no longer available/i }
        end

        should "set the ts_tx_retrieval_errors attribute when there are errors with ErrorSourceID 3" do
          stub_ts_unknown_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)

          assert_raises(Travelsavers::BookTransaction::UnknownBookingStatusError) { book_transaction.success? }
          assert book_transaction.ts_tx_retrieval_errors?
          assert !book_transaction.validation_errors?
          assert !book_transaction.vendor_booking_errors?
          assert !book_transaction.vendor_booking_retrieval_errors?

          assert_equal 1, book_transaction.ts_tx_retrieval_errors.size
          assert book_transaction.ts_tx_retrieval_errors.all? { |error| error.is_a?(BookTransaction::TsTxRetrievalError) }
          assert book_transaction.ts_tx_retrieval_errors.any? { |error|
            error.code == "133" && error.message =~ /unhandled error/
          }
        end

        should "set the vendor_booking_retrieval_errors attribute when there are errors with ErrorSourceID 4" do
          stub_ts_success_with_vendor_booking_retrieval_errors_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)

          assert !book_transaction.success?
          assert book_transaction.vendor_booking_retrieval_errors?
          assert !book_transaction.ts_tx_retrieval_errors?
          assert !book_transaction.validation_errors?
          assert !book_transaction.vendor_booking_errors?

          assert_equal 1, book_transaction.vendor_booking_retrieval_errors.size
          assert book_transaction.vendor_booking_retrieval_errors.all? { |error| error.is_a?(BookTransaction::VendorBookingRetrievalError) }
          assert book_transaction.vendor_booking_retrieval_errors.any? { |error|
            error.code == "134" && error.message =~ /unhandled error/
          }
        end

        should "set the service_start_date to an ActiveSupport::TimeWithZone object, when present" do
          stub_ts_success_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert_instance_of ActiveSupport::TimeWithZone, book_transaction.service_start_date
          assert_equal Time.zone.parse("2012-04-21T00:00:00"), book_transaction.service_start_date
        end

        should "set the service_start_date to nil, when not present" do
          stub_ts_pending_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert_nil book_transaction.service_start_date
        end

        should "set the service_end_date to an ActiveSupport::TimeWithZone object, when present" do
          stub_ts_success_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert_instance_of ActiveSupport::TimeWithZone, book_transaction.service_end_date
          assert_equal Time.zone.parse("2012-04-28T00:00:00"), book_transaction.service_end_date
        end

        should "set the service_end_date to nil, when not present" do
          stub_ts_pending_response(@url)
          book_transaction = Travelsavers::BookTransaction.get(@booking_id, @purchase_stub)
          assert_nil book_transaction.service_end_date
        end

      end

    end

    def data_file_path
      "test/unit/travelsavers/data"
    end

  end

end
