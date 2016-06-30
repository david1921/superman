class PublishingGroupsMailer < ActionMailer::Base   

  default_url_options[:host] = AppConfig.admin_host || "admin.analoganalytics.com"

  def consumer_counts(publishing_group, csv_options = {})
    raise ArgumentError, "Publishing group has no consumer_recipients" if publishing_group.consumer_recipients.blank?

    recipients   publishing_group.consumer_recipients
    from         "Analog Analytics <support@analoganalytics.com>"
    subject      "#{publishing_group.name.titleize} Signup Counts"
    sent_on      Time.now
    content_type "multipart/mixed"

    part :content_type => 'multipart/alternative' do |copy|
      copy.part :content_type => 'text/plain' do |p|
        p.body = "Please see the attached comma-delimited file."
      end
    end
    
    filename = "consumer-counts-#{Time.zone.now.strftime("%Y-%m-%d")}.csv"
    attachment :filename => filename, :content_type => "text/csv" do |a|
      a.body = FasterCSV.generate do |csv|
        csv << ["Publisher", "Signup Count"]
        publishing_group.generate_consumers_totals_list(csv, csv_options)
      end
    end

  end

  def latest_consumers_and_subscribers(publishing_group, filepath)
    raise ArgumentError, "Publishing group has no consumer_recipients" if publishing_group.consumer_recipients.blank?

    recipients   publishing_group.consumer_recipients
    from         "Analog Analytics <support@analoganalytics.com>"
    subject      "#{publishing_group.name.titleize} Sign Ups"
    sent_on      Time.now
    content_type "multipart/mixed"

    part :content_type => 'multipart/alternative' do |copy|
      copy.part :content_type => 'text/plain' do |p|
        p.body = "Please see the attached comma-delimited file."
      end
    end
    
    filename = File.basename(filepath)
    attachment :filename => filename, :content_type => "text/csv", :body => File.read(filepath)
  end

end
