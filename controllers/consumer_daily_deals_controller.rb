class ConsumerDailyDealsController < ApplicationController
	include Publishers::Themes

	before_filter :consumer_required
	before_filter :set_publisher

  def index  	
  	# TODO:
  	#   -- we need to add the notion of saved daily deals to the consumer record.
  	render with_theme(:layout => :daily_deals)
  end

  private

  def set_publisher
  	@publisher = current_user.publisher || current_user.company
  end

 
end
