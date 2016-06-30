require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Advertisers::AuditedTranslationTest

class Advertisers::AuditedTranslationTest < ActiveSupport::TestCase

	context "audited_translations" do

		setup do
			@advertiser = Factory(:advertiser, :name => "Initial Name")
			@advertiser.reload
		end

		should "have one translation" do
			assert_equal 1, @advertiser.translations.size
		end

		should "have no versions on initial translation" do
			assert @advertiser.translations.first.versions.empty?
		end

		should "have 'Initial Name' for the advertiser" do
			assert_equal "Initial Name", @advertiser.name
		end

		context "changed name" do

			setup do
				@advertiser.update_attribute(:name, "MY New Name")
				@advertiser.reload
			end

			should "have one translation" do
				assert_equal 1, @advertiser.translations.size
			end

			should "have one version on the name translation" do
				assert_equal 1, @advertiser.translations.first.versions.size
			end

			should "have correct name for each version of the name translation" do
				translation = @advertiser.translations.first
				assert_equal "MY New Name", translation.name
				translation.revert_to(1)
				assert_equal "Initial Name", translation.name
			end

		end

	end

end