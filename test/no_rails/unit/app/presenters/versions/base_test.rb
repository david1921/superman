require File.dirname(__FILE__) + "/../../presenters_helper"

class Presenters::Versions::BaseTest < Test::Unit::TestCase



	context "by_date" do

		context "with subclass that does not implement build_by_date" do

			setup do
				class NoBuildByDate < Presenters::Versions::Base; end
				@klass = NoBuildByDate.new				
			end

			should "raise NotImplementedError when by_date is called" do
				assert_raises NotImplementedError do
					@klass.by_date
				end
			end

		end

		context "with subclass that does implement build_by_date" do

			setup do
				class WithBuildByDate < Presenters::Versions::Base
					def build_by_date
						[]
					end
				end
				@klass = WithBuildByDate.new
			end

			should "not raise error, and return an empty array" do
				assert_equal [], @klass.by_date
			end

		end

	end

end
