require File.dirname(__FILE__) + "/../lib_helper"

class Travelsavers::BookTransactionTest < Test::Unit::TestCase

  TS_TEST_DATA_DIR = File.dirname(__FILE__) + "/../../../../unit/travelsavers/data/"

  context "TransactionError" do
    context "#consumer_message" do
      should "return the original message" do
        @error = Travelsavers::BookTransaction::TransactionError.new(:code => "", :message => "original error message")
        assert_equal "original error message", @error.consumer_message
      end
    end
  end

  context "BookingError" do

    context "::create" do
      should "return a new BookingError" do
        error = Travelsavers::BookTransaction::BookingError.create({})
        assert_instance_of Travelsavers::BookTransaction::BookingError, error
      end

      should "return a new PriceMismatchError" do
        error = Travelsavers::BookTransaction::BookingError.create(:code => "132", :message => "Actual quoted price is 2000")
        assert_instance_of Travelsavers::BookTransaction::PriceMismatchError, error
      end
    end
  end

  context "PriceMismatchError" do
    context "#consumer_message" do
      should "be 'There was a system error. We will notify you when it has been resolved so you can complete your purchase.'" do
        @error = Travelsavers::BookTransaction::PriceMismatchError.new(:code => "", :message => "")
        assert_equal "There was a system error. We will notify you when it has been resolved so you can complete your purchase.", @error.consumer_message
      end
    end

    context "#message" do
      should "return original message" do
        @error = Travelsavers::BookTransaction::PriceMismatchError.new(:code => "", :message => "original message")
        assert_equal "original message", @error.message
      end
    end
  end

  context "#price_mismatch_error" do

    should "return the price mismatch error from @vendor_booking_errors" do
      xml = File.read(TS_TEST_DATA_DIR + "book_transaction_price_mismatch.xml")
      @book_transaction = Travelsavers::BookTransaction.new(xml, "12345", nil)
      error = @book_transaction.price_mismatch_error
      assert_instance_of Travelsavers::BookTransaction::PriceMismatchError, error
    end

    should "return nil when there is no price mismatch error" do
      xml = File.read(TS_TEST_DATA_DIR + "book_transaction_booking_errors.xml")
      @book_transaction = Travelsavers::BookTransaction.new(xml, "12345", nil)
      error = @book_transaction.price_mismatch_error
      assert !@book_transaction.vendor_booking_errors.empty?
      assert_nil error
    end
  end

  context "#create_error_for_type" do

    should "call BookingError.create" do
      booking_error_options = { :code => "132", :message => "error" }
      mock_booking_error = mock("BookingError")
      doc = Nokogiri::XML("<xml><ErrorCode>132</ErrorCode><ErrorText>error</ErrorText></xml>")

      Travelsavers::BookTransaction::BookingError.expects(:create).with(booking_error_options).returns(mock_booking_error)
      booking_error = Travelsavers::BookTransaction.create_error_for_type(doc, Travelsavers::BookTransaction::BookingError::ErrorSourceId)
      assert_equal mock_booking_error, booking_error
    end
  end


end

