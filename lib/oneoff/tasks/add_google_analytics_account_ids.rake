namespace :oneoff do
  task :add_google_analytics_account_ids do
    data = File.read(File.expand_path("lib/oneoff/tasks/data/google_analytics_account_ids.json", RAILS_ROOT))
    json = JSON.parse(data)
    json["pub_accounts"].each_pair do |label, ids|
      publisher = Publisher.find_by_label(label)
      publisher.update_attribute(:google_analytics_account_ids, ids.join(", ")) if publisher
    end
    json["group_accounts"].each_pair do |label, ids|
      group = PublishingGroup.find_by_label(label)
      group.update_attribute(:google_analytics_account_ids, ids.join(", ")) if group
    end
  end
end