# Supports auto-login which we use for coolsavings.
module Consumers
  module Md5Password
    # see also auto_login.rb, unfortunately
    def self.md5_password(password)
      return password if password.respond_to?(:md5?) && password.md5?
      password && password.md5
    end
  end
end