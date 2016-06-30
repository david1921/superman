# Before running this:
# 
# 1. Do a DRY_RUN=1. Make a note of the number of zip codes and subscribers.
# 2. Ensure zip code count matches expected from xls file.
# 3. Ensure # subscribers that would have been updated matches this SQL query:
#    > select count(*) from subscribers where publisher_id = 179 and zip_code in
#    > (select zip_code from publisher_zip_codes where publisher_id = new_market_id);
# 4. Count how many subscribers the new market currently has:
#    > select count(*) from subscribers where publisher_id = new_market_id;
# 5. Run the script without DRY_RUN.
# 6. Ensure that query #3 is now zero, and query #4 has been augmented by
#    the initial count of #3.
namespace :oneoff do

  task :remap_entertainment_zips_to_markets, [:market] => :environment do |t, args|
    dry_run = ENV['DRY_RUN'].present?
    
    puts "** this is a DRY RUN. no changes will be saved to the database." if dry_run
    
    market = args[:market]
    raise "missing required argument market" unless market.present?
    
    publisher = Publisher.find_by_label("entertainment#{market}")
    raise "couldn't find entertainment publisher for market: #{market}" unless publisher.present?
    
    generic_publisher = Publisher.find_by_label("entertainment")
    
    publisher_zip_codes = publisher.zip_codes
    if publisher_zip_codes.present?
    puts "found #{publisher_zip_codes.size} zip codes for publisher #{publisher.label}"
    else
      puts "Publishing doesn't have any zip codes assigned, skipping."
      next # read as return, but we are in rake task.
    end
    
    subscribers_in_zip_codes = generic_publisher.subscribers.find_all_by_zip_code(publisher.zip_codes)
    puts "found #{subscribers_in_zip_codes.size} subscribers in #{generic_publisher.label}'s zip codes"
    
    num_updated = 0
    publisher_city = publisher.city.titleize
    raise "can't determine city for publisher '#{publisher.label}'" unless publisher_city.present?

    subscribers_in_zip_codes.each do |subscriber|
      subscriber.publisher_id = publisher.id
      subscriber.city = publisher_city
      subscriber.save! unless dry_run
      num_updated += 1
      puts "updated #{num_updated} records so far" if (num_updated % 1000) == 0
    end
    
    puts "#{num_updated} subscribers assigned to publisher: #{publisher.label}, city: #{publisher_city}"
  end
  task :remap_all_entertainment_subscribers => :environment do
    pg = PublishingGroup.find_by_label("entertainment")
    publisher_labels = pg.publishers.map(&:label)
    publisher_labels.map! { |pl|  pl.gsub!(/entertainment/, '') }
    publisher_labels.reject! {|pl| pl.empty? || pl.include?("demo") }
    publisher_labels.each do |pl|
      puts "Running task with market=#{pl}"
      
      Rake::Task["oneoff:remap_entertainment_zips_to_markets"].reenable
      Rake::Task["oneoff:remap_entertainment_zips_to_markets"].invoke(pl)
    end
  end
  
end