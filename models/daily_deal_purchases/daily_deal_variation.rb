module DailyDealPurchases
	module DailyDealVariation

		def self.included(base)
			base.class_eval do
				belongs_to :daily_deal_variation				
			end
		end
	end
end