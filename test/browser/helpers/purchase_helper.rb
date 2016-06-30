
module Helpers
	module PurchaseHelper

		def fill_in_payment_form
	    fill_in "Cardholder Name *:", :with => Faker::Name.name
	    fill_in "Card Number *:", :with => "4111111111111111"
	    fill_in "CVV *:", :with => "123"
	    fill_in "Billing Address Line 1 *", :with => Faker::Address.street_address
	    fill_in "Billing Address City *", :with => Faker::Address.city
	    fill_in "Billing ZIP Code *:", :with => Faker::Address.zip_code
	  end

	  def fill_in_registration_form
	    fill_in "Your Name:", :with => "John Doe"
	    fill_in "Email:", :with => "jdoe@analoganalytics.com"
	    fill_in "Password:", :with => "password"
	    fill_in "Confirm Password:", :with => "password"
	    check "I agree to the Terms and Privacy Policy"
	  end 

	end
end
