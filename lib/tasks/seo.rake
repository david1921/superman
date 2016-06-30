namespace :seo do

  desc "make a publisher or publishing group seo friendly, advertiser and categories need labels"
  task :make_friendly => :environment do
    
    publishers = []
    if ENV["PUBLISHER"] 
      publishers << Publisher.find_by_label(ENV["PUBLISHER"])
    elsif ENV["PUBLISHING_GROUP"]
      publishing_group = PublishingGroup.find_by_name(ENV["PUBLISHING_GROUP"])
      publishers = publishing_group.publishers unless publishing_group.nil?
    end
    
    puts "tranforming: #{publishers.size} publishers"
    
    publishers.each do |publisher|
      publisher.advertisers.each do |advertiser|
        advertiser.generate_label_from_name! 
        puts "we couldn't generate label for #{advertiser.name}: #{advertiser.errors.full_messages}" unless advertiser.valid?
      end
      publisher.offers.each do |offer|
        offer.categories.each do |category|
          category.generate_label_from_name! 
        end
      end
    end
    
  end
  
end