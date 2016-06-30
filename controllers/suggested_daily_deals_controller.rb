class SuggestedDailyDealsController < ApplicationController
  include Publishers::Themes

  before_filter :set_publisher
  before_filter :logged_in_for_publisher

  def create
    @suggested_daily_deal = @publisher.suggested_daily_deals.build(params[:suggested_daily_deal])
    @suggested_daily_deal.consumer = current_consumer

    @theme_template_format = :html # rails defaults format to :js when using ajax
    if @suggested_daily_deal.save
      render with_theme(:template => "suggested_daily_deals/thank_you")
    else
      render with_theme(:template => "suggested_daily_deals/_form", :locals => {:suggested_daily_deal => @suggested_daily_deal})
    end
  end

  private

  def set_publisher
    @publisher = Publisher.find(params[:publisher_id])
  end

  def logged_in_for_publisher
    consumer_login_required(@publisher)
  end
end
