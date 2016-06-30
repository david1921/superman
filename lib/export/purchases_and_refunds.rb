module Export
  
  module PurchasesAndRefunds
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods

      protected

      def get_csv_rows_in_batches(increment_start_at = nil, increment_end_at = nil, batch_size = 10_000, &batch_handler)
        raise ArgumentError, "must be called with a block" unless block_given?

        offset = 0
        loop do
          result = ActiveRecord::Base.connection.execute(%Q{
            (SELECT 100 AS record_set, "P" AS tx_type, ddp.uuid AS order_uuid, ddp.executed_at, ddp.refunded_at,
                    ddp.consumer_id, u.remote_record_id, ddp.daily_deal_id, ddp.quantity,
                    ddp.refund_amount, ddp.actual_purchase_price, u.name AS consumer_name,
                    u.email AS consumer_email, ddpay.payer_postal_code AS consumer_zip_code,
                    p.label AS publisher_label, a.id AS advertiser_id, at.name AS advertiser_name,
                    ddcat.abbreviation AS category_code, dd.price AS deal_price,
                    disc.code AS promo_code, disc.amount AS promo_code_amount, disc.last_usable_at AS promo_code_expiry,
                    dd.advertiser_revenue_share_percentage AS advertiser_revenue_share_percentage,
                    s.zip AS advertiser_zip, ddt.value_proposition, ddp.gift, u.first_name, u.last_name
             FROM daily_deal_purchases ddp
               INNER JOIN daily_deals dd ON ddp.daily_deal_id = dd.id
               INNER JOIN advertisers a ON dd.advertiser_id = a.id
               INNER JOIN publishers p ON dd.publisher_id = p.id
               INNER JOIN publishing_groups pg ON p.publishing_group_id = pg.id
               INNER JOIN users u ON ddp.consumer_id = u.id
               LEFT JOIN daily_deal_payments ddpay ON ddp.id = ddpay.daily_deal_purchase_id
               LEFT JOIN daily_deal_translations ddt ON dd.id = ddt.daily_deal_id
               LEFT JOIN daily_deal_categories ddcat ON dd.analytics_category_id = ddcat.id
               LEFT JOIN advertiser_translations at ON a.id = at.advertiser_id
               LEFT JOIN discounts disc ON ddp.discount_id = disc.id
               LEFT JOIN stores s ON ddp.store_id = s.id
             WHERE pg.label = '#{publishing_group_label}'
               AND ddp.payment_status IN ('captured', 'refunded')
               #{purchases_increment_filter(increment_start_at, increment_end_at)})

            UNION

            (SELECT 200 AS record_set, "R" AS tx_type, ddp.uuid AS order_uuid, ddp.executed_at, ddp.refunded_at,
                    ddp.consumer_id, u.remote_record_id, ddp.daily_deal_id, ddp.quantity,
                    ddp.refund_amount, ddp.actual_purchase_price, u.name AS consumer_name,
                    u.email AS consumer_email, ddpay.payer_postal_code AS consumer_zip_code,
                    p.label AS publisher_label, a.id AS advertiser_id, at.name AS advertiser_name,
                    ddcat.abbreviation AS category_code, dd.price AS deal_price,
                    disc.code AS promo_code, disc.amount AS promo_code_amount, disc.last_usable_at AS promo_code_expiry,
                    dd.advertiser_revenue_share_percentage AS advertiser_revenue_share_percentage,
                    s.zip AS advertiser_zip, ddt.value_proposition, ddp.gift, u.first_name, u.last_name
             FROM daily_deal_purchases ddp
               INNER JOIN daily_deals dd ON ddp.daily_deal_id = dd.id
               LEFT JOIN daily_deal_translations ddt ON dd.id = ddt.daily_deal_id
               INNER JOIN advertisers a ON dd.advertiser_id = a.id
               INNER JOIN publishers p ON dd.publisher_id = p.id
               INNER JOIN publishing_groups pg ON p.publishing_group_id = pg.id
               INNER JOIN users u ON ddp.consumer_id = u.id
               LEFT JOIN daily_deal_payments ddpay ON ddp.id = ddpay.daily_deal_purchase_id
               LEFT JOIN daily_deal_categories ddcat ON dd.analytics_category_id = ddcat.id
               LEFT JOIN advertiser_translations at ON a.id = at.advertiser_id
               LEFT JOIN discounts disc ON ddp.discount_id = disc.id
               LEFT JOIN stores s ON ddp.store_id = s.id
             WHERE pg.label = '#{publishing_group_label}'
               AND ddp.payment_status = 'refunded'
               #{refunds_increment_filter(increment_start_at, increment_end_at)})

            ORDER BY executed_at ASC, record_set ASC LIMIT %d OFFSET %d
          } % [sql_quote(batch_size), sql_quote(offset)])
          
          current_batch_size = result.num_rows
          batch_handler.call(result) if current_batch_size > 0
          
          raise StopIteration if current_batch_size == 0 || current_batch_size < batch_size
          
          offset += batch_size
        end
      end

      def purchases_increment_filter(increment_start_at = nil, increment_end_at = nil)
        return unless increment_end_at || increment_end_at

        purchases_filter = []
        purchases_filter << "ddp.executed_at > #{sql_quote(increment_start_at.utc)}" if increment_start_at
        purchases_filter << "ddp.executed_at <= #{sql_quote(increment_end_at.utc)}" if increment_end_at

        "AND #{purchases_filter.join(' AND ')}"
      end

      def refunds_increment_filter(increment_start_at, increment_end_at)
        return unless increment_start_at || increment_end_at

        refunds_filter = []
        refunds_filter << "ddp.refunded_at > #{sql_quote(increment_start_at.utc)}" if increment_start_at
        refunds_filter << "ddp.refunded_at <= #{sql_quote(increment_end_at.utc)}" if increment_end_at

        "AND #{refunds_filter.join(' AND ')}"
      end
      
      def get_export_filename
        Rails.root.join("tmp", "#{publishing_group_label}-purchases-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}.csv").to_s
      end
      
    end
    
  end
  
end