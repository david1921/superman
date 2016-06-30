class ApiActivityLog < ActiveRecord::Base
  
  KNOWN_APIS = {
    "unknown" => "unknown",
    "third_party_deals" => %w(serial_number_request voucher_status_request voucher_status_change) 
  }
  
  belongs_to :loggable, :polymorphic => true
  validates_presence_of :api_name, :api_activity_label, :request_url, :request_initiated_by_us
  validates_inclusion_of :api_name, :in => KNOWN_APIS.keys
  validate :api_activity_label_known_for_api_name
  
  named_scope :recent, lambda { { :conditions => ["created_at >= ?", 5.days.ago], :order => "created_at DESC" } }

  def self.log(options)
    required_options = [:api_name, :api_activity_label, :request, :request_url, :response, :request_initiated_by_us]
    valid_options = required_options + [:response_time, :loggable, :api_status_code, :api_status_message]
    options.assert_valid_keys valid_options
    required_options.each do |ro|
      raise ArgumentError, "missing required argument #{ro}" unless options.include?(ro)
    end
    
    create! :api_name => options[:api_name],
            :api_activity_label => options[:api_activity_label],
            :request_body => options[:request].body,
            :request_url => options[:request_url], 
            :response_body => options[:response].body,
            :http_status_code => options[:response].code,
            :loggable => options[:loggable],
            :api_status_code => options[:api_status_code], 
            :api_status_message => options[:api_status_message], 
            :request_initiated_by_us => options[:request_initiated_by_us],
            :response_time => options[:response_time]
  end

  private
  
  def api_activity_label_known_for_api_name
    unless KNOWN_APIS[api_name].include?(api_activity_label)
      errors.add(:api_activity_label, "Unknown %{attribute} '#{api_activity_label}' for api '#{api_name}'")
    end
  end
  
end
