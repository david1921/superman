# Link to certificate for a deal purchased on another "platform." First use is to import links to WCAX deals
# purchased on Second Street. Essentially, an URL linked to a Consumer with basic description.
#
# Displayed on "My Deals" page. Passed into the view mixed in a collection with DailyDealPurchases. Both share 
# common getters.
class OffPlatformDailyDealCertificate < ActiveRecord::Base
  belongs_to :consumer

  validates_presence_of :consumer
  validates_presence_of :executed_at
  validates_presence_of :line_item_name

  validate :download_url_parts_present, :on => :create, :unless => 'has_voucher_pdf?'
  validate :presence_of_voucher_pdf, :unless => 'has_download_url_parts?'

  before_create :set_download_url_or_attach_voucher_pdf

  include Analog::Say
  include Import::OffPlatformDailyDealCertificates::CSV

  # download_url parts
  attr_accessor :code
  attr_accessor :contest_id
  attr_accessor :order_id
  attr_accessor :order_line_id

  has_attached_file :voucher_pdf,
                    :bucket         => "groucher.vouchers.analoganalytics.com",
                    :s3_host_alias  => "groucher.vouchers.analoganalytics.com",
                    :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml",
                    :hash_secret    => "Vouchers into groucher vouchers and this is a long key. yeahh! go go go!"

  # Common interface with DailyDealPurchase
  def has_deal_information?
    true
  end

  def quantity
    quantity_excluding_refunds
  end

  def certificates_to_generate_per_unit_quantity
    1
  end

  # Common interface with DailyDealPurchase
  def humanize_created_on
    I18n.localize(executed_at.to_date, :format => :long)    
  end
  
  # Common interface with DailyDealPurchase
  def humanize_expires_on
    I18n.localize(expires_on, :format => :long) if expires_on
  end

  def has_download_url_parts?
    !(download_url.blank? && (code.blank? || contest_id.blank? || order_id.blank? || order_line_id.blank?))
  end

  def has_voucher_pdf?
    self.voucher_pdf_file_name
  end

  def download_url_parts_present
    if !has_download_url_parts?
      errors.add :download_url, "%{attribute} is blank and don't have fields to set it (code, contest_id, order_id, order_line_id)"
    end
  end

  def presence_of_voucher_pdf
    if !has_voucher_pdf?
      errors.add :voucher_pdf, "{{attribute}} is blank"
    end
  end

  def set_download_url_or_attach_voucher_pdf
    unless has_voucher_pdf?
      self.download_url ||= "http://wcax.upickem.net/engine/PrintDeal.aspx?code=#{code}&orderid=#{order_id}&OrderLineID=#{order_line_id}&contestid=#{contest_id}"
    end
  end
end
