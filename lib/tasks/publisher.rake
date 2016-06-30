namespace :publisher do
  
  # Generates a random number of discount codes for 
  #
  desc "generates a random discount codes for publisher - Require: PUBLISHER_LABEL, COUNT, USE, AMOUNT  Optional: EXPIRES_ON"
  task :generate_random_discount_codes => :environment do
    
    VALID_USES = %w( one-time multiple )
    
    label       = ENV["PUBLISHER_LABEL"]
    count       = ENV["COUNT"]
    use         = ENV["USE"]
    amount      = ENV["AMOUNT"]
    expires_on  = ENV["EXPIRES_ON"]
    
    raise "PUBLISHER_LABEL is required, please supply a publisher label" unless label
    raise "COUNT is require, please supply the number of discount codes to produce" unless count
    raise "USE is required, and must be 'one-time' or 'multiple'" unless VALID_USES.include?( use )
    raise "AMOUNT is required" unless amount
    
    publisher = Publisher.find_by_label(label)
    raise "Unable to find a publisher with the given PUBLISHER_LABEL of '#{label}'" unless publisher
    
    puts "creating a #{count} random discounts with an amount of #{amount} for '#{use}' use."
    puts "   --- expiring on #{expires_on}" if expires_on
    
    codes = []
    while(codes.length < count.to_i) do
      code = UUIDTools::UUID.random_create.hexdigest[0..6]
      codes.push( code ) unless codes.include?( code ) || publisher.discounts.find_by_code( code )
    end
    
    last_usable_at = nil
    if expires_on.present?
      Time.zone = publisher.time_zone
      last_usable_at = Time.zone.parse(expires_on).end_of_day
    end
    
    codes.each do |code|
      publisher.discounts.create!({
        :code => code,
        :amount => amount,
        :usable_only_once => (use == 'one-time'),
        :last_usable_at => last_usable_at
      })
    end
    
    
  end
  
  desc "setup up google map for all publishers"
  task :setup_google_map_for_all_publishers => :environment do
    zoom_level = ENV["ZOOM_LEVEL"] || 11
    Publisher.all.each do |publisher|
      geocode_publisher(publisher, zoom_level)
    end    
  end
  
  desc "sets up the google map latitude, longitude and zoom level - Require: PUBLISHING_GROUP_LABEL or PUBLISHER_LABEL  Optional: ZOOM_LEVEL (default is 11)"
  task :setup_google_map => :environment do
    zoom_level  = ENV["ZOOM_LEVEL"] || 11
    publishers_based_on_publishing_group_label_or_publisher_label.each do |publisher|
      geocode_publisher(publisher, zoom_level)
    end
    puts "completed!"
  end
  
  desc "ensure latitude/longitude for stores belonging to publisher or publishing group - Require: PUBLISHING_GROUP_LABEL or PUBLISHER_LABEL"
  task :ensure_latitude_longitude_for_stores => :environment do
    publishers_based_on_publishing_group_label_or_publisher_label.each do |publisher|
      puts "------- #{publisher.label} ----------------"
      publisher.advertisers.each do |advertiser|
        advertiser.stores.each do |store|
          unless store.latitude_and_longitude_present?
            if store.address_mappable?
              begin                
                if !store.set_longitude_and_latitude!(true)
                  puts "ERROR: unable to set lat/long for #{store.id} due to: #{store.errors.full_messages}"
                end
              rescue
                puts "ERROR: unable to set lat/long for #{store.id} due to: #{$!}"
              end
            else
              puts "INFO: unmappable store: #{store.id} - #{store.address} for advertiser: '#{advertiser.name}'"
            end
          end
        end
      end
    end
    puts "completed!"
  end
  
  desc "send push notifications for PUBLISHER_LABEL, can also supply a list of specific devices with DEVICES (comma delimited)"
  task :send_push_notifications => :environment do
    publisher_label = ENV["PUBLISHER_LABEL"]
    raise "PUBLISHER_LABEL is required" unless publisher_label
    publisher = Publisher.find_by_label(publisher_label)
    raise "Unable to find publisher with given label: #{publisher_label}" unless publisher    
    devices = ENV["DEVICES"].present? ? ENV["DEVICES"].split(",") : nil
    publisher.send_push_notifications!(:devices => devices)
  end
  
  def publishers_based_on_publishing_group_label_or_publisher_label
    publishing_group_label  = ENV["PUBLISHING_GROUP_LABEL"]
    publisher_label         = ENV["PUBLISHER_LABEL"]    
    raise "PUBLISHING_GROUP_LABEL or PUBLISHER_LABEL is required" unless publishing_group_label || publisher_label
    publisher_label ? [Publisher.find_by_label(publisher_label)] : PublishingGroup.find_by_label(publishing_group_label).publishers
  end
  
  def geocode_publisher(publisher, zoom_level)
    unless publisher.city.blank? || publisher.state.blank?
      geocoding = Geokit::Geocoders::GoogleGeocoder.geocode("#{publisher.city}, #{publisher.state}")
      begin
        if geocoding.success?
          publisher.update_attributes({
            :google_map_zoom_level  => zoom_level,
            :google_map_longitude   => geocoding.lng,
            :google_map_latitude    => geocoding.lat,
          })
        end
      rescue
        puts "unable to set geo location for #{publisher.label} do to: #{$!}"
      end
    else
      puts "unable to set #{publisher.inspect} no city or state"
    end
  end
  
end