namespace :oneoff do
  namespace :syndication do
    desc "set in_syndicaiton_network = true for any publisher with a syndicated deal"
    task :update_syndication_network_from_syndicated_deals => :environment do

      puts "Identifying publishers that have provided deals..."
      provider_publishers = ActiveRecord::Base.connection.select_values("select distinct(publisher_id) from daily_deals where daily_deals.id in (select distinct(source_id) from daily_deals where source_id is NOT NULL)")
      provider_publishers.each do |id|
        begin
          pub = Publisher.find(id)
          unless pub.in_syndication_network?
            puts "    Adding #{pub.label} to syndication network"
            pub.update_attribute(:in_syndication_network, true)
            puts "    Making all #{pub.label}'s deals available for syndication"
            pub.make_current_and_future_deals_available_for_syndication
          end
        rescue Exception => e
          puts "#{e.class.name}: #{e.message}"
          puts "Skipping publisher id (might be bad daily_deal record): #{id}"
        end
      end

      puts "Identifying publishers that have received deals..."
      receiving_publishers = ActiveRecord::Base.connection.select_values("select distinct(publisher_id) from daily_deals where source_id is NOT NULL")
      receiving_publishers.each do |id|
        begin
          pub = Publisher.find(id)
          unless pub.in_syndication_network?
            puts "    Adding #{pub.label} to syndication network"
            pub.update_attribute(:in_syndication_network, true)
          end
        rescue Exception => e
          puts "#{e.class.name}: #{e.message}"
          puts "Skipping publisher id (might be bad daily_deal record): #{id}"
        end
      end
    end
  end

end


