class Syndication::SessionsController < Syndication::ApplicationController
  skip_before_filter :user_required, :require_syndication_ui_access

  def new
    session[:return_to] = list_syndication_deals_path
    render 'sessions/new'
  end

  def create
    create_session_action
  end

  def destroy
    destroy_session_action
    redirect_back_or_default syndication_login_path
  end

  protected

  def note_failed_signin(identifier)
    flash[:error] = I18n.translate(:login_failed_message)
    logger.warn "Authentication failure for '#{identifier}' from #{request.remote_ip}"
  end
end
