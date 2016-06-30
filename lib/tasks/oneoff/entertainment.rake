namespace :oneoff do
  namespace :entertainment do

    desc "Reassign subscribers that are in the generic entertainment publisher to the one related to its zip code"
    task :reassign_subscribers_from_generic_publisher => :environment  do
      dry_run = ENV['DRY_RUN'].present?
      Jobs::ReassignSubscribersFromGenericPublisherJob.perform dry_run, true
    end

    desc "Change zip code for entertainment subscribers that have zip cod 12345-1234 to 12345."
    task :cut_zip_code => :environment do
      dry_run = ENV['DRY_RUN'].present?

      publishing_group = PublishingGroup.find_by_label("entertainment")

      rzipcode = '^[0-9]{5}\-[0-9]{4}$'
      subs_to_fix = publishing_group.publisher_subscribers.find(:all, :conditions => ["zip_code REGEXP ?", rzipcode])

      total = 0
      subs_to_fix.each do |subscriber|
        new_zip = subscriber.zip_code.slice(0..5)
        subscriber.update_attributes!(:zip_code => new_zip) unless dry_run
        total = total + 1
      end
      puts "Changed #{total} subscribers."
    end

  end
end
