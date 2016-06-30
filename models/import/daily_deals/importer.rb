require "tasks/import/daily_deal_import"

module Import
  module DailyDeals
    class Importer
      include Analog::Say

      attr_reader :children

      def initialize(parent = nil, alternate_attribute_names = nil)
        @errors = ImporterErrors.new
        @validated = false
        @alternate_attribute_names =  alternate_attribute_names || {}
        @children = []
        parent.add_child(self) if parent.present?
      end
      
      def self.import_daily_deals_via_http!
        if publisher_label = ENV['PUBLISHER_LABEL']
          import_daily_deals_via_http_for_publisher!(Publisher.find_by_label!(publisher_label))
        elsif publishing_group_label = ENV['PUBLISHING_GROUP_LABEL']
          publishing_group = PublishingGroup.find_by_label!(publishing_group_label)
          publishing_group.publishers.with_third_party_deals_api_configs.each do |pub|
            begin
              import_daily_deals_via_http_for_publisher!(pub)
            rescue Exception => e
              error_header = "****** WARNING (Import error for #{pub.label}) ******"
              say error_header
              say e.message
              say "*" * error_header.size
            end
          end
        else
          raise ArgumentError, "Must set one of PUBLISHER_LABEL or PUBLISHING_GROUP_LABEL"
        end
      end
      
      def self.import_daily_deals_via_http_for_publisher!(publisher)
        say "Daily Deal Import via HTTP for #{publisher.label}..."
        is_entertainment = publisher.publishing_group.try(:label) == "entertainment"
        if is_entertainment
          env_for_url = Rails.env.production? ? "" : ".qa"
          publisher_config =   {
            :daily_deals_import_url => "https://ws-api#{env_for_url}.entertainment.com/bidas/?ws=157.2A&action=getDeals&vendor=analoganalytics&marketlabel=#{publisher.label}",
            :daily_deals_import_response_url => "https://ws-api#{env_for_url}.entertainment.com/bidas/?ws=157.2A&action=postDealResponses&vendor=analoganalytics"
          }
        else
          publisher_config = UploadConfig.new(:publishers)[publisher.label]
        end

        download_url = publisher_config[:daily_deals_import_url]
        local_file = File.expand_path("tmp/#{publisher.label}-deals-#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.xml", Rails.root)
        say "  GET: #{download_url}"
        say "  TO: #{local_file}"
        auth_options = if publisher.third_party_deals_api_config.present?
          { :basic_auth => { :username => publisher.api_username, :password => publisher.api_password } }
        else
          {}
        end

        response = Import::DailyDealImport::HTTP.download_to_file(download_url, local_file, auth_options)
        response_file = nil
        begin
          if is_entertainment && response.code != '200'
            raise 'send response by email'
          end
          say "Importing..."
          response_file = ::Import::DailyDeals::DailyDealsImporter.daily_deals_import(publisher, local_file)
        rescue Exception
          if is_entertainment
            deliver_file!("DDAcct_Mgmt@entertainment.com", "Deal Import - Request Failed", local_file, 'text/xml')
          else
            raise $!
          end
        end

        if response_file
          response_url = publisher_config[:daily_deals_import_response_url]
          response = Import::DailyDealImport::HTTP.post_file(response_url, response_file, auth_options)
          if is_entertainment && response.body !~ /Success/
            deliver_file!("DDAcct_Mgmt@entertainment.com", "Deal Import - Response Failed", response_file, 'text/xml')
          end
          say "Done."
        end
      end
      
      def self.deliver_file!(*args)
        FileMailer.deliver_file!(*args)
      end

      def find_or_new_model
        raise Analog::Exceptions::SubclassesMustImplementException.new
      end

      def populate_model(model)
        raise Analog::Exceptions::SubclassesMustImplementException.new
      end

      def import
        exceptions = []
        model = nil
        
        begin
          return nil unless valid?
          model = find_or_new_model
          verbose("populating: #{model}")

          begin
            ms = Benchmark.measure { populate_model(model) }
            verbose("finished populating: #{model} (#{"%.3f" % ms.real}s)")
          rescue => e
            Exceptional.handle(e, "Import::DailyDeals::Importer.import: there was a problem populating the #{model.class.name}.")
            exceptions << e
          end

          if child_models_are_valid?
            verbose("saving: #{model}")
            model_saved_successfully = false
            ms = Benchmark.measure { model_saved_successfully = save_model(model) }
            if model_saved_successfully
              verbose("successfully saving: #{model} (#{"%.3f" % ms.real}s)")
            else
              verbose("save aborted, errors saving: #{model} (#{"%.3f" % ms.real}s): #{model.errors.full_messages}")
              add_errors_from_model(model)
            end
          else
            verbose("not saving #{model}: not all children are valid")
            model.valid? # ensure validation errors are set
            add_errors_from_model(model)
          end
        rescue Exception =>  e
          Exceptional.handle(e,  "Import::DailyDeals::Importer.import: there was a problem saving the #{model.class.name}.")
          exceptions << e
        end

        if exceptions.present?
          exceptions.each do |e|
            exception_message = e.message.lines.first.strip
            add_error(:exception, exception_message)
          end
        end

        model
      end

      def errors?
        @errors.errors? || @children.detect(&:errors?).present?
      end

      def add_errors_if_any
        begin
          yield
        rescue Exception => e
          add_error(:exception, "#{e.message.lines.first.strip}")
        end
        !errors?
      end

      def child_models_are_valid?
        @children.detect {|c| !c.valid? }.nil?
      end

      def valid?
        add_errors_if_any do
          validate_if_needed
        end
        !errors?
      end

      def validate
        @validated = true
      end

      def validated?
        @validated
      end

      def validate_if_needed
        validate unless validated?
      end

      def includes_error?(error)
        @errors.include?(error)
      end

      def errors_excluding_children
        @errors
      end

      def errors
        result = @errors.errors.dup
        children.each do |child|
          result += child.errors
        end
        result
      end

      def add_error(attribute, message)
        @errors.add(attribute, "#{message}")
      end

      def add_errors_from_model(model)
        model.errors.each { |attr, msg| add_model_error(attr, msg) }
      end

      def add_model_error(attribute, message)
        add_error(alternate_attribute_name(attribute), message)
      end

      def alternate_attribute_name(attribute)
        @alternate_attribute_names[attribute] || attribute
      end

      def add_child(importer)
        @children << importer
      end

      def attribute_count(node, attribute)
        if node.present? && node.kind_of?(Hash) && node.has_key?(attribute)
          array(node[attribute]).size
        else
          0
        end
      end

      def validate_at_least_one_of(node, attribute)
        add_error(attribute, "must be at least one") if attribute_count(node, attribute) < 1
      end

      def validate_exactly_one_of(node, attribute)
        count = attribute_count(node, attribute)

        if count < 1
          required_field_is_missing(attribute)
        elsif count > 1
          field_has_too_many_values(attribute)
        end
      end

      def validate_at_most_one_of(node, attribute)
        field_has_too_many_values(attribute) if attribute_count(node, attribute) > 1
      end

      def validate_presence_of(node, attribute)
        if node.present? && node.kind_of?(Hash) && node.has_key?(attribute)
          required_field_is_empty(attribute) if node[attribute].blank?
        else
          required_field_is_missing(attribute)
        end
      end

      def required_field_is_missing(attribute)
        add_error(attribute, "is missing")
      end

      def required_field_is_empty(attribute)
        add_error(attribute, "is empty")
      end

      def field_has_too_many_values(attribute)
        add_error(attribute, "has too many values")
      end

      def referenced_object_does_not_exist(attribute)
        add_error(attribute, "does not exist")
      end

      def array(something)
        return [] if something.nil?
        return something if something.kind_of?(Array)
        [something]
      end

      def safe_hash(something)
        return {} if something.nil?
        something
      end

      def time(s)
        return nil if s.blank?
        Time.parse(s)
      end

      def date(s)
        return nil if s.blank?
        Date.parse(s)
      end

      def photo(attribute, photo_url)
        return nil if photo_url.blank?
        photo_filename = download_and_store_photo(attribute, photo_url, File.expand_path("tmp/#{File.basename(photo_url)}", RAILS_ROOT))
        return nil unless File.size?(photo_filename)
        File.new(photo_filename)
      end

      def download_and_store_photo(attribute, photo_url, local_path)
        verbose "Attempting to download #{photo_url}"
        begin
          SystemTimer.timeout(30.seconds) do
            Import::DailyDealImport::HTTP.download_to_file(photo_url, local_path)
          end
          local_path
        rescue Timeout::Error
          say "Timeout getting image: #{photo_url}"
          add_error(attribute, "Timeout fetching image: #{photo_url}")
          nil
        end
      end
      
      def show_verbose_output?
        ENV['VERBOSE'].present?
      end
      
      def verbose(msg)
        say msg if show_verbose_output?
      end

      protected

      # A default implementation that may be overridden by subclasses
      def save_model(model)
        model.save
      end
    end
  end
end
