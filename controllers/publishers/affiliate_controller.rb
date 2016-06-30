class Publishers::AffiliateController < ApplicationController
  include Publishers::Themes
  
  before_filter :load_publisher
  before_filter :assign_market_by_label
  
  layout with_theme("publishers/affiliate")
  
  def show
    render with_theme(:template => "publishers/affiliate/show", :layout => "publishers/affiliate")
  end
  
  def faqs
    render with_theme(:template => "publishers/affiliate/faqs", :layout => "publishers/affiliate")
  end
  
  private
  
  def load_publisher
    label_or_id = params[:label] || params[:publisher_id]
    @publisher = Publisher.find_by_label_or_id!(label_or_id)
  end

  def assign_market_by_label
    if params[:market_label].present?
      @market = Market.find_all_by_publisher_id(@publisher_id).detect {|m| m.label == params[:market_label]}
    end
  end

end
