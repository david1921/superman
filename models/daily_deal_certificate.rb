class DailyDealCertificate < ActiveRecord::Base
  include HasPublisherThemeableTranslations
  include ActionController::UrlWriter
  include ActsAsBarCodeAssignee
  include HasSerialNumber
  include ThirdPartyDealsApi::DailyDealCertificate
  include DailyDealCertificates::Core
  include QrCode
  include DailyDealCertificates::Sequence
  include DailyDealCertificates::Status
  include DailyDealCertificates::MultiVoucherDeals

  STATUSES = [ACTIVE = "active", REDEEMED = "redeemed", REFUNDED = "refunded", VOIDED = "voided"]

  TRANSLATE_SCOPE = [:daily_deal_certificate]

  before_validation_on_create :init_defaults

  belongs_to :daily_deal_purchase, :class_name => 'BaseDailyDealPurchase'

  validates_presence_of :daily_deal_purchase
  validates_presence_of :actual_purchase_price
  validates_presence_of :redeemer_name
  validates_presence_of :refunded_at, :if => :refunded?
  validates_inclusion_of :status, :in => STATUSES, :message => "Invalid status"

  named_scope :captured, { :include => :daily_deal_purchase, :conditions => { 'daily_deal_purchases.payment_status' => "captured" } }
  named_scope :redeemed, { :conditions => ["status = ?", REDEEMED] }
  named_scope :expired, :conditions => ["daily_deals.expires_on < ? AND daily_deal_certificates.status = ? AND daily_deal_certificates.marked_used_by_user != 1", Time.zone.now, ACTIVE], :joins => "INNER JOIN daily_deal_purchases AS daily_deal_purchases_hack ON daily_deal_certificates.daily_deal_purchase_id = daily_deal_purchases_hack.id INNER JOIN daily_deals ON daily_deal_purchases_hack.daily_deal_id = daily_deals.id"
  named_scope :redeemed_and_marked_used_by_user, :conditions => ["status = ? OR marked_used_by_user = 1", REDEEMED]
  named_scope :not_travelsavers, :conditions => "daily_deal_purchase_id NOT IN (SELECT daily_deal_purchase_id FROM travelsavers_bookings)"
  
  
  has_one   :daily_deal, :through => :daily_deal_purchase

  delegate  :with_publisher_logo, :with_syndicated_publisher_logo, :expires_on, :advertiser, :voucher_steps, :publisher,  
            :hide_serial_number_if_bar_code_is_present?, :bar_code_symbology, :voucher_has_qr_code?, :to => :daily_deal
  delegate  :custom_voucher_template_exists?, :custom_voucher_template, :custom_voucher_template_layout, :publisher_for_voucher_rendering, :consumer_name, :consumer_email,
            :affiliate_name, :store, :store_name, :executed_at, :consumer, :humanize_expires_on, :value_proposition, :voucher_headline, :bar_code_encoding_format,
            :value_proposition, :humanize_value, :terms, :price, :humanize_price, :terms_plain, :to => :daily_deal_purchase
  delegate  :currency_symbol, :to => :publisher

  named_scope :refunded, { :conditions => ["status = ?", REFUNDED] }
  named_scope :active, { :include => :daily_deal_purchase,
                         :conditions => %Q{
                           (daily_deal_certificates.status = '#{ACTIVE}')
                           OR (daily_deal_certificates.status = '#{REFUNDED}'
                            AND (daily_deal_purchases.loyalty_refund_amount IS NOT NULL AND daily_deal_purchases.loyalty_refund_amount > 0.0))
                           }
                        }
  named_scope :refunded_between, lambda { |dates|
    sql = "daily_deal_certificates.status = '#{REFUNDED}' AND daily_deal_certificates.refunded_at BETWEEN :beg AND :end"
    { :conditions => [sql, { :beg => Time.zone.parse(dates.begin.to_s).beginning_of_day.utc, :end => Time.zone.parse(dates.end.to_s).end_of_day.utc}] }
  }
  named_scope :validatable, { :include => :daily_deal_purchase,
                              :conditions => %Q{
                                (daily_deal_purchases.payment_status = 'captured')
                                OR (daily_deal_purchases.payment_status = 'refunded'
                                  AND (daily_deal_purchases.loyalty_refund_amount IS NOT NULL AND daily_deal_purchases.loyalty_refund_amount > 0.0))
                               }
                            }
  
  named_scope :not_expired, lambda {{
    :conditions => ["daily_deals.expires_on IS NULL OR daily_deals.expires_on > ?", Time.zone.now],
    :joins => { :daily_deal_purchase => :daily_deal }
  }}
  
  named_scope :redeemable, {
    :conditions => ["daily_deal_certificates.status = ? AND NOT daily_deal_certificates.marked_used_by_user", ACTIVE]
  }
  
  def humanize_redeemed_at
    I18n.localize(redeemed_at.to_date, :format => :long) if redeemed_at
  end
  def humanize_refunded_at
    I18n.localize(refunded_at.to_date, :format => :long) if refunded_at
  end
  

  def init_defaults
    self.status ||= ACTIVE
  end

  def refunded?
    status == REFUNDED
  end
  
  def voided?
    status == VOIDED
  end

  def usable?
    #
    # An expired certificate is still usable in most states, if not at face value.
    #
    status == ACTIVE
  end
  alias_method :active?, :usable?

  def refundable?
    active?
  end
  
  # for when the purchase moves from voided->captured (which is as of this writing an allowed transition)
  def activate!
    self.status = ACTIVE
    save!
  end

  def refund!
    update_attributes! :status => REFUNDED, :refund_amount => actual_purchase_price, :refunded_at => Time.zone.now unless refunded?
  end

  def void!
    self.status = VOIDED
    save!
  end

  def redeemed?
    self.status == REDEEMED
  end

  def redeem!
    update_attributes! :status => REDEEMED, :redeemed_at => Time.zone.now unless redeemed?
  end
  
  def mark_used_by_user!
    update_attributes! :marked_used_by_user => true
  end

  def mark_unused_by_user!
    update_attributes! :marked_used_by_user => false
  end

  def redeemable?
     !redeemed? && (daily_deal_purchase.captured? or (daily_deal_purchase.refunded? && daily_deal_purchase.received_loyalty_refund?))
  end
  
  def affiliate_payout
    price * (daily_deal.affiliate_revenue_share_percentage / 100)
  end

  # helper method to generate just an individual
  # certificate for a daily deal purchase.  This
  # is helpful for re-issuing a cert with a new
  # redeemer_name
  def to_pdf(use_redeemer_name = nil)
    if use_redeemer_name.present?
      self.redeemer_name = use_redeemer_name 
    end

    if custom_voucher_template_exists?
      certificate_bodies = custom_lay_out_as_html_snippet
      PDFKit.new(ERB.new(custom_voucher_template_layout).result(binding), :page_size => 'Letter').to_pdf
    else
      Prawn::Document.new(:page_size => "LETTER") { |pdf| standard_lay_out_with_prawn pdf }.render
    end
  end
  
  def lay_out(pdf)
    warn "DailyDealCertificate#lay_out is deprecated. Use DailyDealCertificate#standard_lay_out_with_prawn instead."
    standard_lay_out_with_prawn(pdf)
  end

  def pdf_filename
    [redeemer_name, advertiser.name, id.to_s].join("_").to_ascii.split.join('_').downcase << ".pdf"
  end

  def custom_lay_out_as_html_snippet(options = {})
    page_break = options[:page_break]
    unless custom_voucher_template_exists?
      raise "DailyDealCertificate#custom_lay_out_as_html_snippet called on a voucher for which no custom layout exists"
    end
    
    certificate = self
    source_publisher = publisher_for_voucher_rendering
    helpers = Object.new
    helpers.extend(ActionView::Helpers::TextHelper)
    if bar_code.present?
      bar_code_file_path = with_bar_code_image(bar_code, :width => 240, :resolution => 600, :keep_jpg => true, :encoding_format => bar_code_encoding_format)
    else
      bar_code_file_path = with_bar_code_image(serial_number, :width => 240, :resolution => 600, :keep_jpg => true)
    end
    deal_description = helpers.truncate(daily_deal.description(:plain), :length => 300)
    value_proposition = helpers.truncate(value_proposition, :length => 50)
    certificate_map_image = map_image_url ? "<img src='#{map_image_url}' width='305px' height='250px' id='imgMap'>" : nil
    ERB.new(custom_voucher_template).result(binding)
  end
  
  def map_image_url
    if location = store || advertiser.store
      escaped_address = CGI.escape("#{location.address_line_1}, #{location.city}, #{location.state} #{location.zip}")
      "http://maps.google.com/maps/api/staticmap?size=305x250&center=#{escaped_address}&markers=size:small|#{escaped_address}&key=ABQIAAAAzObGV3GscSCtMupcN2Jm-RSSjhI9lG3KGwm-Keiwru5ERTctHhTXe3LfYrff_rQT8DZgaQB6AthF0A&sensor=false"
    end
  end
  
  def standard_lay_out_with_prawn(pdf)
    if custom_voucher_template_exists?
      raise "unexpectedly called DailyDealCertificate#standard_lay_out_with_prawn on a voucher for which a custom template exists"
    end

    # Use DejaVuSans instead of the default Helvetica because it supports more
    # unicode characters (such as Greek)
    pdf.font_families.update("DejaVuSans" => {
      :bold        => "#{Rails.root}/assets/fonts/DejaVuSans-Bold.ttf",
      :italic      => "#{Rails.root}/assets/fonts/DejaVuSans-Oblique.ttf",
      :bold_italic => "#{Rails.root}/assets/fonts/DejaVuSans-BoldOblique.ttf",
      :normal      => "#{Rails.root}/assets/fonts/DejaVuSans.ttf"
    })
    pdf.font("DejaVuSans")

    translate_scope = TRANSLATE_SCOPE + [:voucher]

    pdf.bounding_box [54, pdf.bounds.height], :width => 432, :height => 230 do
      pdf.stroke_bounds
      pdf.bounding_box [pdf.bounds.left + 10, pdf.bounds.top - 10], :width => 413, :height => 210 do
        #
        # Certificate header
        #
        pdf.bounding_box [pdf.bounds.left, pdf.bounds.top], :width => 413, :height => 65 do
          begin
            with_publisher_logo(:daily_deal) { |logo| pdf.image(logo, :fit => [260, 56]) }
          rescue OpenURI::HTTPError => e
            logger.error e
          end

          if daily_deal.syndicated? && daily_deal.cobrand_deal_vouchers?
            pdf.bounding_box [pdf.bounds.right - 160, pdf.bounds.top - 10], :width => 70, :height => 29 do
              pdf.text translate_with_theme('deal_provided_by', :scope => translate_scope), :size => 8, :align => :right
            end          
          
            pdf.bounding_box [pdf.bounds.right - 85, pdf.bounds.top + 5], :width => 90, :height => 40 do
              with_syndicated_publisher_logo(:daily_deal) { |logo| pdf.image(logo, :fit => [90, 40], :position => :left) }
            end          
          end
          
          width = 300
          pdf.bounding_box [pdf.bounds.right - width, pdf.bounds.top - 36], :width => width, :height => 29 do
            unless hide_serial_number?
              pdf.text serial_number, :size => 24, :align => :right
            end
          end
          pdf.stroke do
            pdf.line pdf.bounds.bottom_left, pdf.bounds.bottom_right
          end
        end
        #
        # Title
        #
        pdf.pad(10) do
          pdf.text line_item_name, :size => 16, :align => :left, :style => :bold
        end
        if voucher_has_qr_code?
          with_qr_code_image(serial_number, :level => 3) do |png|
            pdf.image png, :fit => [60, 60], :at => [pdf.bounds.right - 56, pdf.bounds.top - 66] 
          end
        end
        #
        # Redeemer and terms
        #
        pdf.bounding_box [pdf.bounds.left, pdf.bounds.top - 105], :width => 200, :height => 110 do
          pdf.font_size(10) do
            pdf.text translate_with_theme('recipient', :scope => translate_scope) + ':', :style => :bold
            pdf.text redeemer_name
             
             pdf.pad_top(8) do
               pdf.text translate_with_theme('expires_on', :scope => translate_scope) + ':', :style => :bold
               pdf.text humanize_expires_on unless expires_on.blank?
             end
               
             pdf.pad_top(8) do
               fine_print_label_default = translate_with_theme('fine_print_label', :scope => translate_scope)
               fine_print_label = publisher.display_text_for(:fine_print_label, fine_print_label_default)
               pdf.text("#{fine_print_label}:", :style => :bold)
               pdf.text_box plain_text_terms, {
                 :size => 6,
                 :at => [0, pdf.bounds.top - 76],
                 :width => 198, :height => 36,
                 :overflow => :shrink_to_fit,
                 :min_font_size => 4
               }
             end
           end
        end
        #
        # Redeem at
        #
        pdf.bounding_box [pdf.bounds.left + 213, pdf.bounds.top - 105], :width => 200, :height => 127 do
          pdf.font_size( 10 ) do
            pdf.text(translate_with_theme('redeem_at', :scope => translate_scope) + ':', :style => :bold)
            pdf.text(advertiser.name)
            if store
              store.address { |line| pdf.text line }
              pdf.text(store.formatted_phone_number) unless store.formatted_phone_number.blank?
            else
              advertiser.address { |line| pdf.text line }
              pdf.text(advertiser.formatted_phone_number) unless advertiser.formatted_phone_number.blank?
            end
          end
          #
          # Bar code
          #
          if bar_code.present?
            with_bar_code_image(bar_code, :width => 216, :height => 40, :resolution => 600, :encoding_format => bar_code_encoding_format) do |jpg|
              pdf.image jpg, :fit => [216, 50], :at => [pdf.bounds.left + 10, pdf.bounds.top - 64] 
            end
          end
        end
      end
    end
    pdf.bounding_box [54, pdf.bounds.height - 236], :width => 432, :height => 20 do
      deal_certificate_terms_message_default = translate_with_theme('terms_message', :scope => translate_scope)
      pdf.text publisher.display_text_for(:deal_certificate_terms_message, deal_certificate_terms_message_default), {
        :align => :center,
        :size => 7,
        :style => :bold
      }
      pdf.text terms_url, :size => 7, :align => :center
    end
    
    pdf.bounding_box [54, pdf.bounds.height - 288], :width => 432, :height => 200 do
      pdf.text translate_with_theme('how_to_use', :scope => translate_scope) + ':', :size => 18, :style => :bold
      pdf.font_size(12) do
        pdf.text(daily_deal.voucher_steps || "")
      end  
    end
    #
    # Page footer
    #
    pdf.bounding_box [0, pdf.bounds.height - 720], :width => 540, :height => 18 do
      pdf.text "http://www.analoganalytics.com", :size => 8, :align => :right, :valign => :bottom
      pdf.image File.expand_path("public/images/powered_by_analog_analytics.png", Rails.root), :width => 90, :at => [0, pdf.bounds.top]
    end
  end

  def plain_text_terms
    all_terms = terms_plain
    all_terms += publisher.daily_deal_universal_terms(:plain) if publisher.daily_deal_universal_terms.present?
    if all_terms.present?
      [].tap { |lines| all_terms.each_line { |line| lines << line.strip }}.select(&:present?).each do |line|
        line << "." unless line =~ /[[:punct:]]$/
      end.join(" ")
    else
      ""
    end
  end

  def terms_url
    publisher = daily_deal_purchase.publisher
    terms_publisher_daily_deals_url(publisher, :host => publisher.daily_deal_host) if publisher
  end  
  
  def html_voucher_steps
    RedCloth.new( voucher_steps ).to_html
  end

  def qr_code_data_uri
    return nil unless voucher_has_qr_code?
    encoding = ""
    with_qr_code_image(serial_number, :level => 3, :output_format => :jpg) do |jpg|
      encoding = Base64.encode64(jpg.read)
    end
    "data:image/jpg;base64,#{encoding}"
  end

end
