namespace :oneoff do
  
  task :seed_entertainment_pub_zip_mappings do
    dry_run = ENV["DRY_RUN"].present?
    
    if dry_run
      puts "** this is a DRY RUN. no records will be created. **"
    end

    zipcode_file_glob = File.join(File.dirname(__FILE__), "data", "zips", "*.txt")
    zipcode_filenames = Dir[zipcode_file_glob]
    zipcode_filenames.each do |zipcode_filename|
      filename = File.basename(zipcode_filename)
      unless filename.match("^([^\.]+)\.txt$")
        puts "skipping #{zipcode_filename}: unrecognized filename format (should be *publisher_label*.txt)"
        next
      end
      
      publisher_label = "entertainment#{$1}"
      publisher = Publisher.find_by_label(publisher_label)
      unless publisher.present?
        puts "skipping #{zipcode_filename}: no publisher with label '#{publisher_label}' found"
        next
      end
      
      pub_zip_count = 0
      File.readlines(zipcode_filename).map(&:strip).each do |zip_code|
        next unless zip_code.present?
        unless dry_run
          PublisherZipCode.create(:zip_code => zip_code, :publisher_id => publisher.id)
        end
        pub_zip_count += 1
      end
      puts "created #{pub_zip_count} zip codes for publisher #{publisher.label}"
    end
  end
  
end
