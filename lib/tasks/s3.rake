namespace :s3 do

  namespace :migrate do
    
    #
    #  Common / All
    #

    desc "Copy static assets from file system to S3. Use LIMIT for testing small migrations."
    task :all do
      import(:all)
    end    
    
    desc "Copy RECENT static assets from file system to S3, default is 7 days.  Supply DAYS to change."
    task :recent do
      import(:all, {:days => (ENV['DAYS']||7).to_i})
    end
    
    
    #
    #  Offers
    #
    
    desc "migrate all the offer attachments"
    task :offer => ["s3:migrate:offer:photos", "s3:migrate:offer:offer_images" ] do      
    end
    
    namespace :offer do
    
      desc "migrate all the offer photos, can limit by ID where ID is one id or comma delimited list of IDs"
      task :photos do
        import( asset_by_class_and_attachment(Offer, "photo") )
      end
      
      desc "migrate all the offer offer_images, can limit by ID where ID is one id or comma delimited list of IDs"
      task :offer_images do
        import( asset_by_class_and_attachment(Offer, "offer_image") )
      end
            
    end
    
    #
    #  Advertisers
    #
    
    desc "migrate all the advertiser attachments"
    task :advertiser => ["s3:migrate:advertiser:logos"] do; end
    
    namespace :advertiser do
      
      desc "migrate all the advertiser logos, can limit by ID where ID is one id or comma delimited list of IDs"
      task :logos do
        import( asset_by_class_and_attachment(Advertiser, "logo") )
      end
      
    end
    
    #
    #  Daily Deals
    #
    
    desc "migrate all the daily deal attachments"
    task :daily_deal => ["s3:migrate:daily_deal:photos"] do; end
    
    namespace :daily_deal do
      
      desc "migrate all daily deal photos, can limit by ID where ID is one id or comma delimited list of IDs"
      task :photos do
        import( asset_by_class_and_attachment(DailyDeal, "photo") )
      end
      
    end 
    
    #
    #  GiftCertificate
    #
    
    desc "migrate all the deal certificate attachments"
    task :gift_certificate => ["s3:migrate:gift_certificate:logos"] do; end
    
    namespace :gift_certificate do
    
      desc "migrate all the deal certificate logos, can limit by ID where ID is one id or comma delimited list of IDs"
      task :logos do
        import( asset_by_class_and_attachment(GiftCertificate, "logo") )
      end
      
    end
    
    #
    #  Publisher
    #
    
    desc "migrate all the publisher attachments"
    task :publisher => ["s3:migrate:publisher:logos", "s3:migrate:publisher:paypal_checkout_header_images"] do; end
    
    namespace :publisher do
    
      desc "migrate all the publisher logos, can limit by ID where ID is one id or comma delimited list of IDs"
      task :logos do
        import( asset_by_class_and_attachment( Publisher, "logo" ) )
      end
      
      desc "migrate all the publisher paypal_checkout_header_images, can limit by ID where ID is one id or comma delimited list of IDs"
      task :paypal_checkout_header_images do
        import( asset_by_class_and_attachment( Publisher, "paypal_checkout_header_image" ) )
      end
      
    end
   
  end
  
  desc "refreshes attachments based on original. run rake s3:refresh for usage."
  task :refresh => :environment do

    all               = ENV['ALL']
    force             = ENV['FORCE']
    model             = ENV['MODEL']
    attachment        = ENV['ATTACHMENT']
    publisher         = Publisher.find_by_label(ENV['PUBLISHER']) unless ENV['PUBLISHER'].blank?
    publishing_group  = PublishingGroup.find_by_name(ENV['PUBLISHING_GROUP'])

    display_usage_for_refresh unless publisher || publishing_group || all

    puts "model: #{model} attachment: #{attachment}"

    klazz           = Module.const_get( model )
    attachment_definitions = attachment_definitions(attachment, klazz)
    total_updates = 0

    publishers_to_process(all, publisher, publishing_group).each do |publisher|
      puts "publisher: #{publisher.name}"
      puts "  updating:"
      puts "    class: #{klazz.to_s} attachment: #{attachment_definitions.collect(&:first).join(', ')}"
      records = 0
      updates = 0
      publisher.send( model.underscore.pluralize ).each do |item|
        if item.hide_at > Time.zone.now
          records += 1
          attachment_definitions.each do |definition| # For each type of attachment a model might have (e.g., photo, logo)
            attachment_name = definition.first
            attachment_options = definition.second

            # Only process if the original exists, otherwise the reprocess will fail
            if item.send( attachment_name ).exists?( :original )
              p "Original found for #{item.id}"
              if should_reprocess?(attachment_name, attachment_options, force, item)
                updates += 1
                p "Reprocessing"
                item.send( attachment_name ).reprocess!
              end
            else
              puts "original image does not exist for #{item.id}"
            end
          end
        end
      end
      puts "      processed #{records} records, with #{updates} updates"
      total_updates += updates
    end

    puts "Processed #{total_updates} total updates"
  end

  def publishers_to_process(all, publisher, publishing_group)
    if all
      publishers = Publisher.all
    elsif publisher.present?
      publishers = [publisher]
    else
      publishers = publishing_group.publishers
    end
    publishers
  end

  def attachment_definitions(attachment, klazz)
    attachment_keys = attachment.to_s.split(",").collect(&:strip)
    attachment_definitions = klazz.attachment_definitions
    attachment_definitions = attachment_definitions.collect { |definition| definition if attachment_keys.include?(definition.first.to_s) }.compact unless attachment_keys.empty?
    attachment_definitions
  end

  def should_reprocess?(attachment_name, attachment_options, force, item)
    should_delete = missing_attachment_styles?(item, attachment_name, attachment_options)
    force || should_delete
  end
  
  desc "Copy image assets that are <= 1 week old from production to staging buckets"
  task :sync_latest_production_assets => :environment do
    AWS::S3::Replicator.sync_latest_production_assets!
  end
  
  def import(*args)
    klass = args.shift
    case 
    when klass.is_a?(Hash)
      _import([klass], args.pop)
    when klass.is_a?(Array)
      _import(klass, args.pop)
    when (klass.is_a?(Symbol) && klass == :all)
      _import(assets, args.pop)
    else
      raise( ArgumentError, "first argument must be one of the following: Hash, Array of Hashes, or symbol :all")
    end 
        
  end
  
  def _import(assets, options)
    require File.expand_path("../models", __FILE__)
    establish_connection!
    
    options ||= {}
        
    find_options = { :order => "created_at desc" }
    find_options[:conditions] = ["id in (?)", ENV["ID"] ] if ENV["ID"].present?
    find_options[:conditions] ||= ["created_at > ?", (options[:days] == 1 ? options[:days].day.ago : options[:days].days.ago)] if options[:days].present?
    find_options[:limit]      = ENV["LIMIT"] if ENV["LIMIT"].present? 
    
    
    verbose = self.send(:verbose)
    verbose = false if verbose.is_a?(Symbol)
    
    assets.each do |asset|
      asset[:class].all(find_options).each do |model|        
        puts "#{model[:class]} #{asset[:attachment]} #{model.id}" if verbose
        dir = File.expand_path("public/system/#{asset[:file_dir]}/#{model.id}", Rails.root)
        if File.exists?(dir)
          styles = model.send(asset[:attachment]).styles
          styles.merge!(:original => {}) # adds the default original style
          styles.each do |style_key, style|
            path = "#{dir}/#{style_key}"
            if File.exists?(path)
              # Returns . and ..
              entries = Dir.entries(path).reject { |e| e == "." || e == ".." }
              case entries.size
              when 0
                puts "Skip empty directory"
              when 1
                file = File.new("#{path}/#{entries.last}")
              else
                files = entries.map do |entry|
                  File.new "#{path}/#{entry}"
                end
                file = files.sort_by(&:mtime).last 
                files.each {|f| f.close unless f == file }
                puts "Expected 1 entry in #{path}, but found #{entries.size - 2}. Using most recent file: #{file.path}"
              end

              if file 
                s3_key = "#{style_key}#{File.extname(file.path)}"
                bucket = asset[:class].attachment_definitions[asset[:attachment].to_sym][:bucket]
                s3_bucket = "#{bucket}/#{Rails.env}/#{model.id}" 
                puts "working on: #{s3_key}/#{s3_bucket}" if verbose
                if ENV["FORCE"].present? || !AWS::S3::S3Object.exists?(s3_key, s3_bucket)                
                  store_asset_on_s3 file.path, s3_key, s3_bucket
                else
                  puts "Skipping #{s3_key} ... file already on S3" if verbose
                end
                file.close
              end
            else
              puts "No image file for style #{style_key}"
            end
          end
        else
          puts "dir #{dir} does not exist." if verbose
        end
      end
    end
  end
  
  def assets
    [
      { :class => Advertiser, :attachment => "logo", :file_dir => "logos" },
      { :class => DailyDeal, :attachment => "photo", :file_dir => "daily_deal_photos" },
      { :class => GiftCertificate, :attachment => "logo", :file_dir => "logos" },
      { :class => Offer, :attachment => "offer_image", :file_dir => "offer_images" },
      { :class => Offer, :attachment => "photo", :file_dir => "photos" },
      { :class => Publisher, :attachment => "logo", :file_dir => "logos" },
      { :class => Publisher, :attachment => "paypal_checkout_header_image", :file_dir => "paypal_checkout_header_images" }
    ]
  end
  
  def asset_by_class_and_attachment(klazz, attachment)
    assets.collect{|asset| asset if asset[:class] == klazz && asset[:attachment] == attachment}.compact
  end
  
  def establish_connection!
    config = YAML.load_file(File.expand_path("#{Rails.root}/config/paperclip_s3.yml", Rails.root))
    AWS::S3::Base.establish_connection!(
      :access_key_id     => config["access_key_id"],
      :secret_access_key => config["secret_access_key"]
    )
  end
  
  def store_asset_on_s3(file_path, s3_key, s3_bucket)
    puts "Storing #{s3_bucket}/#{s3_key}"
    AWS::S3::S3Object.store(
      s3_key, 
      open(file_path), 
      s3_bucket,
      :access => :public_read
    )
    # Shot in the dark to solve a "too many open files" error
    sleep 0.300
  end 
  
  def display_usage_for_refresh
    puts "=================================================="
    puts " s3:refresh usage"
    puts "=================================================="
    puts ""
    puts "Responsible for refreshing model attachments based on the original file."
    puts ""
    puts "Options:"
    puts ""
    puts "  * MODEL            -- the model to refresh. (Optional)"
    puts "  * ATTACHMENT       -- the attachment to refresh.  Can be a comma delimited list. (Optional)"
    puts "  * PUBLISHER        -- the publisher to refresh, the publisher label.  "
    puts "  * PUBLISHING_GROUP -- the publishing group to refresh, the publishing group name.  PUBLISHER or PUBLISHING_GROUP must be supplied. "
    puts "  * ALL              -- refreshes all publishers."
    puts ""
    puts "  PUBLISHER or PUBLISHING_GROUP or ALL must be supplied. If ALL supplied, PUBLISHER and PUBLISHING_GROUP will be ignored"
    puts ""
    puts "Examples:"
    puts ""
    puts "  rake s3:refresh MODEL=Offer PUBLISHER=houstonpress"                             
    puts "  -- will refresh all the attachments on all offers for the 'houstonpress' publisher"
    puts ""
    puts "  rake s3:refresh MODEL=Offer ATTACHMENT=photo PUBLISHING_GROUP=\"Village Voice Media\""
    puts "  -- will refresh only the photo attachment on all offers for all the Village Voice Media publishers"
    puts ""
    exit!
  end  
  
  def missing_attachment_styles?(item, attachment_name, attachment_options)
    missing = false
    styles_hash = attachment_options[:styles].respond_to?(:call) ? attachment_options[:styles].call(item.photo) : attachment_options[:styles]

    styles_hash.keys.each do |style_key|
      missing = true unless item.send(attachment_name).exists?( style_key )
    end
    return missing
  end
end
