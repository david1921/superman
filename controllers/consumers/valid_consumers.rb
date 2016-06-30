module Consumers::ValidConsumers
  def ensure_valid_consumer
    # try to return an answer WITHOUT accessing the session first... failing that, hit the session (current_consumer)
    if current_consumer && !current_consumer.valid? && current_consumer.publisher.publishing_group.enable_force_valid_consumers?
      flash[:notice] = Analog::Themes::I18n.t(current_consumer.publisher, "consumers.edit.confirm_account_details")
      redirect_to edit_publisher_consumer_path(current_consumer.publisher, current_consumer)
      return false
    end
    true
  end
  def enforcing_valid_consumers?
    @publisher && @publisher.try(:publishing_group).try(:enable_force_valid_consumers?)
  end
end
