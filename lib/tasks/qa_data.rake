require File.join(File.dirname(__FILE__), "..", "analog", "qa_data")

namespace :qa_data do
  desc "Create a new advertiser on the publisher with the label provided by PUBLISHER_LABEL"
  task :generate_advertiser do
    label = ENV['PUBLISHER_LABEL']
    raise "Must provide PUBLISHER_LABEL" if label.blank?
    publisher = Publisher.find_by_label(label)
    raise "Could not find publisher with label #{label}" unless publisher

    advertiser = Analog::QaData.generate_advertiser(publisher)
    puts "Generated advertiser for #{label} with ID #{advertiser.id}"
  end

  desc "Create a new store on the advertiser given by ADVERTISER_ID"
  task :generate_store do
    advertiser_id = ENV['ADVERTISER_ID']
    raise "Must provide ADVERTISER_ID" if advertiser_id.blank?
    advertiser = Advertiser.find_by_id(advertiser_id)
    raise "Could not find advertiser with ID #{advertiser}" unless advertiser

    store = Analog::QaData.generate_store(advertiser)
    puts "Generated store with ID #{store.id}"
  end

  desc "Create a new daily deal on the advertiser given by ADVERTISER_ID"
  task :generate_daily_deal do
    advertiser_id = ENV['ADVERTISER_ID']
    raise "Must provide ADVERTISER_ID" if advertiser_id.blank?
    advertiser = Advertiser.find_by_id(advertiser_id)
    raise "Could not find advertiser with ID #{advertiser}" unless advertiser

    daily_deal = Analog::QaData.generate_daily_deal(advertiser, :featured => ENV['FEATURED'] || false)
    puts "Generated daily deal with ID #{daily_deal.id}.  View at: http://localhost:3000/daily_deals/#{daily_deal.id}"
  end

  desc "Create a new advertiser with 3 deals"
  task :generate_advertiser_and_deals do
    label = ENV['PUBLISHER_LABEL']
    raise "Must provide PUBLISHER_LABEL" if label.blank?
    publisher = Publisher.find_by_label(label)
    raise "Could not find publisher with label #{label}" unless publisher

    advertiser = Analog::QaData.generate_advertiser(publisher)
    puts "Generated advertiser for #{label} with ID #{advertiser.id}"

    3.times do |i|
      store = Analog::QaData.generate_store(advertiser)
      puts "Generated store with ID #{store.id}"
    end

    skip_featured = publisher.daily_deals.featured.any?{|dd| dd.start_at <= Time.now && dd.hide_at >= Time.now }
    start_at = 1.day.ago
    3.times do |i|
      daily_deal = Analog::QaData.generate_daily_deal(advertiser, :featured => (i == 0 && !skip_featured), :start_at => start_at)
      puts "Generated daily deal with ID #{daily_deal.id}.  View at: http://localhost:3000/daily_deals/#{daily_deal.id}"
    end
  end
end
