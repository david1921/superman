require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::AssociationsTest
module Publishers
  module PublisherModel
    class AssociationsTest < ActiveSupport::TestCase
      should "have and belong to many publishers excluded from distribution" do
        publisher = Factory(:publisher)
        assert_equal [], publisher.publishers_excluded_from_distribution
        publisher.publishers_excluded_from_distribution = excluded = [Factory(:publisher), Factory(:publisher)]
        assert_equal excluded, publisher.publishers_excluded_from_distribution(true)
      end

      should "have and belong to many publishers unavailable for distribution" do
        publisher = Factory(:publisher)
        assert_equal [], publisher.publishers_unavailable_for_distribution
        publisher.publishers_unavailable_for_distribution = unavailable = [Factory(:publisher), Factory(:publisher)]
        assert_equal unavailable, publisher.publishers_unavailable_for_distribution(true)
      end
    end
  end
end