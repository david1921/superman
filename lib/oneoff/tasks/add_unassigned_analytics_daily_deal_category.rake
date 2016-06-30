namespace :oneoff do
  
  desc "adds unassigned daily deal category belonging to the main analyitcs group"
  task :add_unassigned_analytics_daily_deal_category => :environment do
    name = "Unassigned"
    DailyDealCategory.create!(:name => name, :abbreviation => "UN") unless DailyDealCategory.analytics.find_by_name(name)
  end
  
end