module CyberSource
  class Credentials
    extend ActiveSupport::Memoizable
    
    REQUIRED_ATTRIBUTES = [:label, :merchant_id, :shared_secret, :serial_number, :soap_username, :soap_password]
    OPTIONAL_ATTRIBUTES = [:started_at, :stopped_at]
    ATTRIBUTES = REQUIRED_ATTRIBUTES + OPTIONAL_ATTRIBUTES

    attr_reader *(ATTRIBUTES - [:shared_secret, :started_at, :stopped_at])
    #
    # Using a class instance variable to store configured CyberSource credentials
    # causes them to be lost when Hydra recreates the class at random. Store them
    # in a global variable instead, as a workaround.
    #
    class << self
      def init(*records)
        $cyber_source_credentials = records.map { |attrs| new(attrs) }.group_by(&:label)
      end

      def load(base_path)
        records = []
        Dir.entries(base_path).sort.each do |name|
          if !name.starts_with?(".") && File.directory?(dir = File.join(base_path, name))
            record = ATTRIBUTES.inject({}) do |hash, attr|
              path = File.join(dir, attr.to_s)
              File.readable?(path) ? hash.merge!(attr => File.read(path).strip) : hash
            end
            records << record
          end
        end
        init *records
      end

      def find(*args)
        options = args.extract_options!
        options.assert_valid_keys(:time)
        
        labels = args.select(&:present?)
        candidates = $cyber_source_credentials.values_at(*labels).compact.flatten
        candidates.detect { |credentials| credentials.match(options) } or raise "No credentials match labels #{labels.join(", ")}"
      end
    end

    def initialize(creds)
      creds.symbolize_keys!
      creds.assert_has_keys REQUIRED_ATTRIBUTES, OPTIONAL_ATTRIBUTES
      creds.each { |key, val| instance_variable_set :"@#{key}", val }
    end
    
    def started_at
      Time.parse(@started_at) if @started_at.present?
    end
    memoize :started_at
    
    def stopped_at
      Time.parse(@stopped_at) if @stopped_at.present?
    end
    memoize :stopped_at
    
    def match(options)
      time = options[:time] || Time.now
      (!started_at || started_at <= time) && (!stopped_at || stopped_at > time)
    end
    
    def signature(data)
      Base64.encode64s(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), @shared_secret, data.to_s))
    end
  end
end
