module Export::FormattingHelper
  def unique_file_path(name = 'EXPORT', ext = ".csv")
    datestamp = (ENV['END_DATE'].present) ? ENV['END_DATE'] : Time.now.localtime.strftime("%Y%m%d-%H%M%S")  
    file_name = name << '-' << datestamp << ext
    File.expand_path(file_name, File.expand_path("tmp", Rails.root))
  end
  def formatted_date(value)
    return "" if value.nil?
    date = DateTime.parse(value)
    date = date.to_date
    date.to_formatted_s("%m/%d/%Y") 
  end
  def format_phone(value)
    value = value.to_s.gsub!(/^1/, '')
    number_to_phone(value)
  end
  def format_percentage(value)
    number_to_percentage(value, :precision => 0)
  end
  def format_price(value)
    number_to_currency(value, :precision => 0) 
  end
  def deserialize(string)
     return string unless string.is_a?(String) && string =~ /^---/
     YAML::load(string) rescue string
  end
  def upload_file_to_publisher(file_path, label)
    publishers_config = UploadConfig.new(:publishing_groups) 
    config = publishers_config.fetch!(label)
    if config.nil?
      publishers_config = UploadConfig.new(:publishers)
      config = publishers_config.fetch!(label)
    end
    Uploader.new(publishers_config).upload(label, file_path)  
  end
end