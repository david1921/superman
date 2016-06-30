class DailyDealOrdersController < ApplicationController
  include DailyDeals::Analytics
  include DailyDeals::Orders
  include Publishers::Themes
  
  if ssl_rails_environment?
    ssl_required :current, :braintree_redirect
  else
    ssl_allowed :current, :braintree_redirect
  end
  ssl_allowed :execute_free
  
  layout with_theme("daily_deals")
  
  before_filter :set_daily_deal_order,      :only => [ :braintree_redirect, :thank_you, :execute_free ]
  before_filter :load_publisher_by_label,   :only => [ :current ]

  def current
    @daily_deal_order = current_daily_deal_order(@publisher)
  end

  def braintree_redirect
    @publisher.find_braintree_credentials!
    begin
      @result = Braintree::TransparentRedirect.confirm(request.query_string)
    rescue Braintree::NotFoundError
      #
      # Probably a client reload of the transparent-redirect URL after it was already processed.
      #
      logger.warn("[DailyDealOrder] we were unable to find braintree result for #{@daily_deal_order}")
      return redirect_after_duplicate_braintree_transaction
    end
    if @result.success?
      BraintreeGatewayResult.create :daily_deal_order => @daily_deal_order, :error => false
      braintree_transaction = @result.transaction
      begin
        @daily_deal_order.handle_braintree_sale! braintree_transaction
      rescue DailyDealPurchase::AlreadyExecutedError => error
        #
        # Probably a resubmission of the credit-card form for an already executed purchase.
        #
        logger.warn("[DailyDealOrder] already executed on #{@daily_deal_order} -- error: #{error}")
        void_duplicate_braintree_transaction braintree_transaction
        return redirect_after_duplicate_braintree_transaction
      rescue Timeout::Error
        # just gobble this up, means the pdf had a hard time getting some outside resource like
        # the publisher logo.  we want to continue on like everything is normal.
        # NOTE: we can remove this once we have email handling in a queue.
        logger.warn("[DailyDealOrder] we timed out issuing a handle_braintree_sale! on #{@daily_deal_order} with #{@result.inspect}")
      end
      if @daily_deal_order.executed?
        #
        # FIXME: Is the following auto-login step a security hole?
        #
        session[:daily_deal_order] = nil
        set_up_session @daily_deal_order.consumer unless @daily_deal_order.consumer == current_consumer
        cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
        set_analytics_tag
        redirect_to thank_you_daily_deal_order_path(@daily_deal_order)
        return 
      end
    end
    BraintreeGatewayResult.create :daily_deal_order => @daily_deal_order, :error => true, :error_message => @result.message    
    flash.now[:warn] = "Sorry, we couldn't complete this purchase with the card information you provided. Please try again."
    render :current 
  end
  
  def execute_free
    @daily_deal_order.execute_without_payment!
    cookies[:deal_credit] = { :value => "applied", :expires => 1.month.from_now }
    set_analytics_tag
    redirect_to thank_you_daily_deal_order_path(@daily_deal_order)
  end

  private

  def set_daily_deal_order
    @daily_deal_order = DailyDealOrder.find_by_uuid!(params[:id], :include => { :consumer => :publisher })
    @consumer = @daily_deal_order.consumer
    @publisher = @consumer.publisher
  end

  def load_publisher_by_label
    @publisher = Publisher.find_by_label!( params[:label] )
  end
  
  def redirect_after_duplicate_braintree_transaction
    if !@daily_deal_order.executed?
      flash[:warn] = "Sorry, we couldn't complete this purchase. Please try again."
      return redirect_to(publisher_cart_path(@publisher.label))
    elsif @daily_deal_order.consumer == current_consumer
      set_analytics_tag
      return redirect_to(thank_you_daily_deal_order_path(@daily_deal_order))
    else
      return redirect_to(public_deal_of_day_path(@daily_deal_order.publisher.label))
    end
  end
  
  def void_duplicate_braintree_transaction(braintree_transaction)
    # TODO: not sure what it means to void an order, perhaps iterating through all the daily deal purchases and voiding.
    # For now, just log this issue and we can figure it out.
    logger.warn("[DailyDealOrder] should void braintree transaction: #{braintree_transaction} for daily deal order: #{@daily_deal_order}")
  end
  
end
