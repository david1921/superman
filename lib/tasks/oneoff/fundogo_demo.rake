namespace :oneoff do
  namespace :fundogo_demo do
    task :create_categories => :environment do
      categories = [
        ["Travel", "TR"],
        ["Entertainment", "E"],
        ["Shopping", "S"],
        ["Giving", "G"]
      ]
      categories += DailyDealCategory.analytics.map { |c| [c.name, c.abbreviation] }
      fundogo_demo = Publisher.find_by_label!("fundogo-demo")
      categories.each do |name, abbrev|
        fundogo_demo.daily_deal_categories.create! :name => name, :abbreviation => abbrev
      end      
    end
  end
end
