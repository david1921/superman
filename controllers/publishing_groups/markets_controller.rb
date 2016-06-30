class PublishingGroups::MarketsController < ApplicationController
  include Publishers::Themes
  include Addresses::Validations

  before_filter :load_publishing_group
  before_filter :admin_privilege_required, :only => :index
  
  layout with_theme("landing_pages")
  
  def index
    respond_to do |format|
      format.xml {
        render :xml => Market.all
      }
    end
  end
  
  def search
    @zip_code  = params[:zip_code]
    if valid_us_zip_code?( @zip_code )
      @publisher = @publishing_group.publishers.launched.by_zip_code(@zip_code).first
      if @publisher
        set_zip_code_cookie( @zip_code )
        unless @publishing_group.redirect_to_deal_of_the_day_on_market_lookup?
          redirect_to publisher_landing_page_path(:publisher_id => @publisher.label)
        else
          redirect_to public_deal_of_day_path( @publisher.label )
        end
      else
        render with_theme(:template => "publishing_groups/markets/not_found")
      end
    else
      flash[:warn] = "Please enter a valid zip code."
      redirect_to publishing_group_landing_page_path(@publishing_group.label)
    end
  end

  def not_found
    render with_theme(:template => "publishing_groups/markets/not_found")
  end

  private

  def load_publishing_group
    @publishing_group = PublishingGroup.find_by_label( params[:publishing_group_id] )
  end

end
