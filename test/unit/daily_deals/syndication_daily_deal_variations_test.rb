require File.dirname(__FILE__) + "/../../test_helper"

class SyndicationDailyDealVariationsTest < ActiveSupport::TestCase

	context "daily_deal_variations" do

		setup do
			@source_deal = Factory(:daily_deal_for_syndication)
		end

		context "with no daily deal variations on syndicateable deal" do

			should "should return no daily deal variations" do
				assert @source_deal.daily_deal_variations.empty?, "should be empty"
			end

			context "with a distributed deal" do

				setup do
					@distributed_publisher = Factory(:publisher, :enable_daily_deal_variations => true)
					@distributed_deal = syndicate( @source_deal, @distributed_publisher )
				end

				should "return no daily deal variations" do
					assert @distributed_deal.daily_deal_variations.empty?
				end

			end

		end

		context "with at least one daily deal variations on syndicateable deal" do

			setup do
				@publisher = @source_deal.publisher
				@publisher.update_attribute( :enable_daily_deal_variations, true )

				@variation = Factory(:daily_deal_variation, :daily_deal => @source_deal)				
			end

			should "set @variation in daily deal variations" do
				assert_equal @variation, @source_deal.daily_deal_variations.first
			end

			should "not be syndicated without any distributed deals" do
				assert !@variation.syndicated?
			end

			context "with a distributed deal" do

				setup do
					@distributed_publisher = Factory(:publisher, :enable_daily_deal_variations => true)
					@distributed_deal = syndicate( @source_deal, @distributed_publisher )
				end

				should "varaiation should be syndicated" do
					assert @variation.reload.syndicated?
				end

				should "return source deals variations" do
					assert_equal @source_deal.daily_deal_variations, @distributed_deal.daily_deal_variations
				end

			end

		end

		context "source/distributed deal number sold" do

			setup do
				@publisher = @source_deal.publisher
				@publisher.update_attribute( :enable_daily_deal_variations, true )

				@variation_1 = Factory(:daily_deal_variation, :daily_deal => @source_deal)				
				@variation_2 = Factory(:daily_deal_variation, :daily_deal => @source_deal)

				@distributed_publisher = Factory(:publisher, :enable_daily_deal_variations => true)
				@distributed_deal = syndicate( @source_deal, @distributed_publisher )				
			end

			context "with no sales yet" do

				should "have 0 for number_sold on source deal" do
					assert_equal 0, @source_deal.number_sold
				end

				should "have 0 for number_sold on distributed deal" do
					assert_equal 0, @distributed_deal.number_sold
				end

			end

			context "with just pending sales" do

				setup do
					Factory(:pending_daily_deal_purchase, :daily_deal => @source_deal, :daily_deal_variation => @variation_1)
					Factory(:pending_daily_deal_purchase, :daily_deal => @distributed_deal, :daily_deal_variation => @variation_2)
				end

				should "have 0 for number_sold on source deal" do
					assert_equal 0, @source_deal.number_sold
				end

				should "have 0 for number_sold on distributed deal" do
					assert_equal 0, @distributed_deal.number_sold
				end				

			end

			context "with captured sales" do

				setup do
					Factory(:captured_daily_deal_purchase, :daily_deal => @source_deal, :daily_deal_variation => @variation_1)
					Factory(:captured_daily_deal_purchase, :daily_deal => @source_deal, :daily_deal_variation => @variation_2, :quantity => 2)

					Factory(:captured_daily_deal_purchase, :daily_deal => @distributed_deal, :daily_deal_variation => @variation_2)
				end

				should "have 3 for number sold on source deal" do
					assert_equal 3, @source_deal.number_sold
				end

				should "have 1 for number sold on distributed deal" do
					assert_equal 1, @distributed_deal.number_sold
				end

			end

		end

	end

end