module OffersHelper
  def city_state_zip(offer)
    return unless offer
    
    if offer.city && offer.state && offer.postal_code
      "#{offer.city}, #{offer.state} #{offer.postal_code}"
    elsif offer.city && offer.state
      "#{offer.city}, #{offer.state}"
    elsif offer.city && offer.postal_code
      "#{offer.city} #{offer.postal_code}"
    elsif offer.state && offer.postal_code
      "#{offer.state} #{offer.postal_code}"
    elsif offer.city
      offer.city
    elsif offer.state
      offer.state
    elsif offer.postal_code
      offer.postal_code
    end
  end
  
  def show_expires_on_unless_mcclatchy(offer)
    return if offer.publisher.publishing_group.try(:label) == "mcclatchy"
    return if offer.publisher.publishing_group.try(:label) == "cnhi" #ugly
    return if offer.publisher.publishing_group.try(:label) == "radarfrog" #really ugly
    if offer.expires_on.present?
      %Q{<span id="expires-on">Expires #{offer.expires_on.to_s(:compact)}.</span>}.html_safe
    end
  end
  
  # This (maybe) be public_offers_path, and replace lots of param-passing code
  def listing_view_path(publisher, coupon)
    if request.host[/^locm./]
      public_offers_path(:publisher_id => publisher.label, :offer_id => coupon)
    else
      public_offers_path(:publisher_id => publisher, :offer_id => coupon) 
    end
  end
end
