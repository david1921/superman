module Report::Entertainment

  class Boss   
    
    def initialize
      @definition = [
          BossField.new(25, lambda { |cert, purchase| purchase.consumer.first_name }),
          BossField.new(25, lambda { |cert, purchase| purchase.consumer.last_name }),
          BossField.new(10, lambda { |cert, purchase| ""  }), # empty
          BossField.new(10, lambda { |cert, purchase| "" }), # empty
          BossField.new(100, lambda { |cert, purchase| purchase.consumer.email }),
          BossField.new(50, lambda { |cert, purchase| purchase.consumer.address_line_1.nil? ? "" : purchase.consumer.address_line_1[0,30] }), # *billing address line 1
          BossField.new(50, lambda { |cert, purchase| purchase.consumer.address_line_2.nil? ? "" : purchase.consumer.address_line_2[0,30] }), # *billing address line 2
          BossField.new(30, lambda { |cert, purchase| purchase.consumer.billing_city }), # *billing city
          BossField.new(2, lambda { |cert, purchase| purchase.consumer.state }), # *billing state
          BossField.new(14, lambda { |cert, purchase| BOSSCountryCode.new(purchase.consumer.country_code) }), # *billing country
          BossField.new(9, lambda { |cert, purchase| purchase.consumer.zip_code }), # *billing zip
          BossField.new(8, lambda { |cert, purchase| "" }), # group number
          BossField.new(25, lambda { |cert, purchase| "" }), # group type 
          BossField.new(1, lambda { |cert, purchase| "N" }), # registered flag
          BossField.new(12, lambda { |cert, purchase| purchase.executed_at.getutc.strftime("%Y%m%d%H%M") }), 
          BossField.new(9, lambda { |cert, purchase| "" }), # order_id not used
          BossField.new(16, lambda { |cert, purchase| "" }), # cc number not used
          BossField.new(4, lambda { |cert, purchase| "" }), # cc expiration not used
          BossField.new(8, lambda { |cert, purchase| purchase.total_paid }), # total transaction amt
          BossField.new(2, lambda { |cert, purchase| cert[:line_item] }), # *line number
          BossField.new(6, lambda { |cert, purchase| "1" }), # quantity for this line item
          BossField.new(25, lambda { |cert, purchase| BOSSName.new(cert.redeemer_name).first_name }), # *recipient first name
          BossField.new(25, lambda { |cert, purchase| BOSSName.new(cert.redeemer_name).last_name }), # *recipient last name
          BossField.new(50, lambda { |cert, purchase| purchase.consumer.address_line_1.nil? ? "" : purchase.consumer.address_line_1[0,30] }), # *billing address line 1
          BossField.new(50, lambda { |cert, purchase| purchase.consumer.address_line_2.nil? ? "" : purchase.consumer.address_line_2[0,30] }), # *billing address line 2
          BossField.new(30, lambda { |cert, purchase| purchase.consumer.billing_city }), # *billing city
          BossField.new(2, lambda { |cert, purchase| purchase.consumer.state }), # *billing state
          BossField.new(14, lambda { |cert, purchase| BOSSCountryCode.new(purchase.consumer.country_code) }), # *billing country
          BossField.new(9, lambda { |cert, purchase|  purchase.consumer.zip_code }), # *billing zip
          BossField.new(15, lambda { |cert, purchase| purchase.discount.nil? ? "" : purchase.discount.code }),
          BossField.new(8, lambda { |cert, purchase| "" }), # product code - original - replaced lower down  
          BossField.new(6, lambda { |cert, purchase| LineItemValue.new(cert,purchase).value }), # unit price with sometimes funky math
          BossField.new(6, lambda { |cert, purchase| "" }), # unit shipping  
          BossField.new(1, lambda { |cert, purchase| "0" }), # rush flag      
          BossField.new(1, lambda { |cert, purchase| "N" }), # continuity  
          BossField.new(1, lambda { |cert, purchase| "0" }), # backorder      
          BossField.new(20, lambda { |cert, purchase| "" }), # source id   
          BossField.new(1, lambda { |cert, purchase| "N" }), # message flag      
          BossField.new(50, lambda { |cert, purchase| "" }), # message text  
          BossField.new(15, lambda { |cert, purchase| "" }), # ship to overseas        
          BossField.new(8, lambda { |cert, purchase| "" }), # tax amount  
          BossField.new(1, lambda { |cert, purchase| "" }), # filler      
          BossField.new(8, lambda { |cert, purchase| "" }), # ship tax amount  
          BossField.new(20, lambda { |cert, purchase| "" }), # site id      
          BossField.new(30, lambda { |cert, purchase| "" }), # shipping promo 
          BossField.new(35, lambda { |cert, purchase| "" }), # link id      
          BossField.new(35, lambda { |cert, purchase| "" }), # entry id  
          BossField.new(40, lambda { |cert, purchase| "" }), # custom      
          BossField.new(14, lambda { |cert, purchase| "" }), # filler  
          BossField.new(13, lambda { |cert, purchase| "" }), # group number      
          BossField.new(6, lambda { |cert, purchase| "" }), # cc auth code  
          BossField.new(2, lambda { |cert, purchase| "" }), # cc address verification response
          BossField.new(10, lambda { |cert, purchase| "" }), # seller id  
          BossField.new(22, lambda { |cert, purchase| "" }), # ps2000      
          BossField.new(1, lambda { |cert, purchase| "" }), # auth source  
          BossField.new(21, lambda { |cert, purchase| "" }), # gift card number      
          BossField.new(1, lambda { |cert, purchase| "" }), # gift card status 
          BossField.new(8, lambda { |cert, purchase| "" }), # gift card activation date      
          BossField.new(13, lambda { |cert, purchase| "" }), # gift card assoc  
          BossField.new(50, lambda { |cert, purchase| "" }), # avatax doc ref
          BossField.new(10, lambda { |cert, purchase| purchase.publisher.listing }), # product code
          BossField.new(1, lambda { |cert, purchase| "" }), # cust opt in email
          BossField.new(1, lambda { |cert, purchase| "" }), # cust create profile
          BossField.new(30, lambda { |cert, purchase| "" }), # bank 1
          BossField.new(40, lambda { |cert, purchase| "" }), # bank 2
          BossField.new(12, lambda { |cert, purchase| purchase.daily_deal.nil? ? "" : purchase.daily_deal.id }),      # offer id
          BossField.new(1, lambda { |cert, purchase| purchase.gift ? "Y" : "N" }),    # gift indicator
          BossField.new(19, lambda { |cert, purchase| "" }),                          # *ip address
          BossField.new(1, lambda { |cert, purchase| "Y" }),                          # privacy acceptance 
          BossField.new(12, lambda { |cert, purchase| cert.nil? ? "" : cert.serial_number })  # serial number
      ]
    end
                           
    def generate_for_publishing_group(csv, publishing_group)
      daily_deal_purchase_ids = []
      publishing_group.publishers.each do |publisher| 
        daily_deal_purchase_ids += generate_for_publisher(csv, publisher.id)
      end
      daily_deal_purchase_ids
    end
    
    def find_purchases(publisher_id)
      DailyDealPurchase.find(:all,
                             :include => [:daily_deal_certificates, :daily_deal, :consumer], 
                             :conditions => ["users.publisher_id = ? and daily_deal_purchases.sent_to_publisher_at is NULL", publisher_id])
    end

    def generate_for_publisher(csv, publisher_id)
      daily_deal_purchase_ids = []      
      purchases = find_purchases(publisher_id)
      purchases.each do |purchase|
        line_item = 1                   
        running_total = BigDecimal("0")
        purchase.daily_deal_certificates.sort_by { |cert| cert.created_at }.each do |cert|
          if valid?(cert, purchase)
            cert[:line_item] = line_item
            cert[:last_line_item] = (purchase.daily_deal_certificates.size == line_item)
            cert[:running_total] = running_total
            csv << row(cert, purchase)          
            line_item += 1 
            running_total += LineItemValue.new(cert, purchase).value
          end
        end
        daily_deal_purchase_ids << purchase.id
      end
      daily_deal_purchase_ids
    end  
    
    def valid?(certificate, purchase)
      purchase.consumer.first_name.present? &&
      purchase.consumer.last_name.present? &&
      purchase.consumer.address_line_1.present? &&
      purchase.consumer.billing_city.present? &&
      purchase.consumer.state.present? &&
      purchase.consumer.zip_code.present?
    end
    
    def row(certificate, purchase = nil)
      purchase ||= certificate.daily_deal_purchase
      @definition.map do |boss_field|
        value_for_cert_and_purchase(certificate, purchase, boss_field)
      end
    end
    
    def field(cert, field)
      raise ArgumentError.new("cert cannot be nil") if cert.nil?
      value_for_cert_and_purchase(cert, cert.daily_deal_purchase, field)                                
    end 
    
    def value_for_cert_and_purchase(cert, purchase, field)
      if field.is_a?(Fixnum)
        raise ArgumentError.new("No field defintion for field #{field}") if field >= @definition.size
        boss_field = @definition[field] 
      end
      boss_field ||= field
      daily_deal_purchase ||= cert.daily_deal_purchase
      boss_field.call(cert, purchase)                                 
    end
    
    class BossField         
      def initialize(length, proc)
        @length = length;
        @proc = proc;
      end

      def call(cert, purchase)
        @proc.call(cert, purchase).to_s[0, @length].ljust(@length)
      end
    end
    
    class BOSSCountryCode
      US_CODE = "999COU00000001"
      CANADA_CODE = "999COU00000002"
      def initialize(code)
        @code = code
      end           
      def to_s
        case @code
          when "US"
            US_CODE
          when "CA"
            CANADA_CODE
          else
            @code || ""
        end
      end
    end
    
    class BOSSName
      def initialize(name)
        @bits = name.blank? ? [] : name.split
      end           
      def first_name
        return "" if rubbish?
        @bits[0]
      end
      def last_name
        return "" if rubbish?
        @bits[-1]
      end
      def rubbish?
        @bits.size < 2 or @bits.size > 3
      end
    end
    
    class LineItemValue
      def initialize(cert, purchase) 
        @cert = cert
        @purchase = purchase
      end                   
      def value
        return (@purchase.total_paid / @purchase.quantity).round(2) unless @cert[:last_line_item]
        @purchase.total_paid - @cert[:running_total]
      end
    end
    
  end

end
