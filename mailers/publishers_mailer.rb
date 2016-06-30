class PublishersMailer < ActionMailer::Base   

  default_url_options[:host] = AppConfig.admin_host || "admin.analoganalytics.com"
  
  def coupon_changed(publisher, coupon)
    recipients publisher.approval_email_address
    from       "Analog Analytics <support@analoganalytics.com>"
    subject    "Coupon #{coupon.id} Changed or Added for #{coupon.advertiser.name}"
    body       :offer_url => edit_offer_url(coupon)
  end
  
  #
  # ActionMailer doesn't perform implicit template rendering (e.g. of latest.text.plain.erb) when attachments are present
  #
  def latest_subscribers(publisher, subscribers)
    recipients    publisher.subscriber_recipients
    from          "Analog Analytics <support@analoganalytics.com>"
    subject       "#{publisher.name.titleize} Coupon Subscribers"
    sent_on       Time.now
    content_type  "multipart/mixed"

    # TODO: need to load publisher_mailer config
    config = YAML.load_file(File.expand_path("config/publisher_mailer.yml", Rails.root))    
    if config && config[publisher.label]
      columns = config[publisher.label]['columns']
      include_in_email = config[publisher.label]['include_in_email']
      include_all_subscribers = config[publisher.label]['include_all_subscribers']
      locations = (config[publisher.label]['other_options']||{})['locations']
      date_format = config[publisher.label]['dateformat']
    end
    columns ||= %w( email mobile_number created_at categories other_options )

    if include_all_subscribers
      RAILS_DEFAULT_LOGGER.info("[SUBSCRIBERS] loading all subscribers for #{publisher.name}")
      subscribers = publisher.subscribers 
    end
    
    report = FasterCSV.generate do |csv|
      csv << columns.collect(&:titleize)

      subscribers.each do |subscriber| 
        entry = []
        columns.each do |column|
          case column
          when 'categories'
            entry << subscriber.categories.map { |cat| cat.name.to_s.to_latin_1 }.sort.join(",")
          when 'other_options'
            entry << (subscriber.other_options || []).map { |opt| opt.to_s.to_latin_1 }.sort.join(",")
          when 'created_at'
            unless date_format.present?
              entry << subscriber.created_at.to_s(:db)
            else
              entry << subscriber.created_at.to_s( date_format.to_sym )
            end
          when 'affiliate'
            entry << (subscriber.subscriber_referrer_code.present? ? subscriber.subscriber_referrer_code.code : "" )
          when 'city_state'
            entry << (subscriber.other_options||{})[column]
          else  
            if locations
              if locations.is_a?(Array) && locations.include?( column )
                opts = subscriber.other_options || {}
                if opts.key?('locations')
                  val = (opts['locations']||{})[column]
                  entry << (val.present? && val == '1' ? "yes" : "no")
                elsif opts.key?('city')
                  entry << (opts['city'] == column ? "yes" : "no")
                else
                end
              end
            end
            
            entry << subscriber.send(column.to_sym).to_s.to_latin_1 if subscriber.respond_to?(column.to_sym)
          end
        end  
        csv << entry
      end
    end

    part :content_type => 'multipart/alternative' do |copy|
      copy.part :content_type => 'text/plain' do |p|
        if include_in_email
          p.body = report
        else
          p.body = "Please see the attached comma-delimited file."
        end
      end
    end
            
    filename = "subscribers-#{Time.zone.now.strftime("%Y-%m-%d")}.csv"
    attachment :filename => filename, :content_type => "text/csv" do |a|
      a.body = report
    end
  end
  
  def latest_consumers_and_subscribers(publisher, filepath)
    recipients    publisher.subscriber_recipients
    from          "Analog Analytics <support@analoganalytics.com>"
    subject       "#{publisher.name.titleize} Signups"
    sent_on       Time.now
    content_type  "multipart/mixed"

    part :content_type => 'multipart/alternative' do |copy|
      copy.part :content_type => 'text/plain' do |p|
        p.body = "Please see the attached comma-delimited file."
      end
    end
                
    filename = File.basename(filepath)
    attachment :filename => filename, :content_type => "text/csv", :body => File.read(filepath)
  end
  
  def advertisers_categories(publisher)
    recipients   publisher.categories_recipients
    from         "Analog Analytics <support@analoganalytics.com>"
    subject      "#{publisher.name.titleize} Advertiser Categories"
    sent_on      Time.now
    content_type "multipart/mixed"

    part :content_type => 'multipart/alternative' do |copy|
      copy.part :content_type => 'text/plain' do |p|
        p.body = "Please see the attached comma-delimited file."
      end
    end
    
    filename = "advertisers-categories-#{Time.zone.now.strftime("%Y-%m-%d")}.csv"
    attachment :filename => filename, :content_type => "text/csv" do |a|
      a.body = FasterCSV.generate :col_sep => "\t" do |csv|
        csv << [ "Advertiser", "Coupon", "Categories" ]
        publisher.advertisers.each do |advertiser|
          advertiser.offers.each do |offer|
            offer.categories(true)
            csv << [ advertiser.name.to_latin_1, offer.message.to_latin_1, offer.category_names.to_latin_1 ]
          end
        end
      end
    end
  end

  def support_contact_request(publisher, request)
    recipients publisher.support_email_address
    from       "Analog Analytics <support@analoganalytics.com>"
    subject    request.email_subject || "Support Request from #{request.first_name} #{request.last_name}"
    sent_on    Time.now
    body       :publisher => publisher, :contact_request => request
  end

  def sales_contact_request(publisher, request)
    recipients publisher.sales_email_address
    from       "Analog Analytics <support@analoganalytics.com>"
    subject    "Sales Request from #{request.first_name} #{request.last_name}"
    sent_on    Time.now
    body       :publisher => publisher, :contact_request => request
  end

  def business_contact_request(publisher, request)
    recipients publisher.support_email_address
    from       "Analog Analytics <support@analoganalytics.com>"
    subject    "Business Request from #{request.first_name} #{request.last_name}"
    sent_on    Time.now
    body       :publisher => publisher, :contact_request => request
  end

  def suggested_daily_deal(publisher, suggested_daily_deal)
    recipients publisher.suggested_daily_deal_email_address
    from       "Analog Analytics <support@analoganalytics.com>"
    subject    "Suggested Deal from #{suggested_daily_deal.consumer.name}"
    sent_on    Time.now
    body       :publisher => publisher, :suggested_daily_deal => suggested_daily_deal
  end

  def daily_deal_sold_out_notification(daily_deal)
    recipients daily_deal.publisher.notification_email_address
    from       "Analog Analytics <support@analoganalytics.com>"
    subject    "Daily Deal Sold Out! (#{daily_deal.id})"
    sent_on    Time.now
    body       :publisher => daily_deal.publisher, :daily_deal => daily_deal
  end
end
