require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::SourceChannelTest < ActiveSupport::TestCase

	context "validations" do

		context "with no value" do

			should "not allow no value, once we start using the status value"

		end

		context "with invalid value" do

			should "not allow 'blah'" do
				advertiser = Factory(:advertiser)
				deal = advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :source_channel => "blah") )
				assert deal.invalid?, "deal should be invalid"
			end

		end

		context "with valid values" do

			setup do
				@advertiser = Factory(:advertiser)				
			end

			should "allow 'self-serve'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :source_channel => 'self-serve') )
				assert deal.valid?
			end

			should "allow 'electronic face-to-face'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :source_channel => 'electronic face-to-face') )
				assert deal.valid?
			end

			should "allow 'paper face-to-face'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :source_channel => 'paper face-to-face') )
				assert deal.valid?
			end

			should "allow 'telephone'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :source_channel => 'telephone') )
				assert deal.valid?
			end

		end

	end

end