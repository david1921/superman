namespace :oneoff do

  namespace :cyd do
    desc "Set flag to trigger POST to CYD during consumer registration"
    task :set_notify_third_parties_of_consumer_creation do
      publishing_group = PublishingGroup.find_by_label("cyd")
      raise "CYD publishing group not found" if publishing_group.nil?
      publishing_group.update_attribute("notify_third_parties_of_consumer_creation", true)
      puts "Done"
    end
  end
  
end
