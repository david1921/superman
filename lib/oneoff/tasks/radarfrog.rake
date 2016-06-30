RADARFROG_CATEGORIES = {
  "Apparel" => ["Men", "Women", "Children", "Shoes", "Jewelry", "Bags & Accessories", "Outlet", "Plus Size"],
  "Automotive" => [],
  "Beauty" => ["Bath & Body", "Cosmetics", "Fragrance", "Salon", "Spas"],
  "Business & Office" => [],
  "Computers & Electronics" => ["Computer Hardware", "Consumer Electronics", "Software", "Services & Support"],
  "Construction & Contractors" => [],
  "Eco-Friendly" => [],
  "Education" => [],
  "Entertainment" => ["Arts & Culture", "Books", "Movies", "Music", "Tickets & Events", "Magazines & Newspapers", "Costumes & Party Supplies"],
  "Family" => ["Baby & Children", "Weddings"],
  "Finance & Security" => [],
  "Food & Drink" => ["Gourment", "Beverages", "Dining", "Grocery", "Wineries"],
  "Gifts" => ["Chocolates & Candies", "Flowers", "Gift Baskets & Certificates", "Greeting Cards"],
  "Health" => ["Dental", "Medical", "Exercise & Weight Loss", "Prescriptions & Supplements"],
  "Hobbies & Collectibles" => [],
  "Home & Garden" => ["Furniture & Decor", "Garden", "Kitchen", "Home Improvement"],
  "Industry & Agriculture" => [],
  "Personals" => [],
  "Pets" => [],
  "Real Estate" => [],
  "Retail" => [],
  "Services" => [],
  "Shopping" => [],
  "Sports & Fitness" => ["Apparel", "Equipment", "Outdoors"],
  "Toys & Games" => ["Toys", "Video Games"],
  "Travel" => ["Car Rental", "Flights", "Vacation Packages", "Accommodations", "Cruises", "Luggage & Accessories"]
}

namespace :radarfrog do

  desc "Import categories used by radarfrog's publishing group"
  task :create_publishing_group_categories => :environment do
    publishing_group = PublishingGroup.find_by_label! "radarfrog"
    
    RADARFROG_CATEGORIES.each do |category_name, subcategory_names|
      category = publishing_group.categories.create :name => category_name
      subcategory_names.each do |subcat_name|
        publishing_group.categories.create :name => subcat_name, :parent_id => category.id
      end
    end
  end
  
  desc "update all radar publications theme to 'withtheme'"
  task :update_theme_to_withtheme => :environment do
    PublishingGroup.find_by_label("radarfrog").publishers.each{|p| p.update_attribute(:theme, "withtheme") }
  end
  
  desc "update all, except main radar frog publication to not allow searching by publishing group"
  task :turn_off_searching_by_publishing_group => :environment do
    PublishingGroup.find_by_label("radarfrog").publishers.each do |p|
      unless p.label == 'radarfrog'
        p.update_attribute(:enable_search_by_publishing_group, false) if p.enable_search_by_publishing_group?
      end
    end
  end
  
  desc "assert Offer message and value proposition are the same unless they both have content"
  task :assert_offer_message_and_value_proposition_are_the_same => :environment do
    PublishingGroup.find_by_label("radarfrog").publishers.each do |publisher|
      publisher.offers.each do |offer|
        unless (offer.value_proposition.present? and offer.message.present?) || (offer.value_proposition.blank? and offer.message.blank?)
          if offer.message.present?
            offer.update_attribute(:value_proposition, offer.message)
          else
            offer.update_attribute(:message, offer.value_proposition)
          end
        end
      end
    end
  end
  
  desc "assert adveritser email clipping mode is checked, only if no clipping modes have been selected"
  task :assert_advertiser_clipping_mode_with_no_selection_have_email_clipping_mode => :environment do
    PublishingGroup.find_by_label("radarfrog").publishers.each do |publisher|
      publisher.advertisers.each do |advertiser|    
        if advertiser.coupon_clipping_modes.empty?
          puts "updating advertiser: #{advertiser.id}"
          advertiser.update_attribute(:coupon_clipping_modes, [:email])
        end
      end
    end
  end
  
  desc "fix an issue with newport's share offers screwing up"
  task :fix_newport_publisher => :environment do
    newport = Publisher.find_by_label("radarfrog-newportindependent")
    puts "Loaded with publisher \# #{newport.id} with #{newport.placements.count} placements"
    newport.update_attribute(:place_all_group_offers, false)
    placements_removed = 0
    newport.placements.each do |pl|
      puts "checking offer #{pl.offer.id} with owning publisher of #{pl.offer.advertiser.publisher.id} against newport (#{newport.id})"
      if pl.offer.advertiser.publisher.id != newport.id 
        puts "HIT! #{pl.offer.advertiser.publisher.id} owns placement #{pl.id}"
        Placement.delete(pl.id)
        placements_removed += 1
      else
        "Miss."
      end
    end
    puts "#{placements_removed} placements removed"
    puts "You sunk my battleship."
  end
end