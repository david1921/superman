namespace :oneoff do
  namespace :lin_media do

   desc "import consumers for lin_media publishers" 
   task :import_existing_consumers => :environment do

    ["savenow-austin", "savenow-hamptonroads", "savenow-indianapolis", "savenow-providence", "savenow-westernmass"].each do |label|
      puts "----- importing consumers for: #{label}"
      filename = "#{Rails.root}/tmp/#{label}.csv"
      publisher = Publisher.find_by_label(label)

      total = 0
      dups  = 0
      start_time = Time.now
      if File.exists?(filename)
        FasterCSV.foreach(filename) do |row|
          unless row[0] =~ /Email/
            total += 1
            email_address   = row[0]
            first_name      = row[1]
            last_name       = row[2]
            city            = row[3]
            
            if publisher.publishing_group.consumers.find_by_email(email_address).present?
              dups += 1
              next
            end

            attributes = { :email => email_address,
                           :first_name => first_name,
                           :last_name => last_name,
                           :force_password_reset => true,
                           :password => "lin_mediaimport",
                           :password_confirmation => "lin_mediaimport",
                           :agree_to_terms => true }

            consumer = Consumer.new(attributes)
            consumer.publisher_id = publisher.id
            consumer.activated_at = Time.now 
            unless consumer.save
              puts "invalid consumer: #{consumer.email} - #{consumer.errors.full_messages}"
            end
          end
        end
        puts "    total: #{total}"
        puts "    duplicates: #{dups}"
        puts "    finished in: #{Time.now - start_time} ms"
      else
        puts "unable to find file: #{filename}" 
      end
    end
   end
  end
end
