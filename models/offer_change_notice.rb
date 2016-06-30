class OfferChangeNotice
  def initialize(publisher, date)
    @publisher = publisher
    @date = date
  end
  
  def self.generate_head
    yield header_row
  end
  
  def generate_data
    offer_id_to_active_offer = @publisher.offers.active_on(@date).all.each_with_object({}) { |o, h| h[o.id] = o }
    
    conditions = "publisher_id = ? AND included_on < ? AND (excluded_on IS NULL OR excluded_on > ?)"
    conditions = [conditions, @publisher, @date, @date.yesterday]
    offer_id_to_offer_change = OfferChange.all(:conditions => conditions).each_with_object({}) { |c, h| h[c.offer_id] = c }
    
    advertiser_ids = Set.new(offer_id_to_active_offer.values.map(&:advertiser_id))
    advertiser_id_to_active_offer_count = advertiser_ids.each_with_object({}) do |advertiser_id, hash|
      hash[advertiser_id] = Offer.active_on(@date).count(:conditions => { :advertiser_id => advertiser_id })
    end
    offer_id_to_active_offer.each do |offer_id, active_offer|
      advertiser = active_offer.advertiser
      active_offer_count = advertiser_id_to_active_offer_count[advertiser.id]

      if offer_change = offer_id_to_offer_change[offer_id]
        if active_offer.updated_since?(offer_change.updated_at)
          offer_change.update_attributes! :updated_at => Time.now
          yield notice_row(advertiser.listing, offer_id, :updated, active_offer_count)
        end
      else
        OfferChange.create! :publisher => @publisher, :listing => advertiser.listing, :offer_id => offer_id, :included_on => @date
        yield notice_row(advertiser.listing, offer_id, :include, active_offer_count)
      end
    end
    
    listings = Set.new(offer_id_to_offer_change.values.map(&:listing))
    listing_to_active_offer_count = listings.each_with_object({}) do |listing, hash|
      if advertiser = Advertiser.find_by_publisher_id_and_listing(@publisher, listing)
        count = advertiser_id_to_active_offer_count[advertiser.id]
        hash[listing] = count ? count : Offer.active_on(@date).count(:conditions => { :advertiser_id => advertiser.id })
      else
        hash[listing] = 0
      end
    end
    offer_id_to_offer_change.each do |offer_id, offer_change|
      unless offer_id_to_active_offer[offer_id]
        listing = offer_change.listing
        active_offer_count = listing_to_active_offer_count[listing]
        offer_change.update_attributes! :excluded_on => @date
        yield notice_row(listing, offer_id, :exclude, active_offer_count)
      end
    end
  end
  
  private
  
  def self.header_row
    "AD\tCP\tFlag\tNum"
  end
  
  def notice_row(listing, offer_id, change_type, active_offer_count)
    "#{listing}\t#{offer_id}\t%s\t#{active_offer_count}" % {
      :include => "A",
      :exclude => "D",
      :updated => "U"
    }[change_type]
  end
end
