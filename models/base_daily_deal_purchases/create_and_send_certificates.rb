module BaseDailyDealPurchases::CreateAndSendCertificates

  def create_certificates_and_send_email!
    create_certificates!
    enqueue_email if should_send_email?
    post_to_facebook!
  end

  def create_certificates!
    if daily_deal.using_internal_serial_numbers?
      create_certificates_with_internal_serial_numbers!
    else
      create_certificates_with_third_party_serial_numbers_and_possibly_mark_deal_soldout!
    end
  end

  def send_email!(options = {})
    return if self.certificate_email_sent_at.present? && !options[:force]

    if travelsavers?
      DailyDealPurchaseMailer.deliver_confirmation(self)
    else
      DailyDealMailer.deliver_purchase_confirmation_with_certificates(self)
    end

    self.certificate_email_sent_at = Time.zone.now unless self.certificate_email_sent_at.present?
    save!
  end

  def should_send_email?
    !is_off_platform_purchase?
  end

  private

  def enqueue_email
    Resque.enqueue(SendCertificates, self.id)
  end

  def create_certificates_with_internal_serial_numbers!
    create_number_of_certificates_equal_to_purchase_quantity_times_voucher_multiple!
  end

  def create_certificates_with_third_party_serial_numbers_and_possibly_mark_deal_soldout!
    serial_num_response = get_third_party_serial_numbers_and_possibly_mark_deal_soldout!
    create_number_of_certificates_equal_to_purchase_quantity_times_voucher_multiple! :third_party_serial_numbers => serial_num_response.serial_numbers
  end

  def create_number_of_certificates_equal_to_purchase_quantity_times_voucher_multiple!(options = {})
    return 0 if daily_deal_certificates.present?

    third_party_serial_numbers = options[:third_party_serial_numbers]
    if third_party_serial_numbers.present? && third_party_serial_numbers.length != total_certificates_to_generate
      raise ArgumentError, "number third party serial numbers must match purchase quantity. " +
                           "expected #{quantity}, got #{third_party_serial_numbers.length}"
    end

    total_purchase_price_allocated_to_certs = 0
    total_certificates_to_generate.times do |i|
      amount_left = if actual_purchase_price > total_purchase_price_allocated_to_certs
        actual_purchase_price - total_purchase_price_allocated_to_certs
      else
        0
      end

      cert_purchase_price = if generating_last_certificate?(i)
        amount_left
      else
        [individual_certificate_value, amount_left].min
      end

      common_cert_attrs = {
          :actual_purchase_price => cert_purchase_price,
          :redeemer_name => next_redeemer_name(i),
          :bar_code => daily_deal_variation_or_daily_deal.bar_coded? ? daily_deal_variation_or_daily_deal.assign_bar_code : nil,
          :daily_deal_purchase => self
      }

      if third_party_serial_numbers.present?
        daily_deal_certificates.create!(common_cert_attrs.merge(
          :serial_number => third_party_serial_numbers.shift,
          :serial_number_generated_by_third_party => true
        ))
      else
        daily_deal_certificates.create!(common_cert_attrs)
      end
      total_purchase_price_allocated_to_certs += cert_purchase_price
    end
  end

  def next_redeemer_name(i)
    return consumer.name unless recipient_names.present?
    return consumer.name unless recipient_names[i].present?
    recipient_names[i]
  end
  
  def individual_certificate_value
    (price / certificates_to_generate_per_unit_quantity).round(2)
  end
  
  def generating_last_certificate?(idx)
    (idx + 1) == total_certificates_to_generate
  end
  
  def total_certificates_to_generate
    quantity * certificates_to_generate_per_unit_quantity
  end

  def post_to_facebook!
    begin
      post_purchase_to_fb_wall if post_to_facebook?
    rescue Exception => e
      logger.error "#{e} #{e.backtrace.join(' ')}"
    end
  end

  def is_off_platform_purchase?
    !is_a?(DailyDealPurchase)
  end

end
