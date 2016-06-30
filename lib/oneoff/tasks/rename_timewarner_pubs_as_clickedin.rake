namespace :oneoff do
  desc "rename timewarner publications to clicked in"
  task :rename_timewarner_pubs_as_clickedin do
    twc_publishing_group = PublishingGroup.find_by_label("rr")
    if twc_publishing_group
      twc_publishing_group.publishers.each do |p|
        p.update_attribute(:name, p.name.gsub("Time Warner Cable - ", "ClickedIn - "))
        p.update_attribute(:label, p.label.gsub("timewarnercable-", "clickedin-"))
      end
    end
  end
end