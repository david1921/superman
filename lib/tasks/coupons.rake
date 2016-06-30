namespace :coupons do
  desc "Dump coupons to XML for PUBLISHER"
  task :dump => :environment do
    coupons_dir = File.expand_path(Rails.root + "tmp/coupons")
    system("rm -rf #{coupons_dir}") if File.exists?(coupons_dir)
    system "mkdir -p #{coupons_dir}/offer_images"
    system "mkdir -p #{coupons_dir}/logos"
    system "mkdir -p #{coupons_dir}/photos"

    if ENV["PUBLISHER"] == "ALL"
      publishers = Publisher.find(:all).map(&:id)
    else
      publishers = [Publisher.find_by_name(ENV["PUBLISHER"]).id]
    end
    
    publishers.each do |publisher_id|
      publisher = Publisher.find(publisher_id, :include => { :advertisers => [ :store, { :offers => :categories } ] })

      open("#{coupons_dir}/#{publisher.id}.xml", "w") { |io|
        io << publisher.to_xml(
                :methods => [ :category_names ],
                :include => {:advertisers => { :include => [ :offers, :store ] } }
              )
      }

      publisher.advertisers.map { |c| c.offers.first }.each do |offer|
        if offer
          %w{ offer_images photos }.each do |asset|
            asset_dir = File.expand_path(Rails.root + "public/system/#{asset}")
            system("cp -r #{asset_dir}/#{offer.id} #{coupons_dir}/#{asset}/") if File.exists?("#{asset_dir}/#{offer.id}")
          end
        end
      end

      publisher.advertisers.each do |advertiser|
        asset_dir = File.expand_path(Rails.root + "public/system/logos")
        system("cp -r #{asset_dir}/#{advertiser.id} #{coupons_dir}/logos/") if File.exists?("#{asset_dir}/#{advertiser.id}")
      end
    end
  end

  desc "Load coupons from XML"
  task :load => :environment do
    coupons_dir = File.expand_path(Rails.root + "tmp/coupons")
    offer_images_root = File.expand_path("#{coupons_dir}/offer_images")
    logo_files_root = File.expand_path("#{coupons_dir}/logos")
    photos_logo_root = File.expand_path("#{coupons_dir}/photos")

    Offer.transaction do
      Dir.glob("#{coupons_dir}/*.xml").map { |p| p[/\d+.xml/] }.each do |publisher_id|
        coupons = Hash.from_xml(File.read("#{coupons_dir}/#{publisher_id}"))["publisher"]
        publisher = Publisher.find_or_create_by_name(coupons["name"])
        puts "Publisher: #{publisher.name}"
        publisher.update_attribute(:theme, coupons["theme"])
        publisher.update_attribute(:coupon_page_url, coupons["coupon_page_url"])
        publisher.update_attribute(:label, coupons["label"])
        publisher.update_attribute(:link_to_email, coupons["link_to_email"])
        publisher.update_attribute(:link_to_map, coupons["link_to_map"])
        publisher.update_attribute(:link_to_website, coupons["link_to_website"])
        publisher.update_attribute(:random_coupon_order, coupons["random_coupon_order"])
        publisher.update_attribute(:subcategories, coupons["subcategories"])
        coupons["advertisers"].each do |loaded_advertiser|
          advertiser = publisher.advertisers.create!(
            :coupon_clipping_modes => loaded_advertiser["coupon_clipping_modes"],
            :coupon_limit => nil,
            :landing_page => loaded_advertiser["landing_page"],
            :tagline => loaded_advertiser["tagline"],
            :name => loaded_advertiser["name"],
            :voice_response_code  => loaded_advertiser["voice_response_code"],
            :website_url  => loaded_advertiser["website_url"],
            :call_phone_number  => loaded_advertiser["call_phone_number"],
            :email_address  => loaded_advertiser["email_address"],
            :google_map_url  => loaded_advertiser["google_map_url"]
          )
          puts advertiser.name

          begin
            file_name = loaded_advertiser['logo_file_name']
            unless file_name.blank?
              file_name += "." unless file_name =~ /\./
              advertiser.logo = File.new("#{logo_files_root}/#{loaded_advertiser['id']}/original/#{file_name}")
              advertiser.save
            end
          rescue Exception => e
            p "#{e}: For #{advertiser}"
          end
          
          if loaded_advertiser["store"]
            p "store: #{loaded_advertiser['store']}"
            loaded_store = loaded_advertiser["store"]
            s = advertiser.stores.create(
              :address_line_1 => loaded_store["address_line_1"],
              :address_line_2 => loaded_store["address_line_2"],
              :city => loaded_store["city"],
              :state => loaded_store["state"],
              :zip => loaded_store["zip"],
              :phone_number => loaded_store["phone_number"]
            )
            p "created store #{s} #{s.errors.full_messages}"
          end

          if loaded_advertiser["offers"].present?
            loaded_offer = loaded_advertiser["offers"].first
            offer = advertiser.offers.create!(
              :category_names => loaded_offer["category_names"],
              :email => loaded_offer["email"],
              :expires_on => loaded_offer["expires_on"],
              :message => loaded_offer["message"] || "message",
              :phone_number => loaded_offer["phone_number"],
              :terms => loaded_offer["terms"],
              :txt_message => loaded_offer["txt_message"],
              :value_proposition => loaded_offer["value_proposition"],
              :value_proposition_detail => loaded_offer["value_proposition_detail"],
              :website => loaded_offer["website"]
            )

            begin
              file_name = loaded_offer['offer_image_file_name']
              unless file_name.blank?
                file_name += "." unless file_name =~ /\./
                offer.offer_image = File.new("#{offer_images_root}/#{loaded_offer['id']}/original/#{file_name}")
                offer.save
              end
            rescue Exception => e
              p "#{e}: For #{offer}"
            end

            begin
              offer.reload
              if (file_name = loaded_offer['photo_file_name'])
                file_name += "." unless file_name =~ /\./
                offer.photo =  File.new("#{photos_logo_root}/#{loaded_offer['id']}/original/#{file_name}")
                offer.save
              end
            rescue Exception => e
              p "#{e}: For #{offer}"
            end
          end
        end
      end
    end
  end

  desc "Re-read and save full-size image dimensions. Options: PUBLISHER (restrict to publisher with this label), CLASS (Advertiser or Offer)"
  task :refresh_dimensions => :environment do
    if ENV["PUBLISHER"].present?
      publishers = Publisher.find(:all, :conditions => { :label => ENV["PUBLISHER"] })
    else
      publishers = Publisher.all
    end
    
    publishers.each do |publisher|
      if ENV["CLASS"].blank? || ENV["CLASS"] == "Advertiser"
        publisher.advertisers.find(:all).each do |advertiser|
          if advertiser.logo.file?
            if File.exists?(advertiser.logo.path)
              puts "Read advertiser #{advertiser.id} logo dimensions"
              begin
                Timeout.timeout(10) do
                  geometry = Paperclip::Geometry.from_file(advertiser.logo.path(:facebook))
                  advertiser.logo_facebook_width = geometry.width
                  advertiser.logo_facebook_height = geometry.height
                  advertiser.save!
                end
              rescue Exception => e
                puts e
              end
            else
              puts "WARN: Advertiser #{advertiser.id} logo file not found at #{advertiser.logo.path}"
            end
          end
        end
      end

      publisher.offers.find(:all).each do |offer|
        if ENV["CLASS"].blank? || ENV["CLASS"] == "Offer"
          if offer.offer_image.file?
            puts "Read offer #{offer.id} image dimensions"
            begin
              Timeout.timeout(10) do
                geometry = Paperclip::Geometry.from_file(offer.offer_image.path(:full_size))
                offer.offer_image_width = geometry.width
                offer.offer_image_height = geometry.height
                offer.save!
              end
            rescue Exception => e
              puts e
            end
          end
        end
      end
    end
  end

  desc "Create Facebook thumbnails for PUBLISHER"
  task :refresh_facebook_thumbnails => :environment do
    Publisher.find_by_label(ENV["PUBLISHER"]).advertisers.each do |advertiser|
      if advertiser.logo.file? && File.exists?(advertiser.logo.path)
        puts "Create Facebook thumbnail for #{advertiser.id}"
        begin
          Timeout.timeout(10) do
            advertiser.logo.reprocess!
            advertiser.save!
          end
        rescue Exception => e
          puts e
        end
      else
        puts "WARN: Advertiser #{advertiser.id} logo file not found at #{advertiser.logo.path}"
      end
    end
  end

  desc "Fetch copies of publishers' coupon pages"
  task :pages => :environment do
    rm_rf "public/system/pages"
    mkdir_p "public/system/pages"

    Publisher.find(:all).each do |publisher|
      puts publisher.name
      if publisher.coupon_page_url.present?
        puts publisher.coupon_page_url
        uri = URI.parse(publisher.coupon_page_url)
        html = Net::HTTP.get uri
        
        html.gsub!(/http:\/\/(.*).analoganalytics.com/, "http://localhost:3000")
        html.gsub!(/'\//, "'http://#{uri.host}/")
        html.gsub!(/"\//, "\"http://#{uri.host}/")
        
        File.open("public/system/pages/#{publisher.label}.html", "w") { |file| file << html }
      end
    end
  end
  
  desc "Generate Coupon Codes For Publisher or Publishing Group"
  task :generate_codes => :environment do
    
    if ARGV.size > 1
      publishers = []
      prefix     = nil
      force      = false
      ARGV.each do |argument|
        key, value = argument.split("=")
        case key
        when "PUBLISHER"
          publisher  = Publisher.find_by_name( value )
          publishers << publisher unless publisher.nil?
        when "PUBLISHING_GROUP"
          group      = PublishingGroup.find_by_name( value )
          publishers = group.publishers unless group.nil?
        when "PREFIX"
          prefix = value
        when "FORCE"
          force = (value == 'true' ? true : false)
        end
      end

      raise( ArgumentError, "missing a publisher, please supply a PUBLISHER or PUBLISHING_GROUP") if publishers.empty?
      puts "WARNING: no coupon prefix was given, will be using existing coupon prefix" if prefix.blank?

      if force
        puts "generating codes (FORCE MODE) -- we will be overriding existing codes"      
      else
        puts "generating codes -- we will NOT be overriding existing codes"
      end

      publishers.each do |publisher|
        publisher.update_attribute( :coupon_code_prefix, prefix ) unless prefix.blank?
        publisher.update_attribute( :generate_coupon_code, true )
        publisher.generate_coupon_codes( force )
      end      
    else 
      puts "\n\n"
      puts "=========================================================================================================="
      puts "USAGE" 
      puts "==========================================================================================================\n\n"
      puts "Requires at least one publisher, you can supply a single publisher by name such as:\n\n"
      puts " rake coupons:generate_codes PUBLISHER=\"Monthly Grapevine\"\n\n"
      puts "Or, you can supply a publishing group such as:\n\n"
      puts " rake coupons:generate_codes PUBLISHING_GROUP=\"Student Discount Handbook\"\n\n\n"
      puts "Optional Arguments:\n\n"
      puts " PREFIX -- this is used to set the coupon code prefix for the publisher(s) found\n"
      puts " FORCE -- this forces existing coupon codes to be regenerated, otherwise existing "
      puts "          codes are left alone."
      puts "\n\n"
      puts "Full example:\n\n"
      puts "  rake coupons:generate_codes PUBLISHING_GROUP=\"Student Discount Handbook\" PREFIX=\"SDHS10\" FORCE=true"
      puts "\n"
      puts "==========================================================================================================\n\n"
    end
    
    
  end
end

namespace :paperclip do
  desc "Find and remove orphaned Paperclip assets"

  task :destroy_orphans => :environment do
  destroyed = Hash.new { [] }
    %w( background_images coupon_logos lead_background_images ).each do |asset_type|
      p "Remove obsolete #{asset_type} dir"
      `rm -rf public/system/#{asset_type}`
    end
    
    %w( offer_image photo ).each do |asset_type|
      p "Finding orphaned #{asset_type}s"
      Dir["public/system/#{asset_type}s/*"].each do |asset_dir|
        id = asset_dir[/\/(\d+)$/, 1].to_i
        if Offer.exists?(id)
          offer = Offer.find(id)
          file_name = offer["#{asset_type}_file_name"]
          Dir["public/system/#{asset_type}s/#{id}/**/*.*"].each do |asset_file|
            if file_name.present?
              asset_file_name = asset_file[/\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+\/([^\.]+)/, 1]
              unless asset_file_name == file_name[/([^\.]+)/, 1]
                `rm #{asset_file}`
                destroyed[asset_type] = destroyed[asset_type] << "#{id}: #{asset_file}"
              end
            end
          end
        else
          `rm -rf public/system/#{asset_type}s/#{id}`
          destroyed[asset_type] = destroyed[asset_type] << id
        end
      end
    end
    
    %w( logo ).each do |asset_type|
      p "Finding orphaned #{asset_type}s"
      Dir["public/system/#{asset_type}s/*"].each do |asset_dir|
        id = asset_dir[/\/(\d+)$/, 1].to_i
        if Advertiser.exists?(id)
          offer = Advertiser.find(id)
          file_name = offer["#{asset_type}_file_name"]
          Dir["public/system/#{asset_type}s/#{id}/**/*.*"].each do |asset_file|
            if file_name.present?
              asset_file_name = asset_file[/\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+\/([^\.]+)/, 1]
              unless asset_file_name == file_name[/([^\.]+)/, 1]
                `rm #{asset_file}`
                destroyed[asset_type] = destroyed[asset_type] << "#{id}: #{asset_file}"
              end
            end
          end
        else
          `rm -rf public/system/#{asset_type}s/#{id}`
          destroyed[asset_type] = destroyed[asset_type] << id
        end
      end
    end
    
    p destroyed
  end
end
