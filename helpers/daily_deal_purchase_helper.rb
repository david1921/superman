module DailyDealPurchaseHelper

  def name_on_certificate(daily_deal_purchase)
    translate_scope = [:daily_deal_purchase_helper, :name_on_certificate]

    if daily_deal_purchase.gift
      names = daily_deal_purchase.recipient_names.uniq.map { |name| "<strong>#{name}</strong>" }

      what = t(1 < names.size ? 'one_of_the_recipients_names' : 'the_reipients_name', :scope => translate_scope)

      list = names.to_sentence(:two_words_connector => t('two_words_connector', :scope => translate_scope),
                               :last_word_connector => t('last_word_connector', :scope => translate_scope))
      "#{what}, #{list}"
    else
      t('your_name', :name => daily_deal_purchase.consumer.name, :scope => translate_scope)
    end
  end
  
  def voucher_redeemed_on(voucher)
    if voucher.redeemed?
      voucher.humanize_redeemed_at
    elsif voucher.marked_used_by_user?
      "N/A"
    else
      nil
    end
  end

  def voucher_refunded_on(voucher)
    voucher.refunded? ? voucher.humanize_refunded_at : nil
  end
  
  def travelsavers_booking_refunded_on(booking)
    booking.refunded? ? booking.daily_deal_purchase.humanize_refunded_at : nil
  end

  def your_certificates(daily_deal_purchase)
    translate_scope = [:daily_deal_purchase_helper, :certificate_subject]
    t(daily_deal_purchase.quantity > 1 ? 'plural' : 'singular', :scope => translate_scope)
  end
  
  def daily_deal_purchase_location(daily_deal_purchase)
    if daily_deal_purchase.store.present?
      " at #{daily_deal_purchase.store.summary}"
    end
  end

  def purchase_review_message(daily_deal_purchase)
    translate_scope = [:daily_deal_purchase_helper, :purchase_review_message]

    certificate_pronoun = daily_deal_purchase.quantity > 1 ?
      t('certificate_pronoun.plural', :scope => translate_scope) :
      t('certificate_pronoun.singular', :scope => translate_scope)

    certificates = daily_deal_purchase.quantity > 1 ?
      t('certificate', :scope => translate_scope) :
      t('certificates', :scope => translate_scope)

    t 'all',
      :scope => translate_scope,
      :certificates => '<strong>' + certificates  + '</strong>',
      :certificate_pronoun => certificate_pronoun,
      :line_item_name => '<strong>' + daily_deal_purchase.line_item_name + '</strong>',
      :location => daily_deal_purchase_location(daily_deal_purchase),
      :certificate_subject => your_certificates(daily_deal_purchase),
      :name_on_certificate => name_on_certificate(daily_deal_purchase),
      :email => "<strong>#{daily_deal_purchase.consumer.email}</strong>"
  end

  def purchase_thank_you_message(daily_deal_purchase)
    translate_scope = [:daily_deal_purchase_helper, :purchase_thank_you_message]

    certificates = daily_deal_purchase.quantity > 1 ?
      t('certificates', :scope => translate_scope) :
      t('certificate', :scope => translate_scope)

    t 'all',
      :scope => translate_scope,
      :certificates => certificates,
      :my_deals_link => link_to(t('my_deals'), daily_deal_download_url(daily_deal_purchase), :class => "popout")
  end
  
  def attempted_to_register?
    params[:consumer].present?
  end
  
  def full_error_messages_on(obj, field_name)
    obj.errors.on(field_name).map { |e| "#{field_name.to_s.humanize} #{e}" }.join(". ")
  rescue
    ""
  end
  
  def daily_deal_download_url(daily_deal_purchase, options={})
    publisher, consumer = daily_deal_purchase.publisher, daily_deal_purchase.consumer
    publisher_consumer_daily_deal_purchases_url(publisher, consumer, { :host => publisher.daily_deal_host }.merge(options))
  end
  
  def daily_deal_support_url(daily_deal_purchase)
    [daily_deal_purchase.publisher.support_url, AppConfig.support_url].detect(&:present?) || "http://www.txt411.com/"
  end

  def daily_deal_sending_email_address(publisher)
    email_addr = AppConfig.email_from_address.if_present || "bbdsupport@analoganalytics.com"
    "#{publisher.name_for_daily_deals} <#{email_addr}>"
  end
  
  def print_daily_deal_purchase_link(daily_deal_purchase, class_name = nil)
    translate_scope = [:daily_deal_purchase_helper, :print_daily_deal_purchase_link]

    if daily_deal_purchase.respond_to?(:travelsavers?) && daily_deal_purchase.travelsavers? && daily_deal_purchase.captured?
      link_to(t(:resend_email), resend_email_daily_deal_purchase_path(daily_deal_purchase), :method => :post)
    elsif daily_deal_purchase.respond_to?(:has_voucher_pdf?)  && daily_deal_purchase.has_voucher_pdf?
      if daily_deal_purchase.redeemed?
        "Redeemed at #{daily_deal_purchase.redeemed_at.try(:to_s,:calendar)}"
      else
        link_to(t(:print), daily_deal_purchase.voucher_pdf.url, :target => "_blank", :class => class_name)
      end
    elsif daily_deal_purchase.respond_to?(:download_url)
      if daily_deal_purchase.redeemed?
        "Redeemed at #{daily_deal_purchase.redeemed_at.to_s(:calendar)}"
      else
        link_to(t(:print), daily_deal_purchase.download_url, :target => "_blank", :class => class_name)
      end
    elsif daily_deal_purchase.non_voucher_purchase?
      link_to(t(:view_non_voucher_redemption_page, :scope => translate_scope), non_voucher_redemption_daily_deal_purchase_url(daily_deal_purchase))
    elsif daily_deal_purchase.authorized?
      t(:needs_to_complete_payment)
    elsif daily_deal_purchase.refunded_with_active_certificates?
      t(:refunded)
    elsif daily_deal_purchase.daily_deal_certificates.active.present?
      publisher, consumer = daily_deal_purchase.publisher, daily_deal_purchase.consumer
      download_url = publisher_consumer_daily_deal_purchase_url(publisher.to_param, consumer.to_param, daily_deal_purchase.to_param, :format => :pdf)
      link_to(t(:download_to_print), download_url, :class => class_name)
    else
      daily_deal_purchase.payment_status.capitalize
    end
  end
  
  def admin_daily_deal_purchase_status_link(daily_deal_purchase)
    if !daily_deal_purchase.respond_to?(:daily_deal_certificates)
      if daily_deal_purchase.redeemed?
        return "Redeemed at #{daily_deal_purchase.redeemed_at.to_s(:calendar)}"
      else
        return "Active"
      end 
    end

    if daily_deal_purchase.daily_deal_certificates.active.present?
      publisher, consumer = daily_deal_purchase.publisher, daily_deal_purchase.consumer
      download_url = publisher_consumer_daily_deal_purchase_url(publisher.to_param, consumer.to_param, daily_deal_purchase.to_param, :format => :pdf)
      if daily_deal_purchase.refunded_with_active_certificates?
        "Refunded"
      elsif daily_deal_purchase.partially_refunded?
        link_to("Partially Refunded", download_url)
      else
        daily_deal_purchase.payment_status.capitalize
      end
    else
      daily_deal_purchase.payment_status.capitalize
    end
  end
  
  def daily_deal_purchase_store_id_options(daily_deal)
     [["Please choose a location", ""]] + daily_deal.advertiser.stores.map { |store| [ store.summary, store.id ] }
  end

  def travelsavers_booking_request_transaction_data(daily_deal_purchase)
    booking_request = Travelsavers::BookingRequestForm.new(daily_deal_purchase, handle_redirect_daily_deal_purchase_travelsavers_bookings_url(daily_deal_purchase, :protocol => ssl_rails_environment? ? "https" : "http"))
    booking_request.transaction_data
  end
  
  def paypal_buy_now_form_inputs(daily_deal_purchase, paypal_configuration)
    paypal_options = {
         :currency_code => daily_deal_purchase.publisher.currency_code,
         :cancel_return => paypal_cancel_return_url(daily_deal_purchase),
         :cpp_header_image => paypal_checkout_header_image_url(daily_deal_purchase),
         :custom => "DAILY_DEAL_PURCHASE",
         :discount_amount => daily_deal_purchase.discount_amount,
         :email => daily_deal_purchase.consumer.email,
         :invoice => daily_deal_purchase.analog_purchase_id,
         :item_name => daily_deal_purchase.line_item_name,
         :no_shipping => 2,
         :quantity => daily_deal_purchase.quantity,
         :return => paypal_return_url(daily_deal_purchase),
         :rm => 1
        }
    paypal_options.merge!(paypal_configuration.use_sandbox? ? {} : {
         :business_key => paypal_configuration.key,
         :business_cert => paypal_configuration.certificate,
         :business_certid => paypal_configuration.cert_id
        })
    paypal_options.merge!(AppConfig.respond_to?( :paypal_notify_url ) ? { :notify_url => AppConfig.paypal_notify_url } : {})

    paypal_setup(daily_deal_purchase.paypal_item, daily_deal_purchase.price, paypal_configuration.business, paypal_options)
  end
end
