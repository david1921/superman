require File.dirname(__FILE__) + "/../../test_helper"
unless ActiveSupport::Dependencies.autoload_paths.include?(File.expand_path(File.dirname(__FILE__) + "/../../../../models"))
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../../../app/models")
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../../../app/models/users")
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../../../app/models/daily_deals")
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../../../app/mailers")
end
