class OffPlatformPurchaseSummary < ActiveRecord::Base
  
  GROSS_OR_NET = %w(gross net)
  
  belongs_to :daily_deal
  
  
  
end
