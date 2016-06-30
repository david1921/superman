namespace :markets do

  desc "Remove market"
  task :remove_market do
    unless label = ENV['PUBLISHER_LABEL'] then raise "Must set PUBLISHER_LABEL" end
    unless market_name = ENV['MARKET_NAME'] then raise "Must set MARKET_NAME" end
    unless publisher = Publisher.find_by_label(label) then raise "Can't find pubisher with label '#{label}'" end
    unless market = Market.find_by_publisher_id_and_name(publisher.id, market_name) then raise "Can't find market for publisher with name '#{market_name}'" end

    DailyDeal.transaction do
      DailyDeal.in_market(market).each do |daily_deal|
        puts "Handling deal with id #{daily_deal.id}"
        puts "  - Current markets: #{daily_deal.markets}"
        puts "  - Removing market associations"
        daily_deal.markets.delete(market)
        puts "  - Deal left with markets: #{daily_deal.markets}"
      end

      puts "Removing #{market.market_zip_codes.size} market zip codes"
      market.market_zip_codes.destroy_all

      puts "Removing actual market"
      market.destroy
    end
  end
end
