require File.dirname(__FILE__) + "/../../models_helper"

# hydra class PublishingGroups::CoreTest
module PublishingGroups
  class CoreTest < Test::Unit::TestCase

    def setup
      @publishing_group = stub().extend(PublishingGroups::Core::InstanceMethods)
      @publishing_group.stubs(:say)
      @publishing_group.instance_eval do
        def in_transaction(&block)
          yield
        end
      end
    end

    context "#combine_duplicate_consumers!" do
      should "assimilate and destroy left over" do
        yo1 = mock
        yo2 = mock
        yo3 = mock
        joe1 = mock
        joe2 = mock
        joe3 = mock
        duplicates = {
          "yo@yahoo.com" => [yo1, yo2, yo3],
          "joe@yahoo.com" => [joe1, joe2, joe3]
        }
        yo1.expects(:assimilate!).with(yo2)
        yo1.expects(:assimilate!).with(yo3)
        joe1.expects(:assimilate!).with(joe2)
        joe1.expects(:assimilate!).with(joe3)
        yo2.expects(:force_destroy)
        yo3.expects(:force_destroy)
        joe2.expects(:force_destroy)
        joe3.expects(:force_destroy)
        @publishing_group.stubs(:consumers_grouped_by_duplicated_email).returns(duplicates)
        @publishing_group.combine_duplicate_consumers!
      end

      should "not do much if there are no customers to combine" do
        @publishing_group.stubs(:consumers_grouped_by_duplicated_email).returns({})
        @publishing_group.combine_duplicate_consumers!
      end

    end

  end
end

