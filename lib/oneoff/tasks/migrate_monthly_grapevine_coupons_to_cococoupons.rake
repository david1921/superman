namespace :oneoff do
  
  desc "migrate monthly grapevine coupons to cococoupons"
  task :migrate_monthly_grapevine_coupons_to_cococoupons => :environment do
    monthly_grapevine = Publisher.find_by_label("monthlygrapevine")
    cococoupons       = Publisher.find_by_label("cococoupons")
    force             = ENV["FORCE"]
    
    raise "we were unable to find both or one of the publishers" unless monthly_grapevine && cococoupons
    raise "cococoupons has offers, use FORCE=true to remove them" unless force || cococoupons.offers.empty?
    raise "nothing to move over for Monthly Grapevine" unless monthly_grapevine.offers.present?
    
    puts "starting...."
    if monthly_grapevine.offers.present?
      cococoupons.offers.destroy_all # only destroy the offers
      
      puts "migrating over #{monthly_grapevine.advertisers.size} advertisers"
      monthly_grapevine.advertisers.each do |advertiser|
        advertiser.update_attribute(:publisher_id, cococoupons.id)
      end
      [ApiRequest, Lead, OfferChange, Placement, ImpressionCount, ClickCount].each do |association|
        records = association.find(:all, :conditions => {:publisher_id => monthly_grapevine.id})
        puts "Updating #{records.size} #{association}"
        records.each do |record|
          record.update_attribute(:publisher_id, cococoupons.id)
        end
      end
    end
    puts "done!"
    
  end
  
end