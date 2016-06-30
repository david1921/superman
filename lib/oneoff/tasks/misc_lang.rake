namespace :oneoff do

  task :create_lang_email_files => :environment do
    all_emails = Set.new
    tmp_dir = File.expand_path("tmp", Rails.root)
    PublishingGroup.find_by_label("lang").publishers.each do |publisher|
      emails_this_publisher = Set.new
      emails_this_publisher += publisher.consumers.map(&:email)
      emails_this_publisher += publisher.subscribers.map(&:email)
      all_emails += emails_this_publisher
      File.open(File.expand_path("lang-#{publisher.label}-emails.txt", tmp_dir), "w") do |file|
        emails_this_publisher.each do |email|
          file << "#{email}\n"
        end
      end
    end
    File.open(File.expand_path("lang-all-emails.txt", tmp_dir), "w") do |file|
      all_emails.each do |email|
        file << "#{email}\n"
      end
    end
  end

  task :summarize_subscribers_consumers_purchases_for_lang => :environment do
    tmp_dir = File.expand_path("tmp", Rails.root)
    File.open(File.expand_path("lang-signups-purchases-summary.csv", tmp_dir), "w") do |file|
      file << "publisher_label, subscribers, consumers, total_purchases\n"
      PublishingGroup.find_by_label("lang").publishers.each do |publisher|
        total_purchases = publisher.consumers.inject(0) { |sum, consumer| sum + consumer.daily_deal_purchases.count }
        file << "#{publisher.label}, #{publisher.subscribers.count}, #{publisher.consumers.count}, #{total_purchases}\n"
      end
    end
  end

end