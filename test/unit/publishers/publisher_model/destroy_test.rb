require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::PublisherModel::DestroyTest
module Publishers
  module PublisherModel
    class DestroyTest < ActiveSupport::TestCase
      test "destroy destroys dependent users" do
        publisher = publishers(:gvnews)
        users = publisher.users
        assert users.size > 0, "Publisher fixture should have at least one user"

        publisher_id = publisher.id
        publisher.destroy
        assert     !Publisher.exists?( publisher_id )
        assert_nil Publisher.find_by_name(publisher.name), "Publisher should no longer exist"
        users.each { |user| assert_nil User.find_by_email(user.email), "User #{user.name} should no longer exist" }
      end

      test "destroy without being in publisher group" do
        publisher = Factory(:publisher,  :name => "New Publisher" )
        assert !publisher.new_record?

        publisher_id = publisher.id
        publisher.destroy
        assert !Publisher.exists?( publisher_id )

      end

      test "destroy without being in publisher group and having an advertiser" do
        publisher = Factory(:publisher,  :name => "New Publisher" )
        assert !publisher.new_record?

        publisher.advertisers.create!( :name => "Advertiser" )

        publisher.reload

        assert_equal 1, publisher.advertisers.size

        publisher_id = publisher.id
        publisher.destroy

        assert !Publisher.exists?( publisher_id )
      end

      # Will delete PublishingGroup:
      # publisher.publishing_group = publishing_group
      # publisher.save!
      test "destroy empty publishing groups" do
        publishing_group = PublishingGroup.create!(:name => "Gannet")
        publisher = publishing_group.publishers.create!(:name => "Publisher Name")

        assert PublishingGroup.exists?(:name => "Gannet"), "PublishingGroup should not be destroyed"
        assert_equal publishing_group, publisher.publishing_group(true), "PublishingGroup should not be destroyed"
      end

      test "destroy should not destroy publisher with daily deal purchases" do
        daily_deals_purchase = Factory(:pending_daily_deal_purchase)
        publisher = Publisher.find(daily_deals_purchase.publisher.id)
        assert !publisher.destroy, "Should not destroy publisher"
        assert DailyDeal.exists?(daily_deals_purchase.daily_deal.id), "Should not delete DailyDeal"
        assert DailyDealPurchase.exists?(daily_deals_purchase.id), "Should not delete DailyDealPurchase"
      end
    end
  end
end