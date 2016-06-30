module TravelsaversBookings
  module Core

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module InstanceMethods

      def doc
        @doc ||= Nokogiri::XML(book_transaction_xml)
      end

      def product_name
        doc.css('Product Description Name').first.try(:content)
      end

      def provider_name
        doc.css('Product VendorName').first.try(:content)
      end

      def product_date
        doc.css('Product ServiceStartDate').first.try(:content)
      end

      def formatted_product_date
        Date.parse(product_date).try(:strftime, "%m/%d/%Y") rescue ''
      end

      def subproduct_name
        doc.css('SubProduct Description Name').first.try(:content)
      end

      def total_charges
        doc.css('TotalCharges').first.try(:content)
      end

      def confirmation_number
        doc.css('VendorConfirmationNumber').first.try(:content)
      end

      def passengers
        doc.css('Travelers Person').map do |node|
          OpenStruct.new(
              :name => %w(Title FirstName MiddleName LastName).map { |e| node.css(e).first.try(:content) }.join(' ').squeeze(' '),
              :address1 => node.css('PersonAddress Address1').first.try(:content),
              :address2 => node.css('PersonAddress Address2').first.try(:content),
              :locality => node.css('PersonAddress City Name').first.try(:content),
              :region => node.css('PersonAddress State Code').first.try(:content),
              :postal_code => node.css('PersonAddress PostalCode').first.try(:content),
              :country_code => node.css('PersonAddress Country Code').first.try(:content),
              :birth_date => Time.parse(node.css('BirthDate').first.try(:content)),
              :citizenship => node.css('Citizenship').first.try(:content)
          )
        end
      end

      def next_steps
        advisories = doc.css('ProductAdvisory')
        text = (x = advisories.find { |node| node.css('Format').first.try(:content) == "Text" }) && x.css('Message').first.try(:content)
        html = (y = advisories.find { |node| node.css('Format').first.try(:content) == "HTML" }) && y.css('Message').first.try(:content)
        OpenStruct.new(:text => text, :html => html)
      end

      def sync_with_travelsavers!
        if needs_manual_review?
          raise "Can't call sync_with_travelsavers! on TravelsaversBooking #{id} " +
                "because this booking has been flagged for manual review"
        end

        book_transaction_from_ts = retrieve_book_transaction
        if book_transaction_status_changed?(book_transaction_from_ts)
          update_from_xml!(book_transaction_from_ts.xml_source)
        end
        after_sync_with_travelsavers
      end

      def book_transaction(force_reload=false)
        unless @book_transaction && !force_reload
          @book_transaction = new_book_transaction(book_transaction_xml, book_transaction_id, daily_deal_purchase)
        end
        @book_transaction
      end

      def flag_for_manual_review!
        self.needs_manual_review = true
        save! 
      end

      def flag_for_manual_review_and_send_internal_notification!
        flag_for_manual_review!
        TravelsaversBookingMailer.deliver_booking_unresolved_after_24_hours_internal_notification(self)
      end

      def notify_about_payment_failure!
        deliver_payment_failure_email!
      end

      def notify_about_booking_failure!
        if booking_updated_after_polling_timeout?
          deliver_booking_failure_email!
        end
      end

      def deliver_booking_failure_email!
        if is_fixable_by_user?
          if has_user_fixable_cc_errors?
            deliver_user_fixable_credit_card_errors!
          else
            deliver_user_fixable_booking_error!
          end
        else
          deliver_non_user_fixable_booking_error!
        end
      end

      def handle_invalid_transition!(invalid_transition_exception)
        unless needs_manual_review?
          flag_for_manual_review!
          deliver_invalid_transition_notification!(invalid_transition_exception)
        end
      end

      def deliver_non_user_fixable_booking_error!
        if has_sold_out_error?
          deliver_deal_sold_out_booking_error!
        else  
          deliver_generic_non_user_fixable_booking_error!
        end
      end

      def deliver_deal_sold_out_booking_error!
        TravelsaversBookingMailer.deliver_deal_sold_out_booking_error(self)
      end

      def deliver_generic_non_user_fixable_booking_error!
        TravelsaversBookingMailer.deliver_non_user_fixable_booking_error(self)
      end

      def is_fixable_by_user?
        unfixable_errors.empty?
      end

      def has_unfixable_errors?
        unfixable_errors.present?
      end

      private

      def update_from_xml!(new_book_transaction_xml)
        raise Exception.new("can't be called on a new record") if new_record?

        self.book_transaction_xml = new_book_transaction_xml
        book_transaction(true)
        self.service_start_date = book_transaction.service_start_date
        self.service_end_date = book_transaction.service_end_date
        transition_to(:"booking_#{book_transaction.booking_status}_payment_#{book_transaction.payment_status}")
        save!
      end

      def mark_sold_out!
        (self.daily_deal_variation || self.daily_deal).sold_out!(true)
      end

      def retrieve_book_transaction
        Travelsavers::BookTransaction.get(book_transaction_id, self)
      end

      def after_sync_with_travelsavers
        notify_exceptional_when_price_mismatch_error!
        if has_unfixable_errors?
          flag_for_manual_review!
          deliver_unfixable_errors_internal_notification!
        end
        mark_sold_out! if has_sold_out_error?
      end

      def book_transaction_status_changed?(book_transaction)
        (self.booking_status != book_transaction.booking_status) || (self.payment_status != book_transaction.payment_status)
      end

      def new_book_transaction(*args)
        Travelsavers::BookTransaction.new(*args)
      end

      def notify_exceptional_when_price_mismatch_error!
        if book_transaction.price_mismatch_error
          notify_exceptional(book_transaction.price_mismatch_error, "ALERT! Price for deal #{daily_deal_purchase.daily_deal_id} does not match price in Travelsavers system. Fix this immediately!")
        end
      end

      def deliver_unfixable_errors_internal_notification!
        TravelsaversBookingMailer.deliver_unfixable_error_internal_notification(self)
      end

      def notify_exceptional(exception, msg)
        Exceptional.handle(exception, msg)
      end

      def deliver_payment_failure_email!
        TravelsaversBookingMailer.deliver_payment_failed!(self)
      end

      def deliver_user_fixable_booking_error!
        TravelsaversBookingMailer.deliver_user_fixable_booking_error(self)
      end

      def deliver_user_fixable_credit_card_errors!
        TravelsaversBookingMailer.deliver_user_fixable_credit_card_errors(self)
      end

      def deliver_invalid_transition_notification!(invalid_transition_exception)
        TravelsaversBookingMailer.deliver_invalid_transition_internal_notification(self, invalid_transition_exception)
      end

      def booking_updated_after_polling_timeout?
        Time.zone.now >= (updated_at + TravelsaversBooking::BROWSER_POLLING_TIME_LIMIT)
      end
    end


    module ClassMethods
      def create_or_reset_with_new_transaction_id!(ts_transaction_id, purchase_uuid)
        purchase = DailyDealPurchase.find_by_uuid!(purchase_uuid)
        booking = purchase.travelsavers_booking
        if booking
          booking.book_transaction_xml = nil
          booking.book_transaction_id = ts_transaction_id
          booking.transition_to(:booking_nil_payment_nil)
          booking
        else
          create!(
              :daily_deal_purchase => purchase,
              :book_transaction_id => ts_transaction_id
          )
        end
      end
    end
  end
end
