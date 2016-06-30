# Import WCAX from Second Street
module Import
  module OffPlatformDailyDealCertificates
    module CSV
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def from_csv_file(path, publisher_label)
          begin
            OffPlatformDailyDealCertificate.transaction do
              publisher = Publisher.find_by_label!(publisher_label)
              
              row_index = 0
              FasterCSV.foreach(path, :headers => true) do |row|

                begin
                  from_csv(row, publisher)
                rescue Exception => e
                  say "#{e}: #{path} #{row_index}"
                  say row
                end

                row_index = row_index + 1
                if row_index % 1000 == 0
                  say row_index
                elsif row_index % 100 == 0
                  dot
                end
              end
            end
          rescue FasterCSV::MalformedCSVError => e
            say "#{e}: #{path}"
          end
        end

        def from_csv(row, publisher)
          if row_blank?(row) || !active?(row) || !valid_email?(row)
            return nil
          end

          consumer = (publisher.publishing_group || publisher).consumers.find_by_email(row["PurchaserEmail"])
          if consumer.nil?
            consumer = publisher.consumers.build(
              :email => row["PurchaserEmail"],
              :first_name => row["PurchaserFirstName"],
              :last_name => row["PurchaserLastName"],
              :agree_to_terms => true
            )
            consumer.force_password_reset = true
            consumer.password = "123456"
            consumer.password_confirmation = "123456"
            consumer.save!
          end
          consumer.off_platform_daily_deal_certificates.create!(
            :executed_at => row["OrderDateTime"],
            :expires_on => row["DateExpires"],
            :line_item_name => row["Offer"].gsub(/<[^>]+>/, ""),
            :code => row["Code"],
            :contest_id => row["ContestID"],
            :order_id => row["OrderID"],
            :order_line_id => row["OrderLineID"],
            :quantity_excluding_refunds => row["Quantity"],
            :redeemer_names => "#{row["PurchaserFirstName"]} #{row["PurchaserLastName"]}",
            :redeemed_at => row["DateRedeemed"],
            :redeemed => row["IsRedeemed"].casecmp("TRUE") == 0
          )
        end

        def row_blank?(row)
          row["PurchaserEmail"].blank? || row["PurchaserFirstName"].blank? || row["PurchaserLastName"].blank? || row["OrderStatus"].blank?
        end

        def active?(row)
          # Typically "Authorized Refund" if not "Active"
          row["Status"] == "Active"
        end

        def valid_email?(row)
          row["PurchaserEmail"].present? && row["PurchaserEmail"][::Authentication.login_regex]
        end
      end
    end
  end
end
