namespace :oneoff do
  namespace :entertainment do
    
    desc "Set the third party deals api configs for all Entertainment publishers"
    task :set_third_party_api_configs do
      entertainment = PublishingGroup.find_by_label!("entertainment")
      entertainment.publishers.each do |publisher|
        next if publisher.third_party_deals_api_config.present?
        
        print "Creating third party api config for #{publisher.label}..."
        ThirdPartyDealsApi::Config.create! :publisher_id => publisher.id,
                                           :api_username => "analog",
                                           :api_password => "MahN7De8"
        puts "done."
      end
    end
    
    desc "Upload 'new' zipcodes for markets"
    task :update_zipcode_to_markets_from_csv => :environment do
      raise "FILE is required" if ENV['FILE'].empty?
      csv_filename = ENV['FILE']
      publishing_group = PublishingGroup.find_by_label("entertainment")

      pub_market_lookup = {}
      publishing_group.publishers.each do |pub|
        pub_market_lookup[pub.market_name] = pub.id.to_s if pub.market_name.present?
      end
      pub_zipcode_lookup = {}
      publishing_group.publishers.each do |pub|
        pub.publisher_zip_codes.each do |zip|
          pub_zipcode_lookup[zip.zip_code] =  zip.publisher_id.to_s
        end
      end      

      PublisherZipCode.transaction do
        new_zips = Array.new
        FasterCSV.foreach(csv_filename) do |row|
          # row[0]  = zipcode 
          # row[1]  = market_name        
          if !pub_zipcode_lookup.key?(row[0]) && (row[0].length == 5) # zip doesn't exist in system
              puts "#{row[0]} not found."
            if pub_market_lookup.key?(row[1]) #market exists
              puts "creating new zipcode for #{row[0]}, (Pub #{pub_market_lookup[row[1].to_s]})"
              new_zips.push( PublisherZipCode.create({:publisher_id => pub_market_lookup[row[1].to_s], :zip_code => row[0]}) ) 
            end
          end
        end
        puts "#{new_zips.count} new zipcodes created in system"
        raise ActiveRecord::Rollback if ENV['DRY_RUN'].present?
      end
    end
  end
end