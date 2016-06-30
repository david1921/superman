module Export::Publisher

  NYDN_EXPORT_COLUMNS = [
    { "email" => "email" },
    { "first_name" => "first_name" },
    { "last_name" => "last_name" },
    { "zip" => "zip_code" },
    { "RecipientName" => "recipient_names" },
    { "Address1" => "address_line_1" },
    { "Address2" => "address_line_2" },
    { "City" => "city" },
    { "State" => "state" },
    { "DD_DEAL" => "value_proposition" },
    { "DD_CATEGORY" => "category" },
    { "DD_PRICE" => "price" },
    { "DD_CARD_TYPE" => "card_type" },
    { "DD_QTY" => "quantity" },
    { "DD_DATE" => "created_at" },
    { "TX_TYPE" => proc do |row|
        %w(R P).include?(row["rec_type"]) ? row["rec_type"] : ""
      end },
    { "DD_ADVERTISER" => "advertiser_name" },
    { "DD_TOTAL_COST" => "actual_purchase_price" },
    { "CONSUMER_DATE" => "consumer_date" }
  ]

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods

    def export_nydn_purchases_and_consumers!(options = {})
      job = Job.start!(nydn_export_job_key)

      options.assert_valid_keys(:file_name, :incremental)
      options[:incremental] = options.fetch(:incremental, false)

      nydn_publisher = Publisher.find_by_label!("nydailynews")

      csv_filename = options[:file_name]
      unless csv_filename.present?
        raise ArgumentError, "missing required argument :file_name for NYDN CSV export"
      end
      csv_options = { :force_quotes => true }
      csv_options.merge!(:col_sep => "\t") if ".xls" == File.extname(csv_filename).downcase

      export_options = get_export_options(options[:incremental])
      FasterCSV.open(csv_filename, "w", csv_options) do |csv_file|
        csv_file << nydn_export_column_names
        seen_subscriber_email = {}
        nydn_publisher.daily_deal_purchases_and_consumers_and_subscribers(export_options) do |result_row|
          next if result_row["rec_type"] == "S" && seen_subscriber_email[result_row["email"]]

          # NYDN needs us to ensure zip_code is a numeric value, or empty.
          unless result_row["zip_code"] =~ /^\d+$/
            result_row["zip_code"] = ""
          end
          if result_row["recipient_names"].present?
            result_row["recipient_names"] = deserialize_recipient_names(result_row["recipient_names"])
          end
          csv_file << to_nydn_csv(result_row)

          seen_subscriber_email[result_row["email"]] = 1 if result_row["rec_type"] == "S"
        end
      end

      job.finish! :increment_timestamp => export_options[:to]
    end

    def nydn_export_column_names
      NYDN_EXPORT_COLUMNS.map { |c| c.keys.first }
    end

    def nydn_export_column_keys
      NYDN_EXPORT_COLUMNS.map { |c| c.values.first }
    end

    private

    def get_export_options(incremental)
      return {} unless incremental

      export_options = { :to => Job.increment_timestamp }
      if job = Job.with_key(nydn_export_job_key).latest_incremental_run.first
        export_options[:from] = job.increment_timestamp
      end
      export_options
    end

    def deserialize_recipient_names(recipient_names_yaml)
      recipient_names = YAML::load(recipient_names_yaml)
      recipient_names.is_a?(Array) ? recipient_names.join("; ") : recipient_names
    rescue
      ""
    end

    def nydn_export_job_key
      @nydn_export_job_key ||= "daily_deals:export_nydn_purchases_and_consumers:nydailynews"
    end

    def to_nydn_csv(row)
      nydn_export_column_keys.map do |k|
        case k
        when String
          row[k].present? ? row[k] : ""
        when Proc
          k.call(row)
        else
          raise "expected NYDN export column key to be a String or Proc, got #{k.inspect}"
        end
      end
    end

  end

  module InstanceMethods

    def daily_deal_purchases_and_consumers_and_subscribers(options = {})
      options.assert_valid_keys(:from, :to)

      conn = DailyDealPurchase.connection

      subscribers_created_at_filter = consumers_activated_at_filter = purchases_created_at_filter = ""

      [:from, :to].each do |param_name|
        if options[param_name]
          unless options[param_name].is_a?(Time)
            raise ArgumentError, "Expected :#{param_name} parameter to be of type Time. Got #{options[param_name].class}."
          end
        end
      end

      quoted_from_date = options[:from].present? ? conn.quote(options[:from].utc) : nil
      quoted_to_date = options[:to].present? ? conn.quote(options[:to].utc) :nil

      if quoted_from_date && quoted_to_date
        subscribers_created_at_filter = "AND (s.created_at > #{quoted_from_date} AND s.created_at <= #{quoted_to_date})"
        consumers_activated_at_filter = "AND (u.activated_at > #{quoted_from_date} AND u.activated_at <= #{quoted_to_date})"
        purchases_created_at_filter = "AND (ddp.created_at > #{quoted_from_date} AND ddp.created_at <= #{quoted_to_date})"
        refunds_refunded_at_filter = "AND (ddp.refunded_at > #{quoted_from_date} AND ddp.refunded_at <= #{quoted_to_date})"
      elsif quoted_from_date && !quoted_to_date
        subscribers_created_at_filter = "AND s.created_at > #{quoted_from_date}"
        consumers_activated_at_filter = "AND u.activated_at > #{quoted_from_date}"
        purchases_created_at_filter = "AND ddp.created_at > #{quoted_from_date}"
        refunds_refunded_at_filter = "AND ddp.refunded_at > #{quoted_from_date}"
      elsif quoted_to_date && !quoted_from_date
        subscribers_created_at_filter = "AND s.created_at <= #{quoted_to_date}"
        consumers_activated_at_filter = "AND u.activated_at <= #{quoted_to_date}"
        purchases_created_at_filter = "AND ddp.created_at <= #{quoted_to_date}"
        refunds_refunded_at_filter = "AND ddp.refunded_at <= #{quoted_to_date}"
      end

      quoted_publisher_id = conn.quote(id)

      result = conn.execute %Q{
        (SELECT s.email AS email, s.first_name AS first_name, s.last_name AS last_name, s.zip_code AS zip_code,
               "" AS recipient_names, "" AS address_line_1, "" AS address_line_2,
               "" AS city, "" AS state, "" AS value_proposition,
               "" AS category, "" AS price, "" AS card_type, "" AS quantity,
               s.created_at AS created_at, "S" as rec_type, "" AS advertiser_name,
               "" AS actual_purchase_price, 100 AS record_group_order, "" AS consumer_date
        FROM subscribers s
        WHERE s.publisher_id = #{quoted_publisher_id} AND s.email NOT IN (SELECT DISTINCT(email) FROM users WHERE publisher_id = #{quoted_publisher_id}) #{subscribers_created_at_filter})

        UNION

        (SELECT u.email AS email, u.first_name AS first_name, u.last_name AS last_name, u.zip_code AS zip_code,
               "" AS recipient_names, u.address_line_1 AS address_line_1, u.address_line_2 AS address_line_2,
               u.billing_city AS city, u.state AS state, "" AS value_proposition,
               "" AS category, "" AS price, "" AS card_type, "" AS quantity,
               u.created_at AS created_at, "C" as rec_type, "" AS advertiser_name,
               "" AS actual_purchase_price, 200 AS record_group_order, "" AS consumer_date
        FROM users u
        WHERE u.publisher_id = #{quoted_publisher_id}
          AND u.id NOT IN (SELECT consumer_id FROM daily_deal_purchases WHERE payment_status IN ('captured', 'refunded') AND type = 'DailyDealPurchase')
          AND u.activated_at IS NOT NULL
          #{consumers_activated_at_filter})

        UNION

        (SELECT u.email AS email, u.first_name AS first_name, u.last_name AS last_name, u.zip_code AS zip_code,
               ddp.recipient_names AS recipient_names, u.address_line_1 AS address_line_1, u.address_line_2 AS address_line_2,
               u.billing_city AS city, u.state AS state, ddt.value_proposition AS value_proposition,
               ddc.abbreviation AS category, dd.price AS price, "" AS card_type,
               ddp.quantity AS quantity, ddp.created_at AS created_at,
               'P' AS rec_type, at.name as advertiser_name, ddp.actual_purchase_price AS actual_purchase_price,
               300 AS record_group_order, u.created_at AS consumer_date
        FROM daily_deal_purchases ddp
          INNER JOIN users u INNER JOIN daily_deals dd INNER JOIN advertisers a
            ON ddp.consumer_id = u.id AND
               ddp.daily_deal_id = dd.id AND
               dd.advertiser_id = a.id
               #{purchases_created_at_filter}
           INNER JOIN daily_deal_categories ddc ON dd.analytics_category_id = ddc.id
           LEFT JOIN daily_deal_translations ddt ON dd.id = ddt.daily_deal_id AND ddt.locale = 'en'
           LEFT JOIN advertiser_translations at ON a.id = at.advertiser_id AND at.locale = 'en'
        WHERE dd.publisher_id = #{quoted_publisher_id}
          AND ddp.payment_status IN ('captured', 'refunded'))

        UNION

        (SELECT u.email AS email, u.first_name AS first_name, u.last_name AS last_name, u.zip_code AS zip_code,
               ddp.recipient_names AS recipient_names, u.address_line_1 AS address_line_1, u.address_line_2 AS address_line_2,
               u.billing_city AS city, u.state AS state, ddt.value_proposition AS value_proposition,
               ddc.abbreviation AS category, dd.price AS price, "" AS card_type,
               -ddp.quantity AS quantity, ddp.refunded_at AS created_at,
               'R' AS rec_type, at.name as advertiser_name, -ddp.actual_purchase_price AS actual_purchase_price,
               400 AS record_group_order, u.created_at AS consumer_date
        FROM daily_deal_purchases ddp
          INNER JOIN users u INNER JOIN daily_deals dd INNER JOIN advertisers a
            ON ddp.consumer_id = u.id AND
               ddp.daily_deal_id = dd.id AND
               dd.advertiser_id = a.id
               #{refunds_refunded_at_filter}
           INNER JOIN daily_deal_categories ddc ON dd.analytics_category_id = ddc.id
           LEFT JOIN daily_deal_translations ddt ON dd.id = ddt.daily_deal_id AND ddt.locale = 'en'
           LEFT JOIN advertiser_translations at ON a.id = at.advertiser_id AND at.locale = 'en'
        WHERE dd.publisher_id = #{quoted_publisher_id} AND ddp.payment_status = 'refunded')

        ORDER BY record_group_order ASC, created_at ASC
      }

      if block_given?
        result.each_hash do |row_hash|
          yield row_hash
        end
      else
        result.all_hashes
      end
    end

    def export_google_offers_feed_xml!(buffer)
      xml = Builder::XmlMarkup.new(:target => buffer)
      xml.instruct!
      xml.feed "xmlns" => "http://base.google.com/ns/1.0", "xml:lang" => "en-US" do
        daily_deals.current_or_future.location_not_required.each do |deal|
          next unless deal.advertiser.address?
          
          xml.entry do
            xml.id deal.uuid
            xml.type "marketplace_prepaid"
            xml.title deal.value_proposition
            xml.description { xml.cdata!(deal.description(:source).gsub("\n", "<br>")) }
            xml.display_image deal.photo.url
            xml.attribution_image deal.publisher.logo.url
            listify_textile_source(deal, :highlights).each { |h| xml.highlight strip_asterisks(h) }
            fit_to_ten_sentences(listify_textile_source(deal, :terms)).each do |t|
              xml.fine_print strip_asterisks(t)
            end
            xml.original_price("%.2f #{currency_code}" % deal.value)
            xml.offer_price("%.2f #{currency_code}" % deal.price)
            # Set max_available to 100_000 if nil, because Google doesn't
            # allow this field to be blank.
            xml.max_available(deal.quantity || 100_000)
            xml.max_allow_user deal.max_quantity
            xml.distribution_date "#{deal.start_at.iso8601}/#{deal.hide_at.iso8601}"
            xml.redemption_date "#{deal.start_at.iso8601}/#{deal.expires_on_iso8601}" if deal.expires?

            xml.merchant do
              xml.name deal.advertiser.name
              xml.description deal.advertiser.description
              xml.url deal.advertiser.website_url if deal.advertiser.website_url.present?
            end
        
            xml.merchant_location do
              s = deal.advertiser.store
              xml.address_1 s.address_line_1
              xml.address_2(s.address_line_2) if s.address_line_2.present?
              xml.city s.city
              xml.state s.state
              xml.postal_code s.zip
              xml.country_code s.country.try(:code)
              xml.phone s.phone_number
            end

            xml.redemption do
              xml.code_provider_type "google"
              xml.code_display_type "alphanumeric"
              xml.instructions do
                xml.cdata! deal.voucher_steps.gsub(/\n/, "<br>")
              end
            end
            
            deal.advertiser.stores.each do |s|
              xml.redemption_location do
                xml.address_1 s.address_line_1
                xml.address_2 s.address_line_2 if s.address_line_2.present?
                xml.city(s.city || "")
                xml.state(s.state || "")
                xml.postal_code(s.zip || "")
                xml.country_code(s.country_code || "")
                xml.phone s.phone_number
              end
            end
          end
        end
      end
    end

    def google_offers_feed_xml_filename
      Rails.root.join("tmp", "#{label}-google-feed-#{Time.zone.now.strftime("%Y%m%d%H%M%S")}.xml").to_s
    end
    
    def enable_google_offers_feed?
      label == "ocregister"
    end

    private
    
    def fit_to_ten_sentences(elements)
      return elements if elements.size <= 10
      new_elements = elements[0..8]
      new_elements << elements[9..-1].reduce([]) do |phrases, el|
        phrases << strip_asterisks(el.strip.sub(/\.$/, ""))
      end.join(". ")
    end
    
    def strip_asterisks(s)
      s.sub(/^\s*?\*\s*/, "")
    end

    def listify_textile_source(obj, attr)
      textile_source = obj.send(attr, :source) rescue nil
      textile_source.present? ? textile_source.split(/\n+/).map(&:strip).select(&:present?) : []
    end

  end

end
