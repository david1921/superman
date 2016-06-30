module DailyDeals
	module Status

		STATUSES = ["Draft", "Awaiting Approval", "Approved", "Rejected", "Live", "Closed", "Withdrawn"]

		def self.included(base)
			base.class_eval do
				# NOTE: remove allow_blank and allow_nil once we turn on statuses for daily deals.
				validates_inclusion_of :status, :in => STATUSES, :allow_blank => true, :allow_nil => true
			end
		end

	end
end