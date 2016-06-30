module Api::ThirdPartyPurchases::Application::Filters

  def set_xml_format
    request.format = :xml
  end

end