namespace :oneoff do
  namespace :coupons do

    desc "fix data issue from pt-27050021"
    task :fix_offers_without_placements => :environment do
      offers = Offer.find_by_sql <<-sql
        select o.* from offers o
        left join placements p on p.`offer_id` = o.id
        join advertisers a on o.`advertiser_id` = a.id
        join publishers pub on pub.id = a.`publisher_id`
        where p.id is NULL and o.`show_on` < now() and o.`expires_on` > now()
      sql
      offers.each(&:save!) # fires the set_placement callback which creates a placement and fixes the data issue.
    end

    desc "set publishers.allow_offers for pubs with advertisers that have offers"
    task :set_allow_offers => :environment do
      publisher_ids_with_offers = Advertiser.connection.select_values <<-sql
        SELECT DISTINCT(p.id) FROM publishers p
        JOIN advertisers a ON a.publisher_id = p.id
        INNER JOIN offers o ON o.advertiser_id = a.id
        WHERE p.allow_offers != 1
      sql

      if publisher_ids_with_offers.present?
        if ENV['DOIT'].present?
          Advertiser.connection.execute "UPDATE publishers SET allow_offers = 1 WHERE id IN (#{publisher_ids_with_offers.join(',')})"
          puts "Set publishers.allow_offers for #{publisher_ids_with_offers.count} publishers"
        else
          puts "TESTING: Set publishers.allow_offers for #{publisher_ids_with_offers.count} publishers: #{Publisher.find(publisher_ids_with_offers).map(&:name).sort.join("\n\t")}"
          puts "Set ENV['DOIT'] to actually perform the update."
        end
      else
        puts "No publishers found (that should have :allow_offers => true)"
      end

    end
  end
end
