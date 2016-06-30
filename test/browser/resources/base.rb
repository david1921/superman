module Resources
  class Base < ActiveResource::Base
    self.site = AppConfig.active_resource_host
    self.user = AppConfig.active_resource_user
    self.password = AppConfig.active_resource_password
    self.timeout = 60*5
  end
end