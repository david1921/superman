module Import
  module DailyDeals

    class DailyDealsImporter < Importer

      class << self

        def daily_deals_import(publisher, full_path)
          job = start_job(full_path, publisher)
          importer = import_file(full_path, publisher)
          response_file_path = response_fullpath(full_path)
          create_response_file(response_file_path, importer.xml_response)
          finish_job(job)
          response_file_path
        end

        def start_job(full_path, publisher)
          DailyDeal.logger.info "DailyDealsImporter.start_job (#{Time.zone.now})"
          job = Job.start!("daily_deals_import")
          job.publisher = publisher
          job.file_name = File.basename(full_path)
          job.save!
          job
        end

        def import_file(full_path, publisher)
          importer = nil
          File.open(full_path) do |file|
            puts "Reading XML file"
            importer = from_xml(file.read)
            raise "publishers do not match (#{publisher.label} != #{importer.publisher_label})" if publisher.label != importer.publisher_label
            importer.import
          end
          importer
        end

        def finish_job(job)
          DailyDeal.logger.info "DailyDealsImporter.finish_job (#{Time.zone.now})"
          job.finished_at = Time.zone.now
          job.save!
        end

        def response_fullpath(full_path)
          full_path.gsub(/.xml$/, "-response.xml")
        end

        def create_response_file(full_path, xml_response)
          File.open(full_path, "w") do |file|
            file.write(xml_response)
          end
        end

        def from_xml(xml)
          DailyDealsImporter.new(xml.blank? ? {} : HashWithIndifferentAccess.new(Hash.from_xml(xml)))
        rescue Exception => e
          DailyDealsImporter.new({}).tap do |importer|
            importer.add_error(:exception, e.message.lines.first.strip)
          end
        end

      end
      
      attr_reader :xml, :daily_deals, :root_hash

      def initialize(hash)
        super()
        @root_hash = hash
      end

      def import
        add_errors_if_any do
          import_daily_deals if valid?
        end
      end

      def import_daily_deals
        @daily_deals ||= daily_deal_importers.map do |i|
          DailyDeal.transaction do
            result = i.import
            unless i.valid?
              raise ActiveRecord::Rollback
            end
            result
          end
        end
      end

      def import_request
        root_hash[:import_request] || {}
      end

      def publisher_label
        import_request[:publisher_label]
      end

      def publisher
        @publisher ||= Publisher.find_by_label!(publisher_label)
      end

      def timestamp
        import_request[:timestamp]
      end


      def daily_deal_hashes
        @deal_hashes ||= array(import_request[:daily_deal])
      end

      def has_daily_deals?
        daily_deal_hashes.size > 0
      end

      def validate
        required_field_is_missing(:import_request) if import_request.blank?
        required_field_is_missing(:publisher_label) if publisher_label.blank?
        referenced_object_does_not_exist(:publisher) unless publisher_exists?
        required_field_is_missing(:timestamp) if timestamp.blank?
        super
      end

      def publisher_exists?
        return false if publisher_label.blank?
        Publisher.find_by_label(publisher_label).present?
      end

      def daily_deal_importers
        @daily_deal_importers ||= daily_deal_hashes.map { |deal_hash| DailyDealImporter.new(self, publisher, deal_hash) }
      end

      def validate_daily_deals
        daily_deal_importers.each do |importer|
          importer.validate
        end
      end

      def xml_response
        result = ""
        xml_builder = Builder::XmlMarkup.new(:target => result, :indent => 2)
        xml_builder.instruct!
        import_response_attributes = {:publisher_label => publisher_label, :timestamp => timestamp, :xmlns=>"http://analoganalytics.com/api/daily_deals"}
        if daily_deal_importers.present?
          xml_builder.import_response(import_response_attributes) do
            daily_deal_importers.each { |i| i.xml_response(xml_builder) }
          end
        else
          xml_builder.import_response(import_response_attributes)
        end
        result
      end
    end
  end
end
