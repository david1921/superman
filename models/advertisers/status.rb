module Advertisers
	module Status

		APPROVED	= :approved
		PENDING 	= :pending
		SUSPENDED = :suspended

    STATUSES = [PENDING, APPROVED, SUSPENDED]

		def self.included(base)
			base.class_eval do
			  state_machine :status, :initial => PENDING do
			  	state APPROVED, PENDING, SUSPENDED
			  	after_transition [PENDING, SUSPENDED] => APPROVED, :do => :update_offers_advertiser_active
			  	event :approve do
			  		transition [PENDING, SUSPENDED] => APPROVED
			  	end
			  	event :suspend do
			  		transition [PENDING, APPROVED] => SUSPENDED
			  	end
			  end
			end
		end

	end
end