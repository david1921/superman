namespace :store do
  
  desc "update all stores latitude and longitude, if mappable"
  task :update_latitude_and_longitude_for_all_stores => :environment do
    failed_to_update = []
    Store.all.each do |store|
      unless store.latitude_and_longitude_present?
        if store.address_mappable?
          begin
            store.set_longitude_and_latitude(true)
            failed_to_update << store unless store.save            
          rescue
            puts "we have an error for: #{store.inspect} -- error #{$!}"
          end
        end
      end      
    end  
    puts "we couldn't update #{failed_to_update.size}"
  end
  
end