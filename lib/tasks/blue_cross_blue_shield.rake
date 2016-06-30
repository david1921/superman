namespace :blue_cross_blue_shield do

  desc "Import plans and prefixes from file.  Requires PUBLISHING_GROUP_LABEL and FILE"
  task :import_plans_and_prefixes => :environment do
    publishing_group_label = ENV["PUBLISHING_GROUP_LABEL"]
    file = ENV["FILE"]
    dry_run = ENV["DRY_RUN"]

    raise "FILE not specified" if file.blank?
    raise "PUBLISHING_GROUP_LABEL not specified" if publishing_group_label.blank?

    publishing_group = PublishingGroup.find_by_label(publishing_group_label)

    raise "Could not find publishing group with label '#{publishing_group_label}'" if publishing_group.blank?

    puts "** DRY RUN!  Import will not be saved! ** " if dry_run

    importer = BlueCrossBlueShield::PlanImporter.new(file, publishing_group, :dry_run => dry_run)

    importer.import

    if importer.errors.present?
      puts "There were errors during import: \n\t#{importer.errors.join("\n\t")}"
      puts "Import rolled back!"
    else
      puts "Import completed without errors: #{importer.publishers.size} plan(s) were updated or created."
    end
  end
  
  desc "Output a listing of Publishers <=> Memberships codes to csv for bcbsa publishers."
  task :output_alpha_prefix_to_csv => :environment do
    publishing_group_label = ENV["PUBLISHING_GROUP_LABEL"] || "bcbsa"
    file_path = unique_file_path ('bcbsa_alpha_prefix')
    
    publishing_group = PublishingGroup.find_by_label(publishing_group_label)
    
    header = ["Publisher", "Publisher Label", "Alpha Prefix"]
    FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
      csv << header
      publishing_group.publishers.each do |p|
        p.publisher_membership_codes.each do |c|
          csv << [p.name,p.label,c.code]
        end
      end
    end

  end
  def unique_file_path(name = 'EXPORT', ext = ".csv")  
    file_name = name << '-' << Time.now.localtime.strftime("%Y%m%d-%H%M%S") << ext
    File.expand_path(file_name, File.expand_path("tmp", Rails.root))
  end

end
