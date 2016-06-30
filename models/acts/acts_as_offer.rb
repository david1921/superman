# represents common functionality for Advertiser Offers, such as
# coupons and deal certificates.
module ActsAsOffer
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
            
      #
      # === Associations
      #
      belongs_to :advertiser
      has_one :publisher, :through => :advertiser
      
      #
      # === Validations
      #
      validates_presence_of :advertiser
      
      #
      # === Delegate
      #
      delegate :address, :address?, :email_address, :formatted_phone_number, :zip, :to => :advertiser

    end
  end
 

  module InstanceMethods
    def advertiser_name
      @advertiser_name ||= advertiser.try(:name).to_s
    end

    def website_url
      advertiser.website_url
    end 
    
    def active_on?(date)
      (show_on.nil? || date >= show_on) && (expires_on.nil? || date <= expires_on)
    end
    
    def expired?
       !active_on?( Time.zone.now )
    end 
    alias_method :expired, :expired?
    
    def advertiser_message
      advertiser.tagline
    end

    def link_to_map?
      advertiser.try(:publisher).try(:link_to_map?)
    end
    
    def publisher_name
      advertiser.try(:publisher).try(:name)
    end
    
    def auto_insert_expiration_date?
      advertiser.try(:publisher).try(:auto_insert_expiration_date?)
    end
    
    def currency_to_number(currency)
      if currency.to_f == 0
        currency = currency.strip.gsub(/^\$/, "").to_f rescue nil
      end
      currency
    end 
    
  end
end
