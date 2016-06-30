module OneClickPurchasesHelper
	def text_for_recipient_select_option(recipient)
		truncate("#{recipient.name}, #{recipient.address_line_1}", :length => 28)
	end
	def is_one_click_purchase_page?
    return controller_name == 'one_click_purchases'
	end
end
