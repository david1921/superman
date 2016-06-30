namespace :oneoff do
  namespace :bcbsa do

    desc "Synchronize silverpop after consumer creation"
    task :turn_on_sync_with_silverpop do
      bcbsa = PublishingGroup.find_by_label('bcbsa')
      raise "Could not find bcbsa" unless bcbsa
      unless bcbsa.silverpop_database_identifier.present?
        puts "WARNING: synching will not occur until silverpop_database_identifier is present"
      end
      bcbsa.consumer_after_create_strategy = "add_to_silverpop"
      bcbsa.consumer_after_update_strategy = "update_silverpop"
      bcbsa.save!
      puts "sync with silverpop turned on for bcbsa"
    end

    desc "update allow_consumer_show_action to true on publishing group"
    task :update_allow_consumer_show_action_to_true_on_publishing_group => :environment do
      pg = PublishingGroup.find_by_label("bcbsa")
      pg.update_attribute(:allow_consumer_show_action, true) if pg
    end

  end
end
