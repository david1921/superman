class Advertisers::NotesController < Advertisers::AdminController

	before_filter :load_note, :only => [:edit, :update]
	before_filter :ensure_user_can_manage_note, :only => [:edit, :update]

	def index
		publisher = @advertiser.publisher
		@notes 		= notes
		@note 		= @advertiser.notes.build

		add_crumb publisher.name
		add_crumb "Advertisers", publisher_advertisers_path(publisher)
		add_crumb @advertiser.name, edit_advertiser_path(@advertiser)
		add_crumb "Notes"
	end

	def create
		@note = @advertiser.notes.build(params[:note].merge(:user => current_user))
		if @note.save
			redirect_to advertiser_notes_path(@advertiser)
		else
			@notes = notes
			render :index
		end
	end

	def edit
		publisher = @advertiser.publisher
		add_crumb publisher.name
		add_crumb "Advertisers", publisher_advertisers_path(publisher)
		add_crumb @advertiser.name, edit_advertiser_path(@advertiser)
		add_crumb "Edit Note"		
	end

	def update
		@note.update_attributes(params[:note])
		redirect_to advertiser_notes_path(@advertiser)
	end

	private

	def load_note
		@note = @advertiser.notes.find_by_id(params[:id])
	end

	def ensure_user_can_manage_note
		unless @note && (admin? || current_user == @note.user)
			redirect_to advertiser_notes_path(@advertiser)
		end
	end

	def notes
		@advertiser.notes.descending_by_updated_at
	end

end
