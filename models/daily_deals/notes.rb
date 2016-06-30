module DailyDeals
	module Notes

		def self.included(base)
			base.class_eval do
				has_many :notes, :as => :notable
			end
		end

	end
end