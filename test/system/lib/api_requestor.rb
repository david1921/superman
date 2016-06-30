class ApiRequestor
  include Test::Unit::Assertions

  attr_accessor :publisher_label
  
  def initialize(options)
    @publisher_label = options[:publisher_label]
  end
  
  def self.new_with_random_type(publisher)
    if rand(10) < 4
      TxtApiRequestor.new(
        :publisher_label => publisher.label,
        :mobile_number => "6266745901",
        :message => "api test message"
      )
    else
      CallApiRequestor.new(
        :publisher_label => publisher.label,
        :consumer_phone_number => "6266745901",
        :merchant_phone_number => "8005551212"
      )
    end
  end
  
  def invoke(service, params)
    uri = api_service_uri(service)
    req = Net::HTTP::Post.new(uri.path, { 'API-Version' => '1.0.0' })
    req.basic_auth 'gharalam@moreyinteractive.com', 'secret'
    req.set_form_data params.merge({ :publisher_label => publisher_label })
    Net::HTTP.new(uri.host, uri.port).start { |http| http.request(req) }
  end

  def api_service_uri(service)
    @api_service_uri ||= {}
    @api_service_uri[service] ||= URI.parse("http://#{AppConfig.receiver_address}:#{AppConfig.receiver_port}/super-banner/#{service}")
  end
end
