module Report::Publisher
  def self.included(base)
    base.send :include, InstanceMethods
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def all_with_purchased_daily_deal_counts(dates, publishers)
      sql =<<-EOF
        SELECT publishers.id, publishers.name, publishers.currency_code AS currency_code
        , COUNT(DISTINCT(daily_deals.id)) AS daily_deals_count
        , COUNT(DISTINCT(users.id)) AS daily_deal_purchasers_count
        , SUM(1.0/daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_purchases_total_quantity
        , SUM(daily_deal_purchases.gross_price/daily_deal_purchases.quantity/daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_purchases_gross
        , SUM(daily_deal_certificates.actual_purchase_price) AS daily_deal_purchases_actual_purchase_price
        , SUM(IF(daily_deal_certificates.refunded_at BETWEEN :beg AND :end, daily_deal_certificates.refund_amount, 0)) AS daily_deal_purchases_refund_amount
        FROM publishers
          INNER JOIN daily_deals ON publishers.id = daily_deals.publisher_id
          INNER JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id
          INNER JOIN daily_deal_certificates ON daily_deal_purchases.id = daily_deal_certificates.daily_deal_purchase_id
          LEFT JOIN users ON daily_deal_purchases.consumer_id = users.id
        WHERE publishers.id IN (:ids)
        AND daily_deal_purchases.payment_status IN ('captured', 'refunded')
        AND daily_deal_purchases.executed_at BETWEEN :beg AND :end
        AND daily_deal_purchases.type in ('DailyDealPurchase','NonVoucherDailyDealPurchase')
        GROUP BY publishers.id
        ORDER BY publishers.name ASC
      EOF


      purchased_outside_period_but_refunded_in_period_sql =<<-EOF
        SELECT p.id, SUM(ddc.refund_amount) as refund_total
         FROM publishers p
         INNER JOIN daily_deals dd ON dd.publisher_id = p.id
         INNER JOIN daily_deal_purchases ddp ON ddp.daily_deal_id = dd.id
         INNER JOIN daily_deal_certificates ddc ON ddc.daily_deal_purchase_id = ddp.id
         WHERE p.id IN (:ids)
         AND ddp.executed_at NOT BETWEEN :beg AND :end
         AND ddc.refunded_at BETWEEN  :beg AND :end
         AND ddc.status = 'refunded'
         AND ddp.type = 'DailyDealPurchase'
         GROUP BY p.id
      EOF

      times = times_for_dates(dates)

      purchased_outside_refunded_inside = find_by_sql(
        [purchased_outside_period_but_refunded_in_period_sql, { :ids => publishers, :beg => times.begin, :end => times.end }])

      added_refund_amounts = Hash.new(0)
      purchased_outside_refunded_inside.map do |p|
        added_refund_amounts[p["id"]] = p["refund_total"]
      end

      find_by_sql([sql, { :ids => publishers, :beg => times.begin, :end => times.end }]).tap do |rows|
        rows.each do |row|
          row['currency_symbol'] = Publisher.currency_symbol_for(row["currency_code"])
          row['daily_deals_count'] = row['daily_deals_count'].to_i
          row['daily_deal_purchasers_count'] = row['daily_deal_purchasers_count'].to_i
          row['daily_deal_purchases_total_quantity'] = row['daily_deal_purchases_total_quantity'].to_i
          row['daily_deal_purchases_gross'] = row['daily_deal_purchases_gross'].to_f
          row['daily_deal_purchases_actual_purchase_price'] = row['daily_deal_purchases_actual_purchase_price'].to_f
          row['daily_deal_purchases_refund_amount'] = row['daily_deal_purchases_refund_amount'].to_f + added_refund_amounts[row["id"]].to_f
        end
      end
    end

    def all_with_purchased_daily_deal_counts_by_market(dates, publisher)
      sql =<<-EOF
      SELECT markets.id
          , IF(markets.name IS NULL, 'No Market', markets.name) AS name
          , publishers.currency_code AS currency_code
          , COUNT(DISTINCT(daily_deals.id)) AS daily_deals_count
          , COUNT(DISTINCT(users.id)) AS daily_deal_purchasers_count
          , SUM(1.0/daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_purchases_total_quantity
          , SUM(daily_deal_purchases.gross_price/daily_deal_purchases.quantity/daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_purchases_gross
          , SUM(daily_deal_certificates.actual_purchase_price) AS daily_deal_purchases_actual_purchase_price
          , SUM(IF(daily_deal_certificates.refunded_at BETWEEN :beg AND :end, daily_deal_certificates.refund_amount, 0)) AS daily_deal_purchases_refund_amount
          FROM publishers
            INNER JOIN daily_deals ON publishers.id = daily_deals.publisher_id
            INNER JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id
            INNER JOIN daily_deal_certificates ON daily_deal_purchases.id = daily_deal_certificates.daily_deal_purchase_id
            LEFT JOIN markets ON daily_deal_purchases.market_id = markets.id
            LEFT JOIN users ON daily_deal_purchases.consumer_id = users.id
          WHERE publishers.id = :id
            AND daily_deal_purchases.payment_status IN ('captured', 'refunded') AND daily_deal_purchases.executed_at BETWEEN :beg AND :end
            AND daily_deal_purchases.type = 'DailyDealPurchase'
          GROUP BY markets.id
          ORDER BY markets.name ASC
      EOF

      purchased_outside_period_but_refunded_in_period_sql =<<-EOF
         SELECT markets.id, SUM(daily_deal_certificates.refund_amount) as refund_total
         FROM daily_deal_purchases ddp
         LEFT JOIN markets ON ddp.market_id = markets.id
         INNER JOIN daily_deal_certificates on ddp.id = daily_deal_certificates.daily_deal_purchase_id
         INNER JOIN daily_deals dd ON ddp.daily_deal_id = dd.id
         INNER JOIN advertisers a ON dd.advertiser_id = a.id
         INNER JOIN publishers p ON a.publisher_id = p.id
         WHERE p.id = :id
           AND ddp.executed_at NOT BETWEEN :beg AND :end
           AND daily_deal_certificates.status = 'refunded'
           AND daily_deal_certificates.refunded_at BETWEEN :beg AND :end
           AND ddp.type = 'DailyDealPurchase'
         GROUP BY markets.id
      EOF

      times = times_for_dates(dates)

      purchased_outside_refunded_inside = find_by_sql(
        [purchased_outside_period_but_refunded_in_period_sql, { :id => publisher.id, :beg => times.begin, :end => times.end }])

      added_refund_amounts = Hash.new(0)
      purchased_outside_refunded_inside.map do |p|
        added_refund_amounts[p["id"]] = p["refund_total"]
      end

      find_by_sql([sql, { :id => publisher.id, :beg => times.begin, :end => times.end }]).tap do |rows|
        rows.each do |row|

          row['currency_symbol'] = Publisher.currency_symbol_for(row["currency_code"])
          row['daily_deals_count'] = row['daily_deals_count'].to_i
          row['daily_deal_purchasers_count'] = row['daily_deal_purchasers_count'].to_i
          row['daily_deal_purchases_total_quantity'] = row['daily_deal_purchases_total_quantity'].to_i
          row['daily_deal_purchases_gross'] = row['daily_deal_purchases_gross'].to_f
          row['daily_deal_purchases_actual_purchase_price'] = row['daily_deal_purchases_actual_purchase_price'].to_f
          row['daily_deal_purchases_refund_amount'] = row['daily_deal_purchases_refund_amount'].to_f + added_refund_amounts[row["id"]].to_f
        end
      end
    end

    def all_with_affiliated_daily_deal_counts(dates, publishers)
      sql =<<-EOF
        SELECT publishers.id, publishers.name, publishers.currency_code AS currency_code
        , COUNT(DISTINCT(daily_deals.id)) AS daily_deals_count
        , COUNT(DISTINCT(users.id)) AS daily_deal_purchasers_count
        , SUM(IFNULL(daily_deal_purchases.quantity, 0)) AS daily_deal_purchases_total_quantity
        , SUM(daily_deal_purchases.gross_price) AS daily_deal_affiliate_gross
        , SUM(daily_deal_purchases.gross_price * (daily_deals.affiliate_revenue_share_percentage / 100)) AS daily_deal_affiliate_payout
        FROM publishers
          INNER JOIN daily_deals ON publishers.id = daily_deals.publisher_id
          INNER JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id
          LEFT JOIN users ON daily_deal_purchases.consumer_id = users.id
        WHERE publishers.id IN (:ids)
          AND daily_deal_purchases.affiliate_id IS NOT NULL
          AND daily_deal_purchases.payment_status = 'captured'
          AND daily_deal_purchases.executed_at BETWEEN :beg AND :end
        GROUP BY publishers.id
        ORDER BY publishers.name ASC
      EOF

      times = times_for_dates(dates)
      find_by_sql([sql, { :ids => publishers, :beg => times.begin, :end => times.end }]).tap do |rows|
        rows.each do |row|
          row['currency_symbol'] = Publisher.currency_symbol_for(row["currency_code"])
          row['daily_deals_count'] = row['daily_deals_count'].to_i
          row['daily_deal_purchasers_count'] = row['daily_deal_purchasers_count'].to_i
          row['daily_deal_purchases_total_quantity'] = row['daily_deal_purchases_total_quantity'].to_i
          row['daily_deal_affiliate_gross'] = row['daily_deal_affiliate_gross'].to_f
          row['daily_deal_affiliate_payout'] = row['daily_deal_affiliate_payout'].to_f
        end
      end
    end

    def all_with_refunded_daily_deal_counts(dates, publishers)
      sql =<<-EOF
        SELECT publishers.id, publishers.name, publishers.currency_code AS currency_code
        , COUNT(DISTINCT(daily_deals.id)) AS daily_deals_count
        , COUNT(DISTINCT(users.id)) AS daily_deal_purchasers_count
        , COUNT(DISTINCT(daily_deal_certificates.id)) AS daily_deal_refunded_vouchers_count
        , SUM(daily_deal_purchases.gross_price/daily_deal_purchases.quantity/daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_refunded_vouchers_gross
        , SUM(daily_deal_certificates.refund_amount) AS daily_deal_refunded_vouchers_amount
        FROM publishers
          INNER JOIN daily_deals ON publishers.id = daily_deals.publisher_id
          INNER JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id
          INNER JOIN daily_deal_certificates ON daily_deal_purchase_id = daily_deal_purchases.id
          LEFT JOIN users ON daily_deal_purchases.consumer_id = users.id
        WHERE publishers.id IN (:ids)
          AND daily_deal_certificates.status = 'refunded' AND daily_deal_certificates.refunded_at BETWEEN :beg AND :end
          AND daily_deal_purchases.type = 'DailyDealPurchase'
        GROUP BY publishers.id
        ORDER BY publishers.name ASC
      EOF
      times = times_for_dates(dates)
      find_by_sql([sql, { :ids => publishers, :beg => times.begin, :end => times.end }]).tap do |rows|
        rows.each do |row|
          row['currency_symbol'] = Publisher.currency_symbol_for(row["currency_code"])
          row['daily_deals_count'] = row['daily_deals_count'].to_i
          row['daily_deal_purchasers_count'] = row['daily_deal_purchasers_count'].to_i
          row['daily_deal_refunded_vouchers_count'] = row['daily_deal_refunded_vouchers_count'].to_i
          row['daily_deal_refunded_vouchers_gross'] = row['daily_deal_refunded_vouchers_gross'].to_f
          row['daily_deal_refunded_vouchers_amount'] = row['daily_deal_refunded_vouchers_amount'].to_f
        end
      end
    end

    def all_with_refunded_daily_deal_counts_by_market(dates, publisher)
      sql =<<-EOF
        SELECT markets.id
        , IF(markets.name IS NULL, 'No Market', markets.name) AS name
        , publishers.currency_code AS currency_code
        , COUNT(DISTINCT(daily_deals.id)) AS daily_deals_count
        , COUNT(DISTINCT(users.id)) AS daily_deal_purchasers_count
        , COUNT(DISTINCT(daily_deal_certificates.id)) AS daily_deal_refunded_vouchers_count
        , SUM(daily_deal_purchases.gross_price/daily_deal_purchases.quantity/daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_refunded_vouchers_gross
        , SUM(daily_deal_certificates.refund_amount) AS daily_deal_refunded_vouchers_amount
        FROM publishers
          INNER JOIN daily_deals ON publishers.id = daily_deals.publisher_id
          INNER JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id
          INNER JOIN daily_deal_certificates ON daily_deal_purchase_id = daily_deal_purchases.id
          LEFT JOIN markets ON daily_deal_purchases.market_id = markets.id
          LEFT JOIN users ON daily_deal_purchases.consumer_id = users.id
        WHERE publishers.id = :publisher_id
          AND daily_deal_certificates.status = 'refunded' AND daily_deal_certificates.refunded_at BETWEEN :beg AND :end
          AND daily_deal_purchases.type = 'DailyDealPurchase'
        GROUP BY markets.id
        ORDER BY markets.name ASC
      EOF
      times = times_for_dates(dates)
      find_by_sql([sql, { :publisher_id => publisher.id, :beg => times.begin, :end => times.end }]).tap do |rows|
        rows.each do |row|
          row['currency_symbol'] = Publisher.currency_symbol_for(row["currency_code"])
          row['daily_deals_count'] = row['daily_deals_count'].to_i
          row['daily_deal_purchasers_count'] = row['daily_deal_purchasers_count'].to_i
          row['daily_deal_refunded_vouchers_count'] = row['daily_deal_refunded_vouchers_count'].to_i
          row['daily_deal_refunded_vouchers_gross'] = row['daily_deal_refunded_vouchers_gross'].to_f
          row['daily_deal_refunded_vouchers_amount'] = row['daily_deal_refunded_vouchers_amount'].to_f
        end
      end
    end

    def update_unique_subscribers_count!
      Publisher.all.each do |publisher|
        publisher.update_attribute :unique_subscribers_count, Publisher.connection.select_value("
          select count(distinct(email)) from (
            select email from users where publisher_id=#{publisher.id}
            union
            select email from subscribers where publisher_id=#{publisher.id}
          ) as TEMP
        ")
      end
    end

    private

    def times_for_dates(dates)
      Time.zone.parse(dates.begin.to_s) .. Time.zone.parse(dates.end.to_s).end_of_day
    end
  end

  module InstanceMethods

    def generate_consumers_list(csv, opts={})
      options = {
          :columns =>  %w{ status email name subject },
          :allow_duplicates => false,
          :column_title_map => nil,
          :interval_in_hours => nil,
          :include_header => true
      }.merge(opts) {| key, old, new | new.nil? ? old : new }

      columns = options[:columns]
      column_title_map = options[:column_title_map]

      known_columns = %w{ status email name subject first_name last_name zip zip_code gender birth_year city mobile_number referral_code created_at billing_city address_line_1 address_line_2 state country_code publisher_label referred spent_credit device signup_discount_code market preferred_locale }
      columns.each { |column| raise "Unknown column '#{column}'" unless known_columns.include?(column) }

      column_title_map ||= {}
      column_title_map = column_title_map.with_indifferent_access
      if options[:include_header]
        csv << (columns.collect {|c| column_title_map[c].present? ? column_title_map[c] : c})
      end

      subject = daily_deals.current_or_previous.try(:email_blast_subject).to_s

      signups(options[:interval_in_hours], options[:allow_duplicates]).each do |record|
        csv << record.merge("status" => "1", "subject" => subject).values_at(*columns)
      end
    end

    def signups(interval_in_hours = nil, duplicates = false)
      duplicates ? signup_records(interval_in_hours) : signup_records_deduplicated_on_email(interval_in_hours)
    end


    def signup_records_deduplicated_on_email(interval_in_hours)
      first_attribute_present = lambda do |signups, attr|
        signups.detect { |signup| signup.respond_to?(attr) && signup.send(attr).present? }.try(attr).to_s
      end

      [].tap do |array|
        (consumers_and_subscribers_from_signup(interval_in_hours)).group_by(&:email).delete_if { |email, _| email.blank? }.each do |email, signups|
          array << HashWithIndifferentAccess.new({
            "email" => email,
            "name" => first_attribute_present.call(signups, :name),
            "zip" => first_attribute_present.call(signups, :zip_code),
            "zip_code" => first_attribute_present.call(signups, :zip_code),
            "gender" => first_attribute_present.call(signups, :gender),
            "birth_year" => first_attribute_present.call(signups, :birth_year),
            "first_name" => first_attribute_present.call(signups, :first_name),
            "last_name" => first_attribute_present.call(signups, :last_name),
            "mobile_number" => first_attribute_present.call(signups, :mobile_number),
            "created_at" => first_attribute_present.call(signups, :created_at),
            "referral_code" => first_attribute_present.call(signups, :referral_code),
            "city" => first_attribute_present.call(signups, :city),
            "state" => first_attribute_present.call(signups, :state),
            "country_code" => first_attribute_present.call(signups, :country_code),
            "billing_city" => first_attribute_present.call(signups, :billing_city),
            "referred" => first_attribute_present.call(signups, :referred?),
            "spent_credit" => first_attribute_present.call(signups, :spent_credit),
            "device" => first_attribute_present.call(signups, :device),
            "signup_discount_code" => first_attribute_present.call(signups, :signup_discount_code),
            "publisher_label" => label,
            "market" => first_attribute_present.call(signups, :market),
            "preferred_locale" => first_attribute_present.call(signups, :preferred_locale)
          })
        end
      end
    end

    def signup_records(interval_in_hours)
      attribute_value = lambda do |signup, attr|
        signup.respond_to?(attr) ? signup.send(attr).if_present : nil
      end

      [].tap do |array|
        (consumers_and_subscribers_from_signup(interval_in_hours)).delete_if { |signup| signup.email.blank? }.each do |signup|
          array << HashWithIndifferentAccess.new({
            "email" => attribute_value.call(signup, :email),
            "name" => attribute_value.call(signup, :name),
            "zip" => attribute_value.call(signup, :zip_code),
            "zip_code" => attribute_value.call(signup, :zip_code),
            "gender" => attribute_value.call(signup, :gender),
            "birth_year" => attribute_value.call(signup, :birth_year),
            "first_name" => attribute_value.call(signup, :first_name),
            "last_name" => attribute_value.call(signup, :last_name),
            "mobile_number" => attribute_value.call(signup, :mobile_number),
            "created_at" => attribute_value.call(signup, :created_at).to_formatted_s(:db),
            "referral_code" => attribute_value.call(signup, :referral_code),
            "city" => attribute_value.call(signup, :city),
            "state" => attribute_value.call(signup, :state),
            "billing_city" => attribute_value.call(signup, :billing_city),
            "country_code" => attribute_value.call(signup, :country_code),
            "referred" => attribute_value.call(signup, :referred?),
            "spent_credit" => attribute_value.call(signup, :spent_credit),
            "device" => attribute_value.call(signup, :device),
            "signup_discount_code" => attribute_value.call(signup, :signup_discount_code),
            "publisher_label" => label,
            "market" => attribute_value.call(signup, :market).try(:name),
            "preferred_locale" => attribute_value.call(signup, :preferred_locale)
          })
        end
      end
    end

    def consumers_and_subscribers_from_signup(interval_in_hours = nil)
      if interval_in_hours
        hours_ago = interval_in_hours.hours.ago
        (consumers.active + subscribers).collect {|signup| signup if signup.created_at >= hours_ago}.compact
      else
        consumers.active + subscribers
      end
    end

    def subscribers_in_date_range(dates)
      sql = <<-EOF
        SELECT DISTINCT(email), zip_code, id, first_name, last_name, name
        FROM subscribers
        WHERE publisher_id = :publisher_id
          AND created_at >= :t_begin
          AND created_at <= :t_end
      EOF
      times = times_for_dates(dates)
      ::Subscriber.find_by_sql([sql, {
        :publisher_id => id,
        :t_begin      => times.begin,
        :t_end        => times.end
      }])
    end

    def referrals_in_date_range(dates)
      sql = <<-EOF
        SELECT referrer.id, referrer.email,
          COUNT(referred.id) AS referral_count,
          IFNULL(credits.credits_given, 0.0) AS credits_given,
          IFNULL(purchases.credit_used, 0.0) AS credit_used
        FROM users AS referrer
        LEFT JOIN users AS referred
          ON referrer.referrer_code = referred.referral_code
        LEFT JOIN (
          SELECT SUM(credits.amount) AS credits_given, credits.consumer_id
          FROM credits
          WHERE credits.origin_type = 'DailyDealPurchase'
            AND credits.created_at >= :t_begin
            AND credits.created_at <= :t_end
          GROUP BY credits.consumer_id
        ) AS credits ON referrer.id = credits.consumer_id
        LEFT JOIN (
          SELECT SUM(credit_used) AS credit_used, consumer_id
          FROM daily_deal_purchases
          WHERE created_at >= :t_begin
            AND created_at <= :t_end
          GROUP BY consumer_id
        ) AS purchases ON referrer.id = purchases.consumer_id
        WHERE referrer.type = 'Consumer'
          AND referred.type = 'Consumer'
          AND referred.created_at >= :t_begin
          AND referred.created_at <= :t_end
          AND referrer.publisher_id = :publisher_id
          AND referred.publisher_id = :publisher_id
        GROUP BY referrer.id
      EOF
      times = times_for_dates(dates)
      ::Consumer.find_by_sql([sql, {
        :publisher_id => id,
        :t_begin      => times.begin,
        :t_end        => times.end
      }])
    end

    def placed_advertisers_count
      joins = { :offers => :placements }
      conditions = { 'placements.publisher_id' => id }
      ::Advertiser.count(:id, :joins => joins, :conditions => conditions, :distinct => true)
    end

    def impressions_count(dates)
      conditions = { 'impression_counts.publisher_id' => id, 'impression_counts.created_at' => times_for_dates(dates) }
      ImpressionCount.sum(:count, :conditions => conditions )
    end

    def clicks_count(dates, clickable_type = nil)
      conditions = { 'click_counts.publisher_id' => id, 'click_counts.created_at' => times_for_dates_for_click_counts(dates), 'click_counts.mode' => "" }
      conditions['click_counts.clickable_type'] = clickable_type if clickable_type
      ClickCount.sum(:count, :conditions => conditions )
    end

    def facebooks_count(dates, clickable_type = nil)
      conditions = { 'click_counts.publisher_id' => id, 'click_counts.created_at' => times_for_dates(dates), 'click_counts.mode' => "facebook" }
      conditions['click_counts.clickable_type'] = clickable_type if clickable_type
      ClickCount.sum(:count, :conditions => conditions )
    end

    def twitters_count(dates, clickable_type = nil)
      conditions = { 'click_counts.publisher_id' => id, 'click_counts.created_at' => times_for_dates(dates), 'click_counts.mode' => "twitter" }
      conditions['click_counts.clickable_type'] = clickable_type if clickable_type
      ClickCount.sum(:count, :conditions => conditions )
    end

    def txts_count(dates)
      joins = "INNER JOIN leads ON txts.source_type = 'Lead' AND txts.source_id = leads.id"
      conditions = { 'leads.publisher_id' => id, 'txts.created_at' => times_for_dates(dates), 'txts.status' => 'sent' }
      Txt.count(:joins => joins, :conditions => conditions)
    end

    def emails_count(dates)
      conditions = { 'leads.publisher_id' => id, 'leads.created_at' => times_for_dates(dates), 'leads.email_me' => true }
      Lead.count(:conditions => conditions)
    end

    def prints_count(dates)
      conditions = { 'leads.publisher_id' => id, 'leads.created_at' => times_for_dates(dates), 'leads.print_me' => true }
      Lead.count(:conditions => conditions)
    end

    def voice_messages_count(dates)
      conditions = { 'leads.publisher_id' => id, 'voice_messages.created_at' => times_for_dates(dates), 'voice_messages.status' => 'sent' }
      VoiceMessage.count(:joins => :lead, :conditions => conditions)
    end

    def calls_count(dates)
      voice_messages_count(dates)
    end

    def voice_messages_minutes(dates)
      sql = <<-EOF
      SELECT advertisers.publisher_id AS id, SUM(intelligent_minutes + talk_minutes) AS cdr_minutes
      FROM offers
        INNER JOIN leads ON offers.id = leads.offer_id
        INNER JOIN advertisers ON advertisers.id = offers.advertiser_id
        INNER JOIN voice_messages ON leads.id = voice_messages.lead_id
        INNER JOIN call_detail_records ON voice_messages.call_detail_record_sid = call_detail_records.sid
      WHERE advertisers.publisher_id = ?
        AND voice_messages.created_at BETWEEN ? AND ?
        AND voice_messages.status = 'sent'
      GROUP BY id
    EOF
      times_for_dates = times_for_dates(dates)
      (Publisher.find_by_sql([sql, id, times_for_dates.begin, times_for_dates.end]).first.try(:cdr_minutes) || "0").to_f
    end

    def advertisers_with_gift_certificates_counts(dates)
      sql =<<-EOF
      SELECT a.id, at.name,
        SUM(IF((b.alloc_begin - IFNULL(b.purchased_begin,0)) > 0, b.alloc_begin - IFNULL(b.purchased_begin,0), 0)) AS available_count_begin,
        SUM(b.price*IF((b.alloc_begin - IFNULL(b.purchased_begin,0)) > 0, b.alloc_begin - IFNULL(b.purchased_begin,0), 0)) AS available_revenue_begin,
        SUM(IFNULL(b.purchased_later, 0) - IFNULL(b.purchased_begin, 0)) AS purchased_count,
        SUM(IFNULL(b.revenue, 0.00)) AS purchased_revenue,
        SUM(IF((b.alloc_later - IFNULL(b.purchased_later,0)) > 0, b.alloc_later - IFNULL(b.purchased_later,0), 0)) AS available_count_end,
        SUM(b.price*IF((b.alloc_later - IFNULL(b.purchased_later,0)) > 0, b.alloc_later - IFNULL(b.purchased_later,0), 0)) AS available_revenue_end
      FROM advertisers AS a
      INNER JOIN (
        SELECT g.id, g.advertiser_id, g.price,
          g.number_allocated*((g.show_on IS NULL or g.show_on <= :d_begin) AND (g.expires_on IS NULL OR g.expires_on >= :d_begin)) AS alloc_begin,
          g.number_allocated*((g.show_on IS NULL or g.show_on <= :d_later) AND (g.expires_on IS NULL OR g.expires_on >= :d_later)) AS alloc_later,
          SUM(p.paypal_payment_date < :t_begin AND p.payment_status = "completed") AS purchased_begin,
          SUM(p.paypal_payment_date < :t_later AND p.payment_status = "completed") AS purchased_later,
          SUM(p.paypal_payment_gross*(p.paypal_payment_date >= :t_begin AND p.paypal_payment_date < :t_later AND p.payment_status = "completed"))
            AS revenue
        FROM gift_certificates AS g LEFT JOIN purchased_gift_certificates AS p
          ON g.id = p.gift_certificate_id
        GROUP BY g.id
      ) AS b ON a.publisher_id = :publisher_id AND a.id = b.advertiser_id
      LEFT JOIN advertiser_translations at ON a.id = at.advertiser_id AND locale = "en"
      GROUP BY a.id
      HAVING available_count_begin > 0 OR available_count_end > 0 OR purchased_count > 0
    EOF
      times = times_for_dates(dates)
      ::Advertiser.find_by_sql(
        [sql, { :publisher_id => id, :d_begin => times.begin, :d_later => times.end + 1, :t_begin => times.begin, :t_later => times.end + 1 }]
      )
    end

    def advertisers_with_web_offers_counts(dates)
      sql =<<-EOF
      SELECT a.id, a.name, a.listing
      , IFNULL(o.offers_count, 0) AS offers_count
      , IFNULL(b.impressions_count, 0) AS impressions_count
      , IFNULL(c.clicks_count, 0) AS clicks_count
      , IFNULL(d.facebooks_count, 0) AS facebooks_count
      , IFNULL(e.twitters_count, 0) AS twitters_count
      , IFNULL(f.prints_count, 0) AS prints_count
      , IFNULL(g.emails_count, 0) AS emails_count
      , IFNULL(h.txts_count, 0) AS txts_count
      , IFNULL(i.calls_count, 0) AS calls_count
      FROM (
        SELECT advertiser_translations.name, advertisers.id, advertisers.listing
        FROM advertisers
        INNER JOIN offers ON advertisers.id = offers.advertiser_id
        LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND locale = "en"
        WHERE advertisers.publisher_id = :publisher_id
        GROUP BY id
      ) AS a
      LEFT JOIN (
        SELECT advertiser_id, COUNT(DISTINCT(offers.id)) AS offers_count
        FROM offers
        WHERE offers.deleted_at IS NULL AND
             ((offers.show_on BETWEEN :t_begin AND :t_end) OR
              (offers.expires_on BETWEEN :t_begin AND :t_end) OR
              (offers.show_on <= :t_begin AND offers.expires_on >= :t_end))
        GROUP BY advertiser_id
      ) AS o ON a.id = o.advertiser_id
      LEFT JOIN (
        SELECT SUM(impression_counts.count) AS impressions_count, offers.advertiser_id
        FROM impression_counts
        INNER JOIN offers ON impression_counts.viewable_id = offers.id AND impression_counts.viewable_type = 'Offer'
        WHERE impression_counts.publisher_id = :publisher_id AND impression_counts.created_at >= :t_begin AND impression_counts.created_at <= :t_end
        GROUP BY advertiser_id
      ) AS b ON a.id = b.advertiser_id
      LEFT JOIN (
        SELECT SUM(click_counts.count) AS clicks_count, offers.advertiser_id
        FROM click_counts
        INNER JOIN offers ON click_counts.clickable_id = offers.id AND click_counts.clickable_type = 'Offer'
        WHERE click_counts.publisher_id = :publisher_id AND click_counts.created_at >= :utc_begin AND click_counts.created_at <= :utc_end
          AND click_counts.mode = ''
        GROUP BY advertiser_id
      ) AS c ON a.id = c.advertiser_id
      LEFT JOIN (
        SELECT SUM(click_counts.count) AS facebooks_count, offers.advertiser_id
        FROM click_counts
        INNER JOIN offers ON click_counts.clickable_id = offers.id AND click_counts.clickable_type = 'Offer'
        WHERE click_counts.publisher_id = :publisher_id AND click_counts.created_at >= :t_begin AND click_counts.created_at <= :t_end
          AND click_counts.mode = 'facebook'
        GROUP BY advertiser_id
      ) AS d ON a.id = d.advertiser_id
      LEFT JOIN (
        SELECT SUM(click_counts.count) AS twitters_count, offers.advertiser_id
        FROM click_counts
        INNER JOIN offers ON click_counts.clickable_id = offers.id AND click_counts.clickable_type = 'Offer'
        WHERE click_counts.publisher_id = :publisher_id AND click_counts.created_at >= :t_begin AND click_counts.created_at <= :t_end
          AND click_counts.mode = 'twitter'
        GROUP BY advertiser_id
      ) AS e ON a.id = e.advertiser_id
      LEFT JOIN (
        SELECT COUNT(leads.id) AS prints_count, offers.advertiser_id
        FROM leads
        INNER JOIN offers ON leads.offer_id = offers.id
        WHERE leads.publisher_id = :publisher_id AND leads.created_at >= :t_begin AND leads.created_at <= :t_end AND leads.print_me
        GROUP BY advertiser_id
      ) AS f ON a.id = f.advertiser_id
      LEFT JOIN (
        SELECT COUNT(leads.id) AS emails_count, offers.advertiser_id
        FROM leads
        INNER JOIN offers ON leads.offer_id = offers.id
        WHERE leads.publisher_id = :publisher_id AND leads.created_at >= :t_begin AND leads.created_at <= :t_end AND leads.email_me
        GROUP BY advertiser_id
      ) AS g ON a.id = g.advertiser_id
      LEFT JOIN (
        SELECT COUNT(txts.id) AS txts_count, offers.advertiser_id
        FROM txts
        INNER JOIN leads ON txts.source_type = 'Lead' AND txts.source_id = leads.id
        INNER JOIN offers ON leads.offer_id = offers.id
        WHERE leads.publisher_id = :publisher_id AND txts.created_at >= :t_begin AND txts.created_at <= :t_end AND txts.status = 'sent'
        GROUP BY advertiser_id
      ) AS h ON a.id = h.advertiser_id
      LEFT JOIN (
        SELECT COUNT(voice_messages.id) AS calls_count, offers.advertiser_id
        FROM voice_messages
        INNER JOIN leads on voice_messages.lead_id = leads.id
        INNER JOIN offers ON leads.offer_id = offers.id
        WHERE leads.publisher_id = :publisher_id AND voice_messages.created_at >= :t_begin AND voice_messages.created_at <= :t_end
          AND voice_messages.status = 'sent'
        GROUP BY advertiser_id
      ) AS i ON a.id = i.advertiser_id
      ORDER BY name ASC
    EOF
      times = times_for_dates(dates)
      utc_times = times_for_dates_for_click_counts(dates)
      ::Advertiser.find_by_sql([sql, { :publisher_id => id, :utc_begin => utc_times.begin, :utc_end => utc_times.end, :t_begin => times.begin, :t_end => times.end }])
    end

    def advertisers_with_daily_deal_counts(dates)
      sql = <<-EOF
        SELECT a.id, a.name, t.twitter_count, f.facebook_count
        FROM (
          SELECT advertisers.id, advertiser_translations.name
          FROM advertisers
          LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND locale = "en"
          WHERE advertisers.publisher_id = :publisher_id
        ) AS a
        LEFT JOIN (
          SELECT SUM(click_counts.count) AS twitter_count, daily_deals.advertiser_id
          FROM click_counts
          INNER JOIN daily_deals ON click_counts.clickable_id = daily_deals.id
            AND click_counts.clickable_type = 'DailyDeal'
          WHERE click_counts.publisher_id = :publisher_id
            AND click_counts.mode = "twitter"
          GROUP BY daily_deals.advertiser_id
        ) AS t ON a.id = t.advertiser_id
        LEFT JOIN (
          SELECT SUM(click_counts.count) AS facebook_count, daily_deals.advertiser_id
          FROM click_counts
          INNER JOIN daily_deals ON click_counts.clickable_id = daily_deals.id
            AND click_counts.clickable_type = 'DailyDeal'
          WHERE click_counts.publisher_id = :publisher_id
            AND click_counts.mode = "facebook"
          GROUP BY daily_deals.advertiser_id
        ) AS f ON a.id = f.advertiser_id
        ORDER BY name ASC
      EOF
      times = times_for_dates(dates)
      ::Advertiser.find_by_sql([sql, { :publisher_id => id, :t_begin => times.begin, :t_end => times.end }])
    end

    def daily_deals_summary(dates, market = nil)
      market_and_group_by_clauses = market.nil? ? " AND daily_deal_purchases.market_id IS NULL" : " AND daily_deal_purchases.market_id = :market_id"
      market_and_group_by_clauses << " GROUP BY daily_deal_or_variation_accounting_id"
      market_and_group_by_clauses << " ORDER BY daily_deals.start_at ASC"

      times = times_for_dates(dates)

      captured_or_refunded_daily_deal_purchases_sql = captured_or_refunded_daily_deal_purchases_for_date_range_sql_snippet(times)
      refund_certificates_sql = refund_certificates_for_date_range_sql_snippet(times)

      sql = %Q{
        SELECT daily_deals.*
          , daily_deals.listing AS deal_listing
          , daily_deal_translations.value_proposition AS daily_deal_value_proposition
          , daily_deal_variations.listing AS variation_listing
          , daily_deal_variations.id AS variation_id
          , daily_deal_variations.daily_deal_sequence_id AS daily_deal_sequence_id
          , daily_deal_variation_translations.value_proposition AS variation_value_proposition
          , COUNT(DISTINCT(IF(#{captured_or_refunded_daily_deal_purchases_sql}, daily_deal_certificates.id, NULL))) / IF(daily_deal_purchases.daily_deal_variation_id IS NOT NULL, 1, daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_purchases_total_quantity
          , COUNT(DISTINCT(IF(#{captured_or_refunded_daily_deal_purchases_sql}, daily_deal_purchases.consumer_id, NULL))) as daily_deal_purchasers_count
          , SUM(IF(#{captured_or_refunded_daily_deal_purchases_sql}, IF(daily_deal_purchases.daily_deal_variation_id, daily_deal_variations.price, daily_deals.price), 0)) / IF(daily_deal_purchases.daily_deal_variation_id IS NOT NULL, 1, daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_purchases_gross
          , SUM(IF(#{captured_or_refunded_daily_deal_purchases_sql}, daily_deal_certificates.actual_purchase_price, 0)) AS daily_deal_purchases_amount
          , SUM(IF(daily_deal_certificates.refunded_at IS NULL, daily_deal_certificates.actual_purchase_price, 0)) AS daily_deal_actual_purchase_price
          , COUNT(DISTINCT(IF(#{refund_certificates_sql}, daily_deal_certificates.id, NULL))) / IF(daily_deal_purchases.daily_deal_variation_id IS NOT NULL, 1, daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_refunded_voucher_count
          , SUM(IF(#{refund_certificates_sql}, daily_deal_certificates.refund_amount, 0)) AS daily_deal_refunds_total_amount
          , IF(daily_deal_variations.id, CONCAT(daily_deals.id,'-',daily_deal_sequence_id), daily_deals.id) as daily_deal_or_variation_accounting_id
          FROM daily_deals
          LEFT JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id AND daily_deal_purchases.type in ('DailyDealPurchase','NonVoucherDailyDealPurchase')
          LEFT JOIN daily_deal_certificates ON daily_deal_purchases.id = daily_deal_certificates.daily_deal_purchase_id
          LEFT JOIN daily_deal_variations ON (daily_deals.id = daily_deal_variations.daily_deal_id OR daily_deals.source_id = daily_deal_variations.daily_deal_id) AND daily_deal_variations.deleted_at IS NULL
          LEFT JOIN daily_deal_translations ON daily_deals.id = daily_deal_translations.daily_deal_id AND daily_deal_translations.locale = :locale
          LEFT JOIN daily_deal_variation_translations ON daily_deal_variations.id = daily_deal_variation_translations.daily_deal_variation_id AND daily_deal_variation_translations.locale = :locale
          LEFT JOIN users on daily_deal_purchases.consumer_id = users.id
          WHERE daily_deals.publisher_id = :publisher_id
          AND (
            daily_deals.start_at BETWEEN :beg AND :end 
            OR daily_deals.hide_at BETWEEN :beg AND :end
            OR daily_deals.start_at <= :beg  AND daily_deals.hide_at >= :end
            OR daily_deal_purchases.executed_at BETWEEN :beg AND :end
            OR daily_deal_purchases.refunded_at BETWEEN :beg AND :end
          )
      }
      sql << market_and_group_by_clauses

      times = times_for_dates(dates)
      _self = self
      purchase_rows = ::DailyDeal.find_by_sql([sql, { :publisher_id => id, :market_id => market.try(:id), :beg => times.begin, :end => times.end, :locale => locale[:language] }]).tap do |rows|
        rows.each do |row|
          row["currency_code"] = _self.currency_code
          row["currency_symbol"] = _self.currency_symbol          
          row['daily_deal_or_variation_listing'] = row['variation_listing']||row['deal_listing']
          row['daily_deal_or_variation_value_proposition'] = row['variation_value_proposition'].present? ? row['variation_value_proposition'] : row['daily_deal_value_proposition']
          row['daily_deal_purchasers_count'] = row['daily_deal_purchasers_count'].to_i
          row['daily_deal_purchases_total_quantity'] = row['daily_deal_purchases_total_quantity'].to_i
          row['daily_deal_purchases_gross'] = row['daily_deal_purchases_gross'].to_f
          row['daily_deal_purchases_amount'] = row['daily_deal_purchases_amount'].to_f
          row['daily_deal_refunds_total_amount'] = row['daily_deal_refunds_total_amount'].to_f
          row['daily_deal_refunded_voucher_count'] = row['daily_deal_refunded_voucher_count'].to_i
        end
      end      

      purchase_rows.sort { |p1, p2| p1.start_at <=> p2.start_at }
    end

    def daily_deals_with_affiliated_daily_deal_counts(dates)
      sql =<<-EOF
        SELECT daily_deals.*
        , COUNT(DISTINCT(users.id)) AS daily_deal_purchasers_count
        , SUM(daily_deal_purchases.quantity) AS daily_deal_affiliate_total_quantity
        , SUM(daily_deal_purchases.gross_price) AS daily_deal_affiliate_gross
        , SUM(daily_deal_purchases.gross_price * (daily_deals.affiliate_revenue_share_percentage / 100)) AS daily_deal_affiliate_payout
        FROM daily_deals
          INNER JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id
          LEFT JOIN users ON daily_deal_purchases.consumer_id = users.id
        WHERE daily_deals.publisher_id = :publisher_id
          AND daily_deal_purchases.payment_status = 'captured'
          AND daily_deal_purchases.executed_at BETWEEN :beg AND :end
          AND daily_deal_purchases.affiliate_id IS NOT NULL
        GROUP BY daily_deals.id
        ORDER BY daily_deals.start_at ASC
      EOF
      times = times_for_dates(dates)
      ::DailyDeal.find_by_sql([sql, { :publisher_id => id, :beg => times.begin, :end => times.end }]).tap do |rows|
        rows.each do |row|
          row["currency_code"] = currency_code
          row["currency_symbol"] = currency_symbol
          row["daily_deal_purchasers_count"] = row["daily_deal_purchasers_count"].to_i
          row["daily_deal_affiliate_total_quantity"] = row["daily_deal_affiliate_total_quantity"].to_i
          row["daily_deal_affiliate_gross"] = row["daily_deal_affiliate_gross"].to_f
          row["daily_deal_affiliate_payout"] = row["daily_deal_affiliate_payout"].to_f
        end
      end
    end

    def daily_deals_with_refund_counts(dates, market = nil)
      market_and_group_by_clauses = market.nil? ? " AND daily_deal_purchases.market_id IS NULL" : " AND daily_deal_purchases.market_id = :market_id"
      market_and_group_by_clauses << " GROUP BY daily_deals.id"
      market_and_group_by_clauses << " ORDER BY daily_deals.start_at ASC"

      sql =<<-EOF
        SELECT daily_deals.*
        , COUNT(DISTINCT(users.id)) AS daily_deal_refunded_purchasers_count
        , COUNT(DISTINCT(daily_deal_purchases.id)) AS daily_deal_refunded_purchases_count
        FROM daily_deals
        INNER JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id
        INNER JOIN daily_deal_certificates ON daily_deal_purchase_id = daily_deal_purchases.id
        LEFT JOIN users ON daily_deal_purchases.consumer_id = users.id
        WHERE daily_deals.publisher_id = :publisher_id
        AND daily_deal_certificates.status = 'refunded' AND daily_deal_certificates.refunded_at BETWEEN :beg AND :end
        AND daily_deal_purchases.type = 'DailyDealPurchase'
      EOF
      sql << market_and_group_by_clauses
      times = times_for_dates(dates)
      this_pub = self
      ::DailyDeal.find_by_sql([sql, { :publisher_id => id, :market_id => market.try(:id), :beg => times.begin, :end => times.end }]).tap do |deals|
        deals.each do |deal|
          refunded_certificates = deal.refunded_certificates_by_market(dates, market)
          deal['currency_code'] = this_pub.currency_code
          deal['currency_symbol'] = this_pub.currency_symbol
          deal['daily_deal_refunded_purchasers_count'] = deal['daily_deal_refunded_purchasers_count'].to_i
          deal['daily_deal_refunded_purchases_count'] = deal['daily_deal_refunded_purchases_count'].to_i
          deal['daily_deal_vouchers_refunded_count'] =  refunded_certificates.size
          deal['daily_deal_refunds_gross'] = refunded_certificates.inject(0) {|sum, cert| sum + cert.price} / deal.certificates_to_generate_per_unit_quantity
          deal['daily_deal_refunds_amount'] = refunded_certificates.inject(0) { |sum, cert| sum + cert.refund_amount }
        end
      end
    end

    def consumers_totals(options = {})
      sql_opts = {:publisher_id => id}
      having_clause = ''

      if options[:date_range]
        sql_opts[:date_begin] = options[:date_range].begin
        sql_opts[:date_end]   = options[:date_range].end
        having_clause = "HAVING min(created_at) BETWEEN :date_begin AND :date_end"
      end

      # Get count of all unique emails from consumers and subscribers
      # where the date they were first created is in the given time range
      #
      # It would be nice to figure out how to use the named scopes for such
      # things as consumers.active here

      publisher = Publisher.find_by_sql([
        "SELECT COUNT(*) count
         FROM (
           SELECT email
           FROM (
              SELECT email, created_at
              FROM users
              WHERE activated_at IS NOT NULL
                AND publisher_id = :publisher_id
                AND type = 'Consumer'
            UNION ALL
              SELECT email, created_at
              FROM subscribers
              WHERE publisher_id = :publisher_id
           ) AS signups
           GROUP BY email
           #{having_clause}
         ) min_created_at",
         sql_opts
      ])

      publisher[0].count.to_i
    end

    def paychex_daily_deal_reports(date_end)
      date_begin = date_end.to_date - 30.years

      times = times_for_dates(date_begin.to_date .. date_end.to_date)
      captured_or_refunded_daily_deal_purchases_sql = captured_or_refunded_daily_deal_purchases_for_date_range_sql_snippet(times)
      refund_certificates_sql = refund_certificates_for_date_range_sql_snippet(times)

      deal_reports = ::DailyDeal.find_by_sql([
        "SELECT daily_deals.*
          , daily_deals.price as price
          , daily_deals.listing as deal_listing
          , daily_deal_variations.listing as variation_listing
          , daily_deal_variations.price as variation_price
          , daily_deal_translations.value_proposition AS daily_deal_value_proposition
          , daily_deal_variation_translations.value_proposition AS variation_value_proposition
          , COUNT(DISTINCT(IF(#{captured_or_refunded_daily_deal_purchases_sql}, daily_deal_certificates.id, NULL))) / IF(daily_deal_purchases.daily_deal_variation_id IS NOT NULL, 1, daily_deals.certificates_to_generate_per_unit_quantity) AS daily_deal_purchases_total_quantity
          , SUM(IF(#{captured_or_refunded_daily_deal_purchases_sql}, IF(daily_deal_purchases.daily_deal_variation_id, daily_deal_variations.price, daily_deals.price), 0)) / IF(daily_deal_purchases.daily_deal_variation_id IS NOT NULL, 1, daily_deals.certificates_to_generate_per_unit_quantity) AS gross_revenue_to_date
          , SUM(IF(#{refund_certificates_sql}, daily_deal_certificates.refund_amount, 0)) AS daily_deal_refunds_total_amount
         FROM daily_deals
         INNER JOIN daily_deal_purchases ON daily_deals.id = daily_deal_purchases.daily_deal_id
         INNER JOIN daily_deal_certificates ON daily_deal_purchases.id = daily_deal_certificates.daily_deal_purchase_id
         LEFT JOIN daily_deal_variations ON daily_deals.id = daily_deal_variations.daily_deal_id AND daily_deal_variations.deleted_at IS NULL
         LEFT JOIN daily_deal_translations ON daily_deals.id = daily_deal_translations.daily_deal_id AND daily_deal_translations.locale = :locale
         LEFT JOIN daily_deal_variation_translations ON daily_deal_variations.id = daily_deal_variation_translations.daily_deal_variation_id AND daily_deal_variation_translations.locale = :locale
         WHERE daily_deals.price > 0
           AND publisher_id = :publisher_id
           AND daily_deals.start_at >= :date_begin
           AND daily_deals.start_at < :date_end
         GROUP BY variation_listing, deal_listing
         ORDER BY start_at ASC",
        { :publisher_id => id, :date_begin => times.begin, :date_end => times.end, :locale => locale[:language] }
      ])

      deal_reports.each do |daily_deal|
        daily_deal['daily_deal_or_variation_listing'] = daily_deal['variation_listing']||daily_deal['deal_listing']
        daily_deal['daily_deal_or_variation_value_proposition'] = daily_deal['variation_value_proposition'].present? ? daily_deal['variation_value_proposition'] : daily_deal['daily_deal_value_proposition']
        daily_deal['daily_deal_purchases_total_quantity'] = daily_deal['daily_deal_purchases_total_quantity'].to_i
        daily_deal['gross_revenue_to_date'] = daily_deal['gross_revenue_to_date'].to_f
        daily_deal['daily_deal_purchases_amount'] = daily_deal['daily_deal_purchases_amount'].to_f
        daily_deal['daily_deal_refunds_total_amount'] = daily_deal['daily_deal_refunds_total_amount'].to_f
        # the following line is to set the price for the daily deal with the variation price
        # if there is a variation, otherwise it just uses the original price.  This is only
        # used by the Paychex reporting module -- if we use this report code somewhere else
        # we might need to look at adding support for the paychex stuff on the variation.
        daily_deal['price'] = (daily_deal["variation_price"]||daily_deal["price"]).to_f
      end
    end

    private

    def times_for_dates(dates)
      Time.zone.parse(dates.begin.to_s) .. Time.zone.parse(dates.end.to_s).end_of_day
    end
    
    def times_for_dates_for_click_counts(dates)
      Time.parse("#{dates.begin.to_s}T00:00:00Z") .. Time.zone.parse(dates.end.to_s).end_of_day
    end

    def captured_or_refunded_daily_deal_purchases_for_date_range_sql_snippet(date_range)
      # we are looking for all daily deal purchases that are in a state
      # of captured or refunded which have an executed_at between the given
      # data range.  If we have a daily deal variation associated with
      # the daily deal purchase, we want to make sure to align the
      # purchase with the correct daily daily variation (otherwise, it
      # would it sum/count over all the variations associated with the
      # daily deal purchase daily deal.)
      #
      # This snippet is used several times in the main SQL.
      captured_or_refunded_daily_deal_purchases_condition = %Q{
        daily_deal_purchases.payment_status IN ('captured', 'refunded') 
        AND daily_deal_purchases.executed_at BETWEEN :beg AND :end 
        AND (daily_deal_purchases.daily_deal_variation_id IS NULL OR daily_deal_purchases.daily_deal_variation_id = daily_deal_variations.id)                
      }
      captured_or_refunded_daily_deal_purchases_sql = ActiveRecord::Base.__send__(:sanitize_sql_array, 
                    [captured_or_refunded_daily_deal_purchases_condition, {:beg => date_range.begin, :end => date_range.end}])
    end

    def refund_certificates_for_date_range_sql_snippet(date_range)
      refund_certificates_condition = %Q{
        daily_deal_certificates.refunded_at BETWEEN :beg AND :end 
        AND (daily_deal_purchases.daily_deal_variation_id IS NULL OR daily_deal_purchases.daily_deal_variation_id = daily_deal_variations.id)
      }
      refund_certificates_sql = ActiveRecord::Base.__send__(:sanitize_sql_array,
                    [refund_certificates_condition, {:beg => date_range.begin, :end => date_range.end}])
    end
  end
end
