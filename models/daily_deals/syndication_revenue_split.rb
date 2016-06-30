class DailyDeals::SyndicationRevenueSplit < ActiveRecord::Base
  
  include DailyDeals::SyndicationRevenueSplitValidation
  include DailyDeals::SyndicationRevenueSplitConstants
  include DailyDeals::SyndicationRevenueSplitDetails
                                                           
  validates_inclusion_of  :revenue_split_type, :in => SYNDICATION_REVENUE_SPLIT_TYPE.values, :message => SYNDICATION_REVENUE_SPLIT_TYPE_INCLUSION_MESSAGE, :allow_blank => false
  validates_presence_of   :merchant_net_percentage, :if => :net_revenue_split_type?
  validate                :validate_revenue_split_percentages
  
  def gross_revenue_split_type?
    revenue_split_type == 'gross'
  end
  
  def net_revenue_split_type?
    revenue_split_type == 'net'
  end
  
end