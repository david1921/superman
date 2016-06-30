require File.dirname(__FILE__) + "/../../test_helper"

class OneClickPurchasesHelperTest < ActionView::TestCase

	context "text_for_recipient_select_option" do
		should "return address for recipient with short address" do
			recipient = Factory(:recipient, :name => "John Smith", :address_line_1 => "123 Main Street")
			assert_equal "John Smith, 123 Main Street", text_for_recipient_select_option(recipient)
		end

		should "return truncated address for recipient with long address" do
			recipient = Factory(:recipient, :name => "John Smith", :address_line_1 => "123 Super Long Name Street Avenue")
			assert_equal "John Smith, 123 Super Lon...", text_for_recipient_select_option(recipient)
		end
	end

end
