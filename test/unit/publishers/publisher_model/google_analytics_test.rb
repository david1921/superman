require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::GoogleAnalyticsTest
module Publishers
  module PublisherModel
    class GoogleAnalyticsTest < ActiveSupport::TestCase
      test "google_analytics_ids returns an array of google analytics ids from publisher and publishing group" do
        group_ids = "UA-19396594-1, UA-19396594-2,UA-19396594-3"
        pub_ids = "UA-19396594-4, UA-19396594-5,UA-19396594-6"
        publishing_group = Factory(:publishing_group, :google_analytics_account_ids => group_ids)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :google_analytics_account_ids => pub_ids)
        ids = publisher.google_analytics_ids
        assert_same_elements ['UA-21436942-1', 'UA-19396594-1', 'UA-19396594-2', 'UA-19396594-3', 'UA-19396594-4', 'UA-19396594-5', 'UA-19396594-6'], ids
      end

      test "google_analytics_ids when publishing_group account ids are nil" do
        group_ids = nil
        pub_ids = "UA-19396594-4, UA-19396594-5,UA-19396594-6"
        publishing_group = Factory(:publishing_group, :google_analytics_account_ids => group_ids)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :google_analytics_account_ids => pub_ids)
        ids = publisher.google_analytics_ids
        assert_same_elements ['UA-21436942-1', 'UA-19396594-4', 'UA-19396594-5', 'UA-19396594-6'], ids
      end

      test "google_analytics_ids when publisher account ids are nil" do
        group_ids = "UA-19396594-4, UA-19396594-5,UA-19396594-6"
        pub_ids = nil
        publishing_group = Factory(:publishing_group, :google_analytics_account_ids => group_ids)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :google_analytics_account_ids => pub_ids)
        ids = publisher.google_analytics_ids
        assert_same_elements ['UA-21436942-1', 'UA-19396594-4', 'UA-19396594-5', 'UA-19396594-6'], ids
      end

      test "google_analytics_ids when publishing_group account ids are empty string" do
        group_ids = ""
        pub_ids = "UA-19396594-4, UA-19396594-5,UA-19396594-6"
        publishing_group = Factory(:publishing_group, :google_analytics_account_ids => group_ids)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :google_analytics_account_ids => pub_ids)
        ids = publisher.google_analytics_ids
        assert_same_elements ['UA-21436942-1', 'UA-19396594-4', 'UA-19396594-5', 'UA-19396594-6'], ids
      end

      test "google_analytics_ids when publisher account ids are empty string" do
        group_ids = "UA-19396594-4, UA-19396594-5,UA-19396594-6"
        pub_ids = ""
        publishing_group = Factory(:publishing_group, :google_analytics_account_ids => group_ids)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :google_analytics_account_ids => pub_ids)
        ids = publisher.google_analytics_ids
        assert_same_elements ['UA-21436942-1', 'UA-19396594-4', 'UA-19396594-5', 'UA-19396594-6'], ids
      end

      test "google_analytics_ids when publishing group is not set" do
        pub_ids = "UA-19396594-4, UA-19396594-5,UA-19396594-6"
        publisher = Factory(:publisher, :publishing_group => nil, :google_analytics_account_ids => pub_ids)
        ids = publisher.google_analytics_ids
        assert_same_elements ['UA-21436942-1', 'UA-19396594-4', 'UA-19396594-5', 'UA-19396594-6'], ids
      end
    end
  end
end