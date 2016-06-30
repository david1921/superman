module ThirdPartyDealsApi

  class Config < ActiveRecord::Base
    set_table_name "third_party_deals_api_configs"
    
    belongs_to :publisher
    validates_presence_of :publisher_id, :api_username, :api_password
    
    unless Rails.env.development?
      validates_format_of :voucher_serial_numbers_url, :with => %r{^https://}, :message => "%{attribute} must be https", :allow_blank => true
    end
  end

end
