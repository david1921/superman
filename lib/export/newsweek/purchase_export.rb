require File.dirname(__FILE__) + "/purchase_export/acceptable_countries"

module Export
  module Newsweek
    class PurchaseExport
      PUBLISHER_LABEL = "newsweek"
      JOB_KEY = "newsweek:export_purchases"

      THIRD_PARTY_NAME = "AAN"
      CLIENT_CODE = "195"
      PUBLICATION_CODE = "01"
      ORDER_FLAG = "P"
      SOURCE_KEY = "62WN19"
      TERM = 27

      attr_reader :warnings

      class << self
        def export_to_1500_record_layout!(options = {})
          publisher = ::Publisher.find_by_label(PUBLISHER_LABEL)
          export_timestamp = Time.zone.now.to_i

          raise RuntimeError, "Newsweek publisher not found" unless publisher.present?

          options = {
            :max_purchases_per_file => 999_999
          }.merge(options)

          file_paths = []
          Job.run!(JOB_KEY, :incremental => true) do |increment_start_at, increment_end_at, job|
            job.publisher_id = publisher.id
            daily_deal_purchases = captured_daily_deal_purchases_within_times(publisher, increment_start_at, increment_end_at)
            daily_deal_purchases_slices = daily_deal_purchases.each_slice(options[:max_purchases_per_file]).to_a

            if daily_deal_purchases_slices.empty?
              file_paths << write_purchases_to_file([], 0, export_timestamp)
            else
              daily_deal_purchases_slices.each_with_index do |daily_deal_purchases_slice, i|
                file_paths << write_purchases_to_file(daily_deal_purchases_slice, i, export_timestamp)
              end
            end
          end

          file_paths
        end

        def upload_1500_record_layout_file!
          file_paths = export_to_1500_record_layout!

          file_paths.each do |file_path|
            ensure_file_exists!(file_path)

            Uploader.new("newsweek" => {
              :protocol => "sftp",
              :host => "sftp.palmcoastd.com",
              :user => "AnalogAnalyticsD",
              :pass => "8b5dtsUL"
            }).upload("newsweek", file_path)
          end
        end

        private

        def write_purchases_to_file(daily_deal_purchases, file_number, export_timestamp)
          file_path = export_file_path(file_number, export_timestamp)

          File.open(file_path, "w") do |file|
            purchase_export = new(file, daily_deal_purchases)
            purchase_export.write
          end

          file_path
        end

        def ensure_file_exists!(file_name)
          raise "Export file does not exist: #{file_name}." unless File.exists?(file_name)
        end

        def captured_daily_deal_purchases_within_times(publisher, start_at, end_at)
          publisher.daily_deal_purchases.captured(nil).within_increment_timestamps(start_at, end_at)
        end

        def export_file_path(file_number, timestamp)
          date = Time.now.utc.strftime("%m%d%y")
          Rails.root.join("tmp", "#{THIRD_PARTY_NAME}#{date}-NWK-#{timestamp}-#{file_number}.TXT").to_s
        end
      end

      def initialize(file, daily_deal_purchases)
        @file = file
        @daily_deal_purchases = daily_deal_purchases
        @warnings = []
      end

      def write
        @file.puts generate_header
        @daily_deal_purchases.each do |daily_deal_purchase|
          if daily_deal_purchase.recipients.any?
            generate_one_line_per_recipient(daily_deal_purchase)
          else
            @file.puts generate_line(daily_deal_purchase, daily_deal_purchase.consumer)
          end
        end
      end

      private

      def generate_one_line_per_recipient(daily_deal_purchase)
        daily_deal_purchase.recipients.each do |daily_deal_purchase_recipient|
          @file.puts generate_line(daily_deal_purchase, daily_deal_purchase_recipient)
        end
      end

      def generate_header
        header = "PCD"
        header << full_date_format_in_utc(Time.now)
        header << daily_deal_purchase_count
        header << left_justified_field(THIRD_PARTY_NAME, 10)
        header << blanks(1475)
      end

      def generate_line(daily_deal_purchase, recipient)
        line = full_width_field(CLIENT_CODE.dup, 3)
        line << full_width_field(PUBLICATION_CODE, 2)
        line << full_date_format_in_utc(daily_deal_purchase.executed_at)
        line << blanks(8)
        line << full_width_field(ORDER_FLAG, 1)
        line << blanks(33)
        line << left_justified_field(SOURCE_KEY, 7)
        line << right_justified_field(TERM.to_s, 3, "0")
        line << cash_value(daily_deal_purchase)
        line << full_name(recipient.name)
        line << blanks(54)
        line << left_justified_field(recipient.address_line_1, 27)
        line << left_justified_field(recipient.address_line_2, 27)
        line << left_justified_field(recipient.city, 20)
        line << left_justified_field(recipient.state, 2)
        line << postal_code(recipient.zip_code, recipient.country_code)
        line << country(recipient)
        line << blanks(6)
        line << blanks(10, "0")
        line << blanks(219)
        line << bulk_quantity(daily_deal_purchase)
        line << blanks(20)
        line << blanks(89, "0")
        line << left_justified_field(daily_deal_purchase.consumer.email, 50)
        line << blanks(847)
      end

      def quantity_per_row(daily_deal_purchase)
        daily_deal_purchase.recipients.length > 1 ? 1 : daily_deal_purchase.quantity
      end

      def left_justified_field(value, width, ensure_length = false)
        value = value.to_s

        if ensure_length
          value = value.ljust(width)
          check_field_width(value, width, ensure_length)
        else
          check_field_width(value, width, ensure_length)
          value = value[0..width-1]
          value = value.ljust(width)
        end

        value
      end

      def right_justified_field(value, width, fill = " ", ensure_length = false)
        value = value.to_s

        if ensure_length
          value = value.rjust(width, fill)
          check_field_width(value, width, ensure_length)
        else
          check_field_width(value, width, ensure_length)
          value = value[0..width-1]
          value = value.rjust(width, fill)
        end

        value
      end

      def full_width_field(value, width)
        value = value.to_s
        if value.length < width
          raise "Value for field is not long enough '#{value}'.  Should be #{width} characters."
        end
        value
      end

      def check_field_width(value, width, ensure_length)
        if value.length > width
          @warnings << "Field was #{value.length} characters, expected #{width} characters: #{value}"
        end

        if value.length != width && ensure_length
          raise "Length of value is incorrect '#{value}'.  Should be #{width} characters."
        end
      end

      def blanks(length, fill = " ")
        fill * length
      end

      def full_date_format_in_utc(time)
        time.utc.strftime("%m%d%y")
      end

      def daily_deal_purchase_count
        if @daily_deal_purchases.length.to_s.length > 6
          raise "Too many purchases. Number of purchases can not exceed 999,999."
        end
        right_justified_field(@daily_deal_purchases.length, 6, "0", true)
      end

      def cash_value(daily_deal_purchase)
        value = daily_deal_purchase.price * quantity_per_row(daily_deal_purchase)
        value = (100 * value).to_i.to_s
        right_justified_field(value, 7, "0")
      end

      def full_name(value)
        if value =~ /,/
          @warnings << "Comma was removed from full name: Doe, John"
        end
        left_justified_field(value.gsub(",", ""), 27)
      end

      def postal_code(value, country_code)
        value = value.to_s
        case country_code
        when "US"
          value = value.gsub("-", "")
        when "CA", "CAN"
          if value.length == 6
            value = value.gsub(/(.{3})(.{3})/, '\1 \2')
          else
            value = value.gsub("-", " ")
          end
        end
        left_justified_field(value, 9)
      end

      def country(recipient)
        country_code = recipient.country_code
        country_code = country_code.present? ? country_code : "US"

        case country_code
        when "US"
          value = ""
        when "CA", "CAN"
          value = "CANADA"
        else
          value = Country.find_by_code(country_code).name

          unless ACCEPTABLE_COUNTRIES.include? value
            raise "Country not expected by Newsweek."
          end
        end

        left_justified_field(value, 20)
      end

      def bulk_quantity(daily_deal_purchase)
        right_justified_field(quantity_per_row(daily_deal_purchase).to_s, 3, "0")
      end
    end
  end
end
