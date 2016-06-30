module Export
  
  module Signups
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      def get_export_filename
        Rails.root.join("tmp", "#{publishing_group_label}-subs-and-consumers-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.csv").to_s
      end
      
      def get_csv_rows_in_batches(increment_start_at = nil, increment_end_at = nil, batch_size = 10_000, &batch_handler)
        raise ArgumentError, "must be called with a block" unless block_given?
        
        offset = 0
        loop do
          result = ActiveRecord::Base.connection.execute(%Q{
            (SELECT "S" AS rec_type, NULL AS remote_record_id, s.id AS signup_id, s.created_at AS signup_date,
                     p.label AS publisher_label, s.email, s.name, s.zip_code,
                     s.city, s.state, s.address_line_1, s.address_line_2, NULL AS device,
                     s.first_name, s.last_name
             FROM subscribers s
               INNER JOIN publishers p ON s.publisher_id = p.id
               INNER JOIN publishing_groups pg ON p.publishing_group_id = pg.id
             WHERE pg.label = '#{publishing_group_label}'
             #{signups_increment_filter(increment_start_at, increment_end_at)})
           
             UNION
           
             (SELECT DISTINCT "C" AS rec_type, u.remote_record_id, u.id AS signup_id, u.created_at AS signup_date,
                     p.label AS publisher_label, u.email, u.name,
                     MIN(ddpay.payer_postal_code) COLLATE utf8_general_ci AS zip_code,
                     u.billing_city AS city, u.state, u.address_line_1, u.address_line_2,
                     u.device, u.first_name, u.last_name
             FROM users u
               INNER JOIN publishers p ON u.publisher_id = p.id
               INNER JOIN publishing_groups pg ON p.publishing_group_id = pg.id
               LEFT JOIN daily_deal_purchases ddp ON u.id = ddp.consumer_id
               LEFT JOIN daily_deal_payments ddpay ON ddp.id = ddpay.daily_deal_purchase_id
             WHERE pg.label = '#{publishing_group_label}'
                   #{users_increment_filter(increment_start_at, increment_end_at)}
             GROUP BY rec_type, u.id, u.created_at, p.label, u.email, u.name,
                      u.billing_city, u.state, u.address_line_1, u.address_line_2,
                      u.first_name, u.last_name)
           
             ORDER BY signup_date ASC LIMIT %d OFFSET %d
          } % [sql_quote(batch_size), sql_quote(offset)])
          
          current_batch_size = result.num_rows
          batch_handler.call(result) if current_batch_size > 0
          
          raise StopIteration if current_batch_size == 0 || current_batch_size < batch_size
          
          offset += batch_size
        end
      end
      
      def signups_increment_filter(increment_start_at = nil, increment_end_at = nil)
        return unless increment_end_at || increment_end_at

        signups_filter = []
        signups_filter << "s.created_at > #{sql_quote(increment_start_at.utc)}" if increment_start_at
        signups_filter << "s.created_at <= #{sql_quote(increment_end_at.utc)}" if increment_end_at

        "AND #{signups_filter.join(' AND ')}"
      end

      def users_increment_filter(increment_start_at, increment_end_at)
        return unless increment_start_at || increment_end_at

        users_filter = []
        users_filter << "u.created_at > #{sql_quote(increment_start_at.utc)}" if increment_start_at
        users_filter << "u.created_at <= #{sql_quote(increment_end_at.utc)}" if increment_end_at

        "AND #{users_filter.join(' AND ')}"
      end
      
    end
    
    
  end
  
end