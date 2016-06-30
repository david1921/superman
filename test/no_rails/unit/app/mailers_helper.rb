require File.dirname(__FILE__) + "/../../test_helper"
unless ActiveSupport::Dependencies.load_paths.include?(File.expand_path(File.dirname(__FILE__) + "/../../../../mailers"))
  ActiveSupport::Dependencies.load_paths << File.expand_path(File.dirname(__FILE__) + "/../../../../app/mailers")
end
