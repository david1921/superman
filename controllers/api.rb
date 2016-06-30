module Api
  def self.included(base)
    base.send :include, Api::Authentication
    base.send :include, Api::Versioning
    base.send :include, Api::Consumers
  end
end
