class AuthorizeController < ApplicationController
  include FacebookAuth
  
  before_filter :set_publisher
  before_filter :block_bots!
  
  def init
    redirect_to client(params[:rails_env]).web_server.authorize_url(
      :redirect_uri => auth_callback_url(@publisher),
      :scope => 'email,offline_access,publish_stream,user_birthday'
      )
  end

  def callback
    case params[:error_reason]
    when "user_denied"
      redirect_to public_deal_of_day_path(@publisher.label)
    else
      facebook_signin(@publisher, access_token_from_code(params[:code]))      
      redirect_back_or_default public_deal_of_day_path(@publisher.label)
    end
  end
  
  private
  
  def set_publisher
    @publisher = Publisher.find(params[:publisher_id])
  end
  
  def client(rails_env)
    FacebookAuth.oauth2_client(@publisher, rails_env || Rails.env)
  end
  
  def access_token_from_code(code)
    begin
      client(params[:rails_env]).web_server.get_access_token(code, :redirect_uri => auth_callback_url(@publisher), :parse_json => true)
    rescue
      nil
    end
  end
  
end
