module OffersTestHelper
  def create_offer_for(publisher, options={})
    index = options[:index] || 0
    advertiser = publisher.advertisers.create!
    if options[:store]
      advertiser.stores.create!(
        :address_line_1 => "#{index * 1000} Barnes Canyon Road",
        :city => "San Diego",
        :state => "CA",
        :zip => "92121",
        :phone_number => "858-123-4567"
      )
    end
    advertiser.offers.create!(
      :message => "Offer #{index}",
      :categories => options[:categories] || [categories(:restaurants)]
    )
  end  
end
