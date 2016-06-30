class CreditCardsController < ApplicationController
  include Publishers::Themes
  include Api

  ssl_required_if_ssl_rails_environment :index, :create
  ssl_allowed :braintree_customer_redirect, :braintree_credit_card_redirect, :destroy

  before_filter :check_and_set_api_version_header_for_json_requests
  before_filter :login_via_session_for_json_request!, :except => [:braintree_customer_redirect, :braintree_credit_card_redirect]
  before_filter :set_and_check_consumer, :except => [:braintree_customer_redirect, :braintree_credit_card_redirect]
  
  skip_before_filter :verify_authenticity_token

  def index
    respond_to do |format|
      format.html do
        @publisher = @consumer.publisher
        @credit_cards = @consumer.credit_cards
        render with_theme(:layout => "daily_deals")
      end
      format.json do
        @credit_cards = @consumer.credit_cards
        render :layout => false
      end
    end
  end
  
  def create
    respond_to do |format|
      format.json do
        render :layout => false
      end
    end
  end
  
  def braintree_customer_redirect
    #
    # Redirect action for Braintree API returning a Braintree customer object
    #
    braintree_common_redirect do |result, consumer|
      braintree_customer = result.customer
      consumer.check_vault_id! braintree_customer.id
      braintree_customer.credit_cards[0]
    end
  end
  
  def braintree_credit_card_redirect
    #
    # Redirect action for Braintree API returning a Braintree credit-card object
    #
    braintree_common_redirect do |result, consumer|
      braintree_credit_card = result.credit_card
      consumer.check_vault_id! braintree_credit_card.customer_id
      braintree_credit_card
    end
  end
  
  def destroy
    @credit_card = @consumer.credit_cards.find(params[:id])
    @credit_card.destroy
    render :nothing => true, :status => @credit_card.destroyed? ? :ok : :conflict
  end
  
  private
  
  def set_and_check_consumer
    @consumer = Consumer.find_by_id(params[:consumer_id])
    render :nothing => true, :status => :not_found unless @consumer && current_consumer == @consumer
    !performed?
  end

  def braintree_common_redirect
    begin
      @consumer = Consumer.find(params[:consumer_id])
      @consumer.publisher.find_braintree_credentials!

      result = Braintree::TransparentRedirect.confirm(request.query_string)
      if result.success?
        braintree_credit_card = yield(result, @consumer)
        @credit_card = @consumer.create_or_update_credit_card(braintree_credit_card)
        respond_to do |format|
          format.json { render :braintree_common_redirect, :layout => false }
        end
      else
        respond_to do |format|
          format.json { render :json => { :errors => PaymentGateway::Error.list_from_braintree_result(result) }, :status => :conflict }
        end
      end
    rescue Braintree::NotFoundError, SecurityError
      respond_to do |format|
        format.json { render :nothing => true, :status => :forbidden }
      end
    end
  end
end
