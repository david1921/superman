class ReportsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include Reports::Reporting

  before_filter :default_to_demo_login
  before_filter :user_required
  before_filter :admin_privilege_required, :except => [:show, :purchased_daily_deals, :refunded_daily_deals]

  layout 'reports'
  
  def show
    redirect_to admin? ? reports_publishers_path : {
      PublishingGroup => reports_publishers_path,
            Publisher => reports_publisher_path(current_user.company),
           Advertiser => reports_advertiser_path(current_user.company)
    }[current_user.company.class]
  end
  
  def purchased_gift_certificates
    @dates = date_range_defaulting_to_last_month(params[:dates_begin], params[:dates_end])

    @publisher_ids = Publisher.observable_by(current_user).map(&:id)

    @purchased_gift_certificates = PurchasedGiftCertificate.for_publisher(@publisher_ids).completed(@dates)
    @purchased_gift_certificates = PurchasedGiftCertificate.completed(@dates) if current_user.has_full_admin_privileges?
    @purchased_gift_certificates.sort do |a, b|
      case date_order = a.paypal_payment_date <=> b.paypal_payment_date
      when +1, -1
        date_order
      when 0
        a.publisher.name <=> b.publisher.name
      end
    end
    
    respond_to do |format|
      format.html do
        set_crumb_prefix
      end

      format.xml
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "Purchased certificates, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Publisher",
            "Purchase Date",
            "Deal Certificate",
            "Currency Code",
            "Value",
            "Payment",
            "PayPal Transaction ID",
            "Serial Number",
            "Name",
            "Street",
            "City",
            "State",
            "ZIP",
            "Email",
            "Status"
          ]
          @purchased_gift_certificates.each do |purchased_gift_certificate|
            csv << [
              purchased_gift_certificate.gift_certificate.publisher.name,
              purchased_gift_certificate.paypal_payment_date,
              purchased_gift_certificate.gift_certificate.item_number,
              purchased_gift_certificate.currency_code,
              number_to_currency(purchased_gift_certificate.value, :unit => purchased_gift_certificate.currency_symbol),
              number_to_currency(purchased_gift_certificate.paypal_payment_gross, :unit => purchased_gift_certificate.currency_symbol),
              purchased_gift_certificate.paypal_txn_id,
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
    @dates = date_range_defaulting_to_last_30_days(params[:dates_begin], params[:dates_end])
    respond_to do |format|
      format.html do
        set_crumb_prefix
      end
      
      format.xml do
        @publishers = Publisher.all_with_purchased_daily_deal_counts(@dates, Publisher.observable_by(current_user))
      end
      
      format.csv do
        @publishers = Publisher.all_with_purchased_daily_deal_counts(@dates, Publisher.observable_by(current_user))
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "Daily Deals, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Publisher",
            "Deals",
            "Purchased",
            "Purchasers",
            "Currency Code",
            "Gross",
            "Discount",
            "Refunds",
            "Total"
          ]
          @publishers.sort_by(&:name).each do |publisher|
            csv << [
              publisher.name,
              publisher.daily_deals_count,
              publisher.daily_deal_purchases_total_quantity,
              publisher.daily_deal_purchasers_count,
              publisher.currency_code,
              publisher.daily_deal_purchases_gross,
              publisher.daily_deal_purchases_gross - publisher.daily_deal_purchases_actual_purchase_price,
              publisher.daily_deal_purchases_refund_amount,
              publisher.daily_deal_purchases_actual_purchase_price - publisher.daily_deal_purchases_refund_amount
            ]
          end
        end                
      end
    end
  end

  def affiliated_daily_deals
    @dates = date_range_defaulting_to_last_30_days(params[:dates_begin], params[:dates_end])    
    respond_to do |format|
      format.html do
        set_crumb_prefix
      end

      format.xml do
        @publishers = Publisher.all_with_affiliated_daily_deal_counts(@dates, Publisher.observable_by(current_user))
      end

      format.csv do
        @publishers = Publisher.all_with_affiliated_daily_deal_counts(@dates, Publisher.observable_by(current_user))
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "Affiliated Daily Deals, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Publisher",
            "Affiliated Deals",
            "Purchased",
            "Purchasers",
            "Currency Code",
            "Gross",
            "Payout",
            "Total"
          ]
          @publishers.sort_by(&:name).each do |publisher|
            csv << [
              publisher.name,
              publisher.daily_deals_count,
              publisher.daily_deal_purchases_total_quantity,
              publisher.daily_deal_purchasers_count,
              publisher.currency_code,
              publisher.daily_deal_affiliate_gross,
              publisher.daily_deal_affiliate_payout,
              publisher.daily_deal_affiliate_gross - publisher.daily_deal_affiliate_payout
            ]
          end
        end                
      end
    end
  end
  
  def refunded_daily_deals
    @dates = date_range_defaulting_to_last_30_days(params[:dates_begin], params[:dates_end])
    respond_to do |format|
      format.html do
        set_crumb_prefix
      end
      
      format.xml do
        @publishers = Publisher.all_with_refunded_daily_deal_counts(@dates, Publisher.observable_by(current_user))
      end
      
      format.csv do
        @publishers = Publisher.all_with_refunded_daily_deal_counts(@dates, Publisher.observable_by(current_user))
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "Daily Deals, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Publisher",
            "Deals w/ Refunds",
            "Refunded Vouchers",
            "Purchasers",
            "Currency Code",
            "Gross Refunded",
            "Discount",
            "Total Refunded"
          ]
          @publishers.sort_by(&:name).each do |publisher|
            csv << [
              publisher.name,
              publisher.daily_deals_count,
              publisher.daily_deal_refunded_vouchers_count,
              publisher.daily_deal_purchasers_count,
              publisher.currency_code,
              publisher.daily_deal_refunded_vouchers_gross,
              publisher.daily_deal_refunded_vouchers_gross - publisher.daily_deal_refunded_vouchers_amount,
              publisher.daily_deal_refunded_vouchers_amount
            ]
          end
        end                
      end
    end
  end
  
  private
  
  def date_range_defaulting_to_last_month(a, b)
    setup_date_range(a, b) do |dates_begin, dates_end|
      unless dates_begin || dates_end
        last_month = Time.zone.now.prev_month
        dates_begin, dates_end = [last_month.beginning_of_month, last_month.end_of_month]
      end      
    end
  end
  
  def date_range_defaulting_to_last_30_days(a, b)
    setup_date_range(a, b) do |dates_begin, dates_end|
      unless dates_begin || dates_end
        today = Time.zone.now
        dates_begin, dates_end = [(today - 30.days).beginning_of_day, today.end_of_day]
      end
    end
  end  
  
  def setup_date_range(a, b)
    dates_begin, dates_end = [parse_date(a), parse_date(b)]
    new_dates_begin, new_dates_end = yield dates_begin, dates_end
    dates_begin = new_dates_begin || dates_begin
    dates_end   = new_dates_end || dates_end
    
    dates_begin ||= dates_end.prev_month + 1.day
    dates_end ||= dates_begin.next_month - 1.day

    dates_begin, dates_end = [dates_end, dates_begin] if dates_end < dates_begin
    dates_begin .. dates_end
  end

  def set_crumb_prefix
    add_crumb "Analytics", reports_path
  end

end
