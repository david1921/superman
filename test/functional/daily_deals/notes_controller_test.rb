require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeals::NotesControllerTest < ActionController::TestCase

	context "#index" do

		setup do
			@daily_deal = Factory(:daily_deal)
		end

		context "without an authenticated user" do

			should "redirect to new session path" do
				get :index, :daily_deal_id => @daily_deal.to_param
				assert_redirected_to new_session_path
			end

		end	

		context "with an authenticated user that can not manage daily deal" do

			setup do
				@user = Factory(:user)
				login_as @user
			end

			should "redirect to new session path" do
				get :index, :daily_deal_id => @daily_deal.to_param
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that can manage the daily deal" do

			setup do
				publisher = @daily_deal.publisher
				publisher.update_attribute(:self_serve, true)
				@user = Factory(:user, :company => publisher)
				login_as @user
				get :index, :daily_deal_id => @daily_deal.to_param
			end

			should "assign @notes" do
				assert_not_nil assigns(:notes)
			end

			should "render index template" do
				assert_template :index
			end

			should "render the create note form" do
				assert_select "form[action='#{daily_deal_notes_path(@daily_deal)}']"
			end

		end

		context "with an admin account" do

			setup do
				login_as Factory(:admin)
				get :index, :daily_deal_id => @daily_deal.to_param
			end

			should "assign @notes" do
				assert_not_nil assigns(:notes)
			end

			should "render index template" do
				assert_template :index
			end

			should "render the create note form" do
				assert_select "form[action='#{daily_deal_notes_path(@daily_deal)}']"
			end

		end		

	end

	context "#create" do

		setup do
			@daily_deal = Factory(:daily_deal)
		end

		context "without an authenticated account" do

			should "redirect to new session path" do
				post :create, :daily_deal_id => @daily_deal.to_param, :note => {:text => "blah"} 
				assert_redirected_to new_session_path
			end

		end

		context "with an account that can not manage daily_deal" do

			should "redireect to new session path" do
				login_as Factory(:user)
				post :create, :daily_deal_id => @daily_deal.to_param, :note => {:text => "blah"} 
				assert_redirected_to new_session_path
			end

		end

		context "with an account that can manage daily deal" do

			setup do
				publisher = @daily_deal.publisher
				publisher.update_attribute(:self_serve, true)
				@user = Factory(:user, :company => publisher)
				login_as @user				
			end

			should "create a new note and redirect to daily_deal_notes_path with valid notes attributes" do
				assert_difference "Note.count" do
					post :create, :daily_deal_id => @daily_deal, :note => { :text => "my text!" }
					assert_redirected_to daily_deal_notes_path( @daily_deal )
				end
			end

			should "render index with invalid note attribute and not create a new note" do
				assert_no_difference "Note.count" do
					post :create, :daily_deal_id => @daily_deal, :note => { :text => "" }
					assert_template :index
					assert_not_nil assigns(:notes)
				end
			end

		end

	end

	context "#edit" do

		setup do
			@daily_deal = Factory(:daily_deal)
			@note				= Factory(:note, :notable => @daily_deal)
		end

		context "without an authenticated user" do

			should "redirect to new session path" do
				get :edit, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that cannot manage the daily_deal" do

			should "redirect to new session path" do
				login_as Factory(:user)
				get :edit, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that can manage the daily_deal" do

			setup do
				@publisher  = @daily_deal.publisher
				@publisher.update_attribute(:self_serve, true)
				@note_owner = Factory(:user, :company => @publisher)
				@note = Factory(:note, :notable => @daily_deal, :user => @note_owner)
			end

			should "redirect to daily_deal_notes_path for user who does not own note" do
				user = Factory(:user, :company => @publisher)
				login_as user
				get :edit, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param
				assert_redirected_to daily_deal_notes_path(@daily_deal)
			end

			should "render the edit template for user who does own the note" do
				login_as @note_owner
				get :edit, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param
				assert_template :edit
			end


		end

		context "with an admin account" do

			setup do
				@publisher  = @daily_deal.publisher
				@publisher.update_attribute(:self_serve, true)
				@note_owner = Factory(:user, :company => @publisher)
				@note = Factory(:note, :notable => @daily_deal, :user => @note_owner)				
			end

			should "render the edit template" do
				login_as Factory(:admin)
				get :edit, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param
				assert_template :edit
			end

		end

	end	

	context "#update" do

		setup do
			@daily_deal = Factory(:daily_deal)
			@note				= Factory(:note, :notable => @daily_deal)
		end

		context "without an authenticated user" do

			should "redirect to new session path" do
				put :update, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that cannot manage the daily_deal" do

			should "redirect to new session path" do
				login_as Factory(:user)
				put :update, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that can manage the daily_deal" do

			setup do
				@publisher  = @daily_deal.publisher
				@publisher.update_attribute(:self_serve, true)
				@note_owner = Factory(:user, :company => @publisher)
				@note = Factory(:note, :notable => @daily_deal, :user => @note_owner, :text => "Initial text")
			end

			should "redirect to daily_deal_notes_path and not update note for user who does not own note" do
				user = Factory(:user, :company => @publisher)
				login_as user
				put :update, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to daily_deal_notes_path(@daily_deal)
				assert_equal "Initial text", @note.reload.text
			end

			should "redirect to daily_deal_notes_path and update note for user who does own the note" do
				login_as @note_owner
				put :update, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to daily_deal_notes_path(@daily_deal)
				assert_equal "Changes.", @note.reload.text
			end


		end

		context "with an admin account" do

			setup do
				@publisher  = @daily_deal.publisher
				@publisher.update_attribute(:self_serve, true)
				@note_owner = Factory(:user, :company => @publisher)
				@note = Factory(:note, :notable => @daily_deal, :user => @note_owner)				
			end

			should "redirect to daily_deal_notes_path and update note" do
				login_as Factory(:admin)
				put :update, :daily_deal_id => @daily_deal.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to daily_deal_notes_path(@daily_deal)
				assert_equal "Changes.", @note.reload.text
			end

		end

	end	

end