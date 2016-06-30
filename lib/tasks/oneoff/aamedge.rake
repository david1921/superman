namespace :oneoff do
  namespace :aamedge do
    desc "Update number sold display threshold"
    task :update_number_sold_display => :environment do
   
      ["aamedge-eastvalley", "aamedge-maricopacasagrandepinal", "aamedge-nationwide", "aamedge-newmexico", "aamedge-northernaz", "aamedge-phoenix", "aamedge-scottsdale", "aamedge-tucson", "aamedge-westvalley"].each do |label|
        puts "------ Updating number sold display threshold for: #{label}" 
        publisher = Publisher.find_by_label(label)
        deal_ids = publisher.daily_deal_ids
        deals = DailyDeal.find(deal_ids)
        deals.each do |deal|
          puts "---- deal_id: #{deal.id}" 
          puts "#{deal.number_sold_display_threshold}"
          puts "To: #{deal.number_sold_display_threshold = 1}" 
          deal.save!
        end
      end
    end
  end
end
# usage: RAILS_ENV=development rake oneoff:aamedge:update_number_sold_display 
