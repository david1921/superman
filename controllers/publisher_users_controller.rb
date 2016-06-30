class PublisherUsersController < UsersController
  before_filter :admin_privilege_required
  before_filter :set_parent
  
  helper_method :cancel_edit_url
  
  private
  
  def set_parent
    @parent = Publisher.find(params[:publisher_id])
  end

  def set_crumb_prefix(publisher)
    add_crumb "Publishers", publishers_path
    add_crumb publisher.name
    add_crumb "Users", publisher_users_path(publisher)
  end
  
  def cancel_edit_url
    publisher_users_url(@parent)
  end
end
