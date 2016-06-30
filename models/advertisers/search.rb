module Advertisers
  module Search
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # This is in the process of being refactored
      def search(options={})
        publisher = options[:publisher] or raise(ArgumentError, 'Publisher must be specified (for now)')
        locale = options[:locale] || I18n.locale

        sql = <<-sql
          SELECT advertisers.id, advertiser_translations.name,
            COUNT(DISTINCT o1.id) AS offers_count, COUNT(DISTINCT o2.id) AS active_offers_count,
            COUNT(DISTINCT g1.id) AS gift_certificates_count, COUNT(DISTINCT g2.id) AS active_gift_certificates_count,
            COUNT(DISTINCT t1.id) AS txt_offers_count, COUNT(DISTINCT t2.id) AS active_txt_offers_count,
            COUNT(DISTINCT uc.user_id) AS users_count
          FROM advertisers
            LEFT JOIN offers o1 ON o1.advertiser_id = advertisers.id AND o1.deleted_at IS NULL
            LEFT JOIN offers o2 ON o2.advertiser_id = advertisers.id AND o2.deleted_at IS NULL AND
              (o2.show_on IS NULL OR o2.show_on <= ?) AND (o2.expires_on IS NULL OR o2.expires_on >= ?)
            LEFT JOIN gift_certificates g1 ON g1.advertiser_id = advertisers.id AND !g1.deleted
            LEFT JOIN gift_certificates g2 ON g2.advertiser_id = advertisers.id AND !g2.deleted AND
              (g2.show_on IS NULL or g2.show_on <= ? ) AND (g2.expires_on IS NULL OR g2.expires_on >= ?) AND
              (g2.number_allocated > (SELECT COUNT(*) FROM purchased_gift_certificates pgc WHERE pgc.gift_certificate_id = g2.id))
            LEFT JOIN txt_offers t1 ON t1.advertiser_id = advertisers.id AND NOT t1.deleted
            LEFT JOIN txt_offers t2 ON t2.advertiser_id = advertisers.id AND NOT t2.deleted AND
              (t2.appears_on IS NULL OR t2.appears_on <= ?) AND (t2.expires_on IS NULL OR t2.expires_on >= ?)
            LEFT JOIN user_companies uc ON uc.company_type = 'Advertiser' AND uc.company_id = advertisers.id
            LEFT JOIN advertiser_translations ON advertisers.id = advertiser_translations.advertiser_id AND advertiser_translations.locale = "#{locale}"
            #{zip_match_sql_parts(options)[:joins]}
          WHERE
            advertisers.publisher_id = ? AND advertisers.deleted_at IS NULL
            #{name_match_sql_where(options)}
            #{zip_match_sql_parts(options)[:where]}
          GROUP BY advertisers.id
          ORDER BY advertiser_translations.name
        sql

        returning find_by_sql([sql] + [Time.zone.now]*6 + [publisher.id]) do |advertisers|
          advertisers.each do |advertiser|
            %w{ users offers active_offers gift_certificates active_gift_certificates txt_offers active_txt_offers }.each do |type|
              advertiser.send("#{type}_count=", advertiser.send("#{type}_count").to_i)
            end
          end
        end
      end

      private

      def name_match_sql_where(options)
        name = options[:name]
        name_anchor = name.present? && (name.chars.to_a[0] == '^') ? '' : '%' and
            name.present? ? "AND LOWER(advertiser_translations.name) LIKE #{connection.quote "#{name_anchor}#{name.sub('^', '')}%"}" : ""
      end

      def zip_match_sql_parts(options)
        options[:zip].present? ?
            {
                :joins => "LEFT OUTER JOIN stores ON stores.advertiser_id = advertisers.id",
                :where => "AND LOWER(stores.zip) LIKE #{connection.quote "#{options[:zip].downcase}%"}"
            } :
            {}
      end

    end
  end
end