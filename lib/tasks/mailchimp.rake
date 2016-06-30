def print_mailchimp_result(result)
  num_errors = result[:errors].size
  puts "Added: #{result[:added]}. Updated: #{result[:updated]}. Errors: #{num_errors}"
  if num_errors > 0
    puts "\nError messages:"
    result[:errors].each { |e| puts e }
  end
end

def print_mailchimp_list_info(mailchimp_lists)
  mailchimp_lists.each do |mailchimp_list|
    puts "\n"
    puts "*" * 72
    puts <<MC_LIST
List Name: #{mailchimp_list.name}
ID for API Calls: #{mailchimp_list.id}
Created: #{mailchimp_list.date_created}
Default From Name: #{mailchimp_list.default_from_name}
Default From Email: #{mailchimp_list.default_from_email}
Default Subject: #{mailchimp_list.default_subject}
Member Count: #{mailchimp_list.member_count}
MC_LIST
    puts "*" * 72
  end

end

namespace :mailchimp do
  desc "Return information about a MailChimp list (useful for determining ID to use in API calls)"
  task :list, [:list_name] => :environment do |t, args|
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    raise "No pubisher with label '#{label}'" unless (publisher = Publisher.find_by_label(label))
    
    mc_lists = publisher.mailchimp_lists_by_name(args[:list_name])
    print_mailchimp_list_info(mc_lists)
  end 
  
  namespace :subscribers do
    desc "Update an existing MailChimp list with ALL subscribers for the publisher specified by PUBLISHER_LABEL"
    task :init => :environment do
      raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
      raise "No pubisher with label '#{label}'" unless (publisher = Publisher.find_by_label(label))
      
      publisher.update_mailchimp_list
    end
    
    desc "Update an existing MailChimp list for the publisher specified by PUBLISHER_LABEL going back DAYS number of days"
    task :update => :environment do
      raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
      raise "No pubisher with label '#{label}'" unless (publisher = Publisher.find_by_label(label))
      raise "Must set DAYS to an integer > 0" unless (num_days = ENV['DAYS'].to_i) > 0
      
      publisher.update_mailchimp_list :period => num_days.days
    end    
  end
end