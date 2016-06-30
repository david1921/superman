module BaseDailyDealPurchases::Core

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def update_sent_to_publisher_at(sent_at, daily_deal_purchase_ids)
      DailyDealPurchase.update_all(["sent_to_publisher_at = ?", sent_at], ["id in (?)", daily_deal_purchase_ids])
    end
  end

  def to_param
    uuid
  end

  def recipient_names=(value)
    list = []
    value.each { |name| list << name.to_s.squish } if value.respond_to?(:each)
    write_attribute :recipient_names, list
    synchronize_redeemers_names_on_certificates
  end

  def store_name
    store.try(:summary)
  end

  def consumer_name
    consumer.try(:name)
  end

  def consumer_email
    consumer.try(:email)
  end

  def humanize_executed_at
    I18n.localize(executed_at.to_date, :format => :long) if executed_at
  end

  def humanize_refunded_at
    I18n.localize(refunded_at.to_date, :format => :long) if refunded_at
  end

  def origin_name
    "Analog Analytics"
  end

  def travelsavers?
    pay_using?(:travelsavers)
  end

  def creates_payment?
    !travelsavers?
  end

  def send_purchase_confirmation!
    Resque.enqueue(SendCertificates, self.id)
  end

  def non_voucher_purchase?
    false
  end


  private

  def synchronize_redeemers_names_on_certificates
    daily_deal_certificates.each_with_index do |cert, i|
      cert.redeemer_name = recipient_names[i].present? ? recipient_names[i] : consumer_name
    end
  end

  def store_belongs_to_advertiser
    errors.add_to_base "Please choose a redemption location" unless advertiser.stores.find_by_id(store_id)
  end
end
