module DailyDealPurchases::Recipients

	# Assigns first daily deal purchase recipient using recipient attributes
  def assign_recipient_from_consumer_recipient(recipient, consumer)
  	if recipient.nil? || consumer.nil? || recipient.addressable != consumer
  		errors.add(:recipient, "stored shipping address could not be used")
  	else
	  	purchase_recipient = recipients.first || recipients.build
	  	fields = [:address_line_1, :address_line_2, :city, :country_id, 
	              :latitude, :longitude, :name, :phone_number, :region, :state, :zip]

	  	fields.each do |field|
	     	purchase_recipient[field] = recipient[field] 
	  	end
	  end
  end
end