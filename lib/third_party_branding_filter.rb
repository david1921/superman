module ThirdPartyBrandingFilter
  
  BLACKLISTED_TERMS = [/\bdouble\s*take.*?\b\s*/i]
  BLACKLISTED_DOMAINS = [/doubletakedeals.com/i]
  
  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end
  
  module InstanceMethods
    
  end
  
  module ClassMethods
    
    def strip_third_party_branding_from_fields(*field_names)
      before_validation do |record|
        field_names.each do |text_field|
          next unless record.send(text_field).present?
          BLACKLISTED_TERMS.each do |blacklisted_term|
            stripped_text = if record.class.respond_to?(:textiled_attributes) && record.class.textiled_attributes.include?(text_field)
              original_text = record.send(text_field, :source)
              original_text.gsub(blacklisted_term, "")
            else
              original_text = record.send(text_field)
              original_text.gsub(blacklisted_term, "")
            end
            record.send("#{text_field}=", stripped_text) if original_text != stripped_text
          end
        end
      end
    end
    
    def blank_out_urls_with_third_party_branding(*url_field_names)
      before_validation do |record|
        url_field_names.each do |url_field|
          next unless record.send(url_field).present?
          BLACKLISTED_DOMAINS.each do |blacklisted_domain|
            record.send("#{url_field}=", "") if record.send(url_field) =~ blacklisted_domain
          end
        end
      end
    end
    
  end
  
end