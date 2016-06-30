namespace :oneoff do

  desc "loads all the offer and daily deal categories for Timewarner"
  task :add_timewarner_cable_categories do
    
    # key is the TWC category, the values are mappings from existing categories to 
    # the new TWC category for offers and deals.
    categories = {
      "Alcoholic Beverages" => {
        "offers" => ["Bar"]
      },
      "Associations" => {
        "deals"  => ["Membership"]
      },
      "Automotive" => {},
      "Auto Aftermarket" => {},
      "Education" => {},
      "Financial Services & Insurance" => {},
      "Government/Military" => {},
      "Grocery/Food/Beverage" => {
        "deals" => ["Grocery/Food/Beverage"]
      },
      "Healthcare" => {
        "offers" => ["Medicine", "Health & Beauty", "Heath & Beauty", "Services", "Hair"],
        "deals"  => ["Beauty"]
      },
      "Home Improvement" => {
        "offers" => ["Home Imporvement", "Home Improvement"]
      },
      "Legal" => {},
      "Media" => {
        "deals" => ["Publisher Subscription"]
      },
      "Real Estate" => {},
      "Restaurant" => {
        "offers" => ["Restaurants", "Restuarants", "Diner", "Pizza"],
        "deals"  => ["Dining"]
      },
      "Retail" => {
        "offers" => ["Pet Products", "Gifts"],
        "deals"   => ["Merchandise/Service"]
      },
      "Response Media" => {},
      "RV/Cycles Vehicles" => {},
      "Telecommunication" => {},
      "Travel/Leisure/Entertainment" => {
        "offers" => ["Entertainment", "Events", "Recreation", "Casino"],
        "deals"  => ["Activities", "Tourism", "Theater", "Other"]
      }
    }
    
    rr = PublishingGroup.find_by_label("rr")
    raise ArgumentError, "unable to find publishing group for TWC, which should have a label of rr" unless rr
        
    enable_publisher_daily_deal_categories_for_all_publishers_in_group(rr)
    
    create_offer_categories( rr, categories )
    update_existing_offer_categories( rr, categories )
    
    cleanup_bad_analytics_category_ids_on_daily_deals(rr)
    create_daily_deal_categories( rr, categories )
    update_existing_daily_deal_categories( rr, categories )
    
    
  end
  
  def create_offer_categories( publishing_group, categories ) 
    puts "[Offer Categories] creating..."
    categories.each_pair do |name, mappings|
      create_offer_category_for_publishing_group( publishing_group, name )
    end
    puts "    TOTAL: #{publishing_group.categories.size}"
  end
  
  def create_offer_category_for_publishing_group( publishing_group, category_name )
    unless publishing_group.categories.collect(&:name).include?( category_name )
      puts "   #{category_name}: creating"
      publishing_group.categories.create!( :name => category_name )
    end
  end
  
  def update_existing_offer_categories( publishing_group, categories )    
    puts "[Offer Categories] updating..."
    publishing_group.publishers.each do |publisher|
      publisher.offers.each do |offer|
        new_categories = offer.categories.collect(&:name).collect do |name|
          category_based_on_existing_offer_category( publishing_group, categories, name )
        end   
        update_offer_category( offer, new_categories )     
      end
    end    
  end
  
  def category_based_on_existing_offer_category( publishing_group, categories, category_name )
    found_name = nil
    categories.each_pair do |name, mappings|
      found_name = name if name == category_name      
      unless found_name
        mappings["offers"].each do |offer_category_name|
          found_name = name if offer_category_name == category_name
        end if mappings["offers"].present?
      end
    end
    if found_name
      return publishing_group.categories.find_by_name( found_name )
    else
      puts "   we couldn't find a match for #{category_name}"
      return nil
    end
  end
  
  def update_offer_category( offer, new_categories )
    if new_categories.present?
      offer.categories.clear
      new_categories.uniq.each do |category|
        unless offer.categories.include?( category )
          puts "  updating Offer ##{offer.id} with #{category.name}"
          offer.categories << category
          offer.save
        else
          puts "   we already set category: #{category.name}"
        end
      end      
    else
      unless offer.categories.empty?
        puts "   we don't have any new categories for Offer ##{offer.id}"
        puts "      expected: #{offer.categories.collect(&:name).join(", ")}"
      end
    end
  end
  
  def create_daily_deal_categories( publishing_group, categories )
    puts "[Daily Deal Categories] creating..."
    categories.each_pair do |name, mappings|
      create_daily_deal_category_for_publishing_group( publishing_group, name )
    end
    puts "    TOTAL: #{publishing_group.daily_deal_categories.size}"
  end
  
  def create_daily_deal_category_for_publishing_group( publishing_group, category_name )
    unless publishing_group.daily_deal_categories.collect(&:name).include?( category_name )
      puts "   #{category_name}: creating"
      publishing_group.daily_deal_categories.create!( :name => category_name )
    end
    publishing_group.daily_deal_categories.reload
  end
  
  def update_existing_daily_deal_categories( publishing_group, categories )
    puts "[Daily Deal Categories] updating..."
    publishing_group.publishers.each do |publisher|
      puts "   Publisher: #{publisher.name}"      
      publisher.daily_deals.each do |daily_deal|
        if daily_deal.analytics_category.present?
          new_category = category_based_on_existing_daily_deal_category( publishing_group, categories, daily_deal.analytics_category.name )
        else
          puts "Daily Deal: #{daily_deal.id} has no current category"
        end
        update_daily_deal_category( daily_deal, new_category )
      end
    end
  end
  
  def category_based_on_existing_daily_deal_category( publishing_group, categories, category_name )
    found_name = nil
    categories.each_pair do |name, mappings|
      unless found_name
        mappings["deals"].each do |offer_category_name|
          found_name = name if offer_category_name == category_name
        end if mappings["deals"].present?
      end
    end
    if found_name
      return publishing_group.daily_deal_categories.find_by_name( found_name )   
    else
      puts "   we couldn't find a match for #{category_name}"
      return nil
    end    
  end
  
  def update_daily_deal_category( daily_deal, category )
    if category
      unless daily_deal.analytics_category == category
        puts "     updating Daily Deal ##{daily_deal.id} to #{category.name} (#{category.id})"
        daily_deal.update_attribute(:publishers_category, category)
      else
        puts "     FAIL. Daily Deal #{daily_deal.id} category is equal to an analytics category #{daily_deal.analytics_category.name} (#{daily_deal.analytics_category_id}) and should not be"
      end
    else
      puts "   we could NOT find category for daily deal: #{daily_deal.id}"
    end
  end
  
  def enable_publisher_daily_deal_categories_for_all_publishers_in_group(publishing_group)
    publishing_group.publishers.each do |publisher|
      publisher.update_attribute(:enable_publisher_daily_deal_categories, true)
    end
  end
  
  def cleanup_bad_analytics_category_ids_on_daily_deals(publishing_group)
    publishing_group.publishers.each do |publisher|
      publisher.daily_deals.each do |daily_deal|
        daily_deal.update_attribute(:analytics_category_id, nil) unless daily_deal.analytics_category.present?
      end
    end
  end
  
end