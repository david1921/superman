module DailyDeals
	module SourceChannel

		SOURCES = ["self-serve", "electronic face-to-face", "paper face-to-face", "telephone"]

		def self.included(base)
			base.class_eval do
				# NOTE: do we remove allow_blank and allow_nil once we turn on source channel for daily deals???
				validates_inclusion_of :source_channel, :in => SOURCES, :allow_blank => true, :allow_nil => true
			end
		end

	end
end