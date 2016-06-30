module Api::ThirdPartyPurchases::CallbackConfigs::Core

  def attributes_from_callback_xml(xml)
    data = Hash.from_xml(xml)['callback_config']
    {
        :callback_url => data['url'],
        :callback_username => data['username'],
        :callback_password => data['password']
    }
  end

end