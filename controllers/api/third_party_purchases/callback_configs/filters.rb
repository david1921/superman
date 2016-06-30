module Api::ThirdPartyPurchases::CallbackConfigs::Filters

  def load_config
    @config = find_or_initialize_config_from_user_id(@user.id)
  end

  private

  def find_or_initialize_config_from_user_id(user_id)
    ThirdPartyPurchasesApiConfig.find_or_initialize_by_user_id(user_id)
  end

end