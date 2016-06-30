require 'lib/oneoff/groucher_import'

namespace :oneoff do
  namespace :mytownvip do
    desc "import consumers for groucher dailydeal sites depending on the city they are in."
    task :import_existing_consumers => :environment do

      dry_run = ENV['DRY_RUN'].present?

      ["mytownvip-national"].each do |label|
        puts "importing users for #{label}."
        filename = "tmp/#{label}.csv"
        publisher = Publisher.find_by_label(label)

        total = 0
        dups  = 0
        start_time = Time.now
        if File.exists?(filename)
          FasterCSV.foreach(filename) do |row|
            unless row[0] =~ /First/

              first_name  = row[0] || "MyTownVIP"
              last_name   = row[1] || "Member"
              email       = row[2]
              address     = row[3]
              city        = row[4]
              state       = row[5]
              zip_code    = row[6]
              country = Country.find_by_code("US")

              if publisher.publishing_group.consumers.find_by_email(email).present?
                dups += 1
                next
              end

              attributes = { :email      => email,
                             :first_name => first_name,
                             :last_name  => last_name,
                             :force_password_reset  => true,
                             :password              => "123456",
                             :password_confirmation => "123456",
                             :agree_to_terms        => true,
                             :address_line_1        => address,
                             :city                  => city,
                             :state                 => state,
                             :country               => country
              }

              register_at =  Time.zone.now

              consumer = Consumer.new(attributes)
              consumer.publisher_id = publisher.id
              consumer.created_at   = register_at
              consumer.activated_at = register_at

              if dry_run
                if consumer.valid?
                  total += 1
                  puts "DRY_RUN: Consumer #{consumer.email} is valid."
                else
                  puts "DRY_RUN: Consumer #{consumer.email}. Errors on validation: #{consumer.errors.full_messages}."
                end
              else
                if consumer.save
                  total += 1
                else
                  puts "Invalid consumer: #{consumer.email} - #{consumer.errors.full_messages}"
                end
              end
            end
          end
          puts "   total: #{total}"
          puts "   duplicates: #{dups}"
          puts "   finished in: #{Time.now - start_time} ms"
        else
          puts "Unable to find file: #{filename}."
        end
      end
    end
  end
end
