require File.dirname(__FILE__) + '/../../../../controllers_helper'

# hydra class Api::ThirdPartyPurchases::CallbackConfigs::FiltersTest

module Api::ThirdPartyPurchases::CallbackConfigs
  class FiltersTest < Test::Unit::TestCase

    def setup
      @obj = Object.new.extend(Api::ThirdPartyPurchases::CallbackConfigs::Filters)
    end

    context "#load_config" do
      should "assign new or existing config to @config" do
        config = mock('config')
        user = mock('user', :id => 123)
        @obj.stubs(:find_or_initialize_config_from_user_id).with(123).returns(config)
        @obj.instance_variable_set(:@user, user)

        @obj.load_config
        assert_equal config, @obj.instance_variable_get(:@config)
      end
    end

  end
end