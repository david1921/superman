namespace :oneoff do
  namespace :fundogo do
    desc "Create new categories"
    task :create_categories => :environment do

      dry_run = ENV['DRY_RUN'].present?
      categories = ["Buy","Do","Eat","Go","Help","Pamper","See"]
      publishing_group = PublishingGroup.find_by_label("fundogo")
        categories.each do |cat_name|
          unless publishing_group.daily_deal_categories.find_by_name(cat_name)
            if dry_run
              if publishing_group.daily_deal_categories.new(:name => cat_name, :publishing_group => publishing_group).valid?
                puts "DRY_RUN: New category #{cat_name}"
              else
                puts "DRY_RUN: #{cat_name} not valid."
              end
            else
              publishing_group.daily_deal_categories.new(:name => cat_name, :publishing_group => publishing_group).save
            end
          end
        end

    end #task
  end
end