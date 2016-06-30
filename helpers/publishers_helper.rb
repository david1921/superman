module PublishersHelper
  def affiliated_deals_for(publisher)
    if publisher.affiliate_placements.present?
      affiliated_deals_ul = '<ul class="affiliated-deals">'
      publisher.affiliate_placements.each do |ap|
        next unless ap.placeable.is_a?(DailyDeal)
        
        affiliated_deals_ul << "<li>"
        affiliated_deals_ul << %Q{<div class="value-prop">#{link_to(ap.placeable.value_proposition, edit_daily_deal_path(ap.placeable))}</div>}
        affiliated_deals_ul << %Q{<div class="publisher">from #{link_to(ap.affiliate.label, edit_publisher_path(ap.affiliate))}</div>}
        affiliated_deals_ul << "</li>"
      end
      affiliated_deals_ul << "</ul>"
    else
      "No affiliated deals"
    end
  end
  
  def fraud_risks_status_html(publisher)
    return "<p>This publisher has fraud detection disabled</p>" unless publisher.enable_fraud_detection?

    suspected_frauds_count = publisher.daily_deal_purchases.suspected_frauds.captured(nil).count
    if suspected_frauds_count > 0
      link_to(pluralize(suspected_frauds_count, "suspected fraud"), publisher_suspected_frauds_path(:publisher_id => publisher.to_param, :page => 1, :per_page => 100), :style => "color: red; font-weight: bold")
    else
      "<p>No transactions appear to be fraud risks</p>"
    end
  end
  
  # This should probably use locales
  def zip_code_label(publisher)
    case publisher.currency_code
    when "USD"
      "ZIP Code"
    when "GBP"
      "Postcode"
    else
      "Postal Code"
    end
  end
end
