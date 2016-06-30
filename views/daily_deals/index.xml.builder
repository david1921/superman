xml.daily_deals( 'xmlns' => 'http://analoganalytics.com/api/daily_deals', 'publisher_label' => @publisher.label ) {
  xml << render(:partial => 'daily_deals/daily_deal', :collection => @daily_deals) if @daily_deals.present?
}

