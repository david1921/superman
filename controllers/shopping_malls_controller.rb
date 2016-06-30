class ShoppingMallsController < ApplicationController
  include Publishers::Themes
  include Analog::Referer::Controller

  before_filter :set_referer_information, :only => [:show]
  before_filter :assign_publisher_and_market, :only => [ :show ]
  layout with_theme(["shopping_malls", "daily_deals"])

  def show
    page = params[:page] || 1
    per_page = params[:per_page] || 70
    active_deals = @publisher.daily_deals.active
    if @market
      @daily_deals = active_deals.in_market(@market)
    else
      @daily_deals = active_deals.shopping_mall_or_featured # sorted featured DESC, daily_deals.created_at DESC
    end
    
    @daily_deals = @daily_deals.paginate(:page => page, :per_page => per_page)
    render with_theme :template => "shopping_malls/show"
  end

  private

  def assign_publisher_and_market
    @publisher   = Publisher.find_by_label!(extract_label_from_params)

    if params[:market_label].present?
      @market = Market.find_all_by_publisher_id(@publisher.id).detect {|m| m.label == params[:market_label].downcase }
    end
  end

  def extract_label_from_params
    params[:publisher_id].present? ? params[:publisher_id] : params[:label]
  end

end
