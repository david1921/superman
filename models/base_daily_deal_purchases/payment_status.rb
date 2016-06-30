module BaseDailyDealPurchases::PaymentStatus
  include BaseDailyDealPurchases::CreateAndSendCertificates

  ALLOWED_TRANSITIONS = {
    "pending"    => %w{ authorized captured },
    "authorized" => %w{ captured voided refunded },
    "captured"   => %w{ voided refunded reversed },
    "voided"     => %w{ captured },
    "refunded"   => %w{ refunded }, # partial refunds mean that purchases can be refunded more than once
    "reversed"   => %w{ captured }, # PayPal chargeback reversal
  }

  TRANSITION_CONSTRAINTS = [
    { :from => "authorized", :to =>  "refunded", :check => :travelsavers? }
  ]

  def set_payment_status!(new_payment_status)
    where = "#{inspect}#set_payment_status!(#{new_payment_status})"

    if new_payment_status != payment_status || payment_status == "refunded"
      raise "Unknown payment status #{payment_status} in #{where}" unless ALLOWED_TRANSITIONS.has_key?(payment_status)
      raise "Bad #{payment_status} -> #{new_payment_status} in #{where}" unless allow_transition_to?(new_payment_status)
      self.payment_status = new_payment_status
      self.payment_status_updated_at = Time.zone.now
      save!

      after_executed if executed?
      after_captured if captured?
      after_authorized if authorized?
      after_refunded if refunded?
      after_voided if voided?
    else
      save!
    end
  end

  def pending?
    "pending" == payment_status
  end

  def executed?
    "pending" != payment_status
  end

  def authorized?
    "authorized" == payment_status
  end

  def captured?
    "captured" == payment_status
  end

  def voided?
    "voided" == payment_status
  end

  def refunded?
    "refunded" == payment_status
  end

  def void!
    set_payment_status! "voided"
  end


  private

  def allow_transition_to?(new_payment_status)
    allowed_target_state?(new_payment_status) && constraints_satisified_for_transition_to?(new_payment_status)
  end

  def allowed_target_state?(target_state)
    ALLOWED_TRANSITIONS[payment_status].include?(target_state)
  end

  def constraints_satisified_for_transition_to?(target_state)
    constraint = TRANSITION_CONSTRAINTS.find { |tc| tc[:from] == payment_status && tc[:to] == target_state }
    if constraint.present?
      raise "constraint :check must be a symbol" unless constraint[:check].is_a?(Symbol)
      send(constraint[:check])
    else
      true
    end
  end

  def after_executed
    begin
      #need to override validation because consumers were created before
      #billing address was required or at presignup
      consumer_daily_deal_purchase_executed!
      update_sold_out_at
    rescue Exception => e
      logger.error "after_executed failed for purchase #{uuid} CAUSE: #{e}"
      raise e
    end
  end

  def after_captured
    begin
      create_promotion_discount if respond_to?(:create_promotion_discount)
      create_certificates_and_send_email! if daily_deal_certificates(true).empty?
      daily_deal_certificates.each(&:activate!) # necessary because void -> captured is an allowed transition
      consumer_daily_deal_purchase_captured!
    rescue Exception => e
      logger.error "after_captured failed for purchase #{uuid} CAUSE: #{e}"
      raise e
    end
  end

  def after_authorized
    begin
      create_promotion_discount if respond_to?(:create_promotion_discount)
      create_certificates_and_send_email! if daily_deal_certificates(true).empty?
      daily_deal_certificates.each(&:activate!) # necessary because void -> captured is an allowed transition
      consumer_daily_deal_purchase_captured!
    rescue Exception => e
      logger.error "after_captured failed for purchase #{uuid} CAUSE: #{e}"
      raise e
    end
  end

  def after_refunded
    if travelsavers?
      travelsavers_booking.cancel_if_not_already_canceled!
    end

    if total_paid == refund_amount
      daily_deal_certificates.each(&:refund!)
    end
  end

  def after_voided
    if travelsavers?
      travelsavers_booking.cancel_if_not_already_canceled!
    end

    daily_deal_certificates.each(&:void!)
  end

  def update_sold_out_at
    deal_or_variation = respond_to?(:daily_deal_variation_or_daily_deal) ? daily_deal_variation_or_daily_deal : daily_deal
    deal_or_variation.sold_out! if deal_or_variation.present?
  end

  def consumer_daily_deal_purchase_executed!
    respond_to?(:consumer) && consumer && consumer.daily_deal_purchase_executed!(self)
  end

  def consumer_daily_deal_purchase_captured!
    respond_to?(:consumer) && consumer && consumer.daily_deal_purchase_captured!(self)
  end

end
