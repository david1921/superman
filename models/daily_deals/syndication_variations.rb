module DailyDeals
  module SyndicationVariations

  	def self.included(base)
  		base.send(:include, InstanceMethods)
  		base.class_eval do
  			alias_method_chain :daily_deal_variations, :syndication
  		end
  	end

  	module InstanceMethods

  		def daily_deal_variations_with_syndication
  			if syndicated?
  				source.daily_deal_variations
  			else
  				daily_deal_variations_without_syndication
  			end
  		end

  	end

  end
end