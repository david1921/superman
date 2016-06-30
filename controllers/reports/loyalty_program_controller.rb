class Reports::LoyaltyProgramController < ApplicationController
  
  include Reports::Reporting

  before_filter :user_required
  before_filter :set_publisher_from_id, :only => [:loyalty_eligible_for_publisher, :loyalty_analytics_for_publisher]
  layout 'reports'
  
  def loyalty_eligible_index
    @publishers = restrict_publishers(Publisher.with_purchases_eligible_for_loyalty_refund)
  end
  
  def loyalty_eligible_for_publisher
    @eligible_purchases = @publisher.purchases_eligible_for_loyalty_refund
  end
  
  def loyalty_analytics_index
    @publishers = restrict_publishers(Publisher.with_loyalty_program_deals)
  end
  
  def loyalty_analytics_for_publisher
    @dates = date_range_defaulting_to_last_30_days(params[:dates_begin], params[:dates_end])
    respond_to do |format|
      format.html
      format.xml do
        @purchases_with_loyalty_referrals = @publisher.purchases_with_loyalty_referrals(@dates)
      end
    end
  end
  
  private
  
  def set_publisher_from_id
    @publisher = Publisher.manageable_by(current_user).find(params[:id])
  end

  def restrict_publishers(publishers)
    publishers & Publisher.manageable_by(current_user)
  end
  
end