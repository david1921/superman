require File.dirname(__FILE__) + "/../../test_helper"
$:.insert(0, File.expand_path(File.dirname(__FILE__) + "/../stubs/controllers"))
unless ActiveSupport::Dependencies.autoload_paths.include?(File.expand_path(File.dirname(__FILE__) + "/../../../../controllers"))
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../../../app/controllers")
end
unless ActiveSupport::Dependencies.autoload_paths.include?(File.expand_path(File.dirname(__FILE__) + "/../../../../app/helpers"))
  ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../../../../app/helpers")
end

module AuthenticatedSystem; end
module SslRequirement; end
module Analog
  module SslRequirement; end
end
