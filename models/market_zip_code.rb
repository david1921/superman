class MarketZipCode < ActiveRecord::Base
  belongs_to :market
  has_one :publisher, :through => :market
  validates_presence_of :market, :zip_code
  validates_uniqueness_of :zip_code, :scope => :market_id
  validate :unique_for_publisher_market
  validates_inclusion_of :state_code, :in => ::Addresses::Codes::US::STATE_CODES, :message => :invalid
  
  def unique_for_publisher_market
    if market.publisher && zip_code
      # Find an existing market_zip_code for this publisher and zip code
      match = MarketZipCode.find(:first, :joins => :market, :conditions => {
        :markets => {:publisher_id => market.publisher_id},
        :zip_code => zip_code
      })
      if match && match != self
        errors.add_to_base("market zip code can only belong to one publisher")
      end
    end
  end

end
