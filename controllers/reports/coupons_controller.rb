class Reports::CouponsController < ApplicationController
  include Reports::Reporting

  before_filter :user_required
  layout 'reports'

  helper :reports

  def index
    @dates = date_range(params[:dates_begin], params[:dates_end])
    @advertiser = Advertiser.observable_by(current_user).find(params[:advertiser_id])
    case @summary = params[:summary] || "web_offers"
    when "web_offers"
      return index_with_web_offers
    when "txt_offers"
      return index_with_txt_offers
    when "gift_certificates"
      return index_with_gift_certificates
    else
      raise ActiveRecord::RecordNotFound
    end
  end
  
  private

  def index_with_web_offers
    respond_to do |format|
      format.html do
        set_crumb_prefix
        render "reports/coupons/index_with_web_offers"
      end

      format.xml do
        @offers = @advertiser.offers
        render "reports/coupons/index_with_web_offers"
      end
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@advertiser.name} Web Coupons, %s to %s.csv" % formatted_dates

        stream_csv(filename) do |csv|
          header_row = []
          header_row << "Coupon"
          header_row << "Publisher Offer ID" if @advertiser.offer_has_listing?
          header_row << "Impressions"
          header_row << "Clicks"
          header_row << "Click-through Rate (%)"
          header_row << "Prints"
          header_row << "Texts"
          header_row << "Emails"
          header_row << "Calls"
          header_row << "Facebook Shares"
          header_row << "Twitter Shares" 
          header_row << "Account Executive" 
          csv << header_row
          @advertiser.offers.sort_by(&:message).each do |offer| 
            row = []
            row << offer.message 
            row << offer.listing if @advertiser.offer_has_listing?
            row << (impressions = offer.impressions_count(@dates))
            row << (clicks = offer.clicks_count(@dates))
            row << (impressions > 0) ? ("%.1f" % (100.0 * clicks / impressions)) : 0.0
            row << offer.prints_count(@dates)
            row << offer.txts_count(@dates)
            row << offer.emails_count(@dates)
            row << offer.voice_messages_count(@dates)
            row << offer.facebooks_count(@dates)
            row << offer.twitters_count(@dates)
            row << offer.account_executive
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
        render "reports/coupons/index_with_txt_offers"
      end
      format.xml do
        @txt_offers = @advertiser.txt_offers
        render "reports/coupons/index_with_txt_offers"
      end
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@advertiser.publisher.name} Advertiser with Web Coupons, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Keyword",
            "Texts Received",
            "Texts Sent",
          ]
          @advertiser.txt_offers.sort_by(&:keyword).each do |txt_offer|
            csv << [
              txt_offer.keyword,
              txt_offer.inbound_txt_count(@dates),
              txt_offer.txts_count(@dates)
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
        render "reports/coupons/index_with_gift_certificates"
      end
      
      format.xml do
        @gift_certificates = @advertiser.gift_certificates_counts(@dates)
        render "reports/coupons/index_with_gift_certificates"
      end
      
      format.csv do
        formatted_dates = [:begin, :end].map { |attr| @dates.send(attr).to_formatted_s(:db) }
        filename = "#{@advertiser.name} Deal Certificate Summary, %s to %s.csv" % formatted_dates
        stream_csv(filename) do |csv|
          csv << [
            "Deal Certificate",
            "Initial Count",
            "Initial Inventory (#{@advertiser.currency_symbol})",
            "Deal Certificates Sold",
            "Deal Certificate Revenue",
            "Final Count",
            "Final Inventory (#{@advertiser.currency_symbol})"
          ]
          @advertiser.gift_certificates_counts(@dates).sort_by(&:item_number).each do |gift_certificate|
            csv << [
              gift_certificate.item_number,
              gift_certificate.available_count_begin,
              "%.2f" % gift_certificate.available_revenue_begin,
              gift_certificate.purchased_count,
              "%.2f" % gift_certificate.purchased_revenue,
              gift_certificate.available_count_end
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
      add_crumb @advertiser.publisher.name, reports_publisher_path(@advertiser.publisher)
    end
    if admin? || publishing_group? || publisher?
      add_crumb "Advertisers"
      add_crumb @advertiser.name, reports_advertiser_path(@advertiser)
    end
  end
end
