module Consumers
  module Core

    def consumer_strategy(module_constant, name)
      name ||= "default"
      strategy_classname = name.camelize
      module_constant.const_get(strategy_classname).new
    end

  end
end
