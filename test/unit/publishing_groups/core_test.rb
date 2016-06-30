require File.dirname(__FILE__) + "/../../test_helper"

# hydra class PublishingGroups::CoreTest

class PublishingGroups::CoreTest < ActiveSupport::TestCase

  context "#combine_duplicate_consumers!" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher1 = Factory(:publisher, :publishing_group => @publishing_group)
      @publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
      @publisher3 = Factory(:publisher, :publishing_group => @publishing_group)
      @email = "duplicate@publishinggroup.com"
      @user1 = Factory(:consumer, :publisher => @publisher1, :email => @email)
      @user2 = Factory(:consumer, :publisher => @publisher2, :email => @email)
      @user3 = Factory(:consumer, :publisher => @publisher3, :email => @email)
    end

    should "combine consumers with the same email into one consumer and delete the others" do
      @publishing_group.combine_duplicate_consumers!
      Consumer.find(@user1)
      assert_nil Consumer.find_by_id @user2.id
      assert_nil Consumer.find_by_id @user3.id
    end
  end

end