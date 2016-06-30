module Import
  module MarketZipCodes

    class MarketZipCodesImporter

      def initialize(publisher, csv_import_file_path)
        @publisher = publisher
        @errors = []
        @csv_import_file_path = csv_import_file_path
        @zip_codes_in_file = []
        @existing_zips_not_in_file = []
      end

      def import
        begin
          Market.transaction do
            job = start_job(@csv_import_file_path, @publisher)
            import_market_zip_codes
            document_existing_market_zip_codes_not_in_import
            finish_job(job)
          end
        rescue MarketZipCodeImportException
          # No-op -- errors for these exceptions end up in the response file
        ensure
          create_response_file
        end
      end

      def xml_response
        result = ""
        xml_builder = Builder::XmlMarkup.new(:target => result, :indent => 2)
        xml_builder.instruct!
        xml_builder.market_zip_code_import_response do |response|
          response.status response_status

          unless @errors.empty?
            response.errors do |errors|
              @errors.each { |message| errors.error message }
            end
          end

          unless @existing_zips_not_in_file.empty?
            response.existing_zip_codes_not_in_import do |existing_zips|
              @existing_zips_not_in_file.each { |zip| existing_zips.zip_code_and_market zip }
            end
          end
        end

        result
      end

      def response_file_name
        @csv_import_file_path.gsub!(".csv", "-response.xml")
      end

      private

      def start_job(full_path, publisher)
        MarketZipCode.logger.info "MarketZipCodesImporter.start_job (#{Time.zone.now})"
        job = Job.start!("market_zip_codes_import")
        job.publisher = publisher
        job.file_name = File.basename(full_path)
        job.save!
        job
      end

      def finish_job(job)
        MarketZipCode.logger.info "MarketZipCodesImporter.finish_job (#{Time.zone.now})"
        job.finished_at = Time.zone.now
        job.save!
      end

      def import_market_zip_codes
        count = 1
        FasterCSV.foreach(@csv_import_file_path) do |row|
          if row_valid_and_importable?(row, count)
            market_name, zip1, zip2, state_code = read_row(row)
            create_or_update_market_and_mappings(market_name, zip1, state_code)
            create_or_update_market_and_mappings(market_name, zip2, state_code)
          end
          count += 1
        end
      end

      def create_or_update_market_and_mappings(market_name, zip, state_code)
        @zip_codes_in_file << zip unless @zip_codes_in_file.include?(zip)
        market = Market.find_or_initialize_by_publisher_id_and_name(:publisher_id => @publisher.id, :name => market_name)
        market.save!

        market_zip = MarketZipCode.find(:first,
                                        :joins => { :market => :publisher },
                                        :conditions => ["zip_code = ? and publisher_id = ?", zip, @publisher.id],
                                        :readonly => false)

        if market_zip
          market_zip.update_attributes!('market_id'  => market.id)  if market_zip.market != market
          market_zip.update_attributes!('state_code' => state_code) if market_zip.state_code != state_code
        else
          market_zip_code = MarketZipCode.create(:market_id => market.id, :zip_code => zip, :state_code => state_code)
          unless market_zip_code.errors.empty?
            market_zip_code.errors.each do |error|
              add_errors_and_raise "#{error[1]}"
            end
          end
        end
      end

      def read_row(row)
        market_name = "#{row[4].strip}".titleize
        zip1 = row[0].strip.rjust(5, "0")
        zip2 = row[1].strip.rjust(5, "0")
        state_code = row[3].strip
        [market_name, zip1, zip2, state_code]
      end

      def document_existing_market_zip_codes_not_in_import
        MarketZipCode.find(:all,
                           :joins => "INNER JOIN markets m ON market_zip_codes.market_id = m.id",
                           :conditions => ["m.publisher_id = '?'", @publisher.id],
                           :include => :market

        ).each do |mzc|
          unless @zip_codes_in_file.include?(mzc.zip_code)
            @existing_zips_not_in_file << "#{mzc.zip_code} - #{mzc.market.name}"
          end
        end
      end

      def row_valid_and_importable?(row, count)
        return false if row_is_header?(row, count)
        if (row[0].to_i == 0 || row[1].to_i == 0 || !row[3].is_a?(String) || row[3].length != 2 || !row[4].is_a?(String))
          add_errors_and_raise("Row #{count} is not valid. No changes have been applied.")
        end
        return true
      end

      def row_is_header?(row, count)
        (row[0].to_i == 0 && count == 1)
      end

      def add_errors_and_raise(messages)
        messages = messages.respond_to?(:each) ? messages : [messages]
        messages.each do |message|
          @errors << message and raise(MarketZipCodeImportException, message)
        end
      end

      def response_status
        @errors.empty? ? "success" : "errors"
      end
      
      def create_response_file
        File.open(response_file_name, "w") do |file|
          file.write(xml_response)
        end
      end

    end

    class MarketZipCodeImportException < RuntimeError
    end
  end
end
