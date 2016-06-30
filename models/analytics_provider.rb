class AnalyticsProvider < ActiveRecord::Base
  
  class_inheritable_accessor :columns
  self.columns = []

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :id, :integer
  column :name, :string
  column :site_id, :string
  column :partial, :string
  
  validates_presence_of :id
  validates_presence_of :name
  validates_presence_of :site_id
  
  
  def self.analytics_providers
    [
      {
        :id => -1,
        :name => "None", 
        :partial => ''
      },
      {
        :id => 1,
        :name => "SiteCatalyst", 
        :partial => '/shared/site_catalyst'
      },
      {
        :id => 2,
        :name => "Tracking.net",
        :partial => '/shared/tracking_dot_net'
      },
      {
        :id => 3,
        :name => "Facebook",
        :partial => '/shared/facebook'
      }
    ]
  end
  
  def initialize(attributes = {})
    super
    provider(attributes[:id])
    unless valid_service_provider?(attributes[:id])
      self.errors.add(:id, "%{attribute} doesn't exist")
      return
    end
    self.id         = @provider[:id]
    self.name       = @provider[:name]
    self.partial    = @provider[:partial]
  end
  
  def to_param
    self.id.to_s
  end

  private

  def provider(id = nil)
    @provider ||= AnalyticsProvider.analytics_providers.find {|hash| hash[:id] == id}
  end

  def valid_service_provider?(analytics_provider_id)
    !provider.nil?
  end
end
