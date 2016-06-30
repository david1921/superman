require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Stores::AuditedTest

class Stores::AuditedTest < ActiveSupport::TestCase

	context "audited" do

		setup do
			@address_line_1 = "123 main st"
			@store = Factory(:store, :address_line_1 => @address_line_1)
		end

		should "have no versions on initial create" do
			assert_equal 0, @store.versions.count
		end

		context "changes with no User.current" do

			setup do
				User.stubs(:current).returns(nil)
				@store.update_attribute(:address_line_1, "999 Holgate St.")
				@store.reload
			end

			should "have 1 version" do
				assert_equal 1, @store.versions.count
			end

			should "have a new label" do
				assert_equal "999 Holgate St.", @store.address_line_1
			end

			should "have 123 main st on the versioned store" do
				@store.revert_to(1)
				assert_equal @address_line_1, @store.address_line_1
			end

			should "not have an associated updated_by" do
				@store.revert_to(1)
				assert_nil @store.updated_by
			end

		end

		context "changes with User.current" do

			setup do
				User.stubs(:current).returns( Factory(:admin) )
				@store.update_attribute(:address_line_1, "999 Holgate St.")
				@store.reload
			end

			should "have 1 version" do
				assert_equal 1, @store.versions.count
			end

			should "have a new label" do
				assert_equal "999 Holgate St.", @store.address_line_1
			end

			should "have 123 main st on the versioned store" do
				@store.revert_to(1)
				assert_equal @address_line_1, @store.address_line_1
			end

			should "have an associated updated_by" do
				@store.revert_to(1)
				assert_equal User.current, @store.updated_by
			end			

		end


	end

end