module Api::ThirdPartyPurchases
  class CallbackConfigsController < ApplicationController
    include Api::ThirdPartyPurchases::CallbackConfigs::Filters
    include Api::ThirdPartyPurchases::CallbackConfigs::Core

    before_filter :load_config, :set_xml_format

    def show; end

    def create
      @config.update_attributes(attributes_from_callback_xml(request.body.read))

      render :show
    end

  end
end
