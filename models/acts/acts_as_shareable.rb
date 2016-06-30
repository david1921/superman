# ActsAsShareable
#
# The boilerplate for sharing via twitter and facebook, also responsible for
# managing Bit.ly account and urls.  
#
# Class that include ActsAsShareable will need to provide methods for:
#
#  url_for_bit_ly - this should be the link that will be shorten, and should link to the individual item
module ActsAsShareable

  def self.included(base)
    base.send :include, HasBitLyUrl
    base.send :include, InstanceMethods
  end
  
  module InstanceMethods
    def facebook_title_suffix=(suffix)
      @facebook_title_suffix = suffix
    end

    def facebook_title(pub = nil)
      publisher = pub || self.publisher
      suffix = @facebook_title_suffix ? @facebook_title_suffix : "Coupon"
      "[#{publisher.brand_name_or_name} #{suffix}] #{message.strip}"
    end

    def facebook_title_prefix
      "[#{publisher.brand_name_or_name} Coupon] "
    end
    
    def facebook_description
      concat = lambda { |array, separator| array.map { |item| item.to_s.strip.sub(/\.$/, '') }.select(&:present?).join(separator) }
      concat.call([concat.call([advertiser_name, advertiser.tagline], ": "), message, terms], "; ").gsub(/([^.!])$/, '\1.')
    end
    
    def twitter_status(pub = nil)
      publisher = pub || self.publisher
      "#{publisher.twitter_handle} #{message.strip} at #{advertiser.name.strip} - #{bit_ly_url}"
    end
    
  end
end
