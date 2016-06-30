module Export
  module Entertainment
    class DealSummaryEmailTask
      include Analog::Say

      # Stores all daily deal purchases for entertainment that date in the purchase total table
      # It runs after the task that generate daily dela purchases file
      # input file is the file of all the daily deal purchases
      def self.store_deal_purchase_counts(input_file, for_date, is_dry_run = false)
        input_file = verify_and_parse_file(input_file)
        for_date = DateParser.parse_date!(for_date, :error_message => "Must specify DATE to store results for")

        say "Parsing entertainment signups by markets"
        summary = DealEmailFileSummarizer.summarize(input_file)
        if is_dry_run
          say(format_hash(summary))
        else
          PublisherDailyDealPurchaseTotal.set_totals(for_date, summary)
        end
      end

      DEFAULT_MAX_VARIANCE = 5
      def self.generate_deal_purchase_variance_file(compare_date, for_date, time_zone, is_dry_run=false)

        output_file = create_output_file_path(time_zone)
        raise ArgumentError, "Output file #{output_file} already exists" if File.exists?(output_file)

        for_date = DateParser.parse_date!(for_date, :error_message => "Must specify an END_DATE")
        compare_date = DateParser.parse_date!(compare_date, :error_message => "Must specify a START_DATE")

        say "Generating entertainment signups summaries and comparisons by markets"
        market_counts = DealSummary.summarize compare_date, for_date, DEFAULT_MAX_VARIANCE

        write_out(market_counts, output_file)

        return output_file
      end

      def self.upload_deal_purchase_variance_file(output_file, is_dry_run=false)

        raise ArgumentError, "Must specify FILE to upload" if output_file.nil?
        raise ArgumentError, "File #{output_file} does not exist" unless File.exists?(output_file)

        say "Uploading entertainment signups summaries and comparisons by markets"
        uploader = Uploader.new(UploadConfig.new(:publishing_groups))
        uploader.upload("entertainment", output_file) unless is_dry_run
      end

      private

      def self.write_out(market_counts, output_file)

        DelimitedFile.open(output_file, '|') do |file|
          file << ["Market", "Count", "Variance", "Exceeds Threshold"]
          market_counts.each do |market|
            file << [market.label, market.count, market.variance, market.exceeds]
          end
        end
      end

      def self.format_hash(summary)
        summary.inject(["Market:\tValue"]) do |output, (key, value)|
          output << "#{key}:\t#{value}"
          output
        end.join("\n")
      end

      def self.verify_and_parse_file(file_path)
        raise ArgumentError, "Must specify FILE to read" if file_path.nil?
        raise ArgumentError, "File #{file_path} does not exist" unless File.exist?(file_path)
        file_path
      end

      def self.create_output_file_path(time_zone)
        output_file = time_stamp_name(time_zone)
        File.expand_path(output_file, rails_tmp_path)
      end

      def self.time_stamp_name(time_zone)
        time_stamp  = Time.zone.now.strftime("%Y%m%d")
        "ENTERTAINPUB_DYNDS_DAILYDEAL_#{time_zone}_SUMMARY_#{time_stamp}.txt"
      end

      def self.rails_tmp_path
        File.expand_path("tmp", Rails.root)
      end
    end

    class DateParser

      def self.parse_date!(for_date, options={})
        message = options[:error_message] || "invalid date format for `#{for_date}`"
        raise ArgumentError, message unless for_date =~ /\A[0-9]{8}\z/
        DateTime.strptime(for_date, "%Y%m%d")
      end

    end
    class DealSummary
      def self.summarize(start_date, end_date, max_variance)
        start_counts  = PublisherDailyDealPurchaseTotal.fetch_totals(start_date) || {}
        end_counts  = PublisherDailyDealPurchaseTotal.fetch_totals(end_date) || {}
        (start_counts.keys | end_counts.keys).map do |key|
          MarketPurchasePair.new(key, start_counts[key], end_counts[key], max_variance)
        end
      end
    end

    class DealEmailFileSummarizer
      def self.summarize(input_file)
        config   = {:col_sep => "|", :headers => true, :quote_char => "\n", :skip_blanks => true}
        csv_file = FasterCSV.open(input_file, "rb", config)
        ItemGrouper.group_items(csv_file) { |row| row['USERDEFINED2'] }
      end
    end

    class ItemGrouper
      def self.group_items(items, &item_mapper)
        mapper_func = block_given? ? item_mapper : Proc.new { |x| x }
        items.inject(Hash.new(0)) do |results, current|
          key = mapper_func.call(current).to_s
          results[key] += 1
          results
        end
      end
    end

    class MarketPurchasePair
      attr_accessor :label, :start_value, :end_value

      def initialize(label, start_amount, end_amount, max_variance)
        @label = label.to_s
        @start_value = start_amount || 0
        @end_value = end_amount || 0
        @max_variance = (max_variance || 0).to_f / 100
      end

      def count
        end_value
      end

      def variance
        end_value - start_value
      end

      def exceeds
        return true if no_sales_today_or_no_sales_yesterday || @max_variance == 0
        variance_percentage > @max_variance
      end

      private

      def no_sales_today_or_no_sales_yesterday
        end_value == 0 or start_value == 0
      end

      def variance_percentage
        start_amount = start_value.to_f
        end_amount = end_value.to_f
        ( end_amount - start_amount ).abs / start_amount
      end
    end
  end
end
