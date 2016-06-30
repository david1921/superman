require File.dirname(__FILE__) + "/../test_helper"

class NoteTest < ActiveSupport::TestCase

	context "validations" do

		setup do
			@user 			= Factory(:user)
			@advertiser = Factory(:advertiser)
			@text				= "I am a note"
		end

		should "not be valid with missing notable" do
			note = Note.new(:user => @user, :text => @text)
			assert !note.valid?, "note should not be valid"
			assert note.errors.on(:notable).any?, "should have errors on :notable"
		end

		should "not be valid with missing user" do
			note = Note.new(:notable => @advertiser, :text => @text)
			assert !note.valid?, "note should not be valid"
			assert note.errors.on(:user).any?, "should have errors on :user"
		end

		should "not be valid with missing text" do
			note = Note.new(:notable => @advertiser, :user => @user)
			assert !note.valid?, "note should not be valid"
			assert note.errors.on(:text).any?, "should have errors on :text"
		end

		should "not be valid with invalid external_url" do
			note = Note.new(:notable => @advertiser, :user => @user, :text => "hello", :external_url => "blah")
			assert !note.valid?, "note should not be valid"
			assert note.errors.on(:external_url).any?, "should have errors on :external_url"
		end

	end

end