namespace :silverpop do

  desc "Schedule today's Silverpop mailing for PUBLISHER_LABEL if a new featured deal will be active"
  task :schedule_todays_mailing_for_new_featured_deal => :environment do
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    raise "No pubisher with label '#{label}'" unless (publisher = Publisher.find_by_label(label))

    publisher.schedule_todays_silverpop_mailing do |blast_time|
      daily_deal = publisher.daily_deals.featured_at(blast_time).first
      if daily_deal.try(:expected_email_blast_at?, blast_time)
        { :subject => daily_deal.email_blast_subject }
      else
        nil
      end
    end
  end

  desc "Schedule weekly Silverpop mailings for PUBLISHER_LABEL"
  task :schedule_this_weeks_silverpop_mailings => :environment do
    label = ENV['PUBLISHING_GROUP_LABEL']
    if label
      publishers = PublishingGroup.find_by_label!(label).publishers
    else
      label = ENV['PUBLISHER_LABEL']
      publishers = Array.wrap(Publisher.find_by_label!(label)) if label
    end
    raise "Must set either PUBLISHING_GROUP_LABEL or PUBLISHER_LABEL" unless label
    publishers.each do |publisher|
      publisher.schedule_this_weeks_silverpop_mailings
    end
  end

  desc "Migrate per publisher silverpop credentials from yml config to database"
  task :move_entercom_config_to_db => :environment do
    entercom = PublishingGroup.find_by_label("entercomnew")
    raise "Could not find entercom" unless entercom
    entercom.silverpop_api_host = "api5.silverpop.com"
    entercom.silverpop_api_username = "christina.liao@analoganalytics.com"
    entercom.silverpop_api_password = "?XlK54=v"
    entercom.save!
    config = YAML.load_file(Rails.root.join("config", "silverpop.yml"))
    entercom.publishers.each do |publisher|
      puts publisher.label
      if config[publisher.label]
        publisher.silverpop_list_identifier = config[publisher.label]["list_id"]
        publisher.silverpop_template_identifier = config[publisher.label]["template_id"]
        publisher.save!
      else
        puts "Warning: config is missing for #{publisher.label}"
      end
    end
  end

  desc "Synchronize silverpop databases and lists with analog"
  task :audit_and_synchronize_subscribers_and_consumers => :environment do
    publishing_group_label = ENV["PUBLISHING_GROUP_LABEL"]
    raise "PUBLISHING_GROUP_LABEL not specified" if publishing_group_label.blank?
    publishing_group = PublishingGroup.find_by_label!(publishing_group_label)
    audit_size = if ENV["AUDIT_SIZE"] then ENV["AUDIT_SIZE"].to_i else nil end
    audit = !audit_size.nil?
    puts "Will work on the most recently updated #{audit_size} consumers for each publisher for #{publishing_group.label}"
    publishing_group.silverpop.open do |session|
      publishing_group.publishers.each do |publisher|
        publisher.synchronize_with_silverpop!(publishing_group.silverpop, audit, audit_size)
      end
    end
  end

  desc "Synchronize consumers that are also subscribers to remedy impact of bug"
  task :synchronize_users_that_are_also_subscribers => :environment do
    publishing_group_label = ENV["PUBLISHING_GROUP_LABEL"]
    raise "PUBLISHING_GROUP_LABEL not specified" if publishing_group_label.blank?
    publishing_group = PublishingGroup.find_by_label!(publishing_group_label)
    sql = %Q{
      select distinct(users.id) from users
        inner join subscribers on users.email = subscribers.email
        inner join publishers on users.publisher_id = publishers.id
        where users.publisher_id in (select id from publishers where publishing_group_id=#{publishing_group.id}) and
              subscribers.publisher_id in (select id from publishers where publishing_group_id=#{publishing_group.id});
    }
    consumer_ids = ActiveRecord::Base.connection.select_values(sql)
    puts "Will synch #{consumer_ids.size} consumers..."
    publishing_group.silverpop.open do |_unused|
      consumer_ids.each do |consumer_id|
        consumer = Consumer.find(consumer_id)
        puts "    synching #{consumer.email}"
        consumer.synchronize_with_silverpop(publishing_group.silverpop)
      end
    end
  end

  desc "Synchronize consumers that have failed rows"
  task :synchronize_users_that_have_failed_rows => :environment do
    publishing_group_label = ENV["PUBLISHING_GROUP_LABEL"]
    limit = ENV["LIMIT"]
    raise "PUBLISHING_GROUP_LABEL not specified" if publishing_group_label.blank?
    publishing_group = PublishingGroup.find_by_label!(publishing_group_label)
    publishing_group.synchronize_users_that_have_failed_rows(limit)
  end

end
