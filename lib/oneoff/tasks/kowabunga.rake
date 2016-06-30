namespace :oneoff do

  namespace :kowabunga do

    desc "Cleanup duplicate markets on deals"
    task :cleanup_markets do

      publisher = Publisher.find_by_label("kowabunga")
      raise "Kowabunga publisher not found" if publisher.nil?

      puts "Cleaning up Kowabunga markets"
      daily_deals = publisher.daily_deals
      puts " - Going through #{daily_deals.size} deals"

      daily_deals.each do |daily_deal|
        market_count = daily_deal.markets.size

        if market_count > 1
          puts " - Multiple markets found (#{market_count}) on daily deal #{daily_deal.id}"
          puts " - Removing duplicates"

          market = daily_deal.markets.first
          daily_deal.markets.clear
          daily_deal.markets << market
        end
      end

      puts "Done"
    end

    desc "Clean up deals"
    task :cleanup_deals do

      puts "Running kowabunga deal cleanup"
      DailyDeal.transaction do
        publisher = Publisher.find_by_label("kowabunga")
        raise "Kowabunga publisher not found" if publisher.nil?

        deal_listings = ["1719", "1727", "2073", "2117", "2281", "2367", "2369", "2381", "2411", "2413", "2417", "2419", "2427", "2429", "2439", "2441", "2445", "2447", "2453", "2457", "2459", "2463", "2465", "2469", "2473", "2475", "2479", "2485", "2489", "2493", "2495", "2501", "2509", "2511", "2513", "2519", "2523", "2527", "2531", "2543", "2547", "2553", "2555", "2557", "2561", "2563", "2567", "2577", "2581", "2587", "2595", "2597", "2601", "2603", "2607", "2609", "2623", "2625", "2627", "2639", "2641", "2645", "23115", "114271", "167445", "83393", "83395", "83397", "83399", "83401", "83403", "83405", "83407", "83409", "86173", "86175", "86177"]

        puts "Passed #{deal_listings.size} deal listings"
        deals = DailyDeal.find(:all, :conditions => ["publisher_id = ? AND listing IN(?)", publisher.id, deal_listings])
        puts "Soft deleting #{deals.size} deals"
        
        deals.each do |deal|
          deal.delete!
        end
      end

      puts "Done"
    end
    
    desc "update google analytics account ids for markets"
    task :update_google => :environment do
      KOWABUNGA_ACT_IDS = [["Albequerque","UA-24690621-2"], ["Atlanta","UA-24690621-3"], ["Austin","UA-24690621-4"], ["Baltimore","UA-24690621-5"], ["Birmingham","UA-24690621-6"], ["Boston","UA-24690621-7"], ["Buffalo","UA-24690621-8"], ["Charlotte","UA-24690621-9"], ["Chicago","UA-24690621-10"], ["Cincinnati","UA-24690621-11"], ["Cleveland","UA-24690621-12"], ["Columbus","UA-24690621-13"], ["Dallas","UA-24690621-14"], ["Denver","UA-24690621-15"], ["Detroit","UA-24690621-16"], ["Grand Rapids","UA-24690621-17"], ["Greensboro","UA-24690621-18"], ["Greensboro-High Point-Winston Salem","UA-24690351-7"], ["Greenville","UA-24690621-19"], ["Harrisburg","UA-24690621-20"], ["Hartford","UA-24690621-21"], ["Houston","UA-24690621-22"], ["Indianapolis","UA-24690621-23"], ["Kansas City","UA-24690621-24"], ["Las Vegas","UA-24690621-26"], ["Los Angeles","UA-24690621-27"], ["Louisville","UA-24690621-28"], ["Memphis","UA-24690621-29"], ["Miami","UA-24690621-30"], ["Milwaukee","UA-24690621-31"], ["Minneapolis","UA-24690621-32"], ["Nashville","UA-24690621-33"], ["National","UA-24690621-25"], ["New Orleans","UA-24690621-34"], ["New York","UA-24690621-35"], ["Norfolk","UA-24690621-36"], ["Oklahoma City","UA-24690621-37"], ["Orlando","UA-24690621-38"], ["Philadelphia","UA-24690621-39"], ["Phoenix","UA-24690621-40"], ["Pittsburgh","UA-24690621-41"], ["Portland","UA-24690621-42"], ["Raleigh","UA-24690621-43"], ["Sacramento","UA-24690621-44"], ["Salt Lake City","UA-24690621-45"], ["San Antonio","UA-24690621-46"], ["San Diego","UA-24690621-47"], ["San Francisco","UA-24690621-48"], ["San Jose","UA-24690621-49"], ["Seattle","UA-24690351-2"], ["St. Louis","UA-24690351-3"], ["Tampa","UA-24690351-4"], ["Washington","UA-24690351-5"], ["West Palm Beach","UA-24690351-6"]]

      publisher = Publisher.find_by_label("kowabunga", :include => :markets)
      raise "Kowabunga publisher not found" if publisher.nil?

      publisher.markets.each do |market|
        mk = KOWABUNGA_ACT_IDS.find { |s| s.first.downcase == market.name.downcase}
        if market.name != "other" && mk.present?
          market.google_analytics_account_ids = mk[1]
		      p "#{mk[0]} saved as #{mk[1]}"
          market.save
        end
      end
    end # end task
    
  end
end
