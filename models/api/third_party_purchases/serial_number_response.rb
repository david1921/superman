module Api::ThirdPartyPurchases
  class SerialNumberResponse < ActiveRecordWithoutTable
    include SerialNumberResponses::Core

    attr_accessor :request

  end
end
