class InteractivesController < ApplicationController
  include Publishers::Themes
  
  before_filter :require_publishing_group!, :only => [:offer, :create_offer, :sweepstake, :create_sweepstake]
  
  
  layout with_theme("public_index")

  def offer
    render with_theme(:layout => false)     
  end
  
  def create_offer  
    @offer = Offer.by_publishing_group( @publishing_group ).by_coupon_code( params[:code] ).first
    if @offer && params[:code].present? # make sure we have an offer and that we got one with a code (not a blank code)
      render with_theme(:template => "interactives/offer", :layout => false)
    else
      flash[:error] = "Sorry, that is an invalid code."
      redirect_to offer_publishing_group_interactives_path( @publishing_group.label )
    end
  end
  
  def sweepstake  
    @subscriber = Subscriber.new
    render with_theme(:layout => false)
  end
  
  def create_sweepstake
    @offer  = Offer.by_publishing_group( @publishing_group ).by_coupon_code( params[:code] ).first
    @errors = []
    if @offer && params[:code].present?
      @subscriber           = @offer.publisher.subscribers.build(params[:subscriber])
      if @subscriber.save
        @success = true
      else
        @errors = @subscriber.errors.full_messages
      end
    else
      @subscriber           = @publishing_group.publishers.first.subscribers.build( params[:subscriber] )
      @errors               = @subscriber.errors.full_messages unless @subscriber.valid? # assign error messages      
      @errors << "Sorry, that is an invalid code."      
    end 
    render with_theme(:template => "interactives/sweepstake", :layout => false)
  end
  
  private
  
  def require_publishing_group!
    @publishing_group = params[:publishing_group_id].present? ? PublishingGroup.find_by_label(params[:publishing_group_id]) : nil
    render_404 and return false unless @publishing_group
  end

end
