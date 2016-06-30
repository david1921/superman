module Reports::Reporting
  def self.included(base)
    base.class_eval do
      skip_before_filter :enforce_admin_server
      before_filter :enforce_reports_server
    end
  end
end
