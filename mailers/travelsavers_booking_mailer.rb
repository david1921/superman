class TravelsaversBookingMailer < ApplicationMailer

  include ActionView::Helpers::NumberHelper

  def payment_failed(booking)
    from support_sending_email_address(booking.publisher)
    recipients booking.consumer.email
    subject Analog::Themes::I18n.t(booking.publisher, "travelsavers_booking_mailer.subjects.could_not_process_booking", :brand_name => brand_name(booking.publisher))
    body :customer_service_number => number_to_phone(TravelsaversBooking::CUSTOMER_SERVICE_NUMBER, :area_code => true)
  end

  def unresolved_booking(booking)
    from support_sending_email_address(booking.publisher)
    recipients booking.consumer.email
    subject Analog::Themes::I18n.t(booking.publisher, "travelsavers_booking_mailer.unresolved_booking.subject", :brand_name => brand_name(booking.publisher))
  end

  def user_fixable_booking_error(booking)
    from support_sending_email_address(booking.publisher)
    recipients booking.consumer.email
    brand_name = brand_name(booking.publisher)
    subject Analog::Themes::I18n.t(booking.publisher, "travelsavers_booking_mailer.subjects.could_not_process_booking", :brand_name => brand_name)
    body :brand_name => brand_name, :booking => booking
  end

  def user_fixable_credit_card_errors(booking)
    unless booking.has_user_fixable_cc_errors?
      raise ArgumentError, "can't deliver user fixable credit card errors notification for " +
                           "TravelsaversBooking #{booking.id}: this booking has no user fixable " +
                           "credit card errors"
    end
    recipients booking.consumer.email
    from support_sending_email_address(booking.publisher)
    subject "Regarding Your Recent #{brand_name(booking.publisher)} Booking"
    body :booking => booking
  end

  def deal_sold_out_booking_error(booking)
    from support_sending_email_address(booking.publisher)
    recipients booking.consumer.email
    brand_name = brand_name(booking.publisher)
    subject Analog::Themes::I18n.t(booking.publisher, "travelsavers_booking_mailer.subjects.could_not_process_booking", :brand_name => brand_name)
    body :brand_name => brand_name, :booking => booking
  end

  def non_user_fixable_booking_error(booking)
    from support_sending_email_address(booking.publisher)
    recipients booking.consumer.email
    brand_name = brand_name(booking.publisher) || "Deal of the Day"
    subject Analog::Themes::I18n.t(booking.publisher, "travelsavers_booking_mailer.subjects.could_not_process_booking", :brand_name => brand_name)
    body :brand_name => brand_name, :booking => booking
  end

  private

  def brand_name(publisher)
    brand_name = publisher.daily_deal_brand_name.present? ? publisher.daily_deal_brand_name : "Deal of the Day"
  end

  def unfixable_error_internal_notification(booking)
    unless booking.has_unfixable_errors?
      raise ArgumentError, "can't deliver unfixable error internal notification for TravelsaversBooking #{booking.id}: this booking has no unfixable errors"
    end
    recipients TravelsaversConfig.internal_notification_recipients
    from AppConfig.internal_notification_from_address
    subject "[#{Rails.env}] TravelsaversBooking #{booking.id}: Error - Action Required"
    body :booking => booking
  end

  def invalid_transition_internal_notification(booking, invalid_transition_exception)
    recipients TravelsaversConfig.internal_notification_recipients
    from AppConfig.internal_notification_from_address
    subject "[#{Rails.env}] TravelsaversBooking #{booking.id}: Invalid Transition - Action Required"
    body :booking => booking, :exception => invalid_transition_exception
  end

  def booking_unresolved_after_24_hours_internal_notification(booking)
    if booking.resolved?
      raise ArgumentError, "can't call booking_unresolved_after_24_hours_internal_notification with a resolved booking"
    end

    unless booking.unresolved_for_over_24_hours?
      raise ArgumentError, "can't call booking_unresolved_after_24_hours_internal_notification with a booking that has been unresolved for less than 24 hours"
    end

    recipients TravelsaversConfig.internal_notification_recipients
    from AppConfig.internal_notification_from_address
    subject "[#{Rails.env}] TravelsaversBooking #{booking.id}: Unresolved - Action Required"
    body :booking => booking
  end

end
