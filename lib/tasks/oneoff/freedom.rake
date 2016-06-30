namespace :oneoff do
  namespace :freedom do

    desc "Combine Freedom customers with duplicate email addresses"
    task :combine_customers_on_email => :environment do
      freedom = PublishingGroup.find_by_label("freedom")
      freedom.combine_duplicate_consumers!
    end

  end
end
