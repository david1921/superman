# Represents the definition of the GiftCertificate.
# @see PurchasedGiftCertificate for gift cards that were purchased.
class GiftCertificate < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include ActsAsOffer
  include ActsAsShareable
  
  acts_as_textiled :terms, :description

  belongs_to :advertiser
  has_one :publisher, :through => :advertiser
  has_many :purchased_gift_certificates
  has_many :impression_counts, :as => :viewable, :dependent => :destroy  
  has_many :click_counts, :as => :clickable, :dependent => :destroy  

  delegate :currency_symbol, :paypal_checkout_header_image, :to => :publisher, :allow_nil => true
  
  validates_presence_of :message
  validates_numericality_of :number_allocated, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :price, :greater_than => 0.0
  validates_numericality_of :value, :greater_than => 0.0
  validates_each :price do |record, attr, value|
    record.errors.add attr, "%{attribute} cannot be greater than face value" if value && record.value && value > record.value
  end
  
  
  has_attached_file :logo,
                    :bucket => "logos.gift-certificates.analoganalytics.com",
                    :s3_host_alias => "logos.gift-certificates.analoganalytics.com",
                    :default_style => :normal,
                    :styles => {
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                      :normal    => { :geometry => "400x300>",  :format => :png },
                      :medium    => { :geometry => "240x90>",  :format => :png }
                    }
  
  named_scope :not_deleted, :conditions => { :deleted => false }
  named_scope :deleted, :conditions => {:deleted => true}
  
  named_scope :available, :conditions => %q{
    NOT deleted AND number_allocated >
      (SELECT COUNT(*) FROM purchased_gift_certificates p WHERE p.gift_certificate_id = gift_certificates.id AND p.payment_status = 'completed')
  }

  named_scope :active, lambda {
    { :conditions => ["NOT deleted AND (show_on IS NULL OR :time >= show_on) AND (expires_on IS NULL OR :time <= expires_on)", { :time => Time.zone.now }] }
  }
  
  named_scope :starting_on, lambda {|time|
    {
      :conditions => ["NOT deleted AND show_on <= :time AND show_on > :today", {:time => time, :today => Time.zone.now}]
    }
  }
  
  named_scope :recent, :order => "show_on desc"
  
  before_destroy :verify_no_purchases
  
  def featured_gift_certificate_enabled?  
    # so this works with a new deal certificate
    # instantiated by @advertiser.gift_certificate.build
    # publisher association isn't available until after
    # create.
    p = publisher || advertiser.publisher 
    p && p.enable_featured_gift_certificate?
  end
  
  def price_with_handling_fee
    handling_fee? ? (price + handling_fee) : price
  end
  
  def purchased_count
    purchased_gift_certificates.completed(nil).count
  end
  
  def available_count
    deleted ? 0 : number_allocated - purchased_count
  end

  def available?
    available_count > 0
  end 
  
  def active?
    return false if deleted?
    return false if expires_on && Time.zone.now > expires_on
    show_on.blank? || show_on <= Time.zone.now
  end 
  
  def handling_fee?
    return false if handling_fee.nil?
    handling_fee > 0.00
  end
  
  def humanize_price
    number_to_currency(price, :unit => currency_symbol)
  end
  
  def price=(value)
    self[:price] = currency_to_number(value)
  end
  
  def humanize_value
    number_to_currency(value, :unit => currency_symbol)
  end
  
  def value=(new_value)
    self[:value] = currency_to_number(new_value)
  end
  
  def advertiser_name
    advertiser.try(:name).to_s
  end 
  
  def terms_with_expiration
    terms_with_period = plain_text_terms.strip.sub(/\.$/, '').tap { |text| text << "." if text.present? }
    expiration_phrase = "Expires %s." % expires_on.strftime('%m/%d/%Y') if expires_on.present? 
    [terms_with_period, expiration_phrase].select(&:present?).join(" ")
  end
  
  def item_number
    id.to_s
  end
  
  def item_name
    "%s %s Deal Certificate" % [number_to_currency(value, :unit => currency_symbol), advertiser_name]
  end 
  
  def url_for_bit_ly
    "http://#{advertiser.publisher.host}/publishers/#{advertiser.publisher.label}/gift_certificates?gift_certificate_id=#{id}"
  end
  
  def self.find_by_item_number(value)
    find_by_id(value)
  end
  
  def delete!
    update_attributes!(:deleted => true)
  end
  
  def record_impression
    ImpressionCount.record self, publisher.id
  end
  
  def impressions
    impression_counts.sum(:count)
  end
    
  def record_click(mode=nil)
    ClickCount.record self, publisher.id, mode
  end
    
  def clicks
    click_counts.sum(:count)
  end
  
  def to_preview_pdf
    Prawn::Document.new(:page_size => "LETTER") do |pdf|
      lay_out_pdf_1_up( pdf, sample_recipient_name_and_address_lines, "1111111-111111111")
    end.render
  end
  
  def sample_recipient_name_and_address_lines
    returning([]) do |lines|
      lines << "John Smith"
      lines << "123 Main St" 
    
      line = "San Diego, California"
      line = [line, "92102"].reject(&:blank?).join(" ")
      lines << line if line.present?
    end
  end

  def lay_out_pdf_3_up(pdf, recipient_address, serial_number)
    pdf.fill_color "c0c0c0"
    pdf.fill do
      pdf.rectangle [18, pdf.bounds.top - 18], 12, 72
    end
    pdf.fill_color "ffffff"
    pdf.text_box "FROM", :at => [21, pdf.bounds.top - 68], :rotate => 90, :size => 8
    pdf.fill_color "000000"
      
    pdf.bounding_box [36, pdf.bounds.top -  18], :width => 216, :height => 72 do
      with_publisher_logo { |logo| pdf.image(logo, :fit => [216, 18]) }
      pdf.bounding_box [0, pdf.bounds.top -  27], :width => 216, :height => 45 do
        pdf.text publisher.name
        publisher.address do |line|
          pdf.text line
        end
      end
    end
      
    pdf.fill_color "c0c0c0"
    pdf.fill do
      pdf.rectangle [18, pdf.bounds.top - 124], 12, 72
    end
    pdf.fill_color "ffffff"
    pdf.text_box "TO", :at => [21, pdf.bounds.top - 166], :rotate => 90, :size => 8
    pdf.fill_color "000000"
    
    pdf.bounding_box [36, pdf.bounds.top - 126], :width => 216, :height => 72 do
      recipient_address.each { |text| pdf.text text }
    end
    
    pdf.bounding_box [288, pdf.bounds.top -  18], :width => 270, :height => 180 do
      pdf.text "DEAL CERTIFICATE ##{serial_number}", :size => 16, :style => :bold, :align => :center
      pdf.text "#{humanize_value} VALUE", :size => 16, :style => :bold, :align => :center
      pdf.pad_top(2) { pdf.text "#{advertiser.name}", :align => :center, :size => 10, :style => :italic }
      pdf.stroke do
        pdf.horizontal_line pdf.bounds.left, pdf.bounds.right, :at => pdf.bounds.top - 58
      end
      pdf.bounding_box [0,  pdf.bounds.top - 68], :width => 48, :height => 10 do
        pdf.text "Redeem At", :size => 7, :style => :bold
      end
      pdf.bounding_box [48, pdf.bounds.top - 68], :width => 222, :height => 10 do
        pdf.text [advertiser.address.join(" | "), advertiser.formatted_phone_number].join(" | "), :size => 7
      end
      pdf.bounding_box [0, pdf.bounds.top - 80], :width => 48, :height => 10 do
        pdf.text "Expires On", :size => 7, :style => :bold
      end
      pdf.bounding_box [48, pdf.bounds.top - 80], :width => 222, :height => 10 do
        pdf.text(expires_on.to_formatted_s(:long), :size => 7) if expires_on.present?
      end
      pdf.bounding_box [0, pdf.bounds.top - 92], :width => 48, :height => 10 do
        pdf.text "Fine Print", :size => 7, :style => :bold
      end
      pdf.bounding_box [48, pdf.bounds.top - 92], :width => 222, :height => 40 do
        pdf.text plain_text_terms, :size => 7
      end
    end 
    pdf.bounding_box [288, 36], :width => 270, :height => 18 do
      pdf.text "http://www.analoganalytics.com", :size => 6, :align => :right, :valign => :bottom
      pdf.image File.expand_path("public/images/powered_by_analog_analytics.png", Rails.root), :width => 72, :at => [0, pdf.bounds.top]
    end
  end
  
  def lay_out_pdf_1_up(pdf, recipient_address, serial_number)
    pdf.bounding_box [54, pdf.bounds.height], :width => 432, :height => 230 do
      pdf.stroke_bounds
      pdf.bounding_box [pdf.bounds.left + 10, pdf.bounds.top - 10], :width => 413, :height => 210 do
        #
        # Header
        #
        pdf.bounding_box [pdf.bounds.left, pdf.bounds.top], :width => 413, :height => 65 do
          with_publisher_logo { |logo| pdf.image(logo, :fit => [130, 60]) }
          width = 300
          pdf.bounding_box [pdf.bounds.right - width, pdf.bounds.top - 36], :width => width, :height => 29 do
            pdf.text serial_number, :size => 24, :align => :right
          end
          pdf.stroke do
            pdf.line pdf.bounds.bottom_left, pdf.bounds.bottom_right
          end
        end
        #
        # Title
        #
        pdf.pad(10) do
          pdf.text title, :size => 16, :align => :left, :style => :bold
        end
        #
        # Recipient and terms
        #
        pdf.bounding_box [pdf.bounds.left, pdf.bounds.top - 105], :width => 200, :height => 127 do
          pdf.font_size(10) do
            pdf.text "Recipient:", :style => :bold
            pdf.text recipient_address.first
             
             pdf.pad_top(8) do
               pdf.text "Expires On:", :style => :bold
               pdf.text expires_on.to_s(:simple) unless expires_on.blank?
             end
               
             pdf.pad_top(8) do
               pdf.text "Fine Print:", :style => :bold
               pdf.text plain_text_terms, :size => 8
             end
           end
        end
        #
        # Redeem at
        #
        pdf.bounding_box [pdf.bounds.left + 213, pdf.bounds.top - 105], :width => 200, :height => 127 do
          pdf.font_size( 10 ) do
            pdf.text("Redeem at:", :style => :bold)
            pdf.text(advertiser.name)
            advertiser.address { |line| pdf.text line }
            pdf.text(advertiser.formatted_phone_number) unless advertiser.formatted_phone_number.blank?
          end
        end
      end
    end
    pdf.bounding_box [54, pdf.bounds.height - 260], :width => 432, :height => 200 do
      pdf.bounding_box [0, pdf.bounds.height], :width => 432 do
        pdf.text "How to use this:", :size => 18, :style => :bold
        pdf.font_size(12) do
          pdf.text "1. Print Deal Certificate"
          pdf.text "2. Go to #{advertiser.name}"
          pdf.text "3. Present Deal Certificate and valid ID upon arrival"
        end  
      end
    end 
    pdf.bounding_box [54, pdf.bounds.top - 340], :width => 432, :height => 72 do
      pdf.bounding_box [0, pdf.bounds.top], :width => 82 do
        pdf.text "Business Owners:", :size => 9, :style => :bold
      end
      pdf.bounding_box [82, pdf.bounds.top], :width => 350 do
        pdf.text "To verify this certificate by phone, call (877) 365-0077 and enter #{serial_number.gsub(/\-/, '')}#", :size => 9
      end
    end
    unless publisher.gift_certificate_disclaimer.blank?
      pdf.bounding_box [54, pdf.bounds.top - 520], :width => 432, :height => 200 do
        pdf.text "Terms And Conditions", :size => 12, :style => :bold
        pdf.font_size(8) do
          pdf.text publisher.gift_certificate_disclaimer(:plain).split(/\n/).join("\n\n")
        end
      end
    end
    pdf.bounding_box [0, pdf.bounds.height - 720], :width => 540, :height => 18 do
      pdf.text "http://www.analoganalytics.com", :size => 8, :align => :right, :valign => :bottom
      pdf.image File.expand_path("public/images/powered_by_analog_analytics.png", Rails.root), :width => 90, :at => [0, pdf.bounds.top]
    end
  end
  
  def plain_text_terms
    [].tap { |lines| terms(:plain).to_s.each_line { |line| lines << line.strip.sub(/\.$/, '') }}.select(&:present?).join(". ")
  end

  def address_required?
    physical_gift_certificate? || collect_address?
  end
  
  def to_liquid
    Drop::GiftCertificate.new(self)
  end

  def facebook_url(url, popup)
    self.facebook_title_suffix = "Deal Certificate"

    params = [
      facebook_url_param("[url]", url),
      facebook_url_param("[title]", self.facebook_title),
      facebook_url_param("[summary]", self.description),
      facebook_url_param("[images][0]", self.logo.url)
    ]

    action = popup ? "sharer.php" : "share.php"

    "http://www.facebook.com/#{action}?s=100#{params.join('')}"
  end

  private

  def facebook_url_param(key, value)
    "&p#{CGI.escape(key)}=#{CGI.escape(value)}" unless value.blank?
  end
  
  def verify_no_purchases
    purchased_gift_certificates.empty? or errors.add(:purchased_gift_certificates, "%{attribute} must be empty to destroy") && false
  end
  
  def title
    "#{number_to_currency(value, :unit => currency_symbol)} Deal Certificate To #{advertiser.name}"
  end

  def with_publisher_logo(&block)
    publisher.try(:with_logo, &block)
  end
end
