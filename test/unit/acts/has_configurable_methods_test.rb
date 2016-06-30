require File.dirname(__FILE__) + "/../../test_helper"

class HasConfigurableMethodsTest < ActiveSupport::TestCase
  context "instances of a class with a configurable method having a parent association" do
    setup do
      @configurable_class = Class.new
      @configurable_class.send(:include, HasConfigurableMethods)
      @configurable_class.configurable_method :foo, :key => :key, :parent => :parent

      @instances = []
      
      @instances[0] = @configurable_class.new

      @instances[1] = @configurable_class.new
      @instances[1].stubs(:key => "object1")

      @instances[2] = @configurable_class.new
      @instances[2].stubs(:key => "object2")

      @instances[3] = @configurable_class.new
      @instances[3].stubs(:parent => stub(:key => "parent1"))

      @instances[4] = @configurable_class.new
      @instances[4].stubs(:key => "object1", :parent => stub(:key => "parent1"))

      @instances[5] = @configurable_class.new
      @instances[5].stubs(:key => "object2", :parent => stub(:key => "parent1"))

      @instances[6] = @configurable_class.new
      @instances[6].stubs(:parent => stub(:key => "parent2"))

      @instances[7] = @configurable_class.new
      @instances[7].stubs(:key => "object1", :parent => stub(:key => "parent2"))

      @instances[8] = @configurable_class.new
      @instances[8].stubs(:key => "object2", :parent => stub(:key => "parent2"))
    end

    should "return nil for the configurable method when no method definitions is configured" do
      @instances.each_with_index { |instance, i| assert_nil instance.foo, "Should return nil with no method definition for instance #{i}" }
    end
    
    context "and method definitions configured" do
      setup do
        @configurable_class.configurable_methods_for "object2" do
          def foo
            "bar"
          end
        end

        @configurable_class.configurable_methods_for "parent2" do
          def foo
            "baz"
          end
        end
      end

      should "return nil or the configured value from the method" do
        assert_nil @instances[0].foo, "Should return nil with no key and no parent"
        assert_nil @instances[1].foo, "Should return nil with a key mismatch and no parent"
        assert_equal "bar", @instances[2].foo, "Should return the configured value with a key match and no parent"
        assert_nil @instances[3].foo, "Should return nil with no key and parent key mismatch"
        assert_nil @instances[4].foo, "Should return nil with a key mismatch and parent key mismatch"
        assert_equal "bar", @instances[5].foo, "Should return the configured value with a key match and parent key mismatch"
        assert_equal "baz", @instances[6].foo, "Should return the configured value with no key and parent key match"
        assert_equal "baz", @instances[7].foo, "Should return the configured value with key mismatch and parent key match"
        assert_equal "bar", @instances[8].foo, "Should return the configured value with key match and parent key match"
      end
    end
  end
end
