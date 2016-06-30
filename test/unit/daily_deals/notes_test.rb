require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::NotesTest < ActiveSupport::TestCase

	context "#notes" do

		setup do
			@daily_deal = Factory(:daily_deal)
			@user   		= Factory(:user, :company => @daily_deal.publisher)
		end

		should "have not notes to begin with" do
			assert @daily_deal.notes.empty?
		end

		should "be able to create a note on daily deal" do
			@daily_deal.notes.create( :user => @user, :text => "This is a note" )
			@daily_deal.reload
			assert_equal 1, @daily_deal.notes.size
			assert_equal @user, @daily_deal.notes.first.user
			assert_equal "This is a note", @daily_deal.notes.first.text
		end

	end

end