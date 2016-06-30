require File.dirname(__FILE__) + "/../../test_helper"
unless ActiveSupport::Dependencies.autoload_paths.include?(File.expand_path(File.dirname(__FILE__) + "/../../../../helpers"))
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../../../app/helpers")
end
