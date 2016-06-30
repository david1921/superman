require 'net/http'

class SilverpopError < RuntimeError

  RECIPIENT_NOT_FOUND_ERROR_CODE = 128
  attr_reader :error_code, :raw_msg

  def initialize(error_code, msg)
    super("A silverpop errror ocurred.  Error code: #{error_code}.  Message: #{msg}")
    @error_code = error_code
    @raw_msg = msg
  end

  def recipient_not_found_error?
    error_code == RECIPIENT_NOT_FOUND_ERROR_CODE
  end

end

class Analog::ThirdPartyApi::Silverpop

  DATABASE_LIST_TYPE = 0
  CONTACT_LIST_LIST_TYPE = 18
  PRIVATE_VISIBILITY = 0
  SHARED_VISIBILITY = 1
  OPTED_IN = 2

  def self.allow_silverpop_request?
    Rails.env.production? || Rails.env.staging? || ENV["SILVERPOP_TEST"]
  end

  def initialize(hostname, username, password)
    @hostname, @username, @password = hostname, username, password
    @http = Net::HTTP.new(api_uri.host, api_uri.port)
  end

  def open
    response = api_response(login_request)
    begin
      body = unwrap_from_xml(response.body)["RESULT"]
      @session_encoding = body["SESSION_ENCODING"] if body["SUCCESS"] =~ /true/i
    rescue
      raise "Login failed: #{response.code} #{response.body}"
    end
    if block_given?
      begin
        yield self
      ensure
        close
      end
    end
  end

  def close
    if open?
      response = api_response(logout_request)
      begin
        body = unwrap_from_xml(response.body)["RESULT"]
        @session_encoding = nil if body["SUCCESS"] =~ /true/i
      rescue
        raise "Logout failed: #{response.code} #{response.body}"
      end
    end
  end

  def open?
    @session_encoding.present?
  end

  def schedule_mailing(options = {})
    allowed_keys = [:template_id, :list_id, :mailing_name, :send_at, :subject, :from_name, :from_address, :reply_to, :time_zone]
    required_keys = [:template_id, :list_id, :mailing_name, :send_at]
    validate_options(options, allowed_keys, required_keys)
    request = schedule_mailing_request(options)
    response = execute_silverpop_request(request)
    response["MAILING_ID"]
  end

  def create_contact_list(database_id, contact_list_name)
    options = { :database_id => database_id, :contact_list_name => contact_list_name }
    allowed_keys = required_keys = [:database_id, :contact_list_name]
    validate_options(options, allowed_keys, required_keys)
    request = create_contact_list_request(options)
    response = execute_silverpop_request(request)
    response["CONTACT_LIST_ID"]
  end

  # Used to add a recipient to a DATABASE
  # Use add_contact_to_contact_list to add to a contact list
  def add_recipient(database_id, email)
    options = { :list_id => database_id, :email => email }
    allowed_keys = required_keys = [ :list_id, :email ]
    validate_options(options, allowed_keys, required_keys)
    request = add_recipient_request(options)
    response = execute_silverpop_request(request)
    response["RecipientId"]
  end

  # Used to remove a recipient from a database OR from a contact list
  def remove_recipient(list_id, email)
    options = { :list_id => list_id, :email => email }
    allowed_keys = required_keys = [ :list_id, :email ]
    validate_options(options, allowed_keys, required_keys)
    request = remove_recipient_request(options)
    response = execute_silverpop_request(request)
    true
  end

  # Used to opt_out a recipient from a DATABASE
  def opt_out_recipient(database_id, email)
    options = { :list_id => database_id, :email => email }
    allowed_keys = required_keys = [ :list_id, :email ]
    validate_options(options, allowed_keys, required_keys)
    request = opt_out_recipient_request(options)
    response = execute_silverpop_request(request)
    true
  end

  def add_contact_to_contact_list(contact_list_id, email)
    options = { :contact_list_id => contact_list_id, :email => email }
    allowed_keys = required_keys = [ :contact_list_id, :email ]
    validate_options(options, allowed_keys, required_keys)
    request = add_contact_to_contact_list_request(options)
    response = execute_silverpop_request(request)
    true
  end

  def select_recipient(list_id, email)
    options = { :list_id => list_id, :email => email }
    allowed_keys = required_keys = [ :list_id, :email ]
    validate_options(options, allowed_keys, required_keys)
    request = select_recipient_request(options)
    begin
      execute_silverpop_request(request)
    rescue SilverpopError => e
      raise e unless e.recipient_not_found_error?
      nil
    end
  end

  def contact_lists_for_recipient(list_id, email)
    response = select_recipient(list_id, email)
    contact_lists = response["CONTACT_LISTS"] || {}
    contact_list_ids = contact_lists["CONTACT_LIST_ID"] || []
    Array.wrap(contact_list_ids)
  end

  def recipient_exists?(list_id, email)
    select_recipient(list_id, email).present?
  end

  def recipient_opted_in?(list_id, email)
    recipient = select_recipient(list_id, email)
    return false if recipient.nil?
    opted_in = recipient["OptedIn"]
    opted_out = recipient["OptedOut"]
    return opted_in.present? && opted_out.nil?
  end

  def databases_for_account(options = {})
    get_lists(options.merge(:list_type => DATABASE_LIST_TYPE))
  end

  def contact_lists_for_account(options = {})
    get_lists(options.merge(:list_type => CONTACT_LIST_LIST_TYPE))
  end

  def contact_list_id_if_exists(contact_list_name)
    existing_contact_lists = contact_lists_for_account
    existing_contact_lists.find { |existing_list| existing_list[:name] == contact_list_name }
  end

  def get_lists(options = {})
    options[:visibility] ||= PRIVATE_VISIBILITY
    options[:list_type] ||= DATABASE_LIST_TYPE
    allowed_keys = required_keys = [:list_type, :visibility]
    request = get_lists_request(options)
    response = execute_silverpop_request(request)
    lists = []
    lists_from_server = Array.wrap(response["LIST"] || [])
    lists_from_server.each do |list|
      lists << { :name => list["NAME"], :list_id => list["ID"] }
    end
    lists
  end

  def execute_silverpop_request(request)
    raise "You must open a session before making a request" unless open?
    raise "You must either be in production or set SILVERPOP_TEST environment variable to send a request to silverpop" unless Analog::ThirdPartyApi::Silverpop.allow_silverpop_request?
    response = api_response(request)
    begin
      body = unwrap_from_xml(response.body)
      result = body["RESULT"]
      case result["SUCCESS"]
      when /true|success/i
        result
      when /false/i
        error_code, error_message = extract_silverpop_error_info(body)
        raise SilverpopError.new(error_code, error_message)
      else
        raise RuntimeError, "Silverpop request failed."
      end
    rescue SilverpopError => silver_error
      raise silver_error
    rescue
      raise "Silverpop call failed: #{response.code} #{response.body}"
    end
  end

  def extract_silverpop_error_info(body)
    begin
      error_code = body["Fault"]["detail"]["error"]["errorid"].to_i
      error_message = body["Fault"]["FaultString"]
      [error_code, error_message]
    rescue => x
      [-1, "unknown error: #{body.inspect}"]
    end
  end

  def schedule_mailing_request(options)
    options[:scheduled] = scheduled_time_in_silverpop_format(options)
    options.delete(:send_at)
    options.delete(:time_zone)
    options[:send_html] = "TRUE"
    options[:visibility] = SHARED_VISIBILITY
    silverpop_request("ScheduleMailing", options)
  end

  def scheduled_time_in_silverpop_format(options)
    send_at = options[:send_at]
    if options[:time_zone].present?
      send_at = send_at.in_time_zone(options[:time_zone])
    else
      send_at = send_at.utc
    end
    send_at.strftime("%m/%d/%Y %I:%M:%S %p")
  end

  def create_contact_list_request(options)
    options[:visibility] = PRIVATE_VISIBILITY
    silverpop_request("CreateContactList", options)
  end

  def add_recipient_request(options)
    options[:created_from] = OPTED_IN
    options[:column] = { :name => "EMAIL", :value => options[:email] }
    options.delete(:email)
    silverpop_request("AddRecipient", options)
  end

  def opt_out_recipient_request(options)
    silverpop_request("OptOutRecipient", options)
  end

  def add_contact_to_contact_list_request(options)
    options[:column] = { :name => "EMAIL", :value => options[:email] }
    options.delete(:email)
    silverpop_request("AddContactToContactList", options)
  end

  def remove_recipient_request(options)
    silverpop_request("RemoveRecipient", options)
  end

  def select_recipient_request(options)
    options[:return_contact_lists] = "true"
    silverpop_request("SelectRecipientData", options)
  end

  def get_lists_request(options)
    silverpop_request("GetLists", options)
  end

  def api_uri
    @api_uri ||= URI.parse("http://#{@hostname}")
  end

  def request_path
    "/XMLAPI#{@session_encoding}"
  end

  def api_response(request)
    post = Net::HTTP::Post.new(request_path, { "Content-Type" => "text/xml;charset=UTF-8" })
    post.body = wrap_to_xml(request)
    @http.request(post)
  end

  def wrap_to_xml(content)
    { "Body" => content }.to_xml(:root => "Envelope", :dasherize => false)
  end

  def unwrap_from_xml(xml)
    hash = Hash.from_xml(xml)
    hash["Envelope"]["Body"]
  end

  def login_request
    { "Login" => { "USERNAME" => @username, "PASSWORD" => @password }}
  end

  def logout_request
    { "Logout" => "" }
  end

  def validate_options(options, allowed_keys, required_keys)
    options.assert_valid_keys(allowed_keys)
    required_keys.each { |key| raise "Missing option :#{key}" unless options[key].present? }
  end

  def prepare_options_for_silverpop(options)
    return if options.nil?

    if options[:email].present?
      options[:email] = options[:email].downcase
    end
    column = options[:column]
    if column && column[:name].present? && column[:value].present? && column[:name] == "EMAIL"
      column[:value] = column[:value].downcase
    end
    return options
  end

  def silverpop_request(element_name, options)
    options = prepare_options_for_silverpop(options)
    { element_name => recursively_upcase_keys_and_strip_values(options) }
  end

  def recursively_upcase_keys_and_strip_values(hsh)
    convert_hash_for_request(hsh)
  end

  def convert_anything_for_request(v)
    if v.is_a?(Hash)
      convert_hash_for_request(v)
    elsif v.is_a?(String)
      convert_value_for_request(v)
    elsif v.is_a?(Enumerable)
      convert_enumerable_for_request(v)
    else
      convert_value_for_request(v)
    end
  end

  def convert_hash_for_request(hsh)
    result = {}
    hsh.each do |k,v|
      unless v.blank?
        key = k.to_s.upcase
        result[key] = convert_anything_for_request(v)
      end
    end
    result
  end

  def convert_enumerable_for_request(enum)
    result = []
    enum.each do |v|
      result << convert_anything_for_request(v)
    end
    result
  end

  def convert_value_for_request(v)
    v.to_s.strip
  end

end

