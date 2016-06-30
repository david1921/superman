require File.dirname(__FILE__) + "/../../models_helper"

class TravelsaversBookings::CoreTest < Test::Unit::TestCase
  def setup
    @successful_booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
    @pending_booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
    @success_xml = File.read(File.dirname(__FILE__) + "/../../../../../unit/travelsavers/data/book_transaction_success.xml")
    @pending_xml = File.read(File.dirname(__FILE__) + "/../../../../../unit/travelsavers/data/book_transaction_pending.xml")
    @success_xml_doc = Nokogiri::XML(@success_xml)
    @pending_xml_doc = Nokogiri::XML(@pending_xml)
    @successful_booking.stubs(:doc).returns(@success_xml_doc)
    @pending_booking.stubs(:doc).returns(@pending_xml_doc)
  end

  context "#doc" do
    should "return the xml document and cache it" do
      @successful_booking.unstub(:doc)
      @successful_booking.expects(:book_transaction_xml).once.returns(@success_xml)
      assert_equal @success_xml_doc.to_xml, @successful_booking.doc.to_xml, "documents don't match"
      @successful_booking.doc
    end
  end

  context "#product_name" do
    should "return the product name from the xml" do
      assert_equal @success_xml_doc.css('Product Description Name').first.content, @successful_booking.product_name
    end
  end

  context "#product_date" do
    should "return a product date from the xml" do
      assert_equal @success_xml_doc.css('Product ServiceStartDate').first.content, @successful_booking.product_date
    end
  end

  context "#formatted_product_date" do
    should "return a formatted product date when the xml date is valid" do
      assert_equal '04/21/2012', @successful_booking.formatted_product_date
    end

    should "return a blank string when the xml date is invalid" do
      @successful_booking.stubs(:product_date).returns("not a valid date")
      assert_equal '', @successful_booking.formatted_product_date
    end
  end

  context "#subproduct_name" do
    should "return the subproduct name from the xml" do
      assert_equal @success_xml_doc.css('SubProduct Description Name').first.content, @successful_booking.subproduct_name
    end
  end

  context "#total_charges" do
    should "return TotalCharges from the xml" do
      assert_equal @success_xml_doc.css('TotalCharges').first.content, @successful_booking.total_charges
    end
  end

  context "#confirmation_number" do
    should "return VendorConfirmationNumber from the xml" do
      assert_equal @success_xml_doc.css('VendorConfirmationNumber').first.content, @successful_booking.confirmation_number
    end
  end

  context "#passengers" do
    should "return array of hashes of travelers from the xml" do
      travelers = @success_xml_doc.css('Travelers Person')
      assert_equal travelers.size, @successful_booking.passengers.size
      travelers.each_with_index do |node, i|
        p = @successful_booking.passengers[i]
        assert_equal %w(Title FirstName MiddleName LastName).map{|e| node.css(e).first.try(:content)}.join(' ').squeeze(' '), p.name
        assert_equal node.css('PersonAddress Address1').first.try(:content), p.address1
        assert_equal node.css('PersonAddress Address2').first.try(:content), p.address2
        assert_equal node.css('PersonAddress City Name').first.try(:content), p.locality
        assert_equal node.css('PersonAddress State Code').first.try(:content), p.region
        assert_equal node.css('PersonAddress PostalCode').first.try(:content), p.postal_code
        assert_equal node.css('PersonAddress Country Code').first.try(:content), p.country_code
        assert_equal Time.parse(node.css('BirthDate').first.try(:content)), p.birth_date
        assert_equal node.css('Citizenship').first.try(:content), p.citizenship
      end
    end
  end

  context "#next_steps" do
    should "return the advisories from the xml" do
      text = (<<EOF
Next Steps: Go to the cruise line website using your name, confirmation number and sailing date and:
Register in the cruise line website
View your current reservation
Prepare for your vacation with cruising FAQs
Look for more exciting information
EOF
      ).chomp

      html = (<<EOF
<p><strong>Next Steps:</strong><br />Go to the <a href="www.royalcaribbean.com">cruise line website</a> using your name, confirmation number and sailing date and:</p><div><ol><li>Register in the cruise line website</li><li>View your current reservation</li><li>Prepare for your vacation with cruising FAQs</li><li>Look for more exciting information</li></ol></div>
EOF
      ).chomp

      assert_equal text, @successful_booking.next_steps.text
      assert_similar_html html, @successful_booking.next_steps.html
    end
  end

  context "#book_transaction" do
    setup do
      @mock_purchase = mock('purchase')
      @mock_book_transaction = mock("book_transaction")
      @successful_booking.stubs(:book_transaction_id).returns(123)
      @successful_booking.stubs(:book_transaction_xml).returns(@success_xml)
      @successful_booking.stubs(:daily_deal_purchase).returns(@mock_purchase)
    end

    should "return a new Travelsavers::BookTransaction from the current xml" do
      @successful_booking.stubs(:new_book_transaction).with(@success_xml, 123, @mock_purchase).returns(@mock_book_transaction)
      assert_equal @mock_book_transaction, @successful_booking.book_transaction
    end

    should "return local cached copy on subsequent calls" do
      @successful_booking.expects(:new_book_transaction).once.returns(@mock_book_transaction)
      2.times{ assert_equal @mock_book_transaction, @successful_booking.book_transaction }
    end

    should "return fresh copy when true is passed" do
      @successful_booking.expects(:new_book_transaction).twice.returns(@mock_book_transaction)
      2.times{ @successful_booking.book_transaction(true) }
    end
  end

  context "#sync_with_travelsavers!" do
    setup do
      @successful_booking.stubs(:retrieve_book_transaction)
      @successful_booking.stubs(:book_transaction_status_changed?)
      @successful_booking.stubs(:needs_manual_review?).returns(false)
      @successful_booking.stubs(:sold_out?).returns(false)
    end

    should "retrieve the book transaction" do
      @successful_booking.expects(:retrieve_book_transaction)
      @successful_booking.stubs(:after_sync_with_travelsavers)
      @successful_booking.sync_with_travelsavers!
    end

    context "#mark_sold_out!" do
      setup do
        @daily_deal = mock('daily_deal')
        @daily_deal_variation = mock('daily deal variation')
        @successful_booking.stubs(:daily_deal).returns(@daily_deal)
        @successful_booking.stubs(:daily_deal_variation).returns(nil)
      end

      should "mark the daily deal as sold out" do
        @successful_booking.stubs(:sold_out?).returns(true)
        @daily_deal.expects(:sold_out!).with(true)
        @successful_booking.send(:mark_sold_out!)
      end

      should "mark the daily deal variation as sold out" do
        @successful_booking.stubs(:daily_deal_variation).returns(@daily_deal_variation)
        @successful_booking.stubs(:sold_out?).returns(true)
        @daily_deal_variation.expects(:sold_out!).with(true)
        @successful_booking.send(:mark_sold_out!)
      end
    end

    context "#after_sync_with_travelsavers" do
      setup do
        @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
        @booking.stubs(:notify_exceptional_when_price_mismatch_error!)
        @booking.stubs(:has_unfixable_errors?).returns(false)
      end

      should "call mark_sold_out! if the booking transaction has a sold out error" do
        @booking.stubs(:has_sold_out_error?).returns(true)
        @booking.expects(:mark_sold_out!)
        @booking.send(:after_sync_with_travelsavers)
      end

      should "not call mark_sold_out!" do
        @booking.stubs(:has_sold_out_error?).returns(false)
        @booking.expects(:mark_sold_out!).never
        @booking.send(:after_sync_with_travelsavers)
      end

    end

    context "book transaction status changed" do

      setup do
        @successful_booking.stubs(:book_transaction_status_changed?).returns(true)
        mock_book_transaction = mock("book transaction", :xml_source => "xml")
        @successful_booking.stubs(:retrieve_book_transaction).returns(mock_book_transaction)
        @successful_booking.stubs(:update_from_xml!)
        @successful_booking.stubs(:notify_exceptional_when_price_mismatch_error!)
        @successful_booking.stubs(:unfixable_errors)
        @successful_booking.stubs(:has_sold_out_error?).returns(false)
      end

      should "update the booking xml" do
        @successful_booking.expects(:update_from_xml!).with("xml")
        @successful_booking.sync_with_travelsavers!
      end

      should "notify Exceptional on a price mismatch error" do
        @successful_booking.expects(:notify_exceptional_when_price_mismatch_error!)
        @successful_booking.sync_with_travelsavers!
      end

    end

    context "book transaction status did not change" do
      should "not update the booking xml" do
        @successful_booking.stubs(:book_transaction_status_changed?).returns(false)
        @successful_booking.expects(:update_from_xml!).never
        @successful_booking.stubs(:after_sync_with_travelsavers)
        @successful_booking.sync_with_travelsavers!
      end
    end

  end

  context "#update_from_xml! (private method)" do
    setup do
      @success_xml = "some xml"
      @successful_booking.stubs(:new_record?).returns(false)
      @successful_booking.stubs(:book_transaction_xml=)
      @successful_booking.stubs(:service_start_date=)
      @successful_booking.stubs(:service_end_date=)
      @successful_booking.stubs(:book_transaction).returns(stub_everything)
      @successful_booking.stubs(:transition_to)
      @successful_booking.stubs(:save!)
    end

    should "raise an exception for a new record" do
      @successful_booking.stubs(:new_record?).returns(true)
      e = assert_raise Exception do
        @successful_booking.send(:update_from_xml!, @success_xml)
      end
      assert_equal "can't be called on a new record", e.message
    end

    should "set the :book_transaction_xml attribute" do
      @successful_booking.expects(:book_transaction_xml=).with(@success_xml)
      @successful_booking.send(:update_from_xml!, @success_xml)
    end

    should "reload the book_transaction" do
      @successful_booking.expects(:book_transaction).with(true)
      @successful_booking.send(:update_from_xml!, @success_xml)
    end

    should "transition to the new booking/payment status" do
      mock_book_transaction = mock("book transaction",
                                   :booking_status => "success",
                                   :payment_status => "pending",
                                   :service_start_date => nil,
                                   :service_end_date => nil)
      @successful_booking.stubs(:book_transaction).returns(mock_book_transaction)
      @successful_booking.expects(:transition_to).with(:booking_success_payment_pending)
      @successful_booking.send(:update_from_xml!, @success_xml)
    end

    should "set the service start and end dates from the book_transaction" do
      service_start_date = Time.zone.now + 3.months
      service_end_date = service_start_date + 1.week
      mock_book_transaction = mock("book transaction",
                                   :booking_status => "success",
                                   :payment_status => "pending",
                                   :service_start_date => service_start_date,
                                   :service_end_date => service_end_date)
      @successful_booking.stubs(:book_transaction).returns(mock_book_transaction)
      @successful_booking.expects(:transition_to).with(:booking_success_payment_pending)
      @successful_booking.expects(:service_start_date=).with(service_start_date)
      @successful_booking.expects(:service_end_date=).with(service_end_date)
      @successful_booking.send(:update_from_xml!, @success_xml)
    end

    should "save!" do
      @successful_booking.expects(:save!)
      @successful_booking.send(:update_from_xml!, @success_xml)
    end
  end

  context "notify_exceptional_when_price_mismatch_error!" do
    setup do
      @mock_book_transaction = stub("book transaction", :price_mismatch_error => nil)
      mock_purchase = stub("daily deal purchase", :daily_deal_id => "12345")
      @successful_booking.stubs(:book_transaction).returns(@mock_book_transaction)
      @successful_booking.stubs(:daily_deal_purchase).returns(mock_purchase)
    end

    should "notify Exceptional when price mismatch error" do
      mock_booking_error = mock('booking error')
      @mock_book_transaction.stubs(:price_mismatch_error).returns(mock_booking_error)
      @successful_booking.expects(:notify_exceptional).with(mock_booking_error, "ALERT! Price for deal 12345 does not match price in Travelsavers system. Fix this immediately!")
      @successful_booking.send(:notify_exceptional_when_price_mismatch_error!)
    end

    should "not notify Exceptional unless price mismatch error" do
      @successful_booking.expects(:notify_exceptional).never
      @successful_booking.send(:notify_exceptional_when_price_mismatch_error!)
    end
  end

  context "#notify_about_payment_failure!" do
    should "call #deliver_payment_failure_email! if beyond polling limit " do
      @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
      Timecop.freeze do
        @booking.stubs(:booking_updated_after_polling_timeout?).returns(true)
        @booking.expects(:deliver_payment_failure_email!)
        @booking.send(:notify_about_payment_failure!)
      end
    end

    should "call #deliver_payment_failure_email! if within polling limit" do
      @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
      Timecop.freeze do
        @booking.stubs(:booking_updated_after_polling_timeout?).returns(false)
        @booking.expects(:deliver_payment_failure_email!)
        @booking.send(:notify_about_payment_failure!)
      end
    end
  end

  context "#notify_about_booking_failure!" do
    should "call #deliver_booking_failure_email! if beyond polling limit " do
      @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
      Timecop.freeze do
        @booking.stubs(:booking_updated_after_polling_timeout?).returns(true)
        @booking.expects(:deliver_booking_failure_email!)
        @booking.send(:notify_about_booking_failure!)
      end
    end

    should "not call #deliver_booking_failure_email! if within polling limit" do
      @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
      Timecop.freeze do
        @booking.stubs(:booking_updated_after_polling_timeout?).returns(false)
        @booking.expects(:deliver_booking_failure_email!).never
        @booking.send(:notify_about_booking_failure!)
      end
    end
  end

  context "#deliver_booking_failure_email!!" do
    setup do
      @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
    end

    context "user-fixable error" do
      should "deliver a user-fixable booking error email" do
        @booking.stubs(:is_fixable_by_user?).returns(true)
        @booking.stubs(:has_user_fixable_cc_errors?).returns(false)
        @booking.expects(:deliver_user_fixable_booking_error!)
        @booking.expects(:deliver_non_user_fixable_booking_error!).never
        @booking.deliver_booking_failure_email!
      end
    end

    context "non-user-fixable error" do
      should "deliver the non-user-fixable booking error email" do
        @booking.stubs(:is_fixable_by_user?).returns(false)
        @booking.expects(:deliver_non_user_fixable_booking_error!)
        @booking.expects(:deliver_user_fixable_booking_error!).never
        @booking.deliver_booking_failure_email!
      end
    end
  end

  context "#deliver_non_user_fixable_booking_error!" do
    setup do
      @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
    end

    should "deliver a sold out error" do

      @booking.stubs(:has_sold_out_error?).returns(true)

      @booking.expects(:deliver_deal_sold_out_booking_error!)
      @booking.deliver_non_user_fixable_booking_error!
    end

    should "deliver a generic error" do
      @booking.stubs(:has_sold_out_error?).returns(false)

      @booking.expects(:deliver_generic_non_user_fixable_booking_error!)
      @booking.deliver_non_user_fixable_booking_error!

    end
  end

  context "#is_fixable_by_user?" do
    setup do
      @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
    end

    should "return true if there are no unfixable errors" do
      unfixable_errors = []
      @booking.stubs(:unfixable_errors).returns(unfixable_errors)
      assert @booking.is_fixable_by_user?
    end

    should "return false if there are any non-user-fixable errors" do
      unfixable_errors = [mock('an error'), mock('another error')]
      @booking.stubs(:unfixable_errors).returns(unfixable_errors)
      assert !@booking.is_fixable_by_user?
    end
  end

  context "#handle_invalid_transition!" do
    setup do
      @mock_exception = mock("StateMachine::InvalidTransition")
      @booking = Object.new.extend(TravelsaversBookings::Core::InstanceMethods)
    end

    context "when not flagged for review" do
      setup do
        @booking.stubs(:needs_manual_review?).returns(false)
      end

      should "flag the booking for review" do
        @booking.stubs(:deliver_invalid_transition_notification!)
        @booking.expects(:flag_for_manual_review!)
        @booking.handle_invalid_transition!(@mock_exception)
      end

      should "deliver a notification" do
        @booking.expects(:deliver_invalid_transition_notification!)
        @booking.stubs(:flag_for_manual_review!)
        @booking.handle_invalid_transition!(@mock_exception)
      end
    end

    context "when already flagged for review" do
      should "not deliver a notification or flag for review" do
        @booking.stubs(:needs_manual_review?).returns(true)
        @booking.expects(:deliver_invalid_transition_notification!).never
        @booking.expects(:flag_for_manual_review!).never
        @booking.handle_invalid_transition!(@mock_exception)
      end
    end
  end
end
