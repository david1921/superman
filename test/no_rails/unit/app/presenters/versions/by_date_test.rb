require File.dirname(__FILE__) + "/../../presenters_helper"

class Presenters::Versions::ByDateTest < Test::Unit::TestCase

	context "#initialize" do

		should "raise InvalidDateException if date is nil" do
			assert_raises Presenters::Versions::ByDate::InvalidDateException do
				Presenters::Versions::ByDate.new(nil, [])
			end
		end

		should "raise InvalidDateException from invalid date" do
			assert_raises Presenters::Versions::ByDate::InvalidDateException do
				Presenters::Versions::ByDate.new("blah", [])
			end
		end

	end

	context "#entries" do

		context "with nil versions" do
			should "return an empty array" do
				assert Presenters::Versions::ByDate.new( Time.now, nil ).entries.empty?
			end
		end

		context "with empty versions" do
			should "return an empty array" do
				assert Presenters::Versions::ByDate.new( Time.now, [] ).entries.empty?
			end
		end

	end

end