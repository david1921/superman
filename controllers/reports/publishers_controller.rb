class Reports::PublishersController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include Reports::Reporting

  before_filter :user_required
  before_filter :admin_or_publishing_group_user_required, 
    :except => [ :show, :purchased_gift_certificates, 
                 :purchased_daily_deals, :purchased_daily_deals_by_market, :affiliated_daily_deals, 
                 :refunded_daily_deals, :refunded_daily_deals_by_market,
                 :subscribers, :referrals, :paychex ]
  
  layout 'reports'
  
  def index
    @dates = date_range_defaulting_to_last_month(params[:dates_begin], params[:dates_end])
    @summary = params[:summary] || "reports_home"

    return if @summary == "reports_home"

    @publishers = Publisher.observable_by(current_user).all
    case @summary
    when "web_offers"
      return index_with_web_offers
    when "billing"
      return index_with_billing
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def show
    publisher = Publisher.observable_by(current_user).find(params[:id])
    redirect_to reports_publisher_advertisers_path(publisher)
  end

  def purchased_gift_certificates
    @dates = date_range(params[:dates_begin], params[:dates_end])
    @publisher = Publisher.observable_by(current_user).find(params[:id])
    @purchased_gift_certificates = @publisher.purchased_gift_certificates_completed(@dates).sort do |a, b|
      case advertiser_name_order = a.advertiser_name <=> b.advertiser_name
      when +1, -1
        advertiser_name_order
      when 0
        a.paypal_payment_date <=> b.paypal_payment_date
      end
    end
    
    respond_to do |format|
      format.html do
        set_crumb_prefix
        if admin? || publishing_group?
          add_crumb "Publishers"
          add_crumb @publisher.name, reports_publisher_path(@publisher)
        end
      end

      format.xml
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} purchased certificates, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Advertiser",
            "Deal Certificate",
            "Currency Code",
            "Value",
            "Purchase Price",
            "Purchase Date",
            "Serial Number",
            "Name",
            "Street",
            "City",
            "State",
            "ZIP",
            "Email",
            "Redemption Status"
          ]
          @purchased_gift_certificates.each do |purchased_gift_certificate|
            csv << [
              purchased_gift_certificate.gift_certificate.advertiser.name,
              purchased_gift_certificate.gift_certificate.item_number,
              purchased_gift_certificate.currency_code,
              number_to_currency(purchased_gift_certificate.value, :unit => purchased_gift_certificate.currency_symbol),
              number_to_currency(purchased_gift_certificate.paypal_payment_gross, :unit => purchased_gift_certificate.currency_symbol),
              purchased_gift_certificate.paypal_payment_date,
              purchased_gift_certificate.serial_number,
              purchased_gift_certificate.recipient_name,
              purchased_gift_certificate.paypal_address_street,
              purchased_gift_certificate.paypal_address_city,
              purchased_gift_certificate.paypal_address_state,
              purchased_gift_certificate.paypal_address_zip,
              purchased_gift_certificate.paypal_payer_email,
              purchased_gift_certificate.status
            ]
          end
        end        
      end
    end
  end
  
  def purchased_daily_deals
    @dates = date_range(params[:dates_begin], params[:dates_end])
    @publisher = Publisher.observable_by(current_user).find(params[:id])
    @market = @publisher.markets.find(params[:market_id].to_i) if params[:market_id].present?    
    respond_to do |format|
      format.html do
        set_crumb_prefix
        if admin? || publishing_group?
          add_crumb "Publishers"
          add_crumb @publisher.name, reports_publisher_path(@publisher)
        end
      end

      format.xml do
        @daily_deals = @publisher.daily_deals_summary(@dates, @market)
      end
      
      format.csv do 
        @daily_deals = @publisher.daily_deals_summary(@dates, @market)
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} Purchased Daily Deals, "
        filename << "#{@market.name}, " if @market.present?
        filename << "%s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          header = []
          header << "Started At"
          header << "Ended At"
          header << "Source Publisher" if admin?
          header << "Advertiser"
          header << "Publisher Advertiser ID"
          header << "Accounting ID"
          header << "Listing ID"
          header << "Value"
          header << "Purchased"
          header << "Purchasers"
          header << "Currency Code"
          header << "Gross"
          header << "Publisher Discount"
          header << "Refunds #"
          header << "Refunds #{@publisher.currency_symbol}"
          header << "Total"
          header << "Account Executive"
          header << "Advertiser Rev. %"
          header << "Advertiser Credit %"
          header << "Custom 1"
          header << "Custom 2"
          header << "Custom 3"
          csv << header
          
          @daily_deals.each do |daily_deal|
            row = []
            row << daily_deal.start_at.to_s(:compact)
            row << daily_deal.hide_at.to_s(:compact)
            row << daily_deal.source_publisher.try(:name) if admin?
            row << daily_deal.advertiser_name            
            row << daily_deal.advertiser.try(:listing)
            row << daily_deal.daily_deal_or_variation_accounting_id
            row << daily_deal.daily_deal_or_variation_listing
            row << daily_deal.daily_deal_or_variation_value_proposition
            row << daily_deal.daily_deal_purchases_total_quantity
            row << daily_deal.daily_deal_purchasers_count
            row << daily_deal.currency_code
            row << daily_deal.daily_deal_purchases_gross
            row << daily_deal.daily_deal_purchases_gross - daily_deal.daily_deal_purchases_amount
            row << daily_deal.daily_deal_refunded_voucher_count
            row << daily_deal.daily_deal_refunds_total_amount
            row << daily_deal.daily_deal_purchases_amount - daily_deal.daily_deal_refunds_total_amount
            row << daily_deal.account_executive
            row << daily_deal.advertiser_revenue_share_percentage
            row << daily_deal.advertiser_credit_percentage
            row << daily_deal.custom_1
            row << daily_deal.custom_2
            row << daily_deal.custom_3
            csv << row
          end
        end
      end
    end    
  end

  def affiliated_daily_deals
    @dates = date_range(params[:dates_begin], params[:dates_end])
    @publisher = Publisher.observable_by(current_user).find(params[:id])    
    respond_to do |format|
      format.html do
        set_crumb_prefix
        if admin? || publishing_group?
          add_crumb "Publishers"
          add_crumb @publisher.name, reports_publisher_path(@publisher)
        end
      end

      format.xml do
        @daily_deals = @publisher.daily_deals_with_affiliated_daily_deal_counts(@dates)
      end

      format.csv do 
        @daily_deals = @publisher.daily_deals_with_affiliated_daily_deal_counts(@dates)
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} affiliated deals, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Started At",
            "Advertiser",
            "Accounting ID",
            "Listing",
            "Value Proposition",
            "Purchases",
            "Purchasers",
            "Currency Code",
            "Affiliate Gross",
            "Affiliate Rev. Share",
            "Affiliate Payout",
            "Affiliate Total",
            "Custom 1",
            "Custom 2",
            "Custom 3"
          ]
          @daily_deals.each do |daily_deal|
            csv << [
              daily_deal.start_at.to_s(:compact),              
              daily_deal.advertiser_name,  
              daily_deal.accounting_id,
              daily_deal.listing,
              daily_deal.value_proposition,
              daily_deal.daily_deal_affiliate_total_quantity,
              daily_deal.daily_deal_purchasers_count,
              daily_deal.currency_code,
              daily_deal.daily_deal_affiliate_gross,
              daily_deal.affiliate_revenue_share_percentage,
              daily_deal.daily_deal_affiliate_payout,
              daily_deal.daily_deal_affiliate_gross - daily_deal.daily_deal_affiliate_payout,
              daily_deal.custom_1,
              daily_deal.custom_2,
              daily_deal.custom_3
            ]
          end
        end
      end
    end
  end
  
  def refunded_daily_deals
    @dates = date_range(params[:dates_begin], params[:dates_end])
    @publisher = Publisher.observable_by(current_user).find(params[:id])
    @market = @publisher.markets.find(params[:market_id].to_i) if params[:market_id].present?
    
    respond_to do |format|
      format.html do
        set_crumb_prefix
        if admin? || publishing_group?
          add_crumb "Publishers"
          add_crumb @publisher.name, reports_publisher_path(@publisher)
        end
      end

      format.xml do
        @daily_deals = @publisher.daily_deals_with_refund_counts(@dates, @market)
      end
      
      format.csv do 
        @daily_deals = @publisher.daily_deals_with_refund_counts(@dates, @market)
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} Refunded Daily Deals, "
        filename << "#{@market.name}, " if @market.present?
        filename << "%s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Started At",
            "Advertiser",
            "Accounting ID",
            "Listing",
            "Value Proposition",
            "Purchasers Refunded",
            "Purchases Refunded",
            "Vouchers Refunded",
            "Currency Code",
            "Gross Refunded",
            "Discount",
            "Total Refunded",
            "Custom 1",
            "Custom 2",
            "Custom 3"
          ]
          @daily_deals.each do |daily_deal|
            csv << [
              daily_deal.start_at.to_s(:compact),              
              daily_deal.advertiser_name,  
              daily_deal.accounting_id,
              daily_deal.listing,
              daily_deal.value_proposition,
              daily_deal.daily_deal_refunded_purchasers_count,
              daily_deal.daily_deal_refunded_purchases_count,
              daily_deal.daily_deal_vouchers_refunded_count,
              daily_deal.currency_code,
              daily_deal.daily_deal_refunds_gross,
              daily_deal.daily_deal_refunds_gross - daily_deal.daily_deal_refunds_amount,
              daily_deal.daily_deal_refunds_amount,
              daily_deal.custom_1,
              daily_deal.custom_2,
              daily_deal.custom_3
            ]
          end
        end
      end
    end    
  end
  

  def daily_deals
    @dates = date_range_defaulting_to_last_month(params[:dates_begin], params[:dates_end])
    @publishers = Publisher.observable_by(current_user).all
    respond_to do |format|
      format.html do
        set_crumb_prefix
      end

      format.xml

      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "Publishers Report, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Publisher",
            "Facebook Shares",
            "Twitter Shares"
          ]
          @publishers.sort_by(&:name).each do |publisher|
            csv << [
              publisher.name,
              publisher.facebooks_count(@dates, 'DailyDeal'),
              publisher.twitters_count(@dates, 'DailyDeal')
            ]
          end
        end
      end
    end
  end

  def subscribers
    @dates       = date_range(params[:dates_begin], params[:dates_end])
    @publisher   = Publisher.observable_by(current_user).find(params[:id])
    @subscribers = @publisher.subscribers_in_date_range(@dates)

    respond_to do |format|
      format.html do
        set_crumb_prefix
      end

      format.xml

      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename        = "Publisher Subscribers Report, %s to %s.csv" % formatted_dates

        stream_csv(filename) do |csv|
          csv << ["Email", "Zip Code", "First Name", "Last Name"]

          @subscribers.each do |subscriber|
            csv << [subscriber.email, subscriber.zip_code, subscriber.first_name, subscriber.last_name]
          end
        end
      end
    end
  end

  def referrals
    @dates = date_range(params[:dates_begin], params[:dates_end])
    @publisher = Publisher.observable_by(current_user).find(params[:id])
    @referrals = @publisher.referrals_in_date_range(@dates)
    
    respond_to do |format|
      format.html do
        set_crumb_prefix
      end

      format.xml

      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename        = "Publisher Referrals Report, %s to %s.csv" % formatted_dates

        stream_csv(filename) do |csv|
          csv << ["Email", "Referral Count", "Credits Given", "Credit Used"]

          @referrals.each do |referrals|
            csv << [referrals.email, referrals.referral_count, referrals.credits_given, referrals.credit_used]
          end
        end
      end
    end
  end

  def paychex
    @date = date_or_today(params[:date])
    @publisher = Publisher.observable_by(current_user).find(params[:id])
    
    respond_to do |format|
      format.html do        
        set_crumb_prefix
      end

      format.xml do
        @daily_deals = @publisher.paychex_daily_deal_reports(@date)
      end

      format.csv do
        date = @date.to_formatted_s(:db_date)
        @daily_deals = @publisher.paychex_daily_deal_reports(@date)
        filename = "#{@publisher.name} Paychex Report, %s.csv" % date
        stream_csv(filename) do |csv|
          csv << [
            "Payment Period Ending",
            "Merchant ID",
            "Merchant Name",
            "Merchant Tax ID",
            "Deal ID",
            "Deal Headline",
            "Deal Start Date",
            "Deal End Date",
            "Last Modified By",
            "# Purchased",
            "Gross $",
            "CC Fee $",
            "# Refunds",
            "Refunds $",
            "Adv. Split %",
            "Adv. Earned to Date $",
            "Adv. Due to Date $"
          ]
          @daily_deals.each do |daily_deal|
            csv << [
              date,
              daily_deal.advertiser_id,
              daily_deal.advertiser_name,
              daily_deal.advertiser.federal_tax_id,
              "BBD-" + daily_deal.id.to_s,
              daily_deal.value_proposition,
              daily_deal.start_at.to_formatted_s(:db_date),
              daily_deal.hide_at.to_formatted_s(:db_date),
              "",
              daily_deal.number_sold(@date),
              "%.2f" % daily_deal.gross_revenue_to_date.round(2),
              "%.2f" % daily_deal.paychex_credit_card_fee.round(2),
              daily_deal.number_refunded(@date),
              "%.2f" % daily_deal.daily_deal_refunds_total_amount.round(2),
              daily_deal.advertiser_revenue_share_percentage,
              "%.2f" % daily_deal.paychex_advertiser_share.round(2),
              "%.2f" % daily_deal.paychex_total_payment_due(@date).round(2)
            ]
          end
        end
      end
    end
  end
  
  def purchased_daily_deals_by_market
    @publisher = Publisher.observable_by(current_user).find(params[:id])
    @dates = date_range_defaulting_to_last_month(params[:dates_begin], params[:dates_end])
    @markets = Publisher.all_with_purchased_daily_deal_counts_by_market(@dates, @publisher)
    respond_to do |format|
      format.html do
        set_crumb_prefix
      end
      
      format.xml
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} Purchased Daily Deals By Market, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Market",
            "Deals",
            "Purchased",
            "Purchasers",
            "Currency Code",
            "Gross",
            "Discount",
            "Refunds",
            "Total"
          ]
          @markets.sort_by(&:name).each do |market|
            csv << [
              market.name,
              market.daily_deals_count,
              market.daily_deal_purchases_total_quantity,
              market.daily_deal_purchasers_count,
              market.currency_code,
              market.daily_deal_purchases_gross,
              market.daily_deal_purchases_gross - market.daily_deal_purchases_actual_purchase_price,
              market.daily_deal_purchases_refund_amount,
              market.daily_deal_purchases_actual_purchase_price - market.daily_deal_purchases_refund_amount
            ]
          end
        end                
      end
    end
  end
  
  def refunded_daily_deals_by_market
    @publisher = Publisher.observable_by(current_user).find(params[:id])
    @dates = date_range_defaulting_to_last_month(params[:dates_begin], params[:dates_end])
    @markets = Publisher.all_with_refunded_daily_deal_counts_by_market(@dates, @publisher)
    
    respond_to do |format|
      format.html do
        set_crumb_prefix
      end
      
      format.xml
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} Refunded Daily Deals By Market, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Market",
            "Deals w/ Refunds",
            "Refunded Vouchers",
            "Purchasers",
            "Currency Code",
            "Gross Refunded",
            "Discount",
            "Total Refunded"
          ]
          @markets.sort_by(&:name).each do |market|
            csv << [
              market.name,
              market.daily_deals_count,
              market.daily_deal_refunded_vouchers_count,
              market.daily_deal_purchasers_count,
              market.currency_code,
              market.daily_deal_refunded_vouchers_gross,
              market.daily_deal_refunded_vouchers_gross - market.daily_deal_refunded_vouchers_amount,
              market.daily_deal_refunded_vouchers_amount
            ]
          end
        end                
      end
    end
  end
  
  private
  
  def admin_or_publishing_group_user_required
    admin? || publishing_group? || insufficient_privilege
  end
  
  def date_range_defaulting_to_last_month(a, b)
    dates_begin, dates_end = [parse_date(a), parse_date(b)]
    unless dates_begin || dates_end
      last_month = Time.zone.now.prev_month
      dates_begin, dates_end = [last_month.beginning_of_month, last_month.end_of_month]
    end
    dates_begin ||= dates_end.prev_month + 1.day
    dates_end ||= dates_begin.next_month - 1.day

    dates_begin, dates_end = [dates_end, dates_begin] if dates_end < dates_begin
    dates_begin.to_date .. dates_end.to_date
  end

  def index_with_web_offers
    respond_to do |format|
      format.html do
        set_crumb_prefix
        render "reports/publishers/index_with_web_offers"
      end
      
      format.xml do
        render "reports/publishers/index_with_web_offers"
      end
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "Publishers Report, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Publisher",
            "Advertisers",
            "Coupons",
            "Impressions",
            "Clicks",
            "Click-through Rate (%)",
            "Prints",
            "Texts",
            "Emails",
            "Calls",
            "Facebook Shares",
            "Twitter Shares"
          ]
          @publishers.sort_by(&:name).each do |publisher|
            active_coupons_in_range = publisher.offers.active_between(@dates)
            csv << [
              publisher.name,
              active_coupons_in_range.map(&:advertiser_id).uniq.size,
              active_coupons_in_range.size,
              impressions = publisher.impressions_count(@dates),
              clicks = publisher.clicks_count(@dates, 'Offer'),
              impressions > 0 ? "%.1f" % (100.0 * clicks / impressions) : 0.0,
              publisher.prints_count(@dates),
              publisher.txts_count(@dates),
              publisher.emails_count(@dates),
              publisher.voice_messages_count(@dates),
              publisher.facebooks_count(@dates, 'Offer'),
              publisher.twitters_count(@dates, 'Offer'),
            ]
          end
        end
      end
    end
  end

  def index_with_billing
    return unless admin_privilege_required
    
    respond_to do |format|
      format.html do
        set_crumb_prefix
        render "reports/publishers/index_with_billing"
      end

      format.xml do
        render "reports/publishers/index_with_billing"
      end
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "Billing Summary, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << ["Publisher", "Prints", "Texts", "Emails", "Calls", "Call Minutes"]
          @publishers.sort_by(&:name).each do |publisher|
            csv << [
              publisher.name,
              publisher.prints_count(@dates),
              publisher.txts_count(@dates),
              publisher.emails_count(@dates),
              publisher.voice_messages_count(@dates),
              publisher.voice_messages_minutes(@dates)
            ]
          end
        end
      end
    end
  end

  def set_crumb_prefix
    add_crumb "Analytics", reports_path
  end
end
