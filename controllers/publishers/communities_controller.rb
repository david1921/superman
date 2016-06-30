class Publishers::CommunitiesController < ApplicationController
  include Publishers::Themes

  before_filter :load_publisher

  layout with_theme("publishers/landing_page")

  def index
    # NOTE: This is a placeholder for the public communities (my community) page for TWC 
    # eventually we will probably want admin vs public functionality.
    render with_theme(:template => "publishers/communities/index") 
  end
  
  def learn_more
    # NOTE: this is just for the initial launch of TWC.
    render with_theme(:template => "publishers/communities/learn_more")
  end
  
  private
  
  def load_publisher
    @publisher = Publisher.find_by_label(params[:publisher_id])    
  end

end
