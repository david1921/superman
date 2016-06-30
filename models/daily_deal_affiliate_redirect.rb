class DailyDealAffiliateRedirect < ActiveRecord::Base
  belongs_to :daily_deal
  belongs_to :consumer

  delegate :affiliate_url, :to => :daily_deal

end
