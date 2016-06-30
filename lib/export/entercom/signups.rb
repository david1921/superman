module Export
  
  module Entercom
    
    class Signups < ::Export::Entercom::Base
      
      include Export::Signups
      
      job_key "entercom:generate_signups_csv"

      column "Zip" => :zip_code
      column "Email" => :email
      column "Member ID" => :remote_record_id
      
      class << self
        
        def get_csv_rows_in_batches(increment_start_at = nil, increment_end_at = nil, batch_size = 10_000, &batch_handler)
          raise ArgumentError, "must be called with a block" unless block_given?

          offset = 0
          loop do
            result = ActiveRecord::Base.connection.execute(%Q{
               (SELECT u.remote_record_id, u.id AS signup_id, u.created_at AS signup_date,
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
                 AND u.remote_record_id IS NOT NULL
                 AND u.remote_record_id != ''
                 AND ddpay.payer_postal_code IS NOT NULL
                 AND ddpay.payer_postal_code != ''
                     #{users_increment_filter(increment_start_at, increment_end_at)}
               GROUP BY u.id, u.created_at, p.label, u.email, u.name,
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
        
      end
      
    end
    
  end

end