namespace :oneoff do
  
  TWC_COORDINATES = {
    "clickedin-austin" => {
      :latitude => 30.26737,
      :longitude => -97.743301,
      :zoom => 11
    },
    "clickedin-dallas" => {
      :latitude => 32.8072,
      :longitude => -96.7696,
      :zoom => 10
    },
    "clickedin-sanantonio" => {
      :latitude => 29.424049,
      :longitude => -98.493118,
      :zoom => 11
    },
    "clickedin-charlotte" => {
      :latitude => 35.227111,
      :longitude => -80.843239,
      :zoom => 12
    }
  }
  
  desc "adds latitude and longitude to the timewarnercable publications"
  task :add_latitude_longitude_to_timewarner_publications do
    
    PublishingGroup.find_by_label("rr").publishers.each do |pub|
      settings = TWC_COORDINATES[pub.label]
      if settings
        pub.update_attributes(:google_map_latitude => settings[:latitude], :google_map_longitude => settings[:longitude], :google_map_zoom_level => settings[:zoom])
      end
    end
    
  end
  
end