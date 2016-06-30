class Publishers::LandingPagesController < ApplicationController
  include Publishers::Themes
  
  before_filter :load_publisher
  before_filter :set_publishing_group_from_publisher
  before_filter :redirect_to_publisher_based_on_zip_code, :only => [:show]
  
  layout with_theme("publishers/landing_page")
  
  # NOTE: this is pretty much setup for TWC home page.
  def show
    @daily_deal = @publisher.daily_deals.current_or_previous if @publisher.daily_deals
    @advertiser = @daily_deal.advertiser if @daily_deal
    # TODO: shuffle would work here, but ruby 1.8.6 doesn't support it.  so using sort_by {rand} -- need to clean this up
    @offers     = @publisher.offers.active.featured_for_landing_page.sort_by { rand }[0..1] # get two random offers. NOTE: we might need only grap featured ones    
    render with_theme(:template => "publishers/landing_pages/show") 
  end

  private
  
  def load_publisher
    @publisher = Publisher.find_by_label(params[:publisher_id])
  end
  
  def set_publishing_group_from_publisher
    @publishing_group = @publisher.try(:publishing_group)
  end
  
end
