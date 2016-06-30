class Api::ThirdPartyPurchases::ApplicationController < ApplicationController
  include Api::ThirdPartyPurchases::Application::Filters

  skip_before_filter :verify_authenticity_token, :ensure_proper_protocol

  before_filter :perform_http_basic_authentication
  before_filter :strictly_require_ssl

end
