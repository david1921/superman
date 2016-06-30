require File.dirname(__FILE__) + "/../../models_helper"

# hydra class Sanctions::BaseFileJobTest

module Sanctions
  class BaseFileJobTest < Test::Unit::TestCase
    should "set the queue to :sanctions_file_uploads" do
      assert_equal :sanctions_file_uploads, BaseFileJob.instance_variable_get(:@queue)
    end

    context "self.perform" do
      should "raise an exception" do
        assert_raise RuntimeError do
          BaseFileJob.perform("passphrase")
        end
      end
    end
  end
end