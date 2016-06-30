namespace :oneoff do
  
  desc "setup creative loafing publisher categories and migrate GC to daily deals"
  task :setup_creative_loafing_publisher_categories_and_migrate_gc_to_deals do
    tampa       = Publisher.find_by_label!("tampa")    
    tampa.update_attributes!( :enable_publisher_daily_deal_categories => true )
    
    eats = tampa.daily_deal_categories.find_or_create_by_name( "Eats" )
    living = tampa.daily_deal_categories.find_or_create_by_name( "Living" )
    goods = tampa.daily_deal_categories.find_or_create_by_name( "Goods" )
    
    tampaeats   = Publisher.find_by_label!("tampaeats")
    tampagoods  = Publisher.find_by_label!("tampagoods")
    tampaliving = Publisher.find_by_label!("tampaliving")
    
    Rake::Task["daily_deals:replace_gift_certificates"].execute({:from => tampaeats.label, :to => tampa.label, :category => eats })
    Rake::Task["daily_deals:replace_gift_certificates"].execute({:from => tampagoods.label, :to => tampa.label, :category => goods })
    Rake::Task["daily_deals:replace_gift_certificates"].execute({:from => tampaliving.label, :to => tampa.label, :category => living  })
    
  end
  
end