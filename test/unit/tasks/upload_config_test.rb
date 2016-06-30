require File.dirname(__FILE__) + "/../../test_helper"
require File.expand_path("lib/tasks/upload_config", RAILS_ROOT)

class UploadConfigTest < ActiveSupport::TestCase

  def setup
    @publishers_file_sample = <<'PUBLISHERS_FILE_SAMPLE'
ocregister:
  file: "analog-ocregister-consumers.csv"
  host: "transfer2.silverpop.com"
  user: "analog@ocregister.com"
  pass: "AnalogOCR123"
  path: "upload"
gazette:
  file: "analog-coloradosprings-consumers.csv"
  host: "transfer2.silverpop.com"
  user: "analog@coloradosprings.com"
  pass: "AnalogCS123"
  path: "upload"
gastongazette:
  file: "analog-gastongazette-consumers.csv"
  host: "transfer2.silverpop.com"
  user: "analog@gastongazette.com"
  pass: "analogGS123"
  path: "upload"
PUBLISHERS_FILE_SAMPLE
  end
  
  test "yamlized hash based creation plus one lookup" do
    config = UploadConfig.new(YAML.load(@publishers_file_sample))
    assert_not_nil config["gastongazette"]
  end

  test "file path based creation plus one lookup" do
    config = UploadConfig.new(File.expand_path("config/tasks/daily_deals/upload_consumers_csv.yml", RAILS_ROOT))
    assert_not_nil config[config.keys[0]]
  end
  
  test "symbol based creation plus one lookup" do
    config = UploadConfig.new(:publishers)
    assert_not_nil config[config.keys[0]]
    config = UploadConfig.new(:publishing_groups)
    assert_not_nil config[config.keys[0]]
  end
  
  test "Retrieving an entry returns a hash with symbolized keys" do
    config = UploadConfig.new(YAML.load(@publishers_file_sample))
    assert_equal({ :file => "analog-ocregister-consumers.csv",
                   :host => "transfer2.silverpop.com",
                   :user => "analog@ocregister.com",
                   :pass => "AnalogOCR123",
                   :path => "upload" }, config["ocregister"])
  end
  
  test "Values at works for symbols" do
    config = UploadConfig.new(YAML.load(@publishers_file_sample))
    file, user  = config["ocregister"].values_at(:file, :user)
    assert_equal "analog-ocregister-consumers.csv", file
    assert_equal "analog@ocregister.com", user
  end

  test "Values at works for symbols and nil values" do
    config = UploadConfig.new(YAML.load(@publishers_file_sample))
    file, crickets, user = config["ocregister"].values_at(:file, :crickets, :user)
    assert_equal "analog-ocregister-consumers.csv", file
    assert_equal "analog@ocregister.com", user
    assert_nil crickets
  end
  
  test "config assignment works" do
    config = UploadConfig.new({})
    config["foobar"] = {:yellow => "blue"}
    assert_equal "blue", config[:foobar][:yellow]
  end  
  
  test "accessing a non-existent config returns nil" do
    config = UploadConfig.new({})
    assert_nil config["does_not_exist"]
  end

end