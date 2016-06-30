namespace :oneoff do

  desc "clean up kowabunga markets by removing states from the names"
  task :rename_kowabunga_markets do

    publisher = Publisher.find_by_label("kowabunga")
    raise "Kowabunga publisher not found" if publisher.nil?

    puts "Cleaning up Kowabunga markets"

    publisher.markets.each do |market|
      if comma_index = market.name.index(",")
        puts "Removing state from #{market.name}"
        market.update_attribute(:name, market.name[0...comma_index])
      else
        puts "#{market.name} does not include a comma. Nothing to do."
      end
    end

    puts "Done."
  end
end