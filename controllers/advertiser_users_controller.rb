class AdvertiserUsersController < UsersController
  before_filter :user_required
  before_filter :set_parent
  
  helper_method :cancel_edit_url
  
  private
  
  def set_parent
    @parent = Advertiser.find(params[:advertiser_id])
    Publisher.manageable_by(current_user).find(@parent.publisher.id)
  end

  def set_crumb_prefix(advertiser)
    publisher = advertiser.publisher
    
    if admin?
      add_crumb "Publishers", publishers_path
    end
    if publishing_group?
      add_crumb "Publishers", publishing_group_publishers_path(current_user.company)
    end      
    if admin? || publishing_group? || publisher?
      add_crumb publisher.name
      add_crumb "Advertisers", publisher_advertisers_path(publisher)
    end
    add_crumb advertiser.name
    add_crumb "Users", advertiser_users_path(advertiser)
  end
  
  def cancel_edit_url
    advertiser_users_url(@parent)
  end
end
