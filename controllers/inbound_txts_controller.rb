class InboundTxtsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create    
    InboundTxt.create_from_gateway!(params)
    render :text => "ok", :status => 200
  end
end
