require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::AuditedTest

class Advertisers::AuditedTest < ActiveSupport::TestCase

	context "audited" do

		setup do
			@label = "originallabel"
			@publisher  = Factory(:publisher)
			@advertiser = @publisher.advertisers.create( Factory.attributes_for(:advertiser, :label => @label) )
		end

		should "have 1 version on initial create" do
			assert_equal 1, @advertiser.reload.versions.count
		end

		context "changes with no User.current" do

			setup do
				User.stubs(:current).returns(nil)
				@advertiser.update_attribute(:label, "changedlabel")
				@advertiser.reload
			end

			should "have 2 versions" do
				assert_equal 2, @advertiser.versions.count
			end

			should "have a new label" do
				assert_equal "changedlabel", @advertiser.label
			end

			should "have originallabel on the versioned advertiser" do
				@advertiser.revert_to(1)
				assert_equal @label, @advertiser.label
			end

			should "not have an associated updated_by" do
				@advertiser.revert_to(1)
				assert_nil @advertiser.updated_by
			end

		end

		context "changes with User.current" do

			setup do
				User.stubs(:current).returns( Factory(:admin) )
				@advertiser.update_attribute(:label, "changedlabel")
				@advertiser.reload
			end

			should "have 2 versions" do
				assert_equal 2, @advertiser.versions.count
			end

			should "have a new label" do
				assert_equal "changedlabel", @advertiser.label
			end

			should "have originallabel on the versioned advertiser" do
				@advertiser.revert_to(1)
				assert_equal @label, @advertiser.label
			end

			should "have an associated updated_by" do
				@advertiser.revert_to(1)
				assert_equal User.current, @advertiser.updated_by
			end			

		end


	end

end