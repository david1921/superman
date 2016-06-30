require 'net/http'

class MailChimp
  API_HOST = proc { |data_center| "#{data_center}.api.mailchimp.com" }
  
  def initialize(options)
    raise ArgumentError, "missing required argument :apikey" unless options.has_key?(:apikey)

    @api_key = options[:apikey]
    @api_host = API_HOST.call(@api_key.match(/\-(.+$)/)[1])
    @conn = Net::HTTP.new(@api_host)
  end  

  def list_batch_subscribe(options)
    return unless options.has_key?(:emails)
    raise ArgumentError, "missing required list id for batch subscribe" unless options.has_key?(:id)
    
    api_args = {
      :apikey => @api_key, 
      :batch => format_emails_for_mailchimp(options[:emails])
    }.merge(options.slice(:api_key, :id, :double_optin, :update_existing, :replace_interests))

    result = listBatchSubscribe(api_args)
    
    { :added => result["add_count"].to_i,
      :updated => result["update_count"].to_i,
      :errors => (result["errors"].map { |e| "(#{e['email']}) Error [#{e['code']}]: #{e['message']}" }) || [] }
  end
  
  def lists_by_name(name)
    return [] if name.blank?
    
    api_args = { :apikey => @api_key, :filters => { :list_name => name } }
    result = lists(api_args)
    
    if result["total"] > 0
      result["data"].map do |list_info|
        mcl = MailChimp::List.new(
          list_info.slice(*%w(id name date_created default_from_name default_from_email default_subject)).symbolize_keys)
        mcl.member_count = list_info["stats"]["member_count"]
        mcl
      end
    else
      []
    end
  end
  
  private
  
  def format_emails_for_mailchimp(emails)
    emails.map { |email| { :EMAIL => email, :EMAIL_TYPE => "html" } }
  end
  
  def call_api_method(meth_name, params)
    raise ArgumentError, "expected params to be a Hash. got #{params.class}" unless params.is_a?(Hash)    
    response = @conn.post(api_path_for(meth_name), CGI.escape(params.merge(:apikey => @api_key).to_json))
    ActiveSupport::JSON.decode(response.body)
  end
  
  def method_missing(meth_name, *args)
    call_api_method(meth_name, *args)
  end
  
  def api_path_for(meth_name)
    "/1.3/?method=#{meth_name}"
  end
  
  class List

    attr_accessor :id, :name, :date_created, :default_from_name, :default_from_email,
                  :default_subject, :member_count

    def initialize(options)
      the_list = self
      options.each_pair { |key, value| the_list.send(:"#{key}=", value) }
    end
    
  end
  
end