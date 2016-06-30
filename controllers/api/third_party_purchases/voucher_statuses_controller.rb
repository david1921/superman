module Api::ThirdPartyPurchases
  class VoucherStatusesController < ApplicationController
    include Api::ThirdPartyPurchases::VoucherStatuses::Filters
    include Api::ThirdPartyPurchases::VoucherStatuses::Core

    before_filter :load_certificates, :set_xml_format

    def index
    end

    def create
      update_certificate_statuses(@certificates)
      render :index
    end
  end
end
