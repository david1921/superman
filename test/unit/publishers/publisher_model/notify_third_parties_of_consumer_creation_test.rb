require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::NotifyThirdPartiesOfConsumerCreationTest
module Publishers
  module PublisherModel
    class NotifyThirdPartiesOfConsumerCreationTest < ActiveSupport::TestCase
      context "#notify_third_parties_of_consumer_creation?" do
        
        should "use publisher group setting if a pub group exists and the setting is true" do
          publishing_group = Factory(:publishing_group, :notify_third_parties_of_consumer_creation => true)
          publisher = Factory(:publisher, :publishing_group_id => publishing_group.id, :notify_third_parties_of_consumer_creation => false)
          assert_equal true, publisher.notify_third_parties_of_consumer_creation?
        end

        should "abide by a true at the publisher level even if the value is false at the group level" do
          publishing_group = Factory(:publishing_group, :notify_third_parties_of_consumer_creation => false)
          publisher = Factory(:publisher, :publishing_group_id => publishing_group.id, :notify_third_parties_of_consumer_creation => true)
          assert_equal true, publisher.notify_third_parties_of_consumer_creation?
        end

        should "return false is all is false" do
          publishing_group = Factory(:publishing_group, :notify_third_parties_of_consumer_creation => false)
          publisher = Factory(:publisher, :publishing_group_id => publishing_group.id, :notify_third_parties_of_consumer_creation => false)
          assert_equal false, publisher.notify_third_parties_of_consumer_creation?
        end

        should "not fail if the publisher is not a member of a publishing group" do
          publisher = Factory(:publisher, :notify_third_parties_of_consumer_creation => true)
          assert_equal true, publisher.notify_third_parties_of_consumer_creation?
          publisher.update_attribute("notify_third_parties_of_consumer_creation", false)
          assert_equal false, publisher.notify_third_parties_of_consumer_creation?
        end

      end
    end
  end
end