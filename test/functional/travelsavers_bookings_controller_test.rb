require File.dirname(__FILE__) + "/../test_helper"

class TravelsaversBookingsControllerTest < ActionController::TestCase
  def setup
    FakeWeb.allow_net_connect = false
  end

  context "#handle_redirect" do
    setup do
      @purchase = Factory(:travelsavers_daily_deal_purchase)
      @booking_id = "12345"
    end

    context "valid parameters" do
      context "in all cases" do
        setup do
          get :handle_redirect, :ts_transaction_id => @booking_id, :daily_deal_purchase_id => @purchase.to_param
        end

        should "render the processing page" do
          assert_response :ok
          assert_template :handle_redirect
          assert_select "#processing_message"
          assert_select "#freeze_overlay"
        end

        should "assign the booking to @travelsavers_booking" do
          assert_equal TravelsaversBooking.find_by_book_transaction_id(@booking_id), assigns(:travelsavers_booking)
        end

        should "assign the deal to @daily_deal" do
          assert_equal @purchase.daily_deal, assigns(:daily_deal)
        end
      end

      context "existing booking record" do
        setup do
          @booking = Factory(:travelsavers_booking_with_validation_errors, :daily_deal_purchase => @purchase)
          @new_booking_id = @booking.book_transaction_id.succ
        end

        should "not create a booking record" do
          assert_no_difference "TravelsaversBooking.count" do
            get :handle_redirect, :ts_transaction_id => @new_booking_id, :daily_deal_purchase_id => @purchase.to_param
          end
        end

        should "reset the booking record xml, statuses, and update the ts_transaction_id" do
          get :handle_redirect, :ts_transaction_id => @new_booking_id, :daily_deal_purchase_id => @purchase.to_param
          @booking.reload
          assert_nil @booking.book_transaction_xml
          assert_nil @booking.booking_status
          assert_nil @booking.payment_status
          assert_equal @new_booking_id, @booking.book_transaction_id
        end
      end

      context "existing booking record that is pending" do
        setup do
          @booking = Factory(:pending_travelsavers_booking, :daily_deal_purchase => @purchase)
        end

        should "not reset the booking record because the ts_transaction_id didn't change'" do
          old_book_transaction_id = @booking.book_transaction_id
          get :handle_redirect, :ts_transaction_id => @booking.book_transaction_id, :daily_deal_purchase_id => @purchase.to_param
          @booking.reload
          assert_equal old_book_transaction_id, @booking.book_transaction_id
        end
      end

      context "no existing booking record" do
        should "create a new booking record with the purchase and the transaction id" do
          assert_nil @purchase.travelsavers_booking
          assert_difference "TravelsaversBooking.count" do
            get :handle_redirect, :ts_transaction_id => @booking_id, :daily_deal_purchase_id => @purchase.to_param
          end
          booking = @purchase.reload.travelsavers_booking
          assert_nil booking.book_transaction_xml
          assert_nil booking.booking_status
          assert_nil booking.payment_status
          assert_equal @booking_id, booking.book_transaction_id
        end
      end

      context "booking record validation fails" do
        should "raise an ActiveRecord::RecordInvalid" do
          TravelsaversBooking.any_instance.stubs(:valid?).returns(false)
          assert_raises ActiveRecord::RecordInvalid do
            get :handle_redirect, :ts_transaction_id => @booking_id, :daily_deal_purchase_id => @purchase.to_param
          end
        end
      end
    end

    context "missing ts_transaction_id parameter" do

      should "raise an ArgumentError exception" do
        begin
          get :handle_redirect, :daily_deal_purchase_id => @purchase.to_param
        rescue ArgumentError => e
          assert_equal "missing required parameter ts_transaction_id", e.message
        else
          assert false, "expected ArgumentError exception to be raised"
        end
      end

    end

    context "missing daily_deal_purchase_id" do

      should "raise an ArgumentError exception" do
        begin
          get :handle_redirect, :ts_transaction_id => @booking_id
        rescue ArgumentError => e
          assert_equal "missing required parameter daily_deal_purchase_id", e.message
        else
          assert false, "expected ArgumentError exception to be raised"
        end
      end

    end

  end

  context "#try_to_resolve" do
    setup do
      @booking = Factory(:pending_travelsavers_booking)
    end

    should "assign the booking to @travelsavers_booking" do
      get :try_to_resolve, :id => @booking.to_param
      assert_equal @booking, assigns(:travelsavers_booking)
    end

    context "when the booking has unfixable errors" do
     
      setup do
        stub_ts_success_with_vendor_booking_retrieval_errors_response(travelsavers_booking_url(@booking.book_transaction_id))
      end

      should "render the thank you page url when the polling time limit has been exceeded" do
        @controller.stubs(:polling_time_limit_exceeded?).returns(true)
        get :try_to_resolve, :id => @booking.to_param
        assert_response :success
        assert_equal thank_you_daily_deal_purchase_url(@booking.daily_deal_purchase), @response.body
      end

      should "render the thank you page url even if the polling time limit has not been exceeded" do
        @controller.stubs(:polling_time_limit_exceeded?).returns(false)
        get :try_to_resolve, :id => @booking.to_param
        assert_response :success
        assert_equal thank_you_daily_deal_purchase_url(@booking.daily_deal_purchase), @response.body
      end

    end

    context "booking is unresolved" do
      should "try and resolve the booking" do
        TravelsaversBooking.any_instance.expects(:sync_with_travelsavers!)
        get :try_to_resolve, :id => @booking.to_param
      end

      context "exception raised" do
        setup do
          @exception = Exception.new("something weird happened")
          @exception.stubs(:backtrace).returns(["the", "backtrace"])
          TravelsaversBooking.any_instance.stubs(:sync_with_travelsavers!).raises(@exception)
        end

        should "log to Exceptional and the Rails error log" do
          Exceptional.expects(:handle).with(@exception)
          Rails.logger.expects(:error).with(
            regexp_matches(/^Unexpected error trying to resolve TravelsaversBooking \d+: something weird happened\nthe\nbacktrace/))
          get :try_to_resolve, :id => @booking.to_param
        end

        should "render unexpected error url" do
          get :try_to_resolve, :id => @booking.to_param
          assert_equal unexpected_error_travelsavers_booking_url(@booking), @response.body
        end
      end

      context "polling time limit exceeded" do
        setup do
          TravelsaversBooking.any_instance.stubs(:sync_with_travelsavers!)
          @controller.stubs(:polling_time_limit_exceeded?).returns(true)
        end
        should "render unresolved booking url" do
          get :try_to_resolve, :id => @booking.to_param
          assert_equal unresolved_travelsavers_booking_url(@booking), @response.body
        end
        should "deliver unresolved email to consumer" do
          assert_difference "ActionMailer::Base.deliveries.size" do
            get :try_to_resolve, :id => @booking.to_param
          end
          email = ActionMailer::Base.deliveries.last
          assert_equal [@booking.consumer.email], email.to
          assert_equal "Your Deal of the Day Booking Has Been Received!", email.subject
        end
      end

      context "polling should continue" do

        should "render nothing" do
          TravelsaversBooking.any_instance.stubs(:sync_with_travelsavers!)
          Timecop.freeze do
            @booking.update_attributes!(:created_at => 5.minutes.ago, :updated_at => 29.seconds.ago)
            get :try_to_resolve, :id => @booking.to_param
            assert_equal " ", @response.body # Rails renders a single space to solve a Safari issue
          end
        end
      end

      context "vendor error - price mismatch" do
        should "notify Exceptional" do
          Exceptional.expects(:handle).with(instance_of(Travelsavers::BookTransaction::PriceMismatchError), regexp_matches(/does not match price/))
          stub_ts_price_mismatch_response(travelsavers_booking_url(@booking.book_transaction_id))
          get :try_to_resolve, :id => @booking.to_param
        end
      end

    end

    context "booking is resolved" do
      context "successful" do
        setup do
          stub_ts_success_response(travelsavers_booking_url(@booking.book_transaction_id))
        end

        should "render thank you page url" do
          get :try_to_resolve, :id => @booking.to_param
          assert_equal thank_you_daily_deal_purchase_url(@booking.daily_deal_purchase.to_param), @response.body
        end

        should "send purchase confirmation email" do
          assert_difference "ActionMailer::Base.deliveries.size" do
            get :try_to_resolve, :id => @booking.to_param
          end
          email = ActionMailer::Base.deliveries.last
          assert_equal "Purchase Confirmed", email.subject
        end
      end

      context "not successful" do
        should "render error page url" do
          stub_ts_validation_errors_response(travelsavers_booking_url(@booking.book_transaction_id))
          get :try_to_resolve, :id => @booking.to_param
          assert_equal error_daily_deal_purchase_url(@booking.daily_deal_purchase), @response.body
        end
      end
    end
  end

  context "#try_to_resolve with booking status success, payment status fail" do

    setup do
      @booking = Factory :successful_travelsavers_booking_with_failed_payment
      TravelsaversBooking.any_instance.stubs(:sync_with_travelsavers!)
    end

    should "render nothing when the polling time limit has not been exceeded" do
      @controller.stubs(:polling_time_limit_exceeded?).returns(false)
      get :try_to_resolve, :id => @booking.to_param
      assert_response :success
      assert_equal " ", @response.body
    end

    should "render the thank you page url when the polling time limit has been exceeded" do
      @controller.stubs(:polling_time_limit_exceeded?).returns(true)
      get :try_to_resolve, :id => @booking.to_param
      assert_response :success
      assert_equal thank_you_daily_deal_purchase_url(@booking.daily_deal_purchase.to_param), @response.body
    end

  end

  context "#unresolved" do

    should "display a message letting the user know they will receive an email when " +
           "their booking has been processed" do
      pending_booking = Factory :pending_travelsavers_booking
      get :unresolved, :id => pending_booking.to_param
      assert_response :success
      assert_match /your booking is being processed/i, @response.body
      assert_match /you will receive a confirmation email shortly/i, @response.body
    end

    should "be redirected to the purchase thank_you page, if the booking is actually resolved" do
      successful_booking = Factory :successful_travelsavers_booking
      get :unresolved, :id => successful_booking.to_param
      assert_redirected_to thank_you_daily_deal_purchase_url(successful_booking.daily_deal_purchase)
    end
          
  end

end
