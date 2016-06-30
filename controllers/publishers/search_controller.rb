class Publishers::SearchController < ApplicationController
  include Publishers::Themes
  
  before_filter :load_publisher_by_label, :only => [:show]
  
  layout with_theme("publishers/search")

  def show
    @query        = params[:q]
    context      = params[:c]
    
    # TODO: adding paging when TWC okays the look of the main summary page
    paging = { :page => params[:page] || 1, :per_page => params[:page_size] || 10 }
    if valid_context?( context )      
      case context
      when 'dailydeals'
        @daily_deals = @publisher.daily_deals.active.with_text(@query)
        render with_theme(:template => "publishers/search/daily_deals")
      when 'offers'
        @offers      = @publisher.offers.active.with_text(@query)
        render with_theme(:template => "publishers/search/offers")              
      when 'sweepstakes'
        @sweepstakes = @publisher.sweepstakes.active.with_text(@query)
        render with_theme(:template => "publishers/search/sweepstakes")
      end
    else
      paging[:per_page] = 5 # show only 5 on the summary page
      unless @query.blank?
        @offers       = @publisher.offers.active.with_text(@query)
        @daily_deals  = @publisher.daily_deals.active.with_text(@query)
        @sweepstakes  = @publisher.sweepstakes.active.with_text(@query)
      end
      render with_theme(:template => "publishers/search/summary")      
    end
  end
    
  private
  
  def load_publisher_by_label
    @publisher = Publisher.find_by_label(params[:publisher_id])
  end
  
  def valid_context?( context )
    %w( dailydeals offers sweepstakes ).include?( context )
  end

end
