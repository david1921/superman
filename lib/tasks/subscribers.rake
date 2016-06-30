namespace :subscribers do
  desc "Import a list of subscriber email addresses from SUBSCRIBERS_FILE for PUBLISHER_LABEL"
  task :import => :environment do
    unless label = ENV['PUBLISHER_LABEL'] then raise "Must set PUBLISHER_LABEL" end
    unless publisher = Publisher.find_by_label(label) then raise "Can't find pubisher with label '#{label}'" end
    unless subscribers_filename = ENV['SUBSCRIBERS_FILE'] then raise "Must set SUBSCRIBERS_FILE" end
    
    if File.extname(subscribers_filename) == '.csv'
      puts "Importing from CSV"
      result = publisher.import_subscriber_emails_from_csv(subscribers_filename,
                                                           :ignore_invalid_zip_codes => ENV['IGNORE_INALID_ZIP_CODES'])
    else
      result = publisher.import_subscriber_emails_from_file(subscribers_filename)
    end

    if result[:errors].present?
      puts "Failed to import #{result[:errors].length} emails: #{result[:errors].join(', ')}"
    end
    puts "Successfully imported #{result[:num_added]} subscribers for #{label}"
  end
end
