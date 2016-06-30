module Advertisers::NotesHelper
  def can_edit?(note)
    admin? || is_note_author?(note)
  end

  private

  def is_note_author?(note)
    note.user == current_user
  end
end