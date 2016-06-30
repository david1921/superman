class ThirdPartyEventsController < ApplicationController
  # reporting has been pushed to another story
  # before_filter :user_required, :only => [ :index]
  # before_filter :admin_privilege_required, :only => [ :index ]
  
  def index
    # Show everything till I actually get specs for this
    @events = ThirdPartyEvent.all
    render
  end

  def create_as_get
    if validate_params_based_on_event
      event_attrs = params[:event].merge({
        :visitor =>  visitor,
        :third_party => third_party,
        :third_party_label => params[:third_party_label], 
        :target => target,
        :ip_address => request.remote_ip,
        :session_id => params[:session_id] || session[:session_id]
      })

      @event = ThirdPartyEvent.create(event_attrs)
      
      if !@event.valid?
       raise @event.errors.full_messages
       render :text => @event.errors.full_messages, :status => :not_acceptable
      else
        create_purchase_records!(params[:purchases]) if @event.action == 'purchase'
        
        pixel_file = "public/images/aa_affiliate_tracking.gif" # standard 1x1 invisi-pixel
        send_file pixel_file, :type => 'image/gif'
      end
    else # params failed validations
      raise "Require parameters not given"
    end
  end
  
  def tracker
    # This is the bootstraping javascript file that provides the AA_EVENT javascript object
  end
  
  # not sure how relavant this action is anymore
  def example
    @visitor = Consumer.last
    @publisher = @visitor.publisher
    @deal = @publisher.daily_deals.last
    render :layout => false
  end
  
  protected
  def visitor
    @visitor ||= find_or_create_visitor_by_email(params[:visitor][:email], params[:visitor].merge({:publisher_id => third_party.publisher.id})) if (!params[:visitor].blank?  && !params[:visitor][:email].blank?)
  end
  
  def third_party
    @third_party ||=  Advertiser.find(params[:third_party][:id]) if !params[:third_party].blank? && !params[:third_party][:id].blank? 
  end

  def target
    @target ||= DailyDeal.find(params[:target][:id]) if (!params[:target].blank? && target_type_is_daily_deal? && !target_type_is_nil?)
  end
  
  def purchases
    @event.purchases
  end
  
  private
  def validate_params_based_on_event
    # all requests MUST have at least a valid action defined
    if params[:event].blank? || params[:event][:action].blank? || !ThirdPartyEvent::VALID_ACTIONS.include?(params[:event][:action])
      return false
    end
    
    return true
    case params[:event][:action]
    when /redirect/
      return (!params[:third_party].blank? && !params[:third_party][:id].blank?) &&
        (!params[:target].blank? && !params[:target][:id].blank?)    
    when /landing/ || /lightbox/
      return !params[:session_id].blank?     
    when /purchase/
      return (!params[:session_id].blank? && !params[:purchases].blank?) && (!params[:purchases].empty?) 
    else
      return false
    end
  end

  def find_or_create_visitor_by_email(email,attrs = {})
    User.find_by_email(params[:visitor][:email]) ||
      Subscriber.find_or_create_by_email(params[:visitor][:email], attrs)
  end
  
  def create_purchase_records!(purchases = {})
    return false if purchases.empty?
    purchases.each do |p|
      # due to having to keep the purchases together from javascript through the request into rails, each purchase is keyed by an incremental indexed hash, so the purchase is really at purchases[0], hence using p.last
      pur = ThirdPartyEventPurchase.create(p.last.merge(:third_party_event => @event))
      raise pur.errors.full_messages if !pur.valid?
    end
  end
    
  def target_type_is_daily_deal?
    (params[:target][:id].present? && params[:target][:type].downcase == 'dailydeal' )
  end
  
  def target_type_is_nil?
    (params[:target].nil?) || (params[:target][:type].nil?)
  end

end