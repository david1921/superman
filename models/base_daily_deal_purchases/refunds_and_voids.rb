module BaseDailyDealPurchases::RefundsAndVoids
  include ThirdPartyDealsApi::DailyDealPurchase

  def voidable_or_refundable?
    authorized? || captured? || partially_refunded?
  end

  def partially_refunded?
    refund_amount.present? && refund_amount > 0 && refund_amount < actual_purchase_price
  end

  def fully_refunded?
    refund_amount.present? && refund_amount >= actual_purchase_price
  end

  #this method indicates whether or not the purchase was refunded for
  #less than the actual purchase price - it will be treated as fully
  #refunded - also handles inconsistent data - used primarily in
  #the DailyDealPurchaseHelper.admin_daily_deal_purchase_status_link
  #and print_daily_deal_purchase_link methods
  def refunded_with_active_certificates?
    refunded_at.present? && daily_deal_certificates.active.try(:size) == quantity
  end

  def void_or_full_refund!(admin)
    sync_voucher_status_with_third_party! if has_vouchers_generated_by_third_party?
    if daily_deal_payment
      daily_deal_payment.void_or_full_refund!(admin)
    else
      void_or_full_refund_without_payment(admin)
    end
    send_third_party_voucher_change_notification_as_needed!
  end

  # Partial_refunds are treated separately from a full refund
  # so that we can track refunds at the certificate level.
  def partial_refund!(admin, certificate_ids_to_refund)
    raise "Must be captured or partially refunded to partially refund" unless captured? || partially_refunded?
    sync_voucher_status_with_third_party! if has_vouchers_generated_by_third_party?

    certificate_ids_to_refund = certificate_ids_to_refund.map(&:to_s).uniq
    certs_to_refund = daily_deal_certificates.reject(&:refunded?).select do |cert|
      certificate_ids_to_refund.include?(cert.id.to_s)
    end
    
    unless certs_to_refund.present?
      raise "None of the requested certificates could be refunded"
    end
    
    unless certs_to_refund.size.multiple_of?(certificates_to_generate_per_unit_quantity)
      raise "number of vouchers to refund (#{certs_to_refund.size}) must be a multiple of certificates_to_generate_per_unit_quantity (#{certificates_to_generate_per_unit_quantity}), " +
            "but is not"
    end
    
    total_amount_to_refund = calculate_total_partial_refund_amount(certs_to_refund)
    daily_deal_payment.partial_refund!(admin, total_amount_to_refund) if daily_deal_payment
    certs_to_refund.each do | cert |
      cert.refund!
    end
    send_third_party_voucher_change_notification_as_needed!
    { :number_of_certs_refunded => certs_to_refund.size, :amount_refunded => total_amount_to_refund }
  end

  def quantity_excluding_refunds
    if refunded_with_active_certificates?
      0
    else
      daily_deal_certificates.present? ? daily_deal_certificates.active.size : 0
    end
  end

  private

  def calculate_total_partial_refund_amount(certs_to_refund)
    amount_left_to_refund = actual_purchase_price - refund_amount
    sum_of_certs_to_refund = certs_to_refund.inject(0) { |sum, cert| sum + cert.actual_purchase_price }
    [amount_left_to_refund, sum_of_certs_to_refund].min
  end

  def void_or_full_refund_without_payment(admin)
    raise "Cannot call void_or_full_refund_without_payment on a purchase with a payment" if daily_deal_payment

    self.refunded_at = Time.zone.now
    self.refunded_by = admin.login
    if !travelsavers? || (travelsavers? && captured?)
      self.refund_amount = travelsavers? ? actual_purchase_price : 0
      set_payment_status! "refunded"
    else
      unless travelsavers? && authorized?
        raise "Error voiding purchase without payment: Expected DailyDealPurchase #{id} to be a " +
              "Travelsavers purchase in 'authorized' state, but it is not"
      end
      set_payment_status! "voided"
    end
  end

end
