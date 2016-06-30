namespace :oneoff do
  namespace :bespoke do
    desc "Create new categories"
    task :create_categories => :environment do

      dry_run = ENV['DRY_RUN'].present?

      categories = ["clothing & accessories", "driving", "electronics", "entertainment", "experiences & days out", "food & drink", "health & beauty", "home, garden & DIY", "office & business", "other services", "shopping", "travel", "utilities"]
      publishing_group = PublishingGroup.find_by_label("bespoke")
      publisher_labels = ['bespoke-february', 'bespoke-october']

      publisher_labels.each do  |label|
        publisher = publishing_group.publishers.find_by_label(label)
        categories.each do |cat_name|
          unless publishing_group.daily_deal_categories.find_by_name(cat_name)
            if dry_run
              if publishing_group.daily_deal_categories.new(:name => cat_name, :publisher => publisher).valid?
                puts "DRY_RUN: New category #{cat_name}"
              else
                puts "DRY_RUN: #{cat_name} not valid."
              end
            else
              publishing_group.daily_deal_categories.new(:name => cat_name, :publisher => publisher).save
            end
          end
        end
      end

    end #task
  end
end
