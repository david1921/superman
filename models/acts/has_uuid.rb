module HasUuid
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
    base.class_eval do
      before_save :initialize_uuid
    end
  end

  module ClassMethods
    def uuid_type(value)
      raise "Unknown UUID type '#{value}'" unless [:timestamp, :random, :url_hash].include?(value = value.to_sym)
      @uuid_type = value
    end
    
    def generate_uuid(instance)
      case @uuid_type
      when nil, :timestamp
        UUIDTools::UUID.timestamp_create
      when :random
        UUIDTools::UUID.random_create
      when :url_hash
        UUIDTools::UUID.sha1_create(UUIDTools::UUID_URL_NAMESPACE, instance.url_for_uuid)
      else
        raise "Unknown UUID type '#{@uuid_type}'"
      end
    end
  end

  module InstanceMethods
    def url_for_uuid
      self.to_url
    end
    
    private
    
    def initialize_uuid
      self.uuid = self.class.generate_uuid(self).to_s if uuid.blank?      
    end
  end
end
