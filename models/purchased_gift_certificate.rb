class PurchasedGiftCertificate < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include HasSerialNumber

  attr_writer :bought_with_shopping_cart
   
  PAYPAL_COMMON_ATTRIBUTES = "cmd=_xclick&business=#{AppConfig.paypal_business}&lc=US&currency_code=USD&no_shipping=2&quantity=1"
  belongs_to :gift_certificate

  validates_presence_of     :gift_certificate, :paypal_payment_date
  validates_presence_of     :paypal_txn_id, :paypal_invoice, :serial_number
  validates_uniqueness_of   :paypal_txn_id, :paypal_invoice, :unless => :bought_with_shopping_cart?
  validates_numericality_of :paypal_payment_gross, :greater_than_or_equal_to => 0.00, :allow_nil => false
  validates_email           :paypal_payer_email, :allow_blank => false
  with_options :if => :address_required? do |this|
    this.validates_presence_of :paypal_address_street
    this.validates_presence_of :paypal_address_city
    this.validates_presence_of :paypal_address_state
    this.validates_presence_of :paypal_address_zip
  end
  validates_inclusion_of :payment_status, :in => %w{ completed reversed refunded }, :allow_blank => false
  validates_each :paypal_payment_gross do |record, attr, value|
    if record.new_record? && value && record.gift_certificate && value != record.gift_certificate.price_with_handling_fee
      record.errors.add(attr, "%{attribute} doesn't match deal certificate price + handling fee")
    end
  end

  after_create :send_email_to_buyer
  
  named_scope :completed, lambda { |dates|
    if dates.nil?
      { :conditions => %q(purchased_gift_certificates.payment_status = 'completed') }
    else
      sql = %q(purchased_gift_certificates.payment_status = 'completed' AND purchased_gift_certificates.paypal_payment_date BETWEEN ? AND ?)
      { :conditions => [sql, dates.begin.beginning_of_day, dates.end.end_of_day] }
    end
  }
  named_scope :for_publisher, lambda { |publisher|
    { :joins => { :gift_certificate => :advertiser }, :conditions => { 'advertisers.publisher_id' => publisher.id }}
  }

  delegate :publisher, :advertiser, :physical_gift_certificate?, :collect_address?, :address_required?, :item_number, :value, :humanize_value, :price, {
    :to => :gift_certificate, :allow_nil => true
  }
  delegate :currency_code, :currency_symbol, :to => :publisher
  
  def paypal_payment_date=(value)
    write_attribute :paypal_payment_date, DateTime.strptime(value, "%H:%M:%S %b %d, %Y %Z").utc
  end

  def to_pdf
    Prawn::Document.new(:page_size => "LETTER") do |pdf|
      lay_out(:pdf_1_up, pdf)
    end.render
  end
                                             
  def self.to_pdf(purchased_gift_certificates)
    Prawn::Document.new(:page_size => "LETTER") do |pdf|
      pdf.stroke_color = "c0c0c0"
      group_index = 0
      purchased_gift_certificates.in_groups_of(3, false) do |group|
        pdf.start_new_page if group_index > 0
        group.each_with_index do |purchased_gift_certificate, i|
          pdf.bounding_box [-18, pdf.bounds.height - 252*i], :width => 576, :height => 216 do
            pdf.stroke_bounds
            purchased_gift_certificate.send(:lay_out, :pdf_3_up, pdf)
          end
        end
        group_index += 1
      end
    end.render
  end
  
  def revenue
    paypal_payment_gross
  end
  
  def send_email_to_buyer
    # Note: we deliver this email only for physical_gift_certificates.
    # We may still have collected the address.
    if physical_gift_certificate?
      GiftCertificateMailer.deliver_confirm_purchase self
    else
      GiftCertificateMailer.deliver_gift_certificate self
    end
  end
  
  def self.handle_buy_now(ipn_params)
    item_number = ipn_params['item_number']
    unless gift_certificate = GiftCertificate.find_by_item_number(item_number)
      raise "IPN item number #{item_number} doesn't match a deal certificate"
    end
    purchased_gift_certificate = build_from_ipn_params(ipn_params)
    purchased_gift_certificate.gift_certificate = gift_certificate
    purchased_gift_certificate.save!
  end
  
  def self.handle_shopping_cart_purchase(ipn_params)
    create_cert_purchased_from_shopping_cart = proc do |gross, gift_certificate|
      purchased_cert = build_from_ipn_params(ipn_params.merge("payment_gross" => gross))
      purchased_cert.bought_with_shopping_cart = true
      purchased_cert.gift_certificate = gift_certificate
      purchased_cert.save!
    end

    ipn_params.keys.grep(/^item_number(\d+)$/) do |k|
      item_number = ipn_params[k]
      quantity = ipn_params["quantity#{$1}"].to_i
      gross = ipn_params["mc_gross_#{$1}"].to_f

      unless gift_certificate = GiftCertificate.find_by_item_number(item_number)
        raise "IPN item number #{item_number} doesn't match a deal certificate"
      end
      
      if quantity == 1
        create_cert_purchased_from_shopping_cart.call(gross, gift_certificate)
      else
        quantity.times do
          create_cert_purchased_from_shopping_cart.call(gross / quantity, gift_certificate)
        end
      end
    end
  end
  
  def self.handle_chargeback(ipn_params)
    find_and_save_with_payment_status!("reversed", ipn_params)
  end

  def self.handle_chargeback_reversal(ipn_params)
    find_and_save_with_payment_status!("completed", ipn_params)
  end
  
  def self.shopping_cart_txn?(ipn_params)
    ipn_params && ipn_params['item_number1']
  end

  def self.handle_refund(ipn_params)
    if shopping_cart_txn?(ipn_params)
      update_shopping_cart_txn_status!("refunded", ipn_params)
    else
      find_and_save_with_payment_status!("refunded", ipn_params)
    end
  end
  
  def redeem!
    update_attributes! :redeemed => true
  end

  def redeemable?
    !redeemed? && completed?
  end

  def completed?
    payment_status == "completed"
  end

  def status
    "completed" == payment_status ? (redeemed ? "redeemed" : "open") : payment_status
  end
  
  def recipient_name
    unless @recipient_name
      @recipient_name = "#{paypal_first_name} #{paypal_last_name}"
      @recipient_name = paypal_address_name if @recipient_name.blank?
      @recipient_name = "Deal Certificate Customer" if @recipient_name.blank?
    end
    @recipient_name
  end
  
  def recipient_name_and_address_lines
    returning([]) do |lines|
      lines << recipient_name
      lines << paypal_address_street if paypal_address_street.present?
    
      line = [paypal_address_city, paypal_address_state].reject(&:blank?).join(", ")
      line = [line, paypal_address_zip].reject(&:blank?).join(" ")
      lines << line if line.present?
    end
  end

  def bought_with_shopping_cart!
    @bought_with_shopping_cart = true
  end

  def bought_with_shopping_cart?
    @bought_with_shopping_cart
  end

  private
  
  def self.build_from_ipn_params(params)
    new(
      :paypal_payment_date => params['payment_date'],
      :paypal_txn_id => params['txn_id'],
      :paypal_receipt_id => params['receipt_id'],
      :paypal_invoice => params['invoice'],
      :paypal_payment_gross => params['payment_gross'],
      :paypal_payer_email => params['payer_email'],
      :paypal_payer_status => params['payer_status'],
      :paypal_address_name => params['address_name'],
      :paypal_first_name => params['first_name'],
      :paypal_last_name => params['last_name'],
      :paypal_address_street => params['address_street'],
      :paypal_address_city => params['address_city'],
      :paypal_address_state => params['address_state'],
      :paypal_address_zip => params['address_zip'],
      :paypal_address_status => params['address_status'],
      :payment_status => "completed",
      :payment_status_updated_by_txn_id => params['txn_id'],
      :payment_status_updated_at => Time.zone.now
    )
  end
  
  def self.find_from_ipn_params(ipn_params)
    #
    # For chargeback and chargeback-reversed IPNs, the txn_id is the transaction number of the
    # chargeback/reversed case and the parent_txn_id is the txn_id of the original payment IPN.
    #
    %w{ txn_id parent_txn_id }.map { |param| find_by_paypal_txn_id(ipn_params[param]) }.compact.first
  end
    
  def self.find_and_save_with_payment_status!(payment_status, ipn_params)
    if purchased_gift_certificate = find_from_ipn_params(ipn_params)
      purchased_gift_certificate.update_attributes!({
        :payment_status => payment_status,
        :payment_status_updated_at => Time.zone.now,
        :payment_status_updated_by_txn_id => ipn_params['txn_id']
      })
    else
      raise "Can't find purchased deal certificate matching IPN #{ipn_params['txn_id']}"
    end
  end
  
  def self.update_shopping_cart_txn_status!(payment_status, ipn_params)
    unless txn_id_for_lookup = (ipn_params['parent_txn_id'] || ipn_params['txn_id'])
      raise "missing required PayPal parent_txn_id or txn_id for updating shopping cart transaction"
    end

    ipn_params.keys.grep(/item_number(\d+)/).each do |k|
      unless gc_id = ipn_params[k]
        raise "missing required shopping cart deal certificate ID for updating IPN #{txn_id_for_lookup}"
      end

      if purchased_gift_certificates = find_all_by_gift_certificate_id_and_paypal_txn_id(gc_id, txn_id_for_lookup)
        purchased_gift_certificates.each do |pgc|
          pgc.bought_with_shopping_cart!
          pgc.update_attributes!({
            :payment_status => payment_status,
            :payment_status_updated_at => Time.zone.now,
            :payment_status_updated_by_txn_id => ipn_params['txn_id']
          })          
        end
      else
        raise "can't find purchased deal certificate(s) matching IPN #{txn_id_for_lookup}"
      end
    end
  end
  
  def lay_out(style, pdf)
    gift_certificate.send("lay_out_#{style}", pdf, recipient_name_and_address_lines, serial_number)
  end

end
