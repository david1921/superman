require 'rake'
namespace :categories do

  desc "Get a csv of all the categories under a PG"
  task :generate_csv_of_all, [:publishing_group] => :environment do |task, args|
    args.with_defaults(:publishing_group => ENV['PG'])
    
    pg = (args.publishing_group.present?) ? PublishingGroup.find_by_label(args.publishing_group.to_s) : nil 

    file_name = pg.label << '-categories-' << Time.now.localtime.strftime("%Y%m%d-%H%M%S") << ".csv"
    file_path = File.expand_path(file_name, File.expand_path("tmp", Rails.root))
    
    puts "Outputing batch to #{file_path}"
    
    header = ["Category ID", "Name", "Label"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      pg.available_categories.each do |c|
        csv << [c.id, c.name, c.label]
      end
    end
    
  end

end