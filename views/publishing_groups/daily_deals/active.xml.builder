xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.daily_deals( 'xmlns' => 'http://analoganalytics.com/api/daily_deals', 'publishing_group_label' => @publishing_group.label ) do

  xml << render(:partial => 'daily_deals/daily_deal',
                :collection => @daily_deals,
                :locals => {:include_publisher_label => true}) if @daily_deals.present?

end
  
