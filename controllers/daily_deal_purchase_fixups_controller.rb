class DailyDealPurchaseFixupsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  before_filter :admin_privilege_required
  
  ITEMS_PER_PAGE = 50

  def index
    page = (params[:page] || "1").to_i
    @daily_deal_purchases = DailyDealPurchaseFixup.daily_deal_purchases_needing_fixup((page - 1)*ITEMS_PER_PAGE, ITEMS_PER_PAGE)
    @daily_deal_purchases = WillPaginate::Collection.create(page, ITEMS_PER_PAGE, DailyDealPurchaseFixup.daily_deal_purchases_needing_fixup_count) do |pager|
      pager.replace @daily_deal_purchases
    end
  end
  
  def create
    validation_errors = []
    params[:daily_deal_purchase_fixups].each do |daily_deal_purchase_id, attrs|
      DailyDealPurchaseFixup.find_all_by_daily_deal_purchase_id(daily_deal_purchase_id).each(&:destroy)
      fixup = case attrs[:fixup_type]
      when "nochange"
        NoChangeDailyDealPurchaseFixup.new(:daily_deal_purchase_id => daily_deal_purchase_id)
      when "badgross"
        BadGrossDailyDealPurchaseFixup.new(:daily_deal_purchase_id => daily_deal_purchase_id, :new_gross_price => attrs[:new_gross_price].if_present || attrs[:calculated_gross_price])
      when "refunded"
        RefundedDailyDealPurchaseFixup.new(:daily_deal_purchase_id => daily_deal_purchase_id, :refund_txn_id => attrs[:refund_txn_id], :refund_count => attrs[:refund_count], :new_gross_price => attrs[:new_gross_price].if_present || attrs[:calculated_gross_price])
      end
      if fixup && !fixup.save
        validation_errors << "#{daily_deal_purchase_id}: #{fixup.errors.full_messages.join(',')}"
      end
    end
    flash[:validation_errors] = validation_errors
    redirect_to :action => :index
  end
  
  def purchase_details
    @daily_deal_purchase = DailyDealPurchase.find_by_uuid(params[:id])
    render :layout => false
  end
  
  def braintree_details
    daily_deal_purchase = DailyDealPurchase.find_by_uuid(params[:id])
    daily_deal_purchase.publisher.find_braintree_credentials!
    
    @braintree_transactions = []
    @braintree_transactions << (purchase_txn = Braintree::Transaction.find(daily_deal_purchase.daily_deal_payment.payment_gateway_id))
    
    Braintree::Transaction.search do |search|
      search.created_at >= purchase_txn.created_at
      search.type.is Braintree::Transaction::Type::Credit
      search.refund.is true
      search.credit_card_number.starts_with purchase_txn.credit_card_details.bin
      search.credit_card_number.ends_with purchase_txn.credit_card_details.last_4
    end.each do |txn|
      @braintree_transactions << txn
    end
    render :layout => false
  end

  def purchases_details
    daily_deal_purchase = DailyDealPurchase.find_by_uuid(params[:id])
    conditions = ["id <> ? AND executed_at IS NOT NULL AND discount_id IS NULL", daily_deal_purchase.id]
    @daily_deal_purchases = daily_deal_purchase.daily_deal.daily_deal_purchases.all(:conditions => conditions)
    render :layout => false
  end
  
  protected
  
  def self.ssl_required? ; ssl_rails_environment? end

  def self.ssl_allowed? ; !ssl_rails_environment? end
end
