# Allows Objects to be used as is as Liquid drops.
#
# Usage: 
#
# class Numeric
#   include Liquid::Droppable
# end
#
module Liquid
  module Droppable
    attr_writer :context

    # called by liquid to invoke a drop
    def invoke_drop(method)
      # for backward compatibility with Ruby 1.8
      methods = self.class.public_instance_methods.map { |m| m.to_s }
      if methods.include?(method.to_s)
        send(method.to_sym)
      end
    end

    def has_key?(name)
      true
    end

    def to_liquid
      self
    end

    alias :[] :invoke_drop
  end
end
