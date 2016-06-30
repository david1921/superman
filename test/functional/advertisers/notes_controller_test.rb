require File.dirname(__FILE__) + "/../../test_helper"

class Advertisers::NotesControllerTest < ActionController::TestCase
  
	context "#index" do

		setup do
			@advertiser = Factory(:advertiser)
		end

		context "without an authenticated user" do

			should "redirect to new session path" do
				get :index, :advertiser_id => @advertiser.to_param
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that can not manage advertiser" do

			setup do
				@user = Factory(:user)
				login_as @user
			end

			should "redirect to new session path" do
				get :index, :advertiser_id => @advertiser.to_param
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that can manage advertiser" do

			setup do
				publisher = @advertiser.publisher
				publisher.update_attribute(:self_serve, true)
				@user = Factory(:user, :company => publisher)
				login_as @user
				get :index, :advertiser_id => @advertiser.to_param
			end

			should "assign @notes" do
				assert_not_nil assigns(:notes)
			end

			should "render index template" do
				assert_template :index
			end

			should "render the create note form" do
				assert_select "form[action='#{advertiser_notes_path(@advertiser)}']"
			end

		end

		context "with admin account" do

			setup do
				@admin = Factory(:admin)
				login_as @admin
				get :index, :advertiser_id => @advertiser.to_param
			end

			should "assign @notes" do
				assert_not_nil assigns(:notes)
			end			

			should "render index template" do
				assert_template :index
			end

			should "render the create note form" do
				assert_select "form[action='#{advertiser_notes_path(@advertiser)}']" do
					assert_select "textarea[name='note[text]']"
					assert_select "input[type='file'][name='note[attachment]']"
					assert_select "input[type='text'][name='note[external_url]']"					
					assert_select "input[type=submit][value='Add Note']"
          cancel_url = "window.location.href = '#{edit_publisher_advertiser_url(@advertiser.publisher, @advertiser)}';"
          assert_select "input[onclick='#{cancel_url}'][type=button][value='Cancel']"

				end
			end			

    end

    should "render using the note's updated_at timestamp" do
      user = Factory(:admin, :login => "admin_user")
      note = Factory(:note, :notable => @advertiser, :text => "This is a note", :user => user,
                     :updated_at => "2012-06-21 12:34:56", :created_at => "2012-06-19 12:00:00")
      login_as user
      get :index, :advertiser_id => @advertiser.to_param
      assert_select ".notes li", /\A#{Regexp.escape("June 21, 2012: This is a note by admin_user")}/
    end

	end

	context "#create" do

		setup do
			@advertiser = Factory(:advertiser)
		end

		context "without an authenticated account" do

			should "redirect to new session path" do
				post :create, :advertiser_id => @advertiser.to_param, :note => {:text => "blah"} 
				assert_redirected_to new_session_path
			end

		end

		context "with an account that can not manage advertiser" do

			should "redireect to new session path" do
				login_as Factory(:user)
				post :create, :advertiser_id => @advertiser.to_param, :note => {:text => "blah"} 
				assert_redirected_to new_session_path
			end

		end

		context "with an account that can manage advertiser" do

			setup do
				publisher = @advertiser.publisher
				publisher.update_attribute(:self_serve, true)
				@user = Factory(:user, :company => publisher)
				login_as @user				
			end

			should "create a new note and redirect to advertiser_notes_path with valid notes attributes" do
				assert_difference "Note.count" do
					post :create, :advertiser_id => @advertiser, :note => { :text => "my text!" }
					assert_redirected_to advertiser_notes_path( @advertiser )
				end
			end

			should "render index with invalid note attribute and not create a new note" do
				assert_no_difference "Note.count" do
					post :create, :advertiser_id => @advertiser, :note => { :text => "" }
					assert_template :index
					assert_not_nil assigns(:notes)
				end
			end

		end

	end

	context "#edit" do

		setup do
			@advertiser = Factory(:advertiser)
			@note				= Factory(:note, :notable => @advertiser)
		end

		context "without an authenticated user" do

			should "redirect to new session path" do
				get :edit, :advertiser_id => @advertiser.to_param, :id => @note.to_param
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that cannot manage the advertiser" do

			should "redirect to new session path" do
				login_as Factory(:user)
				get :edit, :advertiser_id => @advertiser.to_param, :id => @note.to_param
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that can manage the advertiser" do

			setup do
				@publisher  = @advertiser.publisher
				@publisher.update_attribute(:self_serve, true)
				@note_owner = Factory(:user, :company => @publisher)
				@note = Factory(:note, :notable => @advertiser, :user => @note_owner)
			end

			should "redirect to advertiser_notes_path for user who does not own note" do
				user = Factory(:user, :company => @publisher)
				login_as user
				get :edit, :advertiser_id => @advertiser.to_param, :id => @note.to_param
				assert_redirected_to advertiser_notes_path(@advertiser)
			end

			should "render the edit template for user who does own the note" do
				login_as @note_owner
				get :edit, :advertiser_id => @advertiser.to_param, :id => @note.to_param
				assert_template :edit
			end


		end

		context "with an admin account" do

			setup do
				@publisher  = @advertiser.publisher
				@publisher.update_attribute(:self_serve, true)
				@note_owner = Factory(:user, :company => @publisher)
				@note = Factory(:note, :notable => @advertiser, :user => @note_owner)				
			end

			should "render the edit template" do
				login_as Factory(:admin)
				get :edit, :advertiser_id => @advertiser.to_param, :id => @note.to_param
				assert_template :edit
			end

		end

	end

	context "#update" do

		setup do
			@advertiser = Factory(:advertiser)
			@note				= Factory(:note, :notable => @advertiser)
		end

		context "without an authenticated user" do

			should "redirect to new session path" do
				put :update, :advertiser_id => @advertiser.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that cannot manage the advertiser" do

			should "redirect to new session path" do
				login_as Factory(:user)
				put :update, :advertiser_id => @advertiser.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to new_session_path
			end

		end

		context "with an authenticated user that can manage the advertiser" do

			setup do
				@publisher  = @advertiser.publisher
				@publisher.update_attribute(:self_serve, true)
				@note_owner = Factory(:user, :company => @publisher)
				@note = Factory(:note, :notable => @advertiser, :user => @note_owner, :text => "Initial text")
			end

			should "redirect to advertiser_notes_path and not update note for user who does not own note" do
				user = Factory(:user, :company => @publisher)
				login_as user
				put :update, :advertiser_id => @advertiser.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to advertiser_notes_path(@advertiser)
				assert_equal "Initial text", @note.reload.text
			end

			should "redirect to advertiser_notes_path and update note for user who does own the note" do
				login_as @note_owner
				put :update, :advertiser_id => @advertiser.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to advertiser_notes_path(@advertiser)
				assert_equal "Changes.", @note.reload.text
			end


		end

		context "with an admin account" do

			setup do
				@publisher  = @advertiser.publisher
				@publisher.update_attribute(:self_serve, true)
				@note_owner = Factory(:user, :company => @publisher)
				@note = Factory(:note, :notable => @advertiser, :user => @note_owner)				
			end

			should "redirect to advertiser_notes_path and update note" do
				login_as Factory(:admin)
				put :update, :advertiser_id => @advertiser.to_param, :id => @note.to_param, :note => {:text => "Changes."}
				assert_redirected_to advertiser_notes_path(@advertiser)
				assert_equal "Changes.", @note.reload.text
			end

		end

	end

end
