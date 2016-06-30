class Placement < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :offer
  
  named_scope :for_publisher, lambda { |publisher| { :conditions => { :publisher_id => publisher.id }}}
  named_scope :for_offer, lambda { |offer| { :conditions => { :offer_id => offer.id }}}

  def self.place_offer(offer)
    # [BR] there seems to be a bug in ActiveRecord's' has_one :publisher, :through => :advertiser.  If the publisher
    # association is accessed before the offer is saved offer.publisher returns nil so we have to reload the offer here.
    if publisher = (offer.publisher || offer.reload.publisher)
      offer.place_with(publisher.place_offers_with)
    end
  end
end
