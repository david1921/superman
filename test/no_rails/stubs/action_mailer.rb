module ActionMailer
  class Base
    def self.helper(*args); end

    def self.default_url_options
      {}
    end
  end
end
