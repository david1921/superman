# Simulate outbound TXT gateway.
#
# In production:
# Sender -> CellTrust
#
# In development/test:
# Sender -> TxtGatewayMessagesController
class TxtGatewayMessagesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # Receive outbound txt msg responses from our system intended for visitor handsets
  # Expects CellTrust HTTP format
  def create
    if params["CustomerNickname"] != "TOMCTA"
      render :xml => %Q{
        <TxTNotifyResponse> 
            <Error> 
                <ErrorCode>201</ErrorCode> 
                <ErrorMessage>Customer Nickname is not valid</ErrorMessage> 
            </Error> 
        </TxTNotifyResponse>
      }, :status => 422
      return
    end

    if params["CustomerNickname"] != "TOMCTA"
      render :xml => %Q{
        <TxTNotifyResponse> 
            <Error> 
                <ErrorCode>201</ErrorCode> 
                <ErrorMessage>Customer Nickname is not valid</ErrorMessage> 
            </Error> 
        </TxTNotifyResponse>
      }, :status => 422
      return
    end

    if params["Message"].blank? || params["PhoneDestination"].blank? || params["XMLResponse"].blank?
      render :xml => %Q{
        <TxTNotifyResponse> 
            <Error> 
                <ErrorCode>201</ErrorCode> 
                <ErrorMessage>Expected Message, PhoneDestination, AdminEmail, and XMLResponse</ErrorMessage> 
            </Error> 
        </TxTNotifyResponse>
      }, :status => 422
      return
    end

    # Recording the outbound message could be a bottleneck, but this CellTrust's gateway has a 400ms lag, so it's realistic.
    # CellTrust can receive messages asynchronously, so an even more realistic test would have several Mongrels behind
    # an HTTP proxy.
    TxtGatewayMessage.create!(
      :message => params["Message"],
      :mobile_number => params["PhoneDestination"],
      :accepted_time => Time.now
    )
    
    render :xml => %Q{
      <TxTNotifyResponse> 
          <MsgResponseList> 
              <MsgResponse type="SMS"> 
                 <Status>ACCEPTED</Status> 
                 <MessageId>#{random_message_id}</MessageId> 
              </MsgResponse> 
          </MsgResponseList> 
      </TxTNotifyResponse> 
    }
  end
  
  # How many outbound TXT message requests have you received from our TXT sender?
  def count
    render :xml => "<count>#{TxtGatewayMessage.count}</count>"
  end

  def delete_all
    render :xml => "<result>#{TxtGatewayMessage.delete_all}</result>"
  end
  
  def random_message_id
    "AAXF#{(rand * 1_000_000_000).to_i}PM#{(rand * 10_000).to_i}"
  end
end