namespace :oneoff do
  task :move_merchant_acount_ids_to_db_from_config do
    publishers        = Publisher.all
    publishing_groups = PublishingGroup.all

    c = 0
    publishing_groups.each do |group|
      if group.merchant_account_id.nil?
        file = File.join(Rails.root, "config/themes/#{group.label}/merchant_account_ids.yml")
        if File.exists?(file)
          c += 1
          data = YAML::load(ERB.new(File.read(file)).result)
          if merch_id = data["braintree"]
            group.merchant_account_id = merch_id
            if group.save
              puts "Updated Publishing Group #{group.label}"
            end
          end
        end
      end
    end
    puts "Updated #{c} records"

    c = 0
    publishers.each do |publisher|
      if publisher.read_attribute(:merchant_account_id).nil? # Because migration/rake deployed before code change, and method already exists with same name, but gets id from yml file
        file = File.join(Rails.root, "config/themes/#{publisher.label}/merchant_account_ids.yml")
        pg = publisher.publishing_group
        unless pg.try(:merchant_account_id)
          if File.exists?(file)
            c += 1
            data = YAML::load(ERB.new(File.read(file)).result)
            if merch_id = data["braintree"]
              publisher.merchant_account_id = merch_id
              if publisher.save
                puts "Updated Publisher #{publisher.label}"
              end
            end
          end
        end
      end
    end
    puts "Updated #{c} records"

  end
end
