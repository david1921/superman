require File.dirname(__FILE__) + "/../../presenters_helper"

class Presenters::Versions::AdvertiserTest < Test::Unit::TestCase

	context "initialize" do

		should "raise MissingAdvertiserException is no advertiser is given" do
			assert_raises Presenters::Versions::Advertiser::MissingAdvertiserException do
				Presenters::Versions::Advertiser.new(nil)
			end
		end

	end

	context "by_date" do

		context "with no versions" do

			setup do
				@advertiser = OpenStruct.new(
					:versions => [],
					:stores => [],
					:translations => []
				)
			end

			should "return empty array" do
				assert Presenters::Versions::Advertiser.new(@advertiser).by_date.empty?
			end

		end

		context "with versions on the main advertiser record" do

			setup do
				@versions = []

				@version_1 = build_version( "May 24 15:55:18 -0700 2012", {"email_address" => ["", "changed@emailaddress.com"]} )
				@version_2 = build_version( "Jun 01 15:55:18 -0700 2012", {"email_address" => ["changed@emailaddress.com", "new@emailaddress.com"]} )

				@versions.push(@version_1)
				@versions.push(@version_2)

				@advertiser = OpenStruct.new(
					:versions => @versions,
					:stores => [],
					:translations => []
				)
				@presenter = Presenters::Versions::Advertiser.new(@advertiser)
			end

			should "return by date desc" do
				assert_equal @version_2.created_at.to_date, @presenter.by_date.first.date, "should show most recent version first"
				assert_equal @version_1.created_at.to_date, @presenter.by_date.last.date, "should show oldest version last"
			end

		end

		context "with versions on the a couple of store records" do

			setup do
				@stores = []

				@version_1 = build_version( "May 30 13:00:00 -0700 2012", {"address_line_1" => ["123 Main Street", "123 Main St"]} )
				@version_1.stubs(:versioned_id).returns(1)
				@store_1 = OpenStruct.new( :id => 1, :versions => [@version_1], :address => ["555 Main Street", "Portland", "OR"] )

				@version_2 = build_version( "Jun 01 15:00:00 -0700 2012", {"phone_number" => ["", "1-800-555-1234"]} )
				@version_2.stubs(:versioned_id).returns(2)
				@store_2 = OpenStruct.new( :id => 2, :versions => [@version_2], :address => ["123 Main Street", "Portland", "OR"] )

				@stores.push( @store_1 )
				@stores.push( @store_2 )

				@advertiser = OpenStruct.new(
					:versions => [],
					:stores => @stores,
					:translations => []
				)				
				@presenter = Presenters::Versions::Advertiser.new(@advertiser)
				@presenter.expects(:find_store_by_id).with(1).returns(@store_1)
				@presenter.expects(:find_store_by_id).with(2).returns(@store_2)
			end

			should "return by date desc" do
				assert_equal @version_2.created_at.to_date, @presenter.by_date.first.date, "should show most recent version first"
				assert_equal @version_1.created_at.to_date, @presenter.by_date.last.date, "should show oldest version last"
			end

		end	

		context "with versions on translations" do

			setup do
				@versions = []

				@version_1 		= build_version( "May 30 13:00:00 -0700 2012", {"name" => ["Initial Name", "Name Change 1"]} )
				@version_2 		= build_version( "May 30 13:00:00 -0700 2012", {"name" => ["Name Change 1", "Name Change 2"]} )				

				@versions.push(@version_1)
				@versions.push(@version_2)

				@translation 	= OpenStruct.new( :versions => @versions )

				@advertiser = OpenStruct.new(
					:versions => [],
					:stores => [],
					:translations => [@translation]
				)
				@presenter = Presenters::Versions::Advertiser.new(@advertiser)
			end

			should "return by date desc" do
				assert_equal @version_2.created_at.to_date, @presenter.by_date.first.date, "should show most recent version first"
				assert_equal @version_1.created_at.to_date, @presenter.by_date.last.date, "should show oldest version last"
			end			

		end	

  end

  context "#description_from_attribute_and_values" do
    setup do
      @presenter = Presenters::Versions::Advertiser.new(OpenStruct.new)
    end

    should "handle blank to non-blank" do
      attribute = "size"
      values = [nil, "Large"]
      assert_equal "Size was changed to 'Large'", @presenter.send(:description_from_attribute_and_values, attribute, values)
    end

    should "handle non-blank to blank" do
      attribute = "size"
      values = ["Large", nil]
      assert_equal "Size was changed from 'Large' to ''", @presenter.send(:description_from_attribute_and_values, attribute, values)
    end
  end

end
