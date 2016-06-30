require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::StatusTest < ActiveSupport::TestCase

	context "validations" do

		context "with no value" do

			should "not allow no value, once we start using the status value"

		end

		context "with invalid value" do

			should "not allow 'blah'" do
				advertiser = Factory(:advertiser)
				deal = advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :status => "blah") )
				assert deal.invalid?, "deal should be invalid"
			end

		end

		context "with valid values" do

			setup do
				@advertiser = Factory(:advertiser)				
			end

			should "allow 'Draft'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :status => 'Draft') )
				assert deal.valid?
			end

			should "allow 'Awaiting Approval'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :status => 'Awaiting Approval') )
				assert deal.valid?
			end

			should "allow 'Approved'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :status => 'Approved') )
				assert deal.valid?
			end

			should "allow 'Rejected'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :status => 'Rejected') )
				assert deal.valid?
			end

			should "allow 'Live'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :status => 'Live') )
				assert deal.valid?
			end

			should "allow 'Closed'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :status => 'Closed') )
				assert deal.valid?
			end

			should "allow 'Withdrawn'" do
				deal = @advertiser.daily_deals.build( Factory.attributes_for(:daily_deal, :status => 'Withdrawn') )
				assert deal.valid?
			end

		end

	end

end