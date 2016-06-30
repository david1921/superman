class Publishers::ContactRequestsController < ApplicationController
  include Publishers::Themes

  before_filter :set_publisher

  layout with_theme("daily_deals")

  def index
    redirect_to :action => :new, :publisher_id => @publisher.id
  end

  protected

  def set_publisher
    @publisher = Publisher.find(params[:publisher_id])
  end
end
