class Api::ThirdPartyPurchases::SoldOutPushNotification

  attr_reader :deal

  @queue = :sold_out_push_notifications

  def initialize(deal)
    @deal = deal
  end

  def perform
    xml = forced_closure_xml
    complete_api_configs.each do |config|
      self.class.post_xml(xml, config.callback_url, config.callback_username, config.callback_password)
    end
  end

  def forced_closure_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.forced_closure do
        xml.daily_deal_listing deal.listing
      end
    end.to_xml
  end


  class << self
    def perform(deal_id)
      new(DailyDeal.find(deal_id)).perform
    end

    def post_xml(xml, url, username, password)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.path + '?' + (uri.query || ''), {"Content-Type" => "application/xml"})
      request.basic_auth username, password
      request.body = xml
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.request(request)
    end
  end

  private

  def complete_api_configs
    ThirdPartyPurchasesApiConfig.with_complete_callback_config
  end

end