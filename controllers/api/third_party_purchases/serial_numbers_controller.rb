module Api::ThirdPartyPurchases
  class SerialNumbersController < ApplicationController

    def create
      snreq = Api::ThirdPartyPurchases::SerialNumberRequest.new(:xml => request.body.read, :user => @user)
      snreq.execute
      snresp = Api::ThirdPartyPurchases::SerialNumberResponse.new(:request => snreq)
      render :text => snresp.to_xml
    end

  end
end