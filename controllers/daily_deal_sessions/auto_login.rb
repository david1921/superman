module DailyDealSessions
  module AutoLogin

    # This is a a before_filter for the create action
    # On a get request, flag the password as an md5 password
    # So the authentication system can act accordingly
    def flag_password_as_md5_on_get
      if request.get? && params[:session].present?
        password = params[:session][:password]
        if password.present?
          password.instance_eval do
            def md5?
              true
            end
          end
        end
      end
    end

  end
end
