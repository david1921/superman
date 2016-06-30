# How many subscribers does entertainment have?
# > select count(*) from subscribers where publisher_id = 179;

# How many subscribers does entertainment dallas have?
# > select count(*) from subscribers where publisher_id = 176;

# Show entertainment dallas subscriber data:
# > select email, other_options from subscribers where publisher_id = 176;

# How many subscribers does entertainment detroit have?
# > select count(*) from subscribers where publisher_id = 175;

# Show entertainment detroit subscriber data:
# > select email, other_options from subscribers where publisher_id = 175;

# How many subscribers does entertainment fortworth have?
# > select count(*) from subscribers where publisher_id = 177;

# Show entertainment fortworth subscriber data:
# > select email, other_options from subscribers where publisher_id = 177;

namespace :oneoff do
  namespace :entertainment do

    desc "Reassign subscribers (with long zip code 12345-1234) to a new publisher based on their zip code."
    task :reassign_subs_with_long_zip_code, [:dry_run] => :environment do |t, args|
      dry_run = args[:dry_run]
      entertainment_publishing_group = PublishingGroup.find_by_label("entertainment")

      rzipcode = '^[0-9]{5}\-[0-9]{4}$'
      count = 0

      subs_to_fix = entertainment_publishing_group.publisher_subscribers.find(:all, :conditions => ["zip_code REGEXP ?", rzipcode])

      subs_to_fix.each do |subscriber|
        new_zip = subscriber.zip_code.slice(0...5)
        publisher_id = entertainment_publishing_group.publisher_zip_codes.find_by_zip_code(new_zip).try(:publisher_id)
        if publisher_id && subscriber.publisher_id != publisher_id
          puts "Updating subscriber #{subscriber.email} with new publisher id #{publisher_id}."
          subscriber.update_attributes!(:publisher_id => publisher_id) unless dry_run
          count = count + 1
        else
          puts "It did not updated the subscriber #{subscriber.email} because the publisher_id #{publisher_id}. Subscriber's publisher is #{subscriber.publisher_id} and zip code is #{subscriber.zip_code}."
        end
      end
      if (count == 0)
        puts "It did not found any entertainment subscriber with four digit zip codes."
      end
    end

    desc "Reassign subscribers with 4 digits zip code (leading zero was trimmed)  to a new publisher based on their zip code. DRY_RUN for not updating."
    task :reassign_subs_with_zero_leading_zip_code, [:dry_run] => :environment do |t, args|
      dry_run = args[:dry_run]
      entertainment_publishing_group = PublishingGroup.find_by_label("entertainment")

      rzipcode = '^[0-9]{4}$'
      count = 0

      subs_to_fix = entertainment_publishing_group.publisher_subscribers.find(:all, :conditions => ["zip_code REGEXP ?", rzipcode])

      subs_to_fix.each do |subscriber|
        new_zip = "0" + subscriber.zip_code
        publisher_id = entertainment_publishing_group.publisher_zip_codes.find_by_zip_code(new_zip).try(:publisher_id)
        if publisher_id && subscriber.publisher_id != publisher_id
          puts "Updating subscriber #{subscriber.email} with new publisher id #{publisher_id}."
          subscriber.update_attributes!(:publisher_id => publisher_id, :zip_code => new_zip) unless dry_run
          count = count + 1
        else
          puts "It did not updated the subscriber #{subscriber.email} because the publisher_id #{publisher_id}. Subscriber's publisher is #{subscriber.publisher_id} and zip code is #{subscriber.zip_code}."
        end
      end
      
      if (count == 0)
        puts "It did not found any entertainment subscriber with four digit zip codes."
      end
    end

    desc "Setup subscribers with blank zip code to the billing or registration zip code given by the client. DRY_RUN for not updating."
    task :reassign_subs_with_blank_zip_code, [:dry_run] => :environment  do |t, args|
      dry_run = args[:dry_run]
      entertainment_publishing_group = PublishingGroup.find_by_label("entertainment")
      entertainment_general_publisher = Publisher.find_by_label('entertainment') # here are all the subscribers that could not get into a publisher

      # This file has #new_zip, #email
      subscriber_zipcode_filename = File.join(File.dirname(__FILE__), "data", "entertainment_publisher_consumers_not_in_emails.csv")
      unless File.exists?(subscriber_zipcode_filename)
        raise "Unable to find subscribers file #{subscriber_zipcode_filename}"
      end

      count = 0
      FasterCSV.foreach(subscriber_zipcode_filename) do |row|
        new_zip, email = row
        new_publisher_id = entertainment_publishing_group.publisher_zip_codes.find_by_zip_code(new_zip).try(:publisher_id)
        our_subscriber = Subscriber.find_by_email(email)
        if our_subscriber && new_publisher_id
          puts "Updating subscriber #{our_subscriber.email} with zip code #{new_zip} and publisher #{new_publisher_id}."
          our_subscriber.update_attributes!( :zip_code => new_zip, :publisher_id => new_publisher_id) unless dry_run
          count = count + 1
        else
          puts "Did not found subscriber #{email} or publisher_id #{new_publisher_id}."
        end
      end
      puts "Changed #{count} subscribers."
    end
  
    desc "Reassign subscribers that are in the generic entertainment publisher to the one related to its zip code"
    task :reassign_subs_from_generic_publisher => :environment  do
      dry_run = ENV['DRY_RUN'].present?
 
      entertainment_publishing_group = PublishingGroup.find_by_label("entertainment")
      entertainment_general_publisher = Publisher.find_by_label('entertainment') # here are all the subscribers that could not get into a publisher
      entertainment_zip_codes = entertainment_publishing_group.publisher_zip_codes

      total_per_market = Hash.new(0)
      total = 0
      entertainment_general_publisher.subscribers.find_each do |subscriber|
        new_publisher = entertainment_zip_codes.find_by_zip_code(subscriber.zip_code).try(:publisher)
        if dry_run
          if new_publisher.nil?
            puts "DRY_RUN: It did not find any publisher with zip code #{subscriber.zip_code}."
          else
            puts "DRY_RUN: Changing subscriber #{subscriber.email} from publisher #{subscriber.publisher_id} to #{new_publisher.id}."
            total = total + 1
            total_per_market[subscriber.zip_code] += 1
          end
        else
          if new_publisher.nil?
            puts "Subscriber #{subscriber.email} . Zip code #{subscriber.zip_code} not found in AA db."
          else
            subscriber.publisher_id = entertainment_zip_codes.find_by_zip_code(subscriber.zip_code).publisher.id
            if subscriber.save
              total = total + 1
              total_per_market[subscriber.zip_code] += 1
              puts "Changed #{total} subscribers."
            else
              puts "It could not save the subscriber . #{subscriber.errors.full_messages}."
            end
          end
        end
      end

     total_per_market.each { |zip, tot| puts "#{tot} new subscribers in publisher #{entertainmet_publishing_group.publisher_zip_codes.find_by_zip_code(zip).publisher.label}" }
     puts "Changed #{total} subscribers."

    end

    desc "Reassign subscribers based on city (valids are dallas, fortworth or detroit)"
    task :reassign_subs, [:city] => :environment do |t, args|
      valid_cities = %w(dallas fortworth detroit)
  
      city = args[:city]
      raise ArgumentError, "a valid city is required (#{valid_cities.join(', ')})" unless city.present? && valid_cities.include?(city)
  
      subscriber_email_filename = File.join(File.dirname(__FILE__), "data", "entertainment_#{city}_subs.txt")
      entertainment_city_publisher = Publisher.find_by_label("entertainment#{city}")
      entertainment_publisher = Publisher.find_by_label("entertainment")
      
      unless File.exists?(subscriber_email_filename)
        raise "Unable to find subscribers file #{subscriber_email_filename}"
      end
      
      puts "Reassigning subscribers in #{subscriber_email_filename} to #{entertainment_city_publisher.label}"
  
      num_updated = 0
      num_skipped = 0
      num_errors = 0
      subscriber_emails = File.readlines(subscriber_email_filename)
      Subscriber.transaction do
        subscriber_emails.map(&:strip).each do |email|
          subscriber = Subscriber.find_by_email_and_publisher_id(email, entertainment_publisher.id)
          unless subscriber.present?
            puts "Skipping #{email}, no record found"
            num_skipped += 1
            next
          end
        
          subscriber.publisher_id = entertainment_city_publisher.id
          subscriber.other_options[:city] = city == "fortworth" ? "Ft. Worth" : city.titlecase
          if ENV['DRY_RUN'].present?
            num_updated += 1
            puts "Would have updated subscriber #{email} to: publisher: #{subscriber.publisher.label}, city: #{subscriber.other_options[:city]}"
          else
            if subscriber.save
              num_updated += 1
            else
              num_errors += 1
              puts "Error saving #{email}: #{subscriber.errors.full_messages.join(', ')}"
            end
          end
        end
      end
      
      puts "#{num_updated} records updated. #{num_errors} errors. #{num_skipped} skipped."
    end
  
  end
end
