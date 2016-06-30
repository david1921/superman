class UploadConfig
  
  def initialize(config)
    @config = case
      when config.is_a?(String): load(config)
      when config.is_a?(Symbol): load(lookup_path(config))
      else config
    end
  end
  
  def [](key)
    if has_key?(key)
      @config[key].symbolize_keys
    else
      nil
    end
  end                          
  
  def []=(key, value)
    @config[key.to_sym] = value
  end

  def fetch!(key)
    raise "No configuration with label #{key}." unless @config.has_key?(key)
    @config[key].symbolize_keys
  end
  
  def has_key?(key)
    @config.has_key?(key)
  end
  
  def keys
    @config.keys
  end

  # could not get alias to work...do not know why
  def labels
    keys
  end   
  
  private
  
  def load(file_path)
    YAML.load(ERB.new(File.read(file_path)).result)
  end
  
  def lookup_path(sym)
    case sym
    when :publishers: File.expand_path("config/tasks/daily_deals/upload_consumers_csv.yml", RAILS_ROOT)
    when :publishing_groups: File.expand_path("config/tasks/daily_deals/upload_publishing_group_consumers_csv.yml", RAILS_ROOT)
    end
  end

end
