module AuthenticatedSystem
  include PurchaseSession
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      current_user.present?
    end

    # Accesses the current user from the session.
    # Future calls avoid the database because nil is not equal to false.
    def current_user
      @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie)
      time_out_session

      if @current_user.try(:locked_at)
        @current_user = nil
      end

      User.current = @current_user
      @current_user
    end

    # Store the given user id in the session.
    def current_user=(new_user)
      if new_user.try(:locked_at)
        new_user = nil
      end

      session[:user_id] = new_user ? new_user.id : nil
      User.current = new_user
      @current_user = new_user
    end

    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.email != "bob"
    #  end
    #
    def authorized?(action=nil, resource=nil, *args)
      logged_in? && current_user.administrator?
    end

    # Filter method to enforce a login requirement.
    #
    # To require User logins for all actions, use this in your controllers:
    #
    #   before_filter :user_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :user_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :user_required
    #
    def user_required
      authorized? || access_denied
    end

    def consumer_required
      (logged_in? && Consumer === current_user) || access_denied
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied(message = "Unauthorized access")
      respond_to do |format|
        format.any(:html, :pdf) do
          store_location
          flash[:notice] = message
          redirect_to new_session_url(params[:param] ? { :param => params[:param] } : {})
        end
        # format.any with no params causes problems with IE 7
        # Sometimes, browser HTTP requests are identidied as AJAX calls,
        # and Rails asks for basic HTTP authentication via a 491
        format.any(:js, :json, :xml) do
          request_http_basic_authentication "Remote API Password"
        end
      end
    end

    def access_forbidden
      render :nothing => true, :status => :forbidden
    end

    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.  Set an appropriately modified
    #   after_filter :store_location, :only => [:index, :new, :show, :edit]
    # for any controller you want to be bounce-backable.
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?, :authorized? if base.respond_to? :helper_method
    end

    #
    # Login
    #

    # Called from #current_user.  First attempt to login by the user id stored in the session.
    def login_from_session
      if session[:user_id]
        self.current_user = User.find_by_id_and_active_session_token(session[:user_id], session[:active_session_token])
      end
    end

    def login_from_basic_auth
      authenticate_with_http_basic do |email, password|
        auth_result = User.authenticate(email, password)
        self.current_user = auth_result.is_a?(User) ? auth_result : nil
      end
    end

    def login_from_cookie
      user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        self.current_user = user
        handle_remember_cookie! false # freshen cookie token (keeping date)
        self.current_user
      end
    end

    # This is ususally what you want; resetting the session willy-nilly wreaks
    # havoc with forgery protection, and is only strictly necessary on login.
    # However, **all session state variables should be unset here**.
    def logout_keeping_session!
      # Kill server-side auth cookie
      if @current_user && @current_user.is_a?(User)
        @current_user.forget_me 
        Exceptional.handle(Exception.new("User record #{@current_user.id} was invalid in #logout_keeping_session!.")) if @current_user.invalid?
        @current_user.reset_active_session_token!
      end
      @current_user = nil       # not logged in, and don't do it for me
      kill_remember_cookie!     # Kill client-side auth cookie
      session[:user_id] = nil   # keeps the session but kill our variable
      kill_purchase_session!
      # explicitly kill any other session variables you set
    end

    # The session should only be reset at the tail end of a form POST --
    # otherwise the request forgery protection fails. It's only really necessary
    # when you cross quarantine (logged-out to logged-in).
    def logout_killing_session!
      logout_keeping_session!
      reset_session
    end

    #
    # Remember_me Tokens
    #
    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    def valid_remember_cookie?
      return nil unless @current_user
      (@current_user.remember_token?) &&
        (cookies[:auth_token] == @current_user.remember_token)
    end

    # Refresh the cookie auth token if it exists, create it otherwise
    def handle_remember_cookie! new_cookie_flag
      return unless @current_user
      case
      when valid_remember_cookie? then @current_user.refresh_token # keeping same expiry date
      when new_cookie_flag        then @current_user.remember_me_for(1.year)
      else
        @current_user.forget_me
        Exceptional.handle(Exception.new("User record #{@current_user.id} was invalid in #handle_remember_cookie!.")) if @current_user.invalid?
      end
      send_remember_cookie!
      cookies[:login] = {
        :value  => @current_user.login,
        :secure => https_only_host?
      }
    end

    def kill_remember_cookie!
      cookies.delete :auth_token
    end

    def send_remember_cookie!
      cookies[:auth_token] = {
        :value   => @current_user.remember_token,
        :expires => @current_user.remember_token_expires_at
      }
    end

    def set_up_session(user, remember_me=false)
      logout_keeping_session!
      if user
        session[:active_session_token] = user.active_session_token
        self.current_user = user
        handle_remember_cookie! remember_me
        flash[:notice] = I18n.t(:login_welcome_message, :name => user.name)

        session[:time_out_at] ||= Time.now + @current_user.session_timeout if @current_user.session_timeout > 0
        #
        # Enforce one-time login for non-admin users having session timeout
        #
        user.randomize_password! if !user.has_admin_privilege? && user.session_timeout > 0
      end
    end

    def create_session_action
      user_params = params[:user] || {}
      auth_result = User.authenticate(user_params[:login].try(:strip), user_params[:password])
      if auth_result.is_a?(User)
        @user = auth_result
        logger.info "Authentication success for '#{@user}'"
        @user.log_action("login", request.remote_ip)
      else
        @user = nil
        if auth_result == :locked
          note_failed_signin "login:#{user_params[:login]}", :message => I18n.t(:user_account_locked)
        else
          note_failed_signin "login:#{user_params[:login]}"
        end
      end

      respond_to do |format|
        format.html do
          remember_me = (user_params[:remember_me_flag] == "1")
          set_up_session @user, remember_me
          if @user
            flash.discard
            redirect_back_or_default('/')
          else
            @user = User.new(user_params)
            render 'sessions/new'
          end
        end
        format.json do
          if @user
            @session = api_session_for_user(@user)
            render :layout => false
          else
            render :nothing => true, :status => :not_found
          end
        end
      end
    end

    def destroy_session_action
      unless self.current_user.nil?
        self.current_user.log_action("logout", request.remote_ip)

        name = self.current_user.name
        logout_killing_session!
        flash[:notice] = "Goodbye #{name}"
      end
    end

  private

    def time_out_session
      if @current_user
        session[:time_out_at] ||= Time.now + @current_user.session_timeout if @current_user.session_timeout > 0

        if !@current_user.has_admin_privilege? && session[:time_out_at] && Time.now >= session[:time_out_at]
          logout_keeping_session!
        end
      end
    end
end
