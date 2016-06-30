module Publishers::SweepstakeEntriesHelper

  def entries_path
    publisher_sweepstake_entries_path(@publisher.label, @sweepstake)
  end

  def login_errors_object
    return nil if current_consumer
    session   = params[:session] || {}
    if session[:email].present? && session[:password].present?
      new_consumer.tap do |consumer|
        consumer.errors.add_to_base(t 'failed_login_message')
      end
    else
      nil
    end
  end
  
  def third_party_opt_in_display_value(sweepstake_entry)
    return "" unless sweepstake_entry.sweepstake.show_promotional_opt_in_checkbox?
    sweepstake_entry.receive_promotional_emails? ? "Yes" : "No"
  end

  private

  def new_consumer
    Consumer.new
  end

end
