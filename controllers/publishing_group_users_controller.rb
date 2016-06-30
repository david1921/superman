class PublishingGroupUsersController < UsersController
  before_filter :admin_privilege_required
  before_filter :set_parent
  before_filter :prevent_deletion_of_api_users_with_purchases, :only => :delete

  helper_method :cancel_edit_url
  
  def create
    @user = User.new(params[:user])
    @user.user_companies << UserCompany.new(:company => @parent)

    User.transaction do
      if @user.save && @user.errors.empty?
        associate_manageable_publishers!
        flash[:notice] = "Created #{@user.name}"
        redirect_to parent_users_url
      else
        flash[:error]  = "Could not create user"
        set_crumb_prefix @parent
        add_crumb_for_action :new
        render :template => "users/edit"
      end
    end
  end
  
  def update
    User.transaction do
      @user = @parent.users.find(params[:id])
      @user.attributes = params[:user]

      if @user.save
        associate_manageable_publishers!
        flash[:notice] = "Updated #{@user.name}"
        redirect_to parent_users_url
      else
        set_crumb_prefix @parent
        add_crumb @user.name
        add_crumb_for_action :edit, @user
        render :template => "users/edit"
      end
    end
  end
  
  private
  
  def associate_manageable_publishers!
    @user.manageable_publishers.destroy_all
    
    if params[:access_perms] == "restricted"
      publisher_ids = params[:user][:manageable_publishers][:publisher_id] rescue []
      publisher_ids.each do |pub_id|
        ManageablePublisher.create! :user_id => @user.id, :publisher_id => pub_id
      end
    end
  end

  def set_parent
    @parent = PublishingGroup.find(params[:publishing_group_id])
  end
  
  def set_crumb_prefix(publishing_group)
    add_crumb "Publishing Groups"
    add_crumb publishing_group.name
    add_crumb "Users", publishing_group_users_path(publishing_group)
  end
  
  def cancel_edit_url
    publishing_group_users_url(@parent)
  end

  def prevent_deletion_of_api_users_with_purchases
    protected_users = User.with_off_platform_purchases.find_all_by_id(params[:id])
    params[:id] -= protected_users.map(&:to_param)
    flash[:error] = "These users are associated with API purchases and could not be deleted: #{protected_users.map(&:login).join(', ')}"
  end
end
