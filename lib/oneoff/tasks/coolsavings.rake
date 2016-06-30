namespace :oneoff do
  namespace :coolsavings do

    desc "Send all coolsavings customers to coolsavings"
    task :export_to_coolsavings => :environment do
      Export::Coolsavings.new.export_all_consumers
    end

    desc "Combine coolsavings customers with duplicate email addresses"
    task :combine_customers_on_email => :environment do
      coolsavings = PublishingGroup.find_by_label("qinteractive")
      coolsavings.combine_duplicate_consumers!
    end

  end
end
