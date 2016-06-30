require File.dirname(__FILE__) + "/../test_helper"

# In Rails 2.3.8 this works as expected, a newer version
# will probably not use the base class name as the addressable_type

class RecipientTest < ActiveSupport::TestCase
	context "type" do
		context "user" do
			setup do
				@consumer = Factory(:consumer)
				@recipient = Factory(:recipient, :addressable => @consumer)
			end

			should "have a User type" do
				assert_equal 'User', @recipient.addressable_type
				assert_equal @consumer, @recipient.addressable
				assert @consumer.recipients.include?(@recipient)
			end
		end
	end
end
