class DailyDeals::NotesController < DailyDeals::AdminController

  before_filter :load_note,                   :only => [:edit, :update]
  before_filter :ensure_user_can_manage_note, :only => [:edit, :update]

  def index
    publisher = @daily_deal.publisher
    @notes    = notes
    @note     = @daily_deal.notes.build

    add_crumb publisher.name
    add_crumb @daily_deal.value_proposition, edit_daily_deal_path(@daily_deal)
    add_crumb "Notes"
  end

  def create
    @note = @daily_deal.notes.build(params[:note].merge(:user => current_user))
    if @note.save
      redirect_to daily_deal_notes_path(@daily_deal)
    else
      @notes = notes
      render :index
    end
  end

  def edit
    publisher = @daily_deal.publisher
    add_crumb publisher.name
    add_crumb @daily_deal.value_proposition, edit_daily_deal_path(@daily_deal)
    add_crumb "Edit Note"       
  end

  def update
    @note.update_attributes(params[:note])
    redirect_to daily_deal_notes_path(@daily_deal)
  end

  private

  def load_note
    @note = @daily_deal.notes.find_by_id(params[:id])
  end

  def ensure_user_can_manage_note
    unless @note && (admin? || current_user == @note.user)
      redirect_to daily_deal_notes_path(@daily_deal)
    end
  end

  def notes
    @daily_deal.notes.descending_by_updated_at
  end  

end
