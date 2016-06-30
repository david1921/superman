class SignupsController < ApplicationController
  include Publishers::Themes

  layout with_theme("daily_deals")
  
  def create
    @publisher = Publisher.find_by_label!(params[:publisher_id])
    @consumer = Consumer.build_unactivated(@publisher, params.reverse_merge(:referral_code => cookies[:referral_code]))
    if @consumer.save
      redirect_to thank_you_publisher_signups_path(
        @publisher.label, 
        :email => @consumer.email, 
        :discount => @consumer.try(:signup_discount).try(:amount),
        :utm_campaign => params[:utm_campaign], 
        :utm_medium => params[:utm_medium], 
        :utm_source => params[:utm_source]        
      )
    else
      redirect_to error_publisher_signups_path(@publisher.label)
    end
  end
  
  def thank_you
    @publisher = Publisher.find_by_label!(params[:publisher_id])
    @daily_deal = @publisher.daily_deals.current_or_previous
    
    if params[:email].present?
      @email = params[:email]
      @discount = params[:discount]
    else
      redirect_to error_publisher_signups_path(@publisher.label)
    end
  end

  def error
    @publisher = Publisher.find_by_label!(params[:publisher_id])
  end
end
