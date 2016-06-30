namespace :oneoff do
  namespace :side_deal_scheduling do

    # Assumes that the migration '20111208000838_side_deal_scheduling' has run and that
    # the featured boolean still exists on DailyDeal. Does not use named scopes for 'featured'
    # as those may have changed by new side-deal-scheduling functionality.
    desc "Find all unfeatured deals and populate the side-deal date fields"
    task :populate_fields => :environment do
      batch_size = 100
      total_deals = DailyDeal.count(:conditions => "featured = false")
      total_batches = total_deals / batch_size + 1
      batch_count = 1

      puts "Populating featured deals' side_start_at and side_end_at"
      puts "  - Processing #{total_deals} daily deals in batches of #{batch_size}"

      DailyDeal.find_in_batches(:conditions => "featured = false",
                                :batch_size => batch_size) do |deals|
        puts "  - Processing #{batch_count.ordinalize} batch of #{total_batches}"
        deals.each do |deal|
          ActiveRecord::Base.connection.execute("UPDATE daily_deals SET side_start_at = '#{deal.start_at.utc.strftime("%Y-%m-%d %H:%M:%S")}', side_end_at = '#{deal.hide_at.utc.strftime("%Y-%m-%d %H:%M:%S")}' WHERE id = #{deal.id};")
        end
        batch_count += 1
      end
    end

    desc "Print each publisher's featured deal's ID and list publishers without a featured deal"
    task :print_featured_deal_ids => :environment do
      Publisher.all(:order => "id ASC").each do |publisher|
        featured_deals = publisher.daily_deals.active.ordered_by_start_at_descending.featured
        puts "#{publisher.id}\t#{featured_deals.empty? ? "" : featured_deals.first.id}"
      end
    end

  end
end