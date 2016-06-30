namespace :deliver do
  desc "Email the latest batch of subscriber signups to their publishers. Use DAYS to override publisher's default report interval"
  task :subscribers => :environment do

    interval = nil
    if ENV["DAYS"].present?
      interval = ENV["DAYS"].to_i.days
    end 
    
    # if only is supplied, then only those publisher labels (separated by commas)
    # will be emailed their recent subscribers.  if except is supplied, then all the
    # matching publisher labels will NOT be emailed their recent subscribers. This 
    # allows us to setup different time of delivers for different publishers.
    only    = ENV["ONLY"] 
    except  = ENV["EXCEPT"] unless only.present? # we don't want both to be supplied, that would be confusing.
    
    Subscriber.deliver_latest({:custom_interval => interval, :only => only, :except => except}).each do |result|
      RAILS_DEFAULT_LOGGER.info( result )
    end
  end
  
  desc "Email current advertisers, coupons and categories to PUBLISHER_LABEL"
  task :advertisers_categories => :environment do
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    Publisher.find_by_label!(label).deliver_advertisers_categories
  end
end
