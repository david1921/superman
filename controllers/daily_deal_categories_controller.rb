class DailyDealCategoriesController < ApplicationController
  include DailyDeals::Filtering
  include Publishers::Themes
  include ::Consumers::RedirectToLocalDeal
  include ::Consumers::ValidConsumers

  before_filter :set_publisher
  
  before_filter :redirect_to_local_publisher_daily_deals_categories, :only => [:index], :unless => :api_request_or_admin_or_consumer_has_master_membership_code?
  before_filter :redirect_to_local_publisher_daily_deals_category,   :only => [:show],  :unless => :api_request_or_admin_or_consumer_has_master_membership_code?
  before_filter :ensure_valid_consumer

  layout with_theme("daily_deals")

  def index
    @daily_deal_categories = @publisher.daily_deal_categories_with_deals.ordered_by_name_ascending

    render with_theme
  end

  def show
    @daily_deal_category = DailyDealCategory.for_publisher(@publisher).find(params[:id])
    @daily_deals = find_available_daily_deals(:categories => [@daily_deal_category])

    @featured_deal = @daily_deals.ordered_by_next_featured_in_category.first
    @side_deals = @daily_deals.not_in([@featured_deal].compact).paginate(:page => params[:page], :per_page => params[:per_page])

    @daily_deals = @daily_deals.paginate(:page => params[:page], :per_page => params[:per_page])

    render with_theme
  end

  private

  def set_publisher
    @publisher = Publisher.find(params[:publisher_id])
  end
end
