namespace :oneoff do

  task :remap_entertainment_cities_markets => :environment do |t|
    cities_not_matched = Set.new
    publishers_with_ambigious_cities = Set.new
    entertainment_publishing_group = PublishingGroup.find_by_label("entertainment")
    entertainment_publisher = Publisher.find_by_label("entertainment")
    publisher_map = entertainment_publishing_group.publishers.select {|p| %w{entertainmentdetroit entertainmentdallas entertainmentfortworth entertainmentphoenixeast entertainmenttucson}.include?(p.label) }.group_by {|p| p.city.downcase }
    changed_subscribers = 0
    Subscriber.find_each(:conditions => ["publisher_id = ?", entertainment_publisher.id]) do |subscriber|
      stripped_city = subscriber.city.try(:strip).try(:downcase)
      matching_publishers = publisher_map[stripped_city] || []
      case matching_publishers.size
        when 0
          cities_not_matched << stripped_city
        when 1
          subscriber.publisher = matching_publishers.first
          subscriber.save!
          changed_subscribers += 1
          if changed_subscribers > 0 && (changed_subscribers % 1000 == 0)
            puts "#{changed_subscribers} subscribers changed"
          end
        else
          publishers_with_ambigious_cities << stripped_city
      end
    end
    puts "publishers with ambiguous cities: #{publishers_with_ambigious_cities.inspect}"
    puts "cities not matches: #{cities_not_matched.inspect}"
    puts "#{changed_subscribers} subscribers changed"
  end
end