require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::SyndicationSourcingByPublisherIdsTest

module DailyDeals
  class SyndicationSourcingByPublisherIdsTest < ActiveSupport::TestCase

    context "sourcing by publisher ids" do
      setup do
        @publisher = Factory(:publisher)
      end

      context "syndicated_deal_publisher_ids" do
        setup do
          @daily_deal = Factory(:daily_deal_for_syndication)
          syndicate(@daily_deal, @publisher)
        end

        should "return ids of publishers the deal is syndicated to" do
          assert_equal [@publisher.id], @daily_deal.syndicated_deal_publisher_ids
        end
      end

      context "syndicated_deal_publisher_ids=" do
        context "with a new deal" do
          setup do
            @daily_deal = Factory.build(:daily_deal_for_syndication)
          end

          context "adding a publisher" do
            should "syndicate deal to added publisher" do
              assert_difference "DailyDeal.count", 2 do
                assert_equal [], @daily_deal.syndicated_deal_publisher_ids

                @daily_deal.syndicated_deal_publisher_ids = [@publisher.id]
                @daily_deal.save

                assert @daily_deal.valid?
                assert_equal [@publisher.id], @daily_deal.syndicated_deal_publisher_ids
              end
            end
          end
        end

        context "with a new deal while also setting advertiser and publisher" do
          setup do
            @daily_deal = Factory.build(:daily_deal_for_syndication, :advertiser_id => nil, :publisher_id => nil)
          end

          context "adding a publisher" do
            should "syndicate deal to added publisher" do
              assert_difference "DailyDeal.count", 2 do
                assert_equal nil, @daily_deal.advertiser_id
                assert_equal nil, @daily_deal.publisher_id
                assert_equal [], @daily_deal.syndicated_deal_publisher_ids

                publisher = Factory(:publisher)
                @daily_deal.advertiser = Factory(:advertiser, :publisher => publisher)
                @daily_deal.publisher = publisher
                @daily_deal.syndicated_deal_publisher_ids = [@publisher.id]
                @daily_deal.save

                assert @daily_deal.valid?
                assert_equal [@publisher.id], @daily_deal.syndicated_deal_publisher_ids
              end
            end
          end
        end

        context "with an existing deal" do
          setup do
            @daily_deal = Factory(:daily_deal_for_syndication)
          end

          context "removing a publisher" do
            setup do
              @publisher2 = Factory(:publisher)
              @syndicated_deal1 = syndicate(@daily_deal, @publisher)
              @syndicated_deal2 = syndicate(@daily_deal, @publisher2)
            end

            should "delete syndicated deal from removed publisher" do
              @daily_deal.syndicated_deal_publisher_ids = [@publisher2.id]
              @daily_deal.save
              @daily_deal.reload

              assert @daily_deal.valid?
              assert_equal [@publisher2.id], @daily_deal.syndicated_deal_publisher_ids
              assert_equal nil, @syndicated_deal2.reload.deleted_at
              assert @syndicated_deal1.reload.deleted_at
            end

            should "work with strings as ids" do
              @daily_deal.syndicated_deal_publisher_ids = [@publisher2.id.to_s]
              @daily_deal.save
              @daily_deal.reload

              assert @daily_deal.valid?
              assert_equal [@publisher2.id], @daily_deal.syndicated_deal_publisher_ids
              assert_equal nil, @syndicated_deal2.reload.deleted_at
              assert @syndicated_deal1.reload.deleted_at
            end
          end

          context "adding a publisher" do
            should "syndicate deal to added publisher" do
              assert_difference "DailyDeal.count", 1 do
                @daily_deal.syndicated_deal_publisher_ids = [@publisher.id]
                @daily_deal.save

                assert @daily_deal.valid?
                assert_equal [@publisher.id], @daily_deal.syndicated_deal_publisher_ids
              end
            end
          end
        end
      end
    end

    private

    def syndicate(daily_deal, syndicated_publisher)
      daily_deal.syndicated_deals.build(:publisher_id => syndicated_publisher.id)
      daily_deal.save!
      daily_deal.syndicated_deals.last
    end
  end
end
