class Reports::AdvertisersController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include Reports::Reporting

  before_filter :user_required
  layout 'reports'

  helper :reports

  def index
    @dates = date_range(params[:dates_begin], params[:dates_end])
    @publisher = Publisher.observable_by(current_user).find(params[:publisher_id])
    case @summary = params[:summary] || "web_offers"
    when "web_offers"
      return index_with_web_offers
    when "txt_offers"
      return index_with_txt_offers
    when "gift_certificates"
      return index_with_gift_certificates
    when "daily_deals"
      return index_with_daily_deals
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def show
    advertiser = Advertiser.observable_by(current_user).find(params[:id])
    redirect_to reports_advertiser_coupons_path(advertiser, params.slice(:dates_begin, :dates_end, :summary))
  end
  
  
  def purchased_gift_certificates
    @dates = date_range(params[:dates_begin], params[:dates_end])
    @advertiser = Advertiser.observable_by(current_user).find(params[:id])
    @publisher = @advertiser.publisher
    @purchased_gift_certificates = @advertiser.purchased_gift_certificates.completed(@dates).all(:include => :gift_certificate).sort do |a, b|
      a.paypal_payment_date <=> b.paypal_payment_date
    end
    
    respond_to do |format|
      format.html do
        set_crumb_prefix
        if admin? || publishing_group? || publisher?
          add_crumb "Advertisers"
          add_crumb @advertiser.name, reports_advertiser_path(@advertiser)
        end
      end
      
      format.xml
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@advertiser.name} - Purchased Deal Certificates, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Deal Certificate",
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
              purchased_gift_certificate.gift_certificate.item_number,
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
    @dates      = date_range(params[:dates_begin], params[:dates_end])
    @advertiser = Advertiser.find(params[:id])
    @publisher  = @advertiser.publisher
    @market = @publisher.markets.find(params[:market_id].to_i) if params[:market_id].present?

    respond_to do |format|
      format.html do
        set_crumb_prefix
        if admin? || publishing_group? || publisher?
          add_crumb "Advertisers"
          if current_user.can_manage? @advertiser
            add_crumb @advertiser.name, reports_advertiser_path(@advertiser)
          else
            add_crumb @advertiser.name
          end
        end
      end
      
      format.xml do
        @daily_deal_certificates = advertiser_purchased_daily_deals()
      end
      
      format.csv do
        @daily_deal_certificates = advertiser_purchased_daily_deals()
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@advertiser.name} Purchased Daily Deals, "
        filename << "#{@market.name}, " if @market.present?
        filename << "%s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Purchaser Name",
            #"Purchaser Email",
            "Recipient Name",
            "Redeemed On",
            "Redeemed At",
            "Serial Number",
            "Deal",
            "Value",
            "Price",
            "Purchase Price",
            "Purchase Date"
          ]
          @daily_deal_certificates.each do |daily_deal_certificate|
            csv << [
              daily_deal_certificate.consumer_name,
              #daily_deal_certificate.consumer_email,
              daily_deal_certificate.redeemer_name,
              daily_deal_certificate.redeemed_at.present? ? daily_deal_certificate.redeemed_at.to_date : "",
              daily_deal_certificate.store_name, 
              daily_deal_certificate.serial_number, 
              daily_deal_certificate.value_proposition,
              number_to_currency(daily_deal_certificate.value, :unit => daily_deal_certificate.currency_symbol),
              number_to_currency(daily_deal_certificate.price, :unit => daily_deal_certificate.currency_symbol),
              number_to_currency(daily_deal_certificate.actual_purchase_price, :unit => daily_deal_certificate.currency_symbol),
              daily_deal_certificate.executed_at.to_date
            ]
          end
        end                
      end
    end
    
  end

  def affiliated_daily_deals
    @dates      = date_range(params[:dates_begin], params[:dates_end])
    @advertiser = Advertiser.find(params[:id])
    @publisher  = @advertiser.publisher   
    respond_to do |format|
      format.html do
        set_crumb_prefix
        if admin? || publishing_group? || publisher?
          add_crumb "Advertisers"
          add_crumb @advertiser.name, reports_advertiser_path(@advertiser)
        end
      end
      
      format.xml do
        @daily_deal_certificates = @advertiser.affiliated_daily_deal_certificates_for_period(@dates, current_user.try(:company))
      end

      format.csv do
        @daily_deal_certificates = @advertiser.affiliated_daily_deal_certificates_for_period(@dates, current_user.try(:company))
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "Purchased Daily Deals, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Purchaser",
            "Recipient",
            "Affiliate",
            "Serial Number",
            "Deal",
            "Accounting ID",
            "Listing",
            "Price",
            "Purchase Price",
            "Affiliate Rev. Share",
            "Affiliate Payout",
            "Total",
            "Purchase Date"
          ]
          @daily_deal_certificates.each do |daily_deal_certificate|
            csv << [
              daily_deal_certificate.consumer_name,
              daily_deal_certificate.redeemer_name,
              daily_deal_certificate.affiliate_name,
              daily_deal_certificate.serial_number,
              daily_deal_certificate.value_proposition,
              daily_deal_certificate.daily_deal.accounting_id,
              daily_deal_certificate.daily_deal.listing,
              number_to_currency(daily_deal_certificate.price, :unit => daily_deal_certificate.currency_symbol),
              number_to_currency(daily_deal_certificate.actual_purchase_price, :unit => daily_deal_certificate.currency_symbol),
              "#{daily_deal_certificate.daily_deal.affiliate_revenue_share_percentage}%",
              number_to_currency(daily_deal_certificate.affiliate_payout, :unit => daily_deal_certificate.currency_symbol),
              number_to_currency(daily_deal_certificate.price - daily_deal_certificate.affiliate_payout, :unit => daily_deal_certificate.currency_symbol),
              daily_deal_certificate.executed_at.to_date
            ]
          end
        end
      end
    end
  end

  def refunded_daily_deals
    @dates      = date_range(params[:dates_begin], params[:dates_end])
    @advertiser = Advertiser.find(params[:id])
    @publisher  = @advertiser.publisher   
    @market = @publisher.markets.find(params[:market_id].to_i) if params[:market_id].present?

    respond_to do |format|
      format.html do
        set_crumb_prefix
        if admin? || publishing_group? || publisher?
          add_crumb "Advertisers"
          add_crumb @advertiser.name, reports_advertiser_path(@advertiser)
        end
      end
      
      format.xml do
        @daily_deal_certificates = advertiser_refunded_daily_deal_certificates()
      end
      
      format.csv do
        @daily_deal_certificates = advertiser_refunded_daily_deal_certificates()
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@advertiser.name} Refunded Daily Deals, "
        filename << "#{@market.name}, " if @market.present?
        filename << "%s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Purchaser Name",
            "Recipient Name", 
            "Serial Number",
            "Deal",
            "Value",
            "Price",
            "Refund Amount",
            "Refund Date"
          ]
          @daily_deal_certificates.select(&:refunded?).each do |daily_deal_certificate|
            csv << [
              daily_deal_certificate.consumer_name,
              daily_deal_certificate.redeemer_name,
              daily_deal_certificate.serial_number, 
              daily_deal_certificate.value_proposition,
              number_to_currency(daily_deal_certificate.value, :unit => daily_deal_certificate.currency_symbol),
              number_to_currency(daily_deal_certificate.price, :unit => daily_deal_certificate.currency_symbol),
              number_to_currency(daily_deal_certificate.refund_amount, :unit => daily_deal_certificate.currency_symbol),
              daily_deal_certificate.refunded_at.to_date.to_s(:compact)
            ]
          end
        end                
      end
    end
    
  end

  private
  
  def index_with_web_offers
    respond_to do |format|
      format.html do
        set_crumb_prefix
        render "reports/advertisers/index_with_web_offers"
      end
      format.xml do   
        @advertisers = @publisher.advertisers_with_web_offers_counts(@dates)
        render "reports/advertisers/index_with_web_offers"
      end
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} Advertiser with Web Coupons, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          header_row = []
          header_row << "Advertiser"
          header_row << "Listing" if @publisher.advertiser_has_listing?
          header_row << "Coupons"
          header_row << "Impressions"
          header_row << "Clicks"
          header_row << "Click-through Rate (%)"
          header_row << "Prints"
          header_row << "Texts"
          header_row << "Emails"
          header_row << "Calls"
          header_row << "Facebook Shares"
          header_row << "Twitter Shares"
          csv << header_row
          @publisher.advertisers_with_web_offers_counts(@dates).each do |advertiser|
            row = []
            clicks = advertiser.clicks_count.to_i 
            impressions = advertiser.impressions_count.to_i
            row << advertiser.name     
            row << advertiser.listing if @publisher.advertiser_has_listing?            
            row << advertiser.offers_count
            row << impressions
            row << clicks
            row << (impressions > 0 ? 100.0 * clicks / impressions : 0.0)
            row << advertiser.prints_count
            row << advertiser.txts_count
            row << advertiser.emails_count
            row << advertiser.calls_count
            row << advertiser.facebooks_count
            row << advertiser.twitters_count
            csv << row
          end
        end
      end
    end
  end
  
  def index_with_txt_offers
    respond_to do |format|
      format.html do
        set_crumb_prefix
        render "reports/advertisers/index_with_txt_offers"
      end
      format.xml do
        @advertisers = @publisher.advertisers.having_txt_offers
        render "reports/advertisers/index_with_txt_offers"
      end
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} Advertiser with Web Coupons, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Advertiser",
            "TXT Coupons",
            "Inbound Texts"
          ]
          @publisher.advertisers.having_txt_offers.sort_by(&:name).each do |advertiser|
            csv << [
              advertiser.name,
              advertiser.txt_offers.count,
              advertiser.inbound_txts_count(@dates)
            ]
          end
        end
      end
    end
  end
  
  def index_with_gift_certificates
    respond_to do |format|
      format.html do
        set_crumb_prefix
        render "reports/advertisers/index_with_gift_certificates"
      end
      format.xml do
        @advertisers = @publisher.advertisers_with_gift_certificates_counts(@dates)
        render "reports/advertisers/index_with_gift_certificates"
      end
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} Advertisers with Deal Certificates, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Advertiser",
            "Initial Count",
            "Currency Code",
            "Initial Inventory (#{@publisher.currency_symbol})",
            "Deal Certificates Sold",
            "Deal Certificate Revenue",
            "Final Count",
            "Final Inventory (#{@publisher.currency_symbol})"
          ]
          @publisher.advertisers_with_gift_certificates_counts(@dates).sort_by(&:name).each do |advertiser|
            csv << [
              advertiser.name,
              advertiser.available_count_begin,
              @publisher.currency_code,
              "%.2f" % advertiser.available_revenue_begin,
              advertiser.purchased_count,
              "%.2f" % advertiser.purchased_revenue,
              advertiser.available_count_end
            ]
          end
        end
      end
    end
  end

  def index_with_daily_deals
    respond_to do |format|
      format.html do
        set_crumb_prefix
        render "reports/advertisers/index_with_daily_deals"
      end

      format.xml do
        @advertisers = @publisher.advertisers_with_daily_deal_counts(@dates)
        render "reports/advertisers/index_with_daily_deals"
      end

      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@publisher.name} Advertiser with Daily Deals, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Advertiser",
            "Facebook",
            "Twitter"
          ]
          @publisher.advertisers_with_daily_deal_counts(@dates).each do |advertiser|
            csv << [
              advertiser.name,
              advertiser.facebook_count,
              advertiser.twitter_count
            ]
          end
        end
      end
    end
  end

  def set_crumb_prefix
    add_crumb "Analytics", reports_path
    if admin? || publishing_group?
      add_crumb "Publishers"
      add_crumb @publisher.name, reports_publisher_path(@publisher)
    end
  end

  def advertiser_purchased_daily_deals
    @advertiser.purchased_daily_deal_certificates_for_period(@dates, current_user.try(:companies), @market)
  end

  def advertiser_refunded_daily_deal_certificates
    @advertiser.refunded_daily_deal_certificates_for_period(@dates, current_user.try(:company), @market)
  end

end
