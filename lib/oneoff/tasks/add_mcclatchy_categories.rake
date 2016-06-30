
namespace :oneoff do
  task :add_mcclatchy_categories do
    require File.join(File.dirname(__FILE__), "data", "mcclatchy_categories.rb")

    publishing_group = PublishingGroup.find_by_label('mcclatchy')

    categories = Analog::OneOffs::MCCLATCHY_CATAGORIES

    Category.transaction do
      categories.each_pair do |category_name, subcategories|
        subcategories.each do |subcategory_name|
          match_found = false

          category = nil
          subcategory = nil

          matches = Category.find_all_by_name(subcategory_name)
          matches.each do |match|
            if match.parent and match.parent.name == category_name
              match_found = true
              category = match.parent
              subcategory = match
              puts "Found full category: #{category_name}:#{subcategory_name}"
              break
            end
          end

          unless match_found
            match = Category.first(:conditions => {:parent_id => nil, :name => category_name})

            if match
              match_found = true
              category = match
              subcategory = Category.create(:parent => match, :name => subcategory_name)
              puts "Created subcategory: #{subcategory_name}"
            end
          end

          unless match_found
            category = Category.create(:name => category_name)
            subcategory = Category.create(:parent => match, :name => subcategory_name)
            puts "Created full category: #{category_name}:#{subcategory_name}"
          end

          unless publishing_group.categories.find_by_id(category.id)
            publishing_group.categories << category
          end

          unless publishing_group.categories.find_by_id(subcategory.id)
            publishing_group.categories << subcategory
          end
        end
      end
    end
  end
end
