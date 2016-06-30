module Report::PublishingGroup
  def daily_deals
    publishers.collect { |p| p.daily_deals }.flatten
  end

  def todays_deals
    publishers.select(&:launched?).collect { |p| p.daily_deals.todays }.flatten
  end

  def todays_deals_by_city
    todays_deals.reject {|deal| deal.publisher.city.blank? }.group_by { |deal| deal.publisher.city.strip }
  end

  def todays_deals_by_publisher_label
    todays_deals.group_by { |deal| deal.publisher.label }
  end
  
  def signups
    all_signups = []
    emails = Set.new
    publishers.each do |publisher|
      publisher.signups.each do |signup|
        all_signups << signup unless emails.include?(signup["email"])
        emails << signup["email"]
      end
    end
    all_signups
  end

  def signups_for_cities(cities)
    subscribers = [].tap do |array|
      publishers.each do |publisher|
        publisher.subscribers.find_in_batches do |batch|
          array.concat batch.select { |subscriber| cities.include?(subscriber.city.to_s.strip) }
        end
      end
    end
    consumers = [].tap do |array|
      publishers.select { |publisher| cities.include?(publisher.city.to_s.strip) }.each do |publisher|
        array.concat publisher.consumers.active
      end
    end
    first_attribute_present = lambda do |signups, attr|
      signups.detect { |signup| signup.respond_to?(attr) && signup.send(attr).present? }.try(attr).to_s.strip
    end

    [].tap do |array|
      (consumers + subscribers).group_by { |signup| signup.email.strip }.delete_if { |email, _| email.blank? }.each do |email, signups|
        array << {
          :email => email,
          :zip_code => first_attribute_present.call(signups, :zip_code),
          :first_name => first_attribute_present.call(signups, :first_name),
          :city => first_attribute_present.call(signups, :city),
          :state => first_attribute_present.call(signups, :state)
        }
      end
    end
  end

  def generate_consumers_list_lang_style(csv, opts = {})
    opts[:include_publisher_bitmap] = true
    opts[:column_title_map] = {
        "email" => "Email",
        "first_name" => "First Name",
        "last_name" => "Last Name",
    }
    opts[:columns] = ["first_name", "last_name", "email"]
    generate_consumers_list(csv, opts)
  end

  def generate_consumers_list(csv, opts = {})
    options = {
        :publisher_labels => publishers.map { |p| p.label },
        :columns =>  %w{ status email name subject },
        :allow_duplicates => false,
        :column_title_map => nil,
        :interval_in_hours => nil,
        :include_header => true,
        :include_publisher_bitmap => false
    }.merge(opts) {| key, old, new | new.nil? ? old : new }

    if !options[:allow_duplicates] && !options[:columns].include?("email")
      raise ArgumentError, "If duplicates are not allowed, \"email\" needs to be included in :columns option"
    end

    # include_publisher_bitmap is a real drag to support
    original_include_header_option = options[:include_header]
    if options[:include_publisher_bitmap]
      # In this case, we need to generate our own header because we are adding publisher names
      options[:include_header] = false
      # In this case, we need to make sure duplicates come through or we can't make the "publisher bitmap"
      options[:allow_duplicates] = true
      options[:columns] += ["email"] if !options[:columns].include?("email")
      options[:columns] += ["publisher_label"] if !options[:columns].include?("publisher_label")
    end

    signups_across_publishers = []
    publishers.select { |p| options[:publisher_labels].include?(p.label) }.each do |publisher|
      publisher.generate_consumers_list(signups_across_publishers, options)
      # if a header is wanted, only include it on the first line
      options[:include_header] = false
    end

    if options[:include_publisher_bitmap]
      options[:include_header] = original_include_header_option
      transfer_to_csv_adding_publisher_bitmap(csv, signups_across_publishers, options)
    elsif options[:allow_duplicates]
      transfer_to_csv(csv, signups_across_publishers)
    else
      transfer_to_csv_and_dedup_on_email(csv, signups_across_publishers, options)
    end

  end

  # The idea here is that for each publisher specified, we include a column for that publisher
  # and stick a 1 or 0 in the column if the publisher has that email address as a signup.
  # Seems like a lot of work when we could just give the label and when it does not
  # seem like there will be lots of overlap.  Also the method is on the heinously complex end of things.
  def transfer_to_csv_adding_publisher_bitmap(csv, signups_across_publishers, options)
    publisher_labels = options[:publisher_labels] || {}

    if publisher_labels.present?
      selected_publishers = publisher_labels.map { |label| publishers.find_by_label!(label) }
    else
      selected_publishers = publishers.sort_by(&:name)
    end

    publisher_label_index = options[:columns].index("publisher_label")
    options[:columns].delete_at(publisher_label_index)
    column_title_map = options[:column_title_map] || {}
    column_title_map = column_title_map.with_indifferent_access
    if options[:include_header]
      csv << (options[:columns].collect {|c| column_title_map[c].present? ? column_title_map[c] : c}) + selected_publishers.map(&:name)
    end

    email_index = options[:columns].index("email")
    signups_across_publishers.group_by { |signup| signup[email_index] }.each_value do |signups|
      signup_to_use = signups.detect { |signup|
        signup.respond_to?(:first_name) && signup.first_name.present? && signup.respond_to?(:last_name) && signup.last_name.present?
      }
      signup_to_use ||= signups[0]
      publisher_labels_for_this_signup = signups.map {|signup| signup[publisher_label_index]}
      publishers_bitmap = selected_publishers.map { |publisher| publisher_labels_for_this_signup.include?(publisher.label) ? 1 : 0 }
      signup_to_use.delete_at(publisher_label_index)
      csv << signup_to_use + publishers_bitmap
    end

  end

  def transfer_to_csv(csv, signups_across_publishers)
    signups_across_publishers.each { |row| csv << row }
  end

  def transfer_to_csv_and_dedup_on_email(csv, signups_across_publishers, options)
    email_index = options[:columns].index("email")
    emails = Set.new
    signups_across_publishers.each do |row|
      if !emails.include?(row[email_index])
        csv << row
      end
      emails << row[email_index]
    end
  end

  def generate_consumers_totals_list(csv, options = {})
    publishers.all(:order => 'name ASC').each do |publisher|
      csv << [publisher.name, publisher.consumers_totals(options)]
    end

    csv
  end

  def consumers_to_csv(csv)
    publishers.each do |p|
      csv << [ "ID", "Publisher ID","Market","First Name", "Last Name", "Email" ]
      p.consumers.each do |c|
        puts("WARN: publisher #{c.publisher_id} does not exist for consumer #{c.id}") unless Publisher.exists?(c.publisher_id)
        csv << [ c.id, c.publisher_id, p.market_name_or_city, c.market, c.first_name, c.last_name, c.email ]
      end
    end
    
  end
  
  def subscribers_to_csv(csv)
    csv << [ "ID", "Publisher ID", "First Name", "Last Name", "Email" ]
    publisher_subscribers.each do |s|
      puts("WARN: publisher #{s.publisher_id} does not exist for subscriber #{s.id}") unless Publisher.exists?(s.publisher_id)
      csv << [ s.id, s.publisher_id, s.first_name, s.last_name, s.email ]
    end
  end
  
  def daily_deal_purchases_to_csv(csv, date_range=(Time.now..Time.now))
    csv << ["Consumer", "Email", "Listing", "Merchant", "Aa Merchant", "Market", "Payment Status", "Advertiser Name",
            "Created At", "Refund Amount", "Quantity", "Gross Price", "Credit Used", "Executed At", "Refunded At", "Recipient Names",
            "Actual Purchase Price", "Gift","Redeemed At", "Serial Number", "Origin Name"]
    all_daily_deal_purchases.payment_status_updated_for_dates(date_range).each do |ddp|
      daily_deal = ddp.daily_deal
      puts("WARN: daily deal #{ddp.daily_deal_id} does not exist for daily deal purchase #{ddp.id}") unless DailyDeal.exists?(ddp.daily_deal_id)
      puts("WARN: consumer #{ddp.consumer_id} does not exist for daily deal purchase #{ddp.id}") unless Consumer.exists?(ddp.consumer_id) || ddp.is_a?(OffPlatformDailyDealPurchase)
      puts("WARN: publisher #{ddp.publisher.id} does not exist for daily deal purchase #{ddp.id}") unless Publisher.exists?(ddp.publisher.id)
      csv << [
        ddp.consumer_id, ddp.consumer.try(:email), daily_deal.listing, daily_deal.advertiser.merchant_id, daily_deal.advertiser_id,
        daily_deal.publisher.market_name_or_city, ddp.payment_status, daily_deal.advertiser.name, ddp.created_at,
        ddp.refund_amount, ddp.quantity, ddp.gross_price, ddp.credit_used, ddp.executed_at, ddp.refunded_at, ddp.recipient_names.try(:join, ','),
        ddp.actual_purchase_price, ddp.gift, ddp.daily_deal_certificates.map(&:redeemed_at).join(','), ddp.daily_deal_certificates.map(&:serial_number).join(','),
        ddp.origin_name
      ]
    end
  end
  
  def advertisers_to_csv(csv)
    csv << [ "ID", "Publisher ID", "Publisher/Deal City", "Client Name", "Listing", "Tagline", "Logo", "Website URL", "E-mail Address",
             "Address Line 1", "Address Line 2", "City", "State", "Zip", "Phone Number" ]

    advertisers.each do |advertiser|
      puts("WARN: publisher #{advertiser.publisher_id} does not exist for advertiser #{advertiser.id}") unless Publisher.exists?(advertiser.publisher_id)
      csv << [
              advertiser.id, 
              advertiser.publisher_id, 
              advertiser.publisher.label, 
              advertiser.name, 
              advertiser.listing, 
              advertiser.tagline, 
              advertiser.logo.url, 
              advertiser.website_url, 
              advertiser.email_address,
              advertiser.address? ? advertiser.store.address_line_1 : nil, 
              advertiser.address? ? advertiser.store.address_line_2 : nil, 
              advertiser.address? ? advertiser.store.city : nil, 
              advertiser.address? ? advertiser.store.state : nil, 
              advertiser.address? ? advertiser.store.zip : nil, 
              advertiser.formatted_phone_number
            ]
    end
  end
  
  def daily_deals_to_csv(csv)
    csv << [ "ID", "Advertiser ID", "Publisher ID", "Publisher/Deal City", "Client Name", "Client Listing", "Value Proposition", "Description", 
             "Price", "Total Available", 
             "Minimum Purchase", "Maximum Purchase", "Location Required", "Value", "Highlights", "Terms", "Reviews", "Twitter Status Text", 
             "Facebook Title Text", "Short Description", "Photo (if possible)", "Start At", "Hide At", "Expires On", 
             "Advertiser Revenue Share Percentage", "Listing"
           ]
             
    daily_deals.each do |dd|
      puts("WARN: advertiser #{dd.advertiser_id} does not exist for daily deal #{dd.id}") unless Advertiser.exists?(dd.advertiser_id)
      puts("WARN: publisher #{dd.publisher_id} does not exist for daily deal #{dd.id}") unless Publisher.exists?(dd.publisher_id)
      csv << [
             dd.id,
             dd.advertiser_id,
             dd.publisher_id,
             dd.publisher.label,
             dd.advertiser.name,
             dd.advertiser.listing,
             dd.value_proposition,
             dd.description,
             dd.price,
             dd.quantity,
             dd.min_quantity,
             dd.max_quantity,
             dd.location_required?,
             dd.value,
             dd.highlights,
             dd.terms,
             dd.reviews,
             dd.twitter_status_text,
             dd.facebook_title_text,
             dd.short_description,
             dd.photo.url,
             dd.start_at,
             dd.hide_at,
             dd.expires_on,
             dd.advertiser_revenue_share_percentage,
             dd.listing
            ]
    end
  end
  
  def daily_deal_certificates_to_csv(csv, conditions = [])
    csv << [ "ID", "Daily Deal Purchase ID", "Purchaser", "Recipient", "Serial Number", "Redeemed On", "Redeemed At", "Deal", "Value", 
             "Price", "Purchase Price", "Purchase Date"  ]
    daily_deal_certificates(conditions).each do |ddc|
      puts("WARN: daily deal purchase #{ddc.daily_deal_purchase_id} does not exist for daily deal certificate #{ddc.id}") unless DailyDealPurchase.exists?(ddc.daily_deal_purchase_id)
      csv << [
              ddc.id,
              ddc.daily_deal_purchase_id,
              ddc.consumer_name,
              ddc.redeemer_name,
              ddc.serial_number,
              ddc.daily_deal_purchase.store.try(:summary),
              ddc.redeemed_at,
              ddc.daily_deal_purchase.daily_deal.listing,
              ddc.daily_deal_purchase.value,
              ddc.daily_deal_purchase.price,
              ddc.daily_deal_purchase.daily_deal_payment.try(:amount),
              ddc.daily_deal_purchase.executed_at
             ]
    end
  end
    
  def daily_deal_revenue_to_csv(csv)
    csv << [ "Daily Deal ID", "Advertiser ID", "Deal Info", "Started At", "Advertiser", "Listing", "Value Proposition", "Purchased", "Purchasers", 
             "Gross", "Discount", "Total", "Expires", "Advertiser Revenue Share", "Hours" ]
             
    publishers.map do |publisher|
      publisher.daily_deals_summary(Time.zone.local(2008)..Time.zone.now)
    end.flatten.each do |daily_deal|
      puts("WARN: advertiser #{daily_deal.advertiser_id} does not exist for daily deal #{daily_deal.id}") unless Advertiser.exists?(daily_deal.advertiser_id)
      csv << [
          daily_deal.id,
          daily_deal.advertiser_id,
          daily_deal.description,
          daily_deal.start_at,
          daily_deal.advertiser.name,
          daily_deal.listing,
          daily_deal.value_proposition,
          daily_deal.number_sold,
          daily_deal.daily_deal_purchasers_count,
          daily_deal.daily_deal_purchases_gross,
          daily_deal.daily_deal_purchases_gross - daily_deal.daily_deal_purchases_amount,
          daily_deal.daily_deal_purchases_amount,
          daily_deal.expires_on,
          daily_deal.advertiser_revenue_share_percentage,
          daily_deal.duration_in_hours
        ]
    end
  end

  def active_discounts_to_csv(csv)
    publishers.each do |publisher|
      publisher.consumers.each do |consumer|
        usable_discount = consumer.signup_discount_if_usable
        csv << [consumer.created_at.to_s, consumer.name, consumer.email, usable_discount.amount.to_s] if usable_discount
      end
    end
  end

end
