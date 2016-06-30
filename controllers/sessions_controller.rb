# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  include Api
  
  ssl_required_if_ssl_rails_environment :new
  ssl_allowed :create, :destroy
  
  before_filter :check_and_set_api_version_header_for_json_requests, :only => [:create]

  def new
    if param = params[:param]
      token = Base64::decode64(param) rescue nil
      user, advertiser = User.authenticate_locm(token)
      set_up_session user
      if user && advertiser
        redirect_to(edit_advertiser_path(advertiser))
      else
        note_failed_signin_locm "param:#{param}" unless user
        render(:action => :locm_login_failure)
      end
    else
      @user = User.new
      @user.login = cookies[:login]
    end
  end

  def create
    create_session_action
  end

  def destroy
    destroy_session_action
    redirect_back_or_default login_path
  end

  protected
  
  def note_failed_signin(identifier, options = {})
    flash[:warn] = options[:message] || I18n.translate(:login_failed_message)
    logger.warn "Authentication failure for '#{identifier}' from #{request.remote_ip}"
  end

  def note_failed_signin_locm(identifier)
    flash[:warn] = "No such account"
    logger.warn "Authentication failure for '#{identifier}' from #{request.remote_ip}"
  end

  def verify_authenticity_token
    unless verified_request? || request.format.json?
      user_params = params[:user] || {}
      note_failed_signin "login:#{user_params[:login]}"
      @user = User.new(user_params)
      flash[:warn] = "Could not login you in. Are cookies enabled in your web browser?"
      render :new
    end
  end
end
