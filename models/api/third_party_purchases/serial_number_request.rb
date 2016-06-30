module Api::ThirdPartyPurchases
  class SerialNumberRequest < ActiveRecordWithoutTable
    include SerialNumberRequests::Core
    include SerialNumberRequests::Validations

    attr_writer :xml, :user
    attr_reader :purchase, :store, :daily_deal, :daily_deal_listing, :executed_at, :doc

    validate :validate_xml
    validate :validate_daily_deal_listing
    validate :validate_executed_at
    validate :validate_store
    validate :validate_deal_availability

    before_validation :set_doc_from_xml
  end
  #ge
end
