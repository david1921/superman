require File.dirname(__FILE__) + "/../../test_helper"

class HasConfigurablePropertiesTest < ActiveSupport::TestCase
  context "an instance of a class with a configurable property" do
    setup do
      @configurable_class = Class.new
      @configurable_class.send(:include, HasConfigurableProperties)
      @configurable_class.configurable_property :foo

      @instance = @configurable_class.new
      @instance.stubs(:label => "mylabel")
    end
    
    should "return nil for the configurable property when no config file exists" do
      File.expects(:exists?).with("#{Rails.root}/config/themes/mylabel/foo.yml").returns(false)
      File.expects(:exists?).with("#{Rails.root}/config/themes/default/foo.yml").returns(false)
      File.expects(:read).never

      assert_nil @instance.foo, "Should return nil with no config file present"
    end
    
    context "having a parent association" do
      setup do
        @configurable_class.configurable_property_parent :parent
        @instance.stubs(:parent).returns(stub(:label => "ptlabel"))
      end

      should "return nil from value_from_config_file when there is a parent association and no config file exists" do
        File.expects(:exists?).with("#{Rails.root}/config/themes/mylabel/foo.yml").returns(false)
        File.expects(:exists?).with("#{Rails.root}/config/themes/ptlabel/foo.yml").returns(false)
        File.expects(:exists?).with("#{Rails.root}/config/themes/default/foo.yml").returns(false)
        File.expects(:read).never
        
        assert_nil @instance.foo, "Should return nil with no config file present"
      end
      
      context "and configuration file contents" do
        setup do
          @contents = <<-EOF
            foo: bar
            baz: <%= Time.now.to_formatted_s(:db) %>
          EOF
          @instant_1 = Time.parse("Jan 15, 2012 12:34:56")
          @instant_2 = Time.parse("Jan 16, 2012 00:00:00")
          @expected_value = { "foo" => "bar", "baz" => "2012-01-15 12:34:56" }
        end

        should "always return the value from the first invocation of value_from_config_file when the instance-label file exists" do
          File.expects(:exists?).with("#{Rails.root}/config/themes/mylabel/foo.yml").returns(true)
          File.expects(:read).once.with("#{Rails.root}/config/themes/mylabel/foo.yml").returns(@contents)
          
          File.expects(:exists?).with("#{Rails.root}/config/themes/ptlabel/foo.yml").never
          File.expects(:exists?).with("#{Rails.root}/config/themes/default/foo.yml").never

          Timecop.freeze(@instant_1) { assert_equal @expected_value, @instance.foo }
          Timecop.freeze(@instant_2) { assert_equal @expected_value, @instance.foo }
        end

        should "always return the value from the first invocation of value_from_config_file when only the parent-label file exists" do
          File.expects(:exists?).with("#{Rails.root}/config/themes/mylabel/foo.yml").returns(false)
          
          File.expects(:exists?).with("#{Rails.root}/config/themes/ptlabel/foo.yml").returns(true)
          File.expects(:read).once.with("#{Rails.root}/config/themes/ptlabel/foo.yml").returns(@contents)
          
          File.expects(:exists?).with("#{Rails.root}/config/themes/default/foo.yml").never

          Timecop.freeze(@instant_1) { assert_equal @expected_value, @instance.foo }
          Timecop.freeze(@instant_2) { assert_equal @expected_value, @instance.foo }
        end

        should "always return the value from the first invocation of value_from_config_file when only the default file exists" do
          File.expects(:exists?).with("#{Rails.root}/config/themes/mylabel/foo.yml").returns(false)
          File.expects(:exists?).with("#{Rails.root}/config/themes/ptlabel/foo.yml").returns(false)
          
          File.expects(:exists?).with("#{Rails.root}/config/themes/default/foo.yml").returns(true)
          File.expects(:read).once.with("#{Rails.root}/config/themes/default/foo.yml").returns(@contents)

          Timecop.freeze(@instant_1) { assert_equal @expected_value, @instance.foo }
          Timecop.freeze(@instant_2) { assert_equal @expected_value, @instance.foo }
        end
      end
    end
  end
end
